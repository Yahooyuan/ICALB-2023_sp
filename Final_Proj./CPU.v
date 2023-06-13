//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Final Project: Customized ISA Processor 
//   Author              : Hsi-Hao Huang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CPU.v
//   Module Name : CPU.v
//   Release version : V1.0 (Release Date: 2023-May)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module CPU(

				clk,
			  rst_n,
  
		   IO_stall,

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
// Input port
input  wire clk, rst_n;
// Output port
output reg  IO_stall;

parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=2, WRIT_NUMBER=1;

// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
  your AXI-4 interface could be designed as convertor in submodule(which used reg for output signal),
  therefore I declared output of AXI as wire in CPU
*/



// axi write address channel 
output  wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_m_inf;
output  wire [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_m_inf;
output  wire [WRIT_NUMBER * 3 -1:0]            awsize_m_inf;
output  wire [WRIT_NUMBER * 2 -1:0]           awburst_m_inf;
output  wire [WRIT_NUMBER * 7 -1:0]             awlen_m_inf;
output  wire [WRIT_NUMBER-1:0]                awvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                awready_m_inf;
// axi write data channel 
output  wire [WRIT_NUMBER * DATA_WIDTH-1:0]     wdata_m_inf;
output  wire [WRIT_NUMBER-1:0]                  wlast_m_inf;
output  wire [WRIT_NUMBER-1:0]                 wvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                 wready_m_inf;
// axi write response channel
input   wire [WRIT_NUMBER * ID_WIDTH-1:0]         bid_m_inf;
input   wire [WRIT_NUMBER * 2 -1:0]             bresp_m_inf;
input   wire [WRIT_NUMBER-1:0]             	   bvalid_m_inf;
output  wire [WRIT_NUMBER-1:0]                 bready_m_inf;
// -----------------------------
// axi read address channel 
output  wire [DRAM_NUMBER * ID_WIDTH-1:0]       arid_m_inf;
output  wire [DRAM_NUMBER * ADDR_WIDTH-1:0]   araddr_m_inf;
output  wire [DRAM_NUMBER * 7 -1:0]            arlen_m_inf;
output  wire [DRAM_NUMBER * 3 -1:0]           arsize_m_inf;
output  wire [DRAM_NUMBER * 2 -1:0]          arburst_m_inf;
output  wire [DRAM_NUMBER-1:0]               arvalid_m_inf;
input   wire [DRAM_NUMBER-1:0]               arready_m_inf;
// -----------------------------
// axi read data channel 
input   wire [DRAM_NUMBER * ID_WIDTH-1:0]         rid_m_inf;
input   wire [DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_m_inf;
input   wire [DRAM_NUMBER * 2 -1:0]             rresp_m_inf;
input   wire [DRAM_NUMBER-1:0]                  rlast_m_inf;
input   wire [DRAM_NUMBER-1:0]                 rvalid_m_inf;
output  wire [DRAM_NUMBER-1:0]                 rready_m_inf;
// -----------------------------

//
//
// 
/* Register in each core:
  There are sixteen registers in your CPU. You should not change the name of those registers.
  TA will check the value in each register when your core is not busy.
  If you change the name of registers below, you must get the fail in this lab.
*/

reg signed [15:0] core_r0 , core_r1 , core_r2 , core_r3 ;
reg signed [15:0] core_r4 , core_r5 , core_r6 , core_r7 ;
reg signed [15:0] core_r8 , core_r9 , core_r10, core_r11;
reg signed [15:0] core_r12, core_r13, core_r14, core_r15;


//###########################################
//
// Wrtie down your design below
//
//###########################################

//####################################################
//               reg & wire & parameter
//####################################################
reg [2:0] current_state,next_state;
////// signal for ins cache
reg signed [15:0] pc_counter,last_pc;
reg ins_fetch;//********
wire ins_ready;
wire [15:0] ins_out;
///// signal for data cache
reg loading;
wire load_ready;
reg store_change;
reg signed [15:0] store_data_rt;
wire signed [15:0] load_data;
reg signed [15:0] load_address;
////// signal for write brige
reg storing;
wire store_done;
reg signed [15:0] store_data;
reg signed [15:0] store_address;
///////////////////////////////
////// signal for design
//////////////////////////////
reg [2:0] op_code;//******
reg func;//********
reg [3:0] rs_num,rt_num,rd_num;//********
reg signed [15:0] rs,rt,rd;
reg signed [4:0] imm;//**********
reg [12:0] j_address;//**************
////////////////////////////////////////////////////////
////// FSM
///////////////////////////////////////////////////////
parameter IDLE = 3'b000;
parameter IF = 3'b001;
parameter ID = 3'b010;
parameter EXE = 3'b011;
parameter MEM = 3'b100;
parameter WB = 3'b101;

parameter signed OFF = 16'h1000;
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) current_state<=0;
  else current_state<=next_state;
end

always @(*) begin
  case(current_state)
  IDLE:begin
      next_state = IF;
  end
  IF:begin
    if(ins_ready) next_state = ID;
    else next_state = IF;
  end
  ID:begin
    next_state = EXE;
  end
  EXE:begin
    if (op_code[1]==1'b1)         next_state = MEM;
    else if (op_code[2]==1'b1)   next_state = IF ;
    else                        next_state =WB;
  end
  MEM:begin
    if(op_code==3'b011) begin
      if(load_ready) next_state = IF;
      else next_state = MEM;
    end
    else begin
      if(store_done) next_state = IF;
      else next_state = MEM;
    end
  end
  WB:begin
    next_state = IF;
  end
  default:next_state = IDLE;
  endcase
end
//####################################################
//               DESIGN
//####################################################
always @(*) begin
  op_code = ins_out[15:13];
end
always @(*) begin
  func = ins_out[0];
end
always @(*) begin
  rs_num = ins_out[12:9];
end
always @(*) begin
  rt_num = ins_out[8:5];
end
always @(*) begin
  rd_num = ins_out[4:1];
end
always @(*) begin
  imm = ins_out[4:0];
end
always @(*) begin
  j_address = {3'b000,ins_out[12:0]};
end
//controal of  cache signal
/*always @(*) begin
  if(current_state==MEM&&op_code==3'b010) store_change = 1;
  else store_change = 0;
end*/
always @(*) begin
  load_address = (2*(rs+imm))+OFF;
end
always @(*) begin
  store_address = (2*(rs+imm))+OFF;
end
always @(*) begin
  store_data_rt = rt;
end
always @(*) begin
  store_data = rt;
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) ins_fetch<=0;
  else if(next_state==IF&&(current_state!=IF)) ins_fetch<=1;
  else ins_fetch<=0;
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) loading<=0;
  else if(next_state==MEM&&(current_state!=MEM)) loading<=1;
  else loading<=0;
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) storing<=0;
  else if(next_state==MEM&&(current_state!=MEM)&&(op_code==3'b010)) storing<=1;
  else storing <=0;
end
always @(posedge clk or negedge rst_n) begin//////refresh pc_counter at EXE stage(any stage after IF)
  if(!rst_n)pc_counter<=16'h1000;
  else if(next_state==EXE) pc_counter<=last_pc;
end
always @(*) begin
  if(op_code==3'b100) last_pc = j_address;
  else if(op_code==3'b101)begin
    if(rs==rt) last_pc =pc_counter+2+(imm*2);
    else last_pc = pc_counter+2;
  end
  else last_pc = pc_counter+2;
end
//####################################################
//               CALL Submodule
//####################################################
/// ins cache
INS_CACHE cache1(.clk(clk),.rst_n(rst_n),.take_ins(ins_fetch),.pc_counter(pc_counter),.ins_ready(ins_ready),.now_ins_o(ins_out), .arid_m_inf(arid_m_inf[7:4]),
.araddr_m_inf(araddr_m_inf[63:32]),.arlen_m_inf(arlen_m_inf[13:7]),.arsize_m_inf(arsize_m_inf[5:3]),.arburst_m_inf(arburst_m_inf[3:2]),
.arvalid_m_inf(arvalid_m_inf[1]),.arready_m_inf(arready_m_inf[1]),.rid_m_inf(rid_m_inf[7:4]),.rdata_m_inf(rdata_m_inf[31:16]),.rresp_m_inf(rresp_m_inf[3:2]),
.rlast_m_inf(rlast_m_inf[1]),.rvalid_m_inf(rvalid_m_inf[1]),.rready_m_inf(rready_m_inf[1]));
// data cache 
READ_CACHE cache2(.clk(clk),.rst_n(rst_n),.loading(loading),.load_ready(load_ready),.store_change(current_state==MEM&&op_code==3'b010),.store_data_rt(rt),.load_data(load_data),.load_address(load_address),
.arid_m_inf(arid_m_inf[3:0]),.araddr_m_inf(araddr_m_inf[31:0]),.arlen_m_inf(arlen_m_inf[6:0]),.arsize_m_inf(arsize_m_inf[2:0]),.arburst_m_inf(arburst_m_inf[1:0]),
.arvalid_m_inf(arvalid_m_inf[0]),.arready_m_inf(arready_m_inf[0]),.rid_m_inf(rid_m_inf[3:0]),.rdata_m_inf(rdata_m_inf[15:0]),.rresp_m_inf(rresp_m_inf[1:0]),
.rlast_m_inf(rlast_m_inf[0]),.rvalid_m_inf(rvalid_m_inf[0]),.rready_m_inf(rready_m_inf[0]));
//write brige
WRITE_BRIGE brige1(.clk(clk),.rst_n(rst_n),.storing(storing),.store_data(store_data),.store_address(store_address),.store_done(store_done),
.awid_m_inf(awid_m_inf),.awaddr_m_inf(awaddr_m_inf),.awsize_m_inf(awsize_m_inf),.awburst_m_inf(awburst_m_inf),.awlen_m_inf(awlen_m_inf),
.awvalid_m_inf(awvalid_m_inf),.awready_m_inf(awready_m_inf),.wdata_m_inf(wdata_m_inf),
.wlast_m_inf(wlast_m_inf),.wvalid_m_inf(wvalid_m_inf),.wready_m_inf(wready_m_inf),.bid_m_inf(bid_m_inf),.bresp_m_inf(bresp_m_inf),
.bvalid_m_inf(bvalid_m_inf),.bready_m_inf(bready_m_inf));

//####################################################
//               OUTPUT 
//####################################################
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) IO_stall<=1;
  else if(next_state==IF&&(current_state!=IF)&&(current_state!=IDLE))IO_stall<=0;
  else IO_stall<=1;
end
////////////////////////////////////////////////////////rs
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) rs<=0;
  else if(next_state==ID)begin
    if(rs_num==0) rs<=core_r0;
    else if(rs_num==1) rs<=core_r1;
    else if (rs_num==2) rs<=core_r2;
    else if(rs_num==3) rs<=core_r3;
    else if(rs_num==4) rs<=core_r4;
    else if(rs_num==5) rs<=core_r5;
    else if(rs_num==6) rs<=core_r6;
    else if(rs_num==7) rs<=core_r7;
    else if(rs_num==8) rs<=core_r8;
    else if(rs_num==9) rs<=core_r9;
    else if(rs_num==10) rs<=core_r10;
    else if(rs_num==11) rs<=core_r11;
    else if(rs_num==12) rs<=core_r12;
    else if(rs_num==13) rs<=core_r13;
    else if(rs_num==14) rs<=core_r14;
    else if(rs_num==15) rs<=core_r15;
  end
end
/////////////////////////////////////////////////////rt
always @(posedge clk or negedge rst_n) begin
   if(!rst_n) rt<=0;
  else if(next_state==ID)begin
    if(rt_num==0) rt<=core_r0;
    else if(rt_num==1) rt<=core_r1;
    else if (rt_num==2) rt<=core_r2;
    else if(rt_num==3) rt<=core_r3;
    else if(rt_num==4) rt<=core_r4;
    else if(rt_num==5) rt<=core_r5;
    else if(rt_num==6) rt<=core_r6;
    else if(rt_num==7) rt<=core_r7;
    else if(rt_num==8) rt<=core_r8;
    else if(rt_num==9) rt<=core_r9;
    else if(rt_num==10) rt<=core_r10;
    else if(rt_num==11) rt<=core_r11;
    else if(rt_num==12) rt<=core_r12;
    else if(rt_num==13) rt<=core_r13;
    else if(rt_num==14) rt<=core_r14;
    else if(rt_num==15) rt<=core_r15;
  end
end
//////////////////////////////////////////////////////rd
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) rd<=0;
  else if(next_state==EXE)begin
    if(op_code==3'b000)begin
      if(func==1) rd<= rs+rt;
      else rd<= rs-rt;
    end
    else if(op_code==001)begin
      if(func==0) rd<=rs*rt;
      else begin
        if(rs<rt) rd<=1;
        else rd<=0;
      end
    end
  end
  else rd<=0;
end
//####################################################
//               core reg file 
//####################################################
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) core_r0<=0;
  else if(next_state==WB&&rd_num==0) core_r0<=rd;
  else if(load_ready&&rt_num==0&&op_code==3'b011) core_r0<=load_data;
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) core_r1<=0;
  else if(next_state==WB&&rd_num==1) core_r1<=rd;
  else if(load_ready&&rt_num==1&&op_code==3'b011) core_r1<=load_data;
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) core_r2<=0;
  else if(next_state==WB&&rd_num==2) core_r2<=rd;
  else if(load_ready&&rt_num==2&&op_code==3'b011) core_r2<=load_data;
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) core_r3<=0;
  else if(next_state==WB&&rd_num==3) core_r3<=rd;
  else if(load_ready&&rt_num==3&&op_code==3'b011) core_r3<=load_data;
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) core_r4<=0;
  else if(next_state==WB&&rd_num==4) core_r4<=rd;
  else if(load_ready&&rt_num==4&&op_code==3'b011) core_r4<=load_data;
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) core_r5<=0;
  else if(next_state==WB&&rd_num==5) core_r5<=rd;
  else if(load_ready&&rt_num==5&&op_code==3'b011) core_r5<=load_data;
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) core_r6<=0;
  else if(next_state==WB&&rd_num==6) core_r6<=rd;
  else if(load_ready&&rt_num==6&&op_code==3'b011) core_r6<=load_data;
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) core_r7<=0;
  else if(next_state==WB&&rd_num==7) core_r7<=rd;
  else if(load_ready&&rt_num==7&&op_code==3'b011) core_r7<=load_data;
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) core_r8<=0;
  else if(next_state==WB&&rd_num==8) core_r8<=rd;
  else if(load_ready&&rt_num==8&&op_code==3'b011) core_r8<=load_data;
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) core_r9<=0;
  else if(next_state==WB&&rd_num==9) core_r9<=rd;
  else if(load_ready&&rt_num==9&&op_code==3'b011) core_r9<=load_data;
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) core_r10<=0;
  else if(next_state==WB&&rd_num==10) core_r10<=rd;
  else if(load_ready&&rt_num==10&&op_code==3'b011) core_r10<=load_data;
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) core_r11<=0;
  else if(next_state==WB&&rd_num==11) core_r11<=rd;
  else if(load_ready&&rt_num==11&&op_code==3'b011) core_r11<=load_data;
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) core_r12<=0;
  else if(next_state==WB&&rd_num==12) core_r12<=rd;
  else if(load_ready&&rt_num==12&&op_code==3'b011) core_r12<=load_data;
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) core_r13<=0;
  else if(next_state==WB&&rd_num==13) core_r13<=rd;
  else if(load_ready&&rt_num==13&&op_code==3'b011) core_r13<=load_data;
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) core_r14<=0;
  else if(next_state==WB&&rd_num==14) core_r14<=rd;
  else if(load_ready&&rt_num==14&&op_code==3'b011) core_r14<=load_data;
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) core_r15<=0;
  else if(next_state==WB&&rd_num==15) core_r15<=rd;
  else if(load_ready&&rt_num==15&&op_code==3'b011) core_r15<=load_data;
end
endmodule

//####################################################
//               Submodule
//####################################################
//////////////////////////
//      INS CACHE
/////////////////////////
module INS_CACHE (
  clk,
  rst_n,
  take_ins,
  pc_counter,
  ins_ready,
  now_ins_o,
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
parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=2, WRIT_NUMBER=1;
input clk,rst_n;
input take_ins;
output reg ins_ready;
output reg [15:0] now_ins_o;
input wire [15:0] pc_counter;//////15~12 bits can't be change only change 0~11
output  wire [ID_WIDTH-1:0]       arid_m_inf;//******** 
output  reg [ADDR_WIDTH-1:0]   araddr_m_inf;///******** reset to 0
output  wire [6:0]            arlen_m_inf;//**********
output  wire [2:0]           arsize_m_inf;//**********
output  wire [1:0]          arburst_m_inf;//********
output  reg                    arvalid_m_inf;//******* reset to 0
input   wire                   arready_m_inf;
input   wire [ID_WIDTH-1:0]         rid_m_inf;
input   wire [DATA_WIDTH-1:0]     rdata_m_inf;
input   wire [1:0]             rresp_m_inf;
input   wire                      rlast_m_inf;
input   wire                     rvalid_m_inf;
output  wire                     rready_m_inf;//***********


//####################################################
//               Wire and reg
//####################################################
reg [2:0] current_state,next_state;
reg [3:0] block_num;
reg first_d2s;
wire [15:0] now_ins;
reg [6:0] now_cache_address;
//####################################################
//               State & FSM
//####################################################
parameter IDLE = 3'b000;
parameter IN_CACHE = 3'b001;
parameter BUF = 3'b010;
parameter NOT_IN_C = 3'b011;
parameter D2S = 3'b100;
parameter OUT = 3'b101;
//////// wire &parameter assign
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) block_num <=0;
  else if(current_state==NOT_IN_C) block_num<=pc_counter[11:8];
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) first_d2s <=0;
  else if(current_state==NOT_IN_C) first_d2s<=1;
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     now_cache_address <= 0 ;
    else begin
        if (next_state==IN_CACHE)      now_cache_address <= pc_counter[7:1] ;
        else if (rvalid_m_inf==1)   now_cache_address <= now_cache_address + 1 ;
        else if (next_state==IDLE)    now_cache_address <= 0 ;
    end
end
///////////////////////////////
//FSM
always@(posedge clk or negedge rst_n) begin
  if(!rst_n) current_state<=IDLE;
  else current_state<=next_state;
end

always @(*) begin
  case(current_state)
  IDLE:begin
    if(take_ins&&block_num==pc_counter[11:8]&&first_d2s) next_state = IN_CACHE;
    else if(take_ins) next_state = NOT_IN_C;
    else next_state = IDLE;
  end
  IN_CACHE:begin
    next_state = BUF;
  end
  BUF: next_state = OUT;
  NOT_IN_C:begin
    if(arready_m_inf) next_state = D2S;
    else next_state = NOT_IN_C;
  end
  D2S:begin
    if(rlast_m_inf) next_state = OUT;
    else next_state = D2S;
  end
  OUT:begin
    next_state = IDLE;
  end
  default:next_state = IDLE;
  endcase
end
/////////////////
assign arid_m_inf = 0 ;
assign arlen_m_inf = 7'b1111111 ;
assign arsize_m_inf = 3'b001 ;
assign arburst_m_inf = 2'b01 ;
//assign araddr_m_inf = {16'd0,pc_counter[15:8],8'b00000000};
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) araddr_m_inf<=0;
  else araddr_m_inf<={16'b0,pc_counter[15:8],8'b0};
end
assign rready_m_inf = (current_state==D2S) ? 1 : 0 ;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     arvalid_m_inf <= 0 ;
    else begin
        if (next_state==NOT_IN_C) arvalid_m_inf <= 1 ;
        else arvalid_m_inf <= 0 ;
    end
end
/////////SRAM used as cache
RA2SH cache_ins(.Q(now_ins),.CLK(clk),.CEN(1'b0),.WEN(current_state!=D2S),.A(now_cache_address),.D(rdata_m_inf),.OEN(1'b0));
///////////////////////////////////////////////////////
///           OUT
//////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) ins_ready<=0;
  else if(current_state==OUT) ins_ready<=1;
  else ins_ready<=0;
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) now_ins_o<=0;
  else begin
    if(current_state==D2S&&rvalid_m_inf&&(now_cache_address==pc_counter[7:1])) now_ins_o<=rdata_m_inf;
    else if(current_state==BUF) now_ins_o<=now_ins;
  end
end
endmodule

//////////////////////////////////////////////
////R_data CACHE
//////////////////////////////////////////////

module READ_CACHE (
  clk,
  rst_n,
  loading,
  load_ready,
  store_change,
  store_data_rt,
  load_data,
  load_address,
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
parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=2, WRIT_NUMBER=1;
  input clk,rst_n;
  input loading,store_change;
  output reg load_ready;
  input [15:0] store_data_rt;
  output reg [15:0] load_data;
  input [15:0] load_address;
  output  wire [ID_WIDTH-1:0]       arid_m_inf;//*****
  output  reg [ADDR_WIDTH-1:0]   araddr_m_inf;//***********
  output  wire [7 -1:0]            arlen_m_inf;//***********
  output  wire [3 -1:0]           arsize_m_inf;//***********
  output  wire [2 -1:0]          arburst_m_inf;//***********
  output  reg                    arvalid_m_inf;
  input   wire                   arready_m_inf;
  input   wire [ID_WIDTH-1:0]         rid_m_inf;
  input   wire [DATA_WIDTH-1:0]     rdata_m_inf;
  input   wire [2 -1:0]             rresp_m_inf;
  input   wire                      rlast_m_inf;
  input   wire                     rvalid_m_inf;
  output  wire                     rready_m_inf;//***********

////////// wire && reg//////////////////////////////
reg [2:0] current_state,next_state;
reg first_d2s;
reg [3:0] block_num;
wire [15:0] s_data_out;
reg [6:0] now_cache_address;
reg [15:0] s_data_in;
wire [6:0] take_out_addr;
///////// parameter////////////////////////////////////////
parameter IDLE = 3'b000;
parameter IN_CACHE = 3'b001;
parameter BUF = 3'b010;
parameter NOT_IN_C = 3'b011;
parameter D2S = 3'b100;
parameter STORE_DRAM = 3'b101;
parameter OUT = 3'b110;
///////////////////////////////////////////
assign arid_m_inf = 0;
assign arlen_m_inf = 7'b1111111;
assign arsize_m_inf = 3'b001 ;
assign arburst_m_inf = 2'b01 ;
//assign araddr_m_inf = { 16'd0,4'b0001,load_address[11:8],8'b00000000};
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) araddr_m_inf<=0;
  else araddr_m_inf<={16'b0,4'b0001,load_address[11:8],8'b0};
end
assign rready_m_inf = (current_state==D2S)?1:0;
assign take_out_addr = load_address[7:1];
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     arvalid_m_inf <= 0 ;
    else begin
        if (next_state==NOT_IN_C) arvalid_m_inf <= 1 ;
        else arvalid_m_inf <= 0 ;
    end
end
/////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) first_d2s <=0;
  else if(current_state==NOT_IN_C) first_d2s<=1;
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) block_num <=0;
  else if(current_state==NOT_IN_C) block_num<=load_address[11:8];
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     now_cache_address <= 0 ;
    else begin
        if (next_state==IN_CACHE||next_state==STORE_DRAM)now_cache_address <= load_address[7:1] ;
        else if (rvalid_m_inf==1)now_cache_address <= now_cache_address + 1 ;
        else if (next_state==IDLE)now_cache_address <= 0 ;
    end
end
//////////////// FSM/////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) current_state<=IDLE;
  else current_state<=next_state;
end

always @(*) begin
  case(current_state)
  IDLE:begin
    if(loading&&store_change&&(block_num==load_address[11:8])) next_state = STORE_DRAM;
    else if(loading&&(block_num==load_address[11:8])&&(first_d2s!=0)) next_state = IN_CACHE;
    else if(store_change==0&&loading) next_state = NOT_IN_C;
    else next_state = IDLE;
  end
  IN_CACHE:begin
    next_state = BUF;
  end
  BUF:begin
    next_state = OUT;
  end
  NOT_IN_C:begin
    if(arready_m_inf)next_state = D2S;
    else next_state = NOT_IN_C;
  end
  D2S:begin
    if(rlast_m_inf) next_state = OUT;
    else next_state = D2S;
  end
  STORE_DRAM:begin
    next_state = IDLE;
  end
  OUT: next_state = IDLE;
  default:next_state = IDLE;
  endcase
end
///////CACHE//////////////////
always @(*) begin
  if(current_state==STORE_DRAM) s_data_in = store_data_rt;
  else s_data_in = rdata_m_inf;
end
RA2SH chche_data(.Q(s_data_out),.CLK(clk),.CEN(1'b0),.WEN((current_state!=D2S)&&(current_state!=STORE_DRAM)),.A(now_cache_address),.D(s_data_in),.OEN(1'b0));
/////////////////////////////////
////////       OUT
////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) load_ready<=0;
  else if(current_state==OUT) load_ready<=1;
  else load_ready<=0;
end

always @(posedge clk  or negedge rst_n) begin
  if(!rst_n) load_data<=0;
  else  begin
    if(current_state==D2S&&rvalid_m_inf&&(now_cache_address==take_out_addr)) load_data<=rdata_m_inf;
    else if(current_state==BUF) load_data<=s_data_out;
  end
end
endmodule


///////////////////////////////////////
//// W to DRAM brige
///////////////////////////////////////
module WRITE_BRIGE (
  clk,
  rst_n,
  storing,
  store_data,
  store_address,
  store_done,
  awid_m_inf,//**********
  awaddr_m_inf,//***** need to reset to 0
  awsize_m_inf,//**********
  awburst_m_inf,//********
  awlen_m_inf,//********** store one data back once
  awvalid_m_inf,//********* need to reset to 0
  awready_m_inf,                     
  wdata_m_inf,//********
  wlast_m_inf,//*******
  wvalid_m_inf,//********
  wready_m_inf,
  bid_m_inf,
  bresp_m_inf,
  bvalid_m_inf,
  bready_m_inf//********* need to resrt to 0
);
parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=2, WRIT_NUMBER=1;
  input clk, rst_n;
  input storing;
  input [15:0] store_data,store_address;
  output store_done;
  output  wire [ID_WIDTH-1:0]        awid_m_inf;//*****
  output  reg [ADDR_WIDTH-1:0]    awaddr_m_inf;//*******
  output  wire [3 -1:0]            awsize_m_inf;//******
  output  wire [2 -1:0]           awburst_m_inf;//*****
  output  wire [7 -1:0]             awlen_m_inf;//*******
  output  reg                     awvalid_m_inf;//********
  input   wire                    awready_m_inf;
  output  reg  [DATA_WIDTH-1:0]     wdata_m_inf;
  output  reg                       wlast_m_inf;//******
  output  reg                      wvalid_m_inf;//**********
  input   wire                     wready_m_inf;
  input   wire [ID_WIDTH-1:0]         bid_m_inf;
  input   wire [2 -1:0]             bresp_m_inf;
  input   wire                     bvalid_m_inf;
  output  wire                     bready_m_inf;

  reg [2:0] current_state,next_state;
  reg store_done;
  reg wr_flag;
  parameter IDLE = 3'b000;
  parameter REQ_D = 3'b001;
  parameter R2D = 3'b010;
  parameter OUT = 3'b011;
  parameter WAIT_NEXT = 3'b100;

  assign awid_m_inf = 0 ;
  assign awlen_m_inf = 7'd0 ;
  assign awsize_m_inf = 3'b001 ;
  assign awburst_m_inf = 2'b01 ;
  //assign awaddr_m_inf = {16'd0,store_address};
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) awaddr_m_inf<=0;
    else awaddr_m_inf<={16'b0,store_address};
  end
  assign bready_m_inf = (current_state==OUT||current_state==WAIT_NEXT) ?1:0;
  ///// awvalid 
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) awvalid_m_inf<=0;
    else if(current_state==REQ_D&&(awready_m_inf==0)) awvalid_m_inf<=1;
    else awvalid_m_inf<=0;
  end
  ////wdata
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) wdata_m_inf<=0;
    else if(current_state==REQ_D) wdata_m_inf<=store_data;
    //else wdata_m_inf<=0;
  end
  //wlast one data send come after awready response 
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) wlast_m_inf<=0;
    else begin
    if(next_state==R2D) wlast_m_inf<=1;
    else wlast_m_inf<=0;
    end
  end
//////wvalid come after awready response 
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) wvalid_m_inf<=0;
    else begin
    if(next_state==R2D) wvalid_m_inf<=1;
    else wvalid_m_inf<=0;
    end
  end
  /////////////////////////////////////
  //FSM
  /////////////////////////////////////
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) current_state<=IDLE;
    else current_state<=next_state;
  end
  always @(*) begin
  case(current_state)
      IDLE:begin
        if(storing) next_state = REQ_D;
        else next_state = IDLE;
      end
      REQ_D:begin
        if(awready_m_inf) next_state = R2D;
        else next_state = REQ_D;
      end
      R2D:begin
        if(wready_m_inf)next_state = OUT;
        else next_state = R2D;
      end
      OUT:begin
         if(bvalid_m_inf) next_state = IDLE;
         else next_state = WAIT_NEXT;
      end
      WAIT_NEXT:begin
        if(bvalid_m_inf) next_state = IDLE;
        else next_state = WAIT_NEXT;
      end
      default:next_state = IDLE;
  endcase
  end

always @(posedge clk or negedge rst_n) begin
  if(!rst_n) store_done<=0;
  else if(current_state==OUT) store_done<=1;
  else store_done<=0;
end

endmodule





