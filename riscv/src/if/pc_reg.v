`include "defines.v"
;
module pc_reg(
input clk,
      input rst,
      input rdy,
      output reg chip_enable,

    output reg chip_enable,
    input update_stat,

    // fecher
    input wire if_write_sig_in,
    input wire [`AddrType] if_write_pc_in,
    output reg [`AddrType] pc_out,
  );
  always @ (posedge clk) begin
    if (rst) begin
      chip_enable <= `False;
    end
    else begin
      chip_enable <= rdy;
    end
  end

  always @ (posedge clk) begin
    if (chip_enable && write_sig ) begin
      chip_enable <= rdy;

    end
  end

endmodule
