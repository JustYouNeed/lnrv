module  lnrv_cmt_dbg
(
    input[31 : 0]               idu_pc,

    input                       ifu_vld,
    input[31 : 0]               ifu_pc,

    input                       cmt_vld,
    input                       cmt_sys_ebreak,

    output                      dbg_req_raw,

    output                      dbg_taken,

    input                       dbg_irq,
    input                       dbg_halt,
    input                       dbg_step,
    input                       dbg_trig,

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

wire                            ebreak4debug;
wire                            dbg_step_req;

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
assign      dbg_step_trig_set = dbg_step & non_dbg_mode & cmt_vld & (~pipe_flush_hsked);
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
assign      ebreak4debug =  cmt_sys_ebreak &
                            non_dbg_mode &
                            dcsr_ebreakm;

assign      dbg_step_req = ifu_vld &
                            (
                                (dbg_step & non_dbg_mode) |
                                dbg_irq |
                                dbg_halt |
                                1'b0
                            );

assign      dbg_req_raw = ebreak4debug | dbg_step_req;

//
assign      pipe_flush_req =    cmt_vld & dbg_req_raw;

assign      pipe_flush_pc_op1   = 32'h800;
assign      pipe_flush_pc_op2   = 32'd0;

// 进入debug mode时，将当前pc值保存到dpc寄存器
assign      dpc_wdata = ebreak4debug ? idu_pc : ifu_pc;

assign      dcause_wdata =  ebreak4debug ? 3'd2 :
                            dbg_halt ? 3'd3 :
                            dbg_step_trig_q ? 3'd4 :
                            dbg_irq ? 3'd5 :
                            3'd0;

assign      dbg_taken = pipe_flush_hsked;


endmodule