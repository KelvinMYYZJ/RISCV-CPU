// RISCV32I CPU top module
// port modification allowed for debugging purposes
`include "defines.v"
module cpu(
    // system clock signal
    input wire clk_in,
    // reset signal
    input wire rst_in,
    // ready signal, pause cpu when low
    input wire	rdy_in,

    // data input bus
    input wire [ 7: 0] mem_din,
    // data output bus
    output wire [ 7: 0] mem_dout,
    // address bus (only 17:0 is used)
    output wire [31: 0] mem_a,
    // write/read signal (1 for write)
    output wire mem_wr,

    // 1 if uart buffer is full
    input wire io_buffer_full,

    // cpu register output (debugging demo)
    output wire [31: 0]	dbgreg_dout
  );

  // implementation goes here

  // all the wires
  // global
  wire global_clear_flag;
  wire [`AddrType] global_clear_pc;
  wire [`IqAddrType]global_iq_head;
  wire global_iq_have_store;
  wire [`IqAddrType] global_iq_first_store_idx;

  // alu - instr queue
  wire alu_iq_write_enable;
  wire [`IqAddrType] alu_iq_write_idx;
  wire alu_iq_write_result_enable;
  wire [`WordType] alu_iq_write_result;
  wire alu_iq_write_need_cdb_enable;
  wire alu_iq_write_need_cde;
  wire alu_iq_write_ready_enable;
  wire alu_iq_write_reade;

  // alu - rs
  wire alu_rs_full;
  wire alu_rs_calc_enable;
  wire [`CalcCodeType] alu_rs_calc_code;
  wire [`WordType] alu_rs_lhs;
  wire [`WordType] alu_rs_rhs;
  wire [`IqAddrType] alu_rs_pos_in_iq;

  // decoder - instr queue
  wire dc_iq_decode_ebable;
  wire [`InstrType] dc_iq_instr;
  wire dc_iq_result_enable;
  wire [`OpcodeType] dc_iq_opcode;
  wire [`RegAddrType] dc_iq_rd;
  wire [`RegAddrType] dc_iq_rs1;
  wire [`RegAddrType] dc_iq_rs2;
  wire [`Func3Type] dc_iq_func3;
  wire [`Func7Type] dc_iq_func7;
  wire [`WordType] dc_iq_imm;

  //instr fetcher - mem ctrl
  wire if_mc_fetch_enable;
  wire [`AddrType] if_mc_addr;
  wire if_mc_result_enable;
  wire [`WordType] if_mc_data;

  //instr fetcher - instr queue
  wire if_iq_write_pc_sig;
  wire [`AddrType] if_iq_write_pc_val;
  wire if_iq_fetch_enable;
  wire [`InstrType] if_iq_instr;
  wire [`AddrType] if_iq_pc;
  wire if_iq_result_enable;

  //instr queue - mem ctrl
  wire iq_mc_store_enable;
  wire [`AddrType] iq_mc_addr;
  wire [1: 0] iq_mc_len;
  wire [`WordType] iq_mc_data;
  wire iq_mc_result_enable;
  //instr queue - rs
  wire iq_rs_commit_flag;
  wire iq_rs_instr1_enable;
  wire iq_rs_instr1_idx;
  wire iq_rs_instr1_ready;
  wire [`RsAddrType] iq_rs_instr1_in_rs;
  wire [`RsAddrType] iq_rs_instr1_pos_in_rs;
  wire iq_rs_instr1_need_cdb;
  wire [`WordType] iq_rs_instr1_result;
  wire [`WordType] iq_rs_instr1_instr;
  wire [`OpcodeType] iq_rs_instr1_instr_optype;
  wire [`Func3Type] iq_rs_instr1_instr_func3;
  wire [`Func7Type] iq_rs_instr1_instr_func7;
  wire [`WordType] iq_rs_instr1_instr_imm;
  wire [`RegAddrType] iq_rs_instr1_instr_rs1;
  wire [`RegAddrType] iq_rs_instr1_instr_rs2;
  wire [`RegAddrType] iq_rs_instr1_instr_rd;
  wire [`AddrType] iq_rs_instr1_instr_pc;
  wire [`AddrType] iq_rs_instr1_tar_addr;
  wire iq_rs_instr1_prediction;
  wire iq_rs_instr2_enable;
  wire iq_rs_instr2_idx;
  wire iq_rs_instr2_ready;
  wire [`RsAddrType] iq_rs_instr2_in_rs;
  wire [`RsAddrType] iq_rs_instr2_pos_in_rs;
  wire iq_rs_instr2_need_cdb;
  wire [`WordType] iq_rs_instr2_result;
  wire [`WordType] iq_rs_instr2_instr;
  wire [`OpcodeType] iq_rs_instr2_instr_optype;
  wire [`Func3Type] iq_rs_instr2_instr_func3;
  wire [`Func7Type] iq_rs_instr2_instr_func7;
  wire [`WordType] iq_rs_instr2_instr_imm;
  wire [`RegAddrType] iq_rs_instr2_instr_rs1;
  wire [`RegAddrType] iq_rs_instr2_instr_rs2;
  wire [`RegAddrType] iq_rs_instr2_instr_rd;
  wire [`AddrType] iq_rs_instr2_instr_pc;
  wire [`AddrType] iq_rs_instr2_tar_addr;
  wire iq_rs_instr2_prediction;
  wire iq_rs_write_enable;
  wire [`IqAddrType] iq_rs_write_idx;
  wire iq_rs_write_result_enable;
  wire [`WordType] iq_rs_write_result;
  wire iq_rs_write_need_cdb_enable;
  wire iq_rs_write_need_cdb;
  wire iq_rs_write_ready_enable;
  wire iq_rs_write_ready;
  wire iq_rs_write_pos_in_rs_enable;
  wire iq_rs_write_pos_in_rs;
  wire iq_rs_write_tar_addr_enable;
  wire iq_rs_write_tar_addr;
  wire iq_rs_cdb_enable;
  wire [`IqAddrType] iq_rs_cdb_idx;
  wire [`WordType] iq_rs_cdb_value;
  wire iq_rs_commit_reg_enable;
  wire [`RegAddrType] iq_rs_commit_reg_idx;
  wire [`IqAddrType] iq_rs_commit_reg_rename;
  wire [`WordType] iq_rs_commit_reg_value;

  //instr queue - load buffer
  wire iq_lb_write_enable;
  wire [`IqAddrType] iq_lb_write_idx;
  wire iq_lb_write_result_enable;
  wire [`WordType] iq_lb_write_result;
  wire iq_lb_write_need_cdb_enable;
  wire iq_lb_write_need_cdb;
  wire iq_lb_write_ready_enable;
  wire iq_lb_write_ready;

  // load buffer - rs
  wire lb_rs_full;
  wire lb_rs_load_enable;
  wire [`Func3Type] lb_rs_func3;
  wire [`AddrType] lb_rs_addr;
  wire [`IqAddrType] lb_rs_pos_in_iq;

  // load buffer - mem ctrl
  wire lb_mc_fetch_enable;
  wire [`AddrType] lb_mc_addr;
  wire [1: 0] lb_mc_len;
  wire lb_mc_result_enable;
  wire [`WordType] lb_mc_data;


  // all the components
  alu alu0(
        .clk(clk_in),
        .rst(rst_in),
        .rdy(rdy_in),
        .chip_enable(),
        .update_stat(global_update_stat),
        .clear_flag_in(global_clear_flag),
        .clear_pc_in(global_clear_pc),
        .iq_write_enable_out(alu_iq_write_enable),
        .iq_write_idx_out(alu_iq_write_idx),
        .iq_write_result_enable_out(alu_iq_write_result_enable),
        .iq_write_result_out(alu_iq_write_result),
        .iq_write_need_cdb_enable_out(alu_iq_write_need_cdb_enable),
        .iq_write_need_cdb_out(alu_iq_write_need_cdb),
        .iq_write_ready_enable_out(alu_iq_write_ready_enable),
        .iq_write_ready_out(alu_iq_write_ready),
        .rs_full_out(alu_rs_full),
        .rs_calc_enable_in(alu_rs_calc_enable),
        .rs_calc_code_in(alu_rs_calc_code),
        .rs_lhs_in(alu_rs_lhs),
        .rs_rhs_in(alu_rs_rhs),
        .rs_pos_in_iq_in(alu_rs_pos_in_iq)
      );
  decoder dc0(
            .clk(clk_in),
            .rst(rst_in),
            .rdy(rdy_in),
            .chip_enable(),
            .update_stat(global_update_stat),
            .decode_ebable(dc_iq_decode_ebable),
            .instr(dc_iq_instr),
            .result_enable_out(dc_iq_result_enable),
            .opcode(dc_iq_opcode),
            .rd(dc_iq_rd),
            .rs1(dc_iq_rs1),
            .rs2(dc_iq_rs2),
            .func3(dc_iq_func3),
            .func7(dc_iq_func7),
            .imm(dc_iq_imm)
          );
  instr_fetcher if0(
                  .clk(clk_in),
                  .rst(rst_in),
                  .rdy(rdy_in),
                  .chip_enable(),
                  .update_stat(global_update_stat),
                  .clear_flag_in(global_clear_flag),
                  .clear_pc_in(global_clear_pc),
                  .mc_fetch_enable_out(if_mc_fetch_enable),
                  .mc_addr_out(if_mc_addr),
                  .mc_result_enable_in(if_mc_result_enable),
                  .mc_data_in(if_mc_data),
                  .iq_write_pc_sig_in(if_iq_write_pc_sig),
                  .iq_write_pc_val_in(if_iq_write_pc_val),
                  .iq_fetch_enable_in(if_iq_fetch_enable),
                  .iq_instr_out(if_iq_instr),
                  .iq_pc_out(if_iq_pc),
                  .iq_result_enable_out(if_iq_result_enable)
                );
  instr_queue iq0(
                .clk(clk_in),
                .rst(rst_in),
                .rdy(rdy_in),
                .chip_enable(),
                .update_stat(global_update_stat),
                .clear_flag_out(global_clear_flag),
                .clear_pc_out(global_clear_pc),
                .iq_head_out(global_iq_head),
                .iq_have_store_out(global_iq_have_store),
                .iq_first_store_idx_out(global_iq_first_store_idx),
                .mc_store_enable_out(iq_mc_store_enable),
                .mc_addr_out(iq_mc_addr),
                .mc_len_out(iq_mc_len),
                .mc_data_out(iq_mc_data),
                .mc_result_enable_in(iq_mc_result_enable),
                .if_fetch_enable_out(if_iq_fetch_enable),
                .if_instr_in(if_iq_instr),
                .if_pc_in(if_iq_pc),
                .if_result_enable_in(if_iq_result_enable),
                .if_write_pc_sig_out(if_iq_write_pc_sig),
                .if_write_pc_val_out(if_iq_write_pc_val),
                .dc_decode_enable_out(dc_iq_decode_enable),
                .dc_instr_out(dc_iq_instr),
                .dc_result_enable_in(dc_iq_result_enable),
                .dc_opcode_in(dc_iq_opcode),
                .dc_rd_in(dc_iq_rd),
                .dc_rs1_in(dc_iq_rs1),
                .dc_rs2_in(dc_iq_rs2),
                .dc_func3_in(dc_iq_func3),
                .dc_func7_in(dc_iq_func7),
                .dc_imm_in(dc_iq_imm),
                // .pd_predict_enable_out(),
                // .pd_pc_out(),
                // .pd_result_enable_in(),
                // .pd_prediction_in(),
                .rs_commit_flag_out(iq_rs_commit_flag),
                .rs_instr1_enable_out(iq_rs_instr1_enable),
                .rs_instr1_idx_out(iq_rs_instr1_idx),
                .rs_instr1_ready_out(iq_rs_instr1_ready),
                .rs_instr1_in_rs_out(iq_rs_instr1_in_rs),
                .rs_instr1_pos_in_rs_out(iq_rs_instr1_pos_in_rs),
                .rs_instr1_need_cdb_out(iq_rs_instr1_need_cdb),
                .rs_instr1_result_out(iq_rs_instr1_result),
                .rs_instr1_instr_out(iq_rs_instr1_instr),
                .rs_instr1_instr_optype_out(iq_rs_instr1_instr_optype),
                .rs_instr1_instr_func3_out(iq_rs_instr1_instr_func3),
                .rs_instr1_instr_func7_out(iq_rs_instr1_instr_func7),
                .rs_instr1_instr_imm_out(iq_rs_instr1_instr_imm),
                .rs_instr1_instr_rs1_out(iq_rs_instr1_instr_rs1),
                .rs_instr1_instr_rs2_out(iq_rs_instr1_instr_rs2),
                .rs_instr1_instr_rd_out(iq_rs_instr1_instr_rd),
                .rs_instr1_instr_pc_out(iq_rs_instr1_instr_pc),
                .rs_instr1_tar_addr_out(iq_rs_instr1_tar_addr),
                .rs_instr1_prediction_out(iq_rs_instr1_prediction),
                .rs_instr2_enable_out(iq_rs_instr2_enable),
                .rs_instr2_idx_out(iq_rs_instr2_idx),
                .rs_instr2_ready_out(iq_rs_instr2_ready),
                .rs_instr2_in_rs_out(iq_rs_instr2_in_rs),
                .rs_instr2_pos_in_rs_out(iq_rs_instr2_pos_in_rs),
                .rs_instr2_need_cdb_out(iq_rs_instr2_need_cdb),
                .rs_instr2_result_out(iq_rs_instr2_result),
                .rs_instr2_instr_out(iq_rs_instr2_instr),
                .rs_instr2_instr_optype_out(iq_rs_instr2_instr_optype),
                .rs_instr2_instr_func3_out(iq_rs_instr2_instr_func3),
                .rs_instr2_instr_func7_out(iq_rs_instr2_instr_func7),
                .rs_instr2_instr_imm_out(iq_rs_instr2_instr_imm),
                .rs_instr2_instr_rs1_out(iq_rs_instr2_instr_rs1),
                .rs_instr2_instr_rs2_out(iq_rs_instr2_instr_rs2),
                .rs_instr2_instr_rd_out(iq_rs_instr2_instr_rd),
                .rs_instr2_instr_pc_out(iq_rs_instr2_instr_pc),
                .rs_instr2_tar_addr_out(iq_rs_instr2_tar_addr),
                .rs_instr2_prediction_out(iq_rs_instr2_prediction),
                .rs_write_enable_in(iq_rs_write_enable),
                .rs_write_idx_in(iq_rs_write_idx),
                .rs_write_result_enable_in(iq_rs_write_result_enable),
                .rs_write_result_in(iq_rs_write_result),
                .rs_write_need_cdb_enable_in(iq_rs_write_need_cdb_enable),
                .rs_write_need_cdb_in(iq_rs_write_need_cdb),
                .rs_write_ready_enable_in(iq_rs_write_ready_enable),
                .rs_write_ready_in(iq_rs_write_ready),
                .rs_write_pos_in_rs_enable_in(iq_rs_write_pos_in_rs_enable),
                .rs_write_pos_in_rs_in(iq_rs_write_pos_in_rs),
                .rs_write_tar_addr_enable_in(iq_rs_write_tar_addr_enable),
                .rs_write_tar_addr_in(iq_rs_write_tar_addr),
                .rs_cdb_enable_out(iq_rs_cdb_enable),
                .rs_cdb_idx_out(iq_rs_cdb_idx),
                .rs_cdb_value_out(iq_rs_cdb_value),
                .rs_commit_reg_enable_out(iq_rs_commit_reg_enable),
                .rs_commit_reg_idx_out(iq_rs_commit_reg_idx),
                .rs_commit_reg_rename_out(iq_rs_commit_reg_rename),
                .rs_commit_reg_value_out(iq_rs_commit_reg_value),
                .alu_write_enable_in(alu_iq_write_enable),
                .alu_write_idx_in(alu_iq_write_idx),
                .alu_write_result_enable_in(alu_iq_write_result_enable),
                .alu_write_result_in(alu_iq_write_result),
                .alu_write_need_cdb_enable_in(alu_iq_write_need_cdb_enable),
                .alu_write_need_cdb_in(alu_iq_write_need_cdb),
                .alu_write_ready_enable_in(alu_iq_write_ready_enable),
                .alu_write_ready_in(alu_iq_write_ready),
                .lb_write_enable_in(iq_lb_write_enable),
                .lb_write_idx_in(iq_lb_write_idx),
                .lb_write_result_enable_in(iq_lb_write_result_enable),
                .lb_write_result_in(iq_lb_write_result),
                .lb_write_need_cdb_enable_in(iq_lb_write_need_cdb_enable),
                .lb_write_need_cdb_in(iq_lb_write_need_cdb),
                .lb_write_ready_enable_in(iq_lb_write_ready_enable),
                .lb_write_ready_in(iq_lb_write_ready)
              );
  load_buffer lb0(
                .clk(clk_in),
                .rst(rst_in),
                .rdy(rdy_in),
                .chip_enable(),
                .update_stat(global_update_stat),
                .clear_flag_in(global_clear_flag),
                .clear_pc_in(global_clear_pc),
                .rs_full_out(lb_rs_full),
                .rs_load_enable_in(lb_rs_load_enable),
                .rs_func3_in(lb_rs_func3),
                .rs_addr_in(lb_rs_addr),
                .rs_pos_in_iq_in(lb_rs_pos_in_iq),
                .mc_fetch_enable_out(lb_mc_fetch_enable),
                .mc_addr_out(lb_mc_addr),
                .mc_len_out(lb_mc_len),
                .mc_result_enable_in(lb_mc_result_enable),
                .mc_data_in(lb_mc_data),
                .iq_write_enable_out(iq_lb_write_enable),
                .iq_write_idx_out(iq_lb_write_idx),
                .iq_write_result_enable_out(iq_lb_write_result_enable),
                .iq_write_result_out(iq_lb_write_result),
                .iq_write_need_cdb_enable_out(iq_lb_write_need_cdb_enable),
                .iq_write_need_cdb_out(iq_lb_write_need_cdb),
                .iq_write_ready_enable_out(iq_lb_write_ready_enable),
                .iq_write_ready_out(iq_lb_write_ready)
              );
  mem_ctrl mc0(
             .clk(clk_in),
             .rst(rst_in),
             .rdy(rdy_in),
             .chip_enable(),
             .update_stat(global_update_stat),
             .clear_flag_in(global_clear_flag),
             .clear_pc_in(global_clear_pc),
             .if_fetch_enable_in(if_mc_fetch_enable),
             .if_addr_in(if_mc_addr),
             .if_result_enable_out(if_mc_result_enable),
             .if_data_out(if_mc_data),
             .lb_fetch_enable_in(lb_mc_fetch_enable),
             .lb_addr_in(lb_mc_addr),
             .lb_len_in(lb_mc_len),
             .lb_result_enable_out(lb_mc_result_enable),
             .lb_data_out(lb_mc_data),
             .iq_store_enable_in(iq_mc_store_enable),
             .iq_addr_in(iq_mc_addr),
             .iq_len_in(iq_mc_len),
             .iq_data_in(iq_mc_data),
             .iq_result_enable_out(iq_mc_result_enable),
             .ram_rw_select_out(mem_wr),
             .ram_addr_out(mem_a),
             .ram_data_out(mem_dout),
             .ram_data_in(mem_din)
           );
  rs rs0(
       .clk(clk_in),
       .rst(rst_in),
       .rdy(rdy_in),
       .chip_enable(),
       .update_stat(global_update_stat),
       .clear_flag_in(global_clear_flag),
       .clear_pc_in(global_clear_pc),
       .iq_head_out(global_iq_head),
       .iq_have_store_out(global_iq_have_store),
       .iq_first_store_idx_out(global_iq_first_store_idx),
       .iq_commit_flag_in(iq_rs_commit_flag),
       .iq_instr1_enable_in(iq_rs_instr1_enable),
       .iq_instr1_idx_in(iq_rs_instr1_idx),
       .iq_instr1_ready_in(iq_rs_instr1_ready),
       .iq_instr1_in_rs_in(iq_rs_instr1_in_rs),
       .iq_instr1_pos_in_rs_in(iq_rs_instr1_pos_in_rs),
       .iq_instr1_need_cdb_in(iq_rs_instr1_need_cdb),
       .iq_instr1_result_in(iq_rs_instr1_result),
       .iq_instr1_instr_in(iq_rs_instr1_instr),
       .iq_instr1_instr_optype_in(iq_rs_instr1_instr_optype),
       .iq_instr1_instr_func3_in(iq_rs_instr1_instr_func3),
       .iq_instr1_instr_func7_in(iq_rs_instr1_instr_func7),
       .iq_instr1_instr_imm_in(iq_rs_instr1_instr_imm),
       .iq_instr1_instr_rs1_in(iq_rs_instr1_instr_rs1),
       .iq_instr1_instr_rs2_in(iq_rs_instr1_instr_rs2),
       .iq_instr1_instr_rd_in(iq_rs_instr1_instr_rd),
       .iq_instr1_instr_pc_in(iq_rs_instr1_instr_pc),
       .iq_instr1_tar_addr_in(iq_rs_instr1_tar_addr),
       .iq_instr1_prediction_in(iq_rs_instr1_prediction),
       .iq_instr2_enable_in(iq_rs_instr2_enable),
       .iq_instr2_idx_in(iq_rs_instr2_idx),
       .iq_instr2_ready_in(iq_rs_instr2_ready),
       .iq_instr2_in_rs_in(iq_rs_instr2_in_rs),
       .iq_instr2_pos_in_rs_in(iq_rs_instr2_pos_in_rs),
       .iq_instr2_need_cdb_in(iq_rs_instr2_need_cdb),
       .iq_instr2_result_in(iq_rs_instr2_result),
       .iq_instr2_instr_in(iq_rs_instr2_instr),
       .iq_instr2_instr_optype_in(iq_rs_instr2_instr_optype),
       .iq_instr2_instr_func3_in(iq_rs_instr2_instr_func3),
       .iq_instr2_instr_func7_in(iq_rs_instr2_instr_func7),
       .iq_instr2_instr_imm_in(iq_rs_instr2_instr_imm),
       .iq_instr2_instr_rs1_in(iq_rs_instr2_instr_rs1),
       .iq_instr2_instr_rs2_in(iq_rs_instr2_instr_rs2),
       .iq_instr2_instr_rd_in(iq_rs_instr2_instr_rd),
       .iq_instr2_instr_pc_in(iq_rs_instr2_instr_pc),
       .iq_instr2_tar_addr_in(iq_rs_instr2_tar_addr),
       .iq_instr2_prediction_in(iq_rs_instr2_prediction),
       .iq_write_enable_out(iq_rs_write_enable),
       .iq_write_idx_out(iq_rs_write_idx),
       .iq_write_result_enable_out(iq_rs_write_result_enable),
       .iq_write_result_out(iq_rs_write_result),
       .iq_write_need_cdb_enable_out(iq_rs_write_need_cdb_enable),
       .iq_write_need_cdb_out(iq_rs_write_need_cdb),
       .iq_write_ready_enable_out(iq_rs_write_ready_enable),
       .iq_write_ready_out(iq_rs_write_ready),
       .iq_write_pos_in_rs_enable_out(iq_rs_write_pos_in_rs_enable),
       .iq_write_pos_in_rs_out(iq_rs_write_pos_in_rs),
       .iq_write_tar_addr_enable_out(iq_rs_write_tar_addr_enable),
       .iq_write_tar_addr_out(iq_rs_write_tar_addr),
       .iq_cdb_enable_in(iq_rs_cdb_enable),
       .iq_cdb_idx_in(iq_rs_cdb_idx),
       .iq_cdb_value_in(iq_rs_cdb_value),
       .iq_commit_reg_enable_in(iq_rs_commit_reg_enable),
       .iq_commit_reg_idx_in(iq_rs_commit_reg_idx),
       .iq_commit_reg_rename_in(iq_rs_commit_reg_rename),
       .iq_commit_reg_value_in(iq_rs_commit_reg_value),
       .alu_full_in(alu_rs_full),
       .alu_calc_enable_out(alu_rs_calc_enable),
       .alu_calc_code_out(alu_rs_calc_code),
       .alu_lhs_out(alu_rs_lhs),
       .alu_rhs_out(alu_rs_rhs),
       .alu_pos_in_iq_out(alu_rs_pos_in_iq),
       .lb_full_in(lb_rs_full),
       .lb_load_enable_out(lb_rs_load_enable),
       .lb_func3_out(lb_rs_func3),
       .lb_addr_out(lb_rs_addr),
       .lb_pos_in_iq_out(lb_rs_pos_in_iq)
     );
  updater updater0(
            .clk(clk_in),
            .rst(rst_in),
            .rdy(rdy_in),
            .chip_enable(),
            .update_stat(global_update_stat));
  // Specifications:
  // - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
  // - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
  // - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
  // - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
  // - 0x30000 read: read a byte from input
  // - 0x30000 write: write a byte to output (write 0x00 is ignored)
  // - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
  // - 0x30004 write: indicates program stop (will output '\0' through uart tx)

  always @(posedge clk_in) begin
    if (rst_in) begin

    end
    else if (!rdy_in) begin

    end
    else begin

    end
  end

endmodule
