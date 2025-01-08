module lnrv_gnrl_fifo#
(
    parameter                       P_DATA_WIDTH    = 32,
    parameter                       P_DEEPTH        = 1,

    // 切断上游valid向下游的组合路径，当工作于fully mode时该参数默认为true，配置无效
    parameter                       P_CUT_VALID     = 1'b0,

    // 切断下游ready向上游的组合路径，当工作于fully mode时该参数默认为true，配置无效
    parameter                       P_CUT_READY     = 1'b0,

    // buffer的工作模式，只有在P_DEEPTH为1时生效，因为深度为1才是真正的buffer
    // 0: forward mode
    // 1: backwar mode
    // 2: fully
    parameter                       P_MODE          = 0
)
(
    input                           clk,
    input                           reset_n,

    // 冲刷请求
    input                           flush_req,
    output                          flush_ack,

    input                           push_vld,
    output                          push_rdy,
    input[P_DATA_WIDTH - 1 : 0]     push_data,

    input                           pop_rdy,
    output                          pop_vld,
    output[P_DATA_WIDTH - 1 : 0]    pop_data
);

generate
    // 如果FIFO深度为0，则直接将输出与输入相连即可
    if(P_DEEPTH == 0) begin: FIFO_DEEPTH_IS_0
        assign      pop_data    = push_data;
        assign      pop_vld     = push_vld;
        assign      push_rdy    = pop_rdy;
    // FIFO深度为1，则使用一个buffer即可
    end else if(P_DEEPTH == 1) begin: FIFO_DEEPTH_IS_1
        reg[P_DATA_WIDTH - 1 : 0]           buf_q;
        wire                                buf_rld;
        wire[P_DATA_WIDTH - 1 : 0]          buf_d;

        wire                                buf_full;
        wire                                buf_not_full;

        wire                                buf_empty;
        wire                                buf_not_empty;

        wire                                push_hsked;
        wire                                pop_hsked;

        assign      push_hsked = push_vld & push_rdy;
        assign      pop_hsked = pop_vld & pop_rdy;

        // 输入端握手成功，则表示可以将数据加载到buffer中
        assign      buf_rld = push_hsked;
        assign      buf_d = push_data;
        always@(posedge clk or negedge reset_n) begin
            if(reset_n == 1'b0) begin
                buf_q <= {P_DATA_WIDTH{1'b0}};
            end else if(buf_rld) begin
                buf_q <= buf_d;
            end
        end

        // 前向模式，在该模式下，在valid路径上插入寄存器，打断valid时序路径
        if((P_MODE == 0) || (P_MODE == 2)) begin: GEN_BUFFER_FULL
            reg                                 buf_full_q;
            wire                                buf_full_set;
            wire                                buf_full_clr;
            wire                                buf_full_rld;
            wire                                buf_full_d;

            // 如果buffer加载了新的数据，则buf已经满了
            assign      buf_full_set = push_hsked;
            // 如果输出端读取了buffer中的数据，则表示
            assign      buf_full_clr = pop_hsked;
            assign      buf_full_rld = buf_full_set | buf_full_clr;
            // 读写可能同时发生，此时buffer中的数据仍有效
            assign      buf_full_d = buf_full_set;
            always@(posedge clk or negedge reset_n) begin
                if(reset_n == 1'b0) begin
                    buf_full_q <= 1'b0;
                end else if(flush_req) begin
                    buf_full_q <= 1'b0;
                end else if(buf_full_rld) begin
                    buf_full_q <= buf_full_d;
                end
            end

            if(P_CUT_READY == 1'b1) begin: CUT_READY_ENABLE
                assign      buf_not_full = (~buf_full_q);
            end else begin: CUT_READY_DISABLE
                assign      buf_not_full = (~buf_full_q) | buf_full_clr;
            end

            assign      buf_full = buf_full_q;
        end else begin
            assign      buf_full = buf_not_empty;
        end

        // 后向模式，在该模式下，在ready路径上插入寄存器，打断ready的时序路径
        if((P_MODE == 1) || (P_MODE == 2)) begin: GEN_BUFFER_EMPTY
            reg                                 buf_empty_q;
            wire                                buf_empty_set;
            wire                                buf_empty_clr;
            wire                                buf_empty_rld;
            wire                                buf_empty_d;

            assign      buf_empty_set = pop_rdy;
            assign      buf_empty_clr = push_vld & (~pop_rdy);
            // 如果set和clr同时发生，则当前寄存器的状态不会有改变，因此只有在set和clr不同时才更新寄存器的值
            assign      buf_empty_rld = buf_empty_set ^ buf_empty_clr;
            // set的优先级更高
            assign      buf_empty_d = buf_empty_set;
            always@(posedge clk or negedge reset_n) begin
                if(reset_n == 1'b0) begin
                    buf_empty_q <= 1'b1;
                end else if(flush_req) begin
                    buf_empty_q <= 1'b1;
                end else if(buf_empty_rld) begin
                    buf_empty_q <= buf_empty_d;
                end
            end

            if(P_CUT_VALID == 1'b1) begin: CUT_VALID_ENABLE
                assign      buf_not_empty = ~buf_empty_q;
            end else begin: CUT_VALID_DISABLE
                assign      buf_not_empty = (~buf_empty_q) | push_vld;
            end

            assign      buf_empty = buf_empty_q;
        end else begin
            assign      buf_empty = buf_not_full;
        end

        // 前向模式
        if(P_MODE == 0) begin: FORWARD_MODE
            assign      pop_vld     = buf_full;
            assign      push_rdy    = buf_not_full;

            assign      pop_data    = buf_q;
        // 后向模式
        end else if(P_MODE == 1) begin: BACKWARD_MODE
            assign      pop_vld     = buf_not_empty;
            assign      push_rdy    = buf_empty;

            assign      pop_data    = buf_empty ? push_data : buf_q;
        // 全向模式
        end else if(P_MODE == 2) begin: FULLY_MODE
            assign      pop_vld     = buf_full;
            assign      push_rdy    = buf_empty;

            assign      pop_data    = buf_q;
        end
    // FIFO深度大于等于2的时候，创建一个真正的FIFO，同时需要保证FIFO深度必须是2的整数次幂
    end else begin: FIFO_DEEPTH_GT_1
        localparam                      LP_PTR_WIDTH = $clog2(P_DEEPTH);

        reg[P_DATA_WIDTH - 1 : 0]       fifo_mem[P_DEEPTH - 1 : 0];

        wire                            fifo_wen;
        wire                            fifo_ren;
        wire                            fifo_wr_full;
        wire                            fifo_rd_empty;

        reg[LP_PTR_WIDTH : 0]           wr_ptr_q;
        wire                            wr_ptr_inc;
        wire                            wr_ptr_rld;
        wire[LP_PTR_WIDTH : 0]          wr_ptr_d;


        reg[LP_PTR_WIDTH : 0]           rd_ptr_q;
        wire                            rd_ptr_inc;
        wire                            rd_ptr_rld;
        wire[LP_PTR_WIDTH : 0]          rd_ptr_d;


        wire                            wr_cycle;
        wire                            rd_cycle;
        wire                            wr_rd_cycle_eq;
        wire                            wr_rd_cycle_not_eq;

        wire[LP_PTR_WIDTH - 1 : 0]      wr_addr;
        wire[LP_PTR_WIDTH - 1 : 0]      rd_addr;
        wire                            wr_rd_addr_eq;
        wire                            wr_rd_addr_not_eq;

        wire                            push_hsked;
        wire                            pop_hsked;

        integer                         i;

        assign      push_hsked = push_vld & push_rdy;
        assign      pop_hsked = pop_vld & pop_rdy;

        assign      fifo_wen = push_hsked;
        assign      fifo_ren = pop_hsked;


        always@(posedge clk or negedge reset_n) begin
            // if(reset_n == 1'b0) begin
            //     for(i = 0; i < P_DEEPTH; i = i + 1) begin
            //         fifo_mem[i] <= {P_DATA_WIDTH{1'b0}};
            //     end
            // end else
            if(fifo_wen) begin
                fifo_mem[wr_addr] <= push_data;
            end
        end

        // 写指针
        assign      wr_ptr_inc = fifo_wen;
        assign      wr_ptr_rld = wr_ptr_inc;
        assign      wr_ptr_d = wr_ptr_q + 1'b1;
        always@(posedge clk or negedge reset_n) begin
            if(reset_n == 1'b0) begin
                wr_ptr_q <= {(LP_PTR_WIDTH + 1){1'b0}};
            end else if(flush_req) begin
                wr_ptr_q <= {(LP_PTR_WIDTH + 1){1'b0}};
            end else if(wr_ptr_rld) begin
                wr_ptr_q <= wr_ptr_d;
            end
        end
        assign      wr_addr = wr_ptr_q[LP_PTR_WIDTH - 1 : 0];
        assign      wr_cycle = wr_ptr_q[LP_PTR_WIDTH];

        assign      rd_ptr_inc = fifo_ren;
        assign      rd_ptr_rld = rd_ptr_inc;
        assign      rd_ptr_d = rd_ptr_q + 1'b1;
        always@(posedge clk or negedge reset_n) begin
            if(reset_n == 1'b0) begin
                rd_ptr_q <= {(LP_PTR_WIDTH + 1){1'b0}};
            end else if(flush_req) begin
                rd_ptr_q <= {(LP_PTR_WIDTH + 1){1'b0}};
            end else if(rd_ptr_rld) begin
                rd_ptr_q <= rd_ptr_d;
            end
        end
        assign      rd_addr = rd_ptr_q[LP_PTR_WIDTH - 1 : 0];
        assign      rd_cycle = rd_ptr_q[LP_PTR_WIDTH];

        assign      wr_rd_cycle_not_eq = wr_cycle ^ rd_cycle;
        assign      wr_rd_cycle_eq = ~wr_rd_cycle_not_eq;

        assign      wr_rd_addr_eq = (wr_addr == rd_addr);
        assign      wr_rd_addr_not_eq = ~wr_rd_addr_eq;

        assign      fifo_wr_full = wr_rd_cycle_not_eq & wr_rd_addr_eq;
        assign      fifo_rd_empty = wr_rd_cycle_eq & wr_rd_addr_eq;

        assign      pop_vld = ~fifo_rd_empty;
        assign      pop_data = fifo_mem[rd_addr] & {P_DATA_WIDTH{pop_vld}};

        if(P_CUT_READY == 1'b1) begin
            assign      push_rdy = (~fifo_wr_full);
        end else begin
            assign      push_rdy = (~fifo_wr_full) | fifo_ren;
        end
    end
endgenerate

assign      flush_ack = 1'b1;

endmodule //lnrv_gnrl_fifo
