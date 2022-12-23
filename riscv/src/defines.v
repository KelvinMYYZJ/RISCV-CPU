`define DEBUGFLAG 0
`define SHOWCOMMITLAG 0

`define Opcode_LoadMem 7'b0000011   //ImmType = I
`define Opcode_StoreMem 7'b0100011  //ImmType = S
`define Opcode_Calc 7'b0110011      //ImmType = R
`define Opcode_CalcI 7'b0010011     //ImmType = I or RS
`define Opcode_BControl 7'b1100011  //ImmType = B
`define Opcode_JAL 7'b1101111       //ImmType = J
`define Opcode_JALR 7'b1100111      //ImmType = I
`define Opcode_LUI 7'b0110111       //ImmType = U
`define Opcode_AUIPC 7'b0010111     //ImmType = U
`define CalcCodeAdd 0
`define CalcCodeSub 1
`define CalcCodeSll 2
`define CalcCodeSlt 3
`define CalcCodeSltu 4
`define CalcCodeXor 5
`define CalcCodeSrl 6
`define CalcCodeSra 7
`define CalcCodeOr 8
`define CalcCodeAnd 9
`define CalcCodeEq 10
`define CalcCodeNeq 11
`define CalcCodeLt 12
`define CalcCodeGe 13
`define CalcCodeLtu 14
`define CalcCodeGeu 15
`define ZeroWord 32'h00000000
`define MaxWord 32'hFFFFFFFF

`define InstrLen 32
`define AddrLen 32
`define RegAddrLen 5
`define RegLen 32
`define WordLen 32
`define ByteLen 8
`define OpcodeLen 7
`define Func7Len 7
`define Func3Len 3
`define CalcCodeLen 4

`define InstrType `InstrLen-1:0
`define AddrType `AddrLen-1:0
`define RegAddrType `RegAddrLen-1:0
`define RegType `RegLen-1:0
`define WordType `WordLen-1:0
`define ByteType `ByteLen-1:0
`define OpcodeType `OpcodeLen-1:0
`define Func7Type `Func7Len-1:0
`define Func3Type `Func3Len-1:0
`define CalcCodeType `CalcCodeLen-1:0

`define RegNum 2**`RegAddrLen
`define RsIdxRange `RegLen-1:0
`define False 1'b0
`define True 1'b1

`define IqAddrLen 2
`define IqAddrType `IqAddrLen-1:0
`define IqLen 2**`IqAddrLen
`define IqIdxRange `IqLen-1:0

`define RsAddrLen 2
`define RsAddrType `RsAddrLen-1:0
`define RsLen 2**`RsAddrLen
`define RsIdxRange `RsLen-1:0
`define RsMaxLsCnt 4
