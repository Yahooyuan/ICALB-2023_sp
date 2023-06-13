module MMT(
// input signals
    clk,
    rst_n,
    in_valid,
	in_valid2,
    matrix,
	matrix_size,
    matrix_idx,
    mode,
	
// output signals
    out_valid,
    out_value
);
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
input        clk, rst_n, in_valid, in_valid2;
input [7:0] matrix;
input [1:0]  matrix_size,mode;
input [4:0]  matrix_idx;

output reg       	     out_valid;
output reg signed [49:0] out_value;
//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------
parameter IDLE = 4'b0000;
parameter IN_DATA = 4'b0001;//Store in SRAM
parameter CHECK = 4'b0010;//know which 3 matrix & mode
parameter BUF = 4'b0011;//read 3 matrix form SRAM and do trans
parameter CAL_trans =4'b0100 ;
parameter CAL_F = 4'b0101;//CAL AB 
parameter CAL_S = 4'b0110;//CAL AB*C
parameter CAL_tr = 4'b0111;//Plus the trace
parameter OUT = 4'b1000;
parameter Wait = 4'b1001;
integer i,i0,i1,i2;
//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------
reg signed [49:0] tr;
reg [2:0] in2_cnt;
reg [9:0] buf_cnt,delay,delay2;
reg [8:0] cal_buf;
reg [4:0] cal_buf2;
//reg [3:0] out_cnt;
reg [12:0] address;
reg [3:0] num_of_ch;//times of in_valid2 being pulling up
reg [4:0] size;
reg [3:0] current_state,next_state;
reg signed [7:0] ma0 [0:3];
reg signed [7:0] mb0 [0:3];
reg signed [7:0] mc0 [0:3];
reg signed [7:0] ma1 [0:15];
reg signed [7:0] mb1 [0:15];
reg signed [7:0] mc1 [0:15];
reg signed [7:0] ma2 [0:63];
reg signed [7:0] mb2 [0:63];
reg signed [7:0] mc2 [0:63];
reg signed [7:0] ma3 [0:255];
reg signed [7:0] mb3 [0:255];
reg signed [7:0] mc3 [0:255];
reg signed [40:0] mf0[0:3];
reg signed [40:0] mf1[0:15];
reg signed [40:0] mf2[0:63];
reg signed [40:0] mf3[0:255];
reg [4:0] ma,mb,mc;
reg [1:0] mode1;
reg [7:0] buffer;
wire signed [7:0] data_out;
reg d_valid;
//---------------------------------------------------------------------
//   FSM
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) current_state<=IDLE;
    else current_state<=next_state;
end
always @(*) begin
    case(current_state)
        IDLE:begin
            if(in_valid) next_state = IN_DATA;
            else next_state = IDLE;
        end
        IN_DATA:begin
            if(~in_valid&&in_valid2) next_state = CHECK;
            else next_state = IN_DATA;
        end
        CHECK:begin
            if(~in_valid2) next_state = BUF;
            else next_state = CHECK;
        end
        BUF:begin
            if(buf_cnt==(3*size*size+1)) next_state = CAL_trans;
            else next_state = BUF;
        end
        CAL_trans:begin
            next_state = CAL_F;
        end
        CAL_F:begin
            if(cal_buf==size*size)next_state = CAL_S;
            else next_state = CAL_F;
        end
        CAL_S:begin
           if(cal_buf2==size) next_state = CAL_tr;
           else next_state = CAL_S;
        end
        CAL_tr:begin
            next_state = OUT;
        end
        OUT:begin
            if(num_of_ch==9) next_state = IDLE;
            else next_state = Wait;
        end
        Wait:begin
            if(in_valid2) next_state = CHECK;
            else next_state = Wait;
        end

        default:next_state = IDLE;
    endcase
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n) d_valid<=0;
    else  d_valid<=in_valid;
end
RA1SH M0(.Q(data_out),.CLK(clk),.CEN(1'b0),.WEN(!d_valid),.A(address),.D(buffer),.OEN(1'b0));
//RA1SH M0(.A(address),.D(matrix),.CLK(clk),.CEN(1'b0),.WEN(next_state==IN_DATA||current_state==IN_DATA),OEN(1'b0),.Q(data_out));
//---------------------------------------------------------------------
//   INPUT WEN==1 when next_st== IN_DATA||current_st==IN_DATA
//---------------------------------------------------------------------
//store size 
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) size <= 0;
    else if(in_valid && current_state==IDLE)  begin
        case(matrix_size)
            2'b00 : size <= 2;
            2'b01 : size <= 4;
            2'b10 : size <= 8;
            2'b11 : size <= 16;
        endcase
    end
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n) buffer<=0;
    else if(in_valid) buffer<=matrix;
end
/// A B C matrix address
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
         ma <= 0; 
         mb<=0; 
         mc<=0;
         end
    else if(in_valid2 && in2_cnt == 'd0)begin
         ma<=matrix_idx;
          mode1<=mode;  
          end     
    else if(in_valid2&&in2_cnt=='d1) mb<=matrix_idx;
    else if(in_valid2&&in2_cnt=='d2) mc<=matrix_idx;
end
//cnt 
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) buf_cnt<=0;
    else if(current_state==BUF) buf_cnt<=buf_cnt+1;
    else buf_cnt<=0;
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n) delay<=0;
    else if(current_state==BUF) delay<=buf_cnt;
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n) delay2<=0;
    else if(current_state==BUF||current_state==CAL_trans) delay2<=delay;
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n) in2_cnt<=0;
    //else if(current_state==Wait||current_state==IDLE) in2_cnt<=0;
    else if(in_valid2) in2_cnt<=in2_cnt+1;
    else if(current_state==Wait||current_state==IDLE||current_state==OUT) in2_cnt<=0;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        num_of_ch<=0;
    end
    else if(current_state==IN_DATA) num_of_ch<=0;
    else if((current_state==IN_DATA&&next_state==CHECK)||(current_state==Wait&&next_state==CHECK))
    num_of_ch<=num_of_ch+1;
    
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) cal_buf<=0;
    else if(current_state==CAL_F) cal_buf<=cal_buf+1;
    else if(current_state==IDLE) cal_buf<=0;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) cal_buf2<=0;
    else if(current_state==CAL_S) cal_buf2<=cal_buf2+1;
    else if(current_state==IDLE) cal_buf2<=0;
end
//address 
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) address<=0;
    else if(in_valid&&current_state==IN_DATA)begin
        address<=address+1;
    end
    
    else if(current_state==BUF)begin
        if(buf_cnt<((size*size)))begin
            address<=0+(size*size*ma)+buf_cnt;
        end
        else if((size*size)<=buf_cnt&&buf_cnt<(2*size*size))begin
            address<=0+size*size*mb+(buf_cnt-(size*size));
        end
        else if(buf_cnt>=(2*size*size)&&(buf_cnt<3*size*size))begin
            address<=0+size*size*mc+(buf_cnt-(2*size*size));
        end
    end
    else address<=0;
end

//---------------------------------------------------------------------
//   PRE CAL PART(put in to reg)
//---------------------------------------------------------------------
always@(posedge clk or negedge rst_n)begin
    if(!rst_n) begin
        for(i=0;i<4;i=i+1)begin
             ma0[i]<=0;
        end
    end
    else if(current_state==IDLE)begin
        for(i=0;i<4;i=i+1) ma0[i]<=0;
    end
    else if(next_state==BUF&&size==2&&delay2<4)begin
         ma0[delay2]<=data_out;
    end
    else if(next_state==CAL_trans&&mode1==2'b01&&size==2)begin
        ma0[0]<=ma0[0];
        ma0[1]<=ma0[2];
        ma0[2]<=ma0[1];
        ma0[3]<=ma0[3];
    end
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n) begin
        for(i=0;i<4;i=i+1)begin
             mb0[i]<=0;
        end
    end
    else if(current_state==IDLE)begin
        for(i=0;i<4;i=i+1) mb0[i]<=0;
    end
    else if(next_state==BUF&&size==2&&delay2>=4&&delay2<8)begin
         mb0[delay2-4]<=data_out;
    end
    else if(next_state==CAL_trans&&mode1==2'b10&&size==2)begin
        mb0[0]<=mb0[0];
        mb0[1]<=mb0[2];
        mb0[2]<=mb0[1];
        mb0[3]<=mb0[3];
    end
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n) begin
        for(i=0;i<4;i=i+1)begin
             mc0[i]<=0;
        end
    end
    else if(current_state==IDLE)begin
        for(i=0;i<4;i=i+1) mc0[i]<=0;
    end
    else if((next_state==BUF||current_state==BUF)&&size==2&&delay2<12&&delay2>=8)begin
         mc0[delay2-8]<=data_out;
    end
    else if((next_state==CAL_trans||current_state==CAL_trans)&&mode1==2'b11&&size==2)begin
        mc0[0]<=mc0[0];
        mc0[1]<=mc0[2];
        mc0[2]<=mc0[1];
        mc0[3]<=mc0[3];
    end
end



always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        for(i0=0;i0<16;i0=i0+1) ma1[i0]<=0;
    end
    else if(current_state==IDLE)begin
        for(i0=0;i0<16;i0=i0+1) ma1[i0]<=0;
    end
    else if(next_state==BUF&&size==4&&delay2<16)begin
        ma1[delay2]<=data_out;
    end
     else if(next_state==CAL_trans&&mode1==2'b01&&size==4)begin
        for(i=0;i<4;i=i+1)begin
            ma1[i]<=ma1[4*i];
            ma1[i+4]<=ma1[1+(4*i)];
            ma1[i+8]<=ma1[2+(4*i)];
            ma1[i+12]<=ma1[3+(4*i)];
            end
     end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        for(i0=0;i0<16;i0=i0+1) mb1[i0]<=0;
    end
    else if(current_state==IDLE)begin
        for(i0=0;i0<16;i0=i0+1) mb1[i0]<=0;
    end
    else if(next_state==BUF&&size==4&&delay2>=16&&delay2<32)begin
        mb1[delay2-16]<=data_out;
    end
     else if(next_state==CAL_trans&&mode1==2'b10&&size==4)begin
        for(i=0;i<4;i=i+1)begin
            mb1[i]<=mb1[4*i];
            mb1[i+4]<=mb1[1+(4*i)];
            mb1[i+8]<=mb1[2+(4*i)];
            mb1[i+12]<=mb1[3+(4*i)];
            end
     end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        for(i0=0;i0<16;i0=i0+1) mc1[i0]<=0;
    end
    else if(current_state==IDLE)begin
        for(i0=0;i0<16;i0=i0+1) mc1[i0]<=0;
    end
    else if((next_state==BUF||current_state==BUF)&&size==4&&delay2>=32&&delay2<=47)begin
        mc1[delay2-32]<=data_out;
    end
     else if((next_state==CAL_trans||current_state==CAL_trans)&&mode1==2'b11&&size==4)begin
        for(i=0;i<4;i=i+1)begin
            mc1[i]<=mc1[4*i];
            mc1[i+4]<=mc1[1+(4*i)];
            mc1[i+8]<=mc1[2+(4*i)];
            mc1[i+12]<=mc1[3+(4*i)];
            end
     end
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        for(i1=0;i1<64;i1=i1+1) ma2[i1]<=0;
    end
    else if(current_state==IDLE)begin
        for(i1=0;i1<64;i1=i1+1) ma2[i1]<=0;
    end
     else if(next_state==BUF&&size==8&&delay2<64)begin
         ma2[delay2]<=data_out;
     end
     else if(next_state==CAL_trans&&mode1==2'b01&&size==8)begin
         for(i=0;i<8;i=i+1)begin
                ma2[i]<=ma2[8*i];
                ma2[i+8]<=ma2[1+(8*i)];
                ma2[i+16]<=ma2[2+(8*i)];
                ma2[i+24]<=ma2[3+(8*i)];
                ma2[i+32]<=ma2[4+(8*i)];
                ma2[i+40]<=ma2[5+(8*i)];
                ma2[i+48]<=ma2[6+(8*i)];
                ma2[i+56]<=ma2[7+(8*i)];

            end
     end
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        for(i1=0;i1<64;i1=i1+1) mb2[i1]<=0;
    end
    else if(current_state==IDLE)begin
        for(i1=0;i1<64;i1=i1+1) mb2[i1]<=0;
    end
     else if(next_state==BUF&&size==8&&delay2>=64&&delay2<128)begin
         mb2[delay2-64]<=data_out;
     end
     else if(next_state==CAL_trans&&mode1==2'b10&&size==8)begin
         for(i=0;i<8;i=i+1)begin
                mb2[i]<=mb2[8*i];
                mb2[i+8]<=mb2[1+(8*i)];
                mb2[i+16]<=mb2[2+(8*i)];
                mb2[i+24]<=mb2[3+(8*i)];
                mb2[i+32]<=mb2[4+(8*i)];
                mb2[i+40]<=mb2[5+(8*i)];
                mb2[i+48]<=mb2[6+(8*i)];
                mb2[i+56]<=mb2[7+(8*i)];

            end
     end
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        for(i1=0;i1<64;i1=i1+1) mc2[i1]<=0;
    end
    else if(current_state==IDLE)begin
        for(i1=0;i1<64;i1=i1+1) mc2[i1]<=0;
    end
     else if((next_state==BUF||current_state==BUF)&&size==8&&delay2>=128&&delay2<192)begin
         mc2[delay2-128]<=data_out;
     end
     else if((next_state==CAL_trans||current_state==CAL_trans)&&mode1==2'b11&&size==8)begin
         for(i=0;i<8;i=i+1)begin
                mc2[i]<=mc2[8*i];
                mc2[i+8]<=mc2[1+(8*i)];
                mc2[i+16]<=mc2[2+(8*i)];
                mc2[i+24]<=mc2[3+(8*i)];
                mc2[i+32]<=mc2[4+(8*i)];
                mc2[i+40]<=mc2[5+(8*i)];
                mc2[i+48]<=mc2[6+(8*i)];
                mc2[i+56]<=mc2[7+(8*i)];

            end
     end
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        for(i2=0;i2<256;i2=i2+1) ma3[i2]<=0;
    end
    else if(current_state==IDLE)begin
        for(i2=0;i2<256;i2=i2+1) ma3[i2]<=0;  
    end
    else if(next_state==BUF&&size==16&&delay2<256)begin
        ma3[delay2]<=data_out;
    end
    else if(next_state==CAL_trans&&mode1==2'b01)begin
         for(i=0;i<16;i=i+1)begin
                ma3[i]<=ma3[16*i];
                ma3[i+16]<=ma3[1+(16*i)];
                ma3[i+32]<=ma3[2+(16*i)];
                ma3[i+48]<=ma3[3+(16*i)];
                ma3[i+64]<=ma3[4+(16*i)];
                ma3[i+80]<=ma3[5+(16*i)];
                ma3[i+96]<=ma3[6+(16*i)];
                ma3[i+112]<=ma3[7+(16*i)];
                ma3[i+128]<=ma3[8+(16*i)];
                ma3[i+144]<=ma3[9+(16*i)];
                ma3[i+160]<=ma3[10+(16*i)];
                ma3[i+176]<=ma3[11+(16*i)];
                ma3[i+192]<=ma3[12+(16*i)];
                ma3[i+208]<=ma3[13+(16*i)];
                ma3[i+224]<=ma3[14+(16*i)];
                ma3[i+240]<=ma3[15+(16*i)];
            end
    end
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        for(i2=0;i2<256;i2=i2+1) mb3[i2]<=0;
    end
    else if(current_state==IDLE)begin
        for(i2=0;i2<256;i2=i2+1) mb3[i2]<=0;  
    end
    else if(next_state==BUF&&size==16&&delay2>=256&&delay2<512)begin
        mb3[delay2-256]<=data_out;
    end
    else if(next_state==CAL_trans&&mode1==2'b10)begin
         for(i=0;i<16;i=i+1)begin
                mb3[i]<=mb3[16*i];
                mb3[i+16]<=mb3[1+(16*i)];
                mb3[i+32]<=mb3[2+(16*i)];
                mb3[i+48]<=mb3[3+(16*i)];
                mb3[i+64]<=mb3[4+(16*i)];
                mb3[i+80]<=mb3[5+(16*i)];
                mb3[i+96]<=mb3[6+(16*i)];
                mb3[i+112]<=mb3[7+(16*i)];
                mb3[i+128]<=mb3[8+(16*i)];
                mb3[i+144]<=mb3[9+(16*i)];
                mb3[i+160]<=mb3[10+(16*i)];
                mb3[i+176]<=mb3[11+(16*i)];
                mb3[i+192]<=mb3[12+(16*i)];
                mb3[i+208]<=mb3[13+(16*i)];
                mb3[i+224]<=mb3[14+(16*i)];
                mb3[i+240]<=mb3[15+(16*i)];
            end
    end
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        for(i2=0;i2<256;i2=i2+1) mc3[i2]<=0;
    end
    else if(current_state==IDLE)begin
        for(i2=0;i2<256;i2=i2+1) mc3[i2]<=0;  
    end
    else if((next_state==BUF||current_state==BUF)&&size==16&&delay2>=512&&delay2<768)begin
        mc3[delay2-512]<=data_out;
    end
    else if((next_state==CAL_trans||current_state==CAL_trans)&&mode1==2'b11)begin
         for(i=0;i<16;i=i+1)begin
                mc3[i]<=mc3[16*i];
                mc3[i+16]<=mc3[1+(16*i)];
                mc3[i+32]<=mc3[2+(16*i)];
                mc3[i+48]<=mc3[3+(16*i)];
                mc3[i+64]<=mc3[4+(16*i)];
                mc3[i+80]<=mc3[5+(16*i)];
                mc3[i+96]<=mc3[6+(16*i)];
                mc3[i+112]<=mc3[7+(16*i)];
                mc3[i+128]<=mc3[8+(16*i)];
                mc3[i+144]<=mc3[9+(16*i)];
                mc3[i+160]<=mc3[10+(16*i)];
                mc3[i+176]<=mc3[11+(16*i)];
                mc3[i+192]<=mc3[12+(16*i)];
                mc3[i+208]<=mc3[13+(16*i)];
                mc3[i+224]<=mc3[14+(16*i)];
                mc3[i+240]<=mc3[15+(16*i)];
            end
    end
end
//---------------------------------------------------------------------
//   CAL PART
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        for(i=0;i<4;i=i+1)begin
            mf0[i]<=0;
        end
        for(i0=0;i0<16;i0=i0+1)begin
            mf1[i0]<=0;
        end
        for(i1=0;i1<64;i1=i1+1)begin
            mf2[i1]<=0;
        end
        for(i2=0;i2<256;i2=i2+1)begin
            mf3[i2]<=0;
        end
    end
    else if(current_state==IDLE)begin
        for(i=0;i<4;i=i+1)begin
            mf0[i]<=0;
        end
        for(i0=0;i0<16;i0=i0+1)begin
            mf1[i0]<=0;
        end
        for(i1=0;i1<64;i1=i1+1)begin
            mf2[i1]<=0;
        end
        for(i2=0;i2<256;i2=i2+1)begin
            mf3[i2]<=0;
        end
    end
    else if(current_state==CAL_F)begin
        case(size)
        2:begin
            if(cal_buf<2) mf0[cal_buf]<=ma0[0]*mb0[cal_buf]+ma0[1]*mb0[cal_buf+2];
            if(cal_buf>=2&&cal_buf<4) mf0[cal_buf]<=ma0[2]*mb0[cal_buf-2]+ma0[3]*mb0[cal_buf];
        end
        4:begin
            if(cal_buf<4) mf1[cal_buf]<=ma1[0]*mb1[cal_buf]+ma1[1]*mb1[cal_buf+4]+ma1[2]*mb1[cal_buf+8]+ma1[3]*mb1[cal_buf+12];
            if(cal_buf>=4&&cal_buf<8) mf1[cal_buf]<=ma1[4]*mb1[cal_buf-4]+ma1[5]*mb1[cal_buf]+ma1[6]*mb1[cal_buf+4]+ma1[7]*mb1[cal_buf+8];
            if(cal_buf>=8&&cal_buf<12) mf1[cal_buf]<=ma1[8]*mb1[cal_buf-8]+ma1[9]*mb1[cal_buf-4]+ma1[10]*mb1[cal_buf]+ma1[11]*mb1[cal_buf+4];
            if(cal_buf>=12&&cal_buf<16) mf1[cal_buf]<=ma1[12]*mb1[cal_buf-12]+ma1[13]*mb1[cal_buf-8]+ma1[14]*mb1[cal_buf-4]+ma1[15]*mb1[cal_buf];
        end
        8:begin
            if(cal_buf<8) mf2[cal_buf]<=ma2[0]*mb2[cal_buf]+ma2[1]*mb2[cal_buf+8]+ma2[2]*mb2[cal_buf+16]+ma2[3]*mb2[cal_buf+24]+ma2[4]*mb2[cal_buf+32]+ma2[5]*mb2[cal_buf+40]+ma2[6]*mb2[cal_buf+48]+ma2[7]*mb2[cal_buf+56];
            if(cal_buf>=8&&cal_buf<16) mf2[cal_buf]<=ma2[8]*mb2[cal_buf-8]+ma2[9]*mb2[cal_buf]+ma2[10]*mb2[cal_buf+8]+ma2[11]*mb2[cal_buf+16]+ma2[12]*mb2[cal_buf+24]+ma2[13]*mb2[cal_buf+32]+ma2[14]*mb2[cal_buf+40]+ma2[15]*mb2[cal_buf+48];
            if(cal_buf>=16&&cal_buf<24) mf2[cal_buf]<=ma2[16]*mb2[cal_buf-16]+ma2[17]*mb2[cal_buf-8]+ma2[18]*mb2[cal_buf]+ma2[19]*mb2[cal_buf+8]+ma2[20]*mb2[cal_buf+16]+ma2[21]*mb2[cal_buf+24]+ma2[22]*mb2[cal_buf+32]+ma2[23]*mb2[cal_buf+40];
            if(cal_buf>=24&&cal_buf<32) mf2[cal_buf]<=ma2[24]*mb2[cal_buf-24]+ma2[25]*mb2[cal_buf-16]+ma2[26]*mb2[cal_buf-8]+ma2[27]*mb2[cal_buf]+ma2[28]*mb2[cal_buf+8]+ma2[29]*mb2[cal_buf+16]+ma2[30]*mb2[cal_buf+24]+ma2[31]*mb2[cal_buf+32];
            if(cal_buf>=32&&cal_buf<40) mf2[cal_buf]<=ma2[32]*mb2[cal_buf-32]+ma2[33]*mb2[cal_buf-24]+ma2[34]*mb2[cal_buf-16]+ma2[35]*mb2[cal_buf-8]+ma2[36]*mb2[cal_buf]+ma2[37]*mb2[cal_buf+8]+ma2[38]*mb2[cal_buf+16]+ma2[39]*mb2[cal_buf+24];
            if(cal_buf>=40&&cal_buf<48) mf2[cal_buf]<=ma2[40]*mb2[cal_buf-40]+ma2[41]*mb2[cal_buf-32]+ma2[42]*mb2[cal_buf-24]+ma2[43]*mb2[cal_buf-16]+ma2[44]*mb2[cal_buf-8]+ma2[45]*mb2[cal_buf]+ma2[46]*mb2[cal_buf+8]+ma2[47]*mb2[cal_buf+16];
            if(cal_buf>=48&&cal_buf<56) mf2[cal_buf]<=ma2[48]*mb2[cal_buf-48]+ma2[49]*mb2[cal_buf-40]+ma2[50]*mb2[cal_buf-32]+ma2[51]*mb2[cal_buf-24]+ma2[52]*mb2[cal_buf-16]+ma2[53]*mb2[cal_buf-8]+ma2[54]*mb2[cal_buf]+ma2[55]*mb2[cal_buf+8];
            if(cal_buf>=56&&cal_buf<64) mf2[cal_buf]<=ma2[56]*mb2[cal_buf-56]+ma2[57]*mb2[cal_buf-48]+ma2[58]*mb2[cal_buf-40]+ma2[59]*mb2[cal_buf-32]+ma2[60]*mb2[cal_buf-24]+ma2[61]*mb2[cal_buf-16]+ma2[62]*mb2[cal_buf-8]+ma2[63]*mb2[cal_buf];
        end
        16:begin
            if(cal_buf<16) mf3[cal_buf]<=ma3[0]*mb3[cal_buf]+ma3[1]*mb3[cal_buf+16]+ma3[2]*mb3[cal_buf+32]+ma3[3]*mb3[cal_buf+48]+ma3[4]*mb3[cal_buf+64]+ma3[5]*mb3[cal_buf+80]+ma3[6]*mb3[cal_buf+96]+ma3[7]*mb3[cal_buf+112]+ma3[8]*mb3[cal_buf+128]+ma3[9]*mb3[cal_buf+144]+ma3[10]*mb3[cal_buf+160]+ma3[11]*mb3[cal_buf+176]+ma3[12]*mb3[cal_buf+192]+ma3[13]*mb3[cal_buf+208]+ma3[14]*mb3[cal_buf+224]+ma3[15]*mb3[cal_buf+240];
            if(cal_buf>=16&&cal_buf<32) mf3[cal_buf]<=ma3[16]*mb3[cal_buf-16]+ma3[17]*mb3[cal_buf]+ma3[18]*mb3[cal_buf+16]+ma3[19]*mb3[cal_buf+32]+ma3[20]*mb3[cal_buf+48]+ma3[21]*mb3[cal_buf+64]+ma3[22]*mb3[cal_buf+80]+ma3[23]*mb3[cal_buf+96]+ma3[24]*mb3[cal_buf+112]+ma3[25]*mb3[cal_buf+128]+ma3[26]*mb3[cal_buf+144]+ma3[27]*mb3[cal_buf+160]+ma3[28]*mb3[cal_buf+176]+ma3[29]*mb3[cal_buf+192]+ma3[30]*mb3[cal_buf+208]+ma3[31]*mb3[cal_buf+224];
            if(cal_buf>=32&&cal_buf<48) mf3[cal_buf]<=ma3[32]*mb3[cal_buf-32]+ma3[33]*mb3[cal_buf-16]+ma3[34]*mb3[cal_buf]+ma3[35]*mb3[cal_buf+16]+ma3[36]*mb3[cal_buf+32]+ma3[37]*mb3[cal_buf+48]+ma3[38]*mb3[cal_buf+64]+ma3[39]*mb3[cal_buf+80]+ma3[40]*mb3[cal_buf+96]+ma3[41]*mb3[cal_buf+112]+ma3[42]*mb3[cal_buf+128]+ma3[43]*mb3[cal_buf+144]+ma3[44]*mb3[cal_buf+160]+ma3[45]*mb3[cal_buf+176]+ma3[46]*mb3[cal_buf+192]+ma3[47]*mb3[cal_buf+208];
            if(cal_buf>=48&&cal_buf<64) mf3[cal_buf]<=ma3[48]*mb3[cal_buf-48]+ma3[49]*mb3[cal_buf-32]+ma3[50]*mb3[cal_buf-16]+ma3[51]*mb3[cal_buf]+ma3[52]*mb3[cal_buf+16]+ma3[53]*mb3[cal_buf+32]+ma3[54]*mb3[cal_buf+48]+ma3[55]*mb3[cal_buf+64]+ma3[56]*mb3[cal_buf+80]+ma3[57]*mb3[cal_buf+96]+ma3[58]*mb3[cal_buf+112]+ma3[59]*mb3[cal_buf+128]+ma3[60]*mb3[cal_buf+144]+ma3[61]*mb3[cal_buf+160]+ma3[62]*mb3[cal_buf+176]+ma3[63]*mb3[cal_buf+192];
            if(cal_buf>=64&&cal_buf<80) mf3[cal_buf]<=ma3[64]*mb3[cal_buf-64]+ma3[65]*mb3[cal_buf-48]+ma3[66]*mb3[cal_buf-32]+ma3[67]*mb3[cal_buf-16]+ma3[68]*mb3[cal_buf]+ma3[69]*mb3[cal_buf+16]+ma3[70]*mb3[cal_buf+32]+ma3[71]*mb3[cal_buf+48]+ma3[72]*mb3[cal_buf+64]+ma3[73]*mb3[cal_buf+80]+ma3[74]*mb3[cal_buf+96]+ma3[75]*mb3[cal_buf+112]+ma3[76]*mb3[cal_buf+128]+ma3[77]*mb3[cal_buf+144]+ma3[78]*mb3[cal_buf+160]+ma3[79]*mb3[cal_buf+176];
            if(cal_buf>=80&&cal_buf<96) mf3[cal_buf]<=ma3[80]*mb3[cal_buf-80]+ma3[81]*mb3[cal_buf-64]+ma3[82]*mb3[cal_buf-48]+ma3[83]*mb3[cal_buf-32]+ma3[84]*mb3[cal_buf-16]+ma3[85]*mb3[cal_buf]+ma3[86]*mb3[cal_buf+16]+ma3[87]*mb3[cal_buf+32]+ma3[88]*mb3[cal_buf+48]+ma3[89]*mb3[cal_buf+64]+ma3[90]*mb3[cal_buf+80]+ma3[91]*mb3[cal_buf+96]+ma3[92]*mb3[cal_buf+112]+ma3[93]*mb3[cal_buf+128]+ma3[94]*mb3[cal_buf+144]+ma3[95]*mb3[cal_buf+160];
            if(cal_buf>=96&&cal_buf<112) mf3[cal_buf]<=ma3[96]*mb3[cal_buf-96]+ma3[97]*mb3[cal_buf-80]+ma3[98]*mb3[cal_buf-64]+ma3[99]*mb3[cal_buf-48]+ma3[100]*mb3[cal_buf-32]+ma3[101]*mb3[cal_buf-16]+ma3[102]*mb3[cal_buf]+ma3[103]*mb3[cal_buf+16]+ma3[104]*mb3[cal_buf+32]+ma3[105]*mb3[cal_buf+48]+ma3[106]*mb3[cal_buf+64]+ma3[107]*mb3[cal_buf+80]+ma3[108]*mb3[cal_buf+96]+ma3[109]*mb3[cal_buf+112]+ma3[110]*mb3[cal_buf+128]+ma3[111]*mb3[cal_buf+144];
            if(cal_buf>=112&&cal_buf<128) mf3[cal_buf]<=ma3[112]*mb3[cal_buf-112]+ma3[113]*mb3[cal_buf-96]+ma3[114]*mb3[cal_buf-80]+ma3[115]*mb3[cal_buf-64]+ma3[116]*mb3[cal_buf-48]+ma3[117]*mb3[cal_buf-32]+ma3[118]*mb3[cal_buf-16]+ma3[119]*mb3[cal_buf]+ma3[120]*mb3[cal_buf+16]+ma3[121]*mb3[cal_buf+32]+ma3[122]*mb3[cal_buf+48]+ma3[123]*mb3[cal_buf+64]+ma3[124]*mb3[cal_buf+80]+ma3[125]*mb3[cal_buf+96]+ma3[126]*mb3[cal_buf+112]+ma3[127]*mb3[cal_buf+128];
            if(cal_buf>=128&&cal_buf<144) mf3[cal_buf]<=ma3[128]*mb3[cal_buf-128]+ma3[129]*mb3[cal_buf-112]+ma3[130]*mb3[cal_buf-96]+ma3[131]*mb3[cal_buf-80]+ma3[132]*mb3[cal_buf-64]+ma3[133]*mb3[cal_buf-48]+ma3[134]*mb3[cal_buf-32]+ma3[135]*mb3[cal_buf-16]+ma3[136]*mb3[cal_buf]+ma3[137]*mb3[cal_buf+16]+ma3[138]*mb3[cal_buf+32]+ma3[139]*mb3[cal_buf+48]+ma3[140]*mb3[cal_buf+64]+ma3[141]*mb3[cal_buf+80]+ma3[142]*mb3[cal_buf+96]+ma3[143]*mb3[cal_buf+112];
            if(cal_buf>=144&&cal_buf<160) mf3[cal_buf]<=ma3[144]*mb3[cal_buf-144]+ma3[145]*mb3[cal_buf-128]+ma3[146]*mb3[cal_buf-112]+ma3[147]*mb3[cal_buf-96]+ma3[148]*mb3[cal_buf-80]+ma3[149]*mb3[cal_buf-64]+ma3[150]*mb3[cal_buf-48]+ma3[151]*mb3[cal_buf-32]+ma3[152]*mb3[cal_buf-16]+ma3[153]*mb3[cal_buf]+ma3[154]*mb3[cal_buf+16]+ma3[155]*mb3[cal_buf+32]+ma3[156]*mb3[cal_buf+48]+ma3[157]*mb3[cal_buf+64]+ma3[158]*mb3[cal_buf+80]+ma3[159]*mb3[cal_buf+96];
            if(cal_buf>=160&&cal_buf<176) mf3[cal_buf]<=ma3[160]*mb3[cal_buf-160]+ma3[161]*mb3[cal_buf-144]+ma3[162]*mb3[cal_buf-128]+ma3[163]*mb3[cal_buf-112]+ma3[164]*mb3[cal_buf-96]+ma3[165]*mb3[cal_buf-80]+ma3[166]*mb3[cal_buf-64]+ma3[167]*mb3[cal_buf-48]+ma3[168]*mb3[cal_buf-32]+ma3[169]*mb3[cal_buf-16]+ma3[170]*mb3[cal_buf]+ma3[171]*mb3[cal_buf+16]+ma3[172]*mb3[cal_buf+32]+ma3[173]*mb3[cal_buf+48]+ma3[174]*mb3[cal_buf+64]+ma3[175]*mb3[cal_buf+80];
            if(cal_buf>=176&&cal_buf<192) mf3[cal_buf]<=ma3[176]*mb3[cal_buf-176]+ma3[177]*mb3[cal_buf-160]+ma3[178]*mb3[cal_buf-144]+ma3[179]*mb3[cal_buf-128]+ma3[180]*mb3[cal_buf-112]+ma3[181]*mb3[cal_buf-96]+ma3[182]*mb3[cal_buf-80]+ma3[183]*mb3[cal_buf-64]+ma3[184]*mb3[cal_buf-48]+ma3[185]*mb3[cal_buf-32]+ma3[186]*mb3[cal_buf-16]+ma3[187]*mb3[cal_buf]+ma3[188]*mb3[cal_buf+16]+ma3[189]*mb3[cal_buf+32]+ma3[190]*mb3[cal_buf+48]+ma3[191]*mb3[cal_buf+64];
            if(cal_buf>=192&&cal_buf<208) mf3[cal_buf]<=ma3[192]*mb3[cal_buf-192]+ma3[193]*mb3[cal_buf-176]+ma3[194]*mb3[cal_buf-160]+ma3[195]*mb3[cal_buf-144]+ma3[196]*mb3[cal_buf-128]+ma3[197]*mb3[cal_buf-112]+ma3[198]*mb3[cal_buf-96]+ma3[199]*mb3[cal_buf-80]+ma3[200]*mb3[cal_buf-64]+ma3[201]*mb3[cal_buf-48]+ma3[202]*mb3[cal_buf-32]+ma3[203]*mb3[cal_buf-16]+ma3[204]*mb3[cal_buf]+ma3[205]*mb3[cal_buf+16]+ma3[206]*mb3[cal_buf+32]+ma3[207]*mb3[cal_buf+48];
            if(cal_buf>=208&&cal_buf<224) mf3[cal_buf]<=ma3[208]*mb3[cal_buf-208]+ma3[209]*mb3[cal_buf-192]+ma3[210]*mb3[cal_buf-176]+ma3[211]*mb3[cal_buf-160]+ma3[212]*mb3[cal_buf-144]+ma3[213]*mb3[cal_buf-128]+ma3[214]*mb3[cal_buf-112]+ma3[215]*mb3[cal_buf-96]+ma3[216]*mb3[cal_buf-80]+ma3[217]*mb3[cal_buf-64]+ma3[218]*mb3[cal_buf-48]+ma3[219]*mb3[cal_buf-32]+ma3[220]*mb3[cal_buf-16]+ma3[221]*mb3[cal_buf]+ma3[222]*mb3[cal_buf+16]+ma3[223]*mb3[cal_buf+32];
            if(cal_buf>=224&&cal_buf<240) mf3[cal_buf]<=ma3[224]*mb3[cal_buf-224]+ma3[225]*mb3[cal_buf-208]+ma3[226]*mb3[cal_buf-192]+ma3[227]*mb3[cal_buf-176]+ma3[228]*mb3[cal_buf-160]+ma3[229]*mb3[cal_buf-144]+ma3[230]*mb3[cal_buf-128]+ma3[231]*mb3[cal_buf-112]+ma3[232]*mb3[cal_buf-96]+ma3[233]*mb3[cal_buf-80]+ma3[234]*mb3[cal_buf-64]+ma3[235]*mb3[cal_buf-48]+ma3[236]*mb3[cal_buf-32]+ma3[237]*mb3[cal_buf-16]+ma3[238]*mb3[cal_buf]+ma3[239]*mb3[cal_buf+16];
            if(cal_buf>=240&&cal_buf<256) mf3[cal_buf]<=ma3[240]*mb3[cal_buf-240]+ma3[241]*mb3[cal_buf-224]+ma3[242]*mb3[cal_buf-208]+ma3[243]*mb3[cal_buf-192]+ma3[244]*mb3[cal_buf-176]+ma3[245]*mb3[cal_buf-160]+ma3[246]*mb3[cal_buf-144]+ma3[247]*mb3[cal_buf-128]+ma3[248]*mb3[cal_buf-112]+ma3[249]*mb3[cal_buf-96]+ma3[250]*mb3[cal_buf-80]+ma3[251]*mb3[cal_buf-64]+ma3[252]*mb3[cal_buf-48]+ma3[253]*mb3[cal_buf-32]+ma3[254]*mb3[cal_buf-16]+ma3[255]*mb3[cal_buf];
        end
        endcase
    end
    else if(next_state==CAL_S)begin
        case(size)
        2:begin
           /* mf0[0]<=mf0[0]*mc0[0]+mf0[1]*mc0[2];
            mf0[1]<=mf0[0]*mc0[1]+mf0[1]*mc0[3];
            mf0[2]<=mf0[2]*mc0[0]+mf0[3]*mc0[2];
            mf0[3]<=mf0[2]*mc0[1]+mf0[3]*mc0[3];*/
            mf0[cal_buf2*3]<=mf0[2*cal_buf2]*mc0[cal_buf2]+mf0[2*cal_buf2+1]*mc0[cal_buf2+2];
        end
        4:begin
        /*for(i=0;i<4;i=i+1)begin
            mf1[i]<=mf1[0]*mc1[i]+mf1[1]*mc1[i+4]+mf1[2]*mc1[i+8]+mf1[3]*mc1[i+12];
            mf1[i+4]<=mf1[4]*mc1[i]+mf1[5]*mc1[i+4]+mf1[6]*mc1[i+8]+mf1[7]*mc1[i+12];
            mf1[i+8]<=mf1[8]*mc1[i]+mf1[9]*mc1[i+4]+mf1[10]*mc1[i+8]+mf1[11]*mc1[i+12];
            mf1[i+12]<=mf1[12]*mc1[i]+mf1[13]*mc1[i+4]+mf1[14]*mc1[i+8]+mf1[15]*mc1[i+12];
        end*/
        mf1[cal_buf2*5]<=mf1[4*cal_buf2]*mc1[cal_buf2]+mf1[4*cal_buf2+1]*mc1[cal_buf2+4]+mf1[4*cal_buf2+2]*mc1[cal_buf2+8]+mf1[4*cal_buf2+3]*mc1[cal_buf2+12];
        end
        8:begin
        /*for(i=0;i<8;i=i+1)begin
            mf2[i]<=mf2[0]*mc2[i]+mf2[1]*mc2[i+8]+mf2[2]*mc2[i+16]+mf2[3]*mc2[i+24]+mf2[4]*mc2[i+32]+mf2[5]*mc2[i+40]+mf2[6]*mc2[i+48]+mc2[7]*mc2[i+56];
            mf2[i+8]<=mf2[8]*mc2[i]+mf2[9]*mc2[i+8]+mf2[10]*mc2[i+16]+mf2[11]*mc2[i+24]+mf2[12]*mc2[i+32]+mf2[13]*mc2[i+40]+mf2[14]*mc2[i+48]+mc2[15]*mc2[i+56];
            mf2[i+16]<=mf2[16]*mc2[i]+mf2[17]*mc2[i+8]+mf2[18]*mc2[i+16]+mf2[19]*mc2[i+24]+mf2[20]*mc2[i+32]+mf2[21]*mc2[i+40]+mf2[22]*mc2[i+48]+mc2[23]*mc2[i+56];
            mf2[i+24]<=mf2[24]*mc2[i]+mf2[25]*mc2[i+8]+mf2[26]*mc2[i+16]+mf2[27]*mc2[i+24]+mf2[28]*mc2[i+32]+mf2[29]*mc2[i+40]+mf2[30]*mc2[i+48]+mc2[32]*mc2[i+56];
            mf2[i+32]<=mf2[32]*mc2[i]+mf2[33]*mc2[i+8]+mf2[34]*mc2[i+16]+mf2[35]*mc2[i+24]+mf2[36]*mc2[i+32]+mf2[37]*mc2[i+40]+mf2[38]*mc2[i+48]+mc2[39]*mc2[i+56];
            mf2[i+40]<=mf2[40]*mc2[i]+mf2[41]*mc2[i+8]+mf2[42]*mc2[i+16]+mf2[43]*mc2[i+24]+mf2[44]*mc2[i+32]+mf2[45]*mc2[i+40]+mf2[46]*mc2[i+48]+mc2[47]*mc2[i+56];
            mf2[i+48]<=mf2[48]*mc2[i]+mf2[49]*mc2[i+8]+mf2[50]*mc2[i+16]+mf2[51]*mc2[i+24]+mf2[52]*mc2[i+32]+mf2[53]*mc2[i+40]+mf2[54]*mc2[i+48]+mc2[55]*mc2[i+56];
            mf2[i+56]<=mf2[56]*mc2[i]+mf2[57]*mc2[i+8]+mf2[58]*mc2[i+16]+mf2[59]*mc2[i+24]+mf2[60]*mc2[i+32]+mf2[61]*mc2[i+40]+mf2[62]*mc2[i+48]+mc2[63]*mc2[i+56];
        end*/
        mf2[cal_buf2*9]<=mf2[8*cal_buf2]*mc2[cal_buf2]+mf2[8*cal_buf2+1]*mc2[cal_buf2+8]+mf2[8*cal_buf2+2]*mc2[cal_buf2+16]+mf2[8*cal_buf2+3]*mc2[cal_buf2+24]+mf2[8*cal_buf2+4]*mc2[cal_buf2+32]+mf2[8*cal_buf2+5]*mc2[cal_buf2+40]+mf2[8*cal_buf2+6]*mc2[cal_buf2+48]+mf2[8*cal_buf2+7]*mc2[cal_buf2+56];
        end
        16:begin
            mf3[cal_buf2*17]<=mf3[16*cal_buf2]*mc3[cal_buf2]+mf3[16*cal_buf2+1]*mc3[cal_buf2+16]+mf3[16*cal_buf2+2]*mc3[cal_buf2+32]+mf3[16*cal_buf2+3]*mc3[cal_buf2+48]+mf3[16*cal_buf2+4]*mc3[cal_buf2+64]+mf3[16*cal_buf2+5]*mc3[cal_buf2+80]+mf3[16*cal_buf2+6]*mc3[cal_buf2+96]+mf3[16*cal_buf2+7]*mc3[cal_buf2+112]+mf3[16*cal_buf2+8]*mc3[cal_buf2+128]+mf3[16*cal_buf2+9]*mc3[cal_buf2+144]+mf3[16*cal_buf2+10]*mc3[cal_buf2+160]+mf3[16*cal_buf2+11]*mc3[cal_buf2+176]+mf3[16*cal_buf2+12]*mc3[cal_buf2+192]+mf3[16*cal_buf2+13]*mc3[cal_buf2+208]+mf3[16*cal_buf2+14]*mc3[cal_buf2+224]+mf3[16*cal_buf2+15]*mc3[cal_buf2+240];
           /* for(i=0;i<16;i=i+1)begin
                mf3[i]<=mf3[0]*mc3[i]+mf3[1]*mc3[i+16]+mf3[2]*mc3[i+32]+mf3[3]*mc3[i+48]+mf3[4]*mc3[i+64]+mf3[5]*mc3[i+80]+mf3[6]*mc3[i+96]+mf3[7]*mc3[i+112]+mf3[8]*mc3[i+128]+mf3[9]*mc3[i+144]+mf3[10]*mc3[i+160]+mf3[11]*mc3[i+176]+mf3[12]*mc3[i+192]+mf3[13]*mc3[i+208]+mf3[14]*mc3[i+224]+mf3[15]*mc3[i+240];
                mf3[i+16]<=mf3[16]*mc3[i]+mf3[17]*mc3[i+16]+mf3[18]*mc3[i+32]+mf3[19]*mc3[i+48]+mf3[20]*mc3[i+64]+mf3[21]*mc3[i+80]+mf3[22]*mc3[i+96]+mf3[23]*mc3[i+112]+mf3[24]*mc3[i+128]+mf3[25]*mc3[i+144]+mf3[26]*mc3[i+160]+mf3[27]*mc3[i+176]+mf3[28]*mc3[i+192]+mf3[29]*mc3[i+208]+mf3[30]*mc3[i+224]+mf3[31]*mc3[i+240];
                mf3[i+32]<=mf3[32]*mc3[i]+mf3[33]*mc3[i+16]+mf3[34]*mc3[i+32]+mf3[35]*mc3[i+48]+mf3[36]*mc3[i+64]+mf3[37]*mc3[i+80]+mf3[38]*mc3[i+96]+mf3[39]*mc3[i+112]+mf3[40]*mc3[i+128]+mf3[41]*mc3[i+144]+mf3[42]*mc3[i+160]+mf3[43]*mc3[i+176]+mf3[44]*mc3[i+192]+mf3[45]*mc3[i+208]+mf3[46]*mc3[i+224]+mf3[47]*mc3[i+240];
                mf3[i+48]<=mf3[48]*mc3[i]+mf3[49]*mc3[i+16]+mf3[50]*mc3[i+32]+mf3[51]*mc3[i+48]+mf3[52]*mc3[i+64]+mf3[53]*mc3[i+80]+mf3[54]*mc3[i+96]+mf3[55]*mc3[i+112]+mf3[56]*mc3[i+128]+mf3[57]*mc3[i+144]+mf3[58]*mc3[i+160]+mf3[59]*mc3[i+176]+mf3[60]*mc3[i+192]+mf3[61]*mc3[i+208]+mf3[62]*mc3[i+224]+mf3[63]*mc3[i+240];
                mf3[i+64]<=mf3[64]*mc3[i]+mf3[65]*mc3[i+16]+mf3[66]*mc3[i+32]+mf3[67]*mc3[i+48]+mf3[68]*mc3[i+64]+mf3[69]*mc3[i+80]+mf3[70]*mc3[i+96]+mf3[71]*mc3[i+112]+mf3[72]*mc3[i+128]+mf3[73]*mc3[i+144]+mf3[74]*mc3[i+160]+mf3[75]*mc3[i+176]+mf3[76]*mc3[i+192]+mf3[77]*mc3[i+208]+mf3[78]*mc3[i+224]+mf3[79]*mc3[i+240];
                mf3[i+80]<=mf3[80]*mc3[i]+mf3[81]*mc3[i+16]+mf3[82]*mc3[i+32]+mf3[83]*mc3[i+48]+mf3[84]*mc3[i+64]+mf3[85]*mc3[i+80]+mf3[86]*mc3[i+96]+mf3[87]*mc3[i+112]+mf3[88]*mc3[i+128]+mf3[89]*mc3[i+144]+mf3[90]*mc3[i+160]+mf3[91]*mc3[i+176]+mf3[92]*mc3[i+192]+mf3[93]*mc3[i+208]+mf3[94]*mc3[i+224]+mf3[95]*mc3[i+240];
                mf3[i+96]<=mf3[96]*mc3[i]+mf3[97]*mc3[i+16]+mf3[98]*mc3[i+32]+mf3[99]*mc3[i+48]+mf3[100]*mc3[i+64]+mf3[101]*mc3[i+80]+mf3[102]*mc3[i+96]+mf3[103]*mc3[i+112]+mf3[104]*mc3[i+128]+mf3[105]*mc3[i+144]+mf3[106]*mc3[i+160]+mf3[107]*mc3[i+176]+mf3[108]*mc3[i+192]+mf3[109]*mc3[i+208]+mf3[110]*mc3[i+224]+mf3[111]*mc3[i+240];
                mf3[i+112]<=mf3[112]*mc3[i]+mf3[113]*mc3[i+16]+mf3[114]*mc3[i+32]+mf3[115]*mc3[i+48]+mf3[116]*mc3[i+64]+mf3[117]*mc3[i+80]+mf3[118]*mc3[i+96]+mf3[119]*mc3[i+112]+mf3[120]*mc3[i+128]+mf3[121]*mc3[i+144]+mf3[122]*mc3[i+160]+mf3[123]*mc3[i+176]+mf3[124]*mc3[i+192]+mf3[125]*mc3[i+208]+mf3[126]*mc3[i+224]+mf3[127]*mc3[i+240];
                mf3[i+128]<=mf3[128]*mc3[i]+mf3[129]*mc3[i+16]+mf3[130]*mc3[i+32]+mf3[131]*mc3[i+48]+mf3[132]*mc3[i+64]+mf3[133]*mc3[i+80]+mf3[134]*mc3[i+96]+mf3[135]*mc3[i+112]+mf3[136]*mc3[i+128]+mf3[137]*mc3[i+144]+mf3[138]*mc3[i+160]+mf3[139]*mc3[i+176]+mf3[140]*mc3[i+192]+mf3[141]*mc3[i+208]+mf3[142]*mc3[i+224]+mf3[143]*mc3[i+240];
                mf3[i+144]<=mf3[144]*mc3[i]+mf3[145]*mc3[i+16]+mf3[146]*mc3[i+32]+mf3[147]*mc3[i+48]+mf3[148]*mc3[i+64]+mf3[149]*mc3[i+80]+mf3[150]*mc3[i+96]+mf3[151]*mc3[i+112]+mf3[152]*mc3[i+128]+mf3[153]*mc3[i+144]+mf3[154]*mc3[i+160]+mf3[155]*mc3[i+176]+mf3[156]*mc3[i+192]+mf3[157]*mc3[i+208]+mf3[158]*mc3[i+224]+mf3[159]*mc3[i+240];
                mf3[i+160]<=mf3[160]*mc3[i]+mf3[161]*mc3[i+16]+mf3[162]*mc3[i+32]+mf3[163]*mc3[i+48]+mf3[164]*mc3[i+64]+mf3[165]*mc3[i+80]+mf3[166]*mc3[i+96]+mf3[167]*mc3[i+112]+mf3[168]*mc3[i+128]+mf3[169]*mc3[i+144]+mf3[170]*mc3[i+160]+mf3[171]*mc3[i+176]+mf3[172]*mc3[i+192]+mf3[173]*mc3[i+208]+mf3[174]*mc3[i+224]+mf3[175]*mc3[i+240];
                mf3[i+176]<=mf3[176]*mc3[i]+mf3[177]*mc3[i+16]+mf3[178]*mc3[i+32]+mf3[179]*mc3[i+48]+mf3[180]*mc3[i+64]+mf3[181]*mc3[i+80]+mf3[182]*mc3[i+96]+mf3[183]*mc3[i+112]+mf3[184]*mc3[i+128]+mf3[185]*mc3[i+144]+mf3[186]*mc3[i+160]+mf3[187]*mc3[i+176]+mf3[188]*mc3[i+192]+mf3[189]*mc3[i+208]+mf3[190]*mc3[i+224]+mf3[191]*mc3[i+240];
                mf3[i+192]<=mf3[192]*mc3[i]+mf3[193]*mc3[i+16]+mf3[194]*mc3[i+32]+mf3[195]*mc3[i+48]+mf3[196]*mc3[i+64]+mf3[197]*mc3[i+80]+mf3[198]*mc3[i+96]+mf3[199]*mc3[i+112]+mf3[200]*mc3[i+128]+mf3[201]*mc3[i+144]+mf3[202]*mc3[i+160]+mf3[203]*mc3[i+176]+mf3[204]*mc3[i+192]+mf3[205]*mc3[i+208]+mf3[206]*mc3[i+224]+mf3[207]*mc3[i+240];
                mf3[i+208]<=mf3[208]*mc3[i]+mf3[209]*mc3[i+16]+mf3[210]*mc3[i+32]+mf3[211]*mc3[i+48]+mf3[212]*mc3[i+64]+mf3[213]*mc3[i+80]+mf3[214]*mc3[i+96]+mf3[215]*mc3[i+112]+mf3[216]*mc3[i+128]+mf3[217]*mc3[i+144]+mf3[218]*mc3[i+160]+mf3[219]*mc3[i+176]+mf3[220]*mc3[i+192]+mf3[221]*mc3[i+208]+mf3[222]*mc3[i+224]+mf3[223]*mc3[i+240];
                mf3[i+224]<=mf3[224]*mc3[i]+mf3[225]*mc3[i+16]+mf3[226]*mc3[i+32]+mf3[227]*mc3[i+48]+mf3[228]*mc3[i+64]+mf3[229]*mc3[i+80]+mf3[230]*mc3[i+96]+mf3[231]*mc3[i+112]+mf3[232]*mc3[i+128]+mf3[233]*mc3[i+144]+mf3[234]*mc3[i+160]+mf3[235]*mc3[i+176]+mf3[236]*mc3[i+192]+mf3[237]*mc3[i+208]+mf3[238]*mc3[i+224]+mf3[239]*mc3[i+240];
                mf3[i+240]<=mf3[240]*mc3[i]+mf3[241]*mc3[i+16]+mf3[242]*mc3[i+32]+mf3[243]*mc3[i+48]+mf3[244]*mc3[i+64]+mf3[245]*mc3[i+80]+mf3[246]*mc3[i+96]+mf3[247]*mc3[i+112]+mf3[248]*mc3[i+128]+mf3[249]*mc3[i+144]+mf3[250]*mc3[i+160]+mf3[251]*mc3[i+176]+mf3[252]*mc3[i+192]+mf3[253]*mc3[i+208]+mf3[254]*mc3[i+224]+mf3[255]*mc3[i+240];
            end*/

        end
        endcase
    end
end

///CAL Trace for differnnt size
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        tr<=0;
    end
    else if(next_state==CAL_tr)begin
        case(size)
            2:tr <= mf0[0]+mf0[3];
            4:tr <= mf1[0]+mf1[5]+mf1[10]+mf1[15];
            8:tr <= mf2[0]+mf2[9]+mf2[18]+mf2[27]+mf2[36]+mf2[45]+mf2[54]+mf2[63];
            16:tr <= mf3[0]+mf3[17]+mf3[34]+mf3[51]+mf3[68]+mf3[85]+mf3[102]+mf3[119]+mf3[136]+mf3[153]+mf3[170]+mf3[187]+mf3[204]+mf3[221]+mf3[238]+mf3[255];
        endcase  
    end
    else if(current_state==IDLE) tr<=0;
    else tr<=tr;
end
//---------------------------------------------------------------------
//   OUTPUT PART
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
        out_value<=0;
    end
    else if(next_state==OUT)begin
        out_value<=tr;
    end
    else out_value<=0;
end







endmodule
