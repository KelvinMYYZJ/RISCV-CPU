`include "defines.v"

module rs (
    input clk,
    input rst,
    input rdy,
    output reg chip_enable,
    input update_stat,
    input clear_flag_in,
    input wire [`AddrType] clear_pc_in,
    // instr queue
    // for load info
    input wire [`IqAddrType] iq_head_out,
    input wire iq_have_store_out,
    input wire [`IqAddrType] iq_first_store_idx_out,
    // commit flag : if true, rs should stop getting instruction
    input wire iq_commit_flag_in,
    // instr1
    input wire iq_instr1_enable_in,
    input wire [`IqAddrType] iq_instr1_idx_in,
    input wire iq_instr1_ready_in,
    input wire [`RsAddrType] iq_instr1_in_rs_in,
    input wire [`RsAddrType] iq_instr1_pos_in_rs_in,
    input wire iq_instr1_need_cdb_in,
    input wire [`WordType] iq_instr1_result_in,
    input wire [`WordType] iq_instr1_instr_in,
    input wire [`OpcodeType] iq_instr1_instr_optype_in,
    input wire [`Func3Type] iq_instr1_instr_func3_in,
    input wire [`Func7Type] iq_instr1_instr_func7_in,
    input wire [`WordType] iq_instr1_instr_imm_in,
    input wire [`RegAddrType] iq_instr1_instr_rs1_in,
    input wire [`RegAddrType] iq_instr1_instr_rs2_in,
    input wire [`RegAddrType] iq_instr1_instr_rd_in,
    input wire [`AddrType] iq_instr1_instr_pc_in,
    input wire [`AddrType] iq_instr1_tar_addr_in,
    input wire iq_instr1_prediction_in,
    // instr2
    input wire iq_instr2_enable_in,
    input wire [`IqAddrType] iq_instr2_idx_in,
    input wire iq_instr2_ready_in,
    input wire [`RsAddrType] iq_instr2_in_rs_in,
    input wire [`RsAddrType] iq_instr2_pos_in_rs_in,
    input wire iq_instr2_need_cdb_in,
    input wire [`WordType] iq_instr2_result_in,
    input wire [`WordType] iq_instr2_instr_in,
    input wire [`OpcodeType] iq_instr2_instr_optype_in,
    input wire [`Func3Type] iq_instr2_instr_func3_in,
    input wire [`Func7Type] iq_instr2_instr_func7_in,
    input wire [`WordType] iq_instr2_instr_imm_in,
    input wire [`RegAddrType] iq_instr2_instr_rs1_in,
    input wire [`RegAddrType] iq_instr2_instr_rs2_in,
    input wire [`RegAddrType] iq_instr2_instr_rd_in,
    input wire [`AddrType] iq_instr2_instr_pc_in,
    input wire [`AddrType] iq_instr2_tar_addr_in,
    input wire iq_instr2_prediction_in,
    // report instr pushed into rs
    output reg iq_push_result_enable_out,
    output reg [`IqAddrType] iq_push_idx_out,
    // write instr
    output reg iq_write_enable_out,
    output reg [`IqAddrType] iq_write_idx_out,
    output reg iq_write_result_enable_out,
    output reg [`WordType] iq_write_result_out,
    output reg iq_write_need_cdb_enable_out,
    output reg iq_write_need_cdb_out,
    output reg iq_write_ready_enable_out,
    output reg iq_write_ready_out,
    output reg iq_write_pos_in_rs_enable_out,
    output reg iq_write_pos_in_rs_out,
    output reg iq_write_tar_addr_enable_out,
    output reg iq_write_tar_addr_out,
    // cdb to rs
    input wire iq_cdb_enable_in,
    input wire [`IqAddrType] iq_cdb_idx_in,
    input wire [`WordType] iq_cdb_value_in,
    // get commit reg value
    input wire iq_commit_reg_enable_in,
    input wire [`RegAddrType] iq_commit_reg_idx_in,
    input wire [`IqAddrType] iq_commit_reg_rename_in,
    input wire [`WordType] iq_commit_reg_value_in,

    // alu
    input wire alu_full_in,
    output reg alu_calc_enable_out,
    output reg [`CalcCodeType] alu_calc_code_out,
    output reg [`WordType] alu_lhs_out,
    output reg [`WordType] alu_rhs_out,
    output reg [`IqAddrType] alu_pos_in_iq_out,

    // lb
    input wire lb_full_in,
    output reg lb_load_enable_out,
    output reg [`Func3Type] lb_func3_out,
    output reg [`AddrType] lb_addr_out,
    output reg [`IqAddrType] lb_pos_in_iq_out
  );
  reg [`IqAddrType] reg_rename [`RegAddrType];
  reg [`WordType] reg_val [`RegAddrType];
  reg reg_is_rename [`RegAddrType];
  reg [`RsAddrType] rs_size;
  reg [`RsAddrType] rs_ls_cnt;
  reg rs_avl[`RsIdxRange];
  reg [`WordType] rs_rs1_val [`RsIdxRange];
  reg [`WordType] rs_rs2_val [`RsIdxRange];
  reg [`WordType] rs_imm [`RsIdxRange];
  reg rs_rs1_is_renamed [`RsIdxRange];
  reg rs_rs2_is_renamed [`RsIdxRange];
  reg [`IqAddrType] rs_rs1_rename [`RsIdxRange];
  reg [`IqAddrType] rs_rs2_rename [`RsIdxRange];
  reg [`IqAddrType] rs_order [`RsIdxRange];
  reg [`AddrType] rs_pc [`RsIdxRange];
  reg [`OpcodeType] rs_instr_opcode [`RsIdxRange];
  reg [`Func7Type] rs_instr_func7 [`RsIdxRange];
  reg [`Func3Type] rs_instr_func3 [`RsIdxRange];
  wire rs_full = rs_size == `RsLen;
  wire rs_ls_full = rs_ls_cnt == `RsMaxLsCnt;

  always @ (posedge clk) begin
    if (rst) begin
      chip_enable <= `False;
      rs_size <= 0;
      rs_ls_cnt <= 0;
      for (i = 0;i < `RsLen;i = i + 1) begin
        rs_avl[i] <= `False;
      end
      for (i = 0;i < `RegLen;i = i + 1) begin
        reg_val[i] <= `ZeroWord;
        reg_is_rename[i] <= `False;
      end
      iq_write_enable_out <= `False;
      iq_write_result_enable_out <= `False;
      iq_write_need_cdb_enable_out <= `False;
      iq_write_ready_enable_out <= `False;
      iq_write_pos_in_rs_enable_out <= `False;
      iq_write_tar_addr_enable_out <= `False;
      iq_push_result_enable_out <= `False;
      // TODO
    end
    else begin
      chip_enable <= rdy;
    end
  end
  integer i;
  integer break_flag;
  always @ (posedge clk) begin
    if (chip_enable) begin
      if (update_stat) begin
        if (iq_cdb_enable_in) begin
          for (i = 0;i < `RsLen; i = i + 1)
            if (rs_avl[i]) begin
              if (rs_rs1_is_renamed[i] && rs_rs1_rename[i] == iq_cdb_idx_in) begin
                rs_rs1_is_renamed[i] <= `False;
                rs_rs1_val[i] <= iq_cdb_value_in;
              end
              if (rs_rs2_is_renamed[i] && rs_rs2_rename[i] == iq_cdb_idx_in) begin
                rs_rs2_is_renamed[i] <= `False;
                rs_rs2_val[i] <= iq_cdb_value_in;
              end
            end
        end
        if (iq_commit_reg_enable_in) begin
          reg_val[iq_commit_reg_idx_in] <= iq_commit_reg_value_in;
          if (reg_is_rename[iq_commit_reg_idx_in] && reg_rename[iq_commit_reg_idx_in] == iq_commit_reg_rename_in) begin
            reg_is_rename[iq_commit_reg_idx_in] <= `False;
          end
        end
        // TODO? : other value update
      end
      else begin
        if (clear_flag_in) begin
          rs_size <= 0;
          rs_ls_cnt <= 0;
          for (i = 0;i < `RsLen;i = i + 1) begin
            rs_avl[i] <= `False;
          end
        end
        else begin
          iq_push_result_enable_out <= `False;
          iq_write_enable_out <= `False;
          iq_write_result_enable_out <= `False;
          iq_write_need_cdb_enable_out <= `False;
          iq_write_ready_enable_out <= `False;
          iq_write_pos_in_rs_enable_out <= `False;
          iq_write_tar_addr_enable_out <= `False;
          iq_push_result_enable_out <= `False;
          // get an instr from instr queue
          if (!rs_full && !iq_commit_flag_in && iq_instr1_enable_in) begin
            if (!(rs_ls_full &&
                  (iq_instr1_instr_optype_in == `Opcode_LoadMem ||
                   iq_instr1_instr_optype_in == `Opcode_StoreMem))) begin // ls not full now
              for (i = 0;i < `RsLen && rs_avl[i];i = i + 1);
              // TODO : in rs
              rs_size <= rs_size + 1;
              if (iq_instr1_instr_optype_in == `Opcode_LoadMem ||
                  iq_instr1_instr_optype_in == `Opcode_StoreMem) begin
                rs_ls_cnt <= rs_ls_cnt + 1;
              end
              rs_avl[i] <= `True;
              rs_instr_opcode[i] <= iq_instr1_instr_optype_in;
              if (iq_instr1_instr_rd_in) begin
                reg_is_rename[iq_instr1_instr_rd_in] <= `True;
                reg_rename[iq_instr1_instr_rd_in] <= iq_instr1_idx_in;
              end
              if (reg_is_rename[iq_instr1_instr_rs1_in]) begin
                rs_rs1_is_renamed[i] <= `True;
                rs_rs1_rename[i] <= reg_rename[iq_instr1_instr_rs1_in];
              end
              else begin
                rs_rs1_is_renamed[i] <= `False;
                rs_rs1_val[i] <= reg_val[iq_instr1_instr_rs1_in];
              end
              if (reg_is_rename[iq_instr1_instr_rs2_in]) begin
                rs_rs2_is_renamed[i] <= `True;
                rs_rs2_rename[i] <= reg_rename[iq_instr1_instr_rs1_in];
              end
              else begin
                rs_rs2_is_renamed[i] <= `False;
                rs_rs2_val[i] <= reg_val[iq_instr1_instr_rs2_in];
              end
              rs_imm[i] <= iq_instr1_instr_imm_in;
              rs_pc[i] <= iq_instr1_instr_pc_in;
              rs_instr_opcode[i] <= iq_instr1_instr_optype_in;
              rs_instr_func3[i] <= iq_instr1_instr_func3_in;
              rs_instr_func7[i] <= iq_instr1_instr_func7_in;
              rs_order[i] <= iq_instr1_idx_in;
              iq_push_result_enable_out <= `True;
              iq_push_idx_out <= iq_instr1_idx_in;
            end
            else begin
              if (iq_instr2_enable_in) begin
                // copy above
              end
            end
          end
          // deal an instr in rs
          if (rs_size) begin
            break_flag = 0;
            for (i = 0;i < `RsLen && !break_flag;i = i + 1) begin
              if (rs_avl[i] && (!rs_rs1_is_renamed[i] && !rs_rs2_is_renamed[i])) begin
                if (rs_instr_opcode[i] == `Opcode_JAL) begin
                  rs_avl[i] <= `False;
                  rs_size <= rs_size - 1;
                  iq_write_enable_out <= `True;
                  iq_write_idx_out <= rs_order[i];
                  iq_write_ready_enable_out <= `True;
                  iq_write_ready_out <= `True;
                  iq_write_result_enable_out <= `True;
                  iq_write_result_out <= rs_pc[i];
                  iq_write_need_cdb_enable_out <= `True;
                  iq_write_need_cdb_out <= `True;
                  break_flag = 1;
                end
                else if (rs_instr_opcode[i] == `Opcode_LoadMem) begin
                  // TODO : more condition to limit load
                  if (!lb_full_in && (iq_have_store_out || (iq_head_out <= iq_first_store_idx_out ?
                                      (iq_head_out <= rs_order[i] && rs_order[i] < iq_first_store_idx_out) :
                                      (iq_head_out <= rs_order[i] || rs_order[i] < iq_first_store_idx_out) ))) begin
                    rs_avl[i] <= `False;
                    rs_size <= rs_size - 1;
                    rs_ls_cnt <= rs_ls_cnt - 1;
                    lb_load_enable_out <= `True;
                    lb_addr_out <= rs_rs1_val[i];
                    lb_func3_out <= rs_instr_func3[i];
                    lb_pos_in_iq_out <= rs_order[i];
                    break_flag = 1;
                  end
                end
                else if (rs_instr_opcode[i] == `Opcode_StoreMem) begin
                  rs_avl[i] <= `False;
                  rs_size <= rs_size - 1;
                  rs_ls_cnt <= rs_ls_cnt - 1;
                  iq_write_enable_out <= `True;
                  iq_write_idx_out <= rs_order[i];
                  iq_write_ready_enable_out <= `True;
                  iq_write_ready_out <= `True;
                  iq_write_result_enable_out <= `True;
                  iq_write_result_out <= rs_rs2_val[i];
                  iq_write_tar_addr_enable_out <= `True;
                  iq_write_tar_addr_out <= rs_rs1_val[i] + rs_imm[i];
                  break_flag = 1;
                end
                else if (rs_instr_opcode[i] == `Opcode_Calc) begin
                  if (!alu_full_in) begin
                    rs_avl[i] <= `False;
                    rs_size <= rs_size - 1;
                    alu_calc_enable_out <= `True;
                    break_flag = 1;
                    if (rs_instr_func3[i] == 0) begin
                      if (rs_instr_func7[i] == 0)
                        alu_calc_code_out <= `CalcCodeAdd;
                      else  // if (rs_instr_func7[i] == 0x20)
                        alu_calc_code_out <= `CalcCodeSub;
                    end
                    else if (rs_instr_func3[i] < 5)
                      alu_calc_code_out <= rs_instr_func3[i] + 1;
                    else if (rs_instr_func3[i] == 5) begin
                      if (rs_instr_func7[i] == 0)
                        alu_calc_code_out <= `CalcCodeSrl;
                      else  // if (rs_instr_func7[i] == 0x20)
                        alu_calc_code_out <= `CalcCodeSra;
                    end
                    else
                      alu_calc_code_out <= rs_instr_func3[i] + 2;
                    alu_lhs_out <= rs_rs1_val[i];
                    alu_rhs_out <= rs_rs2_val[i];
                    if (rs_instr_func3[i] == 1 || rs_instr_func3[i] == 5)
                      alu_rhs_out <= rs_rs2_val[i][4: 0];
                  end
                end
                else if (rs_instr_opcode[i] == `Opcode_CalcI) begin
                  if (!alu_full_in) begin
                    rs_avl[i] <= `False;
                    rs_size <= rs_size - 1;
                    alu_calc_enable_out <= `True;
                    break_flag = 1;
                    if (rs_instr_func3[i] == 0)
                      alu_calc_code_out <= `CalcCodeAdd;
                    else if (rs_instr_func3[i] < 5)
                      alu_calc_code_out <= rs_instr_func3[i] + 1;
                    else if (rs_instr_func3[i] == 5) begin
                      if (rs_instr_func7[i] == 0)
                        alu_calc_code_out <= `CalcCodeSrl;
                      else  // if (rs_instr_func7[i] == 0x20)
                        alu_calc_code_out <= `CalcCodeSra;
                    end
                    else
                      alu_calc_code_out <= rs_instr_func3[i] + 2;
                    alu_lhs_out <= rs_rs1_val[i];
                    alu_rhs_out <= rs_imm[i];
                    if (rs_instr_func3[i] == 1 || rs_instr_func3[i] == 5)
                      alu_rhs_out <= rs_imm[i][4: 0];
                  end
                end
                else if (rs_instr_opcode[i] == `Opcode_LUI) begin
                  rs_avl[i] <= `False;
                  rs_size <= rs_size - 1;
                  iq_write_enable_out <= `True;
                  iq_write_idx_out <= rs_order[i];
                  iq_write_ready_enable_out <= `True;
                  iq_write_ready_out <= `True;
                  iq_write_result_enable_out <= `True;
                  iq_write_result_out <= rs_imm[i];
                  iq_write_need_cdb_enable_out <= `True;
                  iq_write_need_cdb_out <= `True;
                  break_flag = 1;
                end
                else if (rs_instr_opcode[i] == `Opcode_AUIPC) begin
                  rs_avl[i] <= `False;
                  rs_size <= rs_size - 1;
                  iq_write_enable_out <= `True;
                  iq_write_idx_out <= rs_order[i];
                  iq_write_ready_enable_out <= `True;
                  iq_write_ready_out <= `True;
                  iq_write_result_enable_out <= `True;
                  iq_write_result_out <= rs_pc[i] + rs_imm[i];
                  iq_write_need_cdb_enable_out <= `True;
                  iq_write_need_cdb_out <= `True;
                  break_flag = 1;
                end
                else if (rs_instr_opcode[i] == `Opcode_JALR) begin
                  rs_avl[i] <= `False;
                  rs_size <= rs_size - 1;
                  iq_write_enable_out <= `True;
                  iq_write_idx_out <= rs_order[i];
                  iq_write_ready_enable_out <= `True;
                  iq_write_ready_out <= `True;
                  iq_write_result_enable_out <= `True;
                  iq_write_result_out <= rs_pc[i] + 4;
                  iq_write_tar_addr_enable_out <= `True;
                  iq_write_tar_addr_out <= (rs_imm[i] + rs_rs1_val[i]) & 32'hFFFFFFFE;
                  iq_write_need_cdb_enable_out <= `True;
                  iq_write_need_cdb_out <= `True;
                  break_flag = 1;
                end
              end
            end
          end
        end
      end
    end
  end

endmodule //rs
