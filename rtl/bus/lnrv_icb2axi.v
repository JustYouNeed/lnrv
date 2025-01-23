module lnrv_icb2axi#
(
    parameter                           P_ADDR_WIDTH            = 32,
    parameter                           P_DATA_WIDTH            = 32,

    parameter                           P_OTS_COUNT             = 16,

    // ICB总线buf配置
    parameter                           P_ICB_CMD_BUF_DEEPTH    = 1,
    parameter                           P_ICB_RSP_BUF_DEEPTH    = 1,

    parameter                           P_ICB_CMD_CUT_VALID     = 1'b1,
    parameter                           P_ICB_CMD_CUT_READY     = 1'b1,
    parameter                           P_ICB_RSP_CUT_VALID     = 1'b1,
    parameter                           P_ICB_RSP_CUT_READY     = 1'b1,

    parameter                           P_AXI_ID_WIDTH          = 8,

    // axi buf深度
    parameter                           P_AXI_AW_BUF_DEEPTH     = 1,
    parameter                           P_AXI_W_BUF_DEEPTH      = 1,
    parameter                           P_AXI_B_BUF_DEEPTH      = 1,
    parameter                           P_AXI_AR_BUF_DEEPTH     = 1,
    parameter                           P_AXI_R_BUF_DEEPTH      = 1,

    // axi 时序优化配置
    parameter                           P_AXI_AW_CUT_VALID      = 1'b1,
    parameter                           P_AXI_AW_CUT_READY      = 1'b1,
    parameter                           P_AXI_W_CUT_VALID       = 1'b1,
    parameter                           P_AXI_W_CUT_READY       = 1'b1,
    parameter                           P_AXI_B_CUT_VALID       = 1'b1,
    parameter                           P_AXI_B_CUT_READY       = 1'b1,
    parameter                           P_AXI_AR_CUT_VALID      = 1'b1,
    parameter                           P_AXI_AR_CUT_READY      = 1'b1,
    parameter                           P_AXI_R_CUT_VALID       = 1'b1,
    parameter                           P_AXI_R_CUT_READY       = 1'b1
)
(
    // ICB
    input                               icb_cmd_vld,
    output                              icb_cmd_rdy,
    input                               icb_cmd_write,
    input[P_ADDR_WIDTH - 1 : 0]         icb_cmd_addr,
    input[P_DATA_WIDTH - 1 : 0]         icb_cmd_wdata,
    input[(P_DATA_WIDTH/8) - 1 : 0]     icb_cmd_wstrb,
    input[2 : 0]                        icb_cmd_size,
    input[2 : 0]                        icb_cmd_prot,
    input[3 : 0]                        icb_cmd_len,
    input[1 : 0]                        icb_cmd_burst,
    input[3 : 0]                        icb_cmd_cache,
    input                               icb_rsp_rdy,
    output                              icb_rsp_vld,
    output                              icb_rsp_err,
    output[P_DATA_WIDTH - 1 : 0]        icb_rsp_rdata,

    // AXI4
    output                              axi4_awvalid,
    input                               axi4_awready,
    output[P_ADDR_WIDTH - 1 : 0]        axi4_awaddr,
    output[P_AXI_ID_WIDTH - 1 : 0]      axi4_awid,
    output[7 : 0]                       axi4_awlen,
    output[2 : 0]                       axi4_awsize,
    output[1 : 0]                       axi4_awburst,
    output[3 : 0]                       axi4_awcache,
    output[2 : 0]                       axi4_awprot,

    output                              axi4_wvalid,
    input                               axi4_wready,
    output[P_DATA_WIDTH - 1 : 0]        axi4_wdata,
    output[(P_DATA_WIDTH/8) - 1 : 0]    axi4_wstrb,
    output                              axi4_wlast,

    output                              axi4_bready,
    input                               axi4_bvalid,
    input[1 : 0]                        axi4_bresp,
    input[P_AXI_ID_WIDTH - 1 : 0]       axi4_bid,

    output                              axi4_arvalid,
    input                               axi4_arready,
    output                              axi4_arlock,
    output[P_ADDR_WIDTH - 1 : 0]        axi4_araddr,
    output[P_AXI_ID_WIDTH - 1 : 0]      axi4_arid,
    output[7 : 0]                       axi4_arlen,
    output[2 : 0]                       axi4_arsize,
    output[1 : 0]                       axi4_arburst,
    output[3 : 0]                       axi4_arcache,
    output[2 : 0]                       axi4_arprot,

    output                              axi4_rready,
    input                               axi4_rvalid,
    input[P_DATA_WIDTH - 1 : 0]         axi4_rdata,
    input[1 : 0]                        axi4_rresp,
    input                               axi4_rlast,
    input[P_AXI_ID_WIDTH - 1 : 0]       axi4_rid,

    input                               clk,
    input                               reset_n
);

localparam                              LP_BURST_BUF_WIDTH = 5;

wire                                    icb_cmd_vld_bufed;
wire                                    icb_cmd_rdy_bufed;
wire                                    icb_cmd_write_bufed;
wire[P_ADDR_WIDTH - 1 : 0]              icb_cmd_addr_bufed;
wire[P_DATA_WIDTH - 1 : 0]              icb_cmd_wdata_bufed;
wire[(P_DATA_WIDTH/8) - 1 : 0]          icb_cmd_wstrb_bufed;
wire[2: 0]                              icb_cmd_size_bufed;
wire[1: 0]                              icb_cmd_burst_bufed;
wire[3: 0]                              icb_cmd_len_bufed;
wire[2: 0]                              icb_cmd_prot_bufed;
wire[3: 0]                              icb_cmd_cache_bufed;
wire                                    icb_rsp_vld_bufed;
wire                                    icb_rsp_rdy_bufed;
wire[P_DATA_WIDTH - 1 : 0]              icb_rsp_rdata_bufed;
wire                                    icb_rsp_err_bufed;

reg                                     aw_hsked_q;
wire                                    aw_hsked_set;
wire                                    aw_hsked_clr;
wire                                    aw_hsked_rld;
wire                                    aw_hsked_d;

reg                                     ar_hsked_q;
wire                                    ar_hsked_set;
wire                                    ar_hsked_clr;
wire                                    ar_hsked_rld;
wire                                    ar_hsked_d;

reg[3 : 0]                              burst_beat_cnt_q;
wire                                    burst_beat_cnt_rld;
wire[3 : 0]                             burst_beat_cnt_d;
wire                                    last_burst_beat;

wire[LP_BURST_BUF_WIDTH - 1 : 0]        burst_buf_push_data;
wire                                    burst_buf_push_vld;
wire                                    burst_buf_push_rdy;
wire[LP_BURST_BUF_WIDTH - 1 : 0]        burst_buf_pop_data;
wire                                    burst_buf_pop_vld;
wire                                    burst_buf_pop_rdy;

wire                                    burst_write;
wire                                    burst_read;
wire[3 : 0]                             burst_len;

wire                                    icb_write_transfer;
wire                                    icb_read_transfer;

wire                                    axi_write_busy;
wire                                    axi_write_idle;
wire                                    axi_read_idle;

wire                                    awvalid_m;
wire                                    awready_m;
wire[P_ADDR_WIDTH - 1 : 0]              awaddr_m;
wire[7 : 0]                             awlen_m;
wire[2 : 0]                             awsize_m;
wire[1 : 0]                             awburst_m;
wire[3 : 0]                             awcache_m;
wire[2 : 0]                             awprot_m;
wire[P_AXI_ID_WIDTH - 1 : 0]            awid_m;

wire                                    wvalid_m;
wire                                    wready_m;
wire[P_DATA_WIDTH - 1 : 0]              wdata_m;
wire[(P_DATA_WIDTH/8) - 1 : 0]          wstrb_m;
wire[P_AXI_ID_WIDTH - 1 : 0]            wid_m;
wire                                    wlast_m;

wire                                    bvalid_m;
wire                                    bready_m;
wire[1 : 0]                             bresp_m;
wire[P_AXI_ID_WIDTH - 1 : 0]            bid_m;

wire                                    arvalid_m;
wire                                    arready_m;
wire[P_ADDR_WIDTH - 1 : 0]              araddr_m;
wire[7 : 0]                             arlen_m;
wire[2 : 0]                             arsize_m;
wire[1 : 0]                             arburst_m;
wire[3 : 0]                             arcache_m;
wire[2 : 0]                             arprot_m;
wire[P_AXI_ID_WIDTH - 1 : 0]            arid_m;

wire                                    rvalid_m;
wire                                    rready_m;
wire[P_DATA_WIDTH - 1 : 0]              rdata_m;
wire[P_AXI_ID_WIDTH - 1 : 0]            rid_m;
wire[1 : 0]                             rresp_m;
wire                                    rlast_m;

wire                                    axi_ar_hsked;
wire                                    axi_aw_hsked;
wire                                    axi_b_hsked;
wire                                    axi_r_hsked;
wire                                    axi_w_hsked;

wire                                    icb_rsp_rdy_true;


assign      axi_aw_hsked    = axi4_awvalid & axi4_awready;
assign      axi_ar_hsked    = axi4_arvalid & axi4_arready;
assign      axi_w_hsked     = axi4_wvalid & axi4_wready;
assign      axi_b_hsked     = axi4_bvalid & axi4_bready;
assign      axi_r_hsked     = axi4_rvalid & axi4_rready;

// 先在icb路径上插入一个buff
lnrv_icb_slice#
(
    .P_ADDR_WIDTH               ( P_DATA_WIDTH                  ),
    .P_DATA_WIDTH               ( P_ADDR_WIDTH                  ),

    .P_CMD_CUT_VALID            ( P_ICB_CMD_CUT_VALID           ),
    .P_CMD_CUT_READY            ( P_ICB_CMD_CUT_READY           ),
    .P_CMD_BUF_DEEPTH           ( P_ICB_CMD_BUF_DEEPTH          ),

    .P_RSP_CUT_VALID            ( P_ICB_RSP_CUT_VALID           ),
    .P_RSP_CUT_READY            ( P_ICB_RSP_CUT_READY           ),
    .P_RSP_BUF_DEEPTH           ( P_ICB_RSP_BUF_DEEPTH          ),

    .P_OTS_COUNT                ( 1                             ),
    .P_OTS_CTRL_ENABLE          ( 1'b0                          ),
    .P_FLUSH_ENABLE             ( 1'b0                          )
)
u_lnrv_icb_slice
(
    .flush_req                  ( 1'b0                          ),
    .flush_ack                  (                               ),

    .icb_cmd_vld_m              ( icb_cmd_vld                   ),
    .icb_cmd_rdy_m              ( icb_cmd_rdy                   ),
    .icb_cmd_write_m            ( icb_cmd_write                 ),
    .icb_cmd_addr_m             ( icb_cmd_addr                  ),
    .icb_cmd_wdata_m            ( icb_cmd_wdata                 ),
    .icb_cmd_wstrb_m            ( icb_cmd_wstrb                 ),
    .icb_cmd_size_m             ( icb_cmd_size                  ),
    .icb_cmd_burst_m            ( icb_cmd_burst                 ),
    .icb_cmd_len_m              ( icb_cmd_len                   ),
    .icb_cmd_prot_m             ( icb_cmd_prot                  ),
    .icb_cmd_cache_m            ( icb_cmd_cache                 ),
    .icb_rsp_vld_m              ( icb_rsp_vld                   ),
    .icb_rsp_rdy_m              ( icb_rsp_rdy                   ),
    .icb_rsp_rdata_m            ( icb_rsp_rdata                 ),
    .icb_rsp_err_m              ( icb_rsp_err                   ),

    .icb_cmd_vld_s              ( icb_cmd_vld_bufed             ),
    .icb_cmd_rdy_s              ( icb_cmd_rdy_bufed             ),
    .icb_cmd_write_s            ( icb_cmd_write_bufed           ),
    .icb_cmd_addr_s             ( icb_cmd_addr_bufed            ),
    .icb_cmd_wdata_s            ( icb_cmd_wdata_bufed           ),
    .icb_cmd_wstrb_s            ( icb_cmd_wstrb_bufed           ),
    .icb_cmd_size_s             ( icb_cmd_size_bufed            ),
    .icb_cmd_burst_s            ( icb_cmd_burst_bufed           ),
    .icb_cmd_len_s              ( icb_cmd_len_bufed             ),
    .icb_cmd_prot_s             ( icb_cmd_prot_bufed            ),
    .icb_cmd_cache_s            ( icb_cmd_cache_bufed           ),
    .icb_rsp_vld_s              ( icb_rsp_vld_bufed             ),
    .icb_rsp_rdy_s              ( icb_rsp_rdy_bufed             ),
    .icb_rsp_rdata_s            ( icb_rsp_rdata_bufed           ),
    .icb_rsp_err_s              ( icb_rsp_err_bufed             ),

    .clk                        ( clk                           ),
    .reset_n                    ( reset_n                       )
);

assign      icb_write_transfer  = icb_cmd_vld_bufed & icb_cmd_write_bufed;
assign      icb_read_transfer   = icb_cmd_vld_bufed & (~icb_cmd_write_bufed);
assign      icb_rsp_rdy_true    = icb_rsp_rdy_bufed & burst_buf_pop_vld;

// 将burst传输信息保存到buf中
assign      burst_buf_push_vld =    axi_aw_hsked |
                                    axi_ar_hsked;
assign      burst_buf_push_data =   {
                                        icb_cmd_write_bufed,
                                        icb_cmd_len_bufed
                                    };
assign      {
                burst_write,
                burst_len
            } = burst_buf_pop_data;
assign      burst_buf_pop_rdy = burst_beat_cnt_rld &
                                (
                                    burst_write ? axi_b_hsked : last_burst_beat
                                );
// burst buffer
lnrv_gnrl_buf#
(
    .P_DATA_WIDTH               ( LP_BURST_BUF_WIDTH            ),
    .P_DEEPTH                   ( P_OTS_COUNT                   ),

    .P_CUT_VALID                ( 1'b1                          ),
    .P_CUT_READY                ( 1'b1                          ),
    .P_FLUSH_DELAY              ( 1'b1                          )
)
u_trans_burst_buf
(
    .clk                        ( clk                           ),
    .reset_n                    ( reset_n                       ),

    .flush_req                  ( 1'b0                          ),
    .flush_ack                  (                               ),

    .push_vld                   ( burst_buf_push_vld            ),
    .push_rdy                   ( burst_buf_push_rdy            ),
    .push_data                  ( burst_buf_push_data           ),
    .pop_vld                    ( burst_buf_pop_vld             ),
    .pop_rdy                    ( burst_buf_pop_rdy             ),
    .pop_data                   ( burst_buf_pop_data            )
);

assign      burst_read = (~burst_write);

// 统计burst传输的拍数
assign      burst_beat_cnt_rld   = burst_write ? axi_b_hsked : axi_r_hsked;
assign      burst_beat_cnt_d     = last_burst_beat ? 4'd0 : (burst_beat_cnt_q + 1'b1);
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        burst_beat_cnt_q <= 4'd0;
    end else if(burst_beat_cnt_rld) begin
        burst_beat_cnt_q <= burst_beat_cnt_d;
    end
end

//
assign      last_burst_beat = (burst_len == burst_beat_cnt_q) | icb_cmd_write_bufed;

// 保存aw通道的握手信息
assign      aw_hsked_set = axi_aw_hsked;
assign      aw_hsked_clr = axi_w_hsked & last_burst_beat;
assign      aw_hsked_rld = aw_hsked_set | aw_hsked_clr;
assign      aw_hsked_d = aw_hsked_set;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        aw_hsked_q <= 1'b0;
    end else if(aw_hsked_rld) begin
        aw_hsked_q <= aw_hsked_d;
    end
end

assign      axi_write_idle = (~aw_hsked_q) | aw_hsked_clr;
assign      axi_write_busy = aw_hsked_q;

// 我们必须先发送地址信息，才会发送数据
assign      awvalid_m   = icb_write_transfer & axi_write_idle & burst_buf_push_rdy;
assign      awaddr_m    = icb_cmd_addr_bufed;
assign      awprot_m    = icb_cmd_prot_bufed;
assign      awlen_m     = {4'd0, icb_cmd_len_bufed};
assign      awcache_m   = icb_cmd_cache_bufed;
assign      awid_m      = {P_AXI_ID_WIDTH{1'b0}};
assign      awsize_m    = icb_cmd_size_bufed;
assign      awburst_m   = icb_cmd_burst_bufed;

assign      wvalid_m    = icb_write_transfer & axi_write_busy;
assign      wdata_m     = icb_cmd_wdata_bufed;
assign      wstrb_m     = icb_cmd_wstrb_bufed;
assign      wid_m       = {P_AXI_ID_WIDTH{1'b0}};
assign      wlast_m     = last_burst_beat;

assign      bready_m    = burst_write & icb_rsp_rdy_true;

// 读操作
assign      ar_hsked_set = axi_ar_hsked;
assign      ar_hsked_clr = axi_r_hsked & last_burst_beat;
assign      ar_hsked_rld = ar_hsked_set | ar_hsked_clr;
assign      ar_hsked_d = ar_hsked_set;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        ar_hsked_q <= 1'b0;
    end else if(ar_hsked_rld) begin
        ar_hsked_q <= ar_hsked_d;
    end
end

assign      axi_read_idle   = ar_hsked_clr | (~ar_hsked_q);

// 我们必须先发送地址信息，才会发送数据
assign      arvalid_m       = icb_read_transfer & axi_read_idle & burst_buf_push_rdy;
assign      araddr_m        = icb_cmd_addr_bufed;
assign      arprot_m        = icb_cmd_prot_bufed;
assign      arlen_m         = {4'd0, icb_cmd_len_bufed};
assign      arcache_m       = icb_cmd_cache_bufed;
assign      arid_m          = {P_AXI_ID_WIDTH{1'b0}};
assign      arsize_m        = icb_cmd_size_bufed;
assign      arburst_m       = icb_cmd_burst_bufed;

assign      rready_m        = burst_read & icb_rsp_rdy_true;

// 根据当前操作来选择resp
assign      icb_rsp_vld_bufed     = burst_write ? bvalid_m : rvalid_m;
assign      icb_rsp_rdata_bufed   = burst_write ? {P_ADDR_WIDTH{1'b0}} : rdata_m;
assign      icb_rsp_err_bufed     = burst_write ? bresp_m[0] : rresp_m[0];

// assign      icb_cmd_rdy_bufed     =

// axi slice
lnrv_axi_slice #
(
    .P_DATA_WIDTH       ( P_DATA_WIDTH                  ),
    .P_ADDR_WIDTH       ( P_ADDR_WIDTH                  ),
    .P_ID_WIDTH         ( P_AXI_ID_WIDTH                ),
    .P_AXLEN_WIDTH      ( 8                             ),
    .P_AW_USER_WIDTH    ( 1                             ),
    .P_W_USER_WIDTH     ( 1                             ),
    .P_B_USER_WIDTH     ( 1                             ),
    .P_AR_USER_WIDTH    ( 1                             ),
    .P_R_USER_WIDTH     ( 1                             ),

    .P_AW_BUF_DEEPTH    ( P_AXI_AW_BUF_DEEPTH           ),
    .P_W_BUF_DEEPTH     ( P_AXI_W_BUF_DEEPTH            ),
    .P_B_BUF_DEEPTH     ( P_AXI_B_BUF_DEEPTH            ),
    .P_AR_BUF_DEEPTH    ( P_AXI_AR_BUF_DEEPTH           ),
    .P_R_BUF_DEEPTH     ( P_AXI_R_BUF_DEEPTH            ),

    .P_AW_CUT_VALID     ( P_AXI_AW_CUT_VALID            ),
    .P_AW_CUT_READY     ( P_AXI_AW_CUT_READY            ),
    .P_W_CUT_VALID      ( P_AXI_W_CUT_VALID             ),
    .P_W_CUT_READY      ( P_AXI_W_CUT_READY             ),
    .P_B_CUT_VALID      ( P_AXI_B_CUT_VALID             ),
    .P_B_CUT_READY      ( P_AXI_B_CUT_READY             ),
    .P_AR_CUT_VALID     ( P_AXI_AR_CUT_VALID            ),
    .P_AR_CUT_READY     ( P_AXI_AR_CUT_READY            ),
    .P_R_CUT_VALID      ( P_AXI_R_CUT_VALID             ),
    .P_R_CUT_READY      ( P_AXI_R_CUT_READY             )
)
u_lnrv_axi_slice
(
    .aclk               ( clk                           ),
    .areset_n           ( reset_n                       ),

    .awvalid_m          ( awvalid_m                     ),
    .awready_m          ( awready_m                     ),
    .awaddr_m           ( awaddr_m                      ),
    .awlen_m            ( awlen_m                       ),
    .awsize_m           ( awsize_m                      ),
    .awburst_m          ( awburst_m                     ),
    .awcache_m          ( awcache_m                     ),
    .awprot_m           ( awprot_m                      ),
    .awqos_m            ( 4'd0                          ),
    .awregion_m         ( 4'd0                          ),
    .awuser_m           ( 1'b0                          ),
    .awid_m             ( awid_m                        ),

    .wvalid_m           ( wvalid_m                      ),
    .wready_m           ( wready_m                      ),
    .wdata_m            ( wdata_m                       ),
    .wstrb_m            ( wstrb_m                       ),
    .wid_m              ( wid_m                         ),
    .wlast_m            ( wlast_m                       ),
    .wuser_m            ( 1'b0                          ),

    .bvalid_m           ( bvalid_m                      ),
    .bready_m           ( bready_m                      ),
    .bresp_m            ( bresp_m                       ),
    .buser_m            (                               ),
    .bid_m              ( bid_m                         ),

    .arvalid_m          ( arvalid_m                     ),
    .arready_m          ( arready_m                     ),
    .araddr_m           ( araddr_m                      ),
    .arlen_m            ( arlen_m                       ),
    .arsize_m           ( arsize_m                      ),
    .arburst_m          ( arburst_m                     ),
    .arcache_m          ( arcache_m                     ),
    .arprot_m           ( arprot_m                      ),
    .arqos_m            ( 4'd0                          ),
    .arregion_m         ( 4'd0                          ),
    .aruser_m           ( 1'b0                          ),
    .arid_m             ( arid_m                        ),

    .rvalid_m           ( rvalid_m                      ),
    .rready_m           ( rready_m                      ),
    .rdata_m            ( rdata_m                       ),
    .rid_m              ( rid_m                         ),
    .rresp_m            ( rresp_m                       ),
    .rlast_m            ( rlast_m                       ),
    .ruser_m            (                               ),

    .awvalid_s          ( axi4_awvalid                  ),
    .awready_s          ( axi4_awready                  ),
    .awaddr_s           ( axi4_awaddr                   ),
    .awlen_s            ( axi4_awlen                    ),
    .awsize_s           ( axi4_awsize                   ),
    .awburst_s          ( axi4_awburst                  ),
    .awcache_s          ( axi4_awcache                  ),
    .awprot_s           ( axi4_awprot                   ),
    .awqos_s            (                               ),
    .awregion_s         (                               ),
    .awuser_s           (                               ),
    .awid_s             ( axi4_awid                     ),

    .wvalid_s           ( axi4_wvalid                   ),
    .wready_s           ( axi4_wready                   ),
    .wdata_s            ( axi4_wdata                    ),
    .wstrb_s            ( axi4_wstrb                    ),
    .wid_s              (                               ),
    .wlast_s            ( axi4_wlast                    ),
    .wuser_s            (                               ),

    .bvalid_s           ( axi4_bvalid                   ),
    .bready_s           ( axi4_bready                   ),
    .bresp_s            ( axi4_bresp                    ),
    .buser_s            ( 1'b0                          ),
    .bid_s              ( axi4_bid                      ),

    .arvalid_s          ( axi4_arvalid                  ),
    .arready_s          ( axi4_arready                  ),
    .araddr_s           ( axi4_araddr                   ),
    .arlen_s            ( axi4_arlen                    ),
    .arsize_s           ( axi4_arsize                   ),
    .arburst_s          ( axi4_arburst                  ),
    .arcache_s          ( axi4_arcache                  ),
    .arprot_s           ( axi4_arprot                   ),
    .arqos_s            (                               ),
    .arregion_s         (                               ),
    .aruser_s           (                               ),
    .arid_s             ( axi4_arid                     ),

    .rvalid_s           ( axi4_rvalid                   ),
    .rready_s           ( axi4_rready                   ),
    .rdata_s            ( axi4_rdata                    ),
    .rid_s              ( axi4_rid                      ),
    .rresp_s            ( axi4_rresp                    ),
    .rlast_s            ( axi4_rlast                    ),
    .ruser_s            ( 1'b0                          )
);

endmodule