// synopsys translate_off
`ifdef RTL
	`include "GATED_OR.v"
`else
	`include "Netlist/GATED_OR_SYN.v"
`endif
// synopsys translate_on

module SNN(
	// Input signals
	clk,
	rst_n,
	cg_en,
	in_valid,
	img,
	ker,
	weight,

	// Output signals
	out_valid,
	out_data
);

input clk;
input rst_n;
input in_valid;
input cg_en;
input [7:0] img;
input [7:0] ker;
input [7:0] weight;

output reg out_valid;
output reg [9:0] out_data;

//==============================================//
//       parameter & integer declaration        //
//==============================================//
parameter IDLE = 4'b0000;
parameter IN_DATA = 4'b0001;
parameter CONV = 4'b0010;
parameter QUAN = 4'b0011;
parameter MAX_P = 4'b0100;
parameter F_C = 4'b0101;
parameter L1_D = 4'b0110;
parameter ACTIVE = 4'b0111;
parameter OUT = 4'b1000;

//parameter donw1 = 2295;
//parameter down2 = 510;
integer i;
//==============================================//
//           reg & wire declaration             //
//==============================================//
reg [3:0] current_state,next_state;
wire conv_done,quan_done,mp_done,fc_done,l1_done,ac_done;
reg conv_start,quan_start,mp_start,fc_start,l1_start,ac_start;
reg [7:0] in_cnt;
reg [1:0] matrix_cnt;
reg [7:0] m_in[0:71];//0~35 is matrix 1 //36~71 is matrix 2
reg [7:0] kernel [0:8];
reg [7:0] w[0:3];
reg [7:0] nn1,nn2,nn3,nn4,nn5,nn6,nn7,nn8;//put fully connected output here
///CONV in
reg [7:0] c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16,c17,c18,c19,c20,c21,c22,c23,c24,c25,c26,c27,c28,c29,c30,c31,c32,c33,c34,c35,c36;
///CONV out quan in
wire [19:0] q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,q13,q14,q15,q16;
//QUAN out max_pooling in
wire [7:0] mp1,mp2,mp3,mp4,mp5,mp6,mp7,mp8,mp9,mp10,mp11,mp12,mp13,mp14,mp15,mp16;
//// max_pooling out fully connected in
wire [7:0] fc1,fc2,fc3,fc4;
///fully connected out NN OUT
wire [7:0] snn1,snn2,snn3,snn4;
wire [9:0] fo,l1o;
reg sleep_in,sleep_conv,sleep_quan,sleep_mp,sleep_fc,sleep_l1,sleep_ac,sleep_out;
wire g_clock_in,g_clock_conv,g_clock_quan,g_clock_mp,g_clock_fc,g_clock_l1,g_clock_ac,g_clock_out;
//==============================================//
//                 GATED_OR                     //
//==============================================//
GATED_OR GATED_IN(.CLOCK(clk),.SLEEP_CTRL(sleep_in),.RST_N(rst_n),.CLOCK_GATED(g_clock_in));
GATED_OR GATED_CONV(.CLOCK(clk),.SLEEP_CTRL(sleep_conv),.RST_N(rst_n),.CLOCK_GATED(g_clock_conv));
GATED_OR GATED_QUAN(.CLOCK(clk),.SLEEP_CTRL(sleep_quan),.RST_N(rst_n),.CLOCK_GATED(g_clock_quan));
GATED_OR GATED_MP(.CLOCK(clk),.SLEEP_CTRL(sleep_mp),.RST_N(rst_n),.CLOCK_GATED(g_clock_mp));
GATED_OR GATED_FC(.CLOCK(clk),.SLEEP_CTRL(sleep_fc),.RST_N(rst_n),.CLOCK_GATED(g_clock_fc));
GATED_OR GATED_L1(.CLOCK(clk),.SLEEP_CTRL(sleep_l1),.RST_N(rst_n),.CLOCK_GATED(g_clock_l1));
GATED_OR GATED_AC(.CLOCK(clk),.SLEEP_CTRL(sleep_ac),.RST_N(rst_n),.CLOCK_GATED(g_clock_ac));
GATED_OR GATED_OUT(.CLOCK(clk),.SLEEP_CTRL(sleep_out),.RST_N(rst_n),.CLOCK_GATED(g_clock_out));

always @(*) begin
	if(!cg_en) sleep_in = 0;
	else begin
		if((current_state!=IN_DATA)&&(next_state!=IDLE)) sleep_in = 1;
		else sleep_in = 0;
	end
end
always @(*) begin
	if(!cg_en) sleep_conv = 0;
	else begin
		if(next_state!=CONV&&(current_state!=CONV)) sleep_conv = 1;
		else sleep_conv = 0;
	end
end
always @(*) begin
	if(!cg_en) sleep_quan = 0;
	else begin
		if(next_state!=QUAN&&(current_state!=QUAN)) sleep_quan = 1;
		else sleep_quan = 0;
	end
end
always @(*) begin
	if(!cg_en) sleep_mp = 0;
	else begin
		if(next_state!=MAX_P&&(current_state!=MAX_P)) sleep_mp = 1;
		else sleep_mp = 0;
	end
end
always @(*) begin
	if(!cg_en) sleep_fc = 0;
	else begin
		if(next_state!=F_C&&(current_state!=F_C)) sleep_fc = 1;
		else sleep_fc = 0;
	end
end
always @(*) begin
	if(!cg_en) sleep_l1 = 0;
	else begin
		if(next_state!=L1_D&&(current_state!=L1_D)) sleep_l1 = 1;
		else sleep_l1 = 0;
	end
end
always @(*) begin
	if(!cg_en) sleep_ac = 0;
	else begin
		if(next_state!=ACTIVE&&(current_state!=ACTIVE)) sleep_ac = 1;
		else sleep_ac = 0;
	end
end
always @(*) begin
	if(!cg_en) sleep_out = 0;
	else begin
		if(current_state!=OUT&&current_state!=IDLE) sleep_out = 1;
		else sleep_out = 0;
	end
end
//==============================================//
//                  design                      //
//==============================================//
////////////  counter//////////////////////
//conv
always @(posedge g_clock_conv or negedge rst_n) begin
	if(!rst_n) conv_start<=0;
	else if(next_state==CONV) conv_start<=1;
	else  conv_start<=0;
end
//quan
always @(posedge g_clock_quan or negedge rst_n) begin
	if(!rst_n) quan_start<=0;
	else if(next_state==QUAN) quan_start<=1;
	else quan_start<=0;
end
//max_pooling
always @(posedge g_clock_mp or negedge rst_n) begin
	if(!rst_n) mp_start<=0;
	else if(next_state==MAX_P) mp_start<=1;
	else mp_start<=0;
end
//fully connected
always @(posedge g_clock_fc or negedge rst_n) begin
	if(!rst_n) fc_start<=0;
	else if(next_state==F_C) fc_start<=1;
	else fc_start<=0;
end
//L1 DISTANCE
always @(posedge g_clock_l1 or negedge rst_n) begin
	if(!rst_n) l1_start<=0;
	else if(next_state==L1_D) l1_start<=1;
	else l1_start<=0;
end
//ACTIVATION
always @(posedge g_clock_ac or negedge rst_n) begin
	if(!rst_n) ac_start<=0;
	else if(next_state==ACTIVE) ac_start<=1;
	else ac_start<=0;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) matrix_cnt<=0;
	else if(current_state==MAX_P&&(next_state==MAX_P)) matrix_cnt<=matrix_cnt+1;
	else if(current_state==L1_D) matrix_cnt<=0;
end
//////////////   INPUT   /////////////////////////
always @(posedge g_clock_in or negedge rst_n) begin
	if(!rst_n) in_cnt<=0;
	else if(in_cnt==71) in_cnt<=0;
	else if(in_valid) in_cnt<=in_cnt+1;
	//else in_cnt<=0;
end
always @(posedge g_clock_in or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0;i<72;i=i+1) begin
			m_in[i]<=0;
		end
	end
	else if(in_valid) m_in[in_cnt]<=img;
end
always @(posedge g_clock_in or negedge rst_n) begin
	if(!rst_n)begin
		for(i=0;i<9;i=i+1) kernel[i]<=0;
	end
	else if(in_valid&&(in_cnt<9)) kernel[in_cnt]<=ker;
end
always @(posedge g_clock_in or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0;i<4;i=i+1) w[i]<=0;
	end
	else if(in_valid&&(in_cnt<4)) w[in_cnt]<=weight;
end
//==============================================//
//                   FSM                        //
//==============================================//
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) current_state<=0;
	else current_state<=next_state;
end

always @(*) begin
	case(current_state)
	IDLE:begin//0
		if(in_valid) next_state = IN_DATA;
		else next_state = IDLE;
	end
	IN_DATA:begin//1
		if(in_cnt==71) next_state = CONV;
		else next_state = IN_DATA;
	end
	CONV:begin//2
		if(conv_done) next_state = QUAN;
		else next_state = CONV;
	end
	QUAN:begin//3
		if(quan_done) next_state = MAX_P;
		else next_state = QUAN;
	end
	MAX_P:begin//4
		if(mp_done) next_state = F_C;
		else next_state = MAX_P;
	end
	F_C:begin//5
		if(fc_done)begin
			if(matrix_cnt==2) next_state = L1_D;
			else next_state = CONV;
		end
		else next_state = F_C;
	end
	L1_D:begin//6
		if(l1_done) next_state = ACTIVE;
		else next_state = L1_D;
	end
	ACTIVE:begin//7
		next_state = OUT;
	end
	OUT:begin//8
		next_state = IDLE;
	end
	default:next_state = IDLE;
	endcase
end
//==============================================//
//                    CONV INPUT                //
//==============================================//
always @(posedge g_clock_conv or negedge rst_n) begin
	if(!rst_n)begin
		c1<=0;
		c2<=0;
		c3<=0;
		c4<=0;
		c5<=0;
		c6<=0;
		c7<=0;
		c8<=0;
		c9<=0;
		c10<=0;
		c11<=0;
		c12<=0;
		c13<=0;
		c14<=0;
		c15<=0;
		c16<=0;
		c17<=0;
		c18<=0;
		c19<=0;
		c20<=0;
		c21<=0;
		c22<=0;
		c23<=0;
		c24<=0;
		c25<=0;
		c26<=0;
		c27<=0;
		c28<=0;
		c29<=0;
		c30<=0;
		c31<=0;
		c32<=0;
		c33<=0;
		c34<=0;
		c35<=0;
		c36<=0;
	end

	else  if(matrix_cnt==0&&next_state==CONV)begin
		c1 <= m_in[0];
		c2 <= m_in[1];
		c3 <= m_in[2];
		c4 <= m_in[3];
		c5 <= m_in[4];
		c6 <= m_in[5];
		c7 <= m_in[6];
		c8 <= m_in[7];
		c9 <= m_in[8];
		c10 <= m_in[9];
		c11 <= m_in[10];
		c12 <= m_in[11];
		c13 <= m_in[12];
		c14 <= m_in[13];
		c15 <= m_in[14];
		c16 <= m_in[15];
		c17 <= m_in[16];
		c18 <= m_in[17];
		c19 <= m_in[18];
		c20 <= m_in[19];
		c21 <= m_in[20];
		c22 <= m_in[21];
		c23 <= m_in[22];
		c24 <= m_in[23];
		c25 <= m_in[24];
		c26 <= m_in[25];
		c27 <= m_in[26];
		c28 <= m_in[27];
		c29 <= m_in[28];
		c30 <= m_in[29];
		c31 <= m_in[30];
		c32 <= m_in[31];
		c33 <= m_in[32];
		c34 <= m_in[33];
		c35 <= m_in[34];
		c36 <= m_in[35];
	end
	else if(matrix_cnt==1&&next_state==CONV) begin
		c1 <= m_in[36];
		c2 <= m_in[37];
		c3 <= m_in[38];
		c4 <= m_in[39];
		c5 <= m_in[40];
		c6 <= m_in[41];
		c7 <= m_in[42];
		c8 <= m_in[43];
		c9 <= m_in[44];
		c10 <= m_in[45];
		c11 <= m_in[46];
		c12 <= m_in[47];
		c13 <= m_in[48];
		c14 <= m_in[49];
		c15 <= m_in[50];
		c16 <= m_in[51];
		c17 <= m_in[52];
		c18 <= m_in[53];
		c19 <= m_in[54];
		c20 <= m_in[55];
		c21 <= m_in[56];
		c22 <= m_in[57];
		c23 <= m_in[58];
		c24 <= m_in[59];
		c25 <= m_in[60];
		c26 <= m_in[61];
		c27 <= m_in[62];
		c28 <= m_in[63];
		c29 <= m_in[64];
		c30 <= m_in[65];
		c31 <= m_in[66];
		c32 <= m_in[67];
		c33 <= m_in[68];
		c34 <= m_in[69];
		c35 <= m_in[70];
		c36 <= m_in[71];
	end
end
/////////////////
// assign snn to nn
/////////////////
/*always @(posedge clk or negedge rst_n) begin
	if(rst_n)begin
		nn1<=0;
		nn2<=0;
		nn3<=0;
		nn4<=0;
		nn5<=0;
		nn6<=0;
		nn7<=0;
		nn8<=0;
	end
	else if(fc_done&&(matrix_cnt==1))begin
		nn1<=snn1;
		nn2<=snn2;
		nn3<=snn3;
		nn4<=snn4;
	end
	else if(fc_done&&(matrix_cnt==2))begin
		nn5<=snn1;
		nn6<=snn2;
		nn7<=snn3;
		nn8<=snn4;
	end
end*/
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) nn1<=0;
	else if(fc_done&&(matrix_cnt==1)) nn1<=snn1;
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) nn2<=0;
	else if(fc_done&&(matrix_cnt==1)) nn2<=snn2;
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) nn3<=0;
	else if(fc_done&&(matrix_cnt==1)) nn3<=snn3;
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) nn4<=0;
	else if(fc_done&&(matrix_cnt==1)) nn4<=snn4;
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) nn5<=0;
	else if(fc_done&&(matrix_cnt==2))nn5<=snn1;
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) nn6<=0;
	else if(fc_done&&(matrix_cnt==2)) nn6<=snn2;
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) nn7<=0;
	else if(fc_done&&(matrix_cnt==2))nn7<=snn3;
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) nn8<=0;
	else if(fc_done&&(matrix_cnt==2)) nn8<=snn4;
end

//==============================================//
//                  CALL MODULE                 //
//==============================================//
CONVOLUTION C1(.clk(g_clock_conv),.rst_n(rst_n),.start(conv_start),.in1(c1),.in2(c2),.in3(c3),.in4(c4),.in5(c5),.in6(c6),.in7(c7),.in8(c8),.in9(c9),.in10(c10),.in11(c11),
.in12(c12),.in13(c13),.in14(c14),.in15(c15),.in16(c16),.in17(c17),.in18(c18),.in19(c19),.in20(c20),.in21(c21),.in22(c22),.in23(c23),.in24(c24),.in25(c25),.in26(c26),.in27(c27),
.in28(c28),.in29(c29),.in30(c30),.in31(c31),.in32(c32),.in33(c33),.in34(c34),.in35(c35),.in36(c36),
.k1(kernel[0]),.k2(kernel[1]),.k3(kernel[2]),.k4(kernel[3]),.k5(kernel[4]),.k6(kernel[5]),.k7(kernel[6]),.k8(kernel[7]),.k9(kernel[8]),
.out1(q1),.out2(q2),.out3(q3),.out4(q4),.out5(q5),.out6(q6),.out7(q7),.out8(q8),.out9(q9),.out10(q10),.out11(q11),.out12(q12),.out13(q13),.out14(q14),.out15(q15),.out16(q16),
.done(conv_done));

QUANTIZATION Q1(.clk(g_clock_quan),.rst_n(rst_n),.start(quan_start),.in1(q1),.in2(q2),.in3(q3),.in4(q4),.in5(q5),.in6(q6),.in7(q7),.in8(q8),.in9(q9),.in10(q10),.in11(q11),.in12(q12),.in13(q13),.in14(q14),.in15(q15),.in16(q16),
.out1(mp1),.out2(mp2),.out3(mp3),.out4(mp4),.out5(mp5),.out6(mp6),.out7(mp7),.out8(mp8),.out9(mp9),.out10(mp10),.out11(mp11),.out12(mp12),.out13(mp13),.out14(mp14),.out15(mp15),.out16(mp16),.done(quan_done));

MAX_POOLING MP1(.clk(g_clock_mp),.rst_n(rst_n),.start(mp_start),.in1(mp1),.in2(mp2),.in3(mp3),.in4(mp4),.in5(mp5),.in6(mp6),.in7(mp7),.in8(mp8),.in9(mp9),.in10(mp10),.in11(mp11),.in12(mp12),.in13(mp13),.in14(mp14),.in15(mp15),.in16(mp16),
.out1(fc1),.out2(fc2),.out3(fc3),.out4(fc4),.done(mp_done));
////pluse matrix_cnt 
FULLLY_CONNECT FC1(.clk(g_clock_fc),.rst_n(rst_n),.start(fc_start),.in1(fc1),.in2(fc2),.in3(fc3),.in4(fc4),.w1(w[0]),.w2(w[1]),.w3(w[2]),.w4(w[3]),.out1(snn1),.out2(snn2),.out3(snn3),.out4(snn4),.done(fc_done));
////////////   CAL TWO DIFFERENT MATRXI
L1_DISTANCE LD1(.clk(g_clock_l1),.rst_n(rst_n),.start(l1_start),.in11(nn1),.in12(nn2),.in13(nn3),.in14(nn4),.in21(nn5),.in22(nn6),.in23(nn7),.in24(nn8),.out(l1o),.done(l1_done));
ACTIVATION AC1(.clk(g_clock_ac),.rst_n(rst_n),.start(ac_start),.in(l1o),.out(fo),.done(ac_done));

//==============================================//
//                  OUTPUT                      //
//==============================================//g_clock_out
always @(posedge g_clock_out or negedge rst_n) begin
	if(!rst_n) out_data<=0;
	else if(current_state==OUT) out_data<=fo;
	else out_data<=0;
end
always @(posedge g_clock_out or negedge rst_n) begin
	if(!rst_n) out_valid<=0;
	else if(current_state==OUT) out_valid<=1;
	else out_valid<=0;
end
endmodule
//==============================================//
//      CONVOLUTION SUB_MODULE                  //
//==============================================//
module CONVOLUTION (clk,rst_n,start,
in1,in2,in3,in4,in5,in6,in7,in8,in9,in10,in11,in12,in13,in14,in15,in16,in17,in18,in19,in20,in21,in22,in23,in24,in25,in26,in27,in28,in29,in30,in31,in32,in33,in34,in35,in36,
k1,k2,k3,k4,k5,k6,k7,k8,k9,
out1,out2,out3,out4,out5,out6,out7,out8,out9,out10,out11,out12,out13,out14,out15,out16,
done
);	
input clk,rst_n,start;
input [7:0] in1,in2,in3,in4,in5,in6,in7,in8,in9,in10,in11,in12,in13,in14,in15,in16,in17,in18,in19,in20,in21,in22,in23,in24,in25,in26,in27,in28,in29,in30,in31,in32,in33,in34,in35,in36;
input [7:0] k1,k2,k3,k4,k5,k6,k7,k8,k9;
output reg done;
output reg [19:0] out1,out2,out3,out4,out5,out6,out7,out8,out9,out10,out11,out12,out13,out14,out15,out16;
//==============================================//
//           reg & wire declaration             //
//==============================================//
reg [7:0] now_cal1,now_cal2,now_cal3,now_cal4,now_cal5,now_cal6,now_cal7,now_cal8,now_cal9;
//wire [19:0] now_out1,now_out2,now_out3,now_out4,now_out5,now_out6,now_out7,now_out8,now_out9,now_out10,now_out11,now_out12,now_out13,now_out14,now_out15,now_out16;
wire [19:0] out;
reg [5:0] conv_cnt;
//==============================================//
//                  design                      //
//==============================================//
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) conv_cnt<=0;
	else if(conv_cnt==17) conv_cnt<=0;
	else if(start) conv_cnt<=conv_cnt+1;
	//else if(conv_cnt==17) conv_cnt<=0;
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) done<=0;
	else if(conv_cnt>15) done<=1;
	else done<=0;
end
always @(*) begin
	case(conv_cnt)
	0:begin
		now_cal1 = in1;
		now_cal2 = in2;
		now_cal3 = in3;
		now_cal4 = in7;
		now_cal5 = in8;
		now_cal6 = in9;
		now_cal7 =in13;
		now_cal8 =in14;
		now_cal9 =in15;
	end
	1:begin
		now_cal1 = in2;
		now_cal2 = in3;
		now_cal3 = in4;
		now_cal4 = in8;
		now_cal5 = in9;
		now_cal6 = in10;
		now_cal7 = in14;
		now_cal8 = in15;
		now_cal9 = in16;
	end
	2:begin
		now_cal1 = in3;
		now_cal2 = in4;
		now_cal3 = in5;
		now_cal4 = in9;
		now_cal5 =in10;
		now_cal6 =in11;
		now_cal7 =in15;
		now_cal8 =in16;
		now_cal9 =in17;
	end
	3:begin
		now_cal1 = in4;
		now_cal2 =in5;
		now_cal3 =in6;
		now_cal4 =in10;
		now_cal5 =in11;
		now_cal6 =in12;
		now_cal7 =in16;
		now_cal8 =in17;
		now_cal9 =in18;
	end
	4:begin
		now_cal1 = in7;
		now_cal2 =in8;
		now_cal3 =in9;
		now_cal4 =in13;
		now_cal5 =in14;
		now_cal6 =in15;
		now_cal7 =in19;
		now_cal8 =in20;
		now_cal9 =in21;
	end
	5:begin
		now_cal1 = in8;
		now_cal2 =in9;
		now_cal3 =in10;
		now_cal4 =in14;
		now_cal5 =in15;
		now_cal6 =in16;
		now_cal7 =in20;
		now_cal8 =in21;
		now_cal9 =in22;
	end
	6:begin
		now_cal1 = in9;
		now_cal2 =in10;
		now_cal3 =in11;
		now_cal4 =in15;
		now_cal5 =in16;
		now_cal6 =in17;
		now_cal7 =in21;
		now_cal8 =in22;
		now_cal9 =in23;
	end
	7:begin
		now_cal1 = in10;
		now_cal2 =in11;
		now_cal3 =in12;
		now_cal4 =in16;
		now_cal5 =in17;
		now_cal6 =in18;
		now_cal7 =in22;
		now_cal8 =in23;
		now_cal9 =in24;
	end
	8:begin
		now_cal1 = in13;
		now_cal2 =in14;
		now_cal3 =in15;
		now_cal4 =in19;
		now_cal5 =in20;
		now_cal6 =in21;
		now_cal7 =in25;
		now_cal8 =in26;
		now_cal9 =in27;
	end
	9:begin
		now_cal1 = in14;
		now_cal2 =in15;
		now_cal3 =in16;
		now_cal4 =in20;
		now_cal5 =in21;
		now_cal6 =in22;
		now_cal7 =in26;
		now_cal8 =in27;
		now_cal9 =in28;
	end
	10:begin
		now_cal1 = in15;
		now_cal2 =in16;
		now_cal3 =in17;
		now_cal4 =in21;
		now_cal5 =in22;
		now_cal6 =in23;
		now_cal7 =in27;
		now_cal8 =in28;
		now_cal9 =in29;
	end
	11:begin
		now_cal1 = in16;
		now_cal2 =in17;
		now_cal3 =in18;
		now_cal4 =in22;
		now_cal5 =in23;
		now_cal6 =in24;
		now_cal7 =in28;
		now_cal8 =in29;
		now_cal9 =in30;
	end
	12:begin
		now_cal1 = in19;
		now_cal2 =in20;
		now_cal3 =in21;
		now_cal4 =in25;
		now_cal5 =in26;
		now_cal6 =in27;
		now_cal7 =in31;
		now_cal8 =in32;
		now_cal9 =in33;
	end
	13:begin
		now_cal1 = in20;
		now_cal2 =in21;
		now_cal3 =in22;
		now_cal4 =in26;
		now_cal5 =in27;
		now_cal6 =in28;
		now_cal7 =in32;
		now_cal8 =in33;
		now_cal9 =in34;
	end
	14:begin
		now_cal1 = in21;
		now_cal2 =in22;
		now_cal3 =in23;
		now_cal4 =in27;
		now_cal5 =in28;
		now_cal6 =in29;
		now_cal7 =in33;
		now_cal8 =in34;
		now_cal9 =in35;
	end
	15:begin
		now_cal1 = in22;
		now_cal2 =in23;
		now_cal3 =in24;
		now_cal4 =in28;
		now_cal5 =in29;
		now_cal6 =in30;
		now_cal7 =in34;
		now_cal8 =in35;
		now_cal9 =in36;
	end
	default:begin
		now_cal1 = 0;
		now_cal2 =0;
		now_cal3 =0;
		now_cal4 =0;
		now_cal5 =0;
		now_cal6 =0;
		now_cal7 =0;
		now_cal8 =0;
		now_cal9 =0;
	end
	endcase
end
//==============================================//
//           CALL SUB_MODULE                    //
//==============================================//
CONV_CELL CC1(.in1(now_cal1),.in2(now_cal2),.in3(now_cal3),.in4(now_cal4),.in5(now_cal5),.in6(now_cal6),.in7(now_cal7),.in8(now_cal8),.in9(now_cal9),
.k1(k1),.k2(k2),.k3(k3),.k4(k4),.k5(k5),.k6(k6),.k7(k7),.k8(k8),.k9(k9),.out(out));
//==============================================//
//           RECEIVE OUTPUT                     //
//==============================================//
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		out1<=0;
		out2<=0;
		out3<=0;
		out4<=0;
		out5<=0;
		out6<=0;
		out7<=0;
		out8<=0;
		out9<=0;
		out10<=0;
		out11<=0;
		out12<=0;
		out13<=0;
		out14<=0;
		out15<=0;
		out16<=0;
	end
	else begin
		case(conv_cnt)
		0:out1<=out;
		1:out2<=out;
		2:out3<=out;
		3:out4<=out;
		4:out5<=out;
		5:out6<=out;
		6:out7<=out;
		7:out8<=out;
		8:out9<=out;
		9:out10<=out;
		10:out11<=out;
		11:out12<=out;
		12:out13<=out;
		13:out14<=out;
		14:out15<=out;
		15:out16<=out;
		endcase
	end
end
endmodule

module CONV_CELL (
	in1,in2,in3,in4,in5,in6,in7,in8,in9,
	k1,k2,k3,k4,k5,k6,k7,k8,k9,
	out
);
input [7:0] in1,in2,in3,in4,in5,in6,in7,in8,in9;
input [7:0] k1,k2,k3,k4,k5,k6,k7,k8,k9;
output reg [19:0] out;
always @(*) begin
	out =in1*k1+in2*k2+in3*k3+in4*k4+in5*k5+in6*k6+in7*k7+in8*k8+in9*k9;	
end
endmodule
//==============================================//
//      QUANTIZATION SUB_MODULE                 //
//==============================================//
module QUANTIZATION (
	clk,rst_n,start,
	in1,in2,in3,in4,in5,in6,in7,in8,in9,in10,in11,in12,in13,in14,in15,in16,
    out1,out2,out3,out4,out5,out6,out7,out8,out9,out10,out11,out12,out13,out14,out15,out16,
	done
);
	input clk,rst_n,start;
	input [19:0] in1,in2,in3,in4,in5,in6,in7,in8,in9,in10,in11,in12,in13,in14,in15,in16;
	output reg [7:0]  out1,out2,out3,out4,out5,out6,out7,out8,out9,out10,out11,out12,out13,out14,out15,out16;
	output reg done;
//==============================================//
//           reg & wire declaration             //
//==============================================//
reg [4:0] qua_cnt;
parameter down = 2295;
//==============================================//
//           DESIGN                             //
//==============================================//
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) qua_cnt<=0;
	else if(qua_cnt==17) qua_cnt<=0;
	else if(start) qua_cnt<=qua_cnt+1;
	//else if(qua_cnt==17) qua_cnt<=0;
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)done<=0;
	else if(qua_cnt>15) done<=1;
	else done<=0;
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		out1<=0;
		out2<=0;
		out3<=0;
		out4<=0;
		out5<=0;
		out6<=0;
		out7<=0;
		out8<=0;
		out9<=0;
		out10<=0;
		out11<=0;
		out12<=0;
		out13<=0;
		out14<=0;
		out15<=0;
		out16<=0;
	end
	else begin
		case(qua_cnt)
		0:out1<=in1/down;
		1:out2<=in2/down;
		2:out3<=in3/down;
		3:out4<=in4/down;
		4:out5<=in5/down;
		5:out6<=in6/down;
		6:out7<=in7/down;
		7:out8<=in8/down;
		8:out9<=in9/down;
		9:out10<=in10/down;
		10:out11<=in11/down;
		11:out12<=in12/down;
		12:out13<=in13/down;
		13:out14<=in14/down;
		14:out15<=in15/down;
		15:out16<=in16/down;
		endcase
	end
end
endmodule
//==============================================//
//      MAX_POOLING SUB_MODULE                  //
//==============================================//
module MAX_POOLING (
	clk,rst_n,start,
	in1,in2,in3,in4,in5,in6,in7,in8,in9,in10,in11,in12,in13,in14,in15,in16,
	out1,out2,out3,out4,
	done
);
	input clk,rst_n,start;
	input [7:0]in1,in2,in3,in4,in5,in6,in7,in8,in9,in10,in11,in12,in13,in14,in15,in16;
	output reg [7:0] out1,out2,out3,out4;
	output reg done;
	wire [7:0] b1,b2,b3,b4;

	FBB f1(.in1(in1),.in2(in2),.in3(in5),.in4(in6),.out(b1));
	FBB f2(.in1(in3),.in2(in4),.in3(in7),.in4(in8),.out(b2));
	FBB f3(.in1(in9),.in2(in10),.in3(in13),.in4(in14),.out(b3));
	FBB f4(.in1(in11),.in2(in12),.in3(in15),.in4(in16),.out(b4));

	always @(*) begin
		out1 = b1;
		out2 = b2;
		out3 = b3;
		out4 = b4;
	end
	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) done<=0;
		else if(start) done<=1;
		else done<=0;
	end

endmodule
module FBB (
	in1,in2,in3,in4,
	out
);
input [7:0] in1,in2,in3,in4;
output reg [7:0] out;
	always @(*) begin
		if((in1>=in2)&&(in1>=in3)&&(in1>=in4)) out = in1;
		else if((in2>in1)&&(in2>=in3)&&(in2>=in4)) out = in2;
		else if((in3>in1)&&(in3>in2)&&(in3>=in4)) out = in3;
		else out = in4;
	end
endmodule
//==============================================//
//        FULLLY CONNECTION SUB_MODULE          //
//==============================================//
module FULLLY_CONNECT (
	clk,rst_n,start,
	in1,in2,in3,in4,
	w1,w2,w3,w4,
	out1,out2,out3,out4,
	done
);
	input clk,rst_n,start;
	input [7:0] in1,in2,in3,in4;
	input [7:0] w1,w2,w3,w4;
	output reg [7:0] out1,out2,out3,out4;
	output reg done;

	reg [2:0] fc_cnt;
	reg [19:0] o1,o2,o3,o4;
	parameter down = 510;
	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) fc_cnt<=0;
		else if(fc_cnt==4)fc_cnt<=0;
		else if(start&&(!done)) fc_cnt<=fc_cnt+1;
		//else fc_cnt<=0;
	end
	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) done<=0;
		else if(fc_cnt==4) done<=1;
		else done<=0;
	end
	always @(posedge clk or negedge rst_n) begin
		if(!rst_n)begin
			o1<=0;
			o2<=0;
			o3<=0;
			o4<=0;
		end
		else begin
			case(fc_cnt)
			0: o1<=in1*w1+in2*w3;
			1: o2<=in1*w2+in2*w4;
			2: o3<=in3*w1+in4*w3;
			3: o4<=in3*w2+in4*w4;
			endcase
		end
	end
	always @(posedge clk or negedge rst_n) begin
		if(!rst_n)begin
			out1<=0;
			out2<=0;
			out3<=0;
			out4<=0;
		end
		else begin
			case(fc_cnt)
			1:out1<=o1/down;
			2:out2<=o2/down;
			3:out3<=o3/down;
			4:out4<=o4/down;
			endcase
		end
	end
endmodule
//==============================================//
//           L1_DISTANCE SUB_MODULE             //
//==============================================//
module L1_DISTANCE (
	clk,rst_n,start,
	in11,in12,in13,in14,
	in21,in22,in23,in24,
	out,
	done
);	
	input clk,rst_n,start;
	input [7:0] in11,in12,in13,in14;
	input [7:0] in21,in22,in23,in24;
	output reg [9:0] out;
	output reg done;

	wire [7:0] big1,big2,big3,big4;
	wire [7:0] small1,small2,small3,small4;
	reg [2:0] l1_cnt;
	reg [7:0] o1,o2,o3,o4;

	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) l1_cnt<=0;
		else if(start) l1_cnt<=l1_cnt+1;
		else l1_cnt<=0;
	end

	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) done<=0;
		else if(l1_cnt==4) done<=1;
		else done<=0;
	end
		assign big1 = (in11>in21)?in11:in21;
		assign big2 = (in12>in22)?in12:in22;
		assign big3 = (in13>in23)?in13:in23;
		assign big4 = (in14>in24)?in14:in24;

		assign small1 = (in11<in21)?in11:in21;
		assign small2 = (in12<in22)?in12:in22;
		assign small3 = (in13<in23)?in13:in23;
		assign small4 = (in14<in24)?in14:in24;
	
	always @(posedge clk or negedge rst_n) begin
		if(!rst_n)begin
			o1<=0;
			o2<=0;
			o3<=0;
			o4<=0;
		end
		else begin
			case(l1_cnt)
			0:o1<=big1-small1;
			1:o2<=big2-small2;
			2:o3<=big3-small3;
			3:o4<=big4-small4;
			endcase
		end
	end
	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) out<=0;
		else begin
			case(l1_cnt)
			4:out<=o1+o2+o3+o4;
			endcase
		end
	end
endmodule

module ACTIVATION (
	clk,rst_n,start,
	in,
	out,
	done
);
	input clk,rst_n,start;
	input [9:0] in;
	output reg [9:0] out;
	output reg done;

	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) done<=0;
		else if(start) done<=1;
		else done<=0;
	end

	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) out<=0;
		else if(start) out<=(in>=16)?in:0;
	end

endmodule


