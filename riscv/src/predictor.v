module predictor (
    // general
    input wire clk,
    input wire rst,
    input wire rdy,
    output reg chip_enable,
    input wire update_stat,
    input clear_flag_in,
    input wire [`AddrType] clear_pc_in,

    // iq
    // predict part
    input wire iq_predict_enable_in,
    // input wire [`AddrType] iq_pc_in,
    output reg iq_predict_result_enable_out,
    output reg iq_predict_result_out,
    // update stat part
    input wire iq_update_stat_enable_in,
    input wire iq_update_stat_result_in
    // input [`AddrType] wire iq_update_stat_pc_in,
  );
  reg [1: 0] stat;
  always @ (posedge clk) begin
    if (rst) begin
      iq_predict_result_enable_out <= `False;
      stat <= 2'b10;
    end
    else begin
      chip_enable <= rdy;
      if (rdy) begin
        if (update_stat) begin
          if (iq_predict_enable_in) begin
            iq_predict_result_enable_out <= `True;
            iq_predict_result_out <= stat[1];
          end
          if (iq_update_stat_enable_in) begin
            if (iq_update_stat_result_in) begin
              stat <= (stat == 2'b11 ? stat : stat + 1);
            end
            else begin
              stat <= (stat == 2'b00 ? stat : stat - 1);
            end
          end
        end
        else begin
          iq_predict_result_enable_out <= `False;
        end

      end
    end
  end

endmodule //predictor
