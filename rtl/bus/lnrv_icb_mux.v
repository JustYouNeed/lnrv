module  lnrv_icb_mux#
(
    parameter                                       P_ADDR_WIDTH            = 32,
    parameter                                       P_DATA_WIDTH            = 32,
    parameter                                       P_ICB_COUNT             = 4,

    // 是否在slave端口插入buff，以优化时序，但是会带来额外的latency
    parameter                                       P_CMD_BUFF_ENABLE       = 1'b1,
    parameter                                       P_CMD_BUFF_CUT_READY    = 1'b1,
    parameter                                       P_CMD_BUFF_BYPASS       = 1'b0,
    parameter                                       P_CMD_OTS_COUNT         = 1,

    parameter                                       P_RSP_BUFF_ENABLE       = 1'b1,
    parameter                                       P_RSP_BUFF_CUT_READY    = 1'b1,
    parameter                                       P_RSP_BUFF_BYPASS       = 1'b0,
    parameter                                       P_RSP_OTS_COUNT         = 1
)
(
    input                                           clk,
    input                                           reset_n,

    // master port
    input[P_ICB_COUNT - 1 : 0]                      icb_cmd_vld_mn,
    output[P_ICB_COUNT - 1 : 0]                     icb_cmd_rdy_mn,
    input[P_ICB_COUNT - 1 : 0]                      icb_cmd_write_mn,
    input[(P_ADDR_WIDTH * P_ICB_COUNT) - 1 : 0]     icb_cmd_addr_mn,
    input[(P_DATA_WIDTH * P_ICB_COUNT) - 1 : 0]     icb_cmd_wdata_mn,
    input[((P_DATA_WIDTH/8) * P_ICB_COUNT) - 1 : 0] icb_cmd_wstrb_mn,
    input[(P_ICB_COUNT * 3) - 1 : 0]                icb_cmd_size_mn,

    input[P_ICB_COUNT - 1 : 0]                      icb_rsp_rdy_mn,
    output[P_ICB_COUNT - 1 : 0]                     icb_rsp_vld_mn,
    output[(P_DATA_WIDTH * P_ICB_COUNT) - 1 : 0]    icb_rsp_rdata_mn,
    output[P_ICB_COUNT - 1 : 0]                     icb_rsp_err_mn,

    // slave port
    output                                          icb_cmd_vld_s,
    input                                           icb_cmd_rdy_s,
    output                                          icb_cmd_write_s,
    output[P_ADDR_WIDTH - 1 : 0]                    icb_cmd_addr_s,
    output[P_DATA_WIDTH - 1 : 0]                    icb_cmd_wdata_s,
    output[(P_DATA_WIDTH / 8) - 1 : 0]              icb_cmd_wstrb_s,
    output[2 : 0]                                   icb_cmd_size_s,

    input                                           icb_rsp_vld_s,
    output                                          icb_rsp_rdy_s,
    input[P_DATA_WIDTH - 1 : 0]                     icb_rsp_rdata_s,
    input                                           icb_rsp_err_s
);
localparam                                          LP_DISP_BUF_DATA_WIDTH = P_ICB_COUNT;

// 分发信息fifo
wire[LP_DISP_BUF_DATA_WIDTH - 1 : 0]                disp_buf_push_data;
wire                                                disp_buf_push_vld;
wire                                                disp_buf_push_rdy;

wire[LP_DISP_BUF_DATA_WIDTH - 1 : 0]                disp_buf_pop_data;
wire                                                disp_buf_pop_vld;
wire                                                disp_buf_pop_rdy;

wire[P_ICB_COUNT - 1 : 0]                           icb_cmd_req_mn;
wire[P_ICB_COUNT - 1 : 0]                           icb_cmd_grant_mn;
wire[P_ICB_COUNT - 1 : 0]                           icb_rsp_grant;

// 各个master的信息
wire[P_ICB_COUNT - 1 : 0]                           icb_cmd_vld_m_mux;
wire[P_ICB_COUNT - 1 : 0]                           icb_cmd_write_m_mux;
wire[P_ADDR_WIDTH - 1 : 0]                          icb_cmd_addr_m_mux[P_ICB_COUNT - 1 : 0];
wire[P_DATA_WIDTH - 1 : 0]                          icb_cmd_wdata_m_mux[P_ICB_COUNT - 1 : 0];
wire[(P_DATA_WIDTH/8) - 1 : 0]                      icb_cmd_wstrb_m_mux[P_ICB_COUNT - 1 : 0];
wire[2 : 0]                                         icb_cmd_size_m_mux[P_ICB_COUNT - 1 : 0];

wire                                                icb_cmd_vld_m;
wire                                                icb_cmd_rdy_m;
wire                                                icb_cmd_write_m;
reg[P_ADDR_WIDTH - 1 : 0]                           icb_cmd_addr_m;
reg[P_DATA_WIDTH - 1 : 0]                           icb_cmd_wdata_m;
reg[(P_DATA_WIDTH/8) - 1 : 0]                       icb_cmd_wstrb_m;
reg[2 : 0]                                          icb_cmd_size_m;
wire                                                icb_cmd_hsked_m;

wire                                                icb_rsp_vld_m;
wire                                                icb_rsp_rdy_m;
wire                                                icb_rsp_hsked_m;
wire[P_DATA_WIDTH - 1 : 0]                          icb_rsp_rdata_m;
wire                                                icb_rsp_err_m;

genvar                                              i;
integer                                             j;


// 只要command通道有效，就需要请求总线使用权限
assign      icb_cmd_req_mn = icb_cmd_vld_mn & {P_ICB_COUNT{disp_buf_push_rdy}};

// 需要对多个master进行仲裁，以决定当前传输哪个master的数据
lnrv_gnrl_arbiter#
(
    .P_ARBT_NUM                     ( P_ICB_COUNT               ),
    .P_ARBT_TYPE                    ( "round-robin"             )
)
u_lnrv_gnrl_arbiter
(
    .clk                            ( clk                       ),
    .reset_n                        ( reset_n                   ),

    .request                        ( icb_cmd_req_mn            ),
    .grant                          ( icb_cmd_grant_mn          )
);


// 先分离各个master输入的控制信息
generate
    for(i = 0; i < P_ICB_COUNT; i = i + 1) begin
        assign      icb_cmd_vld_m_mux[i]    = icb_cmd_grant_mn[i] & icb_cmd_vld_mn[i];
        assign      icb_cmd_write_m_mux[i]  = icb_cmd_grant_mn[i] & icb_cmd_write_mn[i];
        assign      icb_cmd_addr_m_mux[i]   = {P_ADDR_WIDTH{icb_cmd_grant_mn[i]}} & icb_cmd_addr_mn[i * P_ADDR_WIDTH +: P_ADDR_WIDTH];
        assign      icb_cmd_wdata_m_mux[i]  = {P_DATA_WIDTH{icb_cmd_grant_mn[i]}} & icb_cmd_wdata_mn[i * P_DATA_WIDTH +: P_DATA_WIDTH];
        assign      icb_cmd_wstrb_m_mux[i]  = {(P_DATA_WIDTH/8){icb_cmd_grant_mn[i]}} & icb_cmd_wstrb_mn[i * (P_DATA_WIDTH/8) +: (P_DATA_WIDTH/8)];
        assign      icb_cmd_size_m_mux[i]   = {3{icb_cmd_grant_mn[i]}} & icb_cmd_size_mn[i * 3 +: 3];

        assign      icb_cmd_rdy_mn[i]       = icb_cmd_grant_mn[i] & icb_cmd_rdy_m;
    end
endgenerate

// 合并所有master command通道的输入
always@(*) begin
    icb_cmd_addr_m    = {P_ADDR_WIDTH{1'b0}};
    icb_cmd_wdata_m   = {P_DATA_WIDTH{1'b0}};
    icb_cmd_wstrb_m   = {(P_DATA_WIDTH/8){1'b0}};
    icb_cmd_size_m    = {3{1'b0}};

    for(j = 0; j < P_ICB_COUNT; j = j + 1) begin
        icb_cmd_addr_m    = icb_cmd_addr_m | icb_cmd_addr_m_mux[j];
        icb_cmd_wdata_m   = icb_cmd_wdata_m | icb_cmd_wdata_m_mux[j];
        icb_cmd_wstrb_m   = icb_cmd_wstrb_m | icb_cmd_wstrb_m_mux[j];
        icb_cmd_size_m    = icb_cmd_size_m | icb_cmd_size_m_mux[j];
    end
end

assign      icb_cmd_vld_m   = |icb_cmd_vld_m_mux;
assign      icb_cmd_write_m = |icb_cmd_write_m_mux;


assign      icb_cmd_hsked_m = icb_cmd_vld_m & icb_cmd_rdy_m;
assign      icb_rsp_hsked_m = icb_rsp_vld_m & icb_rsp_rdy_m;

// command成功握手就将分发信息压入fifo
assign      disp_buf_push_vld   = icb_cmd_hsked_m;
assign      disp_buf_push_data  = icb_cmd_grant_mn;

assign      disp_buf_pop_rdy    = icb_rsp_hsked_m;
assign      icb_rsp_grant       = {P_ICB_COUNT{disp_buf_pop_vld}} & disp_buf_pop_data;

// 将分发信息保存下来，用于rsp通道
lnrv_gnrl_buffer#
(
    .P_DATA_WIDTH                   ( LP_DISP_BUF_DATA_WIDTH    ),
    .P_DEEPTH                       ( P_CMD_OTS_COUNT           ),
    .P_CUT_READY                    ( 1'b0                      ),
    .P_BYPASS                       ( 1'b0                      )
)
u_icb_disp_buf
(
    .clk                            ( clk                       ),
    .reset_n                        ( reset_n                   ),

    .flush_req                      ( 1'b0                      ),
    .flush_ack                      (                           ),

    .push_vld                       ( disp_buf_push_vld         ),
    .push_rdy                       ( disp_buf_push_rdy         ),
    .push_data                      ( disp_buf_push_data        ),

    .pop_vld                        ( disp_buf_pop_vld          ),
    .pop_rdy                        ( disp_buf_pop_rdy          ),
    .pop_data                       ( disp_buf_pop_data         )
);


// 插入buff
lnrv_icb_buf#
(
    .P_ADDR_WIDTH                   ( P_ADDR_WIDTH              ),
    .P_DATA_WIDTH                   ( P_DATA_WIDTH              ),

    .P_CMD_BUFF_ENABLE              ( P_CMD_BUFF_ENABLE         ),
    .P_CMD_BUFF_CUT_READY           ( P_CMD_BUFF_CUT_READY      ),
    .P_CMD_BUFF_BYPASS              ( P_CMD_BUFF_BYPASS         ),
    .P_CMD_OTS_COUNT                ( P_CMD_OTS_COUNT           ),

    .P_RSP_BUFF_ENABLE              ( P_RSP_BUFF_ENABLE         ),
    .P_RSP_BUFF_CUT_READY           ( P_RSP_BUFF_CUT_READY      ),
    .P_RSP_BUFF_BYPASS              ( P_RSP_BUFF_BYPASS         ),
    .P_RSP_OTS_COUNT                ( P_RSP_OTS_COUNT           )
)
u_lnrv_icb_buf
(
    .icb_cmd_vld_m                  ( icb_cmd_vld_m             ),
    .icb_cmd_rdy_m                  ( icb_cmd_rdy_m             ),
    .icb_cmd_write_m                ( icb_cmd_write_m           ),
    .icb_cmd_addr_m                 ( icb_cmd_addr_m            ),
    .icb_cmd_wdata_m                ( icb_cmd_wdata_m           ),
    .icb_cmd_wstrb_m                ( icb_cmd_wstrb_m           ),
    .icb_cmd_size_m                 ( icb_cmd_size_m            ),
    .icb_rsp_vld_m                  ( icb_rsp_vld_m             ),
    .icb_rsp_rdy_m                  ( icb_rsp_rdy_m             ),
    .icb_rsp_rdata_m                ( icb_rsp_rdata_m           ),
    .icb_rsp_err_m                  ( icb_rsp_err_m             ),

    .icb_cmd_vld_s                  ( icb_cmd_vld_s             ),
    .icb_cmd_rdy_s                  ( icb_cmd_rdy_s             ),
    .icb_cmd_write_s                ( icb_cmd_write_s           ),
    .icb_cmd_addr_s                 ( icb_cmd_addr_s            ),
    .icb_cmd_wdata_s                ( icb_cmd_wdata_s           ),
    .icb_cmd_wstrb_s                ( icb_cmd_wstrb_s           ),
    .icb_cmd_size_s                 ( icb_cmd_size_s            ),
    .icb_rsp_vld_s                  ( icb_rsp_vld_s             ),
    .icb_rsp_rdy_s                  ( icb_rsp_rdy_s             ),
    .icb_rsp_rdata_s                ( icb_rsp_rdata_s           ),
    .icb_rsp_err_s                  ( icb_rsp_err_s             ),

    .clk                            ( clk                       ),
    .reset_n                        ( reset_n                   )
);

// 选出一个rsp_rdy
assign      icb_rsp_rdy_m = |(icb_rsp_grant & icb_rsp_rdy_mn);

// 生成resp
generate
    for(i = 0; i < P_ICB_COUNT; i = i + 1) begin
        assign      icb_rsp_vld_mn[i] = icb_rsp_grant[i] & icb_rsp_vld_m;
        assign      icb_rsp_err_mn[i] = icb_rsp_grant[i] & icb_rsp_err_m;
        assign      icb_rsp_rdata_mn[i * P_DATA_WIDTH +: P_DATA_WIDTH] = {P_DATA_WIDTH{icb_rsp_grant[i]}} & icb_rsp_rdata_m;
    end
endgenerate


endmodule