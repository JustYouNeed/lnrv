module lnrv_exu_cmt
(
    // 来自分支处理模块的流水线冲刷请求
    input                       brch_pipe_flush_req,
    output                      brch_pipe_flush_ack,
    input[31 : 0]               brch_pipe_flush_pc_op1,
    input[31 : 0]               brch_pipe_flush_pc_op2,

    // 来自异常处理模块的流水线冲刷请求
    input                       excp_pipe_flush_req,
    output                      excp_pipe_flush_ack,
    input[31 : 0]               excp_pipe_flush_pc_op1,
    input[31 : 0]               excp_pipe_flush_pc_op2,

    // 中断处理模块的流水线冲刷请求
    input                       irq_pipe_flush_req,
    output                      irq_pipe_flush_ack,
    input[31 : 0]               irq_pipe_flush_pc_op1,
    input[31 : 0]               irq_pipe_flush_pc_op2,

    // 来自调试处理模块的流水线冲刷请求
    input                       debug_pipe_flush_req,
    output                      debug_pipe_flush_ack,
    input[31 : 0]               debug_pipe_flush_pc_op1,
    input[31 : 0]               debug_pipe_flush_pc_op2,

    input                       irq_cmt_csr,
    input[31 : 0]               irq_cmt_mepc,
    input[31 : 0]               irq_cmt_mcause,

    input                       excp_cmt_csr,
    input[31 : 0]               excp_cmt_mepc,
    input[31 : 0]               excp_cmt_mcause,
    input[31 : 0]               excp_cmt_mtval,

    input                       excp_cmt_dcsr,
    input[31 : 0]               excp_cmt_dpc,
    input[2 : 0]                excp_cmt_dcause,

    input                       debug_cmt_dcsr,
    input[31 : 0]               debug_cmt_dpc,
    input[2 : 0]                debug_cmt_dcause,


    output                      cmt_irq,
    output                      cmt_excp,
    output                      cmt_debug,
    output[31 : 0]              cmt_mepc,
    output[31 : 0]              cmt_mcause,
    output[31 : 0]              cmt_mtval,

    output[31 : 0]              cmt_dpc,
    output[2 : 0]               cmt_dcause,

    output                      pipe_flush_req,
    input                       pipe_flush_ack,
    output[31 : 0]              pipe_flush_pc_op1,
    output[31 : 0]              pipe_flush_pc_op2,

    input                       clk,
    input                       reset_n
);


assign      pipe_flush_req  =   brch_pipe_flush_req | 
                                excp_pipe_flush_req | 
                                irq_pipe_flush_req | 
                                debug_pipe_flush_req;

assign      pipe_flush_pc_op1 = brch_pipe_flush_req ? brch_pipe_flush_pc_op1 : 
                                excp_pipe_flush_req ? excp_pipe_flush_pc_op1 : 
                                irq_pipe_flush_req ? irq_pipe_flush_pc_op1 : 
                                debug_pipe_flush_req ? debug_pipe_flush_pc_op1 : 
                                32'd0;

assign      pipe_flush_pc_op2 = brch_pipe_flush_req ? brch_pipe_flush_pc_op2 : 
                                excp_pipe_flush_req ? excp_pipe_flush_pc_op2 : 
                                irq_pipe_flush_req ? irq_pipe_flush_pc_op2 : 
                                debug_pipe_flush_req ? debug_pipe_flush_pc_op2 : 
                                32'd0;

assign      brch_pipe_flush_ack = pipe_flush_ack;

assign      excp_pipe_flush_ack =   pipe_flush_ack & 
                                    (
                                        ~brch_pipe_flush_req
                                    );

assign      irq_pipe_flush_ack =    pipe_flush_ack & 
                                    (
                                        ~(
                                            brch_pipe_flush_req | 
                                            excp_pipe_flush_req
                                        )
                                    );

assign      debug_pipe_flush_ack =  pipe_flush_ack & 
                                    (
                                        ~(
                                            brch_pipe_flush_req | 
                                            excp_pipe_flush_req | 
                                            irq_pipe_flush_req
                                        )
                                    );

assign      cmt_irq = irq_cmt_csr;
assign      cmt_excp = excp_cmt_csr;
assign      cmt_debug = excp_cmt_dcsr | 
                        debug_cmt_dcsr;


assign      cmt_mepc =  excp_cmt_csr ? excp_cmt_mepc : 
                        irq_cmt_csr ? irq_cmt_mepc : 
                        32'd0;

assign      cmt_mcause =    excp_cmt_csr ? excp_cmt_mcause : 
                            irq_cmt_csr ? irq_cmt_mcause : 
                            32'd0;

// 只有异常情况才需要修改mtval寄存器
assign      cmt_mtval = excp_cmt_mtval;

assign      cmt_dpc =   excp_cmt_dcsr ? excp_cmt_dpc : 
                        debug_cmt_dcsr ? debug_cmt_dpc : 
                        32'd0;

assign      cmt_dcause =    excp_cmt_dcsr ? excp_cmt_dcause : 
                            debug_cmt_dcsr ? debug_cmt_dcause : 
                            3'd0;

endmodule

