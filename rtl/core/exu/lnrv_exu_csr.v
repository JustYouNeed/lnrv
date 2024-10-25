`include "lnrv_def.v"
module lnrv_exu_csr
(
    input                               csr_op_vld,
    output                              csr_op_rdy,
    input[`CSR_OP_BUS_WIDTH - 1 : 0]    csr_op_bus,

    input[31 : 0]                       imm,
    input                               csr_idx_err,
    input[31 : 0]                       csr_rdata,
    input[31 : 0]                       rs1_rdata,

    // alu接口
    output                              csralu_op_vld,
    input                               csralu_op_rdy,
    output[`ALU_OP_BUS_WIDTH - 1 : 0]   csralu_op_bus,
    output[31 : 0]                      csralu_in1,
    output[31 : 0]                      csralu_in2,

    // 交付接口
    output                              csr_cmt_vld,
    input                               csr_cmt_rdy,
    output                              csr_cmt_gpr_wen,
    output                              csr_cmt_csr_wen,
    output                              csr_cmt_idx_err
);

wire                                instr_is_csrrc;
wire                                instr_is_csrrw;
wire                                instr_is_csrrs;
wire                                op1_is_zero;
wire                                op2_is_imm;

wire[31 : 0]                        op1;
wire[31 : 0]                        op2;

wire                                need_alu;

wire                                alu_hsked;

assign      alu_hsked = alu_op_vld & alu_op_rdy;

assign      instr_is_csrrc  = op_bus[`CSR_CSRRC_LOC];
assign      instr_is_csrrw  = op_bus[`CSR_CSRRW_LOC];
assign      instr_is_csrrs  = op_bus[`CSR_CSRRS_LOC];
assign      op2_is_imm      = op_bus[`CSR_OP2_IS_IMM];
assign      rs1_is_0        = op_bus[`CSR_RS1_IS_0];

assign      op1 = instr_is_csrrw ? 32'd0 : csr_rdata;
assign      op2 = op2_is_imm ? imm : rs1_rdata;

assign      need_alu = instr_is_csrrc | instr_is_csrrs;

assign      alu_in1 = op1;
assign      alu_in2 = instr_is_csrrc ? (~op2) : op2;
assign      alu_op_vld = csr_op_vld;

assign      alu_op_bus[`ALU_ADD_LOC]    = 1'b0;
assign      alu_op_bus[`ALU_SUB_LOC]    = 1'b0;
assign      alu_op_bus[`ALU_OR_LOC]     = instr_is_csrrs | instr_is_csrrw;
assign      alu_op_bus[`ALU_XOR_LOC]    = 1'b0;
assign      alu_op_bus[`ALU_AND_LOC]    = instr_is_csrrc;
assign      alu_op_bus[`ALU_SLL_LOC]    = 1'b0;
assign      alu_op_bus[`ALU_SRL_LOC]    = 1'b0;
assign      alu_op_bus[`ALU_SRA_LOC]    = 1'b0;
assign      alu_op_bus[`ALU_LT_LOC]     = 1'b0;
assign      alu_op_bus[`ALU_LTU_LOC]    = 1'b0;
assign      alu_op_bus[`ALU_GTE_LOC]    = 1'b0;
assign      alu_op_bus[`ALU_GTEU_LOC]   = 1'b0;
assign      alu_op_bus[`ALU_NEQ_LOC]    = 1'b0;
assign      alu_op_bus[`ALU_EQ_LOC]     = 1'b0;


assign      csr_cmt_vld         = need_alu ? (alu_op_rdy & csr_op_vld) : csr_op_vld;
assign      csr_cmt_idx_err     = csr_idx_err;
assign      csr_cmt_csr_wen     = csr_op_vld & (instr_is_csrrw | (instr_is_csrrc | instr_is_csrrs) & (~rs1_is_0));
assign      csr_cmt_gpr_wen     = csr_op_vld

endmodule