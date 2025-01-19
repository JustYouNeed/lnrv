`include    "lnrv_def.v"
module	lnrv_ifu#
(
    parameter                           P_OTS_COUNT = 3
)
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

    // 有向量中断发生
    input                               vec_irq_taken,

    // 输出至EXU模块
    output                              ifu_vld,
    input                               ifu_rdy,
    output[31 : 0]                      ifu_ir,                 // instruction寄存器
    output[31 : 0]                      ifu_pc,                 // pc寄存器
    output                              ifu_excp_misalgn,
    output                              ifu_excp_buserr,

    // 取指总线
    output                              icb_cmd_vld,
    input                               icb_cmd_rdy,
    output                              icb_cmd_write,
    output[31 : 0]                      icb_cmd_addr,
    output[31 : 0]                      icb_cmd_wdata,
    output[3 : 0]                       icb_cmd_wstrb,
    output[2 : 0]                       icb_cmd_size,
    input                               icb_rsp_vld,
    output                              icb_rsp_rdy,
    input[31 : 0]                       icb_rsp_rdata,
    input                               icb_rsp_err
);

// 需要保存以下信息
// 1、PC
// 2、instruction
// 3、bus error
// 4、instr addr misalgn
localparam                              LP_IFU_BUF_WIDTH = 32 + 32 + 1 + 1;

localparam                              LP_OTS_CNT_WIDTH = $clog2(P_OTS_COUNT) + 1;

wire                                    pipe_flush_req;
wire                                    pipe_flush_ack;
wire[31 : 0]                            pipe_flush_pc_op1;
wire[31 : 0]                            pipe_flush_pc_op2;
wire                                    pipe_flush_hsked;

wire                                    icb_cmd_hsked;
wire                                    icb_rsp_hsked;


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
wire[2 : 0]                             pc_incr;

reg[LP_OTS_CNT_WIDTH - 1 : 0]           cmd_ots_cnt_q;
wire                                    cmd_ots_cnt_dec;
wire                                    cmd_ots_cnt_inc;
wire                                    cmd_ots_cnt_rld;
wire[LP_OTS_CNT_WIDTH - 1 : 0]          cmd_ots_cnt_d;
wire[LP_OTS_CNT_WIDTH - 1 : 0]          cmd_ots_cnt_sub_1;
wire[LP_OTS_CNT_WIDTH - 1 : 0]          cmd_ots_cnt_add_1;
wire                                    cmd_ots_cnt_not_0;
wire                                    cmd_ots_cnt_is_0;
wire                                    cmd_ots_cnt_lt_max;

reg[LP_OTS_CNT_WIDTH - 1 : 0]           flush_ots_cnt_q;
wire                                    flush_ots_cnt_upd;
wire                                    flush_ots_cnt_dec;
wire                                    flush_ots_cnt_rld;
wire[LP_OTS_CNT_WIDTH - 1 : 0]          flush_ots_cnt_d;
wire                                    flush_ots_cnt_is_0;
wire                                    flush_ots_cnt_not_0;

wire                                    flush_rsp_pending;
wire                                    flush_rsp_not_pending;
wire                                    flush_cmd_pending;

// 没有流水线暂停请求
wire                                    no_pipe_halt_req;

// 剩余指令缓存
reg[15 : 0]                             leftover_buf_q;
wire                                    leftover_buf_rld;
wire[15 : 0]                            leftover_buf_d;

reg                                     firmware_loaded_q;
wire                                    firmware_loaded_d;
wire                                    firmware_loaded;

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

wire                                    ifu_buf_flush_req;

wire[31 : 0]                            ifu_push_ir;
wire[31 : 0]                            ifu_push_pc;
wire                                    ifu_pc_algn_half;
wire                                    rv32_ir;
wire                                    rv16_ir;
wire                                    first_cmd_aft_rst;

reg                                     reset_pend_q;
wire                                    reset_pend_set;
wire                                    reset_pend_clr;
wire                                    reset_pend_rld;
wire                                    reset_pend_d;

reg                                     flush_cmd_pend_q;
wire                                    flush_cmd_pend_set;
wire                                    flush_cmd_pend_clr;
wire                                    flush_cmd_pend_rld;
wire                                    flush_cmd_pend_d;

reg                                     flush_rsp_pend_q;
wire                                    flush_rsp_pend_set;
wire                                    flush_rsp_pend_clr;
wire                                    flush_rsp_pend_rld;
wire                                    flush_rsp_pend_d;

reg                                     vec_irq_wait_pc_q;
wire                                    vec_irq_wait_pc_set;
wire                                    vec_irq_wait_pc_clr;
wire                                    vec_irq_wait_pc_rld;
wire                                    vec_irq_wait_pc_d;

// 接收所有的流水线冲刷请求，且应答是立即的
assign      pipe_flush_req      = pipe_flush_req_cmt | pipe_flush_req_bpu;
assign      pipe_flush_ack      = 1'b1;
assign      pipe_flush_hsked    = pipe_flush_req & pipe_flush_ack;

// 如果分支预测模块和指令执行模块同时请求冲刷流水线，则优先响应指令执行模块，因为指令执行模块的冲刷请求有可能来自中断或者异常，
// 需要优先处理
assign      pipe_flush_pc_op1   = pipe_flush_req_cmt ? pipe_flush_pc_op1_cmt : pipe_flush_pc_op1_bpu;
assign      pipe_flush_pc_op2   = pipe_flush_req_cmt ? pipe_flush_pc_op2_cmt : pipe_flush_pc_op2_bpu;


assign      icb_cmd_hsked   = icb_cmd_vld & icb_cmd_rdy;
assign      icb_rsp_hsked   = icb_rsp_vld & icb_rsp_rdy;


// 复位释放后并不一定能取指，需要等固件加载完成
assign      firmware_loaded_d = (~firmware_loading) | firmware_loaded_q;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        firmware_loaded_q <= 1'b0;
    end else begin
        firmware_loaded_q <= firmware_loaded_d;
    end
end

assign      firmware_loaded = firmware_loaded_q;

// 复位为我们需要从reset_vector取指，由于取指PC直接由组合逻辑输出，因此在第一个取指请求没有成功握手
//      之前，需要保持住复位标志
assign      reset_pend_set = 1'b0;
assign      reset_pend_clr = icb_cmd_hsked;
assign      reset_pend_rld = reset_pend_set | reset_pend_clr;
assign      reset_pend_d = 1'b0;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        reset_pend_q <= 1'b1;
    end else if(reset_pend_rld) begin
        reset_pend_q <= reset_pend_d;
    end
end

// 这里将指令地址分为两个操作数相加
assign      fetch_addr_op1 =    pipe_flush_req ? pipe_flush_pc_op1 :
                                (flush_cmd_pend_q) ? fetch_addr_q :     // 流水线冲刷请求并不一定能被立即处理
                                reset_pend_q ? reset_vector :       // 复位时我们使用复位向量
                                vec_irq_wait_pc_q ? icb_rsp_rdata :
                                fetch_addr_q;

assign      fetch_addr_op2 =    pipe_flush_req ? pipe_flush_pc_op2 :
                                (flush_cmd_pend_q ) ? 32'd0 :
                                reset_pend_q ? 32'd0 :
                                vec_irq_wait_pc_q ? 32'd0 :
                                32'd4;
assign      fetch_addr_rld = icb_cmd_hsked | pipe_flush_hsked | vec_irq_wait_pc_clr;
assign      fetch_addr_d = fetch_addr_op1 + fetch_addr_op2;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        fetch_addr_q <= 32'd0;
    end else if(fetch_addr_rld) begin
        fetch_addr_q <= fetch_addr_d;
    end
end

// 复位后的第一个fetch command
assign      first_cmd_aft_rst = reset_pend_q & icb_cmd_hsked;

// 如果是32位指令，则PC地址递增值为4,16位指令递增2
assign      pc_incr = rv32_ir ? 3'd4 : 3'd2;

// 该寄存器保存真实执行的pc值
// 1、如果当前有流水线冲刷请求，则使用冲刷的地址
// 2、如果当前是第一次取指，也使用取指的地址
// 3、正常执行指令时根据指令位宽递增
assign      ifu_pc_rld =    pipe_flush_hsked |
                            first_cmd_aft_rst |
                            ifu_buf_push_hsked;
// 在复位没有完成，或者流水线冲刷没有完成之前，pc都使用取指pc
assign      ifu_pc_d = (flush_cmd_pending | reset_pend_q) ? fetch_addr_d :
                        ifu_pc_q + pc_incr;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        ifu_pc_q <= 32'd0;
    end else if(ifu_pc_rld) begin
        ifu_pc_q <= ifu_pc_d;
    end
end

assign      ifu_pc_algn_half = ifu_pc_q[1];


assign      cmd_ots_cnt_add_1   = cmd_ots_cnt_q + 1'b1;
assign      cmd_ots_cnt_sub_1   = cmd_ots_cnt_q - 1'b1;
assign      cmd_ots_cnt_not_0   = (|cmd_ots_cnt_q);
assign      cmd_ots_cnt_is_0    = ~cmd_ots_cnt_not_0;
assign      cmd_ots_cnt_lt_max  = (cmd_ots_cnt_q < P_OTS_COUNT);

// 统计发出的ots数量
assign      cmd_ots_cnt_inc = icb_cmd_hsked;
assign      cmd_ots_cnt_dec = icb_rsp_hsked;
assign      cmd_ots_cnt_rld = cmd_ots_cnt_dec ^ cmd_ots_cnt_inc;
assign      cmd_ots_cnt_d = cmd_ots_cnt_inc ? cmd_ots_cnt_add_1 : cmd_ots_cnt_sub_1;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        cmd_ots_cnt_q <= 3'd0;
    end else if(cmd_ots_cnt_rld) begin
        cmd_ots_cnt_q <= cmd_ots_cnt_d;
    end
end


// 统计要冲刷的response个数，如果收到的冲刷请求，则前面提前读取的指令都需要丢弃
assign      flush_ots_cnt_upd = pipe_flush_hsked & cmd_ots_cnt_not_0;
assign      flush_ots_cnt_dec = icb_rsp_hsked & flush_ots_cnt_not_0;
assign      flush_ots_cnt_rld = flush_ots_cnt_upd | flush_ots_cnt_dec;
// 当前有冲刷请求，则需要将当前cmd_ots值更新到flush_ots_cnt中，如果在冲刷请求的时候有一个response被接收了,
//  则实际的ots值为当前ots-1
assign      flush_ots_cnt_d =   pipe_flush_hsked ? (icb_rsp_hsked ? cmd_ots_cnt_sub_1 : cmd_ots_cnt_q) :
                                (flush_ots_cnt_q - 1'b1);
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        flush_ots_cnt_q <= 3'd0;
    end else if(flush_ots_cnt_rld) begin
        flush_ots_cnt_q <= flush_ots_cnt_d;
    end
end

assign      flush_ots_cnt_not_0 = |flush_ots_cnt_q;
assign      flush_ots_cnt_is_0  = ~flush_ots_cnt_not_0;

// 流水线冲刷请求是立即响应的，但是流水线冲刷并不能立即完成，因为有可能上一个取指请求还没有返回，
// 如果当前不能立即冲刷流水线，就需要锁存流水线冲刷请求，直到新地址的取指请求发出，且被接收。
// 如果是向量中断冲刷请求，则在读取到中断函数入口后，也需要冲刷command
assign      flush_cmd_pend_set  = pipe_flush_hsked | vec_irq_wait_pc_clr;
assign      flush_cmd_pend_clr  = icb_cmd_hsked;
assign      flush_cmd_pend_rld  = flush_cmd_pend_set ^ flush_cmd_pend_clr;
assign      flush_cmd_pend_d    = flush_cmd_pend_set;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        flush_cmd_pend_q <= 1'b0;
    end else if(flush_cmd_pend_rld) begin
        flush_cmd_pend_q <= flush_cmd_pend_d;
    end
end

// 外部流水线冲刷信号有效，或者内部保持信号有效，都表示当前有流水线冲刷请求
assign      flush_cmd_pending = pipe_flush_req | flush_cmd_pend_q;

// 冲刷response未完成标志
assign      flush_rsp_pend_set = flush_ots_cnt_upd;
assign      flush_rsp_pend_clr = flush_cmd_pend_rld;
assign      flush_rsp_pend_rld = flush_ots_cnt_rld;//flush_rsp_pend_set ^ flush_rsp_pend_clr;
assign      flush_rsp_pend_d = (flush_ots_cnt_d != 0);
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        flush_rsp_pend_q <= 1'b0;
    end else if(flush_rsp_pend_rld) begin
        flush_rsp_pend_q <= flush_rsp_pend_d;
    end
end

// assign      icb_rsp_discard = pipe_flush_req | flush_rsp_pend_q | vec_irq_wait_pc_q;
assign      flush_rsp_pending       = pipe_flush_req | flush_rsp_pend_q;
assign      flush_rsp_not_pending   = ~flush_rsp_pending;

// leftover_buf将会在response有效，且以下任一条件满足时置位
//      a) 当前PC没有对齐到4字节，且是一个32位指令，则需要将当前reponse的一半保存起来，和下一次取回来的指令组成32位指令
//      b) 当前PC对齐到了4字节，且是一个16位指令，则需要将当前reponse的一半保存起来，下次使用
assign      leftover_buf_vld_set = icb_rsp_hsked & (~(ifu_pc_algn_half ^ rv32_ir));
// 如果buf中push了一个指令，且是16位指令，同时当前leftover_buf中的数据有效，则肯定使用了leftover_buf中的数据，
//  此时表示leftover_buf中的数据已经失效了
assign      leftover_buf_vld_clr = ifu_buf_push_hsked & leftover_buf_vld_q & rv16_ir;
assign      leftover_buf_vld_rld = leftover_buf_vld_set ^ leftover_buf_vld_clr;
assign      leftover_buf_vld_d = leftover_buf_vld_set;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        leftover_buf_vld_q <= 1'b0;
    // 有冲刷请求，需要清空leftover_buf
    end else if(flush_rsp_pending) begin
        leftover_buf_vld_q <= 1'b0;
    end else if(leftover_buf_vld_rld) begin
        leftover_buf_vld_q <= leftover_buf_vld_d;
    end
end

// 如果本次只使用了取回来指令中的一半，则需要将另一半保存起来
assign      leftover_buf_rld = leftover_buf_vld_set;
assign      leftover_buf_d = icb_rsp_rdata[31 : 16];
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        leftover_buf_q <= 16'd0;
    end else if(leftover_buf_rld) begin
        leftover_buf_q <= leftover_buf_d;
    end
end

// 如果是向量中断产生的冲刷请求，我们需要先获取读取中断向量表，获取中断函数入口
assign      vec_irq_wait_pc_set = pipe_flush_req_cmt & pipe_flush_ack_cmt & vec_irq_taken;
// 第一个有效的rsp，就是中断函数入口
assign      vec_irq_wait_pc_clr = icb_rsp_hsked & flush_rsp_not_pending & vec_irq_wait_pc_q;
assign      vec_irq_wait_pc_rld = vec_irq_wait_pc_set | vec_irq_wait_pc_clr;
assign      vec_irq_wait_pc_d = vec_irq_wait_pc_set;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        vec_irq_wait_pc_q <= 1'b0;
    end else if(vec_irq_wait_pc_rld) begin
        vec_irq_wait_pc_q <= vec_irq_wait_pc_d;
    end
end

assign      no_pipe_halt_req = ~pipe_halt_req;

// 如果当前leftover_buf中的数据无效，或者当前是32位指令，都表示leftover_buf为空，
// 因为如果当前是32位指令，则前一条指令执行完成时，leftover_buf中的数据会被送入流水线，
// 此时icb_rsp_rdata的数据可以放到leftover_buf中
assign      leftover_buf_empty = (~leftover_buf_vld_q) | rv32_ir;

// 由于支持C扩展，因此不可能发生取指非对齐错误
assign      fetch_addr_misalgn = 1'b0;

assign      ifu_push_pc = ifu_pc_q;

// 根据leftover_buf中是否有剩余数据来决定push_ir
// 1、如果leftover_buf有效，则直接使用leftover_buf和icb_rsp_rdata[15 : 0]作为指令，同时将icb_rsp_rdata·31:16]保存到leftover_buf
// 2、如果leftover_buf无效，则下列两种情况肯定有一种成立:
//          a) 当前是复位后第一次取指
//          b) 流水线被冲刷了
//      因为如果流水线中有指令在执行，且前一条指令是16位指令，则icb_rsp_rdata[31:16]一定被保存在leftover_buf，leftover_buf一定是有效的，
//      或者前一条指令是32位的，且前一条指令的地址本身就是对齐到2字节的，同样的，上一次的icb_rsp_rdata[31:16]一定被保存了;
//      或者前一条指令是32位的，且前一条指令的地址是对齐到4字节的，则不会有数据被保存到leftover_buf中，当前指令的地址一定也是对齐到4字节的，直接使用icb_rsp_rdata即可
assign      ifu_push_ir =   leftover_buf_vld_q ? {icb_rsp_rdata[15 : 0], leftover_buf_q} :
                            ifu_pc_algn_half ? {16'd0, icb_rsp_rdata[31 : 16]} :
                            icb_rsp_rdata;

// 只要指令的最低两比特是2'b11，那就是32位指令
assign      rv32_ir     = &ifu_push_ir[1 : 0];
assign      rv16_ir     = ~rv32_ir;

// 我们会在以下情况发生时将指令相关信息push到Buff中
// 如果是32位指令，只要不是第一取指，且指令对齐到2字节，就可以push
// 如果不是32位指令，只要leftover_buf非空，或者icb_rsp_vld就可以push
// 这里不考虑流水线冲刷请求，因为流水线冲刷请求会直接作用于buf，有flush_req有效时，push是无效的
assign      ifu_buf_push_vld =  rv32_ir ? (((~ifu_pc_algn_half) | leftover_buf_vld_q) & icb_rsp_vld) :
                                (leftover_buf_vld_q | icb_rsp_vld);

assign      ifu_buf_push_data = {
                                    fetch_addr_misalgn,
                                    icb_rsp_err,
                                    ifu_push_ir,
                                    ifu_push_pc
                                };

// 冲刷过程中的push都是无效的
assign      ifu_buf_push_hsked  = ifu_buf_push_vld & ifu_buf_push_rdy & (~ifu_buf_flush_req);
assign      ifu_buf_pop_hsked   = ifu_buf_pop_vld & ifu_buf_pop_rdy;

assign      ifu_buf_flush_req = pipe_flush_req | flush_rsp_pend_q | vec_irq_wait_pc_q;

// 指令缓存
lnrv_gnrl_buf#
(
    .P_DATA_WIDTH       ( LP_IFU_BUF_WIDTH          ),
    .P_DEEPTH           ( 1                         ),

    .P_CUT_VALID        ( 1'b1                      ),
    .P_CUT_READY        ( 1'b0                      ),
    .P_FLUSH_DELAY      ( 1'b0                      )
)
u_ifu_buffer
(
    .clk                ( clk                       ),
    .reset_n            ( reset_n                   ),

    .flush_req          ( ifu_buf_flush_req         ),
    .flush_ack          (                           ),

    .push_vld           ( ifu_buf_push_vld          ),
    .push_rdy           ( ifu_buf_push_rdy          ),
    .push_data          ( ifu_buf_push_data         ),

    .pop_vld            ( ifu_buf_pop_vld           ),
    .pop_rdy            ( ifu_buf_pop_rdy           ),
    .pop_data           ( ifu_buf_pop_data          )
);

assign      ifu_vld = ifu_buf_pop_vld;
assign      {
                ifu_excp_misalgn,
                ifu_excp_buserr,
                ifu_ir,
                ifu_pc
            } = ifu_buf_pop_data;
assign      ifu_buf_pop_rdy = ifu_rdy;

// 同时满足以下条件才可以发出取指请求
//  a) 当前取指请求没有达到最大的Outstanding数
//  b) 当前没有pipe_halt_req
//  c) 固件已经加载完成
//  d) 当前没有在取向量中断的入口地址
assign      icb_cmd_vld     =   cmd_ots_cnt_lt_max &
                                no_pipe_halt_req &
                                firmware_loaded &
                                (flush_cmd_pend_q | (~vec_irq_wait_pc_q));
// 我们取指地址总是4字节对齐，因此低2比特固定为0
assign      icb_cmd_addr    = {fetch_addr_d[31 : 2], 2'b00};
assign      icb_cmd_write   = 1'b0;
assign      icb_cmd_wdata   = 32'd0;
assign      icb_cmd_wstrb   = 4'd0;
assign      icb_cmd_size    = 3'd2;

// 如果当前有流水线冲刷请求，则可以接收新的指令，
// 或者当前指令已经执行完成，也可以接收新的指令。
assign      icb_rsp_rdy     = flush_rsp_pending | (ifu_buf_push_rdy & leftover_buf_empty);


// 当所有滞外指令都回来时，流水线暂停成功
assign      pipe_halt_ack = cmd_ots_cnt_is_0;

assign      ifu_active = 1'b1;

assign      pipe_flush_ack_cmt = pipe_flush_ack;
assign      pipe_flush_ack_bpu = pipe_flush_ack;

endmodule