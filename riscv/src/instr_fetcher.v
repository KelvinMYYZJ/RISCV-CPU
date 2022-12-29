`include "defines.v"

module instr_fetcher
  (
    // general
    input clk,
    input rst,
    input rdy,
    output reg chip_enable,
    input update_stat,
    input clear_flag_in,
    input wire [`AddrType] clear_pc_in,

    // mem ctrl
    output reg mc_fetch_enable_out,
    output reg [`AddrType] mc_addr_out,
    input wire mc_result_enable_in,
    input wire [`WordType] mc_data_in,

    // instr queue
    // write pc reg
    input wire iq_write_pc_sig_in,
    input wire [`AddrType] iq_write_pc_val_in,

    // fetch
    input wire iq_fetch_enable_in,
    output reg [`InstrType] iq_instr_out,
    output reg [`AddrType] iq_pc_out,
    output reg iq_result_enable_out
  );
  reg [`AddrType] pc;
  // reg vaild
  // reg [`InstrType] icache[];
  always @ (posedge clk) begin
    if (rst) begin
      chip_enable <= `False;
      pc <= `ZeroWord;
      // clear icache
    end
    else begin
      chip_enable <= rdy;
      if (rdy) begin
        if (update_stat) begin
          if (iq_write_pc_sig_in)
            pc <= iq_write_pc_val_in;
        end
        else begin
          mc_fetch_enable_out <= `False;
          iq_result_enable_out <= `False;
          if (clear_flag_in) begin
            pc <= clear_pc_in;
          end
          else begin
            if (iq_fetch_enable_in) begin
              mc_fetch_enable_out <= `True;
              mc_addr_out <= pc;
            end
            if (mc_result_enable_in) begin
              iq_result_enable_out <= `True;
              iq_instr_out <= mc_data_in;
              iq_pc_out <= mc_addr_out;
            end
          end
        end
      end
    end
  end

endmodule //instr_fetcher
