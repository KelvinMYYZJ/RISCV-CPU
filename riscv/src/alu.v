`include "defines.v"
module alu (
    //general
    input clk,
    input rst,
    input rdy,
    output reg chip_enable,
    input update_stat,
    input clear_flag_in,
    input wire [`AddrType] clear_pc_in,

    // instr queue
    output reg iq_write_enable_out,
    output reg [`IqAddrType] iq_write_idx_out,
    output reg iq_write_result_enable_out,
    output reg [`WordType] iq_write_result_out,
    output reg iq_write_need_cdb_enable_out,
    output reg iq_write_need_cdb_out,
    output reg iq_write_ready_enable_out,
    output reg iq_write_ready_out,

    //rs
    output wire rs_full_out,
    input wire rs_calc_enable_in,
    input wire [`CalcCodeType] rs_calc_code_in,
    input wire [`WordType] rs_lhs_in,
    input wire [`WordType] rs_rhs_in,
    input wire [`IqAddrType] rs_pos_in_iq_in
  );
  reg have_result;
  reg [`WordType] result;
  reg [`IqAddrType] pos_in_iq;
  assign rs_full_out = have_result;
  always @ (posedge clk) begin
    if (rst) begin
      chip_enable <= `False;
      have_result <= `False;
    end
    else begin
      chip_enable <= rdy;
      if (rdy) begin
        if (update_stat) begin
          // deal the input from rs
          if (rs_calc_enable_in) begin
            have_result <= `True;
            pos_in_iq <= rs_pos_in_iq_in;
            // $display("calc : op =  %h, lhs = %h, rsh = %h", rs_calc_code_in, rs_lhs_in, rs_rhs_in);
            case (rs_calc_code_in)
              0: result <= rs_lhs_in + rs_rhs_in;
              1: result <= rs_lhs_in - rs_rhs_in;
              2: result <= rs_lhs_in << rs_rhs_in;
              3: result <= ($signed(rs_lhs_in) < $signed(rs_rhs_in)) ? 1 : 0;
              4: result <= (rs_lhs_in < rs_rhs_in) ? 1 : 0;
              5: result <= (rs_lhs_in ^ rs_rhs_in);
              6: result <= rs_lhs_in >> rs_rhs_in;
              7: result <= $signed(rs_lhs_in) >> rs_rhs_in;
              8: result <= rs_lhs_in | rs_rhs_in;
              9: result <= rs_lhs_in & rs_rhs_in;
              10: result <= rs_lhs_in == rs_rhs_in ? 1 : 0;
              11: result <= rs_lhs_in != rs_rhs_in ? 1 : 0;
              12: result <= $signed(rs_lhs_in) < $signed(rs_rhs_in) ? 1 : 0;
              13: result <= $signed(rs_lhs_in) >= $signed(rs_rhs_in) ? 1 : 0;
              14: result <= rs_lhs_in < rs_rhs_in ? 1 : 0;
              15: result <= rs_lhs_in >= rs_rhs_in ? 1 : 0;
            endcase
          end
        end
        else begin
          iq_write_enable_out <= `False;
          if (!clear_flag_in && have_result) begin
            have_result <= `False;
            iq_write_enable_out <= `True;
            iq_write_idx_out <= pos_in_iq;
            iq_write_result_enable_out <= `True;
            iq_write_result_out <= result;
            iq_write_ready_enable_out <= `True;
            iq_write_ready_out <= `True;
            if (rs_calc_code_in < 10) begin
              iq_write_need_cdb_enable_out <= `True;
              iq_write_need_cdb_out <= `True;
            end
            else
              iq_write_need_cdb_enable_out <= `False;
          end
        end
      end
    end
  end
endmodule //alu
