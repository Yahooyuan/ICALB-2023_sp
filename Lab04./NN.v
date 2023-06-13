//synopsys translate_off
`include "/RAID2/EDA/synopsys/synthesis/2020.09/dw/sim_ver/DW_fp_sum3.v"
`include "/RAID2/EDA/synopsys/synthesis/2020.09/dw/sim_ver/DW_fp_mult.v"
`include "/RAID2/EDA/synopsys/synthesis/2020.09/dw/sim_ver/DW_fp_add.v"
`include "/RAID2/EDA/synopsys/synthesis/2020.09/dw/sim_ver/DW_fp_exp.v"
`include "/RAID2/EDA/synopsys/synthesis/2020.09/dw/sim_ver/DW_fp_div.v"
//synopsys translate_on
module NN(
	// Input signals
	clk,
	rst_n,
	in_valid,
	weight_u,
	weight_w,
	weight_v,
	data_x,
	data_h,
	// Output signals
	out_valid,
	out
);

//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------

// IEEE floating point paramenters
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch = 2;
parameter one_float = 32'b00111111100000000000000000000000;
//FSM parameter
parameter IDLE = 4'd0;
parameter IN_DATA = 4'd1;
parameter CAL_MUL = 4'd2;
parameter CAL_ADD = 4'd3;
parameter CAL_LEAK = 4'd4;
parameter CAL_MUL2 = 4'd5;
parameter CAL_ADD2 = 4'd6;
parameter CAL_LEAK2 = 4'd7;
parameter CAL_MUL3 = 4'd8;
parameter CAL_ADD3 = 4'd9;
parameter CAL_LEAK3 = 4'd10;
parameter CAL_MUL4 = 4'd11;
parameter CAL_ADD4 = 4'd12;
parameter CAL_SIG = 4'd13;
parameter OUT = 4'd14;
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
input  clk, rst_n, in_valid;
input [inst_sig_width+inst_exp_width:0] weight_u, weight_w, weight_v;
input [inst_sig_width+inst_exp_width:0] data_x,data_h;
output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;

//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------
reg [3:0] current_state,next_state;
reg [31:0] x [0:8];
reg [31:0] u [0:8];
reg [31:0] v [0:8];
reg [31:0] w [0:8];
//wire [31:0] h [0:2];
reg [31:0] h [0:2];
reg [31:0] y [0:8];
wire [31:0] sig_out0,sig_out1,sig_out2;
reg [3:0] counter;
reg clear;
integer i;
reg mul_in_valid;
reg add2m_in_valid;
reg add_out_in_valid;
reg leaky_in_valid;
reg sig_in_valid;
wire mulx_done,mulh_done,muly_done;
wire add1_done;
wire addout_done;
wire leaky_done;
wire sig_done;
//reg sig_done;
reg [3:0] out_cnt;
reg [3:0] in_cnt;
reg [31:0] now_cal_x0,now_cal_x1,now_cal_x2;
wire [31:0] leakyo0,leakyo1,leakyo2;
wire [31:0] hw_out0,hw_out1,hw_out2,hw_out3,hw_out4,hw_out5,hw_out6,hw_out7,hw_out8;
wire [31:0] xu_out0,xu_out1,xu_out2,xu_out3,xu_out4,xu_out5,xu_out6,xu_out7,xu_out8;
wire [31:0] hv_out0,hv_out1,hv_out2,hv_out3,hv_out4,hv_out5,hv_out6,hv_out7,hv_out8;
wire [31:0] pre_lea0,pre_lea1,pre_lea2;
wire [31:0] pre_sig0,pre_sig1,pre_sig2;
//wire [31:0] exp0,exp1,exp2;
//wire [31:0] f0,f1,f2;
//wire [31:0] s0,s1,s2;
//---------------------------------------------------------------------
//   FSM DESIGN
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) current_state<=IDLE;
	else current_state<=next_state;
end

always @(*) begin
	case(current_state)
	IDLE:begin
		if(in_valid) next_state=IN_DATA;
		else next_state=IDLE;
	end
	IN_DATA:begin
		if(!in_valid) next_state = CAL_MUL;
		else next_state = IN_DATA;
	end
	CAL_MUL:begin
		if(mulx_done&&muly_done&&mulh_done) next_state = CAL_ADD;
		else next_state = CAL_MUL;
	end
	CAL_ADD:begin
		if(add1_done) next_state = CAL_LEAK;
		else next_state = CAL_ADD;
	end
	CAL_LEAK:begin
		if(leaky_done) next_state = CAL_MUL2;
		else next_state = CAL_LEAK;
	end
	CAL_MUL2:begin
		if(mulx_done&&muly_done&&mulh_done) next_state = CAL_ADD2;
		else next_state = CAL_MUL2;
	end
	CAL_ADD2:begin
		if(add1_done) next_state = CAL_LEAK2;
		else next_state = CAL_ADD2;
	end
	CAL_LEAK2:begin
		if(leaky_done&&sig_done) next_state = CAL_MUL3;
		else next_state = CAL_LEAK2;
	end
	CAL_MUL3:begin
		if(mulx_done&&muly_done&&mulh_done) next_state = CAL_ADD3;
		else next_state = CAL_MUL3;
	end
	CAL_ADD3:begin
		if(add1_done) next_state = CAL_LEAK3;
		else next_state = CAL_ADD3;
	end
	CAL_LEAK3:begin
		if(leaky_done&&sig_done) next_state = CAL_MUL4;
		else next_state = CAL_LEAK3;
	end
	CAL_MUL4:begin
		if(mulx_done&&muly_done&&mulh_done) next_state = CAL_ADD4;
		else next_state = CAL_MUL4;
	end
	CAL_ADD4:begin
		if(addout_done) next_state = CAL_SIG;
		else next_state = CAL_ADD4;
	end
	CAL_SIG:begin
		if(sig_done) next_state = OUT;
		else next_state = CAL_SIG;
	end
	OUT:begin
		if(out_cnt==9) next_state = IDLE;
		else next_state = OUT;
	end
	default:next_state = IDLE;
	endcase
end
always @(*) begin
	if(next_state==CAL_MUL||next_state==CAL_MUL2||next_state==CAL_MUL3||next_state==CAL_MUL4)begin
		mul_in_valid = 1;
	end
	else mul_in_valid = 0;
end
always @(*) begin
	if(next_state==CAL_ADD||next_state==CAL_ADD2||next_state==CAL_ADD3||next_state==CAL_ADD4)begin
		add2m_in_valid = 1;
	end
	else add2m_in_valid = 0;
end
always @(*) begin
	if(next_state==CAL_ADD2||next_state==CAL_ADD3||next_state==CAL_ADD4)begin
		add_out_in_valid = 1;
	end
	else add_out_in_valid = 0;
end
always @(*) begin
	if(next_state==CAL_LEAK||next_state==CAL_LEAK2||next_state==CAL_LEAK3)begin
		leaky_in_valid = 1;
	end
	else leaky_in_valid = 0;
end
always@(*)begin
	if(next_state==CAL_LEAK2||next_state==CAL_LEAK3||next_state==CAL_SIG)begin
		sig_in_valid = 1;
	end
	else sig_in_valid = 0;
end
//---------------------------------------------------------------------
//   INPUT DESIGN
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) in_cnt<=0;
	else if(next_state==IN_DATA) in_cnt<=in_cnt+1;
	else in_cnt<=0;
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		for(i=0;i<9;i=i+1) begin
			x[i]<=0;
			u[i]<=0;
			v[i]<=0;
			w[i]<=0;
		end
	end
	else if(in_valid)begin
		x[in_cnt]<=data_x;
		u[in_cnt]<=weight_u;
		v[in_cnt]<=weight_v;
		w[in_cnt]<=weight_w;
	end
end
////////h control
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		for(i=0;i<9;i=i+1)begin
			h[i]<=0;
		end
	end
	else if(in_valid&&in_cnt<3)begin
		h[in_cnt]<=data_h;
	end
	else if(next_state==CAL_MUL2||next_state==CAL_MUL3||next_state==CAL_MUL4)begin
		h[0]<=leakyo0;
		h[1]<=leakyo1;
		h[2]<=leakyo2;
	end
end
//// x1 x2 x3 control
always @(posedge clk or negedge rst_n) begin
	if(~rst_n)begin
		now_cal_x0 <= 0;
		now_cal_x1 <= 0;
		now_cal_x2 <= 0;
	end
	else begin
		case(current_state)
			IN_DATA:begin
				now_cal_x0 <= x[0];
				now_cal_x1 <= x[1];
				now_cal_x2 <= x[2];
			end

			CAL_LEAK:begin
				now_cal_x0 <= x[3];
				now_cal_x1 <= x[4];
				now_cal_x2 <= x[5];
			end

			CAL_LEAK2:begin
				now_cal_x0 <= x[6];
				now_cal_x1 <= x[7];
				now_cal_x2 <= x[8];
			end
		endcase
	end
end
//---------------------------------------------------------------------
//   PRE-OUTPUT DESIGN
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		for(i=0;i<9;i=i+1)begin
			y[i]<=0;
		end
	end
	else if(next_state==CAL_MUL3)begin
		y[0]<=sig_out0;
		y[1]<=sig_out1;
		y[2]<=sig_out2;
	end
	else if(next_state==CAL_MUL4)begin
		y[3]<=sig_out0;
		y[4]<=sig_out1;
		y[5]<=sig_out2;
	end
	else if(next_state==OUT)begin
		y[6]<=sig_out0;
		y[7]<=sig_out1;
		y[8]<=sig_out2;
	end
	
end
//---------------------------------------------------------------------
//   OUTPUT DESIGN
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		out_valid<=0;
	end
	else if(next_state==OUT)begin
		out_valid<=1;
	end
	else out_valid<=0;
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		out_cnt<=0;
	end
	else if(next_state==OUT)begin
		out_cnt<=out_cnt+1;
	end
	else if(current_state==IDLE) out_cnt<=0;
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		out<=0;
	end
	else if(next_state==OUT)begin
		out<=y[out_cnt];
	end
	else out<=0;
end
//h mul W
matrix_MUL M0(.clk(clk),.rst_n(rst_n),.in_valid(mul_in_valid),.m_in0(w[0]),.m_in1(w[1]),.m_in2(w[2]),.m_in3(w[3]),.m_in4(w[4]),.m_in5(w[5]),.m_in6(w[6]),.m_in7(w[7]),.m_in8(w[8]),
.v_in0(h[0]),.v_in1(h[1]),.v_in2(h[2]),.out0(hw_out0),.out1(hw_out1),.out2(hw_out2),.out3(hw_out3),.out4(hw_out4),.out5(hw_out5),.out6(hw_out6),.out7(hw_out7),.out8(hw_out8),
.done(mulh_done));
//x mul U
matrix_MUL M1(.clk(clk),.rst_n(rst_n),.in_valid(mul_in_valid),.m_in0(u[0]),.m_in1(u[1]),.m_in2(u[2]),.m_in3(u[3]),.m_in4(u[4]),.m_in5(u[5]),.m_in6(u[6]),.m_in7(u[7]),.m_in8(u[8]),
.v_in0(now_cal_x0),.v_in1(now_cal_x1),.v_in2(now_cal_x2),.out0(xu_out0),.out1(xu_out1),.out2(xu_out2),.out3(xu_out3),.out4(xu_out4),.out5(xu_out5),.out6(xu_out6),.out7(xu_out7),.out8(xu_out8),
.done(mulx_done));
//ADD X H
matrix_ADD_2M A0(.clk(clk),.rst_n(rst_n),.in_valid(add2m_in_valid),.m1_00(hw_out0),.m1_01(hw_out1),.m1_02(hw_out2),.m1_10(hw_out3),.m1_11(hw_out4),.m1_12(hw_out5),.m1_20(hw_out6),.m1_21(hw_out7),.m1_22(hw_out8),
.m2_00(xu_out0),.m2_01(xu_out1),.m2_02(xu_out2),.m2_10(xu_out3),.m2_11(xu_out4),.m2_12(xu_out5),.m2_20(xu_out6),.m2_21(xu_out7),.m2_22(xu_out8),
.v_out0(pre_lea0),.v_out1(pre_lea1),.v_out2(pre_lea2),.done(add1_done));
//do leaky relu 
LEAKY_RELU L0(.clk(clk),.rst_n(rst_n),.in_valid(leaky_in_valid),.in0(pre_lea0),.in1(pre_lea1),.in2(pre_lea2),.out0(leakyo0),.out1(leakyo1),.out2(leakyo2),.done(leaky_done));
//h n+1 mul V for y
matrix_MUL M2(.clk(clk),.rst_n(rst_n),.in_valid(mul_in_valid),.m_in0(v[0]),.m_in1(v[1]),.m_in2(v[2]),.m_in3(v[3]),.m_in4(v[4]),.m_in5(v[5]),.m_in6(v[6]),.m_in7(v[7]),.m_in8(v[8]),
.v_in0(h[0]),.v_in1(h[1]),.v_in2(h[2]),.out0(hv_out0),.out1(hv_out1),.out2(hv_out2),.out3(hv_out3),.out4(hv_out4),.out5(hv_out5),.out6(hv_out6),.out7(hv_out7),.out8(hv_out8),
.done(muly_done)); 
//add for pre sig out 
matrix_ADD M3(.clk(clk),.rst_n(rst_n),.in_valid(add_out_in_valid),.in0(hv_out0),.in1(hv_out1),.in2(hv_out2),.in3(hv_out3),.in4(hv_out4),.in5(hv_out5),.in6(hv_out6),.in7(hv_out7),.in8(hv_out8),.out0(pre_sig0),.out1(pre_sig1),.out2(pre_sig2),.done(addout_done));
//Sig
/*DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
E0 (.a({~pre_sig0[31],pre_sig0[30:0]}), .z(exp0));
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
E1 (.a({~pre_sig1[31],pre_sig1[30:0]}), .z(exp1));
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
E2 (.a({~pre_sig2[31],pre_sig2[30:0]}), .z(exp2));

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
S0 (.a(exp0), .b(one_float), .rnd(3'b000),.z(f0));
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
S1 (.a(exp1), .b(one_float), .rnd(3'b000),.z(f1));
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
S2 (.a(exp2), .b(one_float), .rnd(3'b000),.z(f2));

DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance) 
D0 (.a(one_float), .b(f0), .rnd(3'b000), .z(s0));
DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance) 
D1 (.a(one_float), .b(f1), .rnd(3'b000), .z(s1));
DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance) 
D2 (.a(one_float), .b(f2), .rnd(3'b000), .z(s2));*/
Sigmoid S0(.clk(clk),.rst_n(rst_n),.in_valid(sig_in_valid),.in0(pre_sig0),.in1(pre_sig1),.in2(pre_sig2),.out0(sig_out0),.out1(sig_out1),.out2(sig_out2),.out_valid(sig_done));
endmodule

//---------------------------------------------------------------------
//   CAL MODULE DESIGN
//---------------------------------------------------------------------
module matrix_MUL (
	clk,
	rst_n,
	in_valid,
	m_in0,
	m_in1,
	m_in2,
	m_in3,
	m_in4,
	m_in5,
	m_in6,
	m_in7,
	m_in8,
	v_in0,
	v_in1,
	v_in2,
	out0,
	out1,
	out2,
	out3,
	out4,
	out5,
	out6,
	out7,
	out8,
	done
);
input clk,rst_n;
input in_valid;
output reg done;
input [31:0]m_in0,m_in1,m_in2,m_in3,m_in4,m_in5,m_in6,m_in7,m_in8,v_in0,v_in1,v_in2;
output reg [31:0] out0,out1,out2,out3,out4,out5,out6,out7,out8;

wire [31:0]mult0_z,mult1_z,mult2_z;

reg [31:0] in0 ,in1, in2;
reg in_valid1,in_valid2,in_valid3,in_valid4;

parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch = 2;
reg [1:0] counter;

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) counter <= 0;
	else if(in_valid) counter <= counter +1;
	else counter <= 0;
end

always @(*) begin//one clk do a row
	case(counter)
		'd0 :begin
			in0 = m_in0;
			in1 = m_in1;
			in2 = m_in2;
		end

		'd01:begin
			in0 = m_in3;
			in1 = m_in4;
			in2 = m_in5;
		end

		'd02:begin
			in0 = m_in6;
			in1 = m_in7;
			in2 = m_in8;
		end

		default:begin
			in0 = 'dx;
			in1 = 'dx;
			in2 = 'dx;
		end
	endcase
end

always @(posedge clk or negedge rst_n) begin
	if(~rst_n) done <=0;
	else begin
		done <= in_valid4;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(~rst_n) in_valid4 <=0;
	else begin
		in_valid4 <= in_valid3;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(~rst_n) in_valid3 <=0;
	else begin
		in_valid3 <= in_valid2;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(~rst_n) in_valid2 <=0;
	else begin
		in_valid2 <= in_valid1;
	end
end


always @(posedge clk or negedge rst_n) begin
	if(~rst_n) in_valid1 <=0;
	else begin
		in_valid1 <= in_valid;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(~rst_n)begin
		out0 <= 0;
		out1 <= 0;
		out2 <= 0;
	end
	else begin
		case(counter)
			'd0 :begin
				out0 <= mult0_z;
				out1 <= mult1_z;
				out2 <= mult2_z;
			end

			'd01:begin
				out3 <= mult0_z;
				out4 <= mult1_z;
				out5 <= mult2_z;
			end

			'd02:begin
				out6 <= mult0_z;
				out7 <= mult1_z;
				out8 <= mult2_z;
			end
		endcase
	end	
end

DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) 
M0 (.a(in0), .b(v_in0), .rnd(3'b000), .z(mult0_z));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) 
M1 (.a(in1), .b(v_in1), .rnd(3'b000), .z(mult1_z));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) 
M2 (.a(in2), .b(v_in2), .rnd(3'b000), .z(mult2_z));
endmodule

module matrix_ADD (
	clk,
	rst_n,
	in_valid,
	in0,
	in1,
	in2,
	in3,
	in4,
	in5,
	in6,
	in7,
	in8,
	out0,
	out1,
	out2,
	done
);
input  clk,rst_n;
input  in_valid;
output reg done;
input [31:0] in0,in1,in2,in3,in4,in5,in6,in7,in8;
output reg [31:0] out0 ,out1, out2;

wire [31:0] add0_z,add1_z,add2_z,add3_z,add4_z,add5_z;
reg  [31:0] add3_b,add4_b,add5_b;
reg in_valid1;

parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch = 2;

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		in_valid1 <= 0;
		done <= 0;
	end
	else begin
		done <= in_valid;
	end
end


always @(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		out0 <= 0;
		out1 <= 0;
		out2 <= 0;
	end
	else if(in_valid) begin
		out0 <= add0_z;
		out1 <= add1_z;
		out2 <= add2_z;
	end
	else begin
		out0 <= out0;
		out1 <= out1;
		out2 <= out2;
	end
end
DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
S0 (.a(in0), .b(in1), .c(in2) , .rnd(3'b000),.z(add0_z));
DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
S1 (.a(in3), .b(in4), .c(in5) , .rnd(3'b000),.z(add1_z));
DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
S2 (.a(in6), .b(in7), .c(in8) , .rnd(3'b000),.z(add2_z));
endmodule

module matrix_ADD_2M(
	clk,
	rst_n,
	in_valid,
	m1_00,
	m1_01,
	m1_02,
	m1_10,
	m1_11,
	m1_12,
	m1_20,
	m1_21,
	m1_22,
	m2_00,
	m2_01,
	m2_02,
	m2_10,
	m2_11,
	m2_12,
	m2_20,
	m2_21,
	m2_22,
	v_out0,
	v_out1,
	v_out2,
	done
);
input  clk, rst_n;
input  in_valid;
output reg  done;
input [31:0]m1_00,m1_01,m1_02,m1_10,m1_11,m1_12,m1_20,m1_21,m1_22,m2_00,m2_01,m2_02,m2_10,m2_11,m2_12,m2_20,m2_21,m2_22;
output reg [31:0] v_out0,v_out1,v_out2;
reg in_valid1,in_valid2;

wire [31:0] partial0,partial1,partial2,partial3,partial4,partial5;

reg [31:0] final0, final1,final2, final3,final4, final5;

wire[31:0] out0,out1,out2;


parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch = 2;

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		in_valid1 <= 0;
		done <= 0;
	end
	else begin
		in_valid1 <= in_valid;
		done <= in_valid1;
	end
end
always @(posedge clk) begin
	final0 <= partial0;
	final1 <= partial3;
	final2 <= partial1;
	final3 <= partial4;
	final4 <= partial2;
	final5 <= partial5;	
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		v_out0 <= 0;
		v_out1 <= 0;
		v_out2 <= 0;
	end
	else if(in_valid1) begin
		v_out0 <= out0;
		v_out1 <= out1;
		v_out2 <= out2;
	end
	else begin
		v_out0 <= v_out0;
		v_out1 <= v_out1;
		v_out2 <= v_out2;
	end
end

DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
S0 (.a(m1_00), .b(m1_01), .c(m1_02) , .rnd(3'b000),.z(partial0));
DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
S1 (.a(m1_10), .b(m1_11), .c(m1_12) , .rnd(3'b000),.z(partial1));
DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
S2 (.a(m1_20), .b(m1_21), .c(m1_22) , .rnd(3'b000),.z(partial2));
DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
S3 (.a(m2_00), .b(m2_01), .c(m2_02) , .rnd(3'b000),.z(partial3));
DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
S4 (.a(m2_10), .b(m2_11), .c(m2_12) , .rnd(3'b000),.z(partial4));
DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
S5 (.a(m2_20), .b(m2_21), .c(m2_22) , .rnd(3'b000),.z(partial5));

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
S6 (.a(final0), .b(final1), .rnd(3'b000),.z(out0));
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
S7 (.a(final2), .b(final3), .rnd(3'b000),.z(out1));
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
S8 (.a(final4), .b(final5), .rnd(3'b000),.z(out2));
endmodule

module LEAKY_RELU(
	clk,
	rst_n,
	in_valid,
	in0,
	in1,
	in2,
	out0,
	out1,
	out2,
	done,
);
input clk ,rst_n ;
input in_valid;
input [31:0]in0 ,in1, in2;
output reg [31:0]out0 ,out1 ,out2;
output reg done;
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch = 2;
parameter point_one_float = 32'b00111101110011001100110011001100;
reg in_valid1;
wire [31:0] no0,no1,no2;
//control one cycle to output 
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		in_valid1<=0;
		done<=0;
	end
	else begin
		in_valid1<=in_valid;
		done<=in_valid1;
	end
end
//
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		out0<=0;
		out1<=0;
		out2<=0;
	end
	else if(in_valid1)begin
		out0<=(in0[31])?no0:in0;
		out1<=(in1[31])?no1:in1;
		out2<=(in2[31])?no2:in2;
	end
end
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) 
M0 (.a(in0), .b(point_one_float), .rnd(3'b000), .z(no0));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) 
M1 (.a(in1), .b(point_one_float), .rnd(3'b000), .z(no1));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) 
M2 (.a(in2), .b(point_one_float), .rnd(3'b000), .z(no2));
endmodule

module Sigmoid (
	clk,
	rst_n,
	in_valid,
	in0,
	in1,
	in2, 
	out0,
	out1,
	out2,
	out_valid 
);

input clk ,rst_n;
input in_valid;
input [31:0]in0 ,in1, in2;
output reg [31:0]out0 ,out1 ,out2;
output reg out_valid;
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch = 0;
parameter one_float = 32'b00111111100000000000000000000000;

reg [31:0] out0_reg,out1_reg,out2_reg;
reg [31:0] add0_a ;
wire [31:0] add0_z,exp_z,div_z;
reg [31:0]  div_b;
reg [2:0] counter;
reg [31:0] in;

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) counter <= 0;
	else if(in_valid) counter <= counter +1;
	else counter <= 0;
end

always @(*) begin
	case(counter)
		'd0 : in = {~in0[31],in0[30:0]};

		'd1 : in = {~in1[31],in1[30:0]};

		'd2 : in = {~in2[31],in2[30:0]};

		default: in = 'dx;
	endcase
end


always @(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		out_valid <= 0;
	end
	else if(counter == 'd5) begin
		out_valid <= 1;
	end
	else out_valid <= 0;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) add0_a <=0;
	else add0_a <= exp_z ;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) div_b <=0;
	else div_b <= add0_z;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		out1 <=0;
		out2 <=0;
		out0 <=0;
	end 
	else if(counter == 'd5) begin
		out0 <= out0_reg ;
		out1 <= out1_reg ;
		out2 <= out2_reg ;
	end 
end

always @(posedge clk) begin
	case(counter)
		'd2 : out0_reg <= div_z;

		'd3:  out1_reg <= div_z;

		'd4:  out2_reg <= div_z;

		default: begin
			out0_reg <= 'dx;
			out1_reg <= 'dx;
			out2_reg <= 'dx;
		end 
	endcase
end

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
S0 (.a(add0_a), .b(one_float), .rnd(3'b000),.z(add0_z));

DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
E0 (.a(in), .z(exp_z));

DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance) 
D0 (.a(one_float), .b(div_b), .rnd(3'b000), .z(div_z));

endmodule


	