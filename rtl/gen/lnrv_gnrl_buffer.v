module	lnrv_gnrl_buffer#
(
	parameter                       P_DATA_WIDTH    = 32,
    parameter                       P_DEEPTH        = 1,
    parameter                       P_BYPASS        = "false",

    // 切断上游valid向下游的组合路径，当工作于fully mode时该参数默认为true，配置无效
    parameter                       P_CUT_VALID     = "false",

    // 切断下游ready向上游的组合路径，当工作于fully mode时该参数默认为true，配置无效
    parameter                       P_CUT_READY     = "false",

    // buffer的工作模式，只有在P_DEEPTH为1时生效，因为深度为1才是真正的buffer
    // 0: forward mode
    // 1: backwar mode
    // 2: fully
    parameter                       P_MODE          = 0
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

wire                            fifo_push_vld;
wire                            fifo_push_rdy;
wire[P_DATA_WIDTH - 1 : 0]      fifo_push_data;

wire                            fifo_pop_vld;
wire                            fifo_pop_rdy;
wire[P_DATA_WIDTH - 1 : 0]      fifo_pop_data;

wire                            bypass;

generate
    if(P_BYPASS == "true") begin
        // 如果当前fifo为空，且接收端可以接收数据，则表示可以将fifo bypass，
        // 直接将输入数据送到输出端，不需要先保存到fifo中
        assign      bypass = pop_rdy & (~fifo_pop_vld);

        assign      pop_data = fifo_pop_vld ? fifo_pop_data : push_data;
        assign      pop_vld = push_vld | fifo_pop_vld;
    end else begin
        assign      bypass = 1'b0;

        assign      pop_data = fifo_pop_data;
        assign      pop_vld = fifo_pop_vld;
    end
endgenerate

// 如果fifo已经被bypass，就不需要往里面写数据了
assign      fifo_push_vld = push_vld & (~bypass);
assign      fifo_push_data = push_data;

assign      push_rdy = fifo_push_rdy;
assign      fifo_pop_rdy = pop_rdy;


lnrv_gnrl_fifo#
(
    .P_DATA_WIDTH       ( P_DATA_WIDTH              ),
    .P_DEEPTH           ( P_DEEPTH                  ),
    .P_CUT_VALID        ( P_CUT_VALID               ),
    .P_CUT_READY        ( P_CUT_READY               ),
    .P_MODE             ( P_MODE                    )
)
u_lnrv_gnrl_fifo
(
    .clk                ( clk                       ),
    .reset_n            ( reset_n                   ),

    .flush_req          ( flush_req                 ),
    .flush_ack          ( flush_ack                 ),

    .push_vld           ( fifo_push_vld             ),
    .push_rdy           ( fifo_push_rdy             ),
    .push_data          ( fifo_push_data            ),

    .pop_rdy            ( fifo_pop_rdy              ),
    .pop_vld            ( fifo_pop_vld              ),
    .pop_data           ( fifo_pop_data             )
);


endmodule