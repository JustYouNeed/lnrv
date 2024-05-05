`include    "lnrv_def.v"
module lnrv_exu_brch
(
    input                                   brch_op_vld,
    output                                  brch_op_rdy,
    input[`BRCH_OP_BUS_WIDTH - 1 : 0]       brch_op_bus,

    input[31 : 0]                           rs1_rdata,
    input[31 : 0]                           rs2_rdata,
    input[31 : 0]                           pc,
    input[31 : 0]                           imm,

    output                                  alu_op_vld,
    input                                   alu_op_rdy,
    output[`ALU_OP_BUS_WIDTH - 1 : 0]       alu_op_bus,
    output[31 : 0]                          alu_in1,
    output[31 : 0]                          alu_in2,
    input[31 : 0]                           alu_add_res,
    input                                   alu_cmp_res,

    input[31 : 0]                           dpc,
    input[31 : 0]                           mepc,

    output                                  brch_cmt_vld,
    input                                   brch_cmt_rdy,
    output                                  brch_cmt_dret,
    output                                  brch_cmt_mret,
    output                                  brch_cmt_fence,
    output                                  brch_cmt_bjp,
    output                                  brch_cmt_bjp_res,

    output                                  gpr_wbck_vld,
    input                                   gpr_wbck_rdy
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

wire                        brch_must_taken;
wire                        brch_cond_taken;
wire                        brch_taken;

wire                        need_wbck;
wire                        need_alu;
wire                        alu_hsked;


assign      alu_hsked = alu_op_vld & alu_op_rdy;

assign      instr_is_beq    = brch_op_bus[`BRCH_BEQ_LOC];
assign      instr_is_bge    = brch_op_bus[`BRCH_BGE_LOC];
assign      instr_is_bgeu   = brch_op_bus[`BRCH_BGEU_LOC];
assign      instr_is_blt    = brch_op_bus[`BRCH_BLT_LOC];
assign      instr_is_bltu   = brch_op_bus[`BRCH_BLTU_LOC];
assign      instr_is_bne    = brch_op_bus[`BRCH_BNE_LOC];
assign      instr_is_jal    = brch_op_bus[`BRCH_JAL_LOC];
assign      instr_is_jalr   = brch_op_bus[`BRCH_JALR_LOC];
assign      instr_is_mret   = brch_op_bus[`BRCH_MRET_LOC];
assign      instr_is_dret   = brch_op_bus[`BRCH_DRET_LOC];
// assign      instr_is_fencei = brch_op_bus[`BRCH_FENCEI_LOC];
assign      instr_is_fence  = brch_op_bus[`BRCH_FENCE_LOC];

assign      op1_is_pc       = brch_op_bus[`BRCH_OP1_IS_PC];
assign      op2_is_imm      = brch_op_bus[`BRCH_OP2_IS_IMM];

assign      alu_op_vld = brch_op_vld;

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
assign      alu_in1 = op1_is_pc ? pc : rs1_rdata;
assign      alu_in2 = op2_is_imm ? 32'd4 : rs2_rdata;

// 以下指令一定会跳转
assign      brch_must_taken =   instr_is_jalr | 
                                instr_is_jal | 
                                instr_is_dret | 
                                instr_is_mret | 
                                instr_is_fence;

// 当条件成立的时候跳转
assign      brch_cond_taken = alu_cmp_res;
assign      brch_taken      = brch_must_taken | brch_cond_taken;


assign      brch_cmt_bjp    =   instr_is_blt | 
                                instr_is_bltu | 
                                instr_is_bne | 
                                instr_is_beq | 
                                instr_is_bge | 
                                instr_is_bgeu;

assign      brch_cmt_dret   = instr_is_dret;
assign      brch_cmt_mret   = instr_is_mret;
assign      brch_cmt_fence  = instr_is_fence;
assign      brch_cmt_jal    = instr_is_jal;
assign      brch_cmt_jalr   = instr_is_jalr;

assign      brch_cmt_vld    = brch_op_vld;

// 分支结果
assign      brch_cmt_bjp_res = brch_must_taken | brch_cond_taken;

// jal和jalr指令需要写回
assign      gpr_wbck_vld = instr_is_jal | instr_is_jalr & alu_hsked;

assign      brch_op_rdy = brch_pipe_flush_req ? brch_pipe_flush_ack : gpr_wbck_rdy;

assign      cmt_mret = instr_is_mret & brch_pipe_flush_ack;
assign      cmt_dret = instr_is_dret & brch_pipe_flush_ack;

endmodule