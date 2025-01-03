module lnrv_cmt_wfi(
    input                   clk,
    input                   reset_n,

    input                   exu_idle,

    input                   cmt_vld,
    input                   cmt_sys_wfi,

    output                  wfi_mode,

    output                  pipe_halt_req,
    input                   pipe_halt_ack,

    input                   excp_req_raw,
    input                   irq_req_raw,
    input                   dbg_req_raw,

    input                   d_mode,
    input                   dcsr_step
);

wire                        wfi_irq_mask;

reg                         pipe_halt_req_q;
wire                        pipe_halt_req_set;
wire                        pipe_halt_req_clr;
wire                        pipe_halt_req_rld;
wire                        pipe_halt_req_d;

reg                         wfi_mode_q;
wire                        wfi_mode_set;
wire                        wfi_mode_clr;
wire                        wfi_mode_rld;
wire                        wfi_mode_d;


wire                        pipe_halt_hsked;


assign      pipe_halt_hsked = pipe_halt_req & pipe_halt_ack;


// 在debug mode或者单步调试模式中，都不会处理wfi指令
assign      wfi_irq_mask = d_mode | dcsr_step;

// 执行到wfi指令时，我们会拉高pipe_halt_req信号，请求暂停流水线
assign      pipe_halt_req_set = cmt_vld & cmt_sys_wfi & (~d_mode);
// 如果期间有中断/异常/调试请求发生，我们立即拉低pipe_halt_req信号，退出wfi模式
assign      pipe_halt_req_clr = excp_req_raw |
                                (irq_req_raw & (~wfi_irq_mask)) |
                                dbg_req_raw;
assign      pipe_halt_req_rld = pipe_halt_req_set | pipe_halt_req_clr;
assign      pipe_halt_req_d = pipe_halt_req_set & (~pipe_halt_req_clr);
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        pipe_halt_req_q <= 1'b0;
    end else if(pipe_halt_req_rld) begin
        pipe_halt_req_q <= pipe_halt_req_d;
    end
end


assign      wfi_mode_set = pipe_halt_hsked & exu_idle;
assign      wfi_mode_clr = pipe_halt_req_clr;
assign      wfi_mode_rld = wfi_mode_set | wfi_mode_clr;
assign      wfi_mode_d = wfi_mode_set & (~wfi_mode_clr);
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        wfi_mode_q <= 1'b0;
    end else if(wfi_mode_rld) begin
        wfi_mode_q <= wfi_mode_d;
    end
end


assign      wfi_mode = wfi_mode_q & (~wfi_mode_clr);


assign      pipe_halt_req = pipe_halt_req_q;

endmodule