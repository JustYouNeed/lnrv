`include    "lnrv_def.v"
module	lnrv_exu_rglr
(
    input                                       rglr_op_vld,
    output                                      rglr_op_rdy,
    input[`RGLR_OP_BUS_WIDTH - 1 : 0]           rglr_op_bus,

    input[31 : 0]                               rs1_rdata,
    input[31 : 0]                               rs2_rdata,
    input[31 : 0]                               imm,
    input[31 : 0]                               pc,

    output                                      rglr2alu_op_vld,
    input                                       rglr2alu_op_rdy,
    output[`ALU_OP_BUS_WIDTH - 1 : 0]           rglr2alu_op_bus,
    output[31 : 0]                              rglr2alu_in1,
    output[31 : 0]                              rglr2alu_in1,

    // 通用寄存器写回接口
    output                                      rglr2gpr_wbck_vld,
    input                                       rglr2gpr_wbck_rdy
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

wire                                alu_hsked;

assign      alu_hsked = rglr2alu_op_vld & rglr2alu_op_rdy;

//从总线中取出各个运算操作
assign      instr_is_add    = rglr_op_bus[`RGLR_ADD_LOC];
assign      instr_is_sub    = rglr_op_bus[`RGLR_SUB_LOC];
assign      instr_is_and    = rglr_op_bus[`RGLR_AND_LOC];
assign      instr_is_or     = rglr_op_bus[`RGLR_OR_LOC];
assign      instr_is_xor    = rglr_op_bus[`RGLR_XOR_LOC];
assign      instr_is_sll    = rglr_op_bus[`RGLR_SLL_LOC];
assign      instr_is_slt    = rglr_op_bus[`RGLR_SLT_LOC];
assign      instr_is_sltu   = rglr_op_bus[`RGLR_SLTU_LOC];
assign      instr_is_sra    = rglr_op_bus[`RGLR_SRA_LOC];
assign      instr_is_srl    = rglr_op_bus[`RGLR_SRL_LOC];
assign      instr_is_auipc  = rglr_op_bus[`RGLR_AUIPC_LOC];
assign      instr_is_lui    = rglr_op_bus[`RGLR_LUI_LOC];

assign      op1_is_pc       = rglr_op_bus[`RGLR_OP1_IS_PC];
assign      op2_is_imm      = rglr_op_bus[`RGLR_OP2_IS_IMM];


assign      rglr2alu_op_bus[`ALU_ADD_LOC]   = instr_is_add;
assign      rglr2alu_op_bus[`ALU_SUB_LOC]   = instr_is_sub;
assign      rglr2alu_op_bus[`ALU_OR_LOC]    = instr_is_or | instr_is_auipc | instr_is_lui;
assign      rglr2alu_op_bus[`ALU_AND_LOC]   = instr_is_and;
assign      rglr2alu_op_bus[`ALU_XOR_LOC]   = instr_is_xor;
assign      rglr2alu_op_bus[`ALU_SLL_LOC]   = instr_is_sll;
assign      rglr2alu_op_bus[`ALU_SRL_LOC]   = instr_is_srl;
assign      rglr2alu_op_bus[`ALU_SRA_LOC]   = instr_is_sra;
assign      rglr2alu_op_bus[`ALU_LT_LOC]    = instr_is_slt;
assign      rglr2alu_op_bus[`ALU_LTU_LOC]   = instr_is_sltu;
assign      rglr2alu_op_bus[`ALU_GTEU_LOC]  = 1'b0;
assign      rglr2alu_op_bus[`ALU_GTE_LOC]   = 1'b0;
assign      rglr2alu_op_bus[`ALU_NEQ_LOC]   = 1'b0;
assign      rglr2alu_op_bus[`ALU_EQ_LOC]    = 1'b0;

assign      rglr2alu_op_vld                 = rglr_op_vld;

// 选择输出到alu的数据
assign      rglr2alu_in1 =  op1_is_pc ? pc : 
                            instr_is_lui ? 32'd0 : 
                            rs1_rdata;

assign      rglr2alu_in2 = op2_is_imm ? imm : rs2_rdata;


// assign      gpr_wbck_data =   op_slt ? {{31{1'b0}}, alu_cmp_res} : 
//                             alu_logic_res;
assign      rglr2gpr_wbck_vld = alu_hsked;

assign      rglr_op_rdy = rglr2gpr_wbck_rdy;

endmodule



