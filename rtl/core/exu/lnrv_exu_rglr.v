`include    "lnrv_def.v"
module	lnrv_exu_rglr
(
    input                                       op_vld,
    output                                      op_rdy,
    input[`RGLR_OP_BUS_WIDTH - 1 : 0]           op_bus,

    input[31 : 0]                               rs1_rdata,
    input[31 : 0]                               rs2_rdata,
    input[31 : 0]                               imm,
    input[31 : 0]                               pc,

    output                                      alu_op_vld,
    input                                       alu_op_rdy,
    output[`ALU_OP_BUS_WIDTH - 1 : 0]           alu_op_bus,
    output[32 : 0]                              alu_in1,
    output[32 : 0]                              alu_in2,
    input[34 : 0]                               alu_res,

    output                                      cmt_vld,
    input                                       cmt_rdy,

    output                                      gpr_wen,
    output[31 : 0]                              gpr_wdata
);

// 该模块处理以下指令:
// add: x[rd] = x[rs1] + x[rs2]
// addi: x[rd] = x[rs1] + imm
// and: x[rd] = x[rs1] & x[rs2]
// andi: x[rd] = x[rs1] & x[rs2]
// auipc: x[rd] = pc + imm
// or: x[rd] = x[rs1] | x[rs2]
// ori: x[rd] = x[rs1] | imm
// sll: x[rd] = x[rs1] << x[rs2]
// slli: x[rd] = x[rs1] << imm
// slt: x[rd] = x[rs1] < x[rs2]
// slti: x[rd] = x[rs1] < uext(imm)
// sltu: x[rd] = x[rs1] < unsiged(x[rs2])
// sra: x[rd] = x[rs1] >> x[rs2] 算术右移
// srai: x[rd] = x[rs1] >> imm 算术右移
// srl: x[rd] = x[rs1] >> x[rs2]
// srli: x[rd] = x[rs1] >> imm
// sub: x[rd] = x[rs1] - x[rs2]
// xor: x[rd] = x[rs1] ^ x[rs2]
// xori: x[rd] = x[rs1] ^ imm
// lui: x[rd] = sext(imm)


wire                                instr_is_add;
wire                                instr_is_sub;
wire                                instr_is_and;
wire                                instr_is_or;
wire                                instr_is_xor;
wire                                instr_is_sll;
wire                                instr_is_slt;
wire                                instr_is_sltu;
wire                                instr_is_sra;
wire                                instr_is_srl;
wire                                instr_is_auipc;
wire                                instr_is_lui;

wire                                op1_is_pc;
wire                                op2_is_imm;


//从总线中取出各个运算操作
assign      instr_is_add    = op_bus[`RGLR_ADD_LOC];
assign      instr_is_sub    = op_bus[`RGLR_SUB_LOC];
assign      instr_is_and    = op_bus[`RGLR_AND_LOC];
assign      instr_is_or     = op_bus[`RGLR_OR_LOC];
assign      instr_is_xor    = op_bus[`RGLR_XOR_LOC];
assign      instr_is_sll    = op_bus[`RGLR_SLL_LOC];
assign      instr_is_slt    = op_bus[`RGLR_SLT_LOC];
assign      instr_is_sltu   = op_bus[`RGLR_SLTU_LOC];
assign      instr_is_sra    = op_bus[`RGLR_SRA_LOC];
assign      instr_is_srl    = op_bus[`RGLR_SRL_LOC];
assign      instr_is_auipc  = op_bus[`RGLR_AUIPC_LOC];
assign      instr_is_lui    = op_bus[`RGLR_LUI_LOC];
assign      op1_is_pc       = op_bus[`RGLR_OP1_IS_PC];
assign      op2_is_imm      = op_bus[`RGLR_OP2_IS_IMM];

// 生成ALU操作总线
assign      alu_op_vld                          = op_vld;
assign      alu_op_bus[`ALU_ADD_LOC]            = instr_is_add;
assign      alu_op_bus[`ALU_SUB_LOC]            = instr_is_sub;
assign      alu_op_bus[`ALU_OR_LOC]             = instr_is_or | instr_is_auipc | instr_is_lui;
assign      alu_op_bus[`ALU_AND_LOC]            = instr_is_and;
assign      alu_op_bus[`ALU_XOR_LOC]            = instr_is_xor;
assign      alu_op_bus[`ALU_SLL_LOC]            = instr_is_sll;
assign      alu_op_bus[`ALU_SRL_LOC]            = instr_is_srl;
assign      alu_op_bus[`ALU_SRA_LOC]            = instr_is_sra;
assign      alu_op_bus[`ALU_LT_LOC]             = instr_is_slt;
assign      alu_op_bus[`ALU_LTU_LOC]            = instr_is_sltu;
assign      alu_op_bus[`ALU_GTEU_LOC]           = 1'b0;
assign      alu_op_bus[`ALU_GTE_LOC]            = 1'b0;
assign      alu_op_bus[`ALU_NEQ_LOC]            = 1'b0;
assign      alu_op_bus[`ALU_EQ_LOC]             = 1'b0;
assign      alu_op_bus[`ALU_IN1_IS_UNSIGED]     = instr_is_sltu;
assign      alu_op_bus[`ALU_IN2_IS_UNSIGED]     = instr_is_sltu;

assign      alu_in1[0 +: 32]                    =   op1_is_pc ? pc : 
                                                    instr_is_lui ? 32'd0 : 
                                                    rs1_rdata;
assign      alu_in1[32 +: 1]                    = alu_in1[31];
assign      alu_in2[0 +: 32]                    = op2_is_imm ? imm : rs2_rdata;
assign      alu_in2[32 +: 1]                    = alu_in2[31];


// 所有常规指令都需要写回GPR
assign      gpr_wen = op_vld;
assign      gpr_wdata = alu_res[0 +: 32];

assign      cmt_vld = alu_op_rdy;

assign      op_rdy = cmt_rdy;
endmodule



