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
    input                       dbg_pipe_flush_req,
    output                      dbg_pipe_flush_ack,
    input[31 : 0]               dbg_pipe_flush_pc_op1,
    input[31 : 0]               dbg_pipe_flush_pc_op2,

    // 来自中断处理模块mcsr的交付请求
    input                       irq_cmt_mcsr_vld,
    input[31 : 0]               irq_cmt_mepc,
    input[31 : 0]               irq_cmt_mcause,

    input                       excp_cmt_mcsr_vld,
    input[31 : 0]               excp_cmt_mepc,
    input[31 : 0]               excp_cmt_mcause,
    input[31 : 0]               excp_cmt_mtval,

    input                       excp_cmt_dcsr_vld,
    input[31 : 0]               excp_cmt_dpc,
    input[2 : 0]                excp_cmt_dcause,

    input                       dbg_cmt_dcsr_vld,
    input[31 : 0]               dbg_cmt_dpc,
    input[2 : 0]                dbg_cmt_dcause,

    output                      cmt_mepc_vld,
    output[31 : 0]              cmt_mepc,

    output                      cmt_mcause_vld,
    output[31 : 0]              cmt_mcause,

    output                      cmt_mtval_vld,
    output[31 : 0]              cmt_mtval,

    output                      cmt_dpc_vld,
    output[31 : 0]              cmt_dpc,

    output                      cmt_dcause_vld,
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
                                dbg_pipe_flush_req;

// 
assign      pipe_flush_pc_op1 = brch_pipe_flush_req ? brch_pipe_flush_pc_op1 : 
                                excp_pipe_flush_req ? excp_pipe_flush_pc_op1 : 
                                irq_pipe_flush_req ? irq_pipe_flush_pc_op1 : 
                                dbg_pipe_flush_req ? dbg_pipe_flush_pc_op1 : 
                                32'd0;

assign      pipe_flush_pc_op2 = brch_pipe_flush_req ? brch_pipe_flush_pc_op2 : 
                                excp_pipe_flush_req ? excp_pipe_flush_pc_op2 : 
                                irq_pipe_flush_req ? irq_pipe_flush_pc_op2 : 
                                dbg_pipe_flush_req ? dbg_pipe_flush_pc_op2 : 
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

assign      dbg_pipe_flush_ack =  pipe_flush_ack & 
                                    (
                                        ~(
                                            brch_pipe_flush_req | 
                                            excp_pipe_flush_req | 
                                            irq_pipe_flush_req
                                        )
                                    );

assign      cmt_irq = irq_cmt_mcsr_vld;
assign      cmt_excp = excp_cmt_mcsr_vld;
assign      cmt_dbg = excp_cmt_dcsr_vld | 
                        dbg_cmt_dcsr_vld;


assign      cmt_mepc_vld = excp_cmt_mcsr_vld | irq_cmt_mcsr_vld;
assign      cmt_mepc =  excp_cmt_mcsr_vld ? excp_cmt_mepc : 
                        irq_cmt_mcsr_vld ? irq_cmt_mepc : 
                        32'd0;

assign      cmt_mcause_vld = cmt_mepc_vld;
assign      cmt_mcause =    excp_cmt_mcsr_vld ? excp_cmt_mcause : 
                            irq_cmt_mcsr_vld ? irq_cmt_mcause : 
                            32'd0;

// 只有异常情况才需要修改mtval寄存器
assign      cmt_mtval_vld = excp_cmt_mcsr_vld;
assign      cmt_mtval = excp_cmt_mtval;

assign      cmt_dpc_vld = excp_cmt_dcsr_vld | dbg_cmt_dcsr_vld;
assign      cmt_dpc =   excp_cmt_dcsr_vld ? excp_cmt_dpc : 
                        dbg_cmt_dcsr_vld ? dbg_cmt_dpc : 
                        32'd0;

assign      cmt_dcause_vld = cmt_dpc_vld;
assign      cmt_dcause =    excp_cmt_dcsr_vld ? excp_cmt_dcause : 
                            dbg_cmt_dcsr_vld ? dbg_cmt_dcause : 
                            3'd0;

endmodule

