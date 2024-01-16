`include "lnrv_def.v"
module lnrv_exu_csr
(
    input                               op_vld,
    output                              op_rdy,
    input[`CSR_OP_BUS_WIDTH - 1 : 0]    op_bus,
    input[31 : 0]                       imm,

    input[11 : 0]                       csr_idx,
    input[31 : 0]                       csr_rdata,
    input[31 : 0]                       rs1_rdata,
    // input[31 : 0]                       rs2_rdata,

    // alu接口
    output                              alu_op_vld,
    input                               alu_op_rdy,
    output[`ALU_OP_BUS_WIDTH - 1 : 0]   alu_op_bus,
    output[31 : 0]                      alu_in1,
    output[31 : 0]                      alu_in2,
    input[31 : 0]                       alu_res,

    // 通用寄存器写回接口
    output                              gpr_wbck_vld,
    input                               gpr_wbck_rdy,
    output[31 : 0]                      gpr_wbck_wdata,

    // csr寄存器写回通道
    output                              csr_wbck_vld,
    input                               csr_wbck_rdy,
    output[11 : 0]                      csr_wbck_idx,
    output[31 : 0]                      csr_wbck_wdata
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
assign      op1_is_zero     = op_bus[`CSR_OP1_IS_ZERO];
assign      op2_is_imm      = op_bus[`CSR_OP2_IS_IMM];

assign      op1 = op1_is_zero ? 32'd0 : csr_rdata;
assign      op2 = op2_is_imm ? imm : rs1_rdata;

assign      need_alu = instr_is_csrrc | instr_is_csrrs;

assign      alu_in1 = op1;
assign      alu_in2 = instr_is_csrrc ? (~op2) : op2;
assign      alu_op_vld = op_vld & need_alu;

assign      alu_op_bus[`ALU_ADD_LOC]    = 1'b0;
assign      alu_op_bus[`ALU_SUB_LOC]    = 1'b0;
assign      alu_op_bus[`ALU_OR_LOC]     = instr_is_csrrs;
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


assign      gpr_wbck_vld = need_alu ? alu_hsked : op_vld;
assign      gpr_wbck_wdata = csr_rdata;

assign      csr_wbck_vld = gpr_wbck_vld;
assign      csr_wbck_idx = csr_idx;
assign      csr_wbck_wdata = need_alu ? alu_res : op2;

assign      op_rdy = gpr_wbck_rdy & csr_wbck_rdy;

endmodule