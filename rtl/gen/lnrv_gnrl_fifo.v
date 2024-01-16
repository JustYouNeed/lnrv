module lnrv_gnrl_fifo#
(
    parameter                       P_DATA_WIDTH = 32,
    parameter                       P_DEEPTH = 1,
    parameter                       P_CUT_READY = "false"
)
(
    input                           clk,
    input                           reset_n,

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
        assign      pop_data = push_data;
        assign      pop_vld = push_vld;
    // FIFO深度为1，则使用一个buffer即可
    end else if(P_DEEPTH == 1) begin: FIFO_DEEPTH_IS_1
        reg[P_DATA_WIDTH - 1 : 0]           fifo_buf_q;
        wire                                fifo_buf_rld;
        wire[P_DATA_WIDTH - 1 : 0]          fifo_buf_d;

        reg                                 fifo_full_q;
        wire                                fifo_full_set;
        wire                                fifo_full_clr;
        wire                                fifo_full_rld;
        wire                                fifo_full_d;

        wire                                fifo_not_full;

        wire                                push_hsked;
        wire                                pop_hsked;

        assign      push_hsked = push_vld & push_rdy & (~flush_req);
        assign      pop_hsked = pop_vld & pop_rdy;

        // 输入端握手成功，则表示可以将数据加载到buffer中
        assign      fifo_buf_rld = push_hsked;
        assign      fifo_buf_d = push_data;
        always@(posedge clk or negedge reset_n) begin
            if(reset_n == 1'b0) begin
                fifo_buf_q <= {P_DATA_WIDTH{1'b0}};
            end else if(fifo_buf_rld) begin
                fifo_buf_q <= fifo_buf_d;
            end
        end

        // 如果buffer加载了新的数据，则fifo已经满了
        assign      fifo_full_set = fifo_buf_rld;
        // 如果输出端读取了buffer中的数据，则标志无效
        assign      fifo_full_clr = pop_hsked;
        assign      fifo_full_rld = fifo_full_set | fifo_full_clr;
        // 读写可能同时发生，此时buffer中的数据仍有效
        assign      fifo_full_d = fifo_full_set;  
        always@(posedge clk or negedge reset_n) begin
            if(reset_n == 1'b0) begin
                fifo_full_q <= 1'b0;
            end else if(flush_req) begin
                fifo_full_q <= 1'b0;
            end else if(fifo_full_rld) begin
                fifo_full_q <= fifo_full_d;
            end
        end

        assign      fifo_not_full = (~fifo_full_q);


        assign      pop_vld = fifo_full_q;
        assign      pop_data = fifo_buf_q;

        // 如果配置了切断ready，则只有当fifo为空的时候才可以接收新的数据，此时每两个cycle
        //      才能接收一个数据，否则当fifo即将为空的时候也可以接收新的数据，此时每个cycle
        //      都可以接收新的数据
        if(P_CUT_READY == "true") begin
            assign      push_rdy = fifo_not_full;
        end else begin
            assign      push_rdy = fifo_not_full | fifo_full_clr;
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

        assign      push_hsked = push_vld & push_rdy & (~flush_req);
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

        if(P_CUT_READY == "true") begin
            assign      push_rdy = (~fifo_wr_full);
        end else begin
            assign      push_rdy = (~fifo_wr_full) | fifo_ren;
        end
    end
endgenerate

assign      flush_ack = 1'b1;

endmodule //lnrv_gnrl_fifo
