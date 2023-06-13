module SUBWAY(
    //Input Port
    clk,
    rst_n,
    in_valid,
    init,
    in0,
    in1,
    in2,
    in3,
    //Output Port
    out_valid,
    out
);


input clk, rst_n;
input in_valid;
input [1:0] init;
input [1:0] in0, in1, in2, in3; 
output reg       out_valid;
output reg [1:0] out;


//==============================================//
//       parameter & integer declaration        //
//==============================================//
parameter IDLE =2'b00;
parameter IN_DATA = 2'b01;
parameter CAL = 2'b10;
parameter OUT = 2'b11;

integer i,j;
//==============================================//
//           reg & wire declaration             //
//==============================================//
reg [1:0] current_state,next_state;
reg [1:0]map[0:3][0:63];
reg [1:0]move[0:62];
reg [5:0]out_cnt;
reg [5:0]in_cnt;
//reg [5:0]cycles;
reg [1:0] now_place;
reg [1:0] new_place1,new_place2,new_place3,new_place4,new_place5,new_place6,new_place7;
reg signed [2:0] dis0,dis1,dis2,dis3,dis4,dis5,dis6;//store the difference between in & out between every two train
//wire [1:0] np0;
//wire [1:0]np1,np2,np3,np4,np5,np6,np7;
//wire signed [2:0] d0,d1,d2,d3,d4,d5,d6;

//==============================================//
//                  design                      //
//==============================================//

//FSM
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        current_state<=IDLE;
    end
    else current_state<=next_state;
end

always@(*)begin
    case(current_state)
    IDLE:begin
        if(in_valid==1) next_state = IN_DATA;
        else next_state = IDLE;
    end
    IN_DATA:begin
        if(in_valid==1)next_state = IN_DATA;
        else next_state = CAL;
    end
    CAL:next_state = OUT;
    OUT:begin
        if(out_cnt==62)next_state = IDLE;
        else next_state = OUT;
    end
    endcase
end
//#############################################
//now place
//#############################################
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        now_place<=0;
    end
    else if(in_valid&&current_state==IDLE) now_place<=init;
    else if(current_state==IDLE) now_place<=0;
    else now_place<=now_place;
end
//#############################################
//map 
//#############################################
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)in_cnt<=0;
    else if(in_valid)in_cnt<=in_cnt+1;
    else  in_cnt<=0;

end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        for(i=0;i<4;i=i+1)begin
            for(j=0;j<64;j=j+1)begin
                map[i][j]<=0;
            end
        end
    end
    else if(in_valid)begin
        map[0][in_cnt]<=in0;
        map[1][in_cnt]<=in1;
        map[2][in_cnt]<=in2;
        map[3][in_cnt]<=in3;
    end
    else begin
        for(i=0;i<4;i=i+1)begin
            for(j=0;j<64;j=j+1)begin
                map[i][j]<=map[i][j];
            end
    end
    end
end
//#######################################
//dis & new place
//now place 0~7
//new place1 8~15
//new place2 16~23
//new place3 24~31
//new place4 32~39
//new place5 40~47
//new place6 48~55
//new place7 56~63
//#######################################
always@(*)begin
    if(map[0][8]==0) dis0 = now_place-0;
    else if(map[1][8]==0) dis0 = now_place-1;
    else if(map[2][8]==0) dis0 = now_place-2;
    else dis0 = now_place-3;
end
always @(*) begin
    new_place1 = now_place-dis0;
end
always @(*) begin
    if(map[0][16]==0) dis1 = new_place1-0;
    else if(map[1][16]==0) dis1 = new_place1-1;
    else if(map[2][16]==0) dis1 = new_place1-2;
    else dis1 = new_place1-3;
end
always @(*) begin
    new_place2 = new_place1-dis1;
end
always @(*) begin
    if(map[0][24]==0) dis2 = new_place2-0;
    else if(map[1][24]==0) dis2 = new_place2-1;
    else if(map[2][24]==0) dis2 = new_place2-2;
    else dis2 = new_place2-3;
end
always @(*) begin
    new_place3 = new_place2-dis2;
end
always @(*) begin
    if(map[0][32]==0) dis3 = new_place3-0;
    else if(map[1][32]==0) dis3 = new_place3-1;
    else if(map[2][32]==0) dis3 = new_place3-2;
    else dis3 = new_place3-3;
end
always @(*) begin
    new_place4 = new_place3-dis3;
end
always @(*) begin
    if(map[0][40]==0) dis4 = new_place4-0;
    else if(map[1][40]==0) dis4 = new_place4-1;
    else if(map[2][40]==0) dis4 = new_place4-2;
    else dis4 = new_place4-3;
end
always @(*) begin
    new_place5 = new_place4-dis4;
end
always @(*) begin
    if(map[0][48]==0) dis5 = new_place5-0;
    else if(map[1][48]==0) dis5 = new_place5-1;
    else if(map[2][48]==0) dis5 = new_place5-2;
    else dis5 = new_place5-3;
end
always @(*) begin
    new_place6 = new_place5-dis5;
end
always @(*) begin
    if(map[0][56]==0) dis6 = new_place6-0;
    else if(map[1][56]==0) dis6 = new_place6-1;
    else if(map[2][56]==0) dis6 = new_place6-2;
    else dis6 = new_place6-3;
end
always @(*) begin
    new_place7 = new_place6-dis6;
end
//#######################################
//record move
//#######################################
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        for(i=0;i<63;i=i+1)begin
            move[i]<=0;
        end
    end
    else if(current_state==IDLE)begin
        for(i=0;i<63;i=i+1) move[i]<=0;
    end
    else if(current_state==CAL)begin
        move[0]<=0;
        move[2]<=0;
        move[8]<=0;
        move[10]<=0;
        move[16]<=0;
        move[18]<=0;
        move[24]<=0;
        move[26]<=0;
        move[32]<=0;
        move[34]<=0;
        move[40]<=0;
        move[42]<=0;
        move[48]<=0;
        move[50]<=0;
        move[58]<=0;
        move[60]<=0;
        move[62]<=0;
        if(map[now_place][2]==2'b10||map[now_place][2]==2'b00) move[1]<=0;
        else if(map[now_place][2]==2'b01)move[1]<=2'b11;
        if(map[now_place][4]==2'b01) move[3]<=2'b11;
        else move[3]<=2'b00;
        //first train to secend train
        if(dis0==-3)begin
            move[4]<=2'b01;
            move[6]<=2'b01;
            move[7]<=2'b01;
            if(map[now_place+1][6]==2'b01) move[5]<=2'b11;
            else move[5]<=2'b00;
        end
        else if(dis0==-2)begin
            move[4]<=2'b01;
            move[6]<=2'b01;
            move[7]<=2'b00;
            if(map[now_place+1][6]==2'b01) move[5]<=2'b11;
            else move[5]<=2'b00;
        end
        else if(dis0==-1)begin
            move[4]<=2'b01;
            move[6]<=2'b00;
            move[7]<=2'b00;
            if(map[now_place+1][6]==2'b01) move[5]<=2'b11;
            else move[5]<=2'b00;
        end
        else if(dis0==0)begin
            move[4]<=2'b00;
            move[6]<=2'b00;
            move[7]<=2'b00;
            if(map[now_place][6]==2'b01) move[5]<=2'b11;
            else move[5]<=2'b00;
        end
        else if(dis0==3)begin
            move[4]<=2'b10;
            move[6]<=2'b10;
            move[7]<=2'b10;
            if(map[now_place-1][6]==2'b01) move[5]<=2'b11;
            else move[5]<=2'b00;
        end
        else if(dis0==2)begin
            move[4]<=2'b10;
            move[6]<=2'b10;
            move[7]<=2'b00;
            if(map[now_place-1][6]==2'b01) move[5]<=2'b11;
            else move[5]<=2'b00;
        end
        else if(dis0==1)begin
            move[4]<=2'b10;
            move[6]<=2'b00;
            move[7]<=2'b00;
            if(map[now_place-1][6]==2'b01) move[5]<=2'b11;
            else move[5]<=2'b00;
        end
        if(map[new_place1][12]==2'b01) move[11]<=2'b11;
        else move[11]<=2'b00;
        if(map[new_place1][10]==2'b01) move[9]<=2'b11;
        else move[9]<=2'b00;
        //secend train to third train dis1 new1 12 13 14 15
        if(dis1==-3)begin
            move[12]<=2'b01;
            move[14]<=2'b01;
            move[15]<=2'b01;
            if(map[new_place1+1][14]==2'b01) move[13]<=2'b11;
            else move[13]<=2'b00;
        end
        else if(dis1==-2)begin
            move[12]<=2'b01;
            move[14]<=2'b01;
            move[15]<=2'b00;
            if(map[new_place1+1][14]==2'b01) move[13]<=2'b11;
            else move[13]<=2'b00;
        end
        else if(dis1==-1)begin
            move[12]<=2'b01;
            move[14]<=2'b00;
            move[15]<=2'b00;
            if(map[new_place1+1][14]==2'b01) move[13]<=2'b11;
            else move[13]<=2'b00;
        end
        else if(dis1==0)begin
            move[12]<=2'b00;
            move[14]<=2'b00;
            move[15]<=2'b00;
            if(map[new_place1][14]==2'b01) move[13]<=2'b11;
            else move[13]<=2'b00;
        end
        else if(dis1==1)begin
            move[12]<=2'b10;
            move[14]<=2'b00;
            move[15]<=2'b00;
            if(map[new_place1-1][14]==2'b01) move[13]<=2'b11;
            else move[13]<=2'b00;
        end
        else if(dis1==2)begin
            move[12]<=2'b10;
            move[14]<=2'b10;
            move[15]<=2'b00;
            if(map[new_place1-1][14]==2'b01) move[13]<=2'b11;
            else move[13]<=2'b00;
        end
        else if(dis1==3)begin
            move[12]<=2'b10;
            move[14]<=2'b10;
            move[15]<=2'b10;
            if(map[new_place1-1][14]==2'b01) move[13]<=2'b11;
            else move[13]<=2'b00;
        end
        if(map[new_place2][18]==2'b01) move[17]<=2'b11;
        else move[17]<=2'b00;
        if(map[new_place2][20]==2'b01) move[19]<=2'b11;
        else move[19]<=2'b00;
        //third to fourth train
        if(dis2==-3)begin
            move[20]<=2'b01;
            move[22]<=2'b01;
            move[23]<=2'b01;
            if(map[new_place2+1][22]==2'b01) move[21]<=2'b11;
            else move[21]<=2'b00;
        end
        else if(dis2==-2)begin
            move[20]<=2'b01;
            move[22]<=2'b01;
            move[23]<=2'b00;
            if(map[new_place2+1][22]==2'b01) move[21]<=2'b11;
            else move[21]<=2'b00;
        end
        else if(dis2==-1)begin
            move[20]<=2'b01;
            move[22]<=2'b00;
            move[23]<=2'b00;
            if(map[new_place2+1][22]==2'b01) move[21]<=2'b11;
            else move[21]<=2'b00;
        end
        else if(dis2==0)begin
            move[20]<=2'b00;
            move[22]<=2'b00;
            move[23]<=2'b00;
            if(map[new_place2][22]==2'b01) move[21]<=2'b11;
            else move[21]<=2'b00;
        end
        else if(dis2==1)begin
            move[20]<=2'b10;
            move[22]<=2'b00;
            move[23]<=2'b00;
            if(map[new_place2-1][22]==2'b01) move[21]<=2'b11;
            else move[21]<=2'b00;
        end
        else if(dis2==2)begin
            move[20]<=2'b10;
            move[22]<=2'b10;
            move[23]<=2'b00;
            if(map[new_place2-1][22]==2'b01) move[21]<=2'b11;
            else move[21]<=2'b00;
        end
        else if(dis2==3)begin
            move[20]<=2'b10;
            move[22]<=2'b10;
            move[23]<=2'b10;
            if(map[new_place2-1][22]==2'b01) move[21]<=2'b11;
            else move[21]<=2'b00;
        end
        if(map[new_place3][26]==2'b01) move[25]<=2'b11;
        else move[25]<=2'b00;
        if(map[new_place3][28]==2'b01) move[27]<=2'b11;
        else move[27]<=2'b00;
        //forth to fifth 
        if(dis3==-3)begin
            move[28]<=2'b01;
            move[30]<=2'b01;
            move[31]<=2'b01;
            if(map[new_place3+1][30]==2'b01) move[29]<=2'b11;
            else move[29]<=2'b00;
        end
        else if(dis3==-2)begin
            move[28]<=2'b01;
            move[30]<=2'b01;
            move[31]<=2'b00;
            if(map[new_place3+1][30]==2'b01) move[29]<=2'b11;
            else move[29]<=2'b00;
        end
        else if(dis3==-1)begin
            move[28]<=2'b01;
            move[30]<=2'b00;
            move[31]<=2'b00;
            if(map[new_place3+1][30]==2'b01) move[29]<=2'b11;
            else move[29]<=2'b00;
        end
        else if(dis3==0)begin
            move[28]<=2'b00;
            move[30]<=2'b00;
            move[31]<=2'b00;
            if(map[new_place3][30]==2'b01) move[29]<=2'b11;
            else move[29]<=2'b00;
        end
        else if(dis3==1)begin
            move[28]<=2'b10;
            move[30]<=2'b00;
            move[31]<=2'b00;
            if(map[new_place3-1][30]==2'b01) move[29]<=2'b11;
            else move[29]<=2'b00;
        end
        else if(dis3==2)begin
            move[28]<=2'b10;
            move[30]<=2'b10;
            move[31]<=2'b00;
            if(map[new_place3-1][30]==2'b01) move[29]<=2'b11;
            else move[29]<=2'b00;
        end
        else if(dis3==3)begin
            move[28]<=2'b10;
            move[30]<=2'b10;
            move[31]<=2'b10;
            if(map[new_place3-1][30]==2'b01) move[29]<=2'b11;
            else move[29]<=2'b00;
        end
        if(map[new_place4][34]==2'b01) move[33]<=2'b11;
        else move[33]<=2'b00;
        if(map[new_place4][36]==2'b01) move[35]<=2'b11;
        else move[35]<=2'b00;
        //fifth to sixth
        if(dis4==-3)begin
            move[36]<=2'b01;
            move[38]<=2'b01;
            move[39]<=2'b01;
            if(map[new_place4+1][38]==2'b01) move[37]<=2'b11;
            else move[37]<=2'b00;
        end
        else if(dis4==-2)begin
            move[36]<=2'b01;
            move[38]<=2'b01;
            move[39]<=2'b00;
            if(map[new_place4+1][38]==2'b01) move[37]<=2'b11;
            else move[37]<=2'b00;
        end
        else if(dis4==-1)begin
            move[36]<=2'b01;
            move[38]<=2'b00;
            move[39]<=2'b00;
            if(map[new_place4+1][38]==2'b01) move[37]<=2'b11;
            else move[37]<=2'b00;
        end
        else if(dis4==0)begin
            move[36]<=2'b00;
            move[38]<=2'b00;
            move[39]<=2'b00;
            if(map[new_place4][38]==2'b01) move[37]<=2'b11;
            else move[37]<=2'b00;
        end
        else if(dis4==1)begin
            move[36]<=2'b10;
            move[38]<=2'b00;
            move[39]<=2'b00;
            if(map[new_place4-1][38]==2'b01) move[37]<=2'b11;
            else move[37]<=2'b00;
            
        end
        else if(dis4==2)begin
            move[36]<=2'b10;
            move[38]<=2'b10;
            move[39]<=2'b00;
            if(map[new_place4-1][38]==2'b01) move[37]<=2'b11;
            else move[37]<=2'b00;
        end
        else if(dis4==3)begin
            move[36]<=2'b10;
            move[38]<=2'b10;
            move[39]<=2'b10;
            if(map[new_place4-1][38]==2'b01) move[37]<=2'b11;
            else move[37]<=2'b00;
        end
        if(map[new_place5][42]==2'b01) move[41]<=2'b11;
        else move[41]<=2'b00;
        if(map[new_place5][44]==2'b01) move[43]<=2'b11;
        else move[43]<=2'b00;
        //sixth to seven
        if(dis5==-3)begin
            move[44]<=2'b01;
            move[46]<=2'b01;
            move[47]<=2'b01;
            if(map[new_place5+1][46]==2'b01) move[45]<=2'b11;
            else move[45]<=2'b00;
        end
        if(dis5==-2)begin
            move[44]<=2'b01;
            move[46]<=2'b01;
            move[47]<=2'b00;
            if(map[new_place5+1][46]==2'b01) move[45]<=2'b11;
            else move[45]<=2'b00;
        end
        if(dis5==-1)begin
            move[44]<=2'b01;
            move[46]<=2'b00;
            move[47]<=2'b00;
            if(map[new_place5+1][46]==2'b01) move[45]<=2'b11;
            else move[45]<=2'b00;
        end
        if(dis5==0)begin
            move[44]<=2'b00;
            move[46]<=2'b00;
            move[47]<=2'b00;
            if(map[new_place5][46]==2'b01) move[45]<=2'b11;
            else move[45]<=2'b00;
        end
        if(dis5==1)begin
            move[44]<=2'b10;
            move[46]<=2'b00;
            move[47]<=2'b00;
            if(map[new_place5-1][46]==2'b01) move[45]<=2'b11;
            else move[45]<=2'b00;
        end
        if(dis5==2)begin
            move[44]<=2'b10;
            move[46]<=2'b10;
            move[47]<=2'b00;
            if(map[new_place5-1][46]==2'b01) move[45]<=2'b11;
            else move[45]<=2'b00;
        end
        if(dis5==3)begin
            move[44]<=2'b10;
            move[46]<=2'b10;
            move[47]<=2'b10;
            if(map[new_place5-1][46]==2'b01) move[45]<=2'b11;
            else move[45]<=2'b00;
        end
        if(map[new_place6][50]==2'b01) move[49]<=2'b11;
        else move[49]<=2'b00;
        if(map[new_place6][52]==2'b01) move[51]<=2'b11;
        else move[51]<=2'b00;
        //seven to eight 
        if(dis6==-3)begin
            move[52]<=2'b01;
            move[54]<=2'b01;
            move[55]<=2'b01;
            if(map[new_place6+1][54]==2'b01) move[53]<=2'b11;
            else move[53]<=2'b00;
        end
        if(dis6==-2)begin
            move[52]<=2'b01;
            move[54]<=2'b01;
            move[55]<=2'b00;
            if(map[new_place6+1][54]==2'b01) move[53]<=2'b11;
            else move[53]<=2'b00;
        end
        if(dis6==-1)begin
            move[52]<=2'b01;
            move[54]<=2'b00;
            move[55]<=2'b00;
            if(map[new_place6+1][54]==2'b01) move[53]<=2'b11;
            else move[53]<=2'b00;
        end
        if(dis6==0)begin
            move[52]<=2'b00;
            move[54]<=2'b00;
            move[55]<=2'b00;
            if(map[new_place6][54]==2'b01) move[53]<=2'b11;
            else move[53]<=2'b00;
        end
        if(dis6==3)begin
            move[52]<=2'b10;
            move[54]<=2'b10;
            move[55]<=2'b10;
            if(map[new_place6-1][54]==2'b01) move[53]<=2'b11;
            else move[53]<=2'b00;
        end
        if(dis6==2)begin
            move[52]<=2'b10;
            move[54]<=2'b10;
            move[55]<=2'b00;
            if(map[new_place6-1][54]==2'b01) move[53]<=2'b11;
            else move[53]<=2'b00;
        end
        if(dis6==1)begin
            move[52]<=2'b10;
            move[54]<=2'b00;
            move[55]<=2'b00;
            if(map[new_place6-1][54]==2'b01) move[53]<=2'b11;
            else move[53]<=2'b00;
        end
        if(map[new_place7][58]==2'b01) move[57]<=2'b11;
        else move[57]<=2'b00;
        if(map[new_place7][60]==2'b01) move[59]<=2'b11;
        else move[59]<=2'b00;

        if(map[new_place7][62]==2'b01)move[61]<=2'b11;
        else move[61]<=2'b00;

    end
    else begin
        for(i=0;i<63;i=i+1)begin
            move[i]<=move[i];
        end
    end
end

//OUT
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) out_cnt<=0;
    else if(current_state==OUT) out_cnt<=out_cnt+1;
    else out_cnt<=0;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        out_valid<=0;
    end
    else if(current_state==OUT) out_valid<=1;
    else out_valid<=0;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        out <=2'b00;
    end
    else if(out_valid&&next_state==OUT) out<=move[out_cnt];
    else if(out_cnt==0) out<=2'b00;
    else if(current_state==IDLE) out<=2'b00;
    else out<=2'b000;
end
endmodule

