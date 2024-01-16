module  lnrv_exu_debug
(
    input                       dbg_irq,
    input                       dbg_halt,
    input                       dbg_step,
    input                       dbg_trig,

    input                       d_mode,

    output                      dbg_taken,

    input                       ifu_pc_vld,
    input[31 : 0]               ifu_pc,

    input                       disp_idle,
    input                       disp_hsked,

    output                      pipe_flush_req,
    input                       pipe_flush_ack,
    output[31 : 0]              pipe_flush_pc_op1,
    output[31 : 0]              pipe_flush_pc_op2,

    output                      cmt_dcsr,
    output[31 : 0]              cmt_dpc,
    output[2 : 0]               cmt_dcause,

    input                       clk,
    input                       reset_n
);


wire                            debug_request;
wire                            not_in_debug_mode;

wire                            step_pipe_flush_req;
wire                            pipe_flush_hsked;

assign      not_in_debug_mode = (~d_mode);


assign      pipe_flush_hsked = pipe_flush_req & pipe_flush_ack;

// 单步调试需要在每一条指令执行完成时，自动请求进入debug mode
assign      step_pipe_flush_req = dbg_step & not_in_debug_mode & disp_hsked;

// 对于调试请求，处理方式与中断一样，我们需要等当前没有要执行的指令，且下一条指令的地址有效,
// 才可以冲刷流水线，进入debug mode
assign      debug_request = disp_idle & 
                            ifu_pc_vld & 
                            not_in_debug_mode & 
                            (
                                dbg_irq | 
                                dbg_halt | 
                                dbg_trig
                            );

assign      dbg_taken = step_pipe_flush_req | 
                        debug_request;

assign      pipe_flush_req = dbg_taken;
assign      pipe_flush_pc_op1 = 32'h800;
assign      pipe_flush_pc_op2 = 32'd0;

assign      cmt_dcsr   = pipe_flush_hsked;
assign      cmt_dpc     = ifu_pc;
assign      cmt_dcause  =   dbg_trig ? 3'd2 : 
                            dbg_halt ? 3'd3 : 
                            dbg_step ? 3'd4 : 
                            dbg_irq ? 3'd5 :
                            3'd0;

endmodule