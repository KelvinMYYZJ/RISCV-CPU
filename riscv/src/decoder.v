`define Opcode_LoadMem 7'b0000011   //ImmType = I
`define Opcode_StoreMem 7'b0100011  //ImmType = S
`define Opcode_Calc 7'b0110011      //ImmType = R
`define Opcode_CalcI 7'b0010011     //ImmType = I or RS
`define Opcode_BControl 7'b1100011  //ImmType = B
`define Opcode_JAL 7'b1101111       //ImmType = J
`define Opcode_JALR 7'b1100111      //ImmType = I
`define Opcode_LUI 7'b0110111       //ImmType = U
`define Opcode_AUIPC 7'b0010111     //ImmType = U
module decoder (input wire[31: 0] instr,
                  output reg[6: 0] opcode,
                  output reg[4: 0] rd,
                  output reg[4: 0] rs1,
                  output reg[4: 0] rs2,
                  output reg[2: 0] funct3,
                  output reg[6: 0] funct7,
                  output reg[31: 0] imm);
  always @(instr) begin
    opcode <= instr[6: 0];
    rd <= instr[11: 7];
    rs1 <= instr[19: 15];
    rs2 <= instr[24: 20];
    funct3 <= instr[14: 12];
    funct7 <= instr[31: 25];
    case (opcode)
      `Opcode_CalcI:
      begin
        case (funct3)
          1, 5: // I type
            imm <= {{27{1'b0}}, instr[24: 20]};
          default: // RS type
            imm <= {{20{instr[31]}}, instr[31: 20]};
        endcase
      end
      `Opcode_LoadMem, `Opcode_JALR: // I type
        imm <= {{20{instr[31]}}, instr[31: 20]};
      `Opcode_Calc:     // R type
        ;                 // no imm
      `Opcode_StoreMem: // S type
        imm <= {{20{instr[31]}}, instr[31: 25], instr[11: 7]};
      `Opcode_StoreMem: // B type
        imm <= {{20{instr[31]}}, { instr[7]}, instr[30: 25], instr[11: 8], {1'b0}};
      `Opcode_JAL: // J type
        imm <= {{12{instr[31]}}, instr[19: 12], {instr[20]}, instr[30: 25], instr[24: 21], {1'b0}};
      `Opcode_LUI, `Opcode_AUIPC: // U type
        imm <= {instr[31: 12], {12{1'b0}}};
    endcase
  end
endmodule
