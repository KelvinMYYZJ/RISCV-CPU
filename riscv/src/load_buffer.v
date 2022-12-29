`include "defines.v"

module load_buffer(
    input clk,
    input rst,
    input rdy,
    output reg chip_enable,
    input update_stat,
    input clear_flag_in,
    input wire [`AddrType] clear_pc_in,

    // rs
    output reg rs_full_out,
    input wire rs_load_enable_in,
    input wire [`Func3Type] rs_func3_in,
    input wire [`AddrType] rs_addr_in,
    input wire [`IqAddrType] rs_pos_in_iq_in,

    // mem ctrl
    output reg mc_fetch_enable_out,
    output reg [`AddrType] mc_addr_out,
    // 0(Byte) or 1(Halfword) or 3(Word)
    output reg [1: 0] mc_len_out,
    input wire mc_result_enable_in,
    input wire [`WordType] mc_data_in,

    // write instr queue part
    output reg iq_write_enable_out,
    output reg [`IqAddrType] iq_write_idx_out,
    output reg iq_write_result_enable_out,
    output reg [`WordType] iq_write_result_out,
    output reg iq_write_need_cdb_enable_out,
    output reg iq_write_need_cdb_out,
    output reg iq_write_ready_enable_out,
    output reg iq_write_ready_out
  );
  localparam DataLoadStatIdle = 0;
  localparam DataLoadStatLoading = 1;
  reg load_stat;
  reg [`IqAddrType] pos_in_iq;
  reg is_unsigned;
  always @ (posedge clk) begin
    if (rst) begin
      chip_enable <= `False;
      load_stat <= DataLoadStatIdle;
      rs_full_out <= `False;
      mc_fetch_enable_out <= `False;
      iq_write_enable_out <= `False;
      iq_write_result_enable_out <= `False;
      iq_write_need_cdb_enable_out <= `False;
      iq_write_ready_enable_out <= `False;
    end
    else begin
      chip_enable <= rdy;
      if (rdy) begin
        if (!update_stat) begin
          if (clear_flag_in) begin
            load_stat <= DataLoadStatIdle;
          end
          else begin

          end
        end
        else begin
          iq_write_enable_out <= `False;
          mc_fetch_enable_out <= `False;
          if (load_stat == DataLoadStatIdle && rs_load_enable_in) begin
            load_stat <= DataLoadStatLoading;
            rs_full_out <= `True;
            mc_fetch_enable_out <= `True;
            mc_addr_out <= rs_addr_in;
            mc_len_out <= ((rs_func3_in & 3) == 2) ? 3 : rs_func3_in & 3;
            pos_in_iq <= rs_pos_in_iq_in;
            is_unsigned <= rs_func3_in & 4;
          end
        end

        if (load_stat == DataLoadStatLoading && mc_result_enable_in) begin
          rs_full_out <= `False;
          load_stat <= DataLoadStatIdle;
          iq_write_enable_out <= `True;
          iq_write_idx_out <= pos_in_iq;
          iq_write_result_enable_out <= `True;
          case (mc_len_out)
            // Btye
            0 : iq_write_result_out <= {{24{is_unsigned ? `False : mc_data_in[7]}}, mc_data_in[7 : 0]};
            // HalfWord
            1 : iq_write_result_out <= {{16{is_unsigned ? `False : mc_data_in[15]}}, mc_data_in[15 : 0]};
            // Word
            3 : iq_write_result_out <= mc_data_in;
          endcase
          // iq_write_result_out <= result;
          // $display("load success!, result : %h", mc_data_in);
          iq_write_ready_enable_out <= `True;
          iq_write_ready_out <= `True;
          iq_write_need_cdb_enable_out <= `True;
          iq_write_need_cdb_out <= `True;
        end
      end
    end
  end
endmodule
