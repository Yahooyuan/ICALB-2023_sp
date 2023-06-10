module CC(
  in_s0,
  in_s1,
  in_s2,
  in_s3,
  in_s4,
  in_s5,
  in_s6,
  opt,
  a,
  b,
  s_id0,
  s_id1,
  s_id2,
  s_id3,
  s_id4,
  s_id5,
  s_id6,
  out

);
input [3:0]in_s0;
input [3:0]in_s1;
input [3:0]in_s2;
input [3:0]in_s3;
input [3:0]in_s4;
input [3:0]in_s5;
input [3:0]in_s6;
input [2:0]opt;
input [1:0]a;
input [2:0]b;
output reg[2:0] s_id0;
output reg[2:0] s_id1;
output reg[2:0] s_id2;
output reg[2:0] s_id3;
output reg[2:0] s_id4;
output reg[2:0] s_id5;
output reg[2:0] s_id6;
output reg [2:0] out; 
//==================================================================
// reg & wire
//==================================================================
wire signed[3:0]ss0;
wire signed[3:0]ss1;
wire signed[3:0]ss2;
wire signed[3:0]ss3;
wire signed[3:0]ss4;
wire signed[3:0]ss5;
wire signed[3:0]ss6;

reg signed[3:0]ssr0,ssr1,ssr2,ssr3,ssr4,ssr5,ssr6;
reg [3:0]ussr0,ussr1,ussr2,ussr3,ussr4,ussr5,ussr6;

wire [3:0]uss0;
wire [3:0]uss1;
wire [3:0]uss2;
wire [3:0]uss3;
wire [3:0]uss4;
wire [3:0]uss5;
wire [3:0]uss6;
wire [2:0]c;
wire [6:0]wsum;
reg  [6:0]sum,sum1;
reg signed [6:0]avg;
reg signed [6:0]ps;
reg signed [7:0]aps;//agument ps
reg signed[7:0]transsc0,transsc1,transsc2,transsc3,transsc4,transsc5,transsc6;//trans score 
reg signed[7:0]divs0,divs1,divs2,divs3,divs4,divs5,divs6;
reg ps0,ps1,ps2,ps3,ps4,ps5,ps6;
reg [2:0]ps_num;
reg[2:0]fa_num;
//S1 wire 
wire [3:0] lv1_s0, lv1_s2,lv1_s3,lv1_s4,lv1_s5,lv1_s6;
wire [3:0] lv2_s0,lv2_s1,lv2_s2,lv2_s3,lv2_s4,lv2_s6;
wire [3:0] lv3_s0,lv3_s1,lv3_s2,lv3_s3,lv3_s4,lv3_s5;
wire [3:0] lv4_s1,lv4_s2,lv4_s4,lv4_s6;
wire [3:0] lv5_s2,lv5_s3,lv5_s4,lv5_s5;
wire [3:0] lv6_s1,lv6_s2,lv6_s3,lv6_s4,lv6_s5,lv6_s6;

wire [2:0] lv1_id0,lv1_id2,lv1_id3,lv1_id4,lv1_id5,lv1_id6;
wire [2:0] lv2_id0,lv2_id1,lv2_id2,lv2_id3,lv2_id4,lv2_id6;
wire [2:0] lv3_id0,lv3_id1,lv3_id2,lv3_id3,lv3_id4,lv3_id5;
wire [2:0] lv4_id1,lv4_id2,lv4_id4,lv4_id6;
wire [2:0] lv5_id2,lv5_id3,lv5_id4,lv5_id5;
wire [2:0] lv6_id1,lv6_id2,lv6_id3,lv6_id4,lv6_id5,lv6_id6;
//S2 wire 
wire signed [3:0] lv1_ss0, lv1_ss2,lv1_ss3,lv1_ss4,lv1_ss5,lv1_ss6;
wire signed [3:0] lv2_ss0,lv2_ss1,lv2_ss2,lv2_ss3,lv2_ss4,lv2_ss6;
wire signed [3:0] lv3_ss0,lv3_ss1,lv3_ss2,lv3_ss3,lv3_ss4,lv3_ss5;
wire signed [3:0] lv4_ss1,lv4_ss2,lv4_ss4,lv4_ss6;
wire signed [3:0] lv5_ss2,lv5_ss3,lv5_ss4,lv5_ss5;
wire signed [3:0] lv6_ss1,lv6_ss2,lv6_ss3,lv6_ss4,lv6_ss5,lv6_ss6;

wire [2:0] lv1_sid0,lv1_sid2,lv1_sid3,lv1_sid4,lv1_sid5,lv1_sid6;
wire [2:0] lv2_sid0,lv2_sid1,lv2_sid2,lv2_sid3,lv2_sid4,lv2_sid6;
wire [2:0] lv3_sid0,lv3_sid1,lv3_sid2,lv3_sid3,lv3_sid4,lv3_sid5;
wire [2:0] lv4_sid1,lv4_sid2,lv4_sid4,lv4_sid6;
wire [2:0] lv5_sid2,lv5_sid3,lv5_sid4,lv5_sid5;
wire [2:0] lv6_sid1,lv6_sid2,lv6_sid3,lv6_sid4,lv6_sid5,lv6_sid6;
//S3 wire  decending unsigned
wire [3:0] dlv1_s0, dlv1_s2,dlv1_s3,dlv1_s4,dlv1_s5,dlv1_s6;
wire [3:0] dlv2_s0,dlv2_s1,dlv2_s2,dlv2_s3,dlv2_s4,dlv2_s6;
wire [3:0] dlv3_s0,dlv3_s1,dlv3_s2,dlv3_s3,dlv3_s4,dlv3_s5;
wire [3:0] dlv4_s1,dlv4_s2,dlv4_s4,dlv4_s6;
wire [3:0] dlv5_s2,dlv5_s3,dlv5_s4,dlv5_s5;
wire [3:0] dlv6_s1,dlv6_s2,dlv6_s3,dlv6_s4,dlv6_s5,dlv6_s6;

wire [2:0] dlv1_id0,dlv1_id2,dlv1_id3,dlv1_id4,dlv1_id5,dlv1_id6;
wire [2:0] dlv2_id0,dlv2_id1,dlv2_id2,dlv2_id3,dlv2_id4,dlv2_id6;
wire [2:0] dlv3_id0,dlv3_id1,dlv3_id2,dlv3_id3,dlv3_id4,dlv3_id5;
wire [2:0] dlv4_id1,dlv4_id2,dlv4_id4,dlv4_id6;
wire [2:0] dlv5_id2,dlv5_id3,dlv5_id4,dlv5_id5;
wire [2:0] dlv6_id1,dlv6_id2,dlv6_id3,dlv6_id4,dlv6_id5,dlv6_id6;
//S4 wire decanding signed
wire signed [3:0] dlv1_ss0, dlv1_ss2,dlv1_ss3,dlv1_ss4,dlv1_ss5,dlv1_ss6;
wire signed [3:0] dlv2_ss0,dlv2_ss1,dlv2_ss2,dlv2_ss3,dlv2_ss4,dlv2_ss6;
wire signed [3:0] dlv3_ss0,dlv3_ss1,dlv3_ss2,dlv3_ss3,dlv3_ss4,dlv3_ss5;
wire signed [3:0] dlv4_ss1,dlv4_ss2,dlv4_ss4,dlv4_ss6;
wire signed [3:0] dlv5_ss2,dlv5_ss3,dlv5_ss4,dlv5_ss5;
wire signed [3:0] dlv6_ss1,dlv6_ss2,dlv6_ss3,dlv6_ss4,dlv6_ss5,dlv6_ss6;

wire [2:0] dlv1_sid0,dlv1_sid2,dlv1_sid3,dlv1_sid4,dlv1_sid5,dlv1_sid6;
wire [2:0] dlv2_sid0,dlv2_sid1,dlv2_sid2,dlv2_sid3,dlv2_sid4,dlv2_sid6;
wire [2:0] dlv3_sid0,dlv3_sid1,dlv3_sid2,dlv3_sid3,dlv3_sid4,dlv3_sid5;
wire [2:0] dlv4_sid1,dlv4_sid2,dlv4_sid4,dlv4_sid6;
wire [2:0] dlv5_sid2,dlv5_sid3,dlv5_sid4,dlv5_sid5;
wire [2:0] dlv6_sid1,dlv6_sid2,dlv6_sid3,dlv6_sid4,dlv6_sid5,dlv6_sid6;

wire [2:0] s1_id0,s1_id1,s1_id2,s1_id3,s1_id4,s1_id5,s1_id6;
wire [2:0] s2_id0,s2_id1,s2_id2,s2_id3,s2_id4,s2_id5,s2_id6;
wire [2:0] s3_id0,s3_id1,s3_id2,s3_id3,s3_id4,s3_id5,s3_id6;
wire [2:0] s4_id0,s4_id1,s4_id2,s4_id3,s4_id4,s4_id5,s4_id6;
//==================================================================
// design
//==================================================================
assign ss0 = in_s0;
assign ss1 = in_s1;
assign ss2 = in_s2;
assign ss3 = in_s3;
assign ss4 = in_s4;
assign ss5 = in_s5;
assign ss6 = in_s6;

assign uss0 = in_s0;
assign uss1 = in_s1;
assign uss2 = in_s2;
assign uss3 = in_s3;
assign uss4 = in_s4;
assign uss5 = in_s5;
assign uss6 = in_s6;

assign c= a+1;

always@(*)begin
ssr0 = in_s0;
ssr1 = in_s1;
ssr2 = in_s2;
ssr3 = in_s3;
ssr4 = in_s4;
ssr5 = in_s5;
ssr6 = in_s6;
end

always@(*)begin
ussr0 = in_s0;
ussr1 = in_s1;
ussr2 = in_s2;
ussr3 = in_s3;
ussr4 = in_s4;
ussr5 = in_s5;
ussr6 = in_s6;
end


//Passing score cal
always@(*)begin
case(opt[0])
1'b0:sum = uss0+uss1+uss2+uss3+uss4+uss5+uss6;
1'b1:sum = ss0+ss1+ss2+ss3+ss4+ss5+ss6;
endcase
end

always@(*)begin
case(opt[0])
1'b0:sum1 = uss0+uss1+uss2+uss3+uss4+uss5+uss6;
1'b1:sum1 = ss0+ss1+ss2+ss3+ss4+ss5+ss6;
endcase
end
assign wsum =ss0+ss1+ss2+ss3+ss4+ss5+ss6;
always@(*)begin
if (wsum[6]==1&&opt[0]==1)begin
sum = -1*sum1;
avg = sum/7;
avg = avg*-1;
//sum = sum1;
end
else 
avg = sum1/7;
end

always@(*)begin
ps = avg-a;
end
always@(*)begin
aps = ps;
end
//linear transformation
always@(*)begin
if(opt[0]==1&&ss0[3]==1)begin
ssr0 = ss0*-1;
divs0 = ssr0/c;
divs0 = divs0*-1;
transsc0 = divs0+b;
end
else begin
divs0 = 0;
transsc0 = uss0*c+b;
end
end

always@(*)begin
if(opt[0]==1&&ss1[3]==1)begin
ssr1 = ss1*-1;
divs1 = ssr1/c;
divs1 = divs1*-1;
transsc1 = divs1+b;
end
else begin
divs1 = 0;
transsc1 = uss1*c+b;
end
end

always@(*)begin
if(opt[0]==1&&ss2[3]==1)begin
ssr2 = ss2*-1;
divs2 = ssr2/c;
divs2 = divs2*-1;
transsc2 = divs2+b;
end
else begin
divs2 = 0;
transsc2 = uss2*c+b;
end
end

always@(*)begin
if(opt[0]==1&&ss3[3]==1)begin
ssr3 = ss3*-1;
divs3 = ssr3/c;
divs3 = divs3*-1;
transsc3 = divs3+b;
end
else begin
divs3 = 0;
transsc3 = uss3*c+b;
end
end

always@(*)begin
if(opt[0]==1&&ss4[3]==1)begin
ssr4 = -1*ss4;
divs4 = ssr4/c;
divs4 = divs4*-1;
transsc4 = divs4+b;
end
else begin
divs4 = 0;
transsc4 = uss4*c+b;
end
end


always@(*)begin
if(opt[0]==1&&ss5[3]==1)begin
ssr5 = ss5*-1;
divs5 = ssr5/c;
divs5 = divs5*-1;
transsc5 = divs5+b;
end
else begin
divs5 = 0;
transsc5 = uss5*c+b;
end
end

always@(*)begin
if(opt[0]==1&&ss6[3]==1)begin
ssr6 = ss6*-1;
divs6 = ssr6/c;
divs6 = divs6*-1;
transsc6 = divs6+b;
end
else begin
divs6 = 0;
transsc6 = uss6*c+b;
end
end
//############################################################################
//Counting part
//############################################################################
always@(*)begin
if(transsc0>=aps)
ps0 = 1;
else 
ps0 = 0;
end

always@(*)begin
if(transsc1>=aps)
ps1 = 1;
else 
ps1 = 0;
end

always@(*)begin
if(transsc2>=aps)
ps2 = 1;
else
ps2 = 0;
end

always@(*)begin
if(transsc3>=aps)
ps3 = 1;
else
ps3 = 0;
end

always@(*)begin
if(transsc4>=aps)
ps4 = 1;
else
ps4 = 0;
end

always@(*)begin
if(transsc5>=aps)
ps5 = 1;
else
ps5 = 0;
end

always@(*)begin
if(transsc6>=aps)
ps6 = 1;
else
ps6 = 0;
end

always@(*)begin
ps_num = ps0+ps1+ps2+ps3+ps4+ps5+ps6;
end
always@(*)begin
fa_num = 7-ps_num;
end

always@(*)begin
case(opt[2])
1'b0:out = ps_num;
1'b1:out = fa_num;
endcase
end



//ST1 s1(.in0(uss0),.in1(uss1),.in2(uss2),.in3(uss3),.in4(uss4),.in5(uss5),.in6(uss6),.id0(s1_id0),.id1(s1_id1),.id2(s1_id2),.id3(s1_id3),.id4(s1_id4),.id5(s1_id5),.id6(s1_id6));

//ST2 s2(.in0(ss0),.in1(ss1),.in2(ss2),.in3(ss3),.in4(ss4),.in5(ss5),.in6(ss6),.id0(s2_id0),.id1(s2_id1),.id2(s2_id2),.id3(s2_id3),.id4(s2_id4),.id5(s2_id5),.id6(s2_id6));

//ST3 s3(.in0(uss0),.in1(uss1),.in2(uss2),.in3(uss3),.in4(uss4),.in5(uss5),.in6(uss6),.id0(s3_id0),.id1(s3_id1),.id2(s3_id2),.id3(s3_id3),.id4(s3_id4),.id5(s3_id5),.id6(s3_id6));
 
//ST4 s4(.in0(ss0),.in1(ss1),.in2(ss2),.in3(ss3),.in4(ss4),.in5(ss5),.in6(ss6),.id0(s4_id0),.id1(s4_id1),.id2(s4_id2),.id3(s4_id3),.id4(s4_id4),.id5(s4_id5),.id6(s4_id6));

always@(*)begin
if(opt[0]==0&&opt[1]==0)begin
s_id0 = s1_id0;
s_id1 = s1_id1;
s_id2 = s1_id2;
s_id3 = s1_id3;
s_id4 = s1_id4;
s_id5 = s1_id5;
s_id6 = s1_id6;
end
else if(opt[0]==1&&opt[1]==0)begin
s_id0 = s2_id0;
s_id1 = s2_id1;
s_id2 = s2_id2;
s_id3 = s2_id3;
s_id4 = s2_id4;
s_id5 = s2_id5;
s_id6 = s2_id6;
end
else if(opt[0]==0&&opt[1]==1)begin
s_id0 = s3_id0;
s_id1 = s3_id1;
s_id2 = s3_id2;
s_id3 = s3_id3;
s_id4 = s3_id4;
s_id5 = s3_id5;
s_id6 = s3_id6;
end
else begin
s_id0 = s4_id0;
s_id1 = s4_id1;
s_id2 = s4_id2;
s_id3 = s4_id3;
s_id4 = s4_id4;
s_id5 = s4_id5;
s_id6 = s4_id6;
end
end

//Sorting  1
assign lv1_s0 = (uss0>uss6)?uss6:uss0;
assign lv1_s6 = (uss0>uss6)?uss0:uss6;
assign lv1_s2 =(uss2>uss3)?uss3:uss2;
assign lv1_s3 =(uss2>uss3)?uss2:uss3;
assign lv1_s4 = (uss4>uss5)?uss5:uss4;
assign lv1_s5 = (uss4>uss5)?uss4:uss5;
assign lv1_id0 = (uss0>uss6)?6:0;
assign lv1_id6 = (uss0>uss6)?0:6;
assign lv1_id2 =(uss2>uss3)?3:2;
assign lv1_id3 =(uss2>uss3)?2:3;
assign lv1_id4 = (uss4>uss5)?5:4;
assign lv1_id5 = (uss4>uss5)?4:5;

assign lv2_s0 = (lv1_s0>lv1_s2)?lv1_s2:(lv1_s0==lv1_s2&&lv1_id0>lv1_id2)?lv1_s2:lv1_s0;
assign lv2_s2 = (lv1_s0>lv1_s2)?lv1_s0:(lv1_s0==lv1_s2&&lv1_id0>lv1_id2)?lv1_s0:lv1_s2;
assign lv2_s1 = (uss1>lv1_s4)?lv1_s4:uss1;
assign lv2_s4 = (uss1>lv1_s4)?uss1:lv1_s4;
assign lv2_s3 = (lv1_s3>lv1_s6)?lv1_s6:(lv1_s3==lv1_s6&&lv1_id3>lv1_id6)?lv1_s6:lv1_s3;
assign lv2_s6 = (lv1_s3>lv1_s6)?lv1_s3:(lv1_s3==lv1_s6&&lv1_id3>lv1_id6)?lv1_s3:lv1_s6;
assign lv2_id0 = (lv1_s0>lv1_s2)?lv1_id2:(lv1_s0==lv1_s2&&lv1_id0>lv1_id2)?lv1_id2:lv1_id0;
assign lv2_id2 = (lv1_s0>lv1_s2)?lv1_id0:(lv1_s0==lv1_s2&&lv1_id0>lv1_id2)?lv1_id0:lv1_id2;
assign lv2_id1 = (uss1>lv1_s4)?lv1_id4:1;
assign lv2_id4 = (uss1>lv1_s4)?1:lv1_id4;
assign lv2_id3 = (lv1_s3>lv1_s6)?lv1_id6:(lv1_s3==lv1_s6&&lv1_id3>lv1_id6)?lv1_id6:lv1_id3;
assign lv2_id6 = (lv1_s3>lv1_s6)?lv1_id3:(lv1_s3==lv1_s6&&lv1_id3>lv1_id6)?lv1_id3:lv1_id6;

assign lv3_s0 = (lv2_s0>lv2_s1)?lv2_s1:(lv2_s0==lv2_s1&&lv2_id0>lv2_id1)?lv2_s1:lv2_s0;
assign lv3_s1 = (lv2_s0>lv2_s1)?lv2_s0:(lv2_s0==lv2_s1&&lv2_id0>lv2_id1)?lv2_s0:lv2_s1;
assign lv3_s2 = (lv2_s2>lv1_s5)?lv1_s5:(lv2_s2==lv1_s5&&lv2_id2>lv1_id5)?lv1_s5:lv2_s2;
assign lv3_s5 = (lv2_s2>lv1_s5)?lv2_s2:(lv2_s2==lv1_s5&&lv2_id2>lv1_id5)?lv2_s2:lv1_s5;
assign lv3_s3 = (lv2_s3>lv2_s4)?lv2_s4:(lv2_s3==lv2_s4&&lv2_id3>lv2_id4)?lv2_s4:lv2_s3;
assign lv3_s4 = (lv2_s3>lv2_s4)?lv2_s3:(lv2_s3==lv2_s4&&lv2_id3>lv2_id4)?lv2_s3:lv2_s4;
assign lv3_id0 = (lv2_s0>lv2_s1)?lv2_id1:(lv2_s0==lv2_s1&&lv2_id0>lv2_id1)?lv2_id1:lv2_id0;
assign lv3_id1 = (lv2_s0>lv2_s1)?lv2_id0:(lv2_s0==lv2_s1&&lv2_id0>lv2_id1)?lv2_id0:lv2_id1;
assign lv3_id2 = (lv2_s2>lv1_s5)?lv1_id5:(lv2_s2==lv1_s5&&lv2_id2>lv1_id5)?lv1_id5:lv2_id2;
assign lv3_id5 = (lv2_s2>lv1_s5)?lv2_id2:(lv2_s2==lv1_s5&&lv2_id2>lv1_id5)?lv2_id2:lv1_id5;
assign lv3_id3 = (lv2_s3>lv2_s4)?lv2_id4:(lv2_s3==lv2_s4&&lv2_id3>lv2_id4)?lv2_id4:lv2_id3;
assign lv3_id4 = (lv2_s3>lv2_s4)?lv2_id3:(lv2_s3==lv2_s4&&lv2_id3>lv2_id4)?lv2_id3:lv2_id4;

assign lv4_s1 = (lv3_s1>lv3_s2)?lv3_s2:(lv3_s1==lv3_s2&&lv3_id1>lv3_id2)?lv3_s2:lv3_s1;
assign lv4_s2 = (lv3_s1>lv3_s2)?lv3_s1:(lv3_s1==lv3_s2&&lv3_id1>lv3_id2)?lv3_s1:lv3_s2;
assign lv4_s4 = (lv3_s4>lv2_s6)?lv2_s6:(lv3_s4==lv2_s6&&lv3_id4>lv2_id6)?lv2_s6:lv3_s4;
assign lv4_s6 = (lv3_s4>lv2_s6)?lv3_s4:(lv3_s4==lv2_s6&&lv3_id4>lv2_id6)?lv3_s4:lv2_s6;
assign lv4_id1 = (lv3_s1>lv3_s2)?lv3_id2:(lv3_s1==lv3_s2&&lv3_id1>lv3_id2)?lv3_id2:lv3_id1;
assign lv4_id2 = (lv3_s1>lv3_s2)?lv3_id1:(lv3_s1==lv3_s2&&lv3_id1>lv3_id2)?lv3_id1:lv3_id2;
assign lv4_id4 = (lv3_s4>lv2_s6)?lv2_id6:(lv3_s4==lv2_s6&&lv3_id4>lv2_id6)?lv2_id6:lv3_id4;
assign lv4_id6 =(lv3_s4>lv2_s6)?lv3_id4:(lv3_s4==lv2_s6&&lv3_id4>lv2_id6)?lv3_id4:lv2_id6;

assign lv5_s2 = (lv4_s2>lv3_s3)?lv3_s3:(lv4_s2==lv3_s3&&lv4_id2>lv3_id3)?lv3_s3:lv4_s2;
assign lv5_s3 = (lv4_s2>lv3_s3)?lv4_s2:(lv4_s2==lv3_s3&&lv4_id2>lv3_id3)?lv4_s2:lv3_s3;
assign lv5_s4 = (lv4_s4>lv3_s5)?lv3_s5:(lv4_s4==lv3_s5&&lv4_id4>lv3_id5)?lv3_s5:lv4_s4;
assign lv5_s5 = (lv4_s4>lv3_s5)?lv4_s4:(lv4_s4==lv3_s5&&lv4_id4>lv3_id5)?lv4_s4:lv3_s5;
assign lv5_id2 = (lv4_s2>lv3_s3)?lv3_id3:(lv4_s2==lv3_s3&&lv4_id2>lv3_id3)?lv3_id3:lv4_id2;
assign lv5_id3 = (lv4_s2>lv3_s3)?lv4_id2:(lv4_s2==lv3_s3&&lv4_id2>lv3_id3)?lv4_id2:lv3_id3;
assign lv5_id4 = (lv4_s4>lv3_s5)?lv3_id5:(lv4_s4==lv3_s5&&lv4_id4>lv3_id5)?lv3_id5:lv4_id4;
assign lv5_id5 = (lv4_s4>lv3_s5)?lv4_id4:(lv4_s4==lv3_s5&&lv4_id4>lv3_id5)?lv4_id4:lv3_id5;

assign lv6_s1 = (lv4_s1>lv5_s2)?lv5_s2:(lv4_s1==lv5_s2&&lv4_id1>lv5_id2)?lv5_s2:lv4_s1;
assign lv6_s2 = (lv4_s1>lv5_s2)?lv4_s1:(lv4_s1==lv5_s2&&lv4_id1>lv5_id2)?lv4_s1:lv5_s2;
assign lv6_s3 = (lv5_s3>lv5_s4)?lv5_s4:(lv5_s3==lv5_s4&&lv5_id3>lv5_id4)?lv5_s4:lv5_s3;
assign lv6_s4 = (lv5_s3>lv5_s4)?lv5_s3:(lv5_s3==lv5_s4&&lv5_id3>lv5_id4)?lv5_s3:lv5_s4;
assign lv6_s5 = (lv5_s5>lv4_s6)?lv4_s6:(lv5_s5==lv4_s6&&lv5_id5>lv4_id6)?lv4_s6:lv5_s5;
assign lv6_s6 = (lv5_s5>lv4_s6)?lv5_s5:(lv5_s5==lv4_s6&&lv5_id5>lv4_id6)?lv5_s5:lv4_s6;
assign lv6_id1 = (lv4_s1>lv5_s2)?lv5_id2:(lv4_s1==lv5_s2&&lv4_id1>lv5_id2)?lv5_id2:lv4_id1;
assign lv6_id2 = (lv4_s1>lv5_s2)?lv4_id1:(lv4_s1==lv5_s2&&lv4_id1>lv5_id2)?lv4_id1:lv5_id2;
assign lv6_id3 = (lv5_s3>lv5_s4)?lv5_id4:(lv5_s3==lv5_s4&&lv5_id3>lv5_id4)?lv5_id4:lv5_id3;
assign lv6_id4 = (lv5_s3>lv5_s4)?lv5_id3:(lv5_s3==lv5_s4&&lv5_id3>lv5_id4)?lv5_id3:lv5_id4;
assign lv6_id5 = (lv5_s5>lv4_s6)?lv4_id6:(lv5_s5==lv4_s6&&lv5_id5>lv4_id6)?lv4_id6:lv5_id5;
assign lv6_id6 = (lv5_s5>lv4_s6)?lv5_id5:(lv5_s5==lv4_s6&&lv5_id5>lv4_id6)?lv5_id5:lv4_id6;

assign s1_id0 = lv3_id0;
assign s1_id1 = lv6_id1;
assign s1_id2 = lv6_id2;
assign s1_id3 = lv6_id3;
assign s1_id4 = lv6_id4;
assign s1_id5 = lv6_id5;
assign s1_id6 = lv6_id6;
//########################################
//Sorting 2
//########################################
assign lv1_ss0 = (ss0>ss6)?ss6:ss0;
assign lv1_ss6 = (ss0>ss6)?ss0:ss6;
assign lv1_ss2 =(ss2>ss3)?ss3:ss2;
assign lv1_ss3 =(ss2>ss3)?ss2:ss3;
assign lv1_ss4 = (ss4>ss5)?ss5:ss4;
assign lv1_ss5 = (ss4>ss5)?ss4:ss5;
assign lv1_sid0 = (ss0>ss6)?6:0;
assign lv1_sid6 = (ss0>ss6)?0:6;
assign lv1_sid2 =(ss2>ss3)?3:2;
assign lv1_sid3 =(ss2>ss3)?2:3;
assign lv1_sid4 = (ss4>ss5)?5:4;
assign lv1_sid5 = (ss4>ss5)?4:5;

assign lv2_ss0 = (lv1_ss0>lv1_ss2)?lv1_ss2:(lv1_ss0==lv1_ss2&&lv1_sid0>lv1_sid2)?lv1_ss2:lv1_ss0;
assign lv2_ss2 = (lv1_ss0>lv1_ss2)?lv1_ss0:(lv1_ss0==lv1_ss2&&lv1_sid0>lv1_sid2)?lv1_ss0:lv1_ss2;
assign lv2_ss1 = (ss1>lv1_ss4)?lv1_ss4:ss1;
assign lv2_ss4 = (ss1>lv1_ss4)?ss1:lv1_ss4;
assign lv2_ss3 = (lv1_ss3>lv1_ss6)?lv1_ss6:(lv1_ss3==lv1_ss6&&lv1_sid3>lv1_sid6)?lv1_ss6:lv1_ss3;
assign lv2_ss6 = (lv1_ss3>lv1_ss6)?lv1_ss3:(lv1_ss3==lv1_ss6&&lv1_sid3>lv1_sid6)?lv1_ss3:lv1_ss6;
assign lv2_sid0 = (lv1_ss0>lv1_ss2)?lv1_sid2:(lv1_ss0==lv1_ss2&&lv1_sid0>lv1_sid2)?lv1_sid2:lv1_sid0;
assign lv2_sid2 = (lv1_ss0>lv1_ss2)?lv1_sid0:(lv1_ss0==lv1_ss2&&lv1_sid0>lv1_sid2)?lv1_sid0:lv1_sid2;
assign lv2_sid1 = (ss1>lv1_ss4)?lv1_sid4:1;
assign lv2_sid4 = (ss1>lv1_ss4)?1:lv1_sid4;
assign lv2_sid3 = (lv1_ss3>lv1_ss6)?lv1_sid6:(lv1_ss3==lv1_ss6&&lv1_sid3>lv1_sid6)?lv1_sid6:lv1_sid3;
assign lv2_sid6 = (lv1_ss3>lv1_ss6)?lv1_sid3:(lv1_ss3==lv1_ss6&&lv1_sid3>lv1_sid6)?lv1_sid3:lv1_sid6;

assign lv3_ss0 = (lv2_ss0>lv2_ss1)?lv2_ss1:(lv2_ss0==lv2_ss1&&lv2_sid0>lv2_sid1)?lv2_ss1:lv2_ss0;
assign lv3_ss1 = (lv2_ss0>lv2_ss1)?lv2_ss0:(lv2_ss0==lv2_ss1&&lv2_sid0>lv2_sid1)?lv2_ss0:lv2_ss1;
assign lv3_ss2 = (lv2_ss2>lv1_ss5)?lv1_ss5:(lv2_ss2==lv1_ss5&&lv2_sid2>lv1_sid5)?lv1_ss5:lv2_ss2;
assign lv3_ss5 = (lv2_ss2>lv1_ss5)?lv2_ss2:(lv2_ss2==lv1_ss5&&lv2_sid2>lv1_sid5)?lv2_ss2:lv1_ss5;
assign lv3_ss3 = (lv2_ss3>lv2_ss4)?lv2_ss4:(lv2_ss3==lv2_ss4&&lv2_sid3>lv2_sid4)?lv2_ss4:lv2_ss3;
assign lv3_ss4 = (lv2_ss3>lv2_ss4)?lv2_ss3:(lv2_ss3==lv2_ss4&&lv2_sid3>lv2_sid4)?lv2_ss3:lv2_ss4;
assign lv3_sid0 = (lv2_ss0>lv2_ss1)?lv2_sid1:(lv2_ss0==lv2_ss1&&lv2_sid0>lv2_sid1)?lv2_sid1:lv2_sid0;
assign lv3_sid1 = (lv2_ss0>lv2_ss1)?lv2_sid0:(lv2_ss0==lv2_ss1&&lv2_sid0>lv2_sid1)?lv2_sid0:lv2_sid1;
assign lv3_sid2 = (lv2_ss2>lv1_ss5)?lv1_sid5:(lv2_ss2==lv1_ss5&&lv2_sid2>lv1_sid5)?lv1_sid5:lv2_sid2;
assign lv3_sid5 = (lv2_ss2>lv1_ss5)?lv2_sid2:(lv2_ss2==lv1_ss5&&lv2_sid2>lv1_sid5)?lv2_sid2:lv1_sid5;
assign lv3_sid3 = (lv2_ss3>lv2_ss4)?lv2_sid4:(lv2_ss3==lv2_ss4&&lv2_sid3>lv2_sid4)?lv2_sid4:lv2_sid3;
assign lv3_sid4 = (lv2_ss3>lv2_ss4)?lv2_sid3:(lv2_ss3==lv2_ss4&&lv2_sid3>lv2_sid4)?lv2_sid3:lv2_sid4;

assign lv4_ss1 = (lv3_ss1>lv3_ss2)?lv3_ss2:(lv3_ss1==lv3_ss2&&lv3_sid1>lv3_sid2)?lv3_ss2:lv3_ss1;
assign lv4_ss2 = (lv3_ss1>lv3_ss2)?lv3_ss1:(lv3_ss1==lv3_ss2&&lv3_sid1>lv3_sid2)?lv3_ss1:lv3_ss2;
assign lv4_ss4 = (lv3_ss4>lv2_ss6)?lv2_ss6:(lv3_ss4==lv2_ss6&&lv3_sid4>lv2_sid6)?lv2_ss6:lv3_ss4;
assign lv4_ss6 = (lv3_ss4>lv2_ss6)?lv3_ss4:(lv3_ss4==lv2_ss6&&lv3_sid4>lv2_sid6)?lv3_ss4:lv2_ss6;
assign lv4_sid1 = (lv3_ss1>lv3_ss2)?lv3_sid2:(lv3_ss1==lv3_ss2&&lv3_sid1>lv3_sid2)?lv3_sid2:lv3_sid1;
assign lv4_sid2 = (lv3_ss1>lv3_ss2)?lv3_sid1:(lv3_ss1==lv3_ss2&&lv3_sid1>lv3_sid2)?lv3_sid1:lv3_sid2;
assign lv4_sid4 = (lv3_ss4>lv2_ss6)?lv2_sid6:(lv3_ss4==lv2_ss6&&lv3_sid4>lv2_sid6)?lv2_sid6:lv3_sid4;
assign lv4_sid6 =(lv3_ss4>lv2_ss6)?lv3_sid4:(lv3_ss4==lv2_ss6&&lv3_sid4>lv2_sid6)?lv3_sid4:lv2_sid6;

assign lv5_ss2 = (lv4_ss2>lv3_ss3)?lv3_ss3:(lv4_ss2==lv3_ss3&&lv4_sid2>lv3_sid3)?lv3_ss3:lv4_ss2;
assign lv5_ss3 = (lv4_ss2>lv3_ss3)?lv4_ss2:(lv4_ss2==lv3_ss3&&lv4_sid2>lv3_sid3)?lv4_ss2:lv3_ss3;
assign lv5_ss4 = (lv4_ss4>lv3_ss5)?lv3_ss5:(lv4_ss4==lv3_ss5&&lv4_sid4>lv3_sid5)?lv3_ss5:lv4_ss4;
assign lv5_ss5 = (lv4_ss4>lv3_ss5)?lv4_ss4:(lv4_ss4==lv3_ss5&&lv4_sid4>lv3_sid5)?lv4_ss4:lv3_ss5;
assign lv5_sid2 = (lv4_ss2>lv3_ss3)?lv3_sid3:(lv4_ss2==lv3_ss3&&lv4_sid2>lv3_sid3)?lv3_sid3:lv4_sid2;
assign lv5_sid3 = (lv4_ss2>lv3_ss3)?lv4_sid2:(lv4_ss2==lv3_ss3&&lv4_sid2>lv3_sid3)?lv4_sid2:lv3_sid3;
assign lv5_sid4 = (lv4_ss4>lv3_ss5)?lv3_sid5:(lv4_ss4==lv3_ss5&&lv4_sid4>lv3_sid5)?lv3_sid5:lv4_sid4;
assign lv5_sid5 = (lv4_ss4>lv3_ss5)?lv4_sid4:(lv4_ss4==lv3_ss5&&lv4_sid4>lv3_sid5)?lv4_sid4:lv3_sid5;

assign lv6_ss1 = (lv4_ss1>lv5_ss2)?lv5_ss2:(lv4_ss1==lv5_ss2&&lv4_sid1>lv5_sid2)?lv5_ss2:lv4_ss1;
assign lv6_ss2 = (lv4_ss1>lv5_ss2)?lv4_ss1:(lv4_ss1==lv5_ss2&&lv4_sid1>lv5_sid2)?lv4_ss1:lv5_ss2;
assign lv6_ss3 = (lv5_ss3>lv5_ss4)?lv5_ss4:(lv5_ss3==lv5_ss4&&lv5_sid3>lv5_sid4)?lv5_ss4:lv5_ss3;
assign lv6_ss4 = (lv5_ss3>lv5_ss4)?lv5_ss3:(lv5_ss3==lv5_ss4&&lv5_sid3>lv5_sid4)?lv5_ss3:lv5_ss4;
assign lv6_ss5 = (lv5_ss5>lv4_ss6)?lv4_ss6:(lv5_ss5==lv4_ss6&&lv5_sid5>lv4_sid6)?lv4_ss6:lv5_ss5;
assign lv6_ss6 = (lv5_ss5>lv4_ss6)?lv5_ss5:(lv5_ss5==lv4_ss6&&lv5_sid5>lv4_sid6)?lv5_ss5:lv4_ss6;
assign lv6_sid1 = (lv4_ss1>lv5_ss2)?lv5_sid2:(lv4_ss1==lv5_ss2&&lv4_sid1>lv5_sid2)?lv5_sid2:lv4_sid1;
assign lv6_sid2 = (lv4_ss1>lv5_ss2)?lv4_sid1:(lv4_ss1==lv5_ss2&&lv4_sid1>lv5_sid2)?lv4_sid1:lv5_sid2;
assign lv6_sid3 = (lv5_ss3>lv5_ss4)?lv5_sid4:(lv5_ss3==lv5_ss4&&lv5_sid3>lv5_sid4)?lv5_sid4:lv5_sid3;
assign lv6_sid4 = (lv5_ss3>lv5_ss4)?lv5_sid3:(lv5_ss3==lv5_ss4&&lv5_sid3>lv5_sid4)?lv5_sid3:lv5_sid4;
assign lv6_sid5 = (lv5_ss5>lv4_ss6)?lv4_sid6:(lv5_ss5==lv4_ss6&&lv5_sid5>lv4_sid6)?lv4_sid6:lv5_sid5;
assign lv6_sid6 = (lv5_ss5>lv4_ss6)?lv5_sid5:(lv5_ss5==lv4_ss6&&lv5_sid5>lv4_sid6)?lv5_sid5:lv4_sid6;

assign s2_id0 = lv3_sid0;
assign s2_id1 = lv6_sid1;
assign s2_id2 = lv6_sid2;
assign s2_id3 = lv6_sid3;
assign s2_id4 = lv6_sid4;
assign s2_id5 = lv6_sid5;
assign s2_id6 = lv6_sid6;
//#####################################
//Sorting 3
//#####################################
assign dlv1_s0 = (uss0<uss6)?uss6:uss0;
assign dlv1_s6 = (uss0<uss6)?uss0:uss6;
assign dlv1_s2 =(uss2<uss3)?uss3:uss2;
assign dlv1_s3 =(uss2<uss3)?uss2:uss3;
assign dlv1_s4 = (uss4<uss5)?uss5:uss4;
assign dlv1_s5 = (uss4<uss5)?uss4:uss5;
assign dlv1_id0 = (uss0<uss6)?6:0;
assign dlv1_id6 = (uss0<uss6)?0:6;
assign dlv1_id2 =(uss2<uss3)?3:2;
assign dlv1_id3 =(uss2<uss3)?2:3;
assign dlv1_id4 = (uss4<uss5)?5:4;
assign dlv1_id5 = (uss4<uss5)?4:5;

assign dlv2_s0 = (dlv1_s0<dlv1_s2)?dlv1_s2:(dlv1_s0==dlv1_s2&&dlv1_id0>dlv1_id2)?dlv1_s2:dlv1_s0;
assign dlv2_s2 = (dlv1_s0<dlv1_s2)?dlv1_s0:(dlv1_s0==dlv1_s2&&dlv1_id0>dlv1_id2)?dlv1_s0:dlv1_s2;
assign dlv2_s1 = (uss1<dlv1_s4)?dlv1_s4:uss1;
assign dlv2_s4 = (uss1<dlv1_s4)?uss1:dlv1_s4;
assign dlv2_s3 = (dlv1_s3<dlv1_s6)?dlv1_s6:(dlv1_s3==dlv1_s6&&dlv1_id3>dlv1_id6)?dlv1_s6:dlv1_s3;
assign dlv2_s6 = (dlv1_s3<dlv1_s6)?dlv1_s3:(dlv1_s3==dlv1_s6&&dlv1_id3>dlv1_id6)?dlv1_s3:dlv1_s6;
assign dlv2_id0 = (dlv1_s0<dlv1_s2)?dlv1_id2:(dlv1_s0==dlv1_s2&&dlv1_id0>dlv1_id2)?dlv1_id2:dlv1_id0;
assign dlv2_id2 = (dlv1_s0<dlv1_s2)?dlv1_id0:(dlv1_s0==dlv1_s2&&dlv1_id0>dlv1_id2)?dlv1_id0:dlv1_id2;
assign dlv2_id1 = (uss1<dlv1_s4)?dlv1_id4:1;
assign dlv2_id4 = (uss1<dlv1_s4)?1:dlv1_id4;
assign dlv2_id3 = (dlv1_s3<dlv1_s6)?dlv1_id6:(dlv1_s3==dlv1_s6&&dlv1_id3>dlv1_id6)?dlv1_id6:dlv1_id3;
assign dlv2_id6 = (dlv1_s3<dlv1_s6)?dlv1_id3:(dlv1_s3==dlv1_s6&&dlv1_id3>dlv1_id6)?dlv1_id3:dlv1_id6;

assign dlv3_s0 = (dlv2_s0<dlv2_s1)?dlv2_s1:(dlv2_s0==dlv2_s1&&dlv2_id0>dlv2_id1)?dlv2_s1:dlv2_s0;
assign dlv3_s1 = (dlv2_s0<dlv2_s1)?dlv2_s0:(dlv2_s0==dlv2_s1&&dlv2_id0>dlv2_id1)?dlv2_s0:dlv2_s1;
assign dlv3_s2 = (dlv2_s2<dlv1_s5)?dlv1_s5:(dlv2_s2==dlv1_s5&&dlv2_id2>dlv1_id5)?dlv1_s5:dlv2_s2;
assign dlv3_s5 = (dlv2_s2<dlv1_s5)?dlv2_s2:(dlv2_s2==dlv1_s5&&dlv2_id2>dlv1_id5)?dlv2_s2:dlv1_s5;
assign dlv3_s3 = (dlv2_s3<dlv2_s4)?dlv2_s4:(dlv2_s3==dlv2_s4&&dlv2_id3>dlv2_id4)?dlv2_s4:dlv2_s3;
assign dlv3_s4 = (dlv2_s3<dlv2_s4)?dlv2_s3:(dlv2_s3==dlv2_s4&&dlv2_id3>dlv2_id4)?dlv2_s3:dlv2_s4;
assign dlv3_id0 = (dlv2_s0<dlv2_s1)?dlv2_id1:(dlv2_s0==dlv2_s1&&dlv2_id0>dlv2_id1)?dlv2_id1:dlv2_id0;
assign dlv3_id1 = (dlv2_s0<dlv2_s1)?dlv2_id0:(dlv2_s0==dlv2_s1&&dlv2_id0>dlv2_id1)?dlv2_id0:dlv2_id1;
assign dlv3_id2 = (dlv2_s2<dlv1_s5)?dlv1_id5:(dlv2_s2==dlv1_s5&&dlv2_id2>dlv1_id5)?dlv1_id5:dlv2_id2;
assign dlv3_id5 = (dlv2_s2<dlv1_s5)?dlv2_id2:(dlv2_s2==dlv1_s5&&dlv2_id2>dlv1_id5)?dlv2_id2:dlv1_id5;
assign dlv3_id3 = (dlv2_s3<dlv2_s4)?dlv2_id4:(dlv2_s3==dlv2_s4&&dlv2_id3>dlv2_id4)?dlv2_id4:dlv2_id3;
assign dlv3_id4 = (dlv2_s3<dlv2_s4)?dlv2_id3:(dlv2_s3==dlv2_s4&&dlv2_id3>dlv2_id4)?dlv2_id3:dlv2_id4;

assign dlv4_s1 = (dlv3_s1<dlv3_s2)?dlv3_s2:(dlv3_s1==dlv3_s2&&dlv3_id1>dlv3_id2)?dlv3_s2:dlv3_s1;
assign dlv4_s2 = (dlv3_s1<dlv3_s2)?dlv3_s1:(dlv3_s1==dlv3_s2&&dlv3_id1>dlv3_id2)?dlv3_s1:dlv3_s2;
assign dlv4_s4 = (dlv3_s4<dlv2_s6)?dlv2_s6:(dlv3_s4==dlv2_s6&&dlv3_id4>dlv2_id6)?dlv2_s6:dlv3_s4;
assign dlv4_s6 = (dlv3_s4<dlv2_s6)?dlv3_s4:(dlv3_s4==dlv2_s6&&dlv3_id4>dlv2_id6)?dlv3_s4:dlv2_s6;
assign dlv4_id1 = (dlv3_s1<dlv3_s2)?dlv3_id2:(dlv3_s1==dlv3_s2&&dlv3_id1>dlv3_id2)?dlv3_id2:dlv3_id1;
assign dlv4_id2 = (dlv3_s1<dlv3_s2)?dlv3_id1:(dlv3_s1==dlv3_s2&&dlv3_id1>dlv3_id2)?dlv3_id1:dlv3_id2;
assign dlv4_id4 = (dlv3_s4<dlv2_s6)?dlv2_id6:(dlv3_s4==dlv2_s6&&dlv3_id4>dlv2_id6)?dlv2_id6:dlv3_id4;
assign dlv4_id6 =(dlv3_s4<dlv2_s6)?dlv3_id4:(dlv3_s4==dlv2_s6&&dlv3_id4>dlv2_id6)?dlv3_id4:dlv2_id6;

assign dlv5_s2 = (dlv4_s2<dlv3_s3)?dlv3_s3:(dlv4_s2==dlv3_s3&&dlv4_id2>dlv3_id3)?dlv3_s3:dlv4_s2;
assign dlv5_s3 = (dlv4_s2<dlv3_s3)?dlv4_s2:(dlv4_s2==dlv3_s3&&dlv4_id2>dlv3_id3)?dlv4_s2:dlv3_s3;
assign dlv5_s4 = (dlv4_s4<dlv3_s5)?dlv3_s5:(dlv4_s4==dlv3_s5&&dlv4_id4>dlv3_id5)?dlv3_s5:dlv4_s4;
assign dlv5_s5 = (dlv4_s4<dlv3_s5)?dlv4_s4:(dlv4_s4==dlv3_s5&&dlv4_id4>dlv3_id5)?dlv4_s4:dlv3_s5;
assign dlv5_id2 = (dlv4_s2<dlv3_s3)?dlv3_id3:(dlv4_s2==dlv3_s3&&dlv4_id2>dlv3_id3)?dlv3_id3:dlv4_id2;
assign dlv5_id3 = (dlv4_s2<dlv3_s3)?dlv4_id2:(dlv4_s2==dlv3_s3&&dlv4_id2>dlv3_id3)?dlv4_id2:dlv3_id3;
assign dlv5_id4 = (dlv4_s4<dlv3_s5)?dlv3_id5:(dlv4_s4==dlv3_s5&&dlv4_id4>dlv3_id5)?dlv3_id5:dlv4_id4;
assign dlv5_id5 = (dlv4_s4<dlv3_s5)?dlv4_id4:(dlv4_s4==dlv3_s5&&dlv4_id4>dlv3_id5)?dlv4_id4:dlv3_id5;

assign dlv6_s1 = (dlv4_s1<dlv5_s2)?dlv5_s2:(dlv4_s1==dlv5_s2&&dlv4_id1>dlv5_id2)?dlv5_s2:dlv4_s1;
assign dlv6_s2 = (dlv4_s1<dlv5_s2)?dlv4_s1:(dlv4_s1==dlv5_s2&&dlv4_id1>dlv5_id2)?dlv4_s1:dlv5_s2;
assign dlv6_s3 = (dlv5_s3<dlv5_s4)?dlv5_s4:(dlv5_s3==dlv5_s4&&dlv5_id3>dlv5_id4)?dlv5_s4:dlv5_s3;
assign dlv6_s4 = (dlv5_s3<dlv5_s4)?dlv5_s3:(dlv5_s3==dlv5_s4&&dlv5_id3>dlv5_id4)?dlv5_s3:dlv5_s4;
assign dlv6_s5 = (dlv5_s5<dlv4_s6)?dlv4_s6:(dlv5_s5==dlv4_s6&&dlv5_id5>dlv4_id6)?dlv4_s6:dlv5_s5;
assign dlv6_s6 = (dlv5_s5<dlv4_s6)?dlv5_s5:(dlv5_s5==dlv4_s6&&dlv5_id5>dlv4_id6)?dlv5_s5:dlv4_s6;
assign dlv6_id1 = (dlv4_s1<dlv5_s2)?dlv5_id2:(dlv4_s1==dlv5_s2&&dlv4_id1>dlv5_id2)?dlv5_id2:dlv4_id1;
assign dlv6_id2 = (dlv4_s1<dlv5_s2)?dlv4_id1:(dlv4_s1==dlv5_s2&&dlv4_id1>dlv5_id2)?dlv4_id1:dlv5_id2;
assign dlv6_id3 = (dlv5_s3<dlv5_s4)?dlv5_id4:(dlv5_s3==dlv5_s4&&dlv5_id3>dlv5_id4)?dlv5_id4:dlv5_id3;
assign dlv6_id4 = (dlv5_s3<dlv5_s4)?dlv5_id3:(dlv5_s3==dlv5_s4&&dlv5_id3>dlv5_id4)?dlv5_id3:dlv5_id4;
assign dlv6_id5 = (dlv5_s5<dlv4_s6)?dlv4_id6:(dlv5_s5==dlv4_s6&&dlv5_id5>dlv4_id6)?dlv4_id6:dlv5_id5;
assign dlv6_id6 = (dlv5_s5<dlv4_s6)?dlv5_id5:(dlv5_s5==dlv4_s6&&dlv5_id5>dlv4_id6)?dlv5_id5:dlv4_id6;

assign s3_id0 = dlv3_id0;
assign s3_id1 = dlv6_id1;
assign s3_id2 = dlv6_id2;
assign s3_id3 = dlv6_id3;
assign s3_id4 = dlv6_id4;
assign s3_id5 = dlv6_id5;
assign s3_id6 = dlv6_id6;
//########################################
//Sorting 4
//########################################
assign dlv1_ss0 = (ss0<ss6)?ss6:ss0;
assign dlv1_ss6 = (ss0<ss6)?ss0:ss6;
assign dlv1_ss2 =(ss2<ss3)?ss3:ss2;
assign dlv1_ss3 =(ss2<ss3)?ss2:ss3;
assign dlv1_ss4 = (ss4<ss5)?ss5:ss4;
assign dlv1_ss5 = (ss4<ss5)?ss4:ss5;
assign dlv1_sid0 = (ss0<ss6)?6:0;
assign dlv1_sid6 = (ss0<ss6)?0:6;
assign dlv1_sid2 =(ss2<ss3)?3:2;
assign dlv1_sid3 =(ss2<ss3)?2:3;
assign dlv1_sid4 = (ss4<ss5)?5:4;
assign dlv1_sid5 = (ss4<ss5)?4:5;

assign dlv2_ss0 = (dlv1_ss0<dlv1_ss2)?dlv1_ss2:(dlv1_ss0==dlv1_ss2&&dlv1_sid0>dlv1_sid2)?dlv1_ss2:dlv1_ss0;
assign dlv2_ss2 = (dlv1_ss0<dlv1_ss2)?dlv1_ss0:(dlv1_ss0==dlv1_ss2&&dlv1_sid0>dlv1_sid2)?dlv1_ss0:dlv1_ss2;
assign dlv2_ss1 = (ss1<dlv1_ss4)?dlv1_ss4:ss1;
assign dlv2_ss4 = (ss1<dlv1_ss4)?ss1:dlv1_ss4;
assign dlv2_ss3 = (dlv1_ss3<dlv1_ss6)?dlv1_ss6:(dlv1_ss3==dlv1_ss6&&dlv1_sid3>dlv1_sid6)?dlv1_ss6:dlv1_ss3;
assign dlv2_ss6 = (dlv1_ss3<dlv1_ss6)?dlv1_ss3:(dlv1_ss3==dlv1_ss6&&dlv1_sid3>dlv1_sid6)?dlv1_ss3:dlv1_ss6;
assign dlv2_sid0 = (dlv1_ss0<dlv1_ss2)?dlv1_sid2:(dlv1_ss0==dlv1_ss2&&dlv1_sid0>dlv1_sid2)?dlv1_sid2:dlv1_sid0;
assign dlv2_sid2 = (dlv1_ss0<dlv1_ss2)?dlv1_sid0:(dlv1_ss0==dlv1_ss2&&dlv1_sid0>dlv1_sid2)?dlv1_sid0:dlv1_sid2;
assign dlv2_sid1 = (ss1<dlv1_ss4)?dlv1_sid4:1;
assign dlv2_sid4 = (ss1<dlv1_ss4)?1:dlv1_sid4;
assign dlv2_sid3 = (dlv1_ss3<dlv1_ss6)?dlv1_sid6:(dlv1_ss3==dlv1_ss6&&dlv1_sid3>dlv1_sid6)?dlv1_sid6:dlv1_sid3;
assign dlv2_sid6 = (dlv1_ss3<dlv1_ss6)?dlv1_sid3:(dlv1_ss3==dlv1_ss6&&dlv1_sid3>dlv1_sid6)?dlv1_sid3:dlv1_sid6;

assign dlv3_ss0 = (dlv2_ss0<dlv2_ss1)?dlv2_ss1:(dlv2_ss0==dlv2_ss1&&dlv2_sid0>dlv2_sid1)?dlv2_ss1:dlv2_ss0;
assign dlv3_ss1 = (dlv2_ss0<dlv2_ss1)?dlv2_ss0:(dlv2_ss0==dlv2_ss1&&dlv2_sid0>dlv2_sid1)?dlv2_ss0:dlv2_ss1;
assign dlv3_ss2 = (dlv2_ss2<dlv1_ss5)?dlv1_ss5:(dlv2_ss2==dlv1_ss5&&dlv2_sid2>dlv1_sid5)?dlv1_ss5:dlv2_ss2;
assign dlv3_ss5 = (dlv2_ss2<dlv1_ss5)?dlv2_ss2:(dlv2_ss2==dlv1_ss5&&dlv2_sid2>dlv1_sid5)?dlv2_ss2:dlv1_ss5;
assign dlv3_ss3 = (dlv2_ss3<dlv2_ss4)?dlv2_ss4:(dlv2_ss3==dlv2_ss4&&dlv2_sid3>dlv2_sid4)?dlv2_ss4:dlv2_ss3;
assign dlv3_ss4 = (dlv2_ss3<dlv2_ss4)?dlv2_ss3:(dlv2_ss3==dlv2_ss4&&dlv2_sid3>dlv2_sid4)?dlv2_ss3:dlv2_ss4;
assign dlv3_sid0 = (dlv2_ss0<dlv2_ss1)?dlv2_sid1:(dlv2_ss0==dlv2_ss1&&dlv2_sid0>dlv2_sid1)?dlv2_sid1:dlv2_sid0;
assign dlv3_sid1 = (dlv2_ss0<dlv2_ss1)?dlv2_sid0:(dlv2_ss0==dlv2_ss1&&dlv2_sid0>dlv2_sid1)?dlv2_sid0:dlv2_sid1;
assign dlv3_sid2 = (dlv2_ss2<dlv1_ss5)?dlv1_sid5:(dlv2_ss2==dlv1_ss5&&dlv2_sid2>dlv1_sid5)?dlv1_sid5:dlv2_sid2;
assign dlv3_sid5 = (dlv2_ss2<dlv1_ss5)?dlv2_sid2:(dlv2_ss2==dlv1_ss5&&dlv2_sid2>dlv1_sid5)?dlv2_sid2:dlv1_sid5;
assign dlv3_sid3 = (dlv2_ss3<dlv2_ss4)?dlv2_sid4:(dlv2_ss3==dlv2_ss4&&dlv2_sid3>dlv2_sid4)?dlv2_sid4:dlv2_sid3;
assign dlv3_sid4 = (dlv2_ss3<dlv2_ss4)?dlv2_sid3:(dlv2_ss3==dlv2_ss4&&dlv2_sid3>dlv2_sid4)?dlv2_sid3:dlv2_sid4;

assign dlv4_ss1 = (dlv3_ss1<dlv3_ss2)?dlv3_ss2:(dlv3_ss1==dlv3_ss2&&dlv3_sid1>dlv3_sid2)?dlv3_ss2:dlv3_ss1;
assign dlv4_ss2 = (dlv3_ss1<dlv3_ss2)?dlv3_ss1:(dlv3_ss1==dlv3_ss2&&dlv3_sid1>dlv3_sid2)?dlv3_ss1:dlv3_ss2;
assign dlv4_ss4 = (dlv3_ss4<dlv2_ss6)?dlv2_ss6:(dlv3_ss4==dlv2_ss6&&dlv3_sid4>dlv2_sid6)?dlv2_ss6:dlv3_ss4;
assign dlv4_ss6 = (dlv3_ss4<dlv2_ss6)?dlv3_ss4:(dlv3_ss4==dlv2_ss6&&dlv3_sid4>dlv2_sid6)?dlv3_ss4:dlv2_ss6;
assign dlv4_sid1 = (dlv3_ss1<dlv3_ss2)?dlv3_sid2:(dlv3_ss1==dlv3_ss2&&dlv3_sid1>dlv3_sid2)?dlv3_sid2:dlv3_sid1;
assign dlv4_sid2 = (dlv3_ss1<dlv3_ss2)?dlv3_sid1:(dlv3_ss1==dlv3_ss2&&dlv3_sid1>dlv3_sid2)?dlv3_sid1:dlv3_sid2;
assign dlv4_sid4 = (dlv3_ss4<dlv2_ss6)?dlv2_sid6:(dlv3_ss4==dlv2_ss6&&dlv3_sid4>dlv2_sid6)?dlv2_sid6:dlv3_sid4;
assign dlv4_sid6 =(dlv3_ss4<dlv2_ss6)?dlv3_sid4:(dlv3_ss4==dlv2_ss6&&dlv3_sid4>dlv2_sid6)?dlv3_sid4:dlv2_sid6;

assign dlv5_ss2 = (dlv4_ss2<dlv3_ss3)?dlv3_ss3:(dlv4_ss2==dlv3_ss3&&dlv4_sid2>dlv3_sid3)?dlv3_ss3:dlv4_ss2;
assign dlv5_ss3 = (dlv4_ss2<dlv3_ss3)?dlv4_ss2:(dlv4_ss2==dlv3_ss3&&dlv4_sid2>dlv3_sid3)?dlv4_ss2:dlv3_ss3;
assign dlv5_ss4 = (dlv4_ss4<dlv3_ss5)?dlv3_ss5:(dlv4_ss4==dlv3_ss5&&dlv4_sid4>dlv3_sid5)?dlv3_ss5:dlv4_ss4;
assign dlv5_ss5 = (dlv4_ss4<dlv3_ss5)?dlv4_ss4:(dlv4_ss4==dlv3_ss5&&dlv4_sid4>dlv3_sid5)?dlv4_ss4:dlv3_ss5;
assign dlv5_sid2 = (dlv4_ss2<dlv3_ss3)?dlv3_sid3:(dlv4_ss2==dlv3_ss3&&dlv4_sid2>dlv3_sid3)?dlv3_sid3:dlv4_sid2;
assign dlv5_sid3 = (dlv4_ss2<dlv3_ss3)?dlv4_sid2:(dlv4_ss2==dlv3_ss3&&dlv4_sid2>dlv3_sid3)?dlv4_sid2:dlv3_sid3;
assign dlv5_sid4 = (dlv4_ss4<dlv3_ss5)?dlv3_sid5:(dlv4_ss4==dlv3_ss5&&dlv4_sid4>dlv3_sid5)?dlv3_sid5:dlv4_sid4;
assign dlv5_sid5 = (dlv4_ss4<dlv3_ss5)?dlv4_sid4:(dlv4_ss4==dlv3_ss5&&dlv4_sid4>dlv3_sid5)?dlv4_sid4:dlv3_sid5;

assign dlv6_ss1 = (dlv4_ss1<dlv5_ss2)?dlv5_ss2:(dlv4_ss1==dlv5_ss2&&dlv4_sid1>dlv5_sid2)?dlv5_ss2:dlv4_ss1;
assign dlv6_ss2 = (dlv4_ss1<dlv5_ss2)?dlv4_ss1:(dlv4_ss1==dlv5_ss2&&dlv4_sid1>dlv5_sid2)?dlv4_ss1:dlv5_ss2;
assign dlv6_ss3 = (dlv5_ss3<dlv5_ss4)?dlv5_ss4:(dlv5_ss3==dlv5_ss4&&dlv5_sid3>dlv5_sid4)?dlv5_ss4:dlv5_ss3;
assign dlv6_ss4 = (dlv5_ss3<dlv5_ss4)?dlv5_ss3:(dlv5_ss3==dlv5_ss4&&dlv5_sid3>dlv5_sid4)?dlv5_ss3:dlv5_ss4;
assign dlv6_ss5 = (dlv5_ss5<dlv4_ss6)?dlv4_ss6:(dlv5_ss5==dlv4_ss6&&dlv5_sid5>dlv4_sid6)?dlv4_ss6:dlv5_ss5;
assign dlv6_ss6 = (dlv5_ss5<dlv4_ss6)?dlv5_ss5:(dlv5_ss5==dlv4_ss6&&dlv5_sid5>dlv4_sid6)?dlv5_ss5:dlv4_ss6;
assign dlv6_sid1 = (dlv4_ss1<dlv5_ss2)?dlv5_sid2:(dlv4_ss1==dlv5_ss2&&dlv4_sid1>dlv5_sid2)?dlv5_sid2:dlv4_sid1;
assign dlv6_sid2 = (dlv4_ss1<dlv5_ss2)?dlv4_sid1:(dlv4_ss1==dlv5_ss2&&dlv4_sid1>dlv5_sid2)?dlv4_sid1:dlv5_sid2;
assign dlv6_sid3 = (dlv5_ss3<dlv5_ss4)?dlv5_sid4:(dlv5_ss3==dlv5_ss4&&dlv5_sid3>dlv5_sid4)?dlv5_sid4:dlv5_sid3;
assign dlv6_sid4 = (dlv5_ss3<dlv5_ss4)?dlv5_sid3:(dlv5_ss3==dlv5_ss4&&dlv5_sid3>dlv5_sid4)?dlv5_sid3:dlv5_sid4;
assign dlv6_sid5 = (dlv5_ss5<dlv4_ss6)?dlv4_sid6:(dlv5_ss5==dlv4_ss6&&dlv5_sid5>dlv4_sid6)?dlv4_sid6:dlv5_sid5;
assign dlv6_sid6 = (dlv5_ss5<dlv4_ss6)?dlv5_sid5:(dlv5_ss5==dlv4_ss6&&dlv5_sid5>dlv4_sid6)?dlv5_sid5:dlv4_sid6;

assign s4_id0 = dlv3_sid0;
assign s4_id1 = dlv6_sid1;
assign s4_id2 = dlv6_sid2;
assign s4_id3 = dlv6_sid3;
assign s4_id4 = dlv6_sid4;
assign s4_id5 = dlv6_sid5;
assign s4_id6 = dlv6_sid6;
endmodule














