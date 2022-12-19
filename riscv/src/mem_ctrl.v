`include "defines.v"
module mem_ctrl (
    // general
    input wire clk,
    input wire rst,
    input wire rdy,
    output reg chip_enable,
    input wire update_stat,
    input clear_flag_in,
    input wire [`AddrType] clear_pc_in,

    // instr fetcher
    input wire if_fetch_enable_in,
    input wire [`AddrType] if_addr_in,
    output reg if_result_enable_out,
    output reg [`WordType] if_data_out,

    // load buffer
    input wire lb_fetch_enable_in,
    input wire [`AddrType] lb_addr_in,
    // 0(Byte) or 1(Halfword) or 3(Word)
    input wire [1: 0] lb_len_in,
    output reg lb_result_enable_out,
    output reg [`WordType] lb_data_out,

    // instr queue
    input wire iq_store_enable_in,
    input wire [`AddrType] iq_addr_in,
    // 0(Byte) or 1(Halfword) or 3(Word)
    input wire [1: 0] iq_len_in,
    input wire [`WordType] iq_data_in,
    output reg iq_result_enable_out,

    // ram
    // output reg ram_enable,
    output reg ram_rw_select_out,                     // read/write select (read: 1, write: 0)
    output reg [`AddrType] ram_addr_out,
    output reg [`ByteType] ram_data_out,
    input wire [`ByteType] ram_data_in
  );
  localparam idle = 0;
  localparam deal_if = 1;
  localparam deal_lb = 2;
  localparam deal_iq = 3;
  reg [1: 0] stat;

  // which byte is io now
  reg [1: 0] ram_io_stat;
  always @ (posedge clk) begin
    if (rst == `True) begin
      chip_enable <= `False;
      // ram_enable <= `False;
      ram_addr_out <= `MaxWord;
      ram_rw_select_out <= 0;
      stat <= idle;
    end
    else begin
      chip_enable <= rdy;
    end
  end

  always @ (posedge clk) begin
    if (chip_enable) begin
      if (clear_flag_in) begin
        stat <= idle;
        // ram_enable <= `False;
        ram_addr_out <= `MaxWord;
      end
      else begin
        if (!update_stat) begin
          if_result_enable_out <= `False;
          lb_result_enable_out <= `False;
          iq_result_enable_out <= `False;
          if (stat == idle) begin
            if (iq_store_enable_in == `True) begin
              stat <= deal_iq;
              stat <= deal_if;
              ram_io_stat <= 0;
              ram_addr_out <= iq_addr_in;
              ram_rw_select_out <= 1;
            end
            else if (if_fetch_enable_in == `True) begin
              stat <= deal_if;
              ram_io_stat <= 0;
              ram_addr_out <= if_addr_in;
              ram_rw_select_out <= 0;
            end
            else if (lb_fetch_enable_in == `True) begin
              stat <= deal_lb;
              ram_io_stat <= 0;
              ram_addr_out <= lb_addr_in;
              ram_rw_select_out <= 0;
            end
          end
        end

        if (stat == deal_if) begin
          ram_io_stat <= ram_io_stat + 1;
          ram_addr_out <= ram_addr_out + 1;
          case (ram_io_stat)
            0: if_data_out[7 : 0] <= ram_data_in;
            1: if_data_out[15 : 8] <= ram_data_in;
            2: if_data_out[23 : 16] <= ram_data_in;
            3: if_data_out[31 : 24] <= ram_data_in;
          endcase
          if (ram_io_stat == 3) begin
            // ram_enable <= `False;
            ram_addr_out <= `MaxWord;
            stat <= idle;
            if_result_enable_out <= `True;
          end
        end

        if (stat == deal_lb) begin
          ram_io_stat <= ram_io_stat + 1;
          ram_addr_out <= ram_addr_out + 1;
          case (ram_io_stat)
            0: lb_data_out[7 : 0] <= ram_data_in;
            1: lb_data_out[15 : 8] <= ram_data_in;
            2: lb_data_out[23 : 16] <= ram_data_in;
            3: lb_data_out[31 : 24] <= ram_data_in;
          endcase
          if (ram_io_stat == lb_len_in) begin
            // ram_enable <= `False;
            ram_addr_out <= `MaxWord;
            stat <= idle;
            lb_result_enable_out <= `True;
          end
        end

        if (stat == deal_iq) begin
          ram_io_stat <= ram_io_stat + 1;
          ram_addr_out <= ram_addr_out + 1;
          case (ram_io_stat)
            0: ram_data_out <= iq_data_in[7 : 0];
            1: ram_data_out <= iq_data_in[15 : 8];
            2: ram_data_out <= iq_data_in[23 : 16];
            3: ram_data_out <= iq_data_in[31 : 24];
          endcase
          if (ram_io_stat == iq_len_in) begin
            // ram_enable <= `False;
            ram_addr_out <= `MaxWord;
            stat <= idle;
            iq_result_enable_out <= `True;
          end
        end
      end
    end
  end

endmodule //mem_ctrl

