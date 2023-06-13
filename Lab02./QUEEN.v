module QUEEN(
    //Input Port
    clk,
    rst_n,

    in_valid,
    col,
    row,

    in_valid_num,
    in_num,

    out_valid,
    out,

    );

input               clk, rst_n, in_valid,in_valid_num;
input       [3:0]   col,row;
input       [2:0]   in_num;

output reg          out_valid;
output reg  [3:0]   out;

//==============================================//
//             Parameter and Integer            //
//==============================================//
integer i,j,idx,idj,k1,k2;

parameter IDLE = 3'd0;
parameter IN_DATA = 3'd1;
parameter Wait = 3'd2;
parameter Cal_point  = 3'd3;
parameter Fill_point = 3'd4;
parameter Back_cal = 3'd5;
parameter Output  = 3'd6;

//==============================================//
//                 reg declaration              //
//==============================================//
reg [3:0] col_r,row_r;
reg [3:0] back_r,back_c;
reg [2:0] current_st,next_st;
reg [3:0] ans [11:0];
reg [1:0] board [11:0][11:0];//00 none 01 can't put 10 queen 11 fixed queen(from input)
reg [3:0] board_queenr[11:0][11:0];
reg [3:0] board_queenc[11:0][11:0];
reg [1:0] board_inp [11:0][11:0];
reg col_array[11:0];
reg row_array[11:0];
reg [3:0] queen_inp;
reg  done;
reg [1:0]wait_cnt;
reg [3:0] out_cnt;
reg wrong;
reg [3:0] col_sum[11:0];
reg [3:0] current_r,current_c;
reg [3:0] last_r,last_c;
//reg [3:0] last2_r,last2_c;
//reg [3:0] first_zero;
reg [3:0] out_r;
//==============================================//
//            FSM State Declaration             //
//==============================================//
//current_state
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        current_st <= IDLE; 
    else 
        current_st <= next_st;
end
//next_state
always @(*) begin
    case(current_st)
    IDLE:begin
        if(in_valid||in_valid_num)
           next_st = IN_DATA; 
        else 
            next_st = IDLE; 
        
    end
    IN_DATA:begin
        if(in_valid_num==0&&in_valid==0)
            next_st = Wait;
        else 
            next_st = IN_DATA;       
    end
    Wait:begin
        if(wait_cnt==2)
        next_st=Cal_point;
        else
        next_st=Wait;
    end
    Cal_point:begin
        next_st = Fill_point;
    end
    Fill_point:begin
        if(wrong)
            next_st = Back_cal;
        else if(wrong==0&&done==1)
            next_st = Output;
        else 
            next_st = Cal_point;
    end
    Back_cal:begin
        if(wrong==1)
        next_st = Back_cal;
        else 
        next_st = Cal_point;
    end
    Output:begin
        if(out_cnt==12)
            next_st = IDLE;
        else 
            next_st = Output;
    end
    endcase
    
end
//==============================================//
//                  Input Block                 //
//==============================================//
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        col_r<=0;
        row_r<=0;
    end
    else if(current_st==IN_DATA||next_st==IN_DATA)begin
        col_r<=col;
        row_r<=row;
    end
    else begin
        col_r<=0;
        row_r<=0;
    end
end

always@(posedge clk)begin
    if(current_st==IDLE)begin
        for(i=0;i<12;i=i+1)begin
            col_array[i]<=0;
        end
    end
    else if(current_st==IN_DATA)begin
        col_array[col]<=1;
    end
    else begin
        for(i=0;i<12;i=i+1)begin
        col_array[i]<=col_array[i];
        end
    end
end

always@(posedge clk)begin
    if(current_st==IDLE)begin
        for(i=0;i<12;i=i+1)begin
            row_array[i]<=0;
        end
    end
    else if(current_st==IN_DATA)begin
        row_array[row]<=1;
    end
    else begin
        for(i=0;i<12;i=i+1)begin
        row_array[i]<=row_array[i];
        end
    end
end

always@(posedge clk)begin
    if(current_st==IDLE)begin
        queen_inp<=0;
    end
    else if(current_st==IN_DATA)begin
        queen_inp<=in_num;
    end
    else begin
        queen_inp<=queen_inp;
    end
end

always@(posedge clk)begin
    if(current_st==IDLE)begin
        for(i=0;i<12;i=i+1)begin
            for(j=0;j<12;j=j+1)begin
                board_inp[i][j]<=0;
            end
        end
    end
    else if(current_st==IN_DATA)begin
        board_inp[row_r][col_r]<=11;
    end
    else begin
        for(i=0;i<12;i=i+1)begin
        for(j=0;j<12;j=j+1)begin
        board_inp[i][j]<=board_inp[i][j];
        end
        end
    end
end
//==============================================//
//                    CAL Block                 //
//==============================================//

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
         for(i=0;i<12;i=i+1)begin
            for(j=0;j<12;j=j+1)begin
                board[i][j]<=0;
            end
        end
    end
    else if(current_st==IN_DATA||current_st==Wait)begin
        for(i=0;i<12;i=i+1)begin
            for(j=0;j<12;j=j+1)begin
                board[i][j]<=board_inp[i][j];
            end
        end
    end
    else if(current_st==Cal_point)begin
        for(i=0;i<12;i=i+1)begin
            for(j=0;j<12;j=j+1)begin
                if(board[i][j]==2'b11||board[i][j]==2'b10)begin                  
                    for(idx=0;idx<12;idx=idx+1)begin
                        //row
                        if(board[i][idx]==2'b11||board[i][idx]==2'b10)begin
                            board[i][idx]<=board[i][idx];
                        end
                        else begin
                            board[i][idx]<=2'b01;
                        end
                        //col
                        if(board[idx][j]==2'b11||board[idx][j]==2'b10)begin
                            board[idx][j]<=board[idx][j];
                        end
                        else begin
                            board[idx][j]<=2'b01;
                        end
                        //dia
                        for(idj=0;idj<12;idj=idj+1)begin
                            if((j-idj)==(i-idx)||(j-idj)==(idx-i)||(idj-j)==(i-idx)||(idj-j)==(idx-i))begin
                                if(board[idx][idj]==2'b11||board[idx][idj]==2'b10)
                                    board[idx][idj]<=board[idx][idj];                                                                                  
                                else
                                    board[idx][idj]<=2'b01; 
                            
                            end                          
                        end
                    end                   
                end
            end
        end
    end
    else if(current_st==Fill_point)begin
        board[current_r][current_c]<=2'b10;
    end
    else if(current_st==Back_cal)begin
        board[current_r][current_c]<=2'b01;
        for(i=0;i<12;i=i+1)begin
            for(j=0;j<12;j=j+1)begin
                if(board_queenc[i][j]==current_c&&board_queenr[i][j]==current_r)begin
                    board[i][j]<=0;
                end
            end
        end
        //board[back_r][back_c]<=2'b10;
    end
    else if(current_st==Output)begin
        for(i=0;i<12;i=i+1)begin
            for(j=0;j<12;j=j+1)begin
                board[i][j]<=board[i][j];
            end
        end
    end
    else begin
        for(i=0;i<12;i=i+1)begin
            for(j=0;j<12;j=j+1)begin
                board[i][j]<=2'b00;
            end
        end
    end
end

genvar j0,j1;
generate
    for(j0=0;j0<12;j0=j0+1)begin
        for(j1=0;j1<12;j1=j1+1)begin
            always @(posedge clk) begin
            case(current_st)
            IDLE:board_queenc[j0][j1]<=4'b1111;
            IN_DATA:board_queenc[j0][j1]<=board_queenc[j0][j1];
            Wait:board_queenc[j0][j1]<=board_queenc[j0][j1];
            Cal_point:begin
                if(board[j0][j1]==2'b11||board[j0][j1]==2'b10)begin
                    for(i=0;i<12;i=i+1)begin
                        if(board_queenc[j0][i]==4'b1111)
                        board_queenc[j0][i]<=j1;
                        if(board_queenc[i][j1]==4'b1111)
                        board_queenc[i][j1]<=j1;
                        for(j=0;j<12;j=j+1)begin
                            if(((j0-i==j1-j)||(i-j0==j1-j)||(j0-i==j-j1)||(i-j0==j-j1))&&board_queenc[i][j]==4'b1111)
                            board_queenc[i][j]<=j1;
                        end
                    end
                end
            end
            Fill_point:begin
                if((board[j0][j1]==2'b11||board[j0][j1]==2'b10)&&board_queenc[j0][j1]==4'b1111)begin
                    for(i=0;i<12;i=i+1)begin
                        if(board_queenc[j0][i]==4'b1111)
                        board_queenc[j0][i]<=j1;
                        if(board_queenc[i][j1]==4'b1111)
                        board_queenc[i][j1]<=j1;
                        for(j=0;j<12;j=j+1)begin
                            if(((j0-i==j1-j)||(i-j0==j1-j)||(j0-i==j-j1)||(i-j0==j-j1))&&board_queenc[i][j]==4'b1111)
                            board_queenc[i][j]<=j1;
                        end
                    end
                end
            end
            Back_cal:begin
                if(board_queenc[j0][j1]==current_c)
                board_queenc[j0][j1]<=1'hf;
                else 
                board_queenc[j0][j1]<=board_queenc[j0][j1];
            end
            Output:begin
                board_queenc[j0][j1]<=board_queenc[j0][j1];
            end
            endcase
            end
            
        end
    end
endgenerate

genvar k,k0;
generate
    for(k=0;k<12;k=k+1)begin
        for(k0=0;k0<12;k0=k0+1)begin
            always @(posedge clk) begin
                case(current_st)
                IDLE:board_queenr[k][k0]<=4'b1111;
                IN_DATA:board_queenr[k][k0]<=board_queenr[k][k0];
                Wait:board_queenr[k][k0]<=board_queenr[k][k0];
                Cal_point:begin
                if(board[k][k0]==2'b11||board[k][k0]==2'b10)begin
                    for(i=0;i<12;i=i+1)begin
                        if(board_queenr[k][i]==4'b1111)
                        board_queenr[k][i]<=k;
                        if(board_queenr[i][k0]==4'b1111)
                        board_queenr[i][k0]<=k;
                        for(j=0;j<12;j=j+1)begin
                            if(((k-i==k0-j)||(i-k==k0-j)||(k-i==j-k0)||(i-k==j-k0))&&board_queenr[i][j]==4'b1111)
                            board_queenr[i][j]<=k;
                        end
                    end
                end
            end
                Fill_point:begin
                    if(board[k][k0]==2'b11||board[k][k0]==2'b10)begin
                    for(i=0;i<12;i=i+1)begin
                        if(board_queenr[k][i]==4'b1111)
                        board_queenr[k][i]<=k;
                        if(board_queenr[i][k0]==4'b1111)
                        board_queenr[i][k1]<=k;
                        for(j=0;j<12;j=j+1)begin
                            if(((k-i==k0-j)||(i-k==k0-j)||(k-i==j-k0)||(i-k==j-k0))&&board_queenr[i][j]==4'b1111)
                            board_queenr[i][j]<=k;
                        end
                    end
                end
                end
                Back_cal:begin
                    if(board_queenr[k][k0]==current_r)
                    board_queenr[k][k0]<=4'b1111;
                    else 
                    board_queenr[k][k0]<=board_queenr[k][k0];
                end
                Output:begin
                    board_queenr[k][k0]<=board_queenr[k][k0];
                end
                endcase
            end
        end
    end    
endgenerate

//Row Col control


   /* always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
        back_r<=0;
        else begin
            for(i=0;i+current_r<12;i=i+1)begin
                if(board[current_r+i][current_c]==2'b00)
                back_r<=current_r+i;
                else if(bo)
            end
        end
    end
*/

genvar i0;
generate
    for(i0=0;i0<12;i0=i0+1)begin
        always@(*)begin
            col_sum[i0] = board[0][i0]+board[1][i0]+board[2][i0]+board[3][i0]+board[4][i0]+board[5][i0]+board[6][i0]+board[7][i0]+board[8][i0]+board[9][i0]+board[10][i0]+board[11][i0];
        end
    end
endgenerate
//find first col(current_col) that needs to fill 
always @(*) begin
    if(wrong==0)begin
    if(col_sum[0]<12)
    current_c = 0;
    else if(col_sum[1]<12)
    current_c = 1;
    else if(col_sum[2]<12)
    current_c = 2;
    else if(col_sum[3]<12)
    current_c = 3;
    else if(col_sum[4]<12)
    current_c = 4;
    else if(col_sum[5]<12)
    current_c = 5;
    else if(col_sum[6]<12)
    current_c = 6;
    else if(col_sum[7]<12)
    current_c = 7;
    else if(col_sum[8]<12)
    current_c = 8;
    else if(col_sum[9]<12)
    current_c = 9;
    else if(col_sum[10]<12)
    current_c = 10;
    else if(col_sum[11]<12)
    current_c = 11;
    else //assign current col to 15 to represent done
    current_c = 15;   
    end
    else begin
        if(col_sum[11]==13)
        current_c = 11;
        else if(col_sum[10]==13)
        current_c = 10;
        else if(col_sum[9]==13)
        current_c = 9;
        else if(col_sum[8]==13)
        current_c = 8;
        else if(col_sum[7]==13)
        current_c = 7;
        else if(col_sum[6]==13)
        current_c = 6;
        else if(col_sum[5]==13)
        current_c = 5;
        else if(col_sum[4]==13)
        current_c = 4;
        else if(col_sum[3]==13)
        current_c = 3;
        else if(col_sum[2]==13)
        current_c = 2;
        else if(col_sum[1]==13)
        current_c = 1;
        else
        current_c = 0;
    end      
end


//find current row (first zero)    
        always @(current_c) begin   
            if(wrong==0)begin         
                if(board[0][current_c]==0)
                current_r = 0;
                else if(board[1][current_c]==0)begin
                    current_r = 1;
                end
                else if(board[2][current_c]==0)begin
                    current_r = 2;
                end
                else if(board[3][current_c]==0)begin
                    current_r = 3;
                end
                else if(board[4][current_c]==0)begin
                    current_r = 4;
                end
                else if(board[5][current_c]==0)begin
                    current_r = 5;
                end
                else if(board[6][current_c]==0)begin
                    current_r = 6;
                end
                else if(board[7][current_c]==0)begin
                    current_r = 7;
                end
                else if(board[8][current_c]==0)begin
                    current_r = 8;
                end
                else if(board[9][current_c]==0)begin
                    current_r = 9;
                end
                else if(board[10][current_c]==0)begin
                    current_r = 10;
                end
                else if(board[11][current_c]==0) begin
                    current_r = 11;
                end
            end
            else if(wrong==1)begin
                if(board[0][current_c]==2'b10)
                current_r = 0;
                else if(board[1][current_c]==2'b10)begin
                    current_r = 1;
                end
                else if(board[2][current_c]==2'b10)begin
                    current_r = 2;
                end
                else if(board[3][current_c]==2'b10)begin
                    current_r = 3;
                end
                else if(board[4][current_c]==2'b10)begin
                    current_r = 4;
                end
                else if(board[5][current_c]==2'b10)begin
                    current_r = 5;
                end
                else if(board[6][current_c]==2'b10)begin
                    current_r = 6;
                end
                else if(board[7][current_c]==2'b10)begin
                    current_r = 7;
                end
                else if(board[8][current_c]==2'b10)begin
                    current_r = 8;
                end
                else if(board[9][current_c]==2'b10)begin
                    current_r = 9;
                end
                else if(board[10][current_c]==2'b10)begin
                    current_r = 10;
                end
                else if(board[11][current_c]==2'b10) begin
                    current_r = 11;
                end
            end
                

            
        end
    

//wrong control
always @(*) begin
    if(col_sum[0]==12)
    wrong=1;
    else if(col_sum[1]==12)
    wrong=1;
    else if(col_sum[2]==12)
    wrong=1;
    else if(col_sum[3]==12)
    wrong=1;
    else if(col_sum[4]==12)
    wrong=1;
    else if(col_sum[5]==12)
    wrong=1;
    else if(col_sum[6]==12)
    wrong=1;
    else if(col_sum[7]==12)
    wrong=1;
    else if(col_sum[8]==12)
    wrong=1;
    else if(col_sum[9]==12)
    wrong=1;
    else if(col_sum[10]==12)
    wrong=1;
    else if(col_sum[11]==12)
    wrong=1;
    else
    wrong=0;
end
always @(*) begin
    if(current_c==15)
    done = 1;
    else 
    done = 0;
end
//==============================================//
//                Counter Block                 //
//==============================================//
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
    wait_cnt<=0;
    else if(wait_cnt==2'b10)
    wait_cnt<=0;
    else 
    wait_cnt <=wait_cnt+1;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
    out_cnt<=0;
    else if(out_cnt==12)
    out_cnt<=0;
    else 
    out_cnt<=out_cnt+1;
end
//GOOD LUCKY
//==============================================//
//                 Output Block                 //
//==============================================//
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
    out<=0;
    else
    out<=0;
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
    out_valid<=0;
    else if(current_st<=Output)
    out_valid<=0;
    else
    out_valid<=0;
end
endmodule 


