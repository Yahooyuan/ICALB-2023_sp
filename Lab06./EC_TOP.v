//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright Optimum Application-Specific Integrated System Laboratory
//    All Right Reserved
//		Date		: 2023/03
//		Version		: v1.0
//   	File Name   : EC_TOP.v
//   	Module Name : EC_TOP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

//synopsys translate_off
`include "INV_IP.v"
//synopsys translate_on

module EC_TOP(
    // Input signals
    clk, rst_n, in_valid,
    in_Px, in_Py, in_Qx, in_Qy, in_prime, in_a,
    // Output signals
    out_valid, out_Rx, out_Ry
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid;
input [6-1:0] in_Px, in_Py, in_Qx, in_Qy, in_prime, in_a;
output reg out_valid;
output reg [6-1:0] out_Rx, out_Ry;
// ===============================================================
//parameters
// ===============================================================
parameter IDLE = 3'b0;
parameter IN_DATA = 3'b1;
parameter CAL1 = 3'b010;
parameter CAL2 = 3'b011;
parameter CAL3 = 3'b100;
parameter CAL4 = 3'b101;
parameter OUT = 3'b110;

reg [2:0] current_state,next_state;
reg [5:0] Px,Py,Qx,Qy;
reg [5:0] npx,npy,nqx,nqy,nrx;
reg [5:0] pr,a;
reg [5:0] in1,in2;
wire [5:0] wout;
//reg [5:0] invout;
//reg [5:0] cout;
reg [20:0] fup;
reg [20:0] s;
reg  [7:0] Rx,Ry;
reg [10:0] bin1;
//wire  [5:0] t;
//assign t = (-14%17);
// ===============================================================
//FSM
// ===============================================================
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
      if(!in_valid)  next_state = CAL1;
      else next_state = IN_DATA;
    end
    CAL1:begin
        next_state = CAL2;
    end
    CAL2:begin
        next_state = CAL3;
    end
    CAL3:begin
        next_state = CAL4;
    end
    CAL4:begin
        next_state = OUT;
    end
    OUT:begin
        next_state = IDLE;
    end
    default:next_state = IDLE;
    endcase
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        Px<=0;
        Py<=0;
        Qx<=0;
        Qy<=0;
        pr<=0;
        a<=0;
    end
    else if(in_valid)begin
        Px<=in_Px;
        Py<=in_Py;
        Qx<=in_Qx;
        Qy<=in_Qy;
        pr<=in_prime;
        a<=in_a;
    end
end
always@(*)begin
    npx = pr-Px;
    npy = pr-Py;
    nqx = pr-Qx;
    nqy = pr-Qy;
    nrx = pr-Rx;
end
always@(*)begin
    if((Px==Qx)&&(Py==Qy)) begin
        bin1 = (2*Py)%pr;
        in1=bin1;
        in2=pr;
    end
    else begin
        bin1 = (Qx+npx)%pr;
        in1=bin1;
        in2 = pr;
    end
end
INV_IP #(.IP_WIDTH(6)) I_INV_IP ( .IN_1(in1), .IN_2(in2), .OUT_INV(wout));

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        fup<=0;
    end
    else if(current_state==CAL1)begin
        if((Px==Qx)&&(Py==Qy)) begin
            fup<=(3*Px*Px+a)%pr;
        end
        else begin
            fup<=(Qy+npy)%pr;
        end
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        s<=0;
    end
    else if(current_state==CAL2)begin
            s<=(fup*wout)%pr;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        Rx<=0;
    end
    else if(current_state==CAL3)begin
            Rx<=((s*s)+npx+nqx)%pr;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        Ry<=0;
    end
    else if(current_state==CAL4)begin
        Ry<=(s*(Px+nrx)+npy)%pr;
    end
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        out_valid<=0;
        out_Rx<=0;
        out_Ry<=0;
    end
    else if(current_state==OUT)begin
        out_valid<=1;
        out_Rx<=Rx;
        out_Ry<=Ry;
    end
    else begin
        out_valid<=0;
        out_Rx<=0;
        out_Ry<=0;
    end
end
endmodule

