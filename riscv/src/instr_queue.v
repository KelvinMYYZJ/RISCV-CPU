`include "defines.v"
module instr_queue (
    // general
    input clk,
    input rst,
    input rdy,
    output reg chip_enable,

    input update_stat,

    // clear controlling
    output reg clear_flag_out,
    output reg [`AddrType] clear_pc_out,

    // some info out
    output wire [`IqAddrType] iq_head_out,
    output reg iq_have_store_out,
    output reg [`IqAddrType] iq_first_store_idx_out,

    //mem ctrl
    output reg mc_store_enable_out,
    output reg [`AddrType] mc_addr_out,
    // 0(Byte) or 1(Halfword) or 3(Word)
    output reg [1: 0] mc_len_out,
    output reg [`WordType] mc_data_out,
    input wire mc_result_enable_in,

    // instr fetch
    output reg if_fetch_enable_out,
    input wire [`InstrType] if_instr_in,
    input wire [`AddrType] if_pc_in,
    input wire if_result_enable_in,
    // pc
    output reg if_write_pc_sig_out,
    output reg [`AddrType] if_write_pc_val_out,

    // decoder
    output reg dc_decode_enable_out,
    output reg [`InstrType] dc_instr_out,
    input wire dc_result_enable_in,
    input wire [`OpcodeType] dc_opcode_in,
    input wire [`RegAddrType] dc_rd_in,
    input wire [`RegAddrType] dc_rs1_in,
    input wire [`RegAddrType] dc_rs2_in,
    input wire [`Func3Type] dc_func3_in,
    input wire [`Func7Type] dc_func7_in,
    input wire [`WordType] dc_imm_in,

    // rs
    // commit flag : if true, rs should stop getting instruction
    output wire rs_commit_flag_out,
    // instr1 : the first instr to push into rs
    output reg rs_instr1_enable_out,
    output reg [`IqAddrType] rs_instr1_idx_out,
    output wire rs_instr1_ready_out,
    output wire [`RsAddrType] rs_instr1_in_rs_out,
    output wire [`RsAddrType] rs_instr1_pos_in_rs_out,
    output wire rs_instr1_need_cdb_out,
    output wire [`WordType] rs_instr1_result_out,
    output wire [`WordType] rs_instr1_instr_out,
    output wire [`OpcodeType] rs_instr1_instr_optype_out,
    output wire [`Func3Type] rs_instr1_instr_func3_out,
    output wire [`Func7Type] rs_instr1_instr_func7_out,
    output wire [`WordType] rs_instr1_instr_imm_out,
    output wire [`RegAddrType] rs_instr1_instr_rs1_out,
    output wire [`RegAddrType] rs_instr1_instr_rs2_out,
    output wire [`RegAddrType] rs_instr1_instr_rd_out,
    output wire [`AddrType] rs_instr1_instr_pc_out,
    output wire [`AddrType] rs_instr1_tar_addr_out,
    output wire rs_instr1_prediction_out,
    // instr2 : the first non-loadstore instr to push into rs
    output reg rs_instr2_enable_out,
    output reg [`IqAddrType] rs_instr2_idx_out,
    output wire rs_instr2_ready_out,
    output wire [`RsAddrType] rs_instr2_in_rs_out,
    output wire [`RsAddrType] rs_instr2_pos_in_rs_out,
    output wire rs_instr2_need_cdb_out,
    output wire [`WordType] rs_instr2_result_out,
    output wire [`WordType] rs_instr2_instr_out,
    output wire [`OpcodeType] rs_instr2_instr_optype_out,
    output wire [`Func3Type] rs_instr2_instr_func3_out,
    output wire [`Func7Type] rs_instr2_instr_func7_out,
    output wire [`WordType] rs_instr2_instr_imm_out,
    output wire [`RegAddrType] rs_instr2_instr_rs1_out,
    output wire [`RegAddrType] rs_instr2_instr_rs2_out,
    output wire [`RegAddrType] rs_instr2_instr_rd_out,
    output wire [`AddrType] rs_instr2_instr_pc_out,
    output wire [`AddrType] rs_instr2_tar_addr_out,
    output wire rs_instr2_prediction_out,
    // accept report :  instr pushed into rs
    input wire rs_push_result_enable_in,
    input wire [`IqAddrType] rs_push_idx_in,
    // accept rs input
    input wire rs_write_enable_in,
    input wire [`IqAddrType] rs_write_idx_in,
    input wire rs_write_result_enable_in,
    input wire [`WordType]rs_write_result_in,
    input wire rs_write_need_cdb_enable_in,
    input wire rs_write_need_cdb_in,
    input wire rs_write_ready_enable_in,
    input wire rs_write_ready_in,
    input wire rs_write_pos_in_rs_enable_in,
    input wire rs_write_pos_in_rs_in,
    input wire rs_write_tar_addr_enable_in,
    input wire [`AddrType] rs_write_tar_addr_in,
    // cdb to rs
    output reg rs_cdb_enable_out,
    output reg [`IqAddrType]rs_cdb_idx_out,
    output reg [`WordType]rs_cdb_value_out,
    // commit reg value to rs
    output reg rs_commit_reg_enable_out,
    output reg [`RegAddrType] rs_commit_reg_idx_out,
    output reg [`IqAddrType] rs_commit_reg_rename_out,
    output reg [`WordType] rs_commit_reg_value_out,

    // alu
    input wire alu_write_enable_in,
    input wire [`IqAddrType] alu_write_idx_in,
    input wire alu_write_result_enable_in,
    input wire [`WordType] alu_write_result_in,
    input wire alu_write_need_cdb_enable_in,
    input wire alu_write_need_cdb_in,
    input wire alu_write_ready_enable_in,
    input wire alu_write_ready_in,

    // load buffer
    input wire lb_write_enable_in,
    input wire [`IqAddrType] lb_write_idx_in,
    input wire lb_write_result_enable_in,
    input wire [`WordType] lb_write_result_in,
    input wire lb_write_need_cdb_enable_in,
    input wire lb_write_need_cdb_in,
    input wire lb_write_ready_enable_in,
    input wire lb_write_ready_in,

    // iq
    // predict part
    output reg pd_predict_enable_out,
    // output reg [`AddrType] pd_pc_out,
    input wire pd_predict_result_enable_in,
    input wire pd_predict_result_in,
    // update stat part
    output reg pd_update_stat_enable_out,
    output reg pd_update_stat_result_out
  );
  assign iq_head_out = iq_head;
  localparam InstrFetchStatIdle = 0;
  localparam InstrFetchStatFetching = 1;
  localparam InstrFetchStatDecoding = 2;
  localparam InstrFetchStatPridecting = 3;

  localparam InstrCommitStatIdle = 0;
  localparam InstrCommitStatStoring = 1;

  integer order;
  integer break_flag;
  integer commit_flag; // used in update stat, means will commit in next working stat
  integer i;
  reg [`IqAddrType] iq_head;
  reg [`IqAddrType] iq_tail;
  wire [`IqAddrType] iq_tail_dec = iq_tail - 1;
  wire [`WordType] iq_imm_tail = iq_instr_imm[iq_tail_dec];
  reg [`IqAddrType] iq_ls_num;
  reg iq_ready [`IqIdxRange];
  reg iq_in_rs [`IqIdxRange]; // pos_in_rs != NIDX
  reg [`RsAddrType] iq_pos_in_rs [`IqIdxRange];
  reg iq_need_cdb [`IqIdxRange];
  reg [`WordType] iq_result [`IqIdxRange];
  reg [`WordType] iq_instr [`IqIdxRange];
  reg [`OpcodeType] iq_instr_optype [`IqIdxRange];
  reg [`Func3Type] iq_instr_func3 [`IqIdxRange];
  reg [`Func7Type] iq_instr_func7 [`IqIdxRange];
  reg [`WordType] iq_instr_imm [`IqIdxRange];
  reg [`RegAddrType] iq_instr_rs1 [`IqIdxRange];
  reg [`RegAddrType] iq_instr_rs2 [`IqIdxRange];
  reg [`RegAddrType] iq_instr_rd [`IqIdxRange];
  reg [`AddrType] iq_instr_pc [`IqIdxRange];
  reg [`AddrType] iq_tar_addr [`IqIdxRange];
  reg iq_prediction [`IqIdxRange];
  reg [1: 0] instr_fetch_stat;
  reg instr_commit_stat;
  wire [`IqAddrType] iq_len = iq_tail - iq_head;
  reg [`AddrType] decoding_instr_pc;
  // reg pd_predict_result_enable_in;
  reg pd_prediction_in;
  integer commit_cnt;
  wire [`IqAddrType] idx = iq_head + i;
  wire break_flag_final = break_flag | !((iq_head <= iq_tail) ?
                                         (iq_head <= idx && idx < iq_tail) :
                                         (iq_head <= idx || idx < iq_tail) );


  assign rs_commit_flag_out = iq_head != iq_tail && iq_ready[iq_head] && iq_need_cdb[iq_head];
  assign rs_instr1_ready_out = iq_ready[rs_instr1_idx_out];
  assign rs_instr1_in_rs_out = iq_in_rs[rs_instr1_idx_out];
  assign rs_instr1_pos_in_rs_out = iq_pos_in_rs[rs_instr1_idx_out];
  assign rs_instr1_need_cdb_out = iq_need_cdb[rs_instr1_idx_out];
  assign rs_instr1_result_out = iq_result[rs_instr1_idx_out];
  assign rs_instr1_instr_out = iq_instr[rs_instr1_idx_out];
  assign rs_instr1_instr_optype_out = iq_instr_optype[rs_instr1_idx_out];
  assign rs_instr1_instr_func3_out = iq_instr_func3[rs_instr1_idx_out];
  assign rs_instr1_instr_func7_out = iq_instr_func7[rs_instr1_idx_out];
  assign rs_instr1_instr_imm_out = iq_instr_imm[rs_instr1_idx_out];
  assign rs_instr1_instr_rs1_out = iq_instr_rs1[rs_instr1_idx_out];
  assign rs_instr1_instr_rs2_out = iq_instr_rs2[rs_instr1_idx_out];
  assign rs_instr1_instr_rd_out = iq_instr_rd[rs_instr1_idx_out];
  assign rs_instr1_instr_pc_out = iq_instr_pc[rs_instr1_idx_out];
  assign rs_instr1_tar_addr_out = iq_tar_addr[rs_instr1_idx_out];
  assign rs_instr1_prediction_out = iq_prediction[rs_instr1_idx_out];

  assign rs_instr2_ready_out = iq_ready[rs_instr2_idx_out];
  assign rs_instr2_in_rs_out = iq_in_rs[rs_instr2_idx_out];
  assign rs_instr2_pos_in_rs_out = iq_pos_in_rs[rs_instr2_idx_out];
  assign rs_instr2_need_cdb_out = iq_need_cdb[rs_instr2_idx_out];
  assign rs_instr2_result_out = iq_result[rs_instr2_idx_out];
  assign rs_instr2_instr_out = iq_instr[rs_instr2_idx_out];
  assign rs_instr2_instr_optype_out = iq_instr_optype[rs_instr2_idx_out];
  assign rs_instr2_instr_func3_out = iq_instr_func3[rs_instr2_idx_out];
  assign rs_instr2_instr_func7_out = iq_instr_func7[rs_instr2_idx_out];
  assign rs_instr2_instr_imm_out = iq_instr_imm[rs_instr2_idx_out];
  assign rs_instr2_instr_rs1_out = iq_instr_rs1[rs_instr2_idx_out];
  assign rs_instr2_instr_rs2_out = iq_instr_rs2[rs_instr2_idx_out];
  assign rs_instr2_instr_rd_out = iq_instr_rd[rs_instr2_idx_out];
  assign rs_instr2_instr_pc_out = iq_instr_pc[rs_instr2_idx_out];
  assign rs_instr2_tar_addr_out = iq_tar_addr[rs_instr2_idx_out];
  assign rs_instr2_prediction_out = iq_prediction[rs_instr2_idx_out];
  always @ (posedge clk) begin
    if (rst) begin
      chip_enable <= `False;
      // pd_predict_result_enable_in <= `True;
      pd_prediction_in <= `True;
      iq_head <= 0;
      iq_tail <= 0;
      instr_fetch_stat <= InstrFetchStatIdle;
      instr_commit_stat <= InstrCommitStatIdle;
      dc_decode_enable_out <= `False;
      if_fetch_enable_out <= `False;
      mc_store_enable_out <= `False;
      clear_flag_out <= `False;
      rs_instr1_enable_out <= `False;
      rs_instr2_enable_out <= `False;
      pd_predict_enable_out <= `False;
      pd_update_stat_enable_out <= `False;
      commit_cnt = 0;
    end
    else begin
      chip_enable <= rdy;
      if (rdy) begin
        if (update_stat) begin
          if (rs_push_result_enable_in) begin
            iq_in_rs[rs_push_idx_in] <= `True;
          end
          if (rs_write_enable_in) begin
            if (rs_write_result_enable_in) begin
              iq_result[rs_write_idx_in] <= rs_write_result_in;
            end
            if (rs_write_need_cdb_enable_in) begin
              if (iq_instr_rd[rs_write_idx_in])
                iq_need_cdb[rs_write_idx_in] <= rs_write_need_cdb_in;
            end
            if (rs_write_ready_enable_in) begin
              iq_ready[rs_write_idx_in] <= rs_write_ready_in;
            end
            if (rs_write_pos_in_rs_enable_in) begin
              iq_in_rs[rs_write_idx_in] <= `True;
              iq_pos_in_rs[rs_write_idx_in] <= rs_write_pos_in_rs_in;
            end
            if (rs_write_tar_addr_enable_in) begin
              iq_tar_addr[rs_write_idx_in] <= rs_write_tar_addr_in;
            end
          end
          if (alu_write_enable_in) begin
            if (alu_write_result_enable_in) begin
              iq_result[alu_write_idx_in] <= alu_write_result_in;
            end
            if (alu_write_need_cdb_enable_in) begin
              if (iq_instr_rd[alu_write_idx_in])
                iq_need_cdb[alu_write_idx_in] <= alu_write_need_cdb_in;
            end
            if (alu_write_ready_enable_in) begin
              iq_ready[alu_write_idx_in] <= alu_write_ready_in;
            end
          end
          if (lb_write_enable_in) begin
            if (lb_write_result_enable_in) begin
              iq_result[lb_write_idx_in] <= lb_write_result_in;
            end
            if (lb_write_need_cdb_enable_in) begin
              // $display("load instr with rd : %h",iq_instr_rd[lb_write_idx_in]);
              if (iq_instr_rd[lb_write_idx_in])
                iq_need_cdb[lb_write_idx_in] <= lb_write_need_cdb_in;
            end
            if (lb_write_ready_enable_in) begin
              iq_ready[lb_write_idx_in] <= lb_write_ready_in;
            end
          end
          // TODO? : other write
          // TODO : find the first store instr
          iq_have_store_out <= `False;
          break_flag = 0;
          for (i = 0;i < `IqLen;i = i + 1) if (!break_flag_final) begin
              if (iq_instr_optype[idx] == `Opcode_StoreMem) begin
                break_flag = 1;
                iq_first_store_idx_out <= idx;
                iq_have_store_out <= `True;
              end
            end
          break_flag = 0;
          rs_instr1_enable_out <= `False;
          rs_instr2_enable_out <= `False;
          break_flag = 0;
          for (i = 0;i < `IqLen;i = i + 1) if (!break_flag_final) begin
              if (!(rs_write_enable_in && rs_write_idx_in == i) && !(rs_push_result_enable_in && rs_push_idx_in == idx)) begin
                // TODO? : other write all continue
                if (!iq_in_rs[idx]) begin
                  rs_instr1_enable_out <= `True;
                  rs_instr1_idx_out <= idx;
                  break_flag = 1;
                end
              end
            end
          // if (i != iq_tail && (iq_instr_optype[i] == `Opcode_StoreMem || iq_instr_optype[i] == `Opcode_LoadMem)) begin
          //   // instr1 is an memory access op
          //   // get instr2
          //   break_flag = 0;
          //   for (i = iq_head;i != iq_tail;i = (i == `IqLen - 1) ? 0 : i + 1) if (!break_flag_final) begin begin
          //         if (!(rs_write_enable_in && rs_write_idx_in == i) && !(rs_push_result_enable_in && rs_push_idx_in == i)) begin
          //           // TODO : other write all continue
          //           if (!iq_in_rs[i] && (iq_instr_optype[i] != `Opcode_StoreMem || iq_instr_optype[i] != `Opcode_LoadMem)) begin
          //             rs_instr2_enable_out <= `True;
          //             rs_instr2_idx_out <= i;
          //             break_flag = 1;
          //           end
          //         end
          //       end
          //     end
          // end
        end
        else begin
          if_write_pc_sig_out <= `False;
          rs_cdb_enable_out <= `False;
          rs_commit_reg_enable_out <= `False;
          mc_store_enable_out <= `False;
          if_fetch_enable_out <= `False;
          dc_decode_enable_out <= `False;
          pd_predict_enable_out <= `False;
          pd_update_stat_enable_out <= `False;
          if (clear_flag_out) begin
            clear_flag_out <= `False;
            iq_head <= 0;
            iq_tail <= 0;
            instr_fetch_stat <= InstrFetchStatIdle;
          end
          else begin
            break_flag = 0;
            for (i = 0;i < `IqLen;i = i + 1) if (!break_flag_final) begin
                if (iq_need_cdb[idx]) begin
                  iq_need_cdb[idx] <= `False;
                  rs_cdb_enable_out <= `True;
                  rs_cdb_idx_out <= idx;
                  rs_cdb_value_out <= iq_result[idx];
                  break_flag = 1;
                end
              end
            if (instr_commit_stat == InstrCommitStatStoring && mc_result_enable_in) begin
              instr_commit_stat <= InstrCommitStatIdle;
            end
            if (iq_head != iq_tail && iq_ready[iq_head] && !iq_need_cdb[iq_head] && instr_commit_stat == InstrCommitStatIdle) begin
              iq_head <= iq_head + 1;
              commit_cnt = commit_cnt + 1;
              if (`SHOW_COMMIT_FLAG)
                if (!(commit_cnt & 16'hFF))
                  $display("commit num : %h", commit_cnt);
              if (`DEBUG_FLAG) $display("commiting, commit_cnt = %h, pc = %h", commit_cnt, iq_instr_pc[iq_head]); // DEBUG_DISPLAY
              if (iq_instr_optype[iq_head] == `Opcode_StoreMem) begin
                mc_store_enable_out <= `True;
                instr_commit_stat <= InstrCommitStatStoring;
                mc_addr_out <= iq_tar_addr[iq_head];
                mc_data_out <= iq_result[iq_head];
                mc_len_out <= ((iq_instr_func3[iq_head] & 3) == 2) ? 3 : iq_instr_func3[iq_head] & 3;
                if (`DEBUG_FLAG) $display("storing, pc = %h, addr = %h, val = %h, store type = %h", iq_instr_pc[iq_head], iq_tar_addr[iq_head], iq_result[iq_head], iq_instr_func3[iq_head] & 3); // DEBUG_DISPLAY
              end
              else if (iq_instr_optype[iq_head] == `Opcode_BControl) begin
                pd_update_stat_enable_out <= `True;
                pd_update_stat_result_out <= iq_result[iq_head];
                // pd_update_stat_pc <= iq_instr_pc[iq_head];
                // $display("pc : %h, result : %h", iq_instr_pc[iq_head], iq_result[iq_head]);
                if (iq_result[iq_head] != iq_prediction[iq_head]) begin
                  clear_flag_out <= `True;
                  // $display("clear because wrong prediction, next pc is %h",iq_result[iq_head] ? iq_instr_pc[iq_head] + iq_instr_imm[iq_head] : iq_instr_pc[iq_head] + 4 );
                  clear_pc_out <= iq_result[iq_head] ? iq_instr_pc[iq_head] + iq_instr_imm[iq_head] : iq_instr_pc[iq_head] + 4 ;
                end
                // else $display("correct prediction : %h",iq_prediction[iq_head]);
              end
              else begin
                if (iq_instr_rd[iq_head]) begin
                  if (`DEBUG_FLAG) $display("nxt_pc : %h", iq_instr_pc[iq_head]); // DEBUG_DISPLAY
                  rs_commit_reg_enable_out <= `True;
                  rs_commit_reg_idx_out <= iq_instr_rd[iq_head];
                  rs_commit_reg_value_out <= iq_result[iq_head];
                  rs_commit_reg_rename_out <= iq_head;
                end
                if (iq_instr_optype[iq_head] == `Opcode_JALR) begin
                  clear_flag_out <= `True;
                  // $display("clear because JALR, next pc is %h",iq_tar_addr[iq_head]);
                  clear_pc_out <= iq_tar_addr[iq_head];
                end
              end
            end

            if (instr_fetch_stat == InstrFetchStatIdle && iq_len + 1 < `IqLen) begin
              if_fetch_enable_out <= `True;
              instr_fetch_stat <= InstrFetchStatFetching;
            end

            if (instr_fetch_stat == InstrFetchStatFetching && if_result_enable_in) begin
              instr_fetch_stat <= InstrFetchStatDecoding;
              dc_decode_enable_out <= `True;
              decoding_instr_pc <= if_pc_in;
              dc_instr_out <= if_instr_in;
            end

            if (instr_fetch_stat == InstrFetchStatDecoding && dc_result_enable_in) begin
              iq_tail <= iq_tail + 1;
              iq_ready[iq_tail] <= `False;
              iq_in_rs[iq_tail] <= `False;
              iq_need_cdb[iq_tail] <= `False;
              iq_instr_func3[iq_tail] <= dc_func3_in;
              iq_instr_func7[iq_tail] <= dc_func7_in;
              iq_instr_optype[iq_tail] <= dc_opcode_in;
              iq_instr_imm[iq_tail] <= dc_imm_in;
              iq_instr_pc[iq_tail] <= decoding_instr_pc;
              iq_instr_rd[iq_tail] <= dc_rd_in;
              iq_instr_rs1[iq_tail] <= dc_rs1_in;
              iq_instr_rs2[iq_tail] <= dc_rs2_in;
              if (dc_opcode_in == `Opcode_BControl) begin
                instr_fetch_stat <= InstrFetchStatPridecting;
                pd_predict_enable_out <= `True;
                // pd_pc_out <= decoding_instr_pc;
              end
              else begin
                if_write_pc_sig_out <= `True;
                if_write_pc_val_out <= decoding_instr_pc + 4;
                instr_fetch_stat <= InstrFetchStatIdle;
                if (dc_opcode_in == `Opcode_JAL) begin
                  if_write_pc_val_out <= decoding_instr_pc + dc_imm_in;
                end
              end
            end

            if (instr_fetch_stat == InstrFetchStatPridecting && pd_predict_result_enable_in) begin
              instr_fetch_stat <= InstrFetchStatIdle;
              // pd_predict_enable_out <= `False;
              iq_prediction[iq_tail_dec] <= pd_predict_result_in;
              if_write_pc_sig_out <= `True;
              if_write_pc_val_out <= pd_predict_result_in ? decoding_instr_pc + iq_imm_tail : (decoding_instr_pc + 4);
            end
          end
        end
      end
    end
  end
endmodule //instr_queue
