module lnrv_bpu
(
    input                       ifu_vld,
    input                       ifu_excp_buserr,
    input                       ifu_excp_misalgn,
    input                       idu_excp_ilgl_ir,
    
    input                       instr_is_fence,
    input                       instr_is_fencei,
    input                       instr_is_jal,
    input                       instr_is_jalr,
    input                       instr_is_mret,
    input                       instr_is_dret,
    input                       instr_is_ebreak,


    output                      pipe_flush_req,
    input                       pipe_flush_ack,
    output[31 : 0]              pipe_flush_pc_op1,
    output[31 : 0]              pipe_flush_pc_op2
);





endmodule
