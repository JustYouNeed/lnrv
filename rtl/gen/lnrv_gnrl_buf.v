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

wire                                buf_full;
wire                                buf_not_full;

wire                                buf_empty;
wire                                buf_not_empty;

wire                                push_hsked;
wire                                pop_hsked;
wire                                pop_xor_push;
wire                                flush_hsked;



assign      push_hsked      = push_vld & push_rdy;
assign      flush_hsked     = flush_req & flush_ack;

generate
    if(P_FLUSH_DELAY) begin
        assign      pop_hsked = pop_vld & pop_rdy;
    end else begin
        assign      pop_hsked = pop_vld & (pop_rdy | flush_req);
    end
endgenerate

assign      pop_xor_push    = push_hsked ^ pop_hsked;

assign      buf_not_empty   = ~buf_empty;
assign      buf_not_full    = ~buf_full;

generate

    // 如果FIFO深度为0，则直接将输出与输入相连即可
    if(P_DEEPTH == 0) begin: GEN_DEEPTH_IS_0
        assign      pop_data        = push_data;

        assign      pop_vld         = push_vld;
        assign      push_rdy        = pop_rdy;

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
            end else if(flush_req) begin
                buf_q <= {P_DATA_WIDTH{1'b0}};
            end else if(buf_rld) begin
                buf_q <=  buf_d;
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
        assign      buf_empty       = buf_not_full;


        if(P_CUT_VALID) begin: CUT_VALID_ENABLE
            assign      pop_vld     = buf_full;
            assign      pop_data    = buf_q;
        end else begin: CUT_VALID_DISABLE
            assign      pop_vld     = buf_full | push_vld;
            assign      pop_data    = buf_full ? buf_q : push_data;
        end

        if(P_CUT_READY == 1'b1) begin: CUT_READY_ENABLE
            assign      push_rdy    = buf_not_full;
        end else begin: CUT_READY_DISABLE
            assign      push_rdy    = buf_not_full | pop_rdy;
        end

    // 深度大于等于2的时候，创建一个真正的FIFO
    end else begin: GEN_DEEPTH_GT_1
        // buf数组
        reg[P_DATA_WIDTH - 1 : 0]       buf_mem_q[P_DEEPTH - 1 : 0];
        wire[P_DEEPTH - 1 : 0]          buf_mem_rld;
        wire[P_DATA_WIDTH - 1 : 0]      buf_mem_d[P_DEEPTH - 1 : 0];

        // 写向量，指向下一个数据的地址，onehot编码
        reg[P_DEEPTH - 1 : 0]           wr_vec_q;
        wire                            wr_vec_rld;
        wire[P_DEEPTH - 1 : 0]          wr_vec_d;
        wire[P_DEEPTH - 1 : 0]          wr_vec_flush;
        wire[P_DEEPTH - 1 : 0]          wr_vec_rsl;

        // 读向量，指向当前读数据的地址，onehont编码
        reg[P_DEEPTH - 1 : 0]           rd_vec_q;
        wire                            rd_vec_rld;
        wire[P_DEEPTH - 1 : 0]          rd_vec_d;
        wire[P_DEEPTH - 1 : 0]          rd_vec_rsl;

        // 真正的写指针，用于选择buf_mem
        wire[P_DEEPTH - 1 : 0]          wr_vec_real;

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


        // 如果有冲刷请求，我们需要将数据写到读指针下一个位置，因为在冲刷时我们会调整写指针，此时的写指针不是真正有效的
        assign      wr_vec_real = flush_hsked ? rd_vec_rsl : wr_vec_q;


        for(i = 0; i < P_DEEPTH; i = i + 1) begin: GEN_BUFFER_MEM
            assign      buf_mem_rld[i] = wr_vec_real[i] & push_hsked;
            assign      buf_mem_d[i] = push_data;
            always@(posedge clk or negedge reset_n) begin
                if(reset_n == 1'b0) begin
                    buf_mem_q[i] <= {P_DATA_WIDTH{1'b0}};
                end else if(buf_mem_rld[i]) begin
                    buf_mem_q[i] <= buf_mem_d[i];
                end
            end
        end


        // 如果在冲刷时有新的数据进来，我们需要将当前进来的数据保存到当前读指针的下一个位置，
        //      同时写指针需要指向读指针后两个的位置，
        // 如果在冲刷时没有新的数据进来，我们只需要将写指针移动到读指针后一个的位置即可
        assign      wr_vec_flush =  push_hsked ? {rd_vec_q[0 +: (P_DEEPTH - 2)], rd_vec_q[P_DEEPTH - 2 +: 2]} :
                                    rd_vec_rsl;

        // 写指针循环左移
        assign      wr_vec_rsl = {wr_vec_q[0 +: (P_DEEPTH - 1)], wr_vec_q[P_DEEPTH - 1]};

        // 写指针，这里使用向量模式，以支持非2^n次方的深度
        assign      wr_vec_rld = push_hsked | flush_hsked;
        // 如果有flush握手成功，则使用flush的写指针，否则使用循左移的指针
        assign      wr_vec_d =  flush_hsked ? wr_vec_flush : wr_vec_rsl;
        always@(posedge clk or negedge reset_n) begin
            if(reset_n == 1'b0) begin
                wr_vec_q <= {{(P_DEEPTH - 1){1'b0}}, 1'b1};
            end else if(wr_vec_rld) begin
                wr_vec_q <= wr_vec_d;
            end
        end

        // 读指针循环左移
        assign      rd_vec_rsl = {rd_vec_q[0 +: (P_DEEPTH - 1)], rd_vec_q[P_DEEPTH - 1]};

        // 我们在flush握手成功的时候也会更新读指针，以
        assign      rd_vec_rld = pop_hsked;
        // 读指针不受冲刷请求影响，我们通过移动写指针的方式来冲刷buf
        assign      rd_vec_d =  rd_vec_rsl;
        always@(posedge clk or negedge reset_n) begin
            if(reset_n == 1'b0) begin
                rd_vec_q <= {{(P_DEEPTH - 1){1'b0}}, 1'b1};
            end else if(rd_vec_rld) begin
                rd_vec_q <= rd_vec_d;
            end
        end

        // 如果写指针追上了读指针，则表示buf已经満了
        assign      wr_catch_up_rd = |(wr_vec_d & rd_vec_q);

        // 如果当前有新的数据进来，且写指针追上了读指针，则buffer满了
        assign      buf_full_set = push_hsked & wr_catch_up_rd;
        // 如果有数据出去了，否则有flush请求，则buffer肯定不是満状态
        assign      buf_full_clr = pop_hsked | flush_hsked;
        assign      buf_full_rld = buf_full_set ^ buf_full_clr;
        assign      buf_full_d = buf_full_set;
        always@(posedge clk or negedge reset_n) begin
            if(reset_n == 1'b0) begin
                buf_full_q <= 1'b0;
            end else if(buf_full_rld) begin
                buf_full_q <= buf_full_d;
            end
        end

        // 如果读指针追上了写指针，则表示buf为空
        assign      rd_catch_up_wr = |(rd_vec_d & wr_vec_q);

        // 在往外送数据的时候，如果满足下列任一条件，我们认为buffer已经空了
        //  1、读指针已经追上了写指针
        //  2、冲刷握手成功
        // assign      buf_empty_set = (pop_hsked & rd_catch_up_wr) |
        //                             (flush_hsked & (~push_hsked));
        if(P_FLUSH_DELAY) begin
            assign      buf_empty_set = (pop_hsked & rd_catch_up_wr);
        end else begin
            assign      buf_empty_set = (pop_hsked & rd_catch_up_wr) | flush_hsked;
        end
        // 如果有新的数据进来，buffer肯定不是空了
        assign      buf_empty_clr = push_hsked;
        // 只有在set和clr不一样的情况下，我们才会更新buf_empty寄存器，因为set和clr同时发生，则buf_empty的状态肯定不变
        assign      buf_empty_rld = buf_empty_set ^ buf_empty_clr;
        //  +---------------+---------------+-------------+-------------+
        //  | buf_empty_set | buf_empty_clr | buf_empty_q | buf_empty_d |
        //  +---------------+---------------+-------------+-------------+
        //  |       0       |       0       |      0      |      0      |
        //  +---------------+---------------+-------------+-------------+
        //  |       0       |       0       |      1      |      1      |
        //  +---------------+---------------+-------------+-------------+
        //  |       0       |       1       |      0      |      0      |
        //  +---------------+---------------+-------------+-------------+
        //  |       0       |       1       |      1      |      0      |
        //  +---------------+---------------+-------------+-------------+
        //  |       1       |       0       |      0      |      1      |
        //  +---------------+---------------+-------------+-------------+
        //  |       1       |       0       |      1      |      1      |
        //  +---------------+---------------+-------------+-------------+
        //  |       1       |       1       |      0      |      0      |
        //  +---------------+---------------+-------------+-------------+
        //  |       1       |       1       |      1      |      1      |
        //  +---------------+---------------+-------------+-------------+
        assign      buf_empty_d = buf_empty_set;
        always@(posedge clk or negedge reset_n) begin
            if(reset_n == 1'b0) begin
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
            assign      push_rdy = buf_not_full;
        end else begin: CUT_READY_DISABLE
            assign      push_rdy = buf_not_full | pop_rdy;
        end
    end
endgenerate

assign      flush_ack   = 1'b1;

endmodule