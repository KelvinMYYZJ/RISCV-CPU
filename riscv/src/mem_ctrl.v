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
    // commit storing
    input wire iq_store_enable_in,
    input wire [`AddrType] iq_addr_in,
    // 0(Byte) or 1(Halfword) or 3(Word)
    input wire [1: 0] iq_len_in,
    input wire [`WordType] iq_data_in,
    output reg iq_result_enable_out,
    
    // commit io reading
    input wire iq_io_fetch_enable_in,
    input wire [`AddrType] iq_io_addr_in,
    // 0(Byte) or 1(Halfword) or 3(Word)
    input wire [1: 0] iq_io_len_in,
    output reg iq_io_result_enable_out,
    output reg [`WordType] iq_io_data_out,

    // ram
    // output reg ram_enable,
    // read/write select (read: 1, write: 0)
    output reg ram_rw_select_out,
    output reg [`AddrType] ram_addr_out,
    output reg [`ByteType] ram_data_out,
    input wire [`ByteType] ram_data_in,

    // uart
    input wire uart_full_in
  );
  reg stall_for_io;
  reg [2: 0]stall_counter;
  wire accessing_io_flag = (iq_addr_in & 32'h00030000) == 32'h00030000;
  wire uart_ban_store_flag = (1 ^ `SIM) && (uart_full_in || stall_for_io) && accessing_io_flag;
  localparam idle = 0;
  localparam deal_if = 1;
  localparam deal_lb = 2;
  localparam deal_iq = 3;
  localparam deal_iq_io = 4;
  reg [2: 0] stat;
  reg if_pending;
  reg lb_pending;
  reg iq_pending;
  reg iq_io_pending;
  // which byte is io now
  reg [2: 0] ram_io_stat;
  always @ (posedge clk) begin
    if (rst == `True) begin
      chip_enable <= `False;
      // ram_enable <= `False;
      // ram_addr_out <= `MaxWord;
      ram_addr_out <= `ZeroWord;
      ram_rw_select_out <= 0;
      stat <= idle;
      stall_for_io <= `False;
    end
    else begin
      chip_enable <= rdy;
      if (rdy) begin
        if (stall_for_io) begin
          stall_counter <= stall_counter - 1;
          if (!stall_counter)
            stall_for_io <= `False;
        end
        if (clear_flag_in) begin
          stat <= idle;
          ram_addr_out <= `ZeroWord;
          ram_rw_select_out <= 0;
          iq_pending <= `False;
          if_pending <= `False;
          lb_pending <= `False;
        end
        else begin
          if (iq_store_enable_in) iq_pending <= `True;
          if (if_fetch_enable_in) if_pending <= `True;
          if (lb_fetch_enable_in) lb_pending <= `True;
          if (iq_io_fetch_enable_in) iq_io_pending <= `True;
          if (!update_stat) begin
            if_result_enable_out <= `False;
            lb_result_enable_out <= `False;
            iq_io_result_enable_out <= `False;
            iq_result_enable_out <= `False;
            if (stat == idle) begin
              if ((iq_store_enable_in || iq_pending) && !uart_ban_store_flag) begin
                iq_pending <= `False;
                stat <= deal_iq;
                ram_io_stat <= 0;
                ram_addr_out <= iq_addr_in;
                ram_data_out <= iq_data_in[7 : 0];
                ram_rw_select_out <= 1;
              end
              else if (if_fetch_enable_in || if_pending) begin
                if_pending <= `False;
                stat <= deal_if;
                ram_io_stat <= 0;
                ram_addr_out <= if_addr_in;
                ram_rw_select_out <= 0;
              end
              else if (iq_io_fetch_enable_in || iq_io_pending) begin
                iq_io_data_out <= `ZeroWord;
                iq_io_pending <= `False;
                stat <= deal_iq_io;
                ram_io_stat <= 0;
                ram_addr_out <= iq_io_addr_in;
                ram_rw_select_out <= 0;
              end
              else if (lb_fetch_enable_in || lb_pending) begin
                lb_pending <= `False;
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
              1: if_data_out[7 : 0] <= ram_data_in;
              2: if_data_out[15 : 8] <= ram_data_in;
              3: if_data_out[23 : 16] <= ram_data_in;
              4: if_data_out[31 : 24] <= ram_data_in;
            endcase
            if (ram_io_stat == 3) ram_addr_out <= `ZeroWord;
            if (ram_io_stat - 1 == 3) begin
              // ram_enable <= `False;
              // ram_addr_out <= `MaxWord;
              ram_addr_out <= `ZeroWord;
              stat <= idle;
              if_result_enable_out <= `True;
            end
          end

          if (stat == deal_lb) begin
            ram_io_stat <= ram_io_stat + 1;
            ram_addr_out <= ram_addr_out + 1;
            case (ram_io_stat)
              1: lb_data_out[7 : 0] <= ram_data_in;
              2: lb_data_out[15 : 8] <= ram_data_in;
              3: lb_data_out[23 : 16] <= ram_data_in;
              4: lb_data_out[31 : 24] <= ram_data_in;
            endcase
            if (ram_io_stat == lb_len_in) ram_addr_out <= `ZeroWord;
            if (ram_io_stat - 1 == lb_len_in) begin
              // ram_enable <= `False;
              // ram_addr_out <= `MaxWord;
              ram_addr_out <= `ZeroWord;
              stat <= idle;
              lb_result_enable_out <= `True;
            end
          end

          if (stat == deal_iq_io) begin
            ram_io_stat <= ram_io_stat + 1;
            ram_addr_out <= ram_addr_out + 1;
            case (ram_io_stat)
              1: iq_io_data_out[7 : 0] <= ram_data_in;
              2: iq_io_data_out[15 : 8] <= ram_data_in;
              3: iq_io_data_out[23 : 16] <= ram_data_in;
              4: iq_io_data_out[31 : 24] <= ram_data_in;
            endcase
            if (ram_io_stat == iq_io_len_in) ram_addr_out <= `ZeroWord;
            if (ram_io_stat - 1 == iq_io_len_in) begin
              // ram_enable <= `False;
              // ram_addr_out <= `MaxWord;
              ram_addr_out <= `ZeroWord;
              stat <= idle;
              iq_io_result_enable_out <= `True;
            end
          end

          if (stat == deal_iq) begin
            ram_io_stat <= ram_io_stat + 1;
            ram_addr_out <= ram_addr_out + 1;
            case (ram_io_stat)
              0: ram_data_out <= iq_data_in[15 : 8];
              1: ram_data_out <= iq_data_in[23 : 16];
              2: ram_data_out <= iq_data_in[31 : 24];
            endcase
            if (ram_io_stat == iq_len_in) begin
              // ram_enable <= `False;
              ram_rw_select_out <= 0;
              ram_addr_out <= `ZeroWord;
              // ram_addr_out <= `MaxWord;
              stat <= idle;
              iq_result_enable_out <= `True;
              if (accessing_io_flag) begin
                stall_for_io <= `True;
                stall_counter <= 1;
              end
            end
          end
        end
      end
    end
  end

endmodule //mem_ctrl

