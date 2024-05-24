module lnrv_exu_cmt_brch
(
    // 分支指令交付请求
    input                       brch_cmt_vld,
    output                      brch_cmt_rdy,
    input                       brch_cmt_bjp,
    input                       brch_cmt_jal,
    input                       brch_cmt_jalr,
    input                       brch_cmt_mret,
    input                       brch_cmt_dret,
    input                       brch_cmt_fence,


    input                       bpu_prdt_res,

    // 流水线冲刷请求
    output                      pipe_flush_req,
    input                       pipe_flush_ack,
    output[31 : 0]              pipe_flush_pc_op1,
    output[31 : 0]              pipe_flush_pc_op2,


    input                       clk,
    input                       reset_n
);


wire                            pipe_flush_req_pre;

assign      pipe_flush_req_pre =    brch_cmt_vld & 
                                    (
                                        brch_cmt_bjp | 
                                        brch_cmt_dret | 
                                        brch_cmt_jal | 
                                        brch_cmt_jalr | 
                                        brch_cmt_mret | 
                                        brch_cmt_fence
                                    );

// 如果分支预测与实际结果不一致，都需要冲刷流水线
assign      pipe_flush_req = bpu_prdt_res ^ pipe_flush_req_pre;


// 如是是dret指令，则跳转地址为dpc；
// 如果是mret指令，则跳转地址为mepc;
// 如果是jalr指令，则跳转地址为x[rs1] + imm;
// 如果是其余跳转指令，如beq/bne等等，则跳转地址为pc + imm;
// 如果不需要跳转，但是分支预测需要跳转，则跳转地址为pc + 4
assign      pipe_flush_pc_op1 = brch_cmt_dret ? dpc : 
                                brch_cmt_mret ? mepc : 
                                brch_cmt_jalr ? rs1_rdata : 
                                pc;
assign      pipe_flush_pc_op2 = brch_cmt_dret ? 32'd0 : 
                                brch_cmt_mret ? 32'd0 : 
                                brch_cmt_fence ? 32'd4 : 
                                brch_cmt_jalr ? imm : 
                                bpu_prdt_res ? 32'd4 : 
                                imm;

endmodule
