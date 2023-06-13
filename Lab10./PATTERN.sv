`include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype_OS.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;

//================================================================
// parameters & integer
//================================================================
logic [7:0] golden_DRAM [(65536 +256*8 -1):65536];
Shop_Info golden_shopping_inf [0:255];
User_Info golden_user_inf [0:255];
logic buyer_can_re[0:255];
logic seller_can_be_re[0:255];
User_id b_table[0:255];
///////////////////////////////////////
parameter id_threshold = 2;
parameter action_threshold = 16;
parameter err_threshold = 20;
parameter lms_threshold = 20;
parameter money_threshold = 20;
parameter complete_threshold = 200;

parameter PRICE_L = 300;
parameter PRICE_M = 200;
parameter PRICE_S = 100;
integer seed = 46;//37
integer SEED = 124;//55
///////////////////////////////////////
integer action_num[0:3][0:3];
integer complete_num[0:1];
integer err_num[0:7];
integer lms_num[0:2];
integer money_num[0:4];
integer id_num[0:255];
 integer pat;
integer i,j;
integer work;
integer wi;
integer wnum = $urandom(198)%(2);
integer witem = $urandom(201)%(2);
reg[10*8:1] txt_green_prefix  = "\033[1;32m";
reg[10*8:1] txt_blue_prefix   = "\033[1;34m";
reg[9*8:1]  reset_color       = "\033[1;0m";
//================================================================
// wire & registers 
//================================================================
Shop_Info now_shop_info_u,now_shop_info_s,re_shop_info_s;
User_Info now_user_info_u,now_user_info_s,re_user_info_s;
Money money;
Action action = No_action;
Action pre_action = No_action;
Action next_action = No_action;
Item_id lms;
logic sell_or_n;
logic cal_start;
User_id now_uid,now_sid;
logic[5:0] buy_how_many;
/////////////////////////////////
Error_Msg golden_err_msg;
logic [31:0] golden_out_info;
logic golden_complete;
//================================================================
// Class
//================================================================
class random_gap;	
    randc integer  interval;
    function new (int seed);
        this.srandom(seed);		
    endfunction 
    constraint limit {interval inside {[1:5]};}
endclass
class random_next_input;	
    randc int next_input;
    function new (int seed);
        this.srandom(seed);		
    endfunction 
    constraint limit {next_input inside {[2:10]};}
endclass
class random_user_id;	
    randc int user_id;
    function new (int seed);
        this.srandom(seed);		
    endfunction 
    constraint limit {user_id inside {[0:255]};}
endclass

class random_seller_id;	
    randc int seller_id;
    function new (int seed);
        this.srandom(seed);		
    endfunction 
    constraint limit {seller_id inside {[0:255]};}
endclass

class random_LMS;
    rand Item_id lms;
    function new(int seed);
        this.srandom(seed);
    endfunction
    constraint limit {lms inside {Large,Medium,Small};}
endclass

class random_money;
    rand Money money;
    function new(int seed);
        this.srandom(seed);
    endfunction
    constraint limit {money inside{[0:60000]};}
endclass

class random_item_num;
    randc logic[5:0] item_num;
    function new(int seed);
        this.srandom(seed);
    endfunction
    constraint limit {item_num inside{[0:63]};}
endclass
class rand_wi;
rand int wi;
    function new(int seed);
    this.srandom(seed);
    endfunction
    constraint limit {wi inside{[0:3]};}
endclass
random_next_input ran_n_in = new(SEED);
random_money ran_mon = new(SEED);
random_LMS ran_lms = new(SEED);
random_user_id ran_uid = new(SEED);
random_seller_id ran_sid = new(SEED);
random_gap ran_gap = new(SEED);
random_item_num ran_it_num = new(SEED);
rand_wi rwi = new(SEED);
//================================================================
// initial
//================================================================
initial begin
    $readmemh("../00_TESTBED/DRAM/dram.dat", golden_DRAM);

    for(i=0;i<256;i=i+1)begin
        golden_shopping_inf [i] = {golden_DRAM[65536+i*8],golden_DRAM[65536+i*8+1],golden_DRAM[65536+i*8+2],golden_DRAM[65536+i*8+3]};
        golden_user_inf [i] = {golden_DRAM[65536+i*8+4],golden_DRAM[65536+i*8+5],golden_DRAM[65536+i*8+6],golden_DRAM[65536+i*8+7]};
    end

    for (i=0;i<4;i=i+1)begin
        for(j=0;j<4;j=j+1)begin
            action_num[i][j] = 0;
        end
    end
    for (i=0;i<2;i=i+1)begin
        complete_num[i] =0;
    end
    for (i=0;i<7;i=i+1)begin
        err_num[i] =0;
    end
    for(i=0;i<3;i=i+1)begin
        lms_num[i] = 0;
    end
    for(i=0;i<5;i=i+1)begin
        money_num[i] = 0;
    end
    for(i=0;i<256;i=i+1)begin
        id_num[i] = 0;
        buyer_can_re[i] = 0;
        seller_can_be_re[i] = 0;
    end
    inf.D = 'dx; 
    inf.id_valid = 0; 
    inf.act_valid = 0; 
    inf.item_valid = 0; 
    inf.num_valid = 0; 
    inf.amnt_valid = 0;
    inf.rst_n = 1;
	reset_task;
    //while(1)begin
        //finish_check;
        for(pat =0;pat<30000;pat = pat+1)begin
        input_task;
        wait_outvalid_task;
        check_ans;
        //$display("PATNUM : %d",pat);
        end
        $finish;
    //end

end

initial begin
    forever @(posedge clk) begin
        if(!inf.rst_n) cal_start <= 0;
        else if(action == Buy && (inf.id_valid == 1||inf.act_valid==1)) cal_start <= 1;
        else if(action == Check && (inf.id_valid == 1||inf.act_valid==1)) cal_start <= 1;
        else if(action == Deposit && (inf.id_valid == 1||inf.act_valid==1)) cal_start <= 1;
        else if(action == Return && (inf.id_valid == 1||inf.act_valid==1)) cal_start <= 1;
        else if(inf.out_valid) cal_start <= 0;
    end
end

initial begin
    forever @(posedge clk) begin
        if(cal_start !==1 && inf.out_valid === 1) you_wrong;
        else if(inf.out_valid === 1 && {inf.id_valid,inf.act_valid,inf.item_valid,inf.amnt_valid,inf.num_valid}!==0) you_wrong;
    end
end
///////////Task/////////////////////////////////
//////Check ans on now_shopping_inf = shopping_inf[now_uid]
/////Check ans on now_shopping_inf = shopping_inf[now_sid]


/*task gen_in;begin
    work = ran_sid.randomize();
    now_sid = ran_sid.seller_id+$urandom(123)+1;
    work = ran_uid.randomize();
    now_uid = ran_uid.user_id;
    work = ran_mon.randomize();
    money = ran_mon.money;
    work = ran_lms.randomize();
    lms = ran_lms.lms;
    work = ran_it_num.randomize();
    buy_how_many = ran_it_num.item_num;
    now_shop_info_u = golden_shopping_inf[now_uid];
    now_shop_info_s = golden_shopping_inf[now_sid];
    now_user_info_u = golden_user_inf[now_uid];
    now_user_info_s = golden_user_inf[now_sid];
    re_shop_info_s = golden_shopping_inf[now_user_info_u.shop_history.seller_ID];
    re_user_info_s = golden_user_inf[now_user_info_u.shop_history.seller_ID];
end
endtask*/

/*task gen_action;begin
    integer next_action;
    integer now_action;
    integer buy_num,check_num,return_num,deposit_num;
    integer weight = 100;
    integer temp;
    if(action == No_action)begin
        next_action = 3;  
    end 
    else begin
        if(action == Buy) now_action = 0;
        else if(action == Check) now_action = 1;
        else if(action == Deposit) now_action = 2;
        else now_action = 3;

        buy_num = action_num[now_action][0];
        check_num = action_num[now_action][1];
        deposit_num = action_num[now_action][2];
        return_num = action_num[now_action][3];

        if(buy_num == 0) buy_num = weight;
        else buy_num = weight / buy_num;

        if(check_num == 0) check_num = weight;
        else check_num = weight / check_num;

        if(deposit_num == 0) deposit_num = weight;
        else deposit_num = weight / deposit_num;

        if(return_num == 0) return_num = weight;
        else return_num = weight / return_num;
        
        temp = $random(SEED) % (buy_num + check_num + deposit_num + return_num);

        if(temp < buy_num) next_action = 0;
        else if(temp < buy_num + check_num) next_action = 1;
        else if(temp < buy_num + check_num + deposit_num) next_action = 2;
        else next_action = 3;

        action_num[now_action][next_action] = action_num[now_action][next_action] + 1;
    end
    pre_action = action;
    action = next_action;
end
endtask*/


task input_task;begin
    //gen_action;
    //wi = $urandom(124)%4;
    Action next_action;
    Action now_action;
    integer buy_num,check_num,return_num,deposit_num;
    integer weight = 100;
    integer temp;
    if(action == No_action)begin
        next_action = Buy;  
    end 
    else begin
        if(action == Buy) now_action = Buy;
        else if(action == Check) now_action = Check;
        else if(action == Deposit) now_action = Deposit;
        else now_action = Return;

        /*buy_num = action_num[now_action][0];
        check_num = action_num[now_action][1];
        deposit_num = action_num[now_action][2];
        return_num = action_num[now_action][3];

        if(buy_num == 0) buy_num = weight;
        else buy_num = weight / buy_num;

        if(check_num == 0) check_num = weight;
        else check_num = weight / check_num;

        if(deposit_num == 0) deposit_num = weight;
        else deposit_num = weight / deposit_num;

        if(return_num == 0) return_num = weight;
        else return_num = weight / return_num;*/
        
        temp = $random(SEED) % (4);

        if(temp ==0) next_action = Buy;
        else if(temp ==1) next_action = Return;
        else if(temp ==2) next_action = Deposit;
        else next_action = Check;

        action_num[now_action][next_action] = action_num[now_action][next_action] + 1;
    end
    pre_action = action;
    action = next_action;
    //$display("current action: %4b",action);
    //gen_in;
    work = rwi.randomize();
    wi = rwi.wi;
    work = ran_sid.randomize();
    now_sid = ran_sid.seller_id+$urandom(123)+1;
    work = ran_uid.randomize();
    now_uid = ran_uid.user_id;
    work = ran_mon.randomize();
    money = ran_mon.money;
    work = ran_lms.randomize();
    lms = ran_lms.lms;
    work = ran_it_num.randomize();
    buy_how_many = ran_it_num.item_num;
    if(buy_how_many==0) buy_how_many = 1;
    //now_uid = 1;
    //now_sid = 2;
    //integer wi;
    //wi = $random(SEED)%(4);
    now_shop_info_u = golden_shopping_inf[now_uid];
    now_shop_info_s = golden_shopping_inf[now_sid];
    now_user_info_u = golden_user_inf[now_uid];
    now_user_info_s = golden_user_inf[now_sid];
    re_shop_info_s = golden_shopping_inf[now_user_info_u.shop_history.seller_ID];
    re_user_info_s = golden_user_inf[now_user_info_u.shop_history.seller_ID];
    inf.D = 'dx;
    inf.id_valid = 0;
    inf.act_valid = 0;
    inf.item_valid = 0;
    inf.num_valid = 0;
    inf.amnt_valid = 0;
    /*if(pat<500)begin
        now_uid = 3;
        now_shop_info_u = golden_shopping_inf[now_uid];
        now_user_info_u = golden_user_inf[now_uid];
        if(pat%2==0) action = Buy;
        else action = Return;
    end*/
    work = ran_n_in.randomize();
    repeat(ran_n_in.next_input)@(negedge clk);
    //$display("now user_id: %d",now_uid);
    //$display("now seller id(second user): %d",now_sid);
    //$display(" Item id :%d",lms);
    ///////////////////////////////////////
    inf.D = now_uid;
    inf.id_valid = 1;
    @(negedge clk);
    inf.D = 'dx;
    inf.id_valid = 0;
    /////////////////////////////////////////////////////
    work = ran_gap.randomize();
    repeat(ran_gap.interval)@(negedge clk);
    inf.D = action;
    inf.act_valid = 1;
    @(negedge clk);
    inf.D = 'dx;
    inf.act_valid = 0;
    work = ran_gap.randomize();
    repeat(ran_gap.interval)@(negedge clk);
///////////////////////////////////////////////////
    if(action==Buy)begin
        inf.D = lms;
        inf.item_valid = 1;
        @(negedge clk);
        inf.D = 'dx;
        inf.item_valid = 0;
        work = ran_gap.randomize();
        repeat(ran_gap.interval)@(negedge clk);
        inf.D = buy_how_many;
        inf.num_valid = 1;
        @(negedge clk);
        inf.D = 'dx;
        inf.num_valid = 0;
        work = ran_gap.randomize();
        repeat(ran_gap.interval)@(negedge clk);
        inf.D = now_sid;
        inf.id_valid = 1;
        @(negedge clk);
        inf.D = 'dx;
        inf.id_valid = 0;
        id_num[now_uid] = id_num[now_uid]+1;
        id_num[now_sid] = id_num[now_sid]+1;
        if(lms==Large) lms_num[2] = lms_num[2]+1;
        if(lms==Medium) lms_num[1] = lms_num[1]+1;
        if(lms==Small) lms_num[0] = lms_num[0]+1;
    end
    else if(action==Check)begin
        inf.D = now_sid;
        inf.id_valid = 1;
        @(negedge clk);
        inf.D = 'dx;
        inf.id_valid = 0;
        id_num[now_uid] = id_num[now_uid]+1;
    end
    else if(action==Deposit)begin
        inf.D = money;
        inf.amnt_valid = 1;
        @(negedge clk);
        inf.D = 'dx;
        inf.amnt_valid = 0;
        if((money<12001))money_num[0] = money_num[0]+1;
        else if((money>=12001)&&(money<24001)) money_num[1] = money_num[1]+1;
        else if((money>=24001)&&(money<36001)) money_num[2] = money_num[2]+1;
        else if((money>=36001)&&(money<48001)) money_num[3] = money_num[3]+1;
        else if(money>=48001) money_num[4] = money_num[4]+1;
    end
    else if(action==Return) begin
        if(wi==0)begin
            inf.D = now_user_info_u.shop_history.item_ID+2;
            inf.item_valid = 1;
            @(negedge clk);
            inf.D = 'dx;
            inf.item_valid = 0;
            work = ran_gap.randomize();
            repeat(ran_gap.interval)@(negedge clk);
            inf.D = now_user_info_u.shop_history.item_num;
            inf.num_valid = 1;
            @(negedge clk);
            inf.D = 'dx;
            inf.num_valid = 0;
            work = ran_gap.randomize();
            repeat(ran_gap.interval)@(negedge clk);
            inf.D = now_user_info_u.shop_history.seller_ID;
            inf.id_valid = 1;
            @(negedge clk);
            inf.D = 'dx;
            inf.id_valid = 0;
            id_num[now_uid] = id_num[now_uid]+1;
            id_num[now_user_info_u.shop_history.seller_ID] = id_num[now_user_info_u.shop_history.seller_ID]+1;
            if(now_user_info_u.shop_history.item_ID==Large) lms_num[2] = lms_num[2]+1;
            if(now_user_info_u.shop_history.item_ID==Medium) lms_num[1] = lms_num[1]+1;
            if(now_user_info_u.shop_history.item_ID==Small) lms_num[0] = lms_num[0]+1;
        end
        else if(wi==1)begin
            inf.D = now_user_info_u.shop_history.item_ID;
            inf.item_valid = 1;
            @(negedge clk);
            inf.D = 'dx;
            inf.item_valid = 0;
            work = ran_gap.randomize();
            repeat(ran_gap.interval)@(negedge clk);
            inf.D = now_user_info_u.shop_history.item_num+2;
            inf.num_valid = 1;
            @(negedge clk);
            inf.D = 'dx;
            inf.num_valid = 0;
            work = ran_gap.randomize();
            repeat(ran_gap.interval)@(negedge clk);
            inf.D = now_user_info_u.shop_history.seller_ID;
            inf.id_valid = 1;
            @(negedge clk);
            inf.D = 'dx;
            inf.id_valid = 0;
            id_num[now_uid] = id_num[now_uid]+1;
            id_num[now_sid] = id_num[now_sid]+1;
            if(now_user_info_u.shop_history.item_ID==Large) lms_num[2] = lms_num[2]+1;
            if(now_user_info_u.shop_history.item_ID==Medium) lms_num[1] = lms_num[1]+1;
            if(now_user_info_u.shop_history.item_ID==Small) lms_num[0] = lms_num[0]+1;
        end
        else if(wi==2)begin
            inf.D =now_user_info_u.shop_history.item_ID;
            inf.item_valid = 1;
            @(negedge clk);
            inf.D = 'dx;
            inf.item_valid = 0;
            work = ran_gap.randomize();
            repeat(ran_gap.interval)@(negedge clk);
            inf.D =  now_user_info_u.shop_history.item_num;
            inf.num_valid = 1;
            @(negedge clk);
            inf.D = 'dx;
            inf.num_valid = 0;
            work = ran_gap.randomize();
            repeat(ran_gap.interval)@(negedge clk);
            inf.D = now_user_info_u.shop_history.seller_ID+2;
            inf.id_valid = 1;
            @(negedge clk);
            inf.D = 'dx;
            inf.id_valid = 0;
            id_num[now_uid] = id_num[now_uid]+1;
            id_num[now_user_info_u.shop_history.seller_ID] = id_num[now_user_info_u.shop_history.seller_ID]+1;
            if(lms==Large) lms_num[2] = lms_num[2]+1;
            if(lms==Medium) lms_num[1] = lms_num[1]+1;
            if(lms==Small) lms_num[0] = lms_num[0]+1;
        end
        else begin
        inf.D = lms;
        inf.item_valid = 1;
        @(negedge clk);
        inf.D = 'dx;
        inf.item_valid = 0;
        work = ran_gap.randomize();
        repeat(ran_gap.interval)@(negedge clk);
        inf.D = buy_how_many;
        inf.num_valid = 1;
        @(negedge clk);
        inf.D = 'dx;
        inf.num_valid = 0;
        work = ran_gap.randomize();
        repeat(ran_gap.interval)@(negedge clk);
        inf.D = now_sid;
        inf.id_valid = 1;
        @(negedge clk);
        inf.D = 'dx;
        inf.id_valid = 0;
        id_num[now_uid] = id_num[now_uid]+1;
        id_num[now_sid] = id_num[now_sid]+1;
        if(lms==Large) lms_num[2] = lms_num[2]+1;
        if(lms==Medium) lms_num[1] = lms_num[1]+1;
        if(lms==Small) lms_num[0] = lms_num[0]+1;
        end
    end
end
endtask

task check_ans;begin
    if(action==Buy)begin
        logic[20:0] temp_exp;
        if(lms==Large)begin
            if(buy_how_many>63-now_shop_info_u.large_num)begin
                golden_err_msg = INV_Full;
                golden_complete = 0;
                golden_out_info = 0;
                err_num[0] = err_num[0]+1;
                complete_num[0] = complete_num[0]+1;
            end
            else if(buy_how_many>now_shop_info_s.large_num)begin
                golden_err_msg = INV_Not_Enough;
                golden_complete = 0;
                golden_out_info = 0;
                err_num[1] = err_num[1]+1;
                complete_num[0] = complete_num[0]+1;
            end
            else if((buy_how_many*PRICE_L)>now_user_info_u.money)begin
                golden_err_msg = Out_of_money;
                golden_complete = 0;
                golden_out_info = 0;
                err_num[2] = err_num[2]+1;
                complete_num[0] = complete_num[0]+1;
            end
            else begin
                if(now_shop_info_u.level==Copper)begin
                    temp_exp = now_shop_info_u.exp+(60*buy_how_many);
                    //buyer
                    now_user_info_u.money = now_user_info_u.money-((300*buy_how_many)+70);
                    now_shop_info_u.large_num = now_shop_info_u.large_num+buy_how_many;
                    if(temp_exp>=1000)begin
                        now_shop_info_u.exp = 0;
                        now_shop_info_u.level = Silver;
                    end
                    else begin
                        now_shop_info_u.exp = temp_exp;
                    end
                end
                else if(now_shop_info_u.level==Silver)begin
                    temp_exp = now_shop_info_u.exp+(60*buy_how_many);
                    now_user_info_u.money = now_user_info_u.money-((300*buy_how_many)+50);
                    now_shop_info_u.large_num = now_shop_info_u.large_num+buy_how_many;
                    if(temp_exp>=2500)begin
                        now_shop_info_u.exp = 0;
                        now_shop_info_u.level = Gold;
                    end
                    else begin
                        now_shop_info_u.exp = temp_exp;
                    end
                end
                else if(now_shop_info_u.level==Gold)begin
                    temp_exp = now_shop_info_u.exp+(60*buy_how_many);
                    now_user_info_u.money = now_user_info_u.money-((300*buy_how_many)+30);
                    now_shop_info_u.large_num = now_shop_info_u.large_num+buy_how_many;
                    if((4000-now_shop_info_u.exp)<(60*buy_how_many))begin
                        now_shop_info_u.exp = 0;
                        now_shop_info_u.level = Platinum;
                    end
                    else begin
                        now_shop_info_u.exp = temp_exp;
                    end
                end
                else if(now_shop_info_u.level==Platinum) begin
                    now_user_info_u.money = now_user_info_u.money-((300*buy_how_many)+10);
                    now_shop_info_u.large_num = now_shop_info_u.large_num+buy_how_many;
                    now_shop_info_u.exp = 0;
                end
                //seller
                if(65535-now_user_info_s.money>(300*buy_how_many)) now_user_info_s.money = now_user_info_s.money+(300*buy_how_many);
                else now_user_info_s.money = 65535;
                now_shop_info_s.large_num = now_shop_info_s.large_num-buy_how_many;
                golden_complete = 1;
                golden_err_msg = No_Err;
                //golden_out_info = now_user_info_u;
                golden_shopping_inf [now_uid] = now_shop_info_u;
                golden_user_inf[now_uid] = now_user_info_u;
                golden_shopping_inf[now_sid] = now_shop_info_s;
                golden_user_inf[now_sid] = now_user_info_s;
                buyer_can_re[now_uid] = 1;
                buyer_can_re[now_sid] = 0;
                seller_can_be_re[now_sid] = 1;
                seller_can_be_re[now_uid] = 0;
                b_table[now_sid] = now_uid;
            end
        end
        else if(lms==Medium)begin
            if(buy_how_many>63-now_shop_info_u.medium_num)begin
                golden_err_msg = INV_Full;
                golden_complete = 0;
                golden_out_info = 0;
                err_num[0] = err_num[0]+1;
                complete_num[0] = complete_num[0]+1;
            end
            else if(buy_how_many>now_shop_info_s.medium_num)begin
                golden_err_msg = INV_Not_Enough;
                golden_complete = 0;
                golden_out_info = 0;
                err_num[1] = err_num[1]+1;
                complete_num[0] = complete_num[0]+1;
            end
            else if((buy_how_many*200)>now_user_info_u.money)begin
                golden_err_msg = Out_of_money;
                golden_complete = 0;
                golden_out_info = 0;
                err_num[2] = err_num[2]+1;
                complete_num[0] = complete_num[0]+1;
            end
            else begin
                temp_exp = now_shop_info_u.exp+(40*buy_how_many);
                if(now_shop_info_u.level==Copper)begin
                    now_user_info_u.money = now_user_info_u.money-((200*buy_how_many)+70);
                    now_shop_info_u.medium_num = now_shop_info_u.medium_num+buy_how_many;
                    if(temp_exp>=1000)begin
                        now_shop_info_u.exp = 0;
                        now_shop_info_u.level = Silver;
                    end
                    else begin
                        now_shop_info_u.exp = temp_exp;
                    end
                end
                else if(now_shop_info_u.level==Silver)begin
                    //temp_exp = now_shop_info_u.exp+(60*buy_how_many);
                    now_user_info_u.money = now_user_info_u.money-((200*buy_how_many)+50);
                    now_shop_info_u.medium_num = now_shop_info_u.medium_num+buy_how_many;
                    if(temp_exp>=2500)begin
                        now_shop_info_u.exp = 0;
                        now_shop_info_u.level = Gold;
                    end
                    else begin
                        now_shop_info_u.exp = temp_exp;
                    end
                end
                else if(now_shop_info_u.level==Gold)begin
                    now_user_info_u.money = now_user_info_u.money-((200*buy_how_many)+30);
                    now_shop_info_u.medium_num = now_shop_info_u.medium_num+buy_how_many;
                    if((4000-now_shop_info_u.exp)<(40*buy_how_many))begin
                        now_shop_info_u.exp = 0;
                        now_shop_info_u.level = Platinum;
                    end
                    else begin
                        now_shop_info_u.exp = temp_exp;
                    end
                end
                else if(now_shop_info_u.level==Platinum) begin
                    now_user_info_u.money = now_user_info_u.money-((200*buy_how_many)+10);
                    now_shop_info_u.medium_num = now_shop_info_u.medium_num+buy_how_many;
                    now_shop_info_u.exp = 0;
                end
                if((65535-now_user_info_s.money)>(200*buy_how_many)) now_user_info_s.money = now_user_info_s.money+(200*buy_how_many);
                else now_user_info_s.money = 65535;
                now_shop_info_s.medium_num = now_shop_info_s.medium_num-buy_how_many;
                golden_complete = 1;
                golden_err_msg = No_Err;
                //golden_out_info = now_user_info_u;
                golden_shopping_inf [now_uid] = now_shop_info_u;
                golden_user_inf[now_uid] = now_user_info_u;
                golden_shopping_inf[now_sid] = now_shop_info_s;
                golden_user_inf[now_sid] = now_user_info_s;
                buyer_can_re[now_uid] = 1;
                buyer_can_re[now_sid] = 0;
                seller_can_be_re[now_sid] = 1;
                seller_can_be_re[now_uid] = 0;
                b_table[now_sid] = now_uid;
            end
        end
        else if(lms==Small) begin
            if(buy_how_many>63-now_shop_info_u.small_num)begin
                golden_err_msg = INV_Full;
                golden_complete = 0;
                golden_out_info = 0;
                err_num[0] = err_num[0]+1;
                complete_num[0] = complete_num[0]+1;
            end
            else if(buy_how_many>now_shop_info_s.small_num)begin
                golden_err_msg = INV_Not_Enough;
                golden_complete = 0;
                golden_out_info = 0;
                err_num[1] = err_num[1]+1;
                complete_num[0] = complete_num[0]+1;
            end
            else if((buy_how_many*PRICE_S)>now_user_info_u.money)begin
                golden_err_msg = Out_of_money;
                golden_complete = 0;
                golden_out_info = 0;
                err_num[2] = err_num[2]+1;
                complete_num[0] = complete_num[0]+1;
            end
            else begin
                temp_exp = now_shop_info_u.exp+(20*buy_how_many);
                if(now_shop_info_u.level==Copper)begin
                    now_user_info_u.money = now_user_info_u.money-((100*buy_how_many)+70);
                    now_shop_info_u.small_num = now_shop_info_u.small_num+buy_how_many;
                    if(temp_exp>=1000)begin
                        now_shop_info_u.exp = 0;
                        now_shop_info_u.level = Silver;
                    end
                    else begin
                        now_shop_info_u.exp = temp_exp;
                    end
                end
                else if(now_shop_info_u.level==Silver)begin
                    now_user_info_u.money = now_user_info_u.money-((100*buy_how_many)+50);
                    now_shop_info_u.small_num = now_shop_info_u.small_num+buy_how_many;
                    if(temp_exp>=2500)begin
                        now_shop_info_u.exp = 0;
                        now_shop_info_u.level = Gold;
                    end
                    else begin
                        now_shop_info_u.exp = temp_exp;
                    end
                end
                else if(now_shop_info_u.level==Gold)begin
                    now_user_info_u.money = now_user_info_u.money-((100*buy_how_many)+30);
                    now_shop_info_u.small_num = now_shop_info_u.small_num+buy_how_many;
                    if((4000-now_shop_info_u.exp)<(20*buy_how_many))begin
                        now_shop_info_u.exp = 0;
                        now_shop_info_u.level = Platinum;
                    end
                    else begin
                        now_shop_info_u.exp = temp_exp;
                    end
                end
                else if(now_shop_info_u.level==Platinum) begin
                    now_user_info_u.money = now_user_info_u.money-((100*buy_how_many)+10);
                    now_shop_info_u.small_num = now_shop_info_u.small_num+buy_how_many;
                    now_shop_info_u.exp = 0;
                    
                end
                if(65535-now_user_info_s.money>(100*buy_how_many)) now_user_info_s.money = now_user_info_s.money+(100*buy_how_many);
                else now_user_info_s.money = 65535;
                now_shop_info_s.small_num = now_shop_info_s.small_num-buy_how_many;
                //now_user_info_u.shop_history.item_ID = lms;
                golden_complete = 1;
                golden_err_msg = No_Err;
                //golden_out_info = now_user_info_u;
                golden_shopping_inf [now_uid] = now_shop_info_u;
                golden_user_inf[now_uid] = now_user_info_u;
                golden_shopping_inf[now_sid] = now_shop_info_s;
                golden_user_inf[now_sid] = now_user_info_s;
                buyer_can_re[now_uid] = 1;
                buyer_can_re[now_sid] = 0;
                seller_can_be_re[now_sid] = 1;
                seller_can_be_re[now_uid] = 0;
                b_table[now_sid] = now_uid;
            end
        end
        if(golden_err_msg==0)begin
        now_user_info_u.shop_history.item_ID = lms;
        now_user_info_u.shop_history.item_num = buy_how_many;
        now_user_info_u.shop_history.seller_ID = now_sid;
        golden_out_info = now_user_info_u;
        //golden_shopping_inf [now_uid] = now_shop_info_u;
        golden_user_inf[now_uid] = now_user_info_u;
        //golden_shopping_inf[now_sid] = now_shop_info_s;
        //golden_user_inf[now_sid] = now_user_info_s;
        end
    end
    else if(action==Check)begin
        golden_err_msg = No_Err;
        golden_complete = 1;
        golden_out_info = {14'b0,now_shop_info_s.large_num,now_shop_info_s.medium_num,now_shop_info_s.small_num};
        complete_num[1] = complete_num[1]+1;
        buyer_can_re[now_uid] = 0;
        seller_can_be_re[now_uid] = 0;
        buyer_can_re[now_sid] = 0;
        seller_can_be_re[now_sid] = 0;
    end
    else if(action==Deposit)begin
        if(65535-now_user_info_u.money<money)begin
            golden_err_msg = Wallet_is_Full;
            golden_complete = 0;
            golden_out_info = 0;
        end
        else begin
            now_user_info_u.money = now_user_info_u.money+money;
            golden_err_msg = No_Err;
            golden_complete = 1;
            golden_out_info = now_user_info_u.money;
            /////update dram
            golden_user_inf[now_uid] = now_user_info_u;
            buyer_can_re[now_uid] = 0;
            seller_can_be_re[now_uid] = 0;
        end
        if(golden_complete==0) complete_num[0] = complete_num[0]+1;
        else complete_num[1] = complete_num[1]+1;
        id_num[now_uid] = id_num[now_uid]+1;
    end
    else if(action==Return)begin
        if(wi==0)begin
            if(buyer_can_re[now_uid]==0)begin
                golden_complete = 0;
                golden_out_info = 0;
                golden_err_msg = Wrong_act;
            end
            else if(seller_can_be_re[now_user_info_u.shop_history.seller_ID]==0)begin
                golden_complete = 0;
                golden_out_info = 0;
                golden_err_msg = Wrong_act;
            end
            else if(b_table[now_user_info_u.shop_history.seller_ID]!=now_uid)begin
                golden_complete = 0;
                golden_out_info = 0;
                golden_err_msg = Wrong_act;
            end
            /*else if(now_user_info_u.shop_history.item_num!=buy_how_many)begin
                golden_complete = 0;
                golden_out_info = 0;
                golden_err_msg = Wrong_Num;
            end*/
            else if(now_user_info_u.shop_history.item_ID!=(now_user_info_u.shop_history.item_ID+2))begin
                golden_complete = 0;
                golden_out_info = 0;
                golden_err_msg = Wrong_Item;
            end
            
            else begin              
                if(now_user_info_u.shop_history.item_ID==Large)begin
                    now_shop_info_u.large_num = now_shop_info_u.large_num-now_user_info_u.shop_history.item_num;
                    now_user_info_u.money = now_user_info_u.money+(now_user_info_u.shop_history.item_num*300);
                    re_shop_info_s.large_num = re_shop_info_s.large_num+now_user_info_u.shop_history.item_num;
                    re_user_info_s.money = re_user_info_s.money-(now_user_info_u.shop_history.item_num*300);
                end
                else if(now_user_info_u.shop_history.item_ID==Medium)begin
                    now_shop_info_u.medium_num = now_shop_info_u.medium_num-now_user_info_u.shop_history.item_num;
                    now_user_info_u.money = now_user_info_u.money+(now_user_info_u.shop_history.item_num*200);
                    re_shop_info_s.medium_num = re_shop_info_s.medium_num+now_user_info_u.shop_history.item_num;
                    re_user_info_s.money = re_user_info_s.money-(now_user_info_u.shop_history.item_num*200);
                end
                else begin
                    now_shop_info_u.small_num = now_shop_info_u.small_num-now_user_info_u.shop_history.item_num;
                    now_user_info_u.money = now_user_info_u.money+(now_user_info_u.shop_history.item_num*100);
                    re_shop_info_s.small_num = re_shop_info_s.small_num+now_user_info_u.shop_history.item_num;
                    re_user_info_s.money = re_user_info_s.money-(now_user_info_u.shop_history.item_num*100);
                end
                //golden_shopping_inf[now_sid] = now_shop_info_s;
                //golden_user_inf[now_sid] = now_user_info_s;
                golden_shopping_inf[now_user_info_u.shop_history.seller_ID] = re_shop_info_s;
                golden_user_inf[now_user_info_u.shop_history.seller_ID] = re_user_info_s;
                golden_shopping_inf[now_uid] = now_shop_info_u;
                golden_user_inf[now_uid] = now_user_info_u;
                //golden_complete = 1;
                //golden_out_info = {14'b0,re_shop_info_s.large_num,re_shop_info_s.medium_num,re_shop_info_s.small_num};
                //golden_err_msg = No_Err;
                id_num[now_user_info_u.shop_history.seller_ID] = id_num[now_user_info_u.shop_history.seller_ID]+1;
            end
        end
        else if(wi==1)begin
            if(buyer_can_re[now_uid]==0)begin
                golden_complete = 0;
                golden_out_info = 0;
                golden_err_msg = Wrong_act;
                //$display("buyer can't ");
            end
            else if(seller_can_be_re[now_user_info_u.shop_history.seller_ID]==0)begin
                golden_complete = 0;
                golden_out_info = 0;
                golden_err_msg = Wrong_act;
                //$display("seller can't");
                //$display("now return seller id %d",now_user_info_u.shop_history.seller_ID);
            end
            else if(b_table[now_user_info_u.shop_history.seller_ID]!=now_uid)begin
                golden_complete = 0;
                golden_out_info = 0;
                golden_err_msg = Wrong_act;
                //$display("buyer wromg");
            end           
            else if(now_user_info_u.shop_history.item_num!=(now_user_info_u.shop_history.item_num+2))begin
                golden_complete = 0;
                golden_out_info = 0;
                golden_err_msg = Wrong_Num;
            end
            else if(now_user_info_u.shop_history.item_ID!=(now_user_info_u.shop_history.item_ID+2))begin
                golden_complete = 0;
                golden_out_info = 0;
                golden_err_msg = Wrong_Item;
            end
            else begin
                if(now_user_info_u.shop_history.item_ID==Large)begin
                    now_shop_info_s.large_num = now_shop_info_s.large_num+now_user_info_u.shop_history.item_num;
                    now_shop_info_u.large_num = now_shop_info_u.large_num-now_user_info_u.shop_history.item_num;
                    now_user_info_s.money = now_user_info_s.money-(300*now_user_info_u.shop_history.item_num);
                    now_user_info_u.money = now_user_info_u.money+(300*now_user_info_u.shop_history.item_num);
                end
                else if(now_user_info_u.shop_history.item_ID==Medium)begin
                    now_shop_info_s.medium_num = now_shop_info_s.medium_num+now_user_info_u.shop_history.item_num;
                    now_shop_info_u.medium_num = now_shop_info_u.medium_num-now_user_info_u.shop_history.item_num;
                    now_user_info_s.money = now_user_info_s.money-(200*now_user_info_u.shop_history.item_num);
                    now_user_info_u.money = now_user_info_u.money+(200*now_user_info_u.shop_history.item_num);
                end
                else begin
                    now_shop_info_s.small_num = now_shop_info_s.small_num+now_user_info_u.shop_history.item_num;
                    now_shop_info_u.small_num = now_shop_info_u.small_num-now_user_info_u.shop_history.item_num;
                    now_user_info_s.money = now_user_info_s.money-(100*now_user_info_u.shop_history.item_num);
                    now_user_info_u.money = now_user_info_u.money+(100*now_user_info_u.shop_history.item_num);
                end
            end
            golden_shopping_inf[now_sid] = now_shop_info_s;
            golden_shopping_inf[now_uid] = now_shop_info_u;
            golden_user_inf[now_sid] = now_user_info_s;
            golden_user_inf[now_uid] = now_user_info_u;
            //golden_err_msg = No_Err;
            //golden_out_info = {14'b0,now_shop_info_s.large_num,now_shop_info_s.medium_num,now_shop_info_s.small_num};
            //golden_complete = 1;
            id_num[now_sid] = id_num[now_sid]+1;
        end
        else if(wi==2)begin
            if(buyer_can_re[now_uid]==0)begin
                golden_complete = 0;
                golden_out_info = 0;
                golden_err_msg = Wrong_act;
            end
            else if(seller_can_be_re[now_user_info_u.shop_history.seller_ID]==0)begin
                golden_complete = 0;
                golden_out_info = 0;
                golden_err_msg = Wrong_act;
            end
            else if(b_table[now_user_info_u.shop_history.seller_ID]!=now_uid)begin
                golden_complete = 0;
                golden_out_info = 0;
                golden_err_msg = Wrong_act;
            end
            else if(now_user_info_u.shop_history.seller_ID!=now_user_info_u.shop_history.seller_ID+2)begin
                golden_complete = 0;
                golden_out_info = 0;
                golden_err_msg = Wrong_ID;
            end
            /*else if(now_user_info_u.shop_history.item_ID!=(now_user_info_u.shop_history.item_ID+2))begin
                golden_complete = 0;
                golden_out_info = 0;
                golden_err_msg = Wrong_Item;
            end*/
            /*else if(now_user_info_u.shop_history.item_num!=(now_user_info_u.shop_history.item_num+2))begin
                golden_complete = 0;
                golden_out_info = 0;
                golden_err_msg = Wrong_Num;
            end*/
            else begin
                if(now_user_info_u.shop_history.item_ID==Large)begin
                    now_shop_info_u.large_num = now_shop_info_u.large_num-now_user_info_u.shop_history.item_num;
                    now_user_info_u.money = now_user_info_u.money+(now_user_info_u.shop_history.item_num*300);
                    re_shop_info_s.large_num = re_shop_info_s.large_num+now_user_info_u.shop_history.item_num;
                    re_user_info_s.money = re_user_info_s.money-(now_user_info_u.shop_history.item_num*300);
                end
                else if(now_user_info_u.shop_history.item_ID==Medium)begin
                    now_shop_info_u.medium_num = now_shop_info_u.medium_num-now_user_info_u.shop_history.item_num;
                    now_user_info_u.money = now_user_info_u.money+(now_user_info_u.shop_history.item_num*200);
                    re_shop_info_s.medium_num = re_shop_info_s.medium_num+now_user_info_u.shop_history.item_num;
                    re_user_info_s.money = re_user_info_s.money-(now_user_info_u.shop_history.item_num*200);
                end
                else begin
                    now_shop_info_u.small_num = now_shop_info_u.small_num-now_user_info_u.shop_history.item_num;
                    now_user_info_u.money = now_user_info_u.money+(now_user_info_u.shop_history.item_num*100);
                    re_shop_info_s.small_num = re_shop_info_s.small_num+now_user_info_u.shop_history.item_num;
                    re_user_info_s.money = re_user_info_s.money-(now_user_info_u.shop_history.item_num*100);
                end
            end
            golden_shopping_inf[now_user_info_u.shop_history.seller_ID] = re_shop_info_s;
            golden_user_inf[now_user_info_u.shop_history.seller_ID] = re_user_info_s;
            golden_shopping_inf[now_uid] = now_shop_info_u;
            golden_user_inf[now_uid] = now_user_info_u;
            //golden_complete = 1;
            //golden_out_info = {14'b0,re_shop_info_s.large_num,re_shop_info_s.medium_num,re_shop_info_s.small_num};
            //golden_err_msg = No_Err;
            id_num[now_user_info_u.shop_history.seller_ID] = id_num[now_user_info_u.shop_history.seller_ID]+1;
        end
        else begin
            if(buyer_can_re[now_uid]==0)begin
                golden_complete = 0;
                golden_out_info = 0;
                golden_err_msg = Wrong_act;
            end
            else if(seller_can_be_re[now_user_info_u.shop_history.seller_ID]==0)begin
                golden_complete = 0;
                golden_out_info = 0;
                golden_err_msg = Wrong_act;
            end
            else if(b_table[now_user_info_u.shop_history.seller_ID]!=now_uid)begin
                golden_complete = 0;
                golden_out_info = 0;
                golden_err_msg = Wrong_act;
            end
            else if(now_user_info_u.shop_history.seller_ID!=now_sid)begin
                golden_complete = 0;
                golden_out_info = 0;
                golden_err_msg = Wrong_ID;
            end
            else if(now_user_info_u.shop_history.item_num!=buy_how_many)begin
                golden_complete = 0;
                golden_out_info = 0;
                golden_err_msg = Wrong_Num;
            end
            else if(now_user_info_u.shop_history.item_ID!=(lms))begin
                golden_complete = 0;
                golden_out_info = 0;
                golden_err_msg = Wrong_Item;
            end
            
            /*else begin
                if(now_user_info_u.shop_history.item_ID==Large)begin
                    now_shop_info_u.large_num = now_shop_info_u.large_num-now_user_info_u.shop_history.item_num;
                    now_user_info_u.money = now_user_info_u.money+(now_user_info_u.shop_history.item_num*300);
                    re_shop_info_s.large_num = re_shop_info_s.large_num+now_user_info_u.shop_history.item_num;
                    re_user_info_s.money = re_user_info_s.money-(now_user_info_u.shop_history.item_num*300);
                end
                else if(now_user_info_u.shop_history.item_ID==Medium)begin
                    now_shop_info_u.medium_num = now_shop_info_u.medium_num-now_user_info_u.shop_history.item_num;
                    now_user_info_u.money = now_user_info_u.money+(now_user_info_u.shop_history.item_num*200);
                    re_shop_info_s.medium_num = re_shop_info_s.medium_num+now_user_info_u.shop_history.item_num;
                    re_user_info_s.money = re_user_info_s.money-(now_user_info_u.shop_history.item_num*200);
                end
                else begin
                    now_shop_info_u.small_num = now_shop_info_u.small_num-now_user_info_u.shop_history.item_num;
                    now_user_info_u.money = now_user_info_u.money+(now_user_info_u.shop_history.item_num*100);
                    re_shop_info_s.small_num = re_shop_info_s.small_num+now_user_info_u.shop_history.item_num;
                    re_user_info_s.money = re_user_info_s.money-(now_user_info_u.shop_history.item_num*100);
                end
            end*/
            golden_shopping_inf[now_user_info_u.shop_history.seller_ID] = re_shop_info_s;
            golden_user_inf[now_user_info_u.shop_history.seller_ID] = re_user_info_s;
            golden_shopping_inf[now_uid] = now_shop_info_u;
            golden_user_inf[now_uid] = now_user_info_u;
            //golden_complete = 1;
            //golden_out_info = {14'b0,re_shop_info_s.large_num,re_shop_info_s.medium_num,re_shop_info_s.small_num};
            //golden_err_msg = No_Err;
            id_num[now_user_info_u.shop_history.seller_ID] = id_num[now_user_info_u.shop_history.seller_ID]+1;
        end
        if(golden_complete==0) complete_num[0] = complete_num[0]+1;
        else complete_num[1] = complete_num[1]+1;
        id_num[now_uid] = id_num[now_uid]+1;
    end
    /*$display("golden ans %h",golden_out_info);
    $display("design ans %h",inf.out_info);
    $display("golden err msg : %d" ,golden_err_msg);
    $display("design err msg :%d",inf.err_msg);
    $display("golden complete %d", golden_complete);
    $display("design complete %d" ,inf.complete);
    $display("buy how many %d",buy_how_many);
    $display("user money  %d",golden_user_inf[now_uid].money);
    $display("wi %d",wi);
    $display("%d",buyer_can_re[now_uid]);
    $display("%d",seller_can_be_re[now_user_info_u.shop_history.seller_ID]);
    $display("%d",b_table[now_user_info_u.shop_history.seller_ID]);
    $display("%d",now_user_info_u.shop_history.seller_ID);
    $display("User level : %d",now_shop_info_u.level);*/
    if((inf.err_msg!=golden_err_msg)||(inf.complete!=golden_complete)||(inf.out_info!=golden_out_info)) you_wrong;
end
endtask

task finish_check;begin
    integer finish = 1;

    for(i=0;i<256;i=i+1)begin
        if(id_num[i]<id_threshold) finish = 0;
    end

    for(i=0;i<5;i=i+1)begin
        if(money_num[i]<money_threshold) finish = 0;
    end

    for (i=0;i<4;i=i+1)begin
        for(j=0;j<4;j=j+1)begin
            if (action_num[i][j]<action_threshold) finish= 0;
        end
    end
    
    for (i=0;i<2;i=i+1)begin
        if (complete_num[i]<complete_threshold) finish= 0;
    end

    for(i=0;i<7;i=i+1)begin
        if(err_num[i]<err_threshold) finish = 0;
    end

    for(i=0;i<3;i=i+1)begin
        if(lms_num[i]<lms_threshold) finish = 0;
    end

    if(finish)begin
        $finish;
    end
end
endtask

task wait_outvalid_task; begin
	while (inf.out_valid!==1) begin
		@(negedge clk);
	end
end 
endtask

task reset_task;begin
    @(negedge clk);
	inf.rst_n = 0;
	repeat(7)@(negedge clk);
	inf.rst_n = 1 ;
	release clk;
end 
endtask

task you_wrong;begin
   $display("Wrong Answer"); 
   $finish;
end
endtask
endprogram