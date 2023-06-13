//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//
//   File Name   : CHECKER.sv
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
//`include "Usertype_PKG.sv"

module Checker(input clk, INF.CHECKER inf);
import usertype::*;

//covergroup Spec1 @();
//	
//       finish your covergroup here
//	
//	
//endgroup

//declare other cover group

//declare the cover group 
//Spec1 cov_inst_1 = new();
covergroup coverage1@(posedge clk iff inf.amnt_valid);
    coverpoint inf.D.d_money{
        bins a0 = {[0:12000]};
        bins a1 = {[12001:24000]};
        bins a2 = {[24001:36000]};
        bins a3 = {[36001:48000]};
        bins a4 = {[48001:60000]};
        option.at_least = 10;
    }
endgroup

covergroup coverage2 @(posedge clk iff inf.id_valid);
    coverpoint inf.D.d_id[0]{
        bins s0 [] = {[0:255]};
        option.auto_bin_max = 256;
        option.at_least = 2; 
    }  
endgroup

covergroup coverage3 @(posedge clk iff inf.act_valid);
    coverpoint inf.D.d_act[0]{
        bins t0 [] = (Buy,Return,Check,Deposit => Buy,Return,Check,Deposit);
        option.at_least = 10;
    }   
endgroup

covergroup coverage4@(posedge clk iff inf.item_valid);
    coverpoint inf.D.d_item[0]{
        bins b0[] = {Large,Medium,Small};
        option.at_least = 20;
    }
endgroup

covergroup coverage5@(posedge clk iff inf.out_valid);
    coverpoint inf.err_msg{
        bins c0[] = {INV_Not_Enough,Out_of_money,INV_Full,Wallet_is_Full,Wrong_ID,Wrong_Num,Wrong_Item,Wrong_act};
        option.at_least = 20;
    }
endgroup

covergroup coverage6@(posedge clk iff inf.out_valid);
    coverpoint inf.complete{
        bins d0[] = {0,1};
        option.at_least = 200;
    }
endgroup

coverage1 c1 = new();
coverage2 c2 = new();
coverage3 c3 = new();
coverage4 c4 = new();
coverage5 c5 = new();
coverage6 c6 = new();

//************************************ below assertion is to check your pattern ***************************************** 
//                                          Please finish and hand in it
// This is an example assertion given by TA, please write other assertions at the below
// assert_interval : assert property ( @(posedge clk)  inf.out_valid |=> inf.id_valid == 0)
// else
// begin
// 	$display("Assertion X is violated");
// 	$fatal; 
// end

//write other assertions
wire #(0.5) rst_reg = inf.rst_n;
assertion1 : assert property(@(negedge rst_reg) ((inf.out_valid === 0) && (inf.err_msg === 0) && (inf.complete === 0) && (inf.out_info === 0) && (inf.C_addr === 0) && (inf.C_data_w === 0) && (inf.C_in_valid === 0) && (inf.C_r_wb === 0) && (inf.C_out_valid === 0) && (inf.C_data_r === 0) && (inf.AR_VALID === 0) && (inf.AR_ADDR === 0) && (inf.R_READY === 0) && (inf.AW_VALID === 0) && (inf.AW_ADDR === 0) && (inf.W_VALID === 0) && (inf.W_DATA === 0) && (inf.B_READY === 0)))
else begin 
    $display("Assertion 1 is violated");
 	$fatal;
end

assertion2 : assert property(@(posedge clk) (inf.out_valid===1&&inf.complete===1) |->(inf.err_msg === 4'b0))
else begin
    $display("Assertion 2 is violated");
    $fatal;
end

assertion3 : assert property(@(posedge clk) (inf.out_valid===1&&inf.complete===0)|->(inf.out_info === 32'b0))
else begin
    $display("Assertion 3 is violated");
    $fatal;
end
// id_valid
assertion4_1 : assert property(@(posedge clk) (inf.id_valid===1)|=>(inf.id_valid===0))
else begin
    $display("Assertion 4 is violated");
    $fatal;
end
//act valid
assertion4_2 : assert property(@(posedge clk) (inf.act_valid===1)|=>(inf.act_valid===0))
else begin
    $display("Assertion 4 is violated");
    $fatal;
end
//amnt valid
assertion4_3 : assert property(@(posedge clk) (inf.amnt_valid===1)|=>(inf.amnt_valid===0))
else begin
    $display("Assertion 4 is violated");
    $fatal;
end
//item valid
assertion4_4 : assert property(@(posedge clk) (inf.item_valid===1)|=>(inf.item_valid===0))
else begin
    $display("Assertion 4 is violated");
    $fatal;
end
// num valid
assertion4_5 : assert property(@(posedge clk) (inf.num_valid===1)|=>(inf.num_valid===0))
else begin
    $display("Assertion 4 is violated");
    $fatal;
end

logic [2:0] only_oz;
assign only_oz = inf.id_valid+inf.act_valid+inf.amnt_valid+inf.item_valid+inf.num_valid;
assertion5 : assert property(@(posedge clk) (only_oz===1)||(only_oz===0))
else begin
    $display("Assertion 5 is violated");
    $fatal;
end

///////// gap 1~5 cycles//////////////////////////
///_|-|
Action action;
always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) action <= No_action;
    else if(inf.out_valid) action <= No_action;
	else if(inf.act_valid) action <= inf.D.d_act[0];
end
////////////Buyer or Seller///////////////////////////////////

//////////////////////////////////////////////////////////////
////Gap 1~5 
//Buy (valid uid->act->item_num->item_id->seller id)
//Buy (act-> item_num->item_id->seller id)
assertion6_1 : assert property(@(posedge clk) (action==No_action&&inf.id_valid===1)|->##[2:6](inf.act_valid===1))
else begin
    $display("Assertion 6 is violated");
    $fatal;
end
assertion6_2 : assert property(@(posedge clk) ((inf.D.d_act[0]==Buy||inf.D.d_act[0]==Return)&&inf.act_valid===1)|->##[2:6](inf.item_valid===1))
else begin
    $display("Assertion 6 is violated");
    $fatal;
end
logic [2:0] have_in;
assign have_in = inf.id_valid+inf.item_valid+inf.num_valid+inf.amnt_valid+inf.act_valid;
integer lat;
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) lat <= 0;
    else if(have_in==0) lat <= lat+1;
    else lat = 0;
end

logic last_in;

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) last_in <= 0;
    else begin
        if(inf.out_valid===1) last_in <= 0;
        else if(action !== No_action)begin
            case(action)
            Buy:begin
                if(inf.id_valid===1) last_in <= 1;
            end
            Check:begin
                if(lat===5&&inf.id_valid===0) last_in<=1;
                else if(inf.id_valid) last_in<=1;
            end
            Deposit:begin
                if(inf.amnt_valid) last_in<=1;
            end
            Return:begin
                if(inf.id_valid) last_in<=1;
            end
            endcase
        end
    end
end

assertion6_2_1 :assert property(@(posedge clk) (last_in)|->(inf.id_valid===0&&inf.act_valid===0&&inf.item_valid===0&&inf.num_valid===0&&inf.amnt_valid===0))
else begin
    $display("Assertion 6 is violated");
    $fatal;
end

assertion6_3 : assert property(@(posedge clk) ((action==Buy||action==Return)&&inf.item_valid===1)|->##[2:6](inf.num_valid===1))
else begin
    $display("Assertion 6 is violated");
    $fatal;
end
assertion6_4 : assert property(@(posedge clk) ((action==Buy||action==Return)&&inf.num_valid===1)|->##[2:6](inf.id_valid===1))
else begin
    $display("Assertion 6 is violated");
    $fatal;
end
assertion6_5 : assert property(@(posedge clk iff (action==Buy||action==Return||action==Check)) (inf.amnt_valid===0))
else begin
    $display("Assertion 6 is violated");
    $fatal;
end
/// Check // (uid)->act->(uid)
assertion6_6 : assert property(@(posedge clk) (inf.D.d_act[0]==Check&&inf.act_valid)|->##[2:6]((inf.item_valid===0)&&(inf.amnt_valid===0)&&(inf.act_valid===0)&&(inf.num_valid===0)))
else begin
    $display("Assertion 6 is violated");
    $fatal;
end
/// Deposit (uid)->act amnt 
assertion6_7 : assert property(@(posedge clk) (inf.D.d_act[0]==Deposit&&inf.act_valid)|->##[2:6](inf.amnt_valid===1))
else begin
    $display("Assertion 6 is violated");
    $fatal;
end
///Return
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
assertion7 : assert property(@(posedge clk) (inf.out_valid===1)|=>(inf.out_valid===0))
else begin
    $display("Assertion 7 is violated");
    $fatal;
end

assertion8 : assert property(@(posedge clk) (inf.out_valid===1)|-> ##[2:10]((inf.id_valid===1)||(inf.act_valid===1)))
else begin
    $display("Assertion 8 is violated");
    $fatal;
end
//Buy 
assertion9_1 : assert property(@(posedge clk) (action==Buy&&inf.id_valid===1)|->##[1:10000](inf.out_valid===1))
else begin
    $display("Assertion 9 is violated");
    $fatal;
end
//Check
assertion9_2 : assert property(@(posedge clk) (inf.D.d_act[0]==Check&&inf.act_valid===1)|->##[1:10000](inf.out_valid===1))
else begin
    $display("Assertion 9 is violated");
    $fatal;
end
//Deposit
assertion9_4 : assert property(@(posedge clk) (action==Deposit&&inf.amnt_valid===1)|->##[1:10000](inf.out_valid===1))
else begin
    $display("Assertion 9 is violated");
    $fatal;
end
//Return
assertion9_5 : assert property(@(posedge clk) (action==Return&&inf.id_valid===1)|->##[1:10000](inf.out_valid===1))
else begin
    $display("Assertion 9 is violated");
    $fatal;
end
endmodule

