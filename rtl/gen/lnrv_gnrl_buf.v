module	lnrv_gnrl_buf#
(
	parameter                       P_DATA_WIDTH    = 32,
    parameter                       P_DEEPTH        = 1,

    // 切断上游valid向下游的组合路径，
    // 当工作于fully及forward mode时该参数默认为true，配置无效
    parameter                       P_CUT_VALID     = 1'b0,

    // 切断下游ready向上游的组合路径
    // 当工作于fully及backward mode时该参数默认为true，配置无效
    parameter                       P_CUT_READY     = 1'b0,

    // 0: flush立即响应
    // 1: 如果buffer中有数据，则需要等当前正在输出的数据已经被接收，才响应，对于一些总线协议，
    //      一般都不允许让valid拉高后，在下游没有接收数据之前拉低，因此我们需要保证已经输出的数据
    //      输出完成
    parameter                       P_FLUSH_DELAY   = 1'b1
)
(
    input                           clk,
    input                           reset_n,

    input                           flush_req,
    output                          flush_ack,

    /* 流水线输入端 */
    input                           push_vld,
    output                          push_rdy,
    input[P_DATA_WIDTH - 1 : 0]     push_data,

    /* 流水线输出端 */
    output                          pop_vld,
    input                           pop_rdy,
    output[P_DATA_WIDTH - 1 : 0]    pop_data
);

wire                                push_rdy_raw;

wire                                buf_full;
wire                                buf_not_full;

wire                                buf_empty;
wire                                buf_not_empty;

wire                                push_hsked;
wire                                pop_hsked;
wire                                pop_xor_push;
wire                                flush_hsked;



assign      push_hsked      = push_vld & push_rdy;
assign      pop_hsked       = pop_vld & pop_rdy;
assign      pop_xor_push    = push_hsked ^ pop_hsked;

assign      buf_not_empty   = ~buf_empty;
assign      buf_not_full    = ~buf_full;

// 如果有冲刷请求，不接收任何push
assign      push_rdy        = push_rdy_raw & (~flush_req);


generate

    // 如果FIFO深度为0，则直接将输出与输入相连即可
    if(P_DEEPTH == 0) begin: GEN_DEEPTH_IS_0
        assign      pop_data        = push_data;

        assign      pop_vld         = push_vld;
        assign      push_rdy_raw    = pop_rdy;

        assign      buf_empty       = pop_rdy;
        assign      buf_full        = push_vld;

    // 深度为1，则使用一个buffer即可
    end else if(P_DEEPTH == 1) begin: GEN_DEEPTH_IS_1
        reg[P_DATA_WIDTH - 1 : 0]           buf_q;
        wire                                buf_rld;
        wire[P_DATA_WIDTH - 1 : 0]          buf_d;

        reg                                 buf_full_q;
        wire                                buf_full_set;
        wire                                buf_full_clr;
        wire                                buf_full_rld;
        wire                                buf_full_d;

        // 输入端握手成功，则表示可以将数据加载到buffer中
        assign      buf_rld = push_hsked;
        assign      buf_d = push_data;
        always@(posedge clk or negedge reset_n) begin
            if(reset_n == 1'b0) begin
                buf_q <= {P_DATA_WIDTH{1'b0}};
            end else if(buf_rld) begin
                buf_q <= #1 buf_d;
            end
        end

        // 如果buffer加载了新的数据，则buf已经满了
        assign      buf_full_set = push_hsked;
        // 如果输出端读取了buffer中的数据，则表示
        assign      buf_full_clr = pop_hsked;
        assign      buf_full_rld = buf_full_set ^ buf_full_clr;
        // 读写可能同时发生，此时buffer中的数据仍有效
        assign      buf_full_d = buf_full_set;
        always@(posedge clk or negedge reset_n) begin
            if(reset_n == 1'b0) begin
                buf_full_q <= 1'b0;
            end else if(flush_hsked) begin
                buf_full_q <= 1'b0;
            end else if(buf_full_rld) begin
                buf_full_q <= buf_full_d;
            end
        end

        assign      buf_full        = buf_full_q;


        if(P_CUT_VALID) begin: CUT_VALID_ENABLE
            assign      pop_vld     = buf_full;
            assign      pop_data    = buf_q;
        end else begin: CUT_VALID_DISABLE
            assign      pop_vld     = buf_full | push_vld;
            assign      pop_data    = buf_full ? buf_q : push_data;
        end

        if(P_CUT_READY == 1'b1) begin: CUT_READY_ENABLE
            assign      push_rdy_raw    = buf_not_full;
        end else begin: CUT_READY_DISABLE
            assign      push_rdy_raw    = buf_not_full | pop_rdy;
        end

    // 深度大于等于2的时候，创建一个真正的FIFO
    end else begin: GEN_DEEPTH_GT_1
        // buf数组
        reg[P_DATA_WIDTH - 1 : 0]       buf_mem_q[P_DEEPTH - 1 : 0];
        wire[P_DEEPTH - 1 : 0]          buf_mem_rld;
        wire[P_DATA_WIDTH - 1 : 0]      buf_mem_d[P_DEEPTH - 1 : 0];

        // 写向量
        reg[P_DEEPTH - 1 : 0]           wr_vec_q;
        wire                            wr_vec_sll;
        wire                            wr_vec_init;
        wire                            wr_vec_rld;
        wire[P_DEEPTH - 1 : 0]          wr_vec_d;

        // 读向量
        reg[P_DEEPTH - 1 : 0]           rd_vec_q;
        wire                            rd_vec_sll;
        wire                            rd_vec_init;
        wire                            rd_vec_rld;
        wire[P_DEEPTH - 1 : 0]          rd_vec_d;

        reg                             buf_full_q;
        wire                            buf_full_set;
        wire                            buf_full_clr;
        wire                            buf_full_rld;
        wire                            buf_full_d;

        reg                             buf_empty_q;
        wire                            buf_empty_set;
        wire                            buf_empty_clr;
        wire                            buf_empty_rld;
        wire                            buf_empty_d;

        wire                            rd_catch_up_wr;
        wire                            wr_catch_up_rd;

        reg[P_DATA_WIDTH - 1 : 0]       pop_data_mux;

        genvar                          i;
        integer                         j;


        for(i = 0; i < P_DEEPTH; i = i + 1) begin: GEN_BUFFER_MEM
            assign      buf_mem_rld[i] = wr_vec_q[i] & push_hsked;
            assign      buf_mem_d[i] = push_data;
            always@(posedge clk or negedge reset_n) begin
                if(reset_n == 1'b0) begin
                    buf_mem_q[i] <= {P_DATA_WIDTH{1'b0}};
                end else if(buf_mem_rld[i]) begin
                    buf_mem_q[i] <= buf_mem_d[i];
                end
            end
        end

        // 写指针，这里使用向量模式，以支持非2^n次方的深度
        assign      wr_vec_rld = push_hsked | flush_hsked;
        assign      wr_vec_d =  flush_hsked ? {{(P_DEEPTH - 1){1'b0}}, 1'b1} :
                                {wr_vec_q[P_DEEPTH - 2 : 0], wr_vec_q[P_DEEPTH - 1]};
        always@(posedge clk or negedge reset_n) begin
            if(reset_n == 1'b0) begin
                wr_vec_q <= {{(P_DEEPTH - 1){1'b0}}, 1'b1};
            end else if(wr_vec_rld) begin
                wr_vec_q <= wr_vec_d;
            end
        end

        // 生成读指针
        assign      rd_vec_rld = pop_hsked | flush_hsked;
        assign      rd_vec_d =  flush_hsked ? {{(P_DEEPTH - 1){1'b0}}, 1'b1} :
                                {rd_vec_q[P_DEEPTH - 2 : 0], rd_vec_q[P_DEEPTH - 1]};
        always@(posedge clk or negedge reset_n) begin
            if(reset_n == 1'b0) begin
                rd_vec_q <= {{(P_DEEPTH - 1){1'b0}}, 1'b1};
            end else if(rd_vec_rld) begin
                rd_vec_q <= rd_vec_d;
            end
        end

        // 如果写指针追上了读指针，则表示buf已经満了
        assign      wr_catch_up_rd = |(wr_vec_d & rd_vec_q);

        assign      buf_full_set = push_hsked & wr_catch_up_rd;
        assign      buf_full_clr = pop_hsked;
        assign      buf_full_rld = buf_full_set ^ buf_full_clr;
        assign      buf_full_d = buf_full_set;
        always@(posedge clk or negedge reset_n) begin
            if(reset_n == 1'b0) begin
                buf_full_q <= 1'b0;
            end else if(flush_hsked) begin
                buf_full_q <= 1'b0;
            end else if(buf_full_rld) begin
                buf_full_q <= buf_full_d;
            end
        end

        // 如果读指针追上了写指针，则表示buf为空
        assign      rd_catch_up_wr = |(rd_vec_d & wr_vec_q);

        assign      buf_empty_set = pop_hsked & rd_catch_up_wr;
        assign      buf_empty_clr = push_hsked;
        assign      buf_empty_rld = buf_empty_set ^ buf_empty_clr;
        assign      buf_empty_d = buf_empty_set;
        always@(posedge clk or negedge reset_n) begin
            if(reset_n == 1'b0) begin
                buf_empty_q <= 1'b1;
            end else if(flush_hsked) begin
                buf_empty_q <= 1'b1;
            end else if(buf_empty_rld) begin
                buf_empty_q <= buf_empty_d;
            end
        end

        assign      buf_full            = buf_full_q;
        assign      buf_not_full        = ~buf_full;
        assign      buf_empty           = buf_empty_q;
        assign      buf_not_empty       = ~buf_empty;

        always@(*) begin
            pop_data_mux = {P_DATA_WIDTH{1'b0}};

            for(j = 0; j < P_DEEPTH; j = j + 1) begin
                pop_data_mux = pop_data_mux | ({P_DATA_WIDTH{rd_vec_q[j]}} & buf_mem_q[j]);
            end
        end


        if(P_CUT_VALID) begin: CUT_VALID_ENABLE
            assign      pop_vld     = buf_not_empty;
            assign      pop_data    = pop_data_mux;
        end else begin: CUT_VALID_DISABLE
            assign      pop_vld     = buf_not_empty | push_vld;
            assign      pop_data    = buf_empty ? push_data : pop_data_mux;
        end

        if(P_CUT_READY == 1'b1) begin: CUT_READY_ENABLE
            assign      push_rdy_raw = buf_not_full;
        end else begin: CUT_READY_DISABLE
            assign      push_rdy_raw = buf_not_full | pop_rdy;
        end
    end
endgenerate


// 生成flush_ack
generate
    if(P_FLUSH_DELAY) begin: FLUSH_DELAY_ENABLE
        // 如果开启了延迟flush，则需要等buf为空，或者口子上的数据已经被接收了，才表示冲刷完成
        assign      flush_hsked = flush_req & (buf_empty | pop_rdy);

        if(P_CUT_READY) begin
            assign      flush_ack = buf_empty;
        end else begin
            assign      flush_ack = buf_empty | pop_rdy;
        end
    // P_FLUSH_DELAY为0时，立即接受冲刷请求
    end else begin: FLUSH_DELAY_DISABLE
        assign      flush_hsked = flush_req;
        assign      flush_ack   = 1'b1;
    end
endgenerate

endmodule