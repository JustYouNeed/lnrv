module lnrv_cmt_brch
(
    // 分支指令交付请求
    input                       cmt_vld,
    input                       cmt_brch_bjp,
    input                       cmt_brch_jalr,
    input                       cmt_brch_jal,
    input                       cmt_brch_mret,
    input                       cmt_brch_dret,
    input                       cmt_brch_fence,


    input                       bpu_prdt_res,

    output                      brch_taken,

    input[31 : 0]               dpc,
    input[31 : 0]               mepc,
    input[31 : 0]               rs1_rdata,
    input[31 : 0]               idu_pc,
    input[31 : 0]               imm,

    // 流水线冲刷请求
    output                      pipe_flush_req,
    input                       pipe_flush_ack,
    output[31 : 0]              pipe_flush_pc_op1,
    output[31 : 0]              pipe_flush_pc_op2,


    input                       clk,
    input                       reset_n
);

wire                            pipe_flush_hsked;
wire                            pipe_flush_req_pre;

assign      pipe_flush_hsked = pipe_flush_req & pipe_flush_ack;

assign      pipe_flush_req_pre =    cmt_vld &
                                    (
                                        cmt_brch_bjp |
                                        cmt_brch_dret |
                                        cmt_brch_jal |
                                        cmt_brch_jalr |
                                        cmt_brch_mret |
                                        cmt_brch_fence
                                    );

// 如果分支预测与实际结果不一致，都需要冲刷流水线
assign      pipe_flush_req = bpu_prdt_res ^ pipe_flush_req_pre;


// 如是是dret指令，则跳转地址为dpc；
// 如果是mret指令，则跳转地址为mepc;
// 如果是jalr指令，则跳转地址为x[rs1] + imm;
// 如果是其余跳转指令，如beq/bne等等，则跳转地址为pc + imm;
// 如果不需要跳转，但是分支预测需要跳转，则跳转地址为pc + 4
assign      pipe_flush_pc_op1 = cmt_brch_dret ? dpc :
                                cmt_brch_mret ? mepc :
                                cmt_brch_jalr ? rs1_rdata :
                                idu_pc;
assign      pipe_flush_pc_op2 = cmt_brch_dret ? 32'd0 :
                                cmt_brch_mret ? 32'd0 :
                                cmt_brch_fence ? 32'd4 :
                                cmt_brch_jalr ? imm :
                                bpu_prdt_res ? 32'd4 :
                                imm;

assign      brch_taken = pipe_flush_hsked;

endmodule
