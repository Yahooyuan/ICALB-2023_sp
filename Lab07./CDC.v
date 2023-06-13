`include "AFIFO.v"

module CDC #(parameter DSIZE = 8,
			   parameter ASIZE = 4)(
	//Input Port
	rst_n,
	clk1,
    clk2,
	in_valid,
    doraemon_id,
    size,
    iq_score,
    eq_score,
    size_weight,
    iq_weight,
    eq_weight,
    //Output Port
	ready,
    out_valid,
	out,
    
); 
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
output reg  [7:0] out;
output reg	out_valid,ready;

input rst_n, clk1, clk2, in_valid;
input  [4:0]doraemon_id;
input  [7:0]size;
input  [7:0]iq_score;
input  [7:0]eq_score;
input [2:0]size_weight,iq_weight,eq_weight;
//---------------------------------------------------------------------
//    PARAMETERS
//---------------------------------------------------------------------
parameter IDLE = 2'b00;
parameter IN_DATA1 =2'b01;
parameter OUT = 2'b10;
parameter DONE = 2'b11;
//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------
reg [7:0] door0,door1,door2,door3,door4;// 0-4:id 5-7:door number
reg [4:0] id0,id1,id2,id3,id4;
wire [4:0] i0,i1,i2,i3,i4;
reg [7:0] iq0,iq1,iq2,iq3,iq4;
reg [7:0] eq0,eq1,eq2,eq3,eq4;
reg [7:0] sz0,sz1,sz2,sz3,sz4;
reg [2:0] s_w,iq_w,eq_w;
reg [2:0] in_cnt;
reg [12:0] out_cnt;
reg [5:0] done_cnt;
reg [1:0] next_state,current_state;
reg [21:0] score0,score1,score2,score3,score4;
wire full;
wire empty;
reg [7:0] biggest;
reg [7:0] write_data;
wire [7:0] read_data;
reg rinc_o,winc_o;
reg winc_d;
reg fthflag;
reg [2:0] ze,on,tw,thr,fourr;
reg [7:0] buffer,buffer2;
wire [4:0] best_id;
wire [2:0] best_door;
reg d_valid;
reg  full_cnt,full_cnt2;
reg d_empt;
//---------------------------------------------------------------------
//   READY &&&&&&&&& control
//---------------------------------------------------------------------
always @(posedge clk1 or negedge rst_n) begin
    if(!rst_n) d_empt<=0;
    else d_empt<=empty;
end
always @(*) begin
    rinc_o = (!empty)&&(!d_empt);//&&ready
    //winc_o = (!full&&in_valid&&(out_cnt>5));
end
always @(posedge clk1 or negedge rst_n) begin
    if(!rst_n) d_valid<=0;
    else d_valid<=in_valid;
end
always @(posedge clk1 or negedge rst_n) begin
    if(!rst_n) winc_o<=0;
    else if((!full)&&d_valid&&(out_cnt>4)) winc_o<=1;
    else if((out_cnt>4)&&(d_valid==0)&&(!full)&&(full_cnt2||full_cnt))winc_o<=1;
    //else if((d_valid==0)&&(winc_o==1))winc_o<=0;
    //else if((out_cnt>4)&&(d_valid==0)&&(!full)&&(full_cnt))winc_o<=1;
    //else if((d_valid==0)&&(winc_o==1))winc_o=0;
    else winc_o<=0;
end
always @(*) begin
   winc_d = winc_o && (!full);
end

AFIFO fifo(.rst_n(rst_n),.rclk(clk2),.rinc(rinc_o),.wclk(clk1),.winc(winc_d),.wdata(buffer),.rempty(empty),.rdata(read_data),.wfull(full));

always @(posedge clk1 or negedge rst_n) begin
    if(!rst_n) buffer<=0;
    else if((!full)&&(d_valid)) buffer<=biggest;
    else if(full_cnt2) buffer<=biggest;
    //else  buffer<=buffer2;
end
/*always @(posedge clk1 or negedge rst_n) begin
    if(!rst_n) buffer2<=0;
    else if(current_state==OUT&&ready&&in_valid) buffer2<=buffer;
end*/
assign best_door = biggest[7:5];
assign best_id = biggest[4:0];
//---------------------------------------------------------------------
//   FSM
//---------------------------------------------------------------------
always @(posedge clk1 or negedge rst_n) begin
    if(!rst_n) current_state<=0;
    else current_state<=next_state;
end
always @(*) begin
    case(current_state)
    IDLE:begin
        if(in_valid) next_state = IN_DATA1;
        else next_state = IDLE;
    end
    IN_DATA1:begin
        if(in_cnt==4) next_state =OUT;
        else next_state = IN_DATA1;
    end
    OUT:begin
        if(out_cnt==6000)next_state = DONE;
        else next_state = OUT;
    end
    DONE:begin 
       if(done_cnt==18) next_state = IDLE;
       else next_state = DONE;
    end
    default:next_state = IDLE;
    endcase
end
//---------------------------------------------------------------------
//   COUNTER
//---------------------------------------------------------------------
always @(posedge clk1 or negedge rst_n) begin
    if(!rst_n) in_cnt<=0;
    else if(next_state==IN_DATA1)begin
    if(in_valid) in_cnt<=in_cnt+1;
    else if(in_cnt==4) in_cnt<=0;
    end
    else if(next_state==OUT) in_cnt<=0;
end
always @(posedge clk1 or negedge rst_n) begin
    if(!rst_n)out_cnt<=0;
    else if(in_valid) out_cnt<=out_cnt+1;
    //else if(out_cnt==6000&&!full) out_cnt<=0;
    //else if()
end
always @(posedge clk1 or negedge rst_n) begin
    if(!rst_n) done_cnt<=0;
    else if(next_state==DONE) done_cnt<=done_cnt+1;
end
always @(posedge clk1 or negedge rst_n) begin
    if(!rst_n) full_cnt<=0;
    else full_cnt<=full; 
end
always @(posedge clk1 or negedge rst_n) begin
    if(!rst_n) full_cnt2<=0;
    else full_cnt2<=full_cnt;
end
//---------------------------------------------------------------------
//   PUT　DATA INTO THE DOOR 
//---------------------------------------------------------------------
always @(posedge clk1 or negedge rst_n) begin/////////dora at door 0
   if(!rst_n)begin
        id0<=0;
        sz0<=0;
        iq0<=0;
        eq0<=0;
   end
   else if(in_valid&&(in_cnt==0)&&next_state==IN_DATA1)begin
        id0<=doraemon_id;
        sz0<=size;
        iq0<=iq_score;
        eq0<=eq_score;
   end
   else if(current_state==OUT&&in_valid&&(biggest==door0))begin
        id0<=doraemon_id;
        sz0<=size;
        iq0<=iq_score;
        eq0<=eq_score;
   end
end
always @(posedge clk1 or negedge rst_n) begin///////////dora at door 1
    if(!rst_n)begin
        id1<=0;
        sz1<=0;
        iq1<=0;
        eq1<=0;
    end
    else if(in_valid&&(in_cnt==1)&&next_state==IN_DATA1)begin
        id1<=doraemon_id;
        sz1<=size;
        iq1<=iq_score;
        eq1<=eq_score;
    end
    else if(current_state==OUT&&in_valid&&(biggest==door1))begin
        id1<=doraemon_id;
        sz1<=size;
        iq1<=iq_score;
        eq1<=eq_score;
    end
end
always @(posedge clk1 or negedge rst_n) begin
    if(!rst_n)begin
        id2<=0;
        sz2<=0;
        iq2<=0;
        eq2<=0;
    end
    else if(in_valid&&(in_cnt==2)&&next_state==IN_DATA1)begin
        id2<=doraemon_id;
        sz2<=size;
        iq2<=iq_score;
        eq2<=eq_score;
    end
    else if(current_state==OUT&&in_valid&&(biggest==door2))begin
        id2<=doraemon_id;
        sz2<=size;
        iq2<=iq_score;
        eq2<=eq_score;
    end
end
always @(posedge clk1 or negedge rst_n) begin
    if(!rst_n)begin
        id3<=0;
        sz3<=0;
        iq3<=0;
        eq3<=0;
    end
    else if(in_valid&&(in_cnt==3)&&next_state==IN_DATA1)begin
        id3<=doraemon_id;
        sz3<=size;
        iq3<=iq_score;
        eq3<=eq_score;
    end
    else if(current_state==OUT&&in_valid&&(biggest==door3))begin
        id3<=doraemon_id;
        sz3<=size;
        iq3<=iq_score;
        eq3<=eq_score;
    end
end
always @(posedge clk1 or negedge rst_n) begin
    if(!rst_n)begin
        id4<=0;
        sz4<=0;
        iq4<=0;
        eq4<=0;
    end
    else if(in_valid&&(in_cnt==4)&&current_state==IN_DATA1)begin
        id4<=doraemon_id;
        sz4<=size;
        iq4<=iq_score;
        eq4<=eq_score;
    end
    else if(current_state==OUT&&in_valid&&(biggest==door4))begin
        id4<=doraemon_id;
        sz4<=size;
        iq4<=iq_score;
        eq4<=eq_score;
    end
end
always @(posedge clk1 or negedge rst_n) begin
    if(!rst_n)begin
        eq_w<=0;
        iq_w<=0;
        s_w<=0;
    end
    else if(current_state==IN_DATA1&&in_cnt==4)begin
        eq_w<=eq_weight;
        iq_w<=iq_weight;
        s_w<=size_weight;
    end
    else if(current_state==OUT&&in_valid)begin
        eq_w<=eq_weight;
        iq_w<=iq_weight;
        s_w<=size_weight;
    
    end
end
//---------------------------------------------------------------------
//   PRE FIND PROCESS 
//---------------------------------------------------------------------
/*always @(posedge clk1 or negedge rst_n) begin
    if(!rst_n)begin
        ze<=0;
        on<=0;
        tw<=0;
        thr<=0;
        fourr<=0;
    end
    else begin
        ze<=3'b000;
        on<=3'b001;
        tw<=3'b010;
        thr<=3'b011;
        fourr<=3'b100;
    end
end*/
//assign i0 = id0;
//assign i1 = id1;
//assign i2 = id2;
//assign i3 = id3;
//assign i4 = id4;
always @(*) begin
    door0 = {3'b000,id0};
    door1 = {3'b001,id1};
    door2 = {3'b010,id2};
    door3 = {3'b011,id3};
    door4 = {3'b100,id4};
end

always @(*) begin
        score0=sz0*s_w+iq0*iq_w+eq0*eq_w;
        score1=sz1*s_w+iq1*iq_w+eq1*eq_w;
        score2=sz2*s_w+iq2*iq_w+eq2*eq_w;
        score3=sz3*s_w+iq3*iq_w+eq3*eq_w;
        score4=sz4*s_w+iq4*iq_w+eq4*eq_w;
end
always @(*) begin
        if((score0>=score1)&&(score0>=score2)&&(score0>=score3)&&(score0>=score4)) biggest<=door0;
        else if((score1>score0)&&(score1>=score2)&&(score1>=score3)&&(score1>=score4)) biggest<=door1;
        else if((score2>score0)&&(score2>score1)&&(score2>=score3)&&(score2>=score4))biggest<=door2;
        else if((score3>score0)&&(score3>score1)&&(score3>score2)&&(score3>=score4)) biggest<=door3;
        else  biggest<=door4;
    //if ((score4>score0)&&(score4>score1)&&(score4>score2)&&(score4>score3))
end
//---------------------------------------------------------------------
//   FIND　THE　LARGEST
//---------------------------------------------------------------------



//---------------------------------------------------------------------
//   OUT
//---------------------------------------------------------------------

always @(posedge clk2 or negedge rst_n) begin
    if(!rst_n) out_valid<=0;
    /*else if(current_state==DONE) out_valid<=rinc_o;
    else if(rinc_o) out_valid <= o1;
    else if(current_state==OUT&&empty==1) out_valid <= 0;
    else if(next_state==DONE) out_valid<=0;
    else if(current_state==IDLE) out_valid<=0;*/
    else out_valid<=rinc_o;
end

always @(posedge clk2 or negedge rst_n) begin
    if(!rst_n) out<=0;
    //else if(done_cnt==18) out<=0;
    else if(rinc_o) out <= read_data;
    //else if(current_state==OUT&&empty==1) out<=0;
    //else if(next_state==DONE) out<=0;
    //else if(current_state==IDLE) out<=0;
    else out<=0;
end

always @(*) begin
    if(current_state==IDLE) ready = 0;
    else if(out_cnt==6000||out_cnt==0||full_cnt||full_cnt2) ready=0;
    else ready=!full;
end

endmodule