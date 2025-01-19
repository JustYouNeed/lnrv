module lnrv_icb_slice#
(
    parameter                           P_ADDR_WIDTH            = 32,
    parameter                           P_DATA_WIDTH            = 32,

    parameter                           P_CMD_CUT_VALID         = 1'b1,
    parameter                           P_CMD_CUT_READY         = 1'b1,
    parameter                           P_CMD_BUF_DEEPTH        = 1,

    parameter                           P_RSP_CUT_VALID         = 1'b1,
    parameter                           P_RSP_CUT_READY         = 1'b1,
    parameter                           P_RSP_BUF_DEEPTH        = 1,

    // 支持的Outstanding传输数量
    parameter                           P_OTS_COUNT             = 1,

    // 0: 仅使能buff功能
    // 1: 使能outstanding控制，开启时模块会在达到P_CMD_BUF_DEEPTH时阻塞后续传输
    parameter                           P_OTS_CTRL_ENABLE       = 0,

    // 0: 禁用flush功能
    // 1：启用flush功能
    parameter                           P_FLUSH_ENABLE          = 0
)
(
    // 发出的command都视为无效状态，不会对上游返回对应的response
    input                               flush_req,
    output                              flush_ack,

    // 上游接口
    input                               icb_cmd_vld_m,
    output                              icb_cmd_rdy_m,
    input                               icb_cmd_write_m,
    input[P_ADDR_WIDTH - 1 : 0]         icb_cmd_addr_m,
    input[P_DATA_WIDTH - 1 : 0]         icb_cmd_wdata_m,
    input[(P_DATA_WIDTH/8) - 1 : 0]     icb_cmd_wstrb_m,
    input[2 : 0]                        icb_cmd_size_m,
    input[1 : 0]                        icb_cmd_burst_m,
    input[3 : 0]                        icb_cmd_len_m,
    input[2 : 0]                        icb_cmd_prot_m,
    input[3 : 0]                        icb_cmd_cache_m,
    output                              icb_rsp_vld_m,
    input                               icb_rsp_rdy_m,
    output[P_DATA_WIDTH - 1 : 0]        icb_rsp_rdata_m,
    output                              icb_rsp_err_m,

    // 下游接口
    output                              icb_cmd_vld_s,
    input                               icb_cmd_rdy_s,
    output                              icb_cmd_write_s,
    output[P_ADDR_WIDTH - 1 : 0]        icb_cmd_addr_s,
    output[P_DATA_WIDTH - 1 : 0]        icb_cmd_wdata_s,
    output[(P_DATA_WIDTH/8) - 1 : 0]    icb_cmd_wstrb_s,
    output[2 : 0]                       icb_cmd_size_s,
    output[1 : 0]                       icb_cmd_burst_s,
    output[3 : 0]                       icb_cmd_len_s,
    output[2 : 0]                       icb_cmd_prot_s,
    output[3 : 0]                       icb_cmd_cahce_s,
    input                               icb_rsp_vld_s,
    output                              icb_rsp_rdy_s,
    input[P_DATA_WIDTH - 1 : 0]         icb_rsp_rdata_s,
    input                               icb_rsp_err_s,

    input                               clk,
    input                               reset_n
);
localparam                              LP_CMD_WSTRB_WIDTH  = P_DATA_WIDTH/8;
localparam                              LP_CMD_BUF_WIDTH    = P_ADDR_WIDTH + P_DATA_WIDTH + LP_CMD_WSTRB_WIDTH + 17;
localparam                              LP_RSP_BUF_WIDTH    = P_DATA_WIDTH + 1;

localparam                              LP_OTS_CNT_WIDTH  = $clog2(P_OTS_COUNT) + 1;

wire[LP_CMD_BUF_WIDTH - 1 : 0]          cmd_buf_push_data;
wire                                    cmd_buf_push_vld;
wire                                    cmd_buf_push_rdy;

wire[LP_CMD_BUF_WIDTH - 1 : 0]          cmd_buf_pop_data;
wire                                    cmd_buf_pop_vld;
wire                                    cmd_buf_pop_rdy;

wire[LP_RSP_BUF_WIDTH - 1 : 0]          rsp_buf_push_data;
wire                                    rsp_buf_push_vld;
wire                                    rsp_buf_push_rdy;

wire[LP_RSP_BUF_WIDTH - 1 : 0]          rsp_buf_pop_data;
wire                                    rsp_buf_pop_vld;
wire                                    rsp_buf_pop_rdy;

wire                                    icb_cmd_hsked_m;
wire                                    icb_rsp_hsked_m;

wire                                    cmd_buf_push_enable;


assign      icb_cmd_hsked_m = icb_cmd_vld_m & icb_cmd_rdy_m;
assign      icb_rsp_hsked_m = icb_rsp_vld_m & icb_rsp_rdy_m;


generate
    if(P_OTS_CTRL_ENABLE) begin: OTS_CTRL_ENABLE
        reg[LP_OTS_CNT_WIDTH - 1 : 0]               ots_cnt_q;
        wire                                        ots_cnt_inc;
        wire                                        ots_cnt_dec;
        wire                                        ots_cnt_rld;
        wire[LP_OTS_CNT_WIDTH - 1 : 0]              ots_cnt_d;

        wire[LP_OTS_CNT_WIDTH - 1 : 0]              ots_cnt_add_1;
        wire[LP_OTS_CNT_WIDTH - 1 : 0]              ots_cnt_sub_1;

        wire                                        ots_cnt_eq_max;

        assign      ots_cnt_add_1 = ots_cnt_q + 1'b1;
        assign      ots_cnt_sub_1 = ots_cnt_q - 1'b1;

        assign      ots_cnt_inc = icb_cmd_hsked_m;
        assign      ots_cnt_dec = icb_rsp_hsked_m;
        assign      ots_cnt_rld = ots_cnt_dec ^ ots_cnt_inc;
        assign      ots_cnt_d = ots_cnt_inc ? ots_cnt_add_1 : ots_cnt_sub_1;
        always@(posedge clk or negedge reset_n) begin
            if(reset_n == 1'b0) begin
                ots_cnt_q <= {LP_OTS_CNT_WIDTH{1'b0}};
            end else if(ots_cnt_rld) begin
                ots_cnt_q <= ots_cnt_d;
            end
        end

        assign      ots_cnt_eq_max = (ots_cnt_q == P_OTS_COUNT);

        assign      cmd_buf_push_enable = (~ots_cnt_eq_max) | icb_rsp_hsked_m;
    end else begin: OTS_CTRL_DISABLE
        assign      cmd_buf_push_enable = 1'b1;
    end
endgenerate



// command
assign      icb_cmd_rdy_m = cmd_buf_push_rdy & cmd_buf_push_enable;
assign      cmd_buf_push_vld = icb_cmd_vld_m & cmd_buf_push_enable;
assign      cmd_buf_push_data = {
                                    icb_cmd_addr_m,
                                    icb_cmd_wdata_m,
                                    icb_cmd_size_m,
                                    icb_cmd_wstrb_m,
                                    icb_cmd_write_m,
                                    icb_cmd_burst_m,
                                    icb_cmd_len_m,
                                    icb_cmd_prot_m,
                                    icb_cmd_cache_m
                                };

// command buffer
lnrv_gnrl_buf#
(
    .P_DATA_WIDTH           ( LP_CMD_BUF_WIDTH          ),
    .P_DEEPTH               ( P_CMD_BUF_DEEPTH          ),

    .P_CUT_VALID            ( P_CMD_CUT_VALID           ),
    .P_CUT_READY            ( P_CMD_CUT_READY           ),
    .P_FLUSH_DELAY          ( 1'b1                      )
)
u_icb_cmd_buff
(
    .clk                    ( clk                       ),
    .reset_n                ( reset_n                   ),

    .flush_req              ( 1'b0                      ),
    .flush_ack              (                           ),

    .push_vld               ( cmd_buf_push_vld          ),
    .push_rdy               ( cmd_buf_push_rdy          ),
    .push_data              ( cmd_buf_push_data         ),
    .pop_vld                ( cmd_buf_pop_vld           ),
    .pop_rdy                ( cmd_buf_pop_rdy           ),
    .pop_data               ( cmd_buf_pop_data          )
);

assign      {
                icb_cmd_addr_s,
                icb_cmd_wdata_s,
                icb_cmd_size_s,
                icb_cmd_wstrb_s,
                icb_cmd_write_s,
                icb_cmd_burst_s,
                icb_cmd_len_s,
                icb_cmd_prot_s,
                icb_cmd_cache_s
            } = cmd_buf_pop_data;
assign      icb_cmd_vld_s = cmd_buf_pop_vld;
assign      cmd_buf_pop_rdy = icb_cmd_rdy_s;

// response
assign      icb_rsp_rdy_s = rsp_buf_push_rdy;
assign      rsp_buf_push_vld = icb_rsp_vld_s;
assign      rsp_buf_push_data = {
                                    icb_rsp_rdata_s,
                                    icb_rsp_err_s
                                };

// response buffer
lnrv_gnrl_buf#
(
    .P_DATA_WIDTH           ( LP_RSP_BUF_WIDTH          ),
    .P_DEEPTH               ( P_RSP_BUF_DEEPTH          ),

    .P_CUT_VALID            ( P_RSP_CUT_VALID           ),
    .P_CUT_READY            ( P_RSP_CUT_READY           ),
    .P_FLUSH_DELAY          ( 1'b1                      )
)
u_icb_rsp_buff
(
    .clk                    ( clk                       ),
    .reset_n                ( reset_n                   ),

    .flush_req              ( 1'b0                      ),
    .flush_ack              (                           ),

    .push_vld               ( rsp_buf_push_vld          ),
    .push_rdy               ( rsp_buf_push_rdy          ),
    .push_data              ( rsp_buf_push_data         ),
    .pop_vld                ( rsp_buf_pop_vld           ),
    .pop_rdy                ( rsp_buf_pop_rdy           ),
    .pop_data               ( rsp_buf_pop_data          )
);

assign      rsp_buf_pop_rdy = icb_rsp_rdy_m;
assign      {
                icb_rsp_rdata_m,
                icb_rsp_err_m
            } = rsp_buf_pop_data;
assign      icb_rsp_vld_m = rsp_buf_pop_vld;

// 立即回复ACK
assign      flush_ack = 1'b1;

endmodule