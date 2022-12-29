`include "defines.v"
module updater
  (
    input clk,
    input rst,
    input rdy,
    output reg chip_enable,

    output reg update_stat
  );
  always @ (posedge clk) begin
    if (rst) begin
      chip_enable <= `False;
      update_stat <= `False;
    end
    else begin
      chip_enable <= rdy;
      if (rdy) update_stat <= ~update_stat;
    end
  end
endmodule //updater
