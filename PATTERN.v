`ifdef RTL
    `define CYCLE_TIME 10.0
`endif
`ifdef GATE
    `define CYCLE_TIME 10.0
`endif



module PATTERN(
    // Output Signals
    clk,
    rst_n,
    in_valid,
    init,
    in0,
    in1,
    in2,
    in3,
    // Input Signals
    out_valid,
    out
);


/* Input for design */
output reg       clk, rst_n;
output reg       in_valid;
output reg [1:0] init;
output reg [1:0] in0, in1, in2, in3; 


/* Output for pattern */
input            out_valid;
input      [1:0] out; 
integer start_place;
integer now_place;
integer i,j,i0,j0;
integer i_pat;
integer replace;
integer skip_time;
integer cycles;
reg[1:0] train_num[0:7];
reg [1:0] t_row[0:3];
//integer SEED;
integer total_latency;
//integer CYCLE = `CYCLE_TIME;
parameter PATNUM = 1000;
//SEED = 123;
reg [1:0] map [0:3][0:63];
reg [1:0] every_step[0:62];


/* define clock cycle */
real CYCLE = `CYCLE_TIME;
always #(CYCLE/2.0) clk = ~clk;

initial begin
    rst_n = 1'b1;
    in_valid = 1'b0;
    in0 = 'dx;
    in1 = 'dx;
    in2 = 'dx;
    in3 = 'dx;
    force clk = 0;
    reset_task;
    for(i_pat=0;i_pat<PATNUM;i_pat=i_pat+1)begin
    geninit;   
    genmap;
    input_task;
    wait_out_valid;
    check_ans;
    for(j=0;j<63;j=j+1)begin
        every_step[j] = 0;
    end
    end
    #(30)
    PASS;
    $finish;
end

always @(negedge clk) begin
    outvalid_rst;
end




task check_ans;
begin
    cycles = 0;
    now_place = start_place;
    while(out_valid==1)begin
        every_step[cycles] = out;
        cycles = cycles +1;

        if(cycles == 64) begin
		  	$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		  	$display ("                                                                 SPEC 7 IS FAIL!                                                            ");
		  	$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		  	$finish;
	  	end
        //################################
        //SPEC 8
        //################################
        case(out)
        2'b00:begin
            if(map[now_place][cycles]==2'b01)begin//hitting lower obstacles
                $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		  		$display ("                                                                 SPEC 8-2 IS FAIL!                                                            ");
		  		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		  		$finish;
            end
            if(map[now_place][cycles]==2'b11)begin//hitting train 
                $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		  		$display ("                                                                 SPEC 8-4 IS FAIL!                                                            ");
		  		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		  		$finish;
            end
        end
        2'b01:begin//right now = now+1
            now_place = now_place+1;
            if(now_place===4)begin
                $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		  		$display ("                                                                 SPEC 8-1 IS FAIL!                                                            ");
		  		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		  		$finish;
            end
            else if(map[now_place][cycles]==2'b01)begin//right and hitting train
                $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		  		$display ("                                                                 SPEC 8-2 IS FAIL!                                                            ");
		  		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		  		$finish;
            end
            else if(map[now_place][cycles]==2'b10)begin
                $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		  		$display ("                                                                 SPEC 8-3 IS FAIL!                                                            ");
		  		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		  		$finish;
            end
            else if(map[now_place][cycles]==2'b11)begin
                $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		  		$display ("                                                                 SPEC 8-4 IS FAIL!                                                            ");
		  		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		  		$finish;
            end
        end
        2'b10:begin//left now = now-1
        now_place = now_place-1;
            if(now_place===-1)begin//Out of bound!!!!!!!
                $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		  		$display ("                                                                 SPEC 8-1 IS FAIL!                                                            ");
		  		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		  		$finish;
            end
            else if(map[now_place][cycles]==2'b01)begin
                $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		  		$display ("                                                                 SPEC 8-2 IS FAIL!                                                            ");
		  		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		  		$finish;
            end
            else if(map[now_place][cycles]==2'b10)begin
                $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		  		$display ("                                                                 SPEC 8-3 IS FAIL!                                                            ");
		  		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		  		$finish;
            end
            else if(map[now_place][cycles]==2'b11)begin
                $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		  		$display ("                                                                 SPEC 8-4 IS FAIL!                                                            ");
		  		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		  		$finish;
            end
        end
        2'b11:begin
            if(map[now_place][cycles]==2'b10)begin//hitting higher obstacles
                $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		  		$display ("                                                                 SPEC 8-3 IS FAIL!                                                            ");
		  		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		  		$finish;
            end
            else if(map[now_place][cycles]==2'b11)begin//hitting train
                $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		  		$display ("                                                                 SPEC 8-4 IS FAIL!                                                            ");
		  		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		  		$finish;
            end
            else if(map[now_place][cycles-1]==2'b01)begin//jump two times 
                $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		  		$display ("                                                                 SPEC 8-5 IS FAIL!                                                            ");
		  		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		  		$finish;
            end
        end
        endcase
        @(negedge clk);
    end
    if(cycles < 63)begin
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                                 SPEC 7 IS FAIL!                                                            ");
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		$finish;
	end
end    
endtask


task reset_task ; 
begin
	#(10); rst_n = 0;

	#(10);
	if((out_valid !== 0) || (out !== 0)) begin
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                                   SPEC 3 IS FAIL!                                                          ");
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		
		#(100);
	    $finish ;
	end
	
	#(10); rst_n = 1 ;
	#(5); release clk;
end endtask

task wait_out_valid ; 
begin
	cycles = 0;
	while(out_valid === 0)begin
		cycles = cycles + 1;
		if(cycles == 3000) begin
			$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
			$display ("                                                                 SPEC 6 IS FAIL!                                                            ");
			$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
			$finish;
		end
		@(negedge clk);
	end
end 
endtask

task outvalid_rst ;
begin
	if( (out_valid === 0) && (out !== 0) )begin	
    	$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
    	$display ("                          		                                    SPEC 4 IS FAIL!                                                            ");	
   	 	$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		$finish;
	end
end 
endtask

task input_task ; 
begin
	skip_time = $urandom_range(2,4);
	repeat(skip_time)@(negedge clk);
	in_valid = 'b1;
	
	for(i=0;i<64;i=i+1)begin
		in3 = map[3][i];
		in2 = map[2][i];
		in1 = map[1][i];
		in0 = map[0][i];

		if(i==0) init = start_place;
		else init='dx;

		@(negedge clk);
	end

	if(out_valid===1) begin
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                                 SPEC 5 IS FAIL!                                                            ");
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		$finish;
	end
	
	in_valid     = 'b0;
	in0       =  'dx;
	in1       =  'dx;
	in2       =  'dx;
	in3       =  'dx;
end 
endtask

task geninit;
begin
    start_place = $urandom_range(0,3);
    $display(start_place);
end
endtask

task genmap;
begin
    for(i=0;i<4;i=i+1)begin
        //$display("\n");
        for(j=0;j<64;j=j+1)begin
            map[i][j] = 2'b00;
            //$display(map[i][j]);                                             
        end
    end
    for(i0=0;i0<4;i0=i0+1)begin      
            for(i=0;i<3;i=i+1)begin
            t_row[i] = $urandom_range(0,3);
            if(i0==t_row[i]&&t_row[i]!=start_place)
            map[t_row[i]][0] = 2'b11;
            end
        for(j0=0;j0<4;j0=j0+1)begin
            if(map[i0][0]==2'b11)
            map[i0][j0] = 2'b11;
            if(map[i0][0]==2'b00)
            map[i0][2] = $urandom_range(0,2);  
        end       
    end
    if(map[start_place][0]==3)begin
        map[start_place][0]=0;
        map[start_place][1]=0;
        map[start_place][2]=$urandom_range(0,2);
        map[start_place][3]=0;
    end
    if(map[0][0]+map[1][0]+map[2][0]+map[3][0]==0)begin
        replace = $urandom_range(0,3);
        if(replace==start_place)begin
            if(replace==3)begin
                replace = replace-$urandom_range(1,3);
                map[replace][0] = 3;
                map[replace][1] = 3;
                map[replace][2] = 3;
                map[replace][3] = 3;
            end
            if(replace==0)begin
                replace = replace+$urandom_range(1,3);
                map[replace][0] = 3;
                map[replace][1] = 3;
                map[replace][2] = 3;
                map[replace][3] = 3;
            end
            else begin
                replace = replace+1;
                map[replace][0] = 3;
                map[replace][1] = 3;
                map[replace][2] = 3;
                map[replace][3] = 3;
            end
        end
        map[replace][0] = 3;
        map[replace][1] = 3;
        map[replace][2] = 3;
        map[replace][3] = 3;
    end
     map[start_place][0]=0;
        map[start_place][1]=0;
        map[start_place][2]=$urandom_range(0,2);
        map[start_place][3]=0;
   for(i=0;i<4;i=i+1)begin
    for(j=4;j<8;j=j+1)begin
        if(j%2==0)
        map[i][j] = $urandom_range(0,2);
    end
   end

   for(i0=0;i0<4;i0=i0+1)begin
        for(i=0;i<3;i=i+1)begin
            t_row[i] = $urandom_range(0,3);
            if(i0==t_row[i]&&i0<3)
            map[t_row[i]][8] = 2'b11;
        end
        for(j0=8;j0<12;j0=j0+1)begin
            if(map[i0][8]==2'b11)
            map[i0][j0] = 2'b11;
            if(map[i0][8]==2'b00)
            map[i0][10] = $urandom_range(0,2);
        end
   end

if(map[0][8]+map[1][8]+map[2][8]+map[3][8]==12)begin
            replace = $urandom_range(0,3);
            map[replace][8] = 0;
            map[replace][9] = 0;
            map[replace][10] = 0;
            map[replace][11] = 0;
        end
if(map[0][8]+map[1][8]+map[2][8]+map[3][8]==0)begin
            replace = $urandom_range(0,3);
            map[replace][8] = 3;
            map[replace][9] = 3;
            map[replace][10] = 3;
            map[replace][11] = 3;
        end

   for(i=0;i<4;i=i+1)begin
    for(j=12;j<16;j=j+1)begin
        if(j%2==0)
        map[i][j] = $urandom_range(0,2);
    end
   end

   for(i0=0;i0<4;i0=i0+1)begin
    for(i=0;i<3;i=i+1)begin
            t_row[i] = $urandom_range(0,3);
            if(i0==t_row[i]&&i0<3)
            map[t_row[i]][16] = 2'b11;
    end
    for(j0=16;j0<20;j0=j0+1)begin
        if(map[i0][16]==2'b11)
            map[i0][j0] = 2'b11;
            if(map[i0][16]==2'b00)
            map[i0][18] = $urandom_range(0,2);
    end
   end

   if(map[0][16]+map[1][16]+map[2][16]+map[3][16]==12)begin
            replace = $urandom_range(0,3);
            map[replace][16] = 0;
            map[replace][17] = 0;
            map[replace][18] = 0;
            map[replace][19] = 0;
        end
        if(map[0][16]+map[1][16]+map[2][16]+map[3][16]==0)begin
            replace = $urandom_range(0,3);
            map[replace][16] = 3;
            map[replace][17] = 3;
            map[replace][18] = 3;
            map[replace][19] = 3;
        end

   for(i=0;i<4;i=i+1)begin
    for(j=20;j<24;j=j+1)begin
        if(j%2==0)
        map[i][j] = $urandom_range(0,2);
    end
   end

   for(i0=0;i0<4;i0=i0+1)begin
    for(i=0;i<3;i=i+1)begin
            t_row[i] = $urandom_range(0,3);
            if(i0==t_row[i]&&i0<3)
            map[t_row[i]][24] = 2'b11;
    end
    for(j0=24;j0<28;j0=j0+1)begin
        if(map[i0][24]==2'b11)
        map[i0][j0] = 2'b11;
        if(map[i0][24]==2'b00)
        map[i0][26] = $urandom_range(0,2);
    end
   end

if(map[0][24]+map[1][24]+map[2][24]+map[3][24]==12)begin
            replace = $urandom_range(0,3);
            map[replace][24] = 0;
            map[replace][25] = 0;
            map[replace][26] = 0;
            map[replace][27] = 0;
        end
        if(map[0][24]+map[1][24]+map[2][24]+map[3][24]==0)begin
            replace = $urandom_range(0,3);
            map[replace][24] = 3;
            map[replace][25] = 3;
            map[replace][26] = 3;
            map[replace][27] = 3;
        end

   for(i=0;i<4;i=i+1)begin
    for(j=28;j<32;j=j+1)begin
        if(j%2==0)
        map[i][j] = $urandom_range(0,2);
    end
   end

   for(i0=0;i0<4;i0=i0+1)begin
    for(i=0;i<3;i=i+1)begin
            t_row[i] = $urandom_range(0,3);
            if(i0==t_row[i]&&i0<3)
            map[t_row[i]][32] = 2'b11;
    end
     for(j0=32;j0<36;j0=j0+1)begin
        if(map[i0][32]==2'b11)
        map[i0][j0] = 2'b11;
        if(map[i0][32]==2'b00)
        map[i0][34] = $urandom_range(0,2);
    end
   end

if(map[0][32]+map[1][32]+map[2][32]+map[3][32]==12)begin
            replace = $urandom_range(0,3);
            map[replace][32] = 0;
            map[replace][33] = 0;
            map[replace][34] = 0;
            map[replace][35] = 0;
        end
        if(map[0][32]+map[1][32]+map[2][32]+map[3][32]==0)begin
            replace = $urandom_range(0,3);
            map[replace][32] = 3;
            map[replace][33] = 3;
            map[replace][34] = 3;
            map[replace][35] = 3;
        end

for(i=0;i<4;i=i+1)begin
    for(j=36;j<40;j=j+1)begin
        if(j%2==0)
        map[i][j] = $urandom_range(0,2);
    end
   end

for(i0=0;i0<4;i0=i0+1)begin
    for(i=0;i<3;i=i+1)begin
            t_row[i] = $urandom_range(0,3);
            if(i0==t_row[i]&&i0<3)
            map[t_row[i]][40] = 2'b11;
    end
     for(j0=40;j0<44;j0=j0+1)begin
        if(map[i0][40]==2'b11)
        map[i0][j0] = 2'b11;
        if(map[i0][40]==2'b00)
        map[i0][42] = $urandom_range(0,2);
    end
   end

if(map[0][40]+map[1][40]+map[2][40]+map[3][40]==12)begin
            replace = $urandom_range(0,3);
            map[replace][40] = 0;
            map[replace][41] = 0;
            map[replace][42] = 0;
            map[replace][43] = 0;
        end
        if(map[0][40]+map[1][40]+map[2][40]+map[3][40]==0)begin
            replace = $urandom_range(0,3);
            map[replace][40] = 3;
            map[replace][41] = 3;
            map[replace][42] = 3;
            map[replace][43] = 3;
        end

   for(i=0;i<4;i=i+1)begin
    for(j=44;j<48;j=j+1)begin
        if(j%2==0)
        map[i][j] = $urandom_range(0,2);
    end
   end

   for(i0=0;i0<4;i0=i0+1)begin
    for(i=0;i<3;i=i+1)begin
            t_row[i] = $urandom_range(0,3);
            if(i0==t_row[i]&&i0<3)
            map[t_row[i]][48] = 2'b11;
    end
     for(j0=48;j0<52;j0=j0+1)begin
        if(map[i0][48]==2'b11)
        map[i0][j0] = 2'b11;
        if(map[i0][48]==2'b00)
        map[i0][50] = $urandom_range(0,2);
    end
   end

if(map[0][48]+map[1][48]+map[2][48]+map[3][48]==12)begin
            replace = $urandom_range(0,3);
            map[replace][48] = 0;
            map[replace][49] = 0;
            map[replace][50] = 0;
            map[replace][51] = 0;
        end
        if(map[0][48]+map[1][48]+map[2][48]+map[3][48]==0)begin
            replace = $urandom_range(0,3);
            map[replace][48] = 3;
            map[replace][49] = 3;
            map[replace][50] = 3;
            map[replace][51] = 3;
        end

   for(i=0;i<4;i=i+1)begin
    for(j=52;j<56;j=j+1)begin
        if(j%2==0)
        map[i][j] = $urandom_range(0,2);
    end
   end

   for(i0=0;i0<4;i0=i0+1)begin
    for(i=0;i<3;i=i+1)begin
            t_row[i] = $urandom_range(0,3);
            if(i0==t_row[i])
            map[t_row[i]][56] = 2'b11;
    end
     for(j0=56;j0<60;j0=j0+1)begin
        if(map[i0][56]==2'b11)
        map[i0][j0] = 2'b11;
        if(map[i0][56]==2'b00)
        map[i0][58] = $urandom_range(0,2);
    end
   end

if(map[0][56]+map[1][56]+map[2][56]+map[3][56]==12)begin
            replace = $urandom_range(0,3);
            map[replace][56] = 0;
            map[replace][57] = 0;
            map[replace][58] = 0;
            map[replace][59] = 0;
end
if(map[0][56]+map[1][56]+map[2][56]+map[3][56]==0)begin
            replace = $urandom_range(0,3);
            map[replace][56] = 3;
            map[replace][57] = 3;
            map[replace][58] = 3;
            map[replace][59] = 3;
end

for(i=0;i<4;i=i+1)begin
    for(j=60;j<64;j=j+1)begin
        if(j%2==0)
        map[i][j] = $urandom_range(0,2);
    end
end

   for(i=0;i<4;i=i+1)begin
    $write("\n");
    for(j=0;j<64;j=j+1)begin
        $write(map[i][j]);
    end
   end
   $write("\n");

end

endtask

task PASS;
begin
	$display ("----------------------------------------------------------------------------------------------------------------------");
	$display ("                                                  Congratulations!                						            ");
	$display ("                                           You have passed all patterns!          						            ");
	$display ("----------------------------------------------------------------------------------------------------------------------");
	$finish;
end
endtask

endmodule