//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Si2 LAB @NCTU ED415
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 spring
//   Midterm Proejct            : GLCM 
//   Author                     : CHarles Han
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : GLCM.v
//   Module Name : GLCM
//   Release version : V1.0 (Release Date: 2023-04)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module GLCM(
				clk,	
			  rst_n,	
	
			in_addr_M,
			in_addr_G,
			in_dir,
			in_dis,
			in_valid,
			out_valid,
	

         awid_m_inf,
       awaddr_m_inf,
       awsize_m_inf,
      awburst_m_inf,
        awlen_m_inf,
      awvalid_m_inf,
      awready_m_inf,
                    
        wdata_m_inf,
        wlast_m_inf,
       wvalid_m_inf,
       wready_m_inf,
                    
          bid_m_inf,
        bresp_m_inf,
       bvalid_m_inf,
       bready_m_inf,
                    
         arid_m_inf,
       araddr_m_inf,
        arlen_m_inf,
       arsize_m_inf,
      arburst_m_inf,
      arvalid_m_inf,
                    
      arready_m_inf, 
          rid_m_inf,
        rdata_m_inf,
        rresp_m_inf,
        rlast_m_inf,
       rvalid_m_inf,
       rready_m_inf 
);
parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 32;
input			  clk,rst_n;



// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
       your AXI-4 interface could be designed as convertor in submodule(which used reg for output signal),
	   therefore I declared output of AXI as wire in Poly_Ring
*/
   
// -----------------------------
// IO port
input [ADDR_WIDTH-1:0]      in_addr_M;
input [ADDR_WIDTH-1:0]      in_addr_G;
input [1:0]  	  		in_dir;
input [3:0]	    		in_dis;
input 			    	in_valid;
output reg 	              out_valid;
// -----------------------------


// axi write address channel 
output  wire [ID_WIDTH-1:0]        awid_m_inf;//******
output  wire [ADDR_WIDTH-1:0]    awaddr_m_inf;//******
output  wire [2:0]            awsize_m_inf;//********
output  wire [1:0]           awburst_m_inf;//*******
output  wire [3:0]             awlen_m_inf;//*******
output  wire                 awvalid_m_inf;
input   wire                 awready_m_inf;
// axi write data channel 
output  wire [ DATA_WIDTH-1:0]     wdata_m_inf;
output  wire                   wlast_m_inf;
output  wire                  wvalid_m_inf;
input   wire                  wready_m_inf;
// axi write response channel
input   wire [ID_WIDTH-1:0]         bid_m_inf;
input   wire [1:0]             bresp_m_inf;
input   wire              	   bvalid_m_inf;
output  wire                  bready_m_inf;//*****
// -----------------------------
// axi read address channel 
output  wire [ID_WIDTH-1:0]       arid_m_inf;//******
output  wire [ADDR_WIDTH-1:0]   araddr_m_inf;//******
output  wire [3:0]            arlen_m_inf;//******
output  wire [2:0]           arsize_m_inf;//******
output  wire [1:0]          arburst_m_inf;//******
output  wire                arvalid_m_inf;//******
input   wire               arready_m_inf;
// -----------------------------
// axi read data channel 
input   wire [ID_WIDTH-1:0]         rid_m_inf;
input   wire [DATA_WIDTH-1:0]     rdata_m_inf;
input   wire [1:0]             rresp_m_inf;
input   wire                   rlast_m_inf;
input   wire                  rvalid_m_inf;
output  wire                  rready_m_inf;//****** 
// -----------------------------
// Parameters
// -----------------------------
parameter IDLE = 4'b0000;
parameter IN_DATA = 4'b0001;
parameter SRAMRES = 4'b0010;
parameter D2S = 4'b0011;
parameter MAT_OUT = 4'b0100;//4 at once into this state 256/4= 64 times
parameter CAL_ADDS = 4'b0101;//cal address and nowx nowy reffx reffy 
parameter CAL_SDATA = 4'b0110;//take out SRAM　and cal  (stay 6 cycles read 4 sram and +1) used sd_cnt to count
parameter W_SDATA = 4'b0111;//write 4 address data(4 cycles) and go back to MAT out(if cal_cnt<64) used wsr_cnt to count
parameter S2D = 4'b1000;//wrute the whole 1024 SRAM back to DRAM
parameter OUT = 4'b1001;//Pull out_valid one cycle for the pattern to check

//integer i,j;
integer i0,j0;
// -----------------------------
// reg & interger
// -----------------------------
reg [3:0] current_state,next_state;
reg [3:0] hand_cnt;
reg [10:0] res_cnt;
reg [9:0] gl_cnt;
reg [9:0] buf_cnt;
reg [8:0] cal_cnt;
reg [4:0] valid_cnt;
reg [4:0] read_cnt;
reg [4:0] resram_cnt;
reg [4:0] sd_cnt,wsr_cnt;
reg [ADDR_WIDTH-1:0] inm_addr;
reg [ADDR_WIDTH-1:0] glcm_addr;
reg [1:0] dir;// 01 x //10 y //11 x&y
reg [3:0] dis;
reg valid4d;
reg valid4d_w;
reg ready4d;
reg w_valid;
reg w_last;
reg [4:0] w_cnt;
reg [4:0] whand_cnt;
reg [31:0] data;
reg [31:0] buffer;
reg [7:0] data_in;
wire [7:0] data_out;
reg [7:0] data_o1,data_o2,data_o3,data_o4;
reg [7:0] b1,b2,b3,b4;
wire vandr;
wire [4:0] plus;
reg wen;
reg [2:0] adder1,adder2,adder3,adder4;
reg [9:0] address;
reg [9:0] address1,address2,address3,address4;
reg [4:0] in_m[0:15][0:15];
reg [4:0] nowx,nowy1,nowy2,nowy3,nowy4,reffx1,reffx2,reffx3,reffx4,reffy1,reffy2,reffy3,reffy4;
reg [7:0] d1,d2,d3,d4;// x y data
reg [7:0] data1,data2,data3,data4;//reff data
wire reflag1,reflag2,reflag3,reflag4;//==1 if refference is in the range of matrix
//id assign
assign awid_m_inf = 'b0;
assign bid_m_inf = 'b0;
assign arid_m_inf = 'b0;
assign rid_m_inf = 'b0;
//read dram
assign arburst_m_inf = 2'b01;
assign arsize_m_inf = 3'b010;
assign arlen_m_inf = 4'b1111;
assign rready_m_inf = 1;
//write dram
assign awburst_m_inf = 2'b01;
assign awsize_m_inf = 3'b010;//32 bits data are send to DRAM
assign awlen_m_inf = 4'b1111;//one hand shake send 16*(32 bits data)
assign bready_m_inf = 1;
/////////
assign araddr_m_inf = inm_addr;
assign arvalid_m_inf = valid4d;
assign awaddr_m_inf = glcm_addr;
assign awvalid_m_inf = valid4d_w;
assign wdata_m_inf = buffer;
assign wlast_m_inf = w_last;
assign wvalid_m_inf = w_valid;
/////////////////////////////////////////////////////
/// cnt
////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) valid_cnt<=0;
  else if(valid4d) valid_cnt<=valid_cnt+1;
  else if(rlast_m_inf) valid_cnt<=0;
end

always @(posedge clk or negedge rst_n) begin
  if(!rst_n) hand_cnt<=0;
  else if(current_state==D2S&&valid_cnt==1) hand_cnt<=hand_cnt+1;
  else if(current_state==OUT) hand_cnt<=0;
end

always @(posedge clk or negedge rst_n) begin
  if(!rst_n) read_cnt<=0;
  else if(rvalid_m_inf) read_cnt<=read_cnt+1;
  else read_cnt<=0;
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) cal_cnt<=0;
  else if(current_state==MAT_OUT) cal_cnt<=cal_cnt+1;
  else if(current_state==S2D) cal_cnt<=0;
end
/*always @(posedge clk or negedge rst_n) begin
  if(!rst_n) resram_cnt<=0;
  else if(next_state==CAL_SDATA) resram_cnt<=resram_cnt+1;
  else if(current_state==CAL_SDATA)resram_cnt<=0;
end*/
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) res_cnt<=0;
  else if(next_state==SRAMRES) res_cnt<=res_cnt+1;
  else res_cnt<=0;
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) sd_cnt<=0;
  else if(next_state==CAL_SDATA) sd_cnt<=sd_cnt+1;
  else if(next_state==W_SDATA) sd_cnt<=0;
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) wsr_cnt<=0;
  else if(next_state==W_SDATA) wsr_cnt<=wsr_cnt+1;
  else if(next_state!=W_SDATA) wsr_cnt<=0;
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) gl_cnt<=0;
  else if(next_state==S2D) begin
    if(buf_cnt==0||buf_cnt==1||buf_cnt==2||buf_cnt==8) gl_cnt<=gl_cnt+1;
  end
  else if(current_state==IDLE) gl_cnt<=0;
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) buf_cnt<=0;
  else if(current_state==S2D&&buf_cnt<8) buf_cnt<=buf_cnt+1;
  else if(current_state==S2D&&buf_cnt==8) buf_cnt<=0;
  //else if(current_state==S2D&&wvalid_m_inf&&wready_m_inf) buf_cnt<=buf_cnt+1;
  else buf_cnt<=0;
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) w_cnt<=0;
  else if(buf_cnt==8) w_cnt<=w_cnt+1;
  else if(w_cnt==16) w_cnt<=0;
  else if(current_state==IDLE) w_cnt<=0;
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) whand_cnt<=0;
  else if(wlast_m_inf&&buf_cnt==8) whand_cnt<=whand_cnt+1;
  else if(current_state==IDLE) whand_cnt<=0;
end
///////////////////////////////////////////////////

always @(posedge clk or negedge rst_n) begin
  if(!rst_n)begin
    current_state<=IDLE;
  end
  else current_state<=next_state;
end

always @(*) begin
  case(current_state)
  IDLE:begin
    if(in_valid) next_state = IN_DATA;
    else next_state = IDLE;
  end
  IN_DATA:begin
    next_state = SRAMRES;
  end
  SRAMRES:begin
    if(res_cnt==1023) next_state = D2S;
    else next_state = SRAMRES;
  end
  D2S:begin
    if(hand_cnt==4&&rlast_m_inf) next_state = MAT_OUT; 
    else next_state = D2S;
  end
  MAT_OUT:begin
    next_state = CAL_ADDS;
  end
  CAL_ADDS:begin
    next_state = CAL_SDATA;
  end
  CAL_SDATA:begin
    if(sd_cnt==6) next_state = W_SDATA;
    else next_state = CAL_SDATA;
  end
  W_SDATA:begin
    if(cal_cnt==64&&wsr_cnt==4) next_state = S2D;
    else if(wsr_cnt==4) next_state = MAT_OUT;
    else next_state = W_SDATA;
  end
  S2D:begin
    //if(gl_cnt==1023) next_state = OUT;
    if(whand_cnt==16) next_state = OUT;
    else next_state = S2D;
  end
  OUT:begin 
    next_state = IDLE;
  end
  default:next_state = IDLE;
  endcase
end
//receive address
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) inm_addr<=0;
  else if(in_valid) inm_addr<=in_addr_M;
  else if(valid_cnt==1) inm_addr<=inm_addr+64;
  else if(current_state==IDLE) inm_addr<=0;
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) glcm_addr<=0;
  else if(in_valid) glcm_addr<=in_addr_G;
  else if(w_last&&buf_cnt==8) glcm_addr<=glcm_addr+64;
  else if(current_state==IDLE) glcm_addr<=0;
end
//in_data
always @(posedge clk or negedge rst_n) begin
  if(!rst_n)begin
    dir<=0;
    dis<=0;
  end
  else if(in_valid)begin
    dir<=in_dir;
    dis<=in_dis;
  end
  else if(current_state==IDLE)begin
    dir<=0;
    dis<=0;
  end
end

///////////////////////////////////////////////
// Valid signal for wirite address chanel
///////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) valid4d_w<=0;
  else if(current_state==S2D)begin
    if(buf_cnt==5&&w_cnt==0) valid4d_w<=1;
    if(buf_cnt==7&&w_cnt==0) valid4d_w<=0;
  end
  else if(current_state==IDLE) valid4d_w<=0;
end

always @(posedge clk or negedge rst_n) begin
  if(!rst_n) w_last<=0;
  else if(w_cnt==15) w_last<=1;
  else w_last<=0;
end

always @(posedge clk or negedge rst_n) begin
  if(!rst_n) w_valid<=0;
  else if(current_state==S2D)begin
  if(w_cnt==0||w_cnt==1)begin
    if(w_cnt==0&&buf_cnt==5) w_valid<=1;
    if(w_cnt==1&&wready_m_inf) w_valid<=0;
    if(w_cnt==1&&buf_cnt==5) w_valid<=1;
    if(w_cnt==1&&buf_cnt==6) w_valid<=0;
  end
  else if((w_cnt!=0)&&(w_cnt!=1))begin
    if(buf_cnt==5) w_valid<=1;
    if(buf_cnt==6) w_valid<=0;
  end
  end
  else if(current_state==IDLE) w_valid<=0;
end
///////////////////////////////////////////
//    valid signal for read address chanel
///////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) valid4d<=0;
  /*
  else if(current_state==D2S&&(valid_cnt<2)) valid4d<=1;
  else valid4d<=0;
  if(arready_m_inf&&valid4d) valid4d<=0;
  */
  else if(current_state==D2S)begin
    if(hand_cnt==0)valid4d<=1;
    if(hand_cnt==0&&arready_m_inf)valid4d<=0;
    if(hand_cnt==1&&rlast_m_inf) valid4d<=1;
    if(hand_cnt==1&&arready_m_inf) valid4d<=0;
    if(hand_cnt==2&&rlast_m_inf) valid4d<=1;
    if(hand_cnt==2&&arready_m_inf) valid4d<=0;
    if(hand_cnt==3&&rlast_m_inf) valid4d<=1;
    if(hand_cnt==3&&arready_m_inf)valid4d<=0;
  end
  else if(current_state==IDLE) valid4d<=0;
end
//assign vandr = (arvalid_m_inf&&arready_m_inf)?1:0;
/*always @(posedge clk or negedge rst_n) begin
  if(!rst_n) ready4d<=0;
  else if(current_state==D2S) ready4d<=1;
  else ready4d<=0;
end*/
///
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) data<=0;
  else if(next_state == D2S) data<=rdata_m_inf;
  else if(current_state==IDLE) data<=0;
end
////////////////////////////////////////////////
//    CAL　THE x and y
///////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(!rst_n)begin
    nowx<=0;
    nowy1<=0;
    nowy2<=1;
    nowy3<=2;
    nowy4<=3;
  end
  else if(current_state==CAL_ADDS)begin
  nowx<=cal_cnt/4;
  if(cal_cnt%4==0)begin
    nowy1<=0;
    nowy2<=1;
    nowy3<=2;
    nowy4<=3;
  end
  else begin
    nowy1<=nowy1+4;
    nowy2<=nowy2+4;
    nowy3<=nowy3+4;
    nowy4<=nowy4+4;
  end
  end
  else if(current_state==IDLE)begin
    nowx<=0;
    nowy1<=0;
    nowy2<=1;
    nowy3<=2;
    nowy4<=3;
  end
end
////////////////////////////////////////////////
//    CAL reff point of x y
///////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(!rst_n)begin
    reffx1<=0;
    reffx2<=0;
    reffx3<=0;
    reffx4<=0;
    reffy1<=0;
    reffy2<=0;
    reffy3<=0;
    reffy4<=0;
  end
  else if(next_state==MAT_OUT)begin
    if(dir==2'b01)begin
        reffy1<=nowy1;
        reffy2<=nowy2;
        reffy3<=nowy3;
        reffy4<=nowy4;
        reffx1<=nowx+dis;
        reffx2<=nowx+dis;
        reffx3<=nowx+dis;
        reffx4<=nowx+dis;
    end
    if(dir==2'b10)begin
      reffx1<=nowx;
      reffx2<=nowx;
      reffx3<=nowx;
      reffx4<=nowx;
      reffy1<=nowy1+dis;
      reffy2<=nowy2+dis;
      reffy3<=nowy3+dis;
      reffy4<=nowy4+dis;
    end
    if(dir==2'b11)begin
      reffx1<=nowx+dis;
      reffx2<=nowx+dis;
      reffx3<=nowx+dis;
      reffx4<=nowx+dis;
      reffy1<=nowy1+dis;
      reffy2<=nowy2+dis;
      reffy3<=nowy3+dis;
      reffy4<=nowy4+dis; 
    end
  end
  else if(current_state==IDLE)begin
    reffx1<=0;
    reffx2<=0;
    reffx3<=0;
    reffx4<=0;
    reffy1<=0;
    reffy2<=0;
    reffy3<=0;
    reffy4<=0;
  end
end
assign reflag1 = (reffx1<16&&reffy1<16)?1:0;
assign reflag2 = (reffx2<16&&reffy2<16)?1:0;
assign reflag3 = (reffx3<16&&reffy3<16)?1:0;
assign reflag4 = (reffx4<16&&reffy4<16)?1:0;

////////////////////////////////////////////////
//    Take reg matrix out
////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(!rst_n)begin
    d1<=0;
    d2<=0;
    d3<=0;
    d4<=0;
  end
  else if(next_state==MAT_OUT)begin
  d1 <= in_m[nowx][nowy1];
  d2 <= in_m[nowx][nowy2];
  d3 <= in_m[nowx][nowy3];
  d4 <= in_m[nowx][nowy4];
  end
  else if(current_state==IDLE)begin
    d1<=0;
    d2<=0;
    d3<=0;
    d4<=0;
  end
end
always @(*) begin
  if(reflag1) data1 = in_m[reffx1][reffy1];
  else data1 = 0;
end
always @(*) begin
  if(reflag2) data2 = in_m[reffx2][reffy2];
  else data2 = 0;
end
always @(*) begin
  if(reflag3) data3 = in_m[reffx3][reffy3];
  else data3 = 0;
end
always @(*) begin
  if(reflag4) data4 = in_m[reffx4][reffy4];
  else data4 = 0;
end

/*always @(posedge clk or negedge rst_n) begin
  if(!rst_n)begin
    data1<=0;
    data2<=0;
    data3<=0;
    data4<=0;
  end
  else if(next_state==CAL_ADDS)begin
  data1 = in_m[reffx1][reffy1];
  data2 = in_m[reffx2][reffy2];
  data3 = in_m[reffx3][reffy3];
  data4 = in_m[reffx4][reffy4];
  end
  else if(current_state==IDLE)begin
    data1<=0;
    data2<=0;
    data3<=0;
    data4<=0;
  end
end*/

always @(*) begin
  address1 = d1*32+data1;
  address2 = d2*32+data2;
  address3 = d3*32+data3;
  address4 = d4*32+data4;
end

/*always @(posedge clk or negedge rst_n) begin
  if(!rst_n)begin
      address1<=0;
      address2<=0;
      address3<=0;
      address4<=0;
  end
  else if(next_state==CAL_ADDS)begin
  address1 = d1*32+data1;
  address2 = d2*32+data2;
  address3 = d3*32+data3;
  address4 = d4*32+data4;
  end
end*/

////////////////////////////////////////////////
//    CAL　How many same cocerrrrrrrrr
////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(!rst_n)begin
    adder1<=0;
    adder2<=0;
    adder3<=0;
    adder4<=0;
  end
  else if((reflag1==0)&&(reflag2==0)&&(reflag3==0)&&(reflag4==0))begin
        adder1<=0;
        adder2<=0;
        adder3<=0;
        adder4<=0;
      end
  else if(next_state==CAL_ADDS&&(reflag1==1)&&(reflag2==0)&&(reflag3==0)&&(reflag4==0))begin
    adder1<=1;
    adder2<=1;
    adder3<=1;
    adder4<=1;
  end
  else if(next_state==CAL_ADDS)begin
    if((address1==address2)&&(address3==address4)&&(address2==address3)&&(address1==address4)) begin//1=2=3=4
      if(reflag1&&reflag2&&reflag3&&reflag4)begin
      adder1<=4;
      adder2<=4;
      adder3<=4;
      adder4<=4;
      end
      else if((reflag1&&reflag2&&reflag3)||(reflag1&&reflag2&&reflag4)||(reflag1&&reflag4&&reflag3)||(reflag4&&reflag2&&reflag3))begin
      adder1<=3;
      adder2<=3;
      adder3<=3;
      adder4<=3;
      end
      else if((reflag1&&reflag2)||(reflag1&&reflag3)||(reflag1&&reflag4)||(reflag2&&reflag3)||(reflag2&&reflag4)||(reflag3&&reflag4))begin
      adder1<=2;
      adder2<=2;
      adder3<=2;
      adder4<=2;
      end
      else begin
      adder1<=1;
      adder2<=1;
      adder3<=1;
      adder4<=1;
      end
    end
      else if((address1==address2)&&(address2==address3))begin//1=2=3
      if(reflag1&&reflag2&&reflag3)begin
      adder1<=3;
      adder2<=3;
      adder3<=3;
      adder4<=1;
      end
      else if((reflag1&&reflag2)||(reflag2&&reflag3)||(reflag1&&reflag3))begin
      adder1<=2;
      adder2<=2;
      adder3<=2;
      adder4<=1;
      end
      else if(reflag1||reflag2||reflag3)begin
      adder1<=1;
      adder2<=1;
      adder3<=1;
      adder4<=1;
      end
      end
      else if((address1==address2)&&(address2==address4))begin//1=2=4
      if(reflag1&&reflag2&&reflag4)begin
      adder1<=3;
      adder2<=3;
      adder3<=1;
      adder4<=3;
      end
      else if((reflag1&&reflag2)||(reflag1&&reflag4)||(reflag2&&reflag4))begin
      adder1<=2;
      adder2<=2;
      adder3<=2;
      adder4<=1;
      end
      else if(reflag1||reflag2||reflag4)begin
      adder1<=1;
      adder2<=1;
      adder3<=1;
      adder4<=1;
      end
      end
      else if((address1==address3)&&(address3==address4))begin//1=3=4
      if(reflag1&&reflag3&&reflag4)begin
      adder1<=3;
      adder2<=1;
      adder3<=3;
      adder4<=3;
      end
      else if((reflag1&&reflag3)||(reflag1&&reflag4)||(reflag3&&reflag4))begin
      adder1<=2;
      adder2<=2;
      adder3<=2;
      adder4<=1;
      end
      else if(reflag1||reflag3||reflag4)begin
      adder1<=1;
      adder2<=1;
      adder3<=1;
      adder4<=1;
      end
      end
      else if((address2==address3)&&(address3==address4))begin//2=3=4
      if(reflag2&&reflag3&&reflag4)begin
      adder1<=1;
      adder2<=3;
      adder3<=3;
      adder4<=3;
      end
      else if((reflag2&&reflag3)||(reflag2&&reflag4)||(reflag3&&reflag4))begin
      adder1<=2;
      adder2<=2;
      adder3<=2;
      adder4<=1;
      end
      else if(reflag2||reflag3||reflag4)begin
      adder1<=1;
      adder2<=1;
      adder3<=1;
      adder4<=1;
      end
      end
      else if(address1==address2)begin
        if(reflag1&&reflag2&&(address3!=address4))begin
        adder1<=2;
        adder2<=2;
        adder3<=1;
        adder4<=1;
        end
        else if(reflag1&&reflag2&&(address3==address4))begin
            adder1<=2;
            adder2<=2;
            adder3<=2;
            adder4<=2;
        end
        else begin
        adder1<=1;
        adder2<=1;
        adder3<=1;
        adder4<=1;
        end
      end
      else if(address1==address3)begin
        if(reflag1&&reflag3&&(address2!=address4))begin
        adder1<=2;
        adder2<=1;
        adder3<=2;
        adder4<=1;
        end
        else if(reflag1&&reflag3&&(address2==address4))begin
        adder1<=2;
        adder2<=2;
        adder3<=2;
        adder4<=2;
        end
        else begin
        adder1<=1;
        adder2<=1;
        adder3<=1;
        adder4<=1;
        end
      end
      else if(address1==address4)begin
      if(reflag1&&reflag4&&(address2!=address3))begin
        adder1<=2;
        adder2<=1;
        adder3<=1;
        adder4<=2;
      end
      else if(reflag1&&reflag4&&(address2==address3))begin
        adder1<=2;
        adder2<=2;
        adder3<=2;
        adder4<=2;
      end
      else begin
        adder1<=1;
        adder2<=1;
        adder3<=1;
        adder4<=1;
      end
      end
      else if(address2==address3)begin
        if(reflag2&&reflag3&&(address1!=address4))begin
        adder1<=1;
        adder2<=2;
        adder3<=2;
        adder4<=1;
        end
        else if(reflag2&&reflag3&&(address1==address4))begin
        adder1<=2;
        adder2<=2;
        adder3<=2;
        adder4<=2;
        end
        else begin
        adder1<=1;
        adder2<=1;
        adder3<=1;
        adder4<=1;
        end
      end
      else if(address2==address4)begin
        if(reflag2&&reflag4&&(address1!=address3))begin
        adder1<=1;
        adder2<=2;
        adder3<=1;
        adder4<=2;
        end
        else if(reflag2&&reflag4&&(address1==address3))begin
        adder1<=2;
        adder2<=2;
        adder3<=2;
        adder4<=2;
        end
        else begin
        adder1<=1;
        adder2<=1;
        adder3<=1;
        adder4<=1;
        end
      end
      else if(address3==address4)begin
        if(reflag3&&reflag4&&(address1!=address2))begin
        adder1<=1;
        adder2<=1;
        adder3<=2;
        adder4<=2;
        end
        else if(reflag3&&reflag4&&(address1==address2))begin
        adder1<=2;
        adder2<=2;
        adder3<=2;
        adder4<=2;
        end
        else begin
        adder1<=1;
        adder2<=1;
        adder3<=1;
        adder4<=1;
      end
      end
///////////////////////////////////////
///////////////////////////////////////
//         ALL are not the same!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
///////////////////////////////////////
///////////////////////////////////////
      else begin
        adder1<=1;
        adder2<=1;
        adder3<=1;
        adder4<=1;
      end
  end
end
////////////////////////////////////////////////
//    SRAM
////////////////////////////////////////////////
RA1SH M0(.Q(data_out),.CLK(clk),.CEN(1'b0),.WEN(wen),.A(address),.D(data_in),.OEN(1'b0));
////////// address/////////
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) address<=0;
  else if(next_state==SRAMRES||current_state==SRAMRES) address<=res_cnt;
  else if(next_state==CAL_SDATA||next_state==CAL_ADDS||(next_state==W_SDATA&&wsr_cnt==4))begin
    case(sd_cnt)
    0:begin
      address<=address1;
    end
    1:begin
      address<=address2;
    end
    2:begin
      address<=address3;
    end
    3:begin
      address<=address4;
    end
    endcase
  end
  else if(next_state==W_SDATA)begin
    case(wsr_cnt)
    0:begin
      address<=address1;
    end
    1:begin
      address<=address2;
    end
    2:begin
      address<=address3;
    end
    3:begin
      address<=address4;
    end
    endcase
  end
  else if(next_state==S2D) address<=gl_cnt;
  else if(current_state==IDLE) address<=0;
end
///////// wen//////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) wen<=1;
  //||(next_state==W_SDATA&&(reflag1)&&reflag2&&reflag3&&reflag4)
  else if(current_state==SRAMRES||next_state==SRAMRES) wen<=0;
  else if(next_state==W_SDATA)begin
    case(wsr_cnt)
    0:begin
      if(reflag1) wen<=0;
      else wen<=1;
    end
    1:begin
      if(reflag2) wen<=0;
      else wen<=1;
    end
    2:begin
      if(reflag3) wen<=0;
      else wen<=1;
    end
    3:begin
      if(reflag4) wen<=0;
      else wen<=1;
    end
    endcase
  end
  else wen<=1;
end
////////data in/////////////////////
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) data_in<=0;
  else if(next_state==SRAMRES||current_state==SRAMRES) data_in<=0;
  else if(next_state==W_SDATA)begin
    case(wsr_cnt)
    0:data_in<=b1;
    1:data_in<=b2;
    2:data_in<=b3;
    3:data_in<=b4;
    endcase
  end
end
always @(*) begin
  b1 = data_o1+adder1;
  b2 = data_o2+adder2;
  b3 = data_o3+adder3;
  b4 = data_o4+adder4;
end
/////////data out/////////////////////
always @(posedge clk or negedge rst_n) begin
  if(!rst_n)begin 
  data_o1<=0;
  data_o2<=0;
  data_o3<=0;
  data_o4<=0;
  end
  else if(next_state==CAL_SDATA)begin
    case(sd_cnt)
    2:begin
      data_o1<=data_out;
    end
    3:begin
      data_o2<=data_out;
    end
    4:begin
      data_o3<=data_out;
    end
    5:begin
      data_o4<=data_out;
    end
    endcase
  end
  /*else if(next_state==W_SDATA&&wsr_cnt==0)begin
    data_o1<=data_o1+1;
    data_o2<=data_o2+1;
    data_o3<=data_o3+1;
    data_o4<=data_o4+1;
  end*/
  else if(next_state==S2D)begin
    case(buf_cnt)
    1:data_o1<=data_out;
    2:data_o2<=data_out;
    3:data_o3<=data_out;
    4:data_o4<=data_out;
    endcase
  end
  else if(current_state==IDLE)begin
  data_o1<=0;
  data_o2<=0;
  data_o3<=0;
  data_o4<=0;
  end
end
////////////////////////////////////////////////
//    Write back to DRAM
////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) buffer<=0;
  else if(current_state==S2D&&buf_cnt==5) buffer<={data_o4,data_o3,data_o2,data_o1};
  else if(current_state==IDLE) buffer<=32'b0;
end

////////////////////////////////////////////////
//    generate circuit for input matrix
///////////////////////////////////////////////

//assign plus = (hand_cnt-1)*4;
/*
genvar i,j;
generate
  for(i=0;i<16;i=i+1)begin
    for(j=0;j<16;j=j+1)begin
      always @(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
          in_m[i][j]<=0;
        end
      //(hand_cnt==1)&&  
        else if((hand_cnt==1)&&(read_cnt<16)&&rvalid_m_inf)begin
          if((i==(read_cnt/4))&&(j==(read_cnt*4)%16))begin
              in_m[i][j]<=rdata_m_inf[7:0];
              in_m[i][j+1]<=rdata_m_inf[15:8];
              in_m[i][j+2]<=rdata_m_inf[23:16];
              in_m[i][j+3]<=rdata_m_inf[31:24];
          end
        end
       
        else if((hand_cnt==2)&&(read_cnt<16)&&rvalid_m_inf)begin
          if(i==((read_cnt/4)+4)&&(j==(read_cnt*4)%16))begin
            in_m[i][j]<=rdata_m_inf[7:0];
            in_m[i][j+1]<=rdata_m_inf[15:8];
            in_m[i][j+2]<=rdata_m_inf[23:16];
            in_m[i][j+3]<=rdata_m_inf[31:24];
          end
        end
       
       
        else if((hand_cnt==3)&&(read_cnt<16)&&rvalid_m_inf)begin
          if(i==((read_cnt/4)+8)&&(j==(read_cnt*4)%16))begin
            in_m[i][j]<=rdata_m_inf[7:0];
            in_m[i][j+1]<=rdata_m_inf[15:8];
            in_m[i][j+2]<=rdata_m_inf[23:16];
            in_m[i][j+3]<=rdata_m_inf[31:24];
          end
        end
       
       
         else if((hand_cnt==4)&&(read_cnt<16)&&rvalid_m_inf)begin
          if(i==((read_cnt/4)+12)&&(j==(read_cnt*4)%16))begin
            in_m[i][j]<=rdata_m_inf[7:0];
            in_m[i][j+1]<=rdata_m_inf[15:8];
            in_m[i][j+2]<=rdata_m_inf[23:16];
            in_m[i][j+3]<=rdata_m_inf[31:24];
          end
        end
       
      end
    end
  end
endgenerate
*/
always @(posedge clk or negedge rst_n) begin
  if(!rst_n)begin
    for(i0=0;i0<16;i0=i0+1)begin
      for(j0=0;j0<16;j0=j0+1)begin
        in_m[i0][j0]<=0;
      end
    end
  end
  else if((hand_cnt==1)&&(read_cnt<16)&&rvalid_m_inf)begin
    for(i0=0;i0<4;i0=i0+1)begin
      for(j0=0;j0<16;j0=j0+1)begin
        if((i0==(read_cnt/4))&&(j0==(read_cnt*4)%16))begin
              in_m[i0][j0]<=rdata_m_inf[7:0];
              in_m[i0][j0+1]<=rdata_m_inf[15:8];
              in_m[i0][j0+2]<=rdata_m_inf[23:16];
              in_m[i0][j0+3]<=rdata_m_inf[31:24];
          end
      end
    end
  end
  else if((hand_cnt==2)&&(read_cnt<16)&&rvalid_m_inf)begin
    for(i0=4;i0<8;i0=i0+1)begin
      for(j0=0;j0<16;j0=j0+1)begin
        if(i0==((read_cnt/4)+4)&&(j0==(read_cnt*4)%16))begin
            in_m[i0][j0]<=rdata_m_inf[7:0];
            in_m[i0][j0+1]<=rdata_m_inf[15:8];
            in_m[i0][j0+2]<=rdata_m_inf[23:16];
            in_m[i0][j0+3]<=rdata_m_inf[31:24];
          end
      end
    end
  end
  else if((hand_cnt==3)&&(read_cnt<16)&&rvalid_m_inf)begin
    for(i0=8;i0<12;i0=i0+1)begin
      for(j0=0;j0<16;j0=j0+1)begin
         if(i0==((read_cnt/4)+8)&&(j0==(read_cnt*4)%16))begin
            in_m[i0][j0]<=rdata_m_inf[7:0];
            in_m[i0][j0+1]<=rdata_m_inf[15:8];
            in_m[i0][j0+2]<=rdata_m_inf[23:16];
            in_m[i0][j0+3]<=rdata_m_inf[31:24];
          end
      end
    end
  end
 else if((hand_cnt==4)&&(read_cnt<16)&&rvalid_m_inf)begin
  for(i0=12;i0<16;i0=i0+1)begin
    for(j0=0;j0<16;j0=j0+1)begin
       if(i0==((read_cnt/4)+12)&&(j0==(read_cnt*4)%16))begin
            in_m[i0][j0]<=rdata_m_inf[7:0];
            in_m[i0][j0+1]<=rdata_m_inf[15:8];
            in_m[i0][j0+2]<=rdata_m_inf[23:16];
            in_m[i0][j0+3]<=rdata_m_inf[31:24];
          end
    end
  end
 end

end


always @(posedge clk or negedge rst_n) begin
  if(!rst_n) out_valid<=0;
  else if(current_state==OUT) out_valid<=1;
  else out_valid<=0;
end
endmodule








