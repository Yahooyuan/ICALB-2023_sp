module OS(input clk, INF.OS_inf inf);
import usertype::*;
//================================================================
// logic 
//================================================================
USER buyer_t,seller_t;
Action action;
Money depo_money,buyer_money,seller_money;
User_id buyer_id,seller_id;
Item_id lms;
Item_num_ext buy_how_many;
User_Level user_level,nu_level;
Item_num b_large,b_mid,b_small,s_large,s_mid,s_small;
USER buyer_f,seller_f;
Item_num nb_large,nb_mid,nb_small,ns_large,ns_mid,ns_small;
///////////////return money/////////////////////////////////////////
Money return_money;
User_id return_seller_id;
Item_id return_lms;
Item_num_ext return_buy_how_many;
Item_num rs_l,rs_m,rs_s;
////////////////////////////////////////////////////////////////////
EXP exp_earn;
EXP buyer_exp,nb_exp,fin_exp;
Money money_earn,money_cost,nbuy_mon,nsell_mon;
USER buyer,seller;
logic upgrade_flag;
logic[6:0] in_cnt;
logic ab_flag;// before or after act_valid (user or seller) pull up after act_valid
logic [1:0] user_cnt;//count how many user also in check can used to det seller or user
logic bors;//used to define CHECK want to check buyer or seller 0:buyer 1:seller
/////////////////return table/////////////////////////////////////////////////////
User_id b_table[0:255];
logic buyer_can_re[0:255];
logic seller_can_be_re[0:255];
//////////////////////////////////////////////////////////////////////////////////
logic err1,err2,err3,err4;/////CAL at CAL stage given value(to error message)at DET_ERROR
//================================================================
// parameters 
//================================================================
parameter FULL = 65535;
/////// NEEDED　EXP to upgraqde
parameter SILVER = 1000;
parameter GOLD = 2500;
parameter PLATINUM = 4000;
////////FEEEEEEEE
parameter FEE_PLA = 10;
parameter FEE_GOL = 30;
parameter FEE_SIL = 50;
parameter FEE_COP = 70;
/////PRICEEEEEEEEE
parameter PRICE_L = 300;
parameter PRICE_M = 200;
parameter PRICE_S = 100;
/////////EXPPPPPPPPPPP
parameter EXP_L = 60;
parameter EXP_M = 40;
parameter EXP_S = 20;

integer i,j,k;
//================================================================
// state 
//================================================================
typedef enum logic[3:0] { IDLE, IN_DATA, READ_D1, READ_D2, CAL, DETECT_ERR, UPDATE, WB_DRAM1,WB_DRAM2, OUT } state;
state current_state,next_state;
//================================================================
// IN DATA 
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) action<=0;
    else if(inf.act_valid) action<=inf.D.d_act[0];
end
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) depo_money<=0;
    else if(inf.amnt_valid) depo_money<=inf.D.d_money;
end
always_ff @(posedge clk or negedge inf.rst_n) begin 
    if(!inf.rst_n) lms<=0;
    else if(inf.item_valid) lms<=inf.D.d_item;
end
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) buy_how_many<=0;
    else if(inf.num_valid)buy_how_many<=inf.D.d_item_num;
end
/////// first user 
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) buyer_id<=0;
    else if(inf.id_valid&&(ab_flag==0)) buyer_id<=inf.D.d_id;
end
///////second user
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) seller_id<=0;
    else if(inf.id_valid&&(ab_flag==1)) seller_id<=inf.D.d_id;
end
//================================================================
// COUNTER  && FLAG
//================================================================
always_ff@(posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n) in_cnt<=0;
    else if(next_state==IN_DATA) in_cnt<=in_cnt+1;
    else in_cnt<=0;
end
always_ff@(posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n) user_cnt<=0;
    else if(inf.id_valid) user_cnt<=user_cnt+1;
    else if(current_state==OUT)user_cnt<=0;
end
always_ff@(posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n)ab_flag<=0;
    else if(inf.act_valid)ab_flag<=1;
    else if(current_state==OUT) ab_flag<=0;
end
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)bors<=0;
    else if(ab_flag==1&&inf.id_valid) bors<=1;
    else if(current_state==IDLE)bors<=0;
end
//================================================================
//   RETURN TABLE
//================================================================
always_ff @( posedge clk or negedge inf.rst_n) begin //////Record the buyer who buy to current seller
    if(!inf.rst_n)begin
        for(i=0;i<256;i=i+1) b_table[i]<=0;
    end
    else if(action==Buy&&(current_state==IDLE)&&inf.complete)begin
            //b_table[buyer_id]<=seller_id;
            b_table[seller_id]<=buyer_id;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        for(j=0;j<256;j=j+1) buyer_can_re[j]<=0;
    end
    else if((current_state==IDLE)&&inf.complete)begin
        case(action)
        Buy:begin
            buyer_can_re[buyer_id]<=1;
            buyer_can_re[seller_id]<=0;
        end
        Check:begin
            if(bors)begin
                buyer_can_re[buyer_id]<=0;
                buyer_can_re[seller_id]<=0;
            end
            else buyer_can_re[buyer_id]<=0;
        end
        Deposit:begin
            buyer_can_re[buyer_id]<=0;
        end
        Return:begin
            buyer_can_re[buyer_id]<=0;
            buyer_can_re[seller_id]<=0;
        end
        endcase
    end
end
/////return seller valid table buyer store seller info
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)begin
        for(k=0;k<256;k=k+1) seller_can_be_re[k]<=0;
    end
    else if((current_state==IDLE)&&inf.complete)begin
        case(action)
        Buy:begin
            seller_can_be_re[buyer_id]<=0;
            seller_can_be_re[seller_id]<=1;
        end
        Check:begin
            if(bors)begin
                seller_can_be_re[buyer_id]<=0;
                seller_can_be_re[seller_id]<=0;
            end
            else seller_can_be_re[buyer_id]<=0;
        end
        Deposit:seller_can_be_re[buyer_id]<=0;
        Return:begin
            seller_can_be_re[buyer_id]<=0;
            seller_can_be_re[seller_id]<=0;
        end
        endcase
    end
end
///// two users: BUY CHECK(maybe) one user doposit
/*always_ff @(posedge clk or negedge inf.rst_n) begin : blockName
    if(!inf.rst_n)begin
         for(j=0;j<256;j=j+1) re_bvalid_table[j]<=0;
    end
    else if(action==Buy&&(current_state==OUT))begin
        if(!(err1||err2||err3||err4)) begin
          re_bvalid_table[buyer_id]<=1;
          re_bvalid_table[seller_id]<=0;
        end
    end
    //sb_table[sb_table[buyer_id]] && sb_table[buyer_id] both can't be same as buyer_id;
    else if((action==Check)&&(current_state==OUT))begin///// if check seller or buyer turned valid to 0
        //if((buyer_id==sb_table[buyer_id])||(buyer_id==sb_table[seller_id])) re_valid_table[buyer_id]<=0;
        if((buyer_id==sb_table[buyer_id])||(buyer_id==sb_table[sb_table[buyer_id]])) re_valid_table[buyer_id]<=0;
        //else if((seller_id==sb_table[buyer_id])||(seller_id==sb_table[seller_id])) re_valid_table[seller_id]<=0;
        else if((seller_id==sb_table[seller_id])||(seller_id==sb_table[sb_table[seller_id]])) re_valid_table[seller_id]<=0;
    end
    else if((action==Deposit)&&(current_state==OUT))begin
        if((buyer_id==sb_table[buyer_id])||(buyer_id==sb_table[sb_table[buyer_id]])) re_valid_table[buyer_id]<=0;
    end
    else if(action==Return&&(current_state==OUT)&&((err1||err2||err3||err4)==0))begin
        sb_table[buyer_id]<=0;
        sb_table[seller_id]<=0;
    end
end*/
//================================================================
//   CAL
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) exp_earn<=0;
    else if(action==Buy&&next_state==CAL&&(user_level!=Platinum))begin
        case(lms)
        Large:exp_earn<=EXP_L*buy_how_many;
        Medium:exp_earn<=EXP_M*buy_how_many;
        Small:exp_earn<=EXP_S*buy_how_many;
        default:exp_earn<=0;
        endcase
    end
    else if(user_level==Platinum) exp_earn<=0;
    else if(current_state==OUT) exp_earn<=0;
end
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) money_cost<=0;
    else if(action==Buy&&next_state==CAL)begin
        case(lms)
        Large:begin
            if(user_level==Platinum) money_cost<=PRICE_L*buy_how_many+FEE_PLA;
            else if(user_level==Gold) money_cost<=PRICE_L*buy_how_many+FEE_GOL;
            else if(user_level==Silver) money_cost<=PRICE_L*buy_how_many+FEE_SIL;
            else if(user_level==Copper)money_cost<=PRICE_L*buy_how_many+FEE_COP;
        end
        Medium:begin
            if(user_level==Platinum) money_cost<=PRICE_M*buy_how_many+FEE_PLA;
            else if(user_level==Gold) money_cost<=PRICE_M*buy_how_many+FEE_GOL;
            else if(user_level==Silver) money_cost<=PRICE_M*buy_how_many+FEE_SIL;
            else if(user_level==Copper)money_cost<=PRICE_M*buy_how_many+FEE_COP;
        end
        Small:begin
            if(user_level==Platinum) money_cost<=PRICE_S*buy_how_many+FEE_PLA;
            else if(user_level==Gold) money_cost<=PRICE_S*buy_how_many+FEE_GOL;
            else if(user_level==Silver) money_cost<=PRICE_S*buy_how_many+FEE_SIL;
            else if(user_level==Copper)money_cost<=PRICE_S*buy_how_many+FEE_COP;
        end
        default:money_cost<=0;
        endcase
    end
end
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) money_earn<=0;
    else if(action==Buy&&next_state==CAL)begin
        case(lms)
        Large:money_earn<=PRICE_L*buy_how_many;
        Medium:money_earn<=PRICE_M*buy_how_many;
        Small:money_earn<=PRICE_S*buy_how_many;
        default:money_earn<=0;
        endcase
    end
end
////////////////////////////////////
///Return //////////////////////////
////////////////////////////////////
//Return money 
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) return_money<=0;
    else if(action==Return&&next_state==CAL)begin
        case(buyer_t.user_info.shop_history.item_ID)
        Large:return_money<=buyer_t.user_info.shop_history.item_num*PRICE_L;
        Medium:return_money<=buyer_t.user_info.shop_history.item_num*PRICE_M;
        Small:return_money<=buyer_t.user_info.shop_history.item_num*PRICE_S;
        endcase
    end
end
//////////// Return buyer money


/////////// Return seller money

/////////// Return buyer stock Large Medium Small

////////// Return seller stock Large Medium Small
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)begin
        rs_l<=0;
        rs_m<=0;
        rs_s<=0;
    end
    else if(action==Return&&current_state==CAL)begin
        case(return_lms)
        Large:begin
            rs_l<=s_large+return_buy_how_many;
            rs_m<=s_mid;
            rs_s<=s_small;
        end
        Medium:begin
            rs_l<=s_large;
            rs_m<=s_mid+return_buy_how_many;
            rs_s<=s_small;
        end
        Small:begin
            rs_l<=s_large;
            rs_m<=s_mid;
            rs_s<=s_small+return_buy_how_many;
        end
        endcase
    end
end
//assign return_seller_id = buyer_t.user_info.shop_history.seller_ID;
assign return_lms = buyer_t.user_info.shop_history.item_ID;
assign return_buy_how_many = buyer_t.user_info.shop_history.item_num;
/////// new level
always_comb begin
    if(user_level==Copper)begin
        if(nb_exp>=SILVER)begin
             nu_level=Silver;
             upgrade_flag=1;
        end
        else  begin
            nu_level = Copper;
            upgrade_flag=0;
        end
    end
    else if(user_level==Silver)begin
        if(nb_exp>=GOLD)begin
             nu_level = Gold;
             upgrade_flag = 1;
        end
        else begin
             nu_level = Silver;
             upgrade_flag = 0;
        end
    end
    else if(user_level==Gold)begin
        if(nb_exp>=PLATINUM)begin
            nu_level = Platinum;
            upgrade_flag = 1;
        end
        else begin
            nu_level = Gold;
            upgrade_flag = 0;
        end
    end
    else begin
        nu_level = Platinum;
        upgrade_flag = 0;
    end
end
////// new exp
//assign nb_exp = buyer_exp+exp_earn;
always_comb begin
    if(user_level==Copper)begin
        if((SILVER-buyer_exp)<=exp_earn) nb_exp = SILVER;
        else nb_exp = buyer_exp+exp_earn;
    end
    else if(user_level==Silver)begin
        if((GOLD-buyer_exp)<=exp_earn) nb_exp = GOLD;
        else nb_exp = buyer_exp+exp_earn;
    end
    else if(user_level==Gold)begin
        if((PLATINUM-buyer_exp)<=exp_earn) nb_exp = PLATINUM;
        else nb_exp = buyer_exp+exp_earn;
    end
    else nb_exp = 0;
end
always_comb begin
    if(upgrade_flag) fin_exp = 0;
    else fin_exp = nb_exp;
end
////// new money
assign nbuy_mon =(buyer_money>=money_cost)? buyer_money-money_cost:buyer_money;
assign nsell_mon =(seller_money==FULL)?seller_money:(((FULL-seller_money)<money_earn))?FULL:seller_money+money_earn;
/////new stock
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        nb_large<=0;
        nb_mid<=0;
        nb_small<=0;
    end
    else if(action==Buy&&next_state==CAL)begin
        if(lms==Large) begin
            nb_large <= b_large+buy_how_many;
            nb_mid <= b_mid;
            nb_small<=b_small;
        end
        else if(lms==Medium)begin
            nb_large<=b_large;
            nb_mid<=b_mid+buy_how_many;
            nb_small<=b_small;
        end
        else if(lms==Small)begin
            nb_large<=b_large;
            nb_mid<=b_mid;
            nb_small<=b_small+buy_how_many;
        end
    end
    else if(action==Return&&next_state==CAL)begin
        case(return_lms)
        Large:begin
            nb_large<=b_large-return_buy_how_many;
            nb_mid <= b_mid;
            nb_small<=b_small;
        end
        Medium:begin
            nb_large<=b_large;
            nb_mid<=b_mid-return_buy_how_many;
            nb_small<=b_small;
        end
        Small:begin
            nb_large<=b_large;
            nb_mid<=b_mid;
            nb_small<=b_small-return_buy_how_many;
        end
        endcase
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)begin
        ns_large<=0;
        ns_mid<=0;
        ns_small<=0;
    end
    else if(lms==Large)begin
        ns_large<=s_large-buy_how_many;
        ns_mid<=s_mid;
        ns_small<=s_small;
        end
        else if(lms==Medium)begin
        ns_large<=s_large;
        ns_mid<=s_mid-buy_how_many;
        ns_small<=s_small;
        end
        else if(lms==Small)begin
        ns_large<=s_large;
        ns_mid<=s_mid;
        ns_small<=s_small-buy_how_many;
        end
    
end
//================================================================
//   FSM
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin 
    if(!inf.rst_n) current_state<= IDLE;
    else current_state<=next_state;
end

always_comb begin 
    case(current_state)
    IDLE:begin
        if(inf.id_valid||inf.act_valid) next_state = IN_DATA;
        else next_state = IDLE;
    end
    IN_DATA:begin
        if(in_cnt==25) next_state = READ_D1;
        //else if(in_cnt==30&&(bors&&user_cnt==1)) next_state = READ_D2;
        else next_state = IN_DATA; 
    end
    READ_D1:begin
        //if(inf.C_out_valid&&user_cnt==1) next_state = CAL;
        if(inf.C_out_valid) next_state = READ_D2;
        else next_state = READ_D1;
    end
    READ_D2:begin
        if(inf.C_out_valid) next_state = CAL;
        else next_state = READ_D2;
    end
    CAL:begin
        next_state = DETECT_ERR;
    end
    DETECT_ERR:begin
        if((err1||err2||err3||err4)) next_state = OUT;
        else next_state = UPDATE;
    end
    UPDATE:begin
        if(action!=Check) next_state = WB_DRAM1;
        else next_state = OUT;
    end
    WB_DRAM1:begin
        if(inf.C_out_valid&&(action==Deposit)) next_state = OUT;
        else if(inf.C_out_valid&&((action==Buy)||(action==Return))) next_state = WB_DRAM2;
        else next_state = WB_DRAM1;
    end
    WB_DRAM2:begin
        if(inf.C_out_valid) next_state = OUT;
        else next_state = WB_DRAM2;
    end
    OUT:begin
        next_state = IDLE;
    end
    default:next_state = IDLE;
    endcase
end
//================================================================
//   DRAM
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) inf.C_r_wb<=0;
    else if(next_state==READ_D1||next_state==READ_D2) inf.C_r_wb<=1;
    else inf.C_r_wb<=0;
end
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) inf.C_in_valid<=0;
    else if((next_state==READ_D1&&(current_state!=READ_D1))||(next_state==READ_D2&&(current_state!=READ_D2))||(next_state==WB_DRAM1&&(current_state!=WB_DRAM1))||(next_state==WB_DRAM2&&(current_state!=WB_DRAM2))) inf.C_in_valid<=1;
    else inf.C_in_valid<=0;
end

always_comb begin
    if(current_state==WB_DRAM1) inf.C_data_w = {buyer_f[7:4],buyer_f[3:0],buyer_f[15:12],buyer_f[11:8],buyer_f[23:20],buyer_f[19:16],buyer_f[31:28],buyer_f[27:24],buyer_f[39:36],buyer_f[35:32],buyer_f[47:44],buyer_f[43:40],buyer_f[55:52],buyer_f[51:48],buyer_f[63:60],buyer_f[59:56]};
    else if(current_state==WB_DRAM2) inf.C_data_w = {seller_f[7:4],seller_f[3:0],seller_f[15:12],seller_f[11:8],seller_f[23:20],seller_f[19:16],seller_f[31:28],seller_f[27:24],seller_f[39:36],seller_f[35:32],seller_f[47:44],seller_f[43:40],seller_f[55:52],seller_f[51:48],seller_f[63:60],seller_f[59:56]};
    else inf.C_data_w = 0;
end
always_comb begin
    if(current_state==READ_D1) inf.C_addr = buyer_id;
    else if(current_state==READ_D2) inf.C_addr = seller_id;
    else if(current_state==WB_DRAM1) inf.C_addr = buyer_id;
    else if(current_state==WB_DRAM2) inf.C_addr = seller_id;
    else inf.C_addr = 0;
end
////buyer information
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) buyer<=0;
    else if(current_state==READ_D1&&(inf.C_out_valid)) buyer<=inf.C_data_r;
end
always_comb begin
    buyer_t = {buyer[7:4],buyer[3:0],buyer[15:12],buyer[11:8],buyer[23:20],buyer[19:16],buyer[31:28],buyer[27:24],buyer[39:36],buyer[35:32],buyer[47:44],buyer[43:40],buyer[55:52],buyer[51:48],buyer[63:60],buyer[59:56]};
end
assign buyer_money = buyer_t.user_info.money;
assign user_level = buyer_t.shop_info.level;
assign buyer_exp = buyer_t.shop_info.exp;
assign b_large = buyer_t.shop_info.large_num;
assign b_mid = buyer_t.shop_info.medium_num;
assign b_small = buyer_t.shop_info.small_num;
/// seller information 
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) seller<=0;
    else if(current_state==READ_D2&&(inf.C_out_valid)) seller<=inf.C_data_r;
end
always_comb begin
    seller_t = {seller[7:4],seller[3:0],seller[15:12],seller[11:8],seller[23:20],seller[19:16],seller[31:28],seller[27:24],seller[39:36],seller[35:32],seller[47:44],seller[43:40],seller[55:52],seller[51:48],seller[63:60],seller[59:56]};
end
assign seller_money = seller_t.user_info.money;
assign s_large = seller_t.shop_info.large_num;
assign s_mid = seller_t.shop_info.medium_num;
assign s_small = seller_t.shop_info.small_num;
//================================================================
//   errrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        err1<=0;
        err2<=0;
        err3<=0;
        err4<=0;
    end
    else if(next_state==DETECT_ERR)begin
        case(action)
        Buy:begin
            if((lms==Large&&((63-b_large)<buy_how_many))||(lms==Medium&&((63-b_mid)<buy_how_many))||(lms==Small&&((63-b_small)<buy_how_many))) err1<=1;
            else if((lms==Large&&(s_large<buy_how_many))||(lms==Medium&&(s_mid<buy_how_many))||(lms==Small&&(s_small<buy_how_many))) err2<=1;
            //else if((lms==Large&&(63-b_large)<buy_how_many)||(lms==Medium&&(63-b_mid)<buy_how_many)||(lms==Small&&(63-b_small)<buy_how_many)) err2<=1;
            else if(buyer_money<money_cost) err3<=1;
            err4<=0;
        end
        Deposit: begin
            if((FULL-buyer_t.user_info.money)<depo_money) err1<=1;
            err2<=0;
            err3<=0;
            err4<=0;
        end
        Return:begin
            if(buyer_can_re[buyer_id]==0||((seller_can_be_re[buyer_t.user_info.shop_history.seller_ID]==0)||(b_table[buyer_t.user_info.shop_history.seller_ID]!=buyer_id))) err1<=1;//||(b_table[seller_id]!=buyer_id)
            else if((b_table[seller_id]!=buyer_id)||(buyer_t.user_info.shop_history.seller_ID!=seller_id)) err2<=1;//(b_table[seller_id]!=buyer_id)||
            else if(return_buy_how_many!=buy_how_many) err3<=1;
            else if(return_lms!=lms) err4<=1;
        end
        default:begin
        err1<=0;
        err2<=0;
        err3<=0;
        err4<=0;
        end
        endcase
    end
    else if(current_state==IDLE)begin
        err1<=0;
        err2<=0;
        err3<=0;
        err4<=0;
    end
end
//================================================================
//   UPDATE
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) buyer_f<=0;
    else if(current_state==UPDATE)begin
    case(action)
    Buy:begin
        buyer_f.shop_info.large_num<=nb_large;
        buyer_f.shop_info.medium_num<=nb_mid;
        buyer_f.shop_info.small_num<=nb_small;
        buyer_f.shop_info.level<=nu_level;
        buyer_f.shop_info.exp<=fin_exp;
        buyer_f.user_info.money<=nbuy_mon;
        buyer_f.user_info.shop_history.item_ID<=lms;
        buyer_f.user_info.shop_history.item_num<=buy_how_many;
        buyer_f.user_info.shop_history.seller_ID<=seller_id;
    end
    Deposit:begin
        buyer_f.shop_info.large_num<=buyer_t.shop_info.large_num;
        buyer_f.shop_info.medium_num<=buyer_t.shop_info.medium_num;
        buyer_f.shop_info.small_num<=buyer_t.shop_info.small_num;
        buyer_f.shop_info.level<=buyer_t.shop_info.level;
        buyer_f.shop_info.exp<=buyer_t.shop_info.exp;
        buyer_f.user_info.money<=buyer_t.user_info.money+depo_money;
        buyer_f.user_info.shop_history.item_ID<=buyer_t.user_info.shop_history.item_ID;
        buyer_f.user_info.shop_history.item_num<=buyer_t.user_info.shop_history.item_num;
        buyer_f.user_info.shop_history.seller_ID<=buyer_t.user_info.shop_history.seller_ID;
    end
    Return:begin
        buyer_f.shop_info.large_num<=nb_large;
        buyer_f.shop_info.medium_num<=nb_mid;
        buyer_f.shop_info.small_num<=nb_small;
        buyer_f.shop_info.level<=buyer_t.shop_info.level;
        buyer_f.shop_info.exp<=buyer_t.shop_info.exp;
        buyer_f.user_info.money<=buyer_t.user_info.money+return_money;
        buyer_f.user_info.shop_history.item_ID<=buyer_t.user_info.shop_history.item_ID;
        buyer_f.user_info.shop_history.item_num<=buyer_t.user_info.shop_history.item_num;
        buyer_f.user_info.shop_history.seller_ID<=buyer_t.user_info.shop_history.seller_ID;
    end
    endcase
    end
end
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) seller_f<=0;
    else if(current_state==UPDATE)begin
        case(action)
        Buy:begin
            seller_f.shop_info.large_num<=ns_large;
            seller_f.shop_info.medium_num<=ns_mid;
            seller_f.shop_info.small_num<=ns_small;
            seller_f.shop_info.level<=seller_t.shop_info.level;
            seller_f.shop_info.exp<=seller_t.shop_info.exp;
            seller_f.user_info.money<=nsell_mon;
            seller_f.user_info.shop_history.item_ID<=seller_t.user_info.shop_history.item_ID;
            seller_f.user_info.shop_history.item_num<=seller_t.user_info.shop_history.item_num;
            seller_f.user_info.shop_history.seller_ID<=seller_t.user_info.shop_history.seller_ID;
        end
        Return:begin
            seller_f.shop_info.large_num<=rs_l;
            seller_f.shop_info.medium_num<=rs_m;
            seller_f.shop_info.small_num<=rs_s;
            seller_f.shop_info.level<=seller_t.shop_info.level;
            seller_f.shop_info.exp<=seller_t.shop_info.exp;
            seller_f.user_info.money<=seller_t.user_info.money-return_money;
            seller_f.user_info.shop_history.item_ID<=seller_t.user_info.shop_history.item_ID;
            seller_f.user_info.shop_history.item_num<=seller_t.user_info.shop_history.item_num;
            seller_f.user_info.shop_history.seller_ID<=seller_t.user_info.shop_history.seller_ID;
        end
        endcase
    end
end
//================================================================
//   OUT
//================================================================
always_ff@(posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n)inf.out_valid<=0;
    else if(current_state==OUT) inf.out_valid<=1;
    else inf.out_valid<=0;
end

always_ff@(posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n) inf.out_info<=0;
    else if(current_state==OUT)begin
        case(action)
        Buy:begin
            if(err1||err2||err3) inf.out_info<=0;
            else  inf.out_info<=buyer_f.user_info;
        end
        Deposit:begin
            if(err1) inf.out_info<=0;
            else inf.out_info<={16'b0,buyer_f.user_info.money};
        end
        Check:begin
            if(bors) inf.out_info<={14'b0,seller_t.shop_info.large_num,seller_t.shop_info.medium_num,seller_t.shop_info.small_num};
            else inf.out_info<={16'b0,buyer_t.user_info.money};
        end
        Return:begin
            if(err1||err2||err3||err4) inf.out_info<=0;
            else inf.out_info<={14'b0,buyer_f.shop_info.large_num,buyer_f.shop_info.medium_num,buyer_f.shop_info.small_num};
        end
        endcase
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin 
    if(!inf.rst_n) inf.err_msg<=0;
    else if(current_state==OUT)begin
        case(action)
            Buy:begin
                if(err1) inf.err_msg <= INV_Full;
                else if(err2) inf.err_msg <= INV_Not_Enough;
                else if(err3) inf.err_msg <= Out_of_money;
                else inf.err_msg <= 0;
            end
            Deposit:begin
                if(err1) inf.err_msg<=Wallet_is_Full;
                else inf.err_msg<=0;
            end
            Return:begin
                if(err1) inf.err_msg<=Wrong_act;
                else if(err2) inf.err_msg<=Wrong_ID;
                else if(err3)inf.err_msg<=Wrong_Num;
                else if(err4) inf.err_msg<=Wrong_ID;
                else inf.err_msg<=0;
            end
            default:inf.err_msg<=0;
        endcase
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin 
    if(!inf.rst_n) inf.complete<=0;
    else if(current_state==OUT)begin
        case(action)
        Buy:begin
            if(err1||err2||err3) inf.complete<=0;
            else inf.complete<=1;
        end
        Deposit:begin
            if(err1) inf.complete<=0;
            else inf.complete<=1;
        end
        Check:begin
            inf.complete<=1;
        end
        Return:begin
            if(err1||err2||err3||err4) inf.complete<=0;
            else inf.complete<=1;
        end
        endcase
    end
    else inf.complete<=0;
end


endmodule