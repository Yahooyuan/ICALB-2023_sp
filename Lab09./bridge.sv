module bridge(input clk, INF.bridge_inf inf);
//================================================================
// logic 
//================================================================
logic [63:0] data;
logic [7:0] address;
//================================================================
// state 
//================================================================
typedef enum logic [2:0] { IDLE , READ_ADDRESS , WAIT_READ_VALID , WRITE_ADDRESS , WAIT_WRITE_VALID ,WRITE_B } state;

state current_state;
state next_state;
//================================================================
//   FSM
//================================================================
always_ff @( posedge clk or negedge inf.rst_n ) begin
    if(!inf.rst_n) current_state <= IDLE;
    else current_state <= next_state;
end

always_comb begin
    case(current_state)
        IDLE: begin
            if(inf.C_in_valid && inf.C_r_wb == 1) next_state = READ_ADDRESS;
            else if(inf.C_in_valid && inf.C_r_wb == 0) next_state = WRITE_ADDRESS;
            else next_state = IDLE;
        end

        READ_ADDRESS:begin
            if(inf.AR_READY) next_state = WAIT_READ_VALID;
            else next_state = READ_ADDRESS;
        end
        
        WAIT_READ_VALID : begin
            if(inf.R_VALID) next_state = IDLE;
            else next_state = WAIT_READ_VALID;
        end

        WRITE_ADDRESS : begin
            if(inf.AW_READY) next_state = WAIT_WRITE_VALID;
            else next_state = WRITE_ADDRESS;
        end

        WAIT_WRITE_VALID:begin
            if(inf.W_READY) next_state = WRITE_B;
            else next_state = WAIT_WRITE_VALID;
        end

        WRITE_B:begin
            if(inf.B_VALID) next_state = IDLE;
            else next_state = WRITE_B;
        end

        default : next_state = IDLE;
    endcase
end

always_comb begin
    if(current_state==WRITE_B) inf.B_READY = 1;
    else inf.B_READY = 0;
end

always_ff @(posedge clk or negedge inf.rst_n) begin 
    if(!inf.rst_n) inf.C_data_r <=0;
    else if (inf.R_VALID) inf.C_data_r <= inf.R_DATA;
end


always_ff @(posedge clk) begin
    if(inf.C_in_valid && inf.C_r_wb == 0) data <= inf.C_data_w;
end

always_ff @(posedge clk) begin
    if(inf.C_in_valid) address <= inf.C_addr;
end

always_ff @(posedge clk or negedge inf.rst_n) begin 
    if(!inf.rst_n) inf.AR_VALID <= 0;
    else if (next_state == READ_ADDRESS) inf.AR_VALID <= 1;
    else inf.AR_VALID <= 0;
end

always_comb begin 
    if (current_state == READ_ADDRESS) inf.AR_ADDR = {6'b100000,address,3'b0};
    else inf.AR_ADDR = 0;
end

always_ff @(posedge clk or negedge inf.rst_n) begin 
    if(!inf.rst_n) inf.R_READY <= 0;
    else if (next_state == WAIT_READ_VALID) inf.R_READY <= 1;
    else inf.R_READY <= 0;
end

always_ff @(posedge clk or negedge inf.rst_n) begin 
    if(!inf.rst_n) inf.AW_VALID <= 0;
    else if (next_state == WRITE_ADDRESS) inf.AW_VALID <= 1;
    else inf.AW_VALID <= 0;
end

always_comb begin 
    if (current_state == WRITE_ADDRESS) inf.AW_ADDR = {6'b100000,address,3'b0};
    else inf.AW_ADDR = 0;
end

always_ff @(posedge clk or negedge inf.rst_n) begin 
    if(!inf.rst_n) inf.W_VALID <= 0;
    else if (next_state == WAIT_WRITE_VALID) inf.W_VALID <= 1;
    else inf.W_VALID <= 0;
end

always_comb begin 
    if (current_state == WAIT_WRITE_VALID) inf.W_DATA = data;
    else inf.W_DATA = 0;
end

always_ff @(posedge clk or negedge inf.rst_n) begin 
    if(!inf.rst_n) inf.C_out_valid <= 0;
    else if ((inf.R_VALID && current_state == WAIT_READ_VALID) || (inf.B_VALID && current_state == WRITE_B)) inf.C_out_valid <= 1;
    else inf.C_out_valid <= 0;
end

endmodule