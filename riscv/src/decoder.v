`include "defines.v"

module decoder (
    // general
    input clk,
    input rst,
    input rdy,
    output reg chip_enable,
    input update_stat,

    // instr_queue
    input wire decode_ebable,
    input wire[`InstrType] instr,
    output reg result_enable_out,
    output reg[`OpcodeType] opcode,
    output reg[`RegAddrType] rd,
    output reg[`RegAddrType] rs1,
    output reg[`RegAddrType] rs2,
    output reg[`Func3Type] func3,
    output reg[`Func7Type] func7,
    output reg[`WordType] imm
  );
  always @ (posedge clk) begin
    if (rst) begin
      chip_enable <= `False;
    end
    else begin
      chip_enable <= rdy;
    end
  end

  always @(posedge clk) begin
    if (chip_enable && !update_stat) begin
      result_enable_out <= `False;
      if (decode_ebable) begin
        rd <= 0;
        rs1 <= 0;
        rs2 <= 0;
        func3 <= 0;
        func7 <= 0;
        imm <= 0;
        result_enable_out <= `True;
        opcode <= instr[6: 0];
        rd <= instr[11: 7];
        rs1 <= instr[19: 15];
        rs2 <= instr[24: 20];
        func3 <= instr[14: 12];
        func7 <= instr[31: 25];
        case (instr[6: 0])
          `Opcode_CalcI: begin
            case (func3)
              1, 5:
                // I type
                imm <= {{27{1'b0}}, instr[24: 20]};
              default:
                // RS type
                imm <= {{20{instr[31]}}, instr[31: 20]};
            endcase
          end
          `Opcode_LoadMem, `Opcode_JALR:
            // I type
            imm <= {{20{instr[31]}}, instr[31: 20]};
          `Opcode_Calc:
            // R type
            ; // no imm
          `Opcode_StoreMem:
            // S type
            imm <= {{20{instr[31]}}, instr[31: 25], instr[11: 7]};
          `Opcode_StoreMem:
            // B type
            imm <= {{20{instr[31]}}, { instr[7]}, instr[30: 25], instr[11: 8], {1'b0}};
          `Opcode_JAL:
            // J type
            imm <= {{12{instr[31]}}, instr[19: 12], {instr[20]}, instr[30: 21], {1'b0}};
          `Opcode_LUI, `Opcode_AUIPC:
            // U type
            imm <= {instr[31: 12], {12{1'b0}}};
        endcase
      end
    end
  end
endmodule
