`include "./decoder.v"

module top_module();
  reg [31: 0]in_instr;
  wire[6: 0] opcode;
  wire[4: 0] rd;
  wire[4: 0] rs1;
  wire[4: 0] rs2;
  wire[2: 0] funct3;
  wire[6: 0] funct7;
  wire[31: 0] imm;
  decoder de(in_instr,
             opcode,
             rd,
             rs1,
             rs2,
             funct3,
             funct7,
             imm);
  initial
  begin
    in_instr = 32'h00020137; //          	lui	sp,0x20
    #1;
    $display("instr = %b\nopcode = %b\nrd = %d\nrs1 = %d\nrs2 = %d\nfunct3 = %b\nfunct7 = %b\nimm = %h\n\n\n", in_instr, opcode, rd, rs1, rs2, funct3, funct7, imm);
    in_instr = 32'h040010ef; //          	jal	ra,1044
    #1;
    $display("instr = %b\nopcode = %b\nrd = %d\nrs1 = %d\nrs2 = %d\nfunct3 = %b\nfunct7 = %b\nimm = %h\n\n\n", in_instr, opcode, rd, rs1, rs2, funct3, funct7, imm);
  end
endmodule
