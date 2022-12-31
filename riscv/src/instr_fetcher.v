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
  integer i;
  reg [`AddrType] pc;
  // direct-mapped icache
  reg ic_vaild [`ICacheArrayRange];
  reg [`InstrType] ic_instr[`ICacheArrayRange];
  reg [`ICacheTagRange] ic_tag [`ICacheArrayRange];
  wire instr_in_cache;
  wire [`InstrType] cache_instr;

  assign instr_in_cache = ic_vaild[pc[`ICacheIdxRange]] && ic_tag[pc[`ICacheIdxRange]] == pc[`ICacheTagRange];
  assign cache_instr = instr_in_cache ? ic_instr[pc[`ICacheIdxRange]] : `ZeroWord;
  always @ (posedge clk) begin
    if (rst) begin
      chip_enable <= `False;
      pc <= `ZeroWord;
      // clear icache
      for (i = 0;i < `ICacheLen;i = i + 1) begin
        ic_vaild[i] = `False;
      end
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
              if (instr_in_cache) begin
                iq_result_enable_out <= `True;
                iq_instr_out <= cache_instr;
                iq_pc_out <= pc;
              end
              else begin
                mc_fetch_enable_out <= `True;
                mc_addr_out <= pc;
              end
            end
            if (mc_result_enable_in) begin
              iq_result_enable_out <= `True;
              iq_instr_out <= mc_data_in;
              iq_pc_out <= mc_addr_out;
              if (`CACHE_VAILD_FLAG)
                ic_vaild[mc_addr_out[`ICacheIdxRange]] = `True;
              ic_tag[mc_addr_out[`ICacheIdxRange]] = mc_addr_out[`ICacheTagRange];
              ic_instr[mc_addr_out[`ICacheIdxRange]] = mc_data_in;
            end
          end
        end
      end
    end
  end

endmodule //instr_fetcher
