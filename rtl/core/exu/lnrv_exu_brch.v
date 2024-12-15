`include    "lnrv_def.v"
module lnrv_exu_brch
(
    input                                   op_vld,
    output                                  op_rdy,
    input[`BRCH_OP_BUS_WIDTH - 1 : 0]       op_bus,

    input[31 : 0]                           rs1_rdata,
    input[31 : 0]                           rs2_rdata,
    input[31 : 0]                           pc,
    input[31 : 0]                           imm,

    output                                  alu_op_vld,
    input                                   alu_op_rdy,
    output[`ALU_OP_BUS_WIDTH - 1 : 0]       alu_op_bus,
    output[31 : 0]                          alu_in1,
    output[31 : 0]                          alu_in2,
    input[31 : 0]                           alu_res,

    output                                  cmt_vld,
    input                                   cmt_rdy,
    output                                  cmt_dret,
    output                                  cmt_mret,
    output                                  cmt_fence,
    output                                  cmt_bjp,
    output                                  cmt_jal,
    output                                  cmt_jalr,

    output                                  gpr_wen,
    output[31 : 0]                          gpr_wdata
);

// 该模块处理分支相关指令:
// beq: if(x[rs1] == x[rs2]) pc += sext(imm)
// bge: if(x[rs1] >= x[rs2]) pc += sext(imm), x[rs1]、x[rs2]视为有符号数
// bgeu: if(x[rs1] >= x[rs2]) pc += sext(imm), x[rs1]、x[rs2]视为无符号数
// blt: if(x[rs1] < x[rs2]) pc += sext(imm), x[rs1]、x[rs2]视为有符号数
// bltu: if(x[rs1] < x[rs2]) pc += sext(imm), x[rs1]、x[rs2]视为无符号数
// bne: if(x[rs1] != x[rs2]) pc += sext(imm)
// jal: x[rd] = pc + 4, pc += imm
// jalr: x[rd] = pc + 4, pc += imm

wire                        instr_is_beq;
wire                        instr_is_bge;
wire                        instr_is_bgeu;
wire                        instr_is_blt;
wire                        instr_is_bltu;
wire                        instr_is_bne;
wire                        instr_is_jal;
wire                        instr_is_jalr;
wire                        instr_is_mret;
wire                        instr_is_dret;
// wire                        instr_is_fencei;
wire                        instr_is_fence;
wire                        instr_is_bxx;

wire                        op1_is_pc;
wire                        op2_is_imm;

wire                        need_alu;

assign      instr_is_beq    = op_bus[`BRCH_BEQ_LOC];
assign      instr_is_bge    = op_bus[`BRCH_BGE_LOC];
assign      instr_is_bgeu   = op_bus[`BRCH_BGEU_LOC];
assign      instr_is_blt    = op_bus[`BRCH_BLT_LOC];
assign      instr_is_bltu   = op_bus[`BRCH_BLTU_LOC];
assign      instr_is_bne    = op_bus[`BRCH_BNE_LOC];
assign      instr_is_jal    = op_bus[`BRCH_JAL_LOC];
assign      instr_is_jalr   = op_bus[`BRCH_JALR_LOC];
assign      instr_is_mret   = op_bus[`BRCH_MRET_LOC];
assign      instr_is_dret   = op_bus[`BRCH_DRET_LOC];
// assign      instr_is_fencei = op_bus[`BRCH_FENCEI_LOC];
assign      instr_is_fence  = op_bus[`BRCH_FENCE_LOC];

assign      instr_is_bxx    =   instr_is_beq | 
                                instr_is_bge | 
                                instr_is_bgeu | 
                                instr_is_blt | 
                                instr_is_bltu | 
                                instr_is_bne;

assign      op1_is_pc       = op_bus[`BRCH_OP1_IS_PC];
assign      op2_is_imm      = op_bus[`BRCH_OP2_IS_IMM];

// 除了下列指令，都需要使用alu
assign      need_alu = ~(
                            instr_is_mret | 
                            instr_is_dret | 
                            instr_is_fence
                        );

assign      alu_op_vld                  = op_vld & need_alu;
assign      alu_op_bus[`ALU_ADD_LOC]    = instr_is_jal | instr_is_jalr;
assign      alu_op_bus[`ALU_SLL_LOC]    = 1'b0;
assign      alu_op_bus[`ALU_SUB_LOC]    = 1'b0;
assign      alu_op_bus[`ALU_SRL_LOC]    = 1'b0;
assign      alu_op_bus[`ALU_SRA_LOC]    = 1'b0;
assign      alu_op_bus[`ALU_XOR_LOC]    = 1'b0;
assign      alu_op_bus[`ALU_OR_LOC]     = 1'b0;
assign      alu_op_bus[`ALU_AND_LOC]    = 1'b0;
assign      alu_op_bus[`ALU_LT_LOC]     = instr_is_blt;
assign      alu_op_bus[`ALU_LTU_LOC]    = instr_is_bltu;
assign      alu_op_bus[`ALU_NEQ_LOC]    = instr_is_bne;
assign      alu_op_bus[`ALU_EQ_LOC]     = instr_is_beq;
assign      alu_op_bus[`ALU_GTEU_LOC]   = instr_is_bgeu;
assign      alu_op_bus[`ALU_GTE_LOC]    = instr_is_bge;

// 如果是直接跳转指令，需要执行pc + 4，否则就是比较x[rs1]和x[rs2]两个寄存器中的值
assign      alu_in1                     = op1_is_pc ? pc : rs1_rdata;
assign      alu_in2                     = op2_is_imm ? 32'd4 : rs2_rdata;


assign      cmt_bjp    = instr_is_bxx & alu_res[0];
assign      cmt_dret   = instr_is_dret;
assign      cmt_mret   = instr_is_mret;
assign      cmt_fence  = instr_is_fence;
assign      cmt_jal    = instr_is_jal;
assign      cmt_jalr   = instr_is_jalr;

// 如果需要使用alu，则需要等alu就绪才可以交付
assign      cmt_vld = need_alu ? alu_op_rdy : op_vld;

assign      op_rdy = cmt_rdy;

// 只有jal和jalr两个指令需要写回
assign      gpr_wen = instr_is_jal | instr_is_jalr;
assign      gpr_wdata = alu_res;

endmodule