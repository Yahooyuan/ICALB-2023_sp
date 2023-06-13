//synopsys translate_off
`include "DW_div.v"
`include "DW_div_seq.v"
`include "DW_div_pipe.v"
//synopsys translate_on

module TRIANGLE(
    clk,
    rst_n,
    in_valid,
    in_length,
    out_cos,
    out_valid,
    out_tri
);
input wire clk, rst_n, in_valid;
input wire [7:0] in_length;

output reg out_valid;
output reg [15:0] out_cos;
output reg [1:0] out_tri;

parameter IDLE = 3'b000;
parameter IN_DATA = 3'b001;
parameter CAL_A = 3'b010;
parameter CAL_B = 3'b011;
parameter CAL_C = 3'b100;
parameter OUT = 3'b101;

reg [2:0] next_state,current_state;
reg [7:0] a,b,c;
wire [15:0] fa,fb,fc;
reg [2:0] in_cnt,out_cnt;
reg [5:0] cal_cnt1,cal_cnt2,cal_cnt3;
reg signed [29:0] upa,upb,upc;
reg signed [16:0] downa,downb,downc;
reg signed [29:0] up;
reg signed [16:0] down;
reg signed [15:0] cosa,cosb,cosc;
wire signed [29:0] cos;
wire [16:0] r;
wire  dv0;
wire statusa;

always@(posedge clk or negedge rst_n)begin
	if(!rst_n) current_state<=IDLE;
	else current_state<=next_state;
end

always@(*)begin
case(current_state)
IDLE:begin
if(in_valid) next_state = IN_DATA;
else next_state = IDLE;
end
IN_DATA:begin
if(in_cnt==3) next_state = CAL_A;
else next_state = IN_DATA;
end
CAL_A:begin
if(cal_cnt1==21) next_state = CAL_B;
else next_state = CAL_A;
end
CAL_B:begin
if(cal_cnt2==21) next_state = CAL_C;
else next_state = CAL_B;
end
CAL_C:begin
if(cal_cnt3==21) next_state = OUT;
else next_state = CAL_C;
end
OUT:begin
if(out_cnt==3) next_state = IDLE;
else next_state = OUT;
end
default: next_state = IDLE;
endcase
end

always@(posedge clk or negedge rst_n)begin
if(!rst_n) in_cnt<=0;
else if(in_valid) in_cnt<=in_cnt+1;
else in_cnt<=0;
end

always@(posedge clk or negedge rst_n)begin
if(!rst_n) cal_cnt1<=0;
else if(next_state==CAL_A) cal_cnt1<=cal_cnt1+1;
else cal_cnt1<=0;
end

always@(posedge clk or negedge rst_n)begin
if(!rst_n) cal_cnt2<=0;
else if(next_state==CAL_B) cal_cnt2<=cal_cnt2+1;
else cal_cnt2<=0;
end

always@(posedge clk or negedge rst_n)begin
if(!rst_n) cal_cnt3<=0;
else if(next_state==CAL_C) cal_cnt3<=cal_cnt3+1;
else cal_cnt3<=0;
end

always@(posedge clk or negedge rst_n)begin
if(!rst_n) out_cnt<=0;
else if(next_state==OUT) out_cnt<=out_cnt+1;
else out_cnt<=0;
end

always@(posedge clk or negedge rst_n)begin
if(!rst_n)begin
a<=0;
b<=0;
c<=0;
end
else if(in_valid&&in_cnt==0) a<=in_length;
else if(in_valid&&in_cnt==1) b<=in_length;
else if(in_valid&&in_cnt==2) c<=in_length;
end

always@(*)begin
//multi 4096 can make area smaller 
//upa = ((b*b)+(c*c)-(a*a))*4096
upa = ((b*b)+(c*c)-(a*a))*2**12;
downa = b*c;
upb = ((a*a)+(c*c)-(b*b))*2**12;
downb = a*c;
upc = ((a*a)+(b*b)-(c*c))*2**12;
downc = a*b;
end


always@(posedge clk or negedge rst_n)begin
if(!rst_n)begin
up<=0;
down<=0;
end
else if(next_state==CAL_A)begin
up<=upa;
down<=downa;
end
else if(next_state==CAL_B)begin
up<=upb;
down<=downb;
end
else if(next_state==CAL_C)begin
up<=upc;
down<=downc;
end
else begin
up<=0;
down<=0;
end
end



DW_div_pipe #(30,
17,
1, 0,
20,
0,
1,
1)
U1 (.clk(clk),.rst_n(rst_n),.en(1'b1),.a(up),.b(down),.quotient(cos),
.remainder(r),.divide_by_0(dv0));

always@(posedge clk or negedge rst_n)begin
if(!rst_n)begin
cosa<=0;
cosb<=0;
cosc<=0;
end
else if(current_state==CAL_A&&cal_cnt1==20)begin
cosa<= cos;
end
else if(current_state==CAL_B&&cal_cnt2==20)begin
cosb<= cos;
end
else if(current_state==CAL_C&&cal_cnt3==20)begin
cosc<= cos;
end
end

always@(posedge clk or negedge rst_n)begin
if(!rst_n)begin
out_valid<=0;
end
else if(next_state==OUT) out_valid<=1;
else out_valid<=0;
end 

always@(posedge clk or negedge rst_n)begin
if(!rst_n)begin
out_cos<=0;
end
else if(next_state==OUT&&out_cnt==0) out_cos<=cosa;
else if(next_state==OUT&&out_cnt==1) out_cos<=cosb;
else if(next_state==OUT&&out_cnt==2) out_cos<=cosc;
end

always@(posedge clk or negedge rst_n)begin
if(!rst_n)begin
out_tri<=0;
end
else if(next_state==OUT&&out_cnt==0)begin
if(cosa==0||cosb==0||cosc==0) out_tri<=2'b11;
else if(cosa<0||cosb<0||cosc<0) out_tri<=2'b01;
else if(cosa>0&&cosb>0&&cosc>0) out_tri<=2'b00;
end
end

endmodule
