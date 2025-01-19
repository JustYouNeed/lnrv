module  lnrv_icb_mux#
(
    parameter                                       P_ADDR_WIDTH            = 32,
    parameter                                       P_DATA_WIDTH            = 32,
    parameter                                       P_SIZE_WIDTH            = 3,
    parameter                                       P_LEN_WIDTH             = 4,
    parameter                                       P_ICB_COUNT             = 4,

    parameter                                       P_CMD_CUT_VALID         = 1'b1,
    parameter                                       P_CMD_CUT_READY         = 1'b1,
    parameter                                       P_CMD_BUF_DEEPTH        = 1,

    parameter                                       P_RSP_CUT_VALID         = 1'b1,
    parameter                                       P_RSP_CUT_READY         = 1'b1,
    parameter                                       P_RSP_BUF_DEEPTH        = 1,

    parameter                                       P_OTS_COUNT             = 1
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
    input[(P_ICB_COUNT * P_SIZE_WIDTH) - 1 : 0]     icb_cmd_size_mn,
    input[(P_ICB_COUNT * 2) - 1 : 0]                icb_cmd_burst_mn,
    input[(P_ICB_COUNT * P_LEN_WIDTH) - 1 : 0]      icb_cmd_len_mn,
    input[(P_ICB_COUNT * 3) - 1 : 0]                icb_cmd_prot_mn,
    input[(P_ICB_COUNT * 4) - 1 : 0]                icb_cmd_cache_mn,

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
    output[P_SIZE_WIDTH - 1 : 0]                                   icb_cmd_size_s,
    output[1 : 0]                                   icb_cmd_burst_s,
    output[P_LEN_WIDTH - 1 : 0]                                   icb_cmd_len_s,
    output[2 : 0]                                   icb_cmd_prot_s,
    output[3 : 0]                                   icb_cmd_cache_s,

    input                                           icb_rsp_vld_s,
    output                                          icb_rsp_rdy_s,
    input[P_DATA_WIDTH - 1 : 0]                     icb_rsp_rdata_s,
    input                                           icb_rsp_err_s
);
localparam                                          LP_MUX_BUF_DATA_WIDTH  = P_ICB_COUNT;
localparam                                          LP_MUX_BUF_DEEPTH      = P_OTS_COUNT;

// 分发信息fifo
wire[LP_MUX_BUF_DATA_WIDTH - 1 : 0]                 mux_buf_push_data;
wire                                                mux_buf_push_vld;
wire                                                mux_buf_push_rdy;

wire[LP_MUX_BUF_DATA_WIDTH - 1 : 0]                 mux_buf_pop_data;
wire                                                mux_buf_pop_vld;
wire                                                mux_buf_pop_rdy;

wire[P_ICB_COUNT - 1 : 0]                           icb_cmd_req_mn;
wire[P_ICB_COUNT - 1 : 0]                           icb_cmd_grant_mn;
wire[P_ICB_COUNT - 1 : 0]                           icb_rsp_grant;

// 各个master的信息
wire[P_ICB_COUNT - 1 : 0]                           icb_cmd_vld_m_mux;
wire[P_ICB_COUNT - 1 : 0]                           icb_cmd_write_m_mux;
wire[P_ADDR_WIDTH - 1 : 0]                          icb_cmd_addr_m_mux[P_ICB_COUNT - 1 : 0];
wire[P_DATA_WIDTH - 1 : 0]                          icb_cmd_wdata_m_mux[P_ICB_COUNT - 1 : 0];
wire[(P_DATA_WIDTH/8) - 1 : 0]                      icb_cmd_wstrb_m_mux[P_ICB_COUNT - 1 : 0];
wire[P_SIZE_WIDTH - 1 : 0]                          icb_cmd_size_m_mux[P_ICB_COUNT - 1 : 0];
wire[1 : 0]                                         icb_cmd_burst_m_mux[P_ICB_COUNT - 1 : 0];
wire[P_LEN_WIDTH - 1 : 0]                           icb_cmd_len_m_mux[P_ICB_COUNT - 1 : 0];
wire[2 : 0]                                         icb_cmd_prot_m_mux[P_ICB_COUNT - 1 : 0];
wire[3 : 0]                                         icb_cmd_cache_m_mux[P_ICB_COUNT - 1 : 0];

wire                                                icb_cmd_vld_m;
wire                                                icb_cmd_rdy_m;
wire                                                icb_cmd_write_m;
reg[P_ADDR_WIDTH - 1 : 0]                           icb_cmd_addr_m;
reg[P_DATA_WIDTH - 1 : 0]                           icb_cmd_wdata_m;
reg[(P_DATA_WIDTH/8) - 1 : 0]                       icb_cmd_wstrb_m;
reg[P_SIZE_WIDTH - 1 : 0]                           icb_cmd_size_m;
reg[1 : 0]                                          icb_cmd_burst_m;
reg[P_LEN_WIDTH - 1 : 0]                            icb_cmd_len_m;
reg[2 : 0]                                          icb_cmd_prot_m;
reg[3 : 0]                                          icb_cmd_cache_m;
wire                                                icb_cmd_hsked_m;

wire                                                icb_rsp_vld_m;
wire                                                icb_rsp_rdy_m;
wire                                                icb_rsp_hsked_m;
wire[P_DATA_WIDTH - 1 : 0]                          icb_rsp_rdata_m;
wire                                                icb_rsp_err_m;

genvar                                              i;
integer                                             j;


// 只要command通道有效，就需要请求总线使用权限
assign      icb_cmd_req_mn = icb_cmd_vld_mn & {P_ICB_COUNT{mux_buf_push_rdy}};

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
        assign      icb_cmd_size_m_mux[i]   = {3{icb_cmd_grant_mn[i]}} & icb_cmd_size_mn[i * P_SIZE_WIDTH +: P_SIZE_WIDTH];
        assign      icb_cmd_burst_m_mux[i]  = {2{icb_cmd_grant_mn[i]}} & icb_cmd_burst_mn[i * 2 +: 2];
        assign      icb_cmd_len_m_mux[i]    = {4{icb_cmd_grant_mn[i]}} & icb_cmd_len_mn[i * P_LEN_WIDTH +: P_LEN_WIDTH];
        assign      icb_cmd_prot_m_mux[i]   = {3{icb_cmd_grant_mn[i]}} & icb_cmd_prot_mn[i * 3 +: 3];
        assign      icb_cmd_cache_m_mux[i]  = {4{icb_cmd_grant_mn[i]}} & icb_cmd_cache_mn[i * 4 +: 4];

        assign      icb_cmd_rdy_mn[i]       = icb_cmd_grant_mn[i] & icb_cmd_rdy_m & mux_buf_push_rdy;
    end
endgenerate

// 合并所有master command通道的输入
always@(*) begin
    icb_cmd_addr_m      = {P_ADDR_WIDTH{1'b0}};
    icb_cmd_wdata_m     = {P_DATA_WIDTH{1'b0}};
    icb_cmd_wstrb_m     = {(P_DATA_WIDTH/8){1'b0}};
    icb_cmd_size_m      = {P_SIZE_WIDTH{1'b0}};
    icb_cmd_burst_m     = 2'b00;
    icb_cmd_len_m       = {P_LEN_WIDTH{1'b0}};
    icb_cmd_prot_m      = 3'b000;
    icb_cmd_cache_m     = 4'b0000;

    for(j = 0; j < P_ICB_COUNT; j = j + 1) begin
        icb_cmd_addr_m      = icb_cmd_addr_m | icb_cmd_addr_m_mux[j];
        icb_cmd_wdata_m     = icb_cmd_wdata_m | icb_cmd_wdata_m_mux[j];
        icb_cmd_wstrb_m     = icb_cmd_wstrb_m | icb_cmd_wstrb_m_mux[j];
        icb_cmd_size_m      = icb_cmd_size_m | icb_cmd_size_m_mux[j];
        icb_cmd_burst_m     = icb_cmd_burst_m | icb_cmd_burst_m_mux[j];
        icb_cmd_len_m       = icb_cmd_len_m | icb_cmd_len_m_mux[j];
        icb_cmd_prot_m      = icb_cmd_prot_m | icb_cmd_prot_m_mux[j];
        icb_cmd_cache_m     = icb_cmd_cache_m | icb_cmd_cache_m_mux[j];
    end
end

// 需要在mux buffer就绪的时候才可以往下游发送命令
assign      icb_cmd_vld_m       = (|icb_cmd_vld_m_mux) & mux_buf_push_rdy;
assign      icb_cmd_write_m     = |icb_cmd_write_m_mux;

assign      icb_cmd_hsked_m     = icb_cmd_vld_m & icb_cmd_rdy_m;
assign      icb_rsp_hsked_m     = icb_rsp_vld_m & icb_rsp_rdy_m;

// command成功握手就将分发信息压入fifo
assign      mux_buf_push_vld    = icb_cmd_hsked_m;
assign      mux_buf_push_data   = icb_cmd_grant_mn;

assign      mux_buf_pop_rdy     = icb_rsp_hsked_m;
assign      icb_rsp_grant       = mux_buf_pop_data;

// 将分发信息保存下来，用于rsp通道
lnrv_gnrl_buf#
(
    .P_DATA_WIDTH           ( LP_MUX_BUF_DATA_WIDTH     ),
    .P_DEEPTH               ( LP_MUX_BUF_DEEPTH         ),

    .P_CUT_VALID            ( 1'b0                      ),
    .P_CUT_READY            ( 1'b0                      ),
    .P_FLUSH_DELAY          ( 1'b0                      )
)
u_icb_mux_buf
(
    .clk                    ( clk                       ),
    .reset_n                ( reset_n                   ),

    .flush_req              ( 1'b0                      ),
    .flush_ack              (                           ),

    .push_vld               ( mux_buf_push_vld          ),
    .push_rdy               ( mux_buf_push_rdy          ),
    .push_data              ( mux_buf_push_data         ),

    .pop_vld                ( mux_buf_pop_vld           ),
    .pop_rdy                ( mux_buf_pop_rdy           ),
    .pop_data               ( mux_buf_pop_data          )
);


// 插入buff
lnrv_icb_slice#
(
    .P_ADDR_WIDTH           ( P_ADDR_WIDTH              ),
    .P_DATA_WIDTH           ( P_DATA_WIDTH              ),
    .P_SIZE_WIDTH           ( P_SIZE_WIDTH              ),
    .P_LEN_WIDTH            ( P_LEN_WIDTH               ),

    .P_CMD_CUT_VALID        ( P_CMD_CUT_VALID           ),
    .P_CMD_CUT_READY        ( P_CMD_CUT_READY           ),
    .P_CMD_BUF_DEEPTH       ( P_CMD_BUF_DEEPTH          ),

    .P_RSP_CUT_VALID        ( P_RSP_CUT_VALID           ),
    .P_RSP_CUT_READY        ( P_RSP_CUT_READY           ),
    .P_RSP_BUF_DEEPTH       ( P_RSP_BUF_DEEPTH          ),

    // 不使用icb buf带的ots控制功能
    .P_OTS_COUNT            ( 1                         ),
    .P_OTS_CTRL_ENABLE      ( 1'b0                      ),
    .P_FLUSH_ENABLE         ( 1'b0                      )
)
u_lnrv_icb_buf
(
    .flush_req              ( 1'b0                      ),
    .flush_ack              (                           ),

    .icb_cmd_vld_m          ( icb_cmd_vld_m             ),
    .icb_cmd_rdy_m          ( icb_cmd_rdy_m             ),
    .icb_cmd_write_m        ( icb_cmd_write_m           ),
    .icb_cmd_addr_m         ( icb_cmd_addr_m            ),
    .icb_cmd_wdata_m        ( icb_cmd_wdata_m           ),
    .icb_cmd_wstrb_m        ( icb_cmd_wstrb_m           ),
    .icb_cmd_size_m         ( icb_cmd_size_m            ),
    .icb_cmd_burst_m        ( icb_cmd_burst_m           ),
    .icb_cmd_len_m          ( icb_cmd_len_m             ),
    .icb_cmd_prot_m         ( icb_cmd_prot_m            ),
    .icb_cmd_cache_m        ( icb_cmd_cache_m           ),
    .icb_rsp_vld_m          ( icb_rsp_vld_m             ),
    .icb_rsp_rdy_m          ( icb_rsp_rdy_m             ),
    .icb_rsp_rdata_m        ( icb_rsp_rdata_m           ),
    .icb_rsp_err_m          ( icb_rsp_err_m             ),

    .icb_cmd_vld_s          ( icb_cmd_vld_s             ),
    .icb_cmd_rdy_s          ( icb_cmd_rdy_s             ),
    .icb_cmd_write_s        ( icb_cmd_write_s           ),
    .icb_cmd_addr_s         ( icb_cmd_addr_s            ),
    .icb_cmd_wdata_s        ( icb_cmd_wdata_s           ),
    .icb_cmd_wstrb_s        ( icb_cmd_wstrb_s           ),
    .icb_cmd_size_s         ( icb_cmd_size_s            ),
    .icb_cmd_burst_s        ( icb_cmd_burst_s           ),
    .icb_cmd_len_s          ( icb_cmd_len_s             ),
    .icb_cmd_prot_s         ( icb_cmd_prot_s            ),
    .icb_cmd_cache_s        ( icb_cmd_cache_s           ),
    .icb_rsp_vld_s          ( icb_rsp_vld_s             ),
    .icb_rsp_rdy_s          ( icb_rsp_rdy_s             ),
    .icb_rsp_rdata_s        ( icb_rsp_rdata_s           ),
    .icb_rsp_err_s          ( icb_rsp_err_s             ),

    .clk                    ( clk                       ),
    .reset_n                ( reset_n                   )
);

// 选出一个rsp_rdy
assign      icb_rsp_rdy_m = |(icb_rsp_grant & icb_rsp_rdy_mn);

// 生成resp
generate
    for(i = 0; i < P_ICB_COUNT; i = i + 1) begin
        assign      icb_rsp_vld_mn[i] = icb_rsp_grant[i] & icb_rsp_vld_m;
        assign      icb_rsp_err_mn[i] = icb_rsp_grant[i] & icb_rsp_err_m;
        assign      icb_rsp_rdata_mn[i * P_DATA_WIDTH +: P_DATA_WIDTH] = icb_rsp_rdata_m;
    end
endgenerate


endmodule