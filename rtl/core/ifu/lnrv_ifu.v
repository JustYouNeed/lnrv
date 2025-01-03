// `include    "lnrv_config.v"
`include    "lnrv_def.v"
module	lnrv_ifu
(
    input                               clk,
    input                               reset_n,

    output                              ifu_active,

    // 在正加载固件，该信号在复位后，如果为高，则不会启动取指
    input                               firmware_loading,

    // 复位向量
    input[31 : 0]                       reset_vector,

    // 来自执行单元的流水线冲刷请求
    input                               pipe_flush_req_cmt,
    output                              pipe_flush_ack_cmt,
    input[31 : 0]                       pipe_flush_pc_op1_cmt,
    input[31 : 0]                       pipe_flush_pc_op2_cmt,

    // 来自分支预测模块的流水线冲刷请求
    input                               pipe_flush_req_bpu,
    output                              pipe_flush_ack_bpu,
    input[31 : 0]                       pipe_flush_pc_op1_bpu,
    input[31 : 0]                       pipe_flush_pc_op2_bpu,

    // 流水线暂停请求
    input                               pipe_halt_req,
    output                              pipe_halt_ack,

    // 输出至EXU模块
    output                              ifu_vld,
    input                               ifu_rdy,
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
wire                                    pipe_flush_ack;
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

reg                                     fetch_enable_q;
wire                                    fetch_enable_d;

// 指令地址
reg[31 : 0]                             fetch_addr_q;
wire                                    fetch_addr_rld;
wire[31 : 0]                            fetch_addr_d;

wire[31 : 0]                            fetch_addr_op1;
wire[31 : 0]                            fetch_addr_op2;

wire                                    fetch_addr_misalgn;

//PC寄存器，输出到下一级流水
reg[31 : 0]                             ifu_pc_q;
wire                                    ifu_pc_rld;
wire[31 : 0]                            ifu_pc_d;

// 滞外请求标志
reg                                     cmd_ots_q;
wire                                    cmd_ots_set;
wire                                    cmd_ots_clr;
wire                                    cmd_ots_rld;
wire                                    cmd_ots_d;

// 没有滞外交易
wire                                    no_cmd_ots;

// 没有流水线暂停请求
wire                                    no_halt_req;

// 没有流水线冲刷请求
wire                                    no_flush_req;

// 剩余指令缓存
reg[15 : 0]                             leftover_buf_q;
wire                                    leftover_buf_rld;
wire[15 : 0]                            leftover_buf_d;

// 剩余指令缓存有效
reg                                     leftover_buf_vld_q;
wire                                    leftover_buf_vld_set;
wire                                    leftover_buf_vld_clr;
wire                                    leftover_buf_vld_rld;
wire                                    leftover_buf_vld_d;
wire                                    leftover_buf_empty;

wire                                    ifu_buf_push_vld;
wire                                    ifu_buf_push_rdy;
wire[LP_IFU_BUF_WIDTH - 1 : 0]          ifu_buf_push_data;
wire                                    ifu_buf_push_hsked;

wire                                    ifu_buf_pop_vld;
wire                                    ifu_buf_pop_rdy;
wire[LP_IFU_BUF_WIDTH - 1 : 0]          ifu_buf_pop_data;
wire                                    ifu_buf_pop_hsked;

wire[31 : 0]                            ifu_push_ir;
wire                                    ifu_pc_algn_half;
wire                                    rv32_ir;

wire                                    firmware_loaded;



// 接收所有的流水线冲刷请求，且应答是立即的
assign      pipe_flush_req      = pipe_flush_req_cmt | pipe_flush_req_bpu;
assign      pipe_flush_ack      = 1'b1;
assign      pipe_flush_hsked    = pipe_flush_req & pipe_flush_ack;

// 如果分支预测模块和指令执行模块同时请求冲刷流水线，则优先响应指令执行模块，因为指令执行模块的冲刷请求有可能来自中断或者异常，
// 需要优先处理
assign      pipe_flush_pc_op1   = pipe_flush_req_cmt ? pipe_flush_pc_op1_cmt : pipe_flush_pc_op1_bpu;
assign      pipe_flush_pc_op2   = pipe_flush_req_cmt ? pipe_flush_pc_op2_cmt : pipe_flush_pc_op2_bpu;


/* 应答通道握手 */
assign      ifu_rsp_hsked = ifu_rsp_vld & ifu_rsp_rdy;

/* 请求通道握手 */
assign      ifu_cmd_hsked = ifu_cmd_vld & ifu_cmd_rdy;

// 外部流水线冲刷信号有效，或者内部保持信号有效，都表示当前有流水线冲刷请求
assign      pipe_flush_vld = pipe_flush_req | flush_req_pend_q;


assign      firmware_loaded = (~firmware_loading);


// 复位释放后并不一定能取指，需要等固件加载完成，同时，该信号只有一次有效，如果复位释放后，再拉低该信号是无效的
assign      fetch_enable_d = firmware_loaded | fetch_enable_q;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        fetch_enable_q <= 1'b0;
    end else begin
        fetch_enable_q <= fetch_enable_d;
    end
end

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

// 流水线冲刷请求是立即响应的，但是流水线冲刷并不能立即完成，因为有可能上一个取指请求还没有返回，
// 如果当前不能立即冲刷流水线，就需要锁存流水线冲刷请求，直到新地址的取指请求发出，且被接收。
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

// 这里将指令地址分为两个操作数相加
assign      fetch_addr_op1 =    pipe_flush_req_bpu ? pipe_flush_pc_op1_bpu :
                                pipe_flush_req_cmt ? pipe_flush_pc_op1_cmt :          // 流水线冲刷请求
                                flush_req_pend_q ? fetch_addr_q :     // 流水线冲刷请求并不一定能被立即处理
                                reset_pend_q ? reset_vector :       // 复位时我们使用复位向量
                                fetch_addr_q;

assign      fetch_addr_op2 =    pipe_flush_req_bpu ? pipe_flush_pc_op2_bpu :
                                pipe_flush_req_cmt ? pipe_flush_pc_op2_cmt :
                                flush_req_pend_q ? 32'd0 :
                                reset_pend_q ? 32'd0 :
                                32'd4;
assign      fetch_addr_rld = ifu_cmd_hsked | pipe_flush_hsked;
assign      fetch_addr_d = fetch_addr_op1 + fetch_addr_op2;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        fetch_addr_q <= 32'd0;
    end else if(fetch_addr_rld) begin
        fetch_addr_q <= fetch_addr_d;
    end
end

// 该寄存器保存真实执行的pc值
assign      ifu_pc_rld = pipe_flush_hsked | (reset_pend_q & ifu_cmd_hsked) | ifu_buf_push_hsked;
assign      ifu_pc_d = (pipe_flush_vld | reset_pend_q) ? fetch_addr_d :
                        ifu_pc_q + (rv32_ir ? 32'd4 : 32'd2);
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        ifu_pc_q <= 32'd0;
    end else if(ifu_pc_rld) begin
        ifu_pc_q <= ifu_pc_d;
    end
end

assign      ifu_pc_algn_half = ifu_pc_q[1];

// 指令请求滞外交易标志，如果需要从总线取指，则可能需要几个周期才能读取到结果，在这期间不可以再次发送
// 新的指令请求
// 如果指令请求被接受，表示有新的滞外交易
assign      cmd_ots_set = ifu_cmd_hsked;
// 收到指令应答，则表示滞外请求完成
assign      cmd_ots_clr = ifu_rsp_hsked;
assign      cmd_ots_rld = cmd_ots_set | cmd_ots_clr;
// 如果当前没有滞外交易，且slave可以立即回rsp_rdy，则不需要设置ots
assign      cmd_ots_d = cmd_ots_q ? cmd_ots_set : (~cmd_ots_clr);
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        cmd_ots_q <= 1'b0;
    end else if(cmd_ots_rld) begin
        cmd_ots_q <= cmd_ots_d;
    end
end

// 没有滞外请求
assign      no_cmd_ots = cmd_ots_clr | (~cmd_ots_q);

// 如果当前是16位指令，则需要将剩下的一半指令保存下来，下次使用
assign      leftover_buf_rld = ifu_rsp_hsked;
assign      leftover_buf_d = ifu_rsp_rdata[31 : 16];
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        leftover_buf_q <= 16'd0;
    end else if(leftover_buf_rld) begin
        leftover_buf_q <= leftover_buf_d;
    end
end

// leftover_buf将会在以下条件成立时置位
// 当前取指总线的应答被接收，同时以下任一条件满足
//      1、当前leftover_buf有效，则一定有数据会被写入leftover_buf，因为取指总线是32位的
//      2、当前leftover_buf无效，但是当前pc值没有对齐到4字节，且取回来的指令是32位指令，我们需要
//          将高16位指令先保存到leftover_buf，或者当前pc值对齐到4字节，但是取回来的指令是16位的，
//          我们需要将高16位指令保存到leftover_buf
assign      leftover_buf_vld_set =  ifu_rsp_hsked &
                                    (
                                        leftover_buf_vld_q |
                                        (~(ifu_pc_algn_half ^ rv32_ir))
                                    );
// 当成功往流水线中push了指令，或者流水线有冲刷请求，leftover_buf中的数据就会无效
assign      leftover_buf_vld_clr = ifu_buf_push_hsked | pipe_flush_vld;
assign      leftover_buf_vld_rld = leftover_buf_vld_set | leftover_buf_vld_clr;
// 在置位时要确保没有流水线冲刷请求，因为冲刷流水线时，读回来的指令会一直接收，但是无效
assign      leftover_buf_vld_d = leftover_buf_vld_set & no_flush_req;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        leftover_buf_vld_q <= 1'b0;
    end else if(leftover_buf_vld_rld) begin
        leftover_buf_vld_q <= leftover_buf_vld_d;
    end
end

assign      no_halt_req = ~pipe_halt_req;
assign      no_flush_req = ~pipe_flush_vld;

// 如果当前leftover_buf中的数据无效，或者当前是32位指令，都表示leftover_buf为空，
// 因为如果当前是32位指令，则前一条指令执行完成时，leftover_buf中的数据会被送入流水线，
// 此时ifu_rsp_rdata的数据可以放到leftover_buf中
assign      leftover_buf_empty = (~leftover_buf_vld_q) | rv32_ir;

// 由于支持C扩展，因此不可能发生取指非对齐错误
assign      fetch_addr_misalgn = 1'b0;

// 根据leftover_buf中是否有剩余数据来决定push_ir
// 1、如果leftover_buf有效，则直接使用leftover_buf和ifu_rsp_rdata[15 : 0]作为指令，同时将ifu_rsp_rdata·31:16]保存到leftover_buf
// 2、如果leftover_buf无效，则下列两种情况肯定有一种成立:
//          a) 当前是复位后第一次取指
//          b) 流水线被冲刷了
//      因为如果流水线中有指令在执行，且前一条指令是16位指令，则ifu_rsp_rdata[31:16]一定被保存在leftover_buf，leftover_buf一定是有效的，
//      或者前一条指令是32位的，且前一条指令的地址本身就是对齐到2字节的，同样的，上一次的ifu_rsp_rdata[31:16]一定被保存了;
//      或者前一条指令是32位的，且前一条指令的地址是对齐到4字节的，则不会有数据被保存到leftover_buf中，当前指令的地址一定也是对齐到4字节的，直接使用ifu_rsp_rdata即可
assign      ifu_push_ir =   leftover_buf_vld_q ? {ifu_rsp_rdata[15 : 0], leftover_buf_q} :
                            ifu_pc_algn_half ? {16'd0, ifu_rsp_rdata[31 : 16]} :
                            ifu_rsp_rdata;

// 只要指令的最低两比特是2'b11，那就是32位指令
assign      rv32_ir = &ifu_push_ir[1 : 0];

// 我们会在以下情况发生时将指令相关信息push到Buff中
assign      ifu_buf_push_vld =  (~pipe_flush_vld) &
                                (
                                    // 如果是32位指令，只要不是第一取指，且指令对齐到2字节，就可以push
                                    // 如果不是32位指令，只要leftover_buf非空，或者ifu_rsp_vld就可以push
                                    rv32_ir ? (((~ifu_pc_algn_half) | leftover_buf_vld_q) & ifu_rsp_vld) :
                                    (ifu_rsp_vld | leftover_buf_vld_q)
                                );
assign      ifu_buf_push_data = {
                                    fetch_addr_misalgn,
                                    ifu_rsp_err,
                                    ifu_push_ir,
                                    ifu_pc_q
                                };
assign      ifu_buf_push_hsked = ifu_buf_push_vld & ifu_buf_push_rdy;

// 指令缓存
lnrv_gnrl_buffer#
(
    .P_DATA_WIDTH       ( LP_IFU_BUF_WIDTH          ),
    .P_DEEPTH           ( 1                         ),
    .P_CUT_READY        ( "false"                   ),
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
assign      ifu_buf_pop_rdy = ifu_rdy;
assign      ifu_buf_pop_hsked = ifu_buf_pop_vld & ifu_buf_pop_rdy;

assign      ifu_vld = ifu_buf_pop_vld;

// 只要没有滞外请求，且没有halt请求，地址对齐，就可以发出新的指令请求
assign      ifu_cmd_vld     = no_cmd_ots & no_halt_req & fetch_enable_q & leftover_buf_empty;
// 我们取指地址总是4字节对齐，因此低2比特固定为0
assign      ifu_cmd_addr    = {fetch_addr_d[31 : 2], 2'b00};
assign      ifu_cmd_write   = 1'b0;
assign      ifu_cmd_wdata   = 32'd0;
assign      ifu_cmd_wstrb   = 4'd0;
assign      ifu_cmd_size    = 3'd2;

// 如果当前有流水线冲刷请求，则可以接收新的指令，
// 或者当前指令已经执行完成，也可以接收新的指令。
assign      ifu_rsp_rdy = pipe_flush_vld | (ifu_buf_push_rdy & leftover_buf_empty);

// 当所有滞外指令都回来时，流水线暂停成功
assign      pipe_halt_ack = no_cmd_ots;

assign      ifu_active = 1'b1;

assign      pipe_flush_ack_cmt = pipe_flush_ack;
assign      pipe_flush_ack_bpu = pipe_flush_ack;

endmodule