jmh// `include    "lnrv_config.v"
`include    "lnrv_def.v"
module	lnrv_ifu
(
    input                               clk,
    input                               reset_n,

    output                              ifu_active,

    // 正在加载代码到
    input                               firmware_loading,

    // 复位向量
    input[31 : 0]                       reset_vector,

    // 来自执行单元的流水线冲刷请求
    input                               exu_pipe_flush_req,
    output                              exu_pipe_flush_ack,
    input[31 : 0]                       exu_pipe_flush_pc_op1,
    input[31 : 0]                       exu_pipe_flush_pc_op2,

    // 来自分支预测模块的流水线冲刷请求
    input                               bpu_pipe_flush_req,
    output                              bpu_pipe_flush_ack,
    input[31 : 0]                       bpu_pipe_flush_pc_op1,
    input[31 : 0]                       bpu_pipe_flush_pc_op2,

    // 流水线暂停请求
    input                               pipe_halt_req,
    output                              pipe_halt_ack,
        
    // 输出至EXU模块
    output                              ifu_pc_vld,
    input                               ifu_pc_rdy,
    output[31 : 0]                      ifu_ir,                 // instruction寄存器
    output[31 : 0]                      ifu_pc,                 // pc寄存器
    output                              ifu_excp_misalgn,
    output                              ifu_excp_buserr,

    // 取指总线
    output                              ifu_cmd_vld,
    input                               ifu_cmd_rdy,
    output                              ifu_cmd_write,
    output[31 : 0]                      ifu_cmd_addr,
    output[31 : 0]                      ifu_cmd_wdata,
    output[3 : 0]                       ifu_cmd_wstrb,
    output[2 : 0]                       ifu_cmd_size,
    input                               ifu_rsp_vld,
    output                              ifu_rsp_rdy,
    input[31 : 0]                       ifu_rsp_rdata,
    input                               ifu_rsp_err
);

// 需要保存以下信息
// 1、PC
// 2、instruction
// 3、bus error
// 4、instr addr misalgn
localparam                              LP_IFU_BUF_WIDTH = 32 + 32 + 1 + 1;

wire                                    pipe_flush_req;
wire[31 : 0]                            pipe_flush_pc_op1;
wire[31 : 0]                            pipe_flush_pc_op2;

wire                                    ifu_cmd_hsked;
wire                                    ifu_rsp_hsked;

reg                                     flush_req_pend_q;
wire                                    flush_req_pend_set;
wire                                    flush_req_pend_clr;
wire                                    flush_req_pend_rld;
wire                                    flush_req_pend_d;

wire                                    pipe_flush_vld;
wire                                    pipe_flush_hsked;

reg                                     reset_pend_q;
wire                                    reset_pend_set;
wire                                    reset_pend_clr;
wire                                    reset_pend_rld;
wire                                    reset_pend_d;

reg                                     halt_ack_q;
wire                                    halt_ack_set;
wire                                    halt_ack_clr;
wire                                    halt_ack_rld;
wire                                    halt_ack_d;

wire                                    no_halt_req;

// 指令地址
reg[31 : 0]                             instr_addr_q;
wire                                    instr_addr_rld;
wire[31 : 0]                            instr_addr_d;

wire[31 : 0]                            instr_addr_op1;
wire[31 : 0]                            instr_addr_op2;

wire                                    instr_addr_algn;
wire                                    instr_addr_misalgn;

//PC寄存器，输出到下一级流水
reg[31 : 0]                             ifu_pc_q;
wire                                    ifu_pc_rld;
wire[31 : 0]                            ifu_pc_d;

//instruction寄存器，输出到下一级流水
reg[31 : 0]                             ifu_ir_q;
wire                                    ifu_ir_rld;
wire[31 : 0]                            ifu_ir_d;

wire                                    ifu_no_err;
wire[31 : 0]                            ifu_push_ir;

// 滞外请求标志
reg                                     cmd_ots_q;
wire                                    cmd_ots_set;
wire                                    cmd_ots_clr;
wire                                    cmd_ots_rld;
wire                                    cmd_ots_d;
// 没有滞外请求
wire                                    no_cmd_ots;

wire                                    ifu_buf_push_vld;
wire                                    ifu_buf_push_rdy;
wire[LP_IFU_BUF_WIDTH - 1 : 0]          ifu_buf_push_data;

wire                                    ifu_buf_pop_vld;
wire                                    ifu_buf_pop_rdy;
wire[LP_IFU_BUF_WIDTH - 1 : 0]          ifu_buf_pop_data;


// 如果分支预测模块和指令执行模块同时请求冲刷流水线，则优先响应指令执行模块，因为指令执行模块的冲刷请求有可能来自中断或者异常，
// 需要优先处理
assign      pipe_flush_req      = exu_pipe_flush_req | bpu_pipe_flush_req;
assign      pipe_flush_pc_op1   = exu_pipe_flush_req ? exu_pipe_flush_pc_op1 : bpu_pipe_flush_pc_op1;
assign      pipe_flush_pc_op2   = exu_pipe_flush_req ? exu_pipe_flush_pc_op2 : bpu_pipe_flush_pc_op2;
assign      pipe_flush_hsked    = pipe_flush_req & pipe_flush_ack;

/* 应答通道握手 */
assign      ifu_rsp_hsked = ifu_rsp_vld & ifu_rsp_rdy;

/* 请求通道握手 */
assign      ifu_cmd_hsked = ifu_cmd_vld & ifu_cmd_rdy;


// 复位为我们需要从reset_vector取指，由于取指PC直接由组合逻辑输出，因此在第一个取指请求没有成功握手
//      之前，需要保持住复位标志
assign      reset_pend_set = 1'b0;
assign      reset_pend_clr = ifu_cmd_hsked;
assign      reset_pend_rld = reset_pend_set | reset_pend_clr;
assign      reset_pend_d = 1'b0;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        reset_pend_q <= 1'b1;
    end else if(reset_pend_rld) begin
        reset_pend_q <= reset_pend_d;
    end
end


// 流水线冲刷请求是立即响应的，但是流水线冲刷并不能立即完成，如果当前不能立即冲刷流水线，
// 就需要挂起流水线冲刷请求，直到冲刷成功。
assign      flush_req_pend_set = pipe_flush_req & (~ifu_cmd_hsked);
assign      flush_req_pend_clr = flush_req_pend_q & ifu_cmd_hsked;
assign      flush_req_pend_rld = flush_req_pend_set | flush_req_pend_clr;
assign      flush_req_pend_d = flush_req_pend_set;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        flush_req_pend_q <= 1'b0;
    end else if(flush_req_pend_rld) begin
        flush_req_pend_q <= flush_req_pend_d;
    end
end

// 外部流水线冲刷信号有效，或者内部保持信号有效，都表示当前有流水线冲刷请求
assign      pipe_flush_vld = pipe_flush_req | flush_req_pend_q;


// 当前没有滞外请求的时候，表示halt成功
assign      halt_ack_set = pipe_halt_req & no_cmd_ots;
assign      halt_ack_clr = halt_ack_q & (~pipe_halt_req);
assign      halt_ack_rld = halt_ack_set | halt_ack_clr;
assign      halt_ack_d = halt_ack_set;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        halt_ack_q <= 1'b0;
    end else if(halt_ack_d) begin
        halt_ack_q <= halt_ack_d;
    end
end


// 这里将指令地址分为两个操作数相加
assign      instr_addr_op1 =    pipe_flush_req ? pipe_flush_pc_op1 :          // 流水线冲刷请求
                                flush_req_pend_q ? instr_addr_q :     // 流水线冲刷请求并不一定能被立即处理
                                reset_pend_q ? reset_vector : 
                                instr_addr_q;

assign      instr_addr_op2 =    pipe_flush_req ? pipe_flush_pc_op2 : 
                                flush_req_pend_q ? 32'd0 : 
                                reset_pend_q ? 32'd0 : 
                                32'd4;
assign      instr_addr_rld = ifu_cmd_hsked | pipe_flush_hsked;
assign      instr_addr_d = instr_addr_op1 + instr_addr_op2;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        instr_addr_q <= reset_vector;
    end else if(instr_addr_rld) begin
        instr_addr_q <= instr_addr_d;
    end
end

// 地址非对齐
assign      instr_addr_misalgn  = |ifu_cmd_addr[1 : 0];
assign      instr_addr_algn     = ~instr_addr_misalgn;

// 指令请求滞外交易标志，如果需要从总线取指，则可能需要几个周期才能读取到结果，在这期间不可以再次发送
// 新的指令请求
// 如果指令请求被接受，表示有新的滞外交易
assign      cmd_ots_set = ifu_cmd_hsked;
// 收到指令应答，则表示滞外请求完成
assign      cmd_ots_clr = ifu_rsp_hsked;
assign      cmd_ots_rld = cmd_ots_set | cmd_ots_clr;
// 如果当前没有滞外交易，且slave可以立即回rsp_rdy，则不需要设置ots
assign      cmd_ots_d = cmd_ots_set;
    // (cmd_ots_set & cmd_ots_q) | 
    //                     (~(cmd_ots_clr | cmd_ots_q));
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        cmd_ots_q <= 1'b0;
    end else if(cmd_ots_rld) begin
        cmd_ots_q <= cmd_ots_d;
    end
end

// 没有滞外请求
assign      no_cmd_ots = cmd_ots_clr | (~cmd_ots_q);

// 如果取指遇到错误，则将流水线中的指令全部弄为0
assign      ifu_no_err = ~(ifu_rsp_err | instr_addr_misalgn);
assign      ifu_push_ir = {32{ifu_no_err}} & ifu_rsp_rdata;

// 我们会在以下情况发生时将指令相关信息push到Buff中
// 1、取指总线有应答
// 2、当前没有滞外交易，但是指令地址非对齐，需要产生异常
assign      ifu_buf_push_vld =  (~pipe_flush_vld) & 
                                (
                                    ifu_rsp_vld | 
                                    ((~cmd_ots_q) & instr_addr_misalgn)
                                );
assign      ifu_buf_push_data = {
                                    instr_addr_misalgn,
                                    ifu_rsp_err,
                                    ifu_push_ir,
                                    instr_addr_q
                                };

lnrv_gnrl_buffer#
(
    .P_DATA_WIDTH       ( LP_IFU_BUF_WIDTH          ),
    .P_DEEPTH           ( 1                         ),
    .P_CUT_READY        ( "true"                    ),
    .P_BYPASS           ( "false"                   )
)       
u_ifu_buffer        
(       
    .clk                ( clk                       ),
    .reset_n            ( reset_n                   ),

    .flush_req          ( pipe_flush_vld            ),
    .flush_ack          (                           ),

    .push_vld           ( ifu_buf_push_vld          ),
    .push_rdy           ( ifu_buf_push_rdy          ),
    .push_data          ( ifu_buf_push_data         ),

    .pop_vld            ( ifu_buf_pop_vld           ),
    .pop_rdy            ( ifu_buf_pop_rdy           ),
    .pop_data           ( ifu_buf_pop_data          )
);

assign      {
                ifu_excp_misalgn,
                ifu_excp_buserr,
                ifu_ir,
                ifu_pc
            } = ifu_buf_pop_data;
assign      ifu_buf_pop_rdy = ifu_pc_rdy;
assign      ifu_pc_vld = ifu_buf_pop_vld;

// 只要没有滞外请求，且没有halt请求，地址对齐，就可以发出新的指令请求
assign      ifu_cmd_vld     = no_cmd_ots & (~pipe_halt_req) & addr_algn;
assign      ifu_cmd_addr    = instr_addr_d;
assign      ifu_cmd_write   = 1'b0;
assign      ifu_cmd_wdata   = 32'd0;
assign      ifu_cmd_wstrb   = 4'd0;
assign      ifu_cmd_size    = 3'd2;

// 如果当前有流水线冲刷请求，则可以接收新的指令，
// 或者当前指令已经执行完成，也可以接收新的指令。
assign      ifu_rsp_rdy = pipe_flush_vld | ifu_buf_push_rdy;

// 无论什么时候都会接收流水线冲刷请求
assign      pipe_flush_ack = 1'b1;

assign      ifu_active = 1'b1;

endmodule