module  lnrv_cmt_dbg
(
    input[31 : 0]               exu_pc,
    input                       exu_idle,

    input                       cmt_hsked,

    input                       ifu_pc_vld,
    input[31 : 0]               ifu_pc,

    output                      dbg_taken,

    input                       dbg_irq,
    input                       dbg_halt,
    input                       dbg_step,
    input                       dbg_trig,

    // ebreak
    input                       sys_cmt_ebreak,

    input                       d_mode,

    // 该寄存器用于设置ebreak指令用途
    // 0:产生异常
    // 1:进入debug mode
    input                       dcsr_ebreakm,

    // 流水线冲刷请求
    output                      pipe_flush_req,
    input                       pipe_flush_ack,
    output[31 : 0]              pipe_flush_pc_op1,
    output[31 : 0]              pipe_flush_pc_op2,

    output[31 : 0]              dpc_wdata,
    output[2 : 0]               dcause_wdata,


    input                       clk,
    input                       reset_n
);

wire                            break4debug;

// 单步调试请求
reg                             dbg_step_trig_q;
wire                            dbg_step_trig_set;
wire                            dbg_step_trig_clr;
wire                            dbg_step_trig_rld;
wire                            dbg_step_trig_d;

wire                            debug_request;
wire                            non_dbg_mode;

wire                            step_pipe_flush_req;
wire                            pipe_flush_hsked;


assign      pipe_flush_hsked = pipe_flush_req & pipe_flush_ack;

assign      non_dbg_mode = ~d_mode;

// 如果设置了单步调试，我们需要在执行完一条指令后，请求CPU进入debug mode 
assign      dbg_step_trig_set = dbg_step & non_dbg_mode & cmt_hsked & (~pipe_flush_hsked);
assign      dbg_step_trig_clr = pipe_flush_hsked;
assign      dbg_step_trig_rld = dbg_step_trig_set | dbg_step_trig_clr;
assign      dbg_step_trig_d = dbg_step_trig_set;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        dbg_step_trig_q <= 1'b0;
    end else if(dbg_step_trig_rld) begin
        dbg_step_trig_q <= dbg_step_trig_d;
    end
end

// ebreak指令用于进入debug mode
assign      ebreak4debug =  sys_excp_ebreak & 
                            non_dbg_mode & 
                            dcsr_ebreakm;

assign      pipe_flush_req_pre =    dbg_irq | 
                                    dbg_halt | 
                                    dbg_trig | 
                                    ebreak4debug | 
                                    dbg_step_trig_q;

// 
assign      pipe_flush_req = exu_idle & ifu_pc_vld & pipe_flush_req_pre;
assign      pipe_flush_pc_op1   = 32'h800;
assign      pipe_flush_pc_op2   = 32'd0;

// 进入debug mode时，将当前pc值保存到dpc寄存器
assign      dpc_wdata       = exu_pc;

assign      dcause_wdata        = ebreak4debug ? 3'd2 : 
                                  dbg_halt ? 3'd3 : 
                                  dbg_step_trig_q ? 3'd4 : 
                                  dbg_irq ? 3'd5 :
                                  3'd0;

endmodule