module lnrv_axi_slice#
(
    // axi参数
    parameter                           P_DATA_WIDTH        = 32,
    parameter                           P_ADDR_WIDTH        = 32,
    parameter                           P_ID_WIDTH          = 4,
    parameter                           P_AXLEN_WIDTH       = 8,
    parameter                           P_AW_USER_WIDTH     = 1,
    parameter                           P_W_USER_WIDTH      = 1,
    parameter                           P_B_USER_WIDTH      = 1,
    parameter                           P_AR_USER_WIDTH     = 1,
    parameter                           P_R_USER_WIDTH      = 1,

    // buf深度
    parameter                           P_AW_BUF_DEEPTH     = 1,
    parameter                           P_W_BUF_DEEPTH      = 1,
    parameter                           P_B_BUF_DEEPTH      = 1,
    parameter                           P_AR_BUF_DEEPTH     = 1,
    parameter                           P_R_BUF_DEEPTH      = 1,

    // 时序优化配置
    parameter                           P_AW_CUT_VALID      = 1'b1,
    parameter                           P_AW_CUT_READY      = 1'b1,
    parameter                           P_W_CUT_VALID       = 1'b1,
    parameter                           P_W_CUT_READY       = 1'b1,
    parameter                           P_B_CUT_VALID       = 1'b1,
    parameter                           P_B_CUT_READY       = 1'b1,
    parameter                           P_AR_CUT_VALID      = 1'b1,
    parameter                           P_AR_CUT_READY      = 1'b1,
    parameter                           P_R_CUT_VALID       = 1'b1,
    parameter                           P_R_CUT_READY       = 1'b1
)
(
    input                               aclk,
    input                               areset_n,

    // master
    input                               awvalid_m,
    output                              awready_m,
    input[P_ADDR_WIDTH - 1 : 0]         awaddr_m,
    input[P_AXLEN_WIDTH - 1 : 0]        awlen_m,
    input[2 : 0]                        awsize_m,
    input[1 : 0]                        awburst_m,
    input[3 : 0]                        awcache_m,
    input[2 : 0]                        awprot_m,
    input[3 : 0]                        awqos_m,
    input[3 : 0]                        awregion_m,
    input[P_AW_USER_WIDTH - 1 : 0]      awuser_m,
    input[P_ID_WIDTH - 1 : 0]           awid_m,

    input                               wvalid_m,
    output                              wready_m,
    input[P_DATA_WIDTH - 1 : 0]         wdata_m,
    input[(P_DATA_WIDTH/8) - 1 : 0]     wstrb_m,
    input[P_ID_WIDTH - 1 : 0]           wid_m,
    input                               wlast_m,
    input[P_W_USER_WIDTH - 1 : 0]       wuser_m,

    output                              bvalid_m,
    input                               bready_m,
    output[1 : 0]                       bresp_m,
    output[P_B_USER_WIDTH - 1 : 0]      buser_m,
    output[P_ID_WIDTH - 1 : 0]          bid_m,

    input                               arvalid_m,
    output                              arready_m,
    input[P_ADDR_WIDTH - 1 : 0]         araddr_m,
    input[P_AXLEN_WIDTH - 1 : 0]        arlen_m,
    input[2 : 0]                        arsize_m,
    input[1 : 0]                        arburst_m,
    input[3 : 0]                        arcache_m,
    input[2 : 0]                        arprot_m,
    input[3 : 0]                        arqos_m,
    input[3 : 0]                        arregion_m,
    input[P_AR_USER_WIDTH - 1 : 0]      aruser_m,
    input[P_ID_WIDTH - 1 : 0]           arid_m,

    output                              rvalid_m,
    input                               rready_m,
    output[P_DATA_WIDTH - 1 : 0]        rdata_m,
    output[P_ID_WIDTH - 1 : 0]          rid_m,
    output[1 : 0]                       rresp_m,
    output                              rlast_m,
    output[P_R_USER_WIDTH - 1 : 0]      ruser_m,

    // slave
    output                              awvalid_s,
    input                               awready_s,
    output[P_ADDR_WIDTH - 1 : 0]        awaddr_s,
    output[P_AXLEN_WIDTH - 1 : 0]       awlen_s,
    output[2 : 0]                       awsize_s,
    output[1 : 0]                       awburst_s,
    output[3 : 0]                       awcache_s,
    output[2 : 0]                       awprot_s,
    output[3 : 0]                       awqos_s,
    output[3 : 0]                       awregion_s,
    output[P_AW_USER_WIDTH - 1 : 0]     awuser_s,
    output[P_ID_WIDTH - 1 : 0]          awid_s,

    output                              wvalid_s,
    input                               wready_s,
    output[P_DATA_WIDTH - 1 : 0]        wdata_s,
    output[(P_DATA_WIDTH/8) - 1 : 0]    wstrb_s,
    output[P_ID_WIDTH - 1 : 0]          wid_s,
    output                              wlast_s,
    output[P_W_USER_WIDTH - 1 : 0]      wuser_s,

    input                               bvalid_s,
    output                              bready_s,
    input[1 : 0]                        bresp_s,
    input[P_B_USER_WIDTH - 1 : 0]       buser_s,
    input[P_ID_WIDTH - 1 : 0]           bid_s,

    output                              arvalid_s,
    input                               arready_s,
    output[P_ADDR_WIDTH - 1 : 0]        araddr_s,
    output[P_AXLEN_WIDTH - 1 : 0]       arlen_s,
    output[2 : 0]                       arsize_s,
    output[1 : 0]                       arburst_s,
    output[3 : 0]                       arcache_s,
    output[2 : 0]                       arprot_s,
    output[3 : 0]                       arqos_s,
    output[3 : 0]                       arregion_s,
    output[P_AR_USER_WIDTH - 1 : 0]     aruser_s,
    output[P_ID_WIDTH - 1 : 0]          arid_s,

    input                               rvalid_s,
    output                              rready_s,
    input[P_DATA_WIDTH - 1 : 0]         rdata_s,
    input[P_ID_WIDTH - 1 : 0]           rid_s,
    input[1 : 0]                        rresp_s,
    input                               rlast_s,
    input[P_R_USER_WIDTH - 1 : 0]       ruser_s
);


localparam                              LP_AXI_AW_BUF_DATA_WIDTH    = P_ADDR_WIDTH + P_AXLEN_WIDTH + 17;
localparam                              LP_AXI_W_BUF_DATA_WIDTH     = P_DATA_WIDTH + (P_DATA_WIDTH/8) + 1;
localparam                              LP_AXI_B_BUF_DATA_WIDTH     = 6;
localparam                              LP_AXI_AR_BUF_DATA_WIDTH    = P_ADDR_WIDTH + P_AXLEN_WIDTH + 17;
localparam                              LP_AXI_R_BUF_DATA_WIDTH     = P_DATA_WIDTH + 7;


wire                                    aw_buf_push_vld;
wire                                    aw_buf_push_rdy;
wire[LP_AXI_AW_BUF_DATA_WIDTH - 1 : 0]  aw_buf_push_data;
wire                                    aw_buf_pop_vld;
wire                                    aw_buf_pop_rdy;
wire[LP_AXI_AW_BUF_DATA_WIDTH - 1 : 0]  aw_buf_pop_data;

wire                                    w_buf_push_vld;
wire                                    w_buf_push_rdy;
wire[LP_AXI_W_BUF_DATA_WIDTH - 1 : 0]   w_buf_push_data;
wire                                    w_buf_pop_vld;
wire                                    w_buf_pop_rdy;
wire[LP_AXI_W_BUF_DATA_WIDTH - 1 : 0]   w_buf_pop_data;

wire                                    b_buf_push_vld;
wire                                    b_buf_push_rdy;
wire[LP_AXI_B_BUF_DATA_WIDTH - 1 : 0]   b_buf_push_data;
wire                                    b_buf_pop_vld;
wire                                    b_buf_pop_rdy;
wire[LP_AXI_B_BUF_DATA_WIDTH - 1 : 0]   b_buf_pop_data;

wire                                    ar_buf_push_vld;
wire                                    ar_buf_push_rdy;
wire[LP_AXI_AR_BUF_DATA_WIDTH - 1 : 0]  ar_buf_push_data;
wire                                    ar_buf_pop_vld;
wire                                    ar_buf_pop_rdy;
wire[LP_AXI_AR_BUF_DATA_WIDTH - 1 : 0]  ar_buf_pop_data;

wire                                    r_buf_push_vld;
wire                                    r_buf_push_rdy;
wire[LP_AXI_R_BUF_DATA_WIDTH - 1 : 0]   r_buf_push_data;
wire                                    r_buf_pop_vld;
wire                                    r_buf_pop_rdy;
wire[LP_AXI_R_BUF_DATA_WIDTH - 1 : 0]   r_buf_pop_data;

// Write Address Channel
assign      aw_buf_push_vld = awvalid_m;
assign      aw_buf_push_data =  {
                                    awaddr_m,
                                    awlen_m,
                                    awsize_m,
                                    awburst_m,
                                    awcache_m,
                                    awprot_m,
                                    awqos_m,
                                    awregion_m,
                                    awuser_m,
                                    awid_m
                                };
assign      awready_m = aw_buf_push_rdy;

assign      {
                awaddr_s,
                awlen_s,
                awsize_s,
                awburst_s,
                awcache_s,
                awprot_s,
                awqos_s,
                awregion_s,
                awuser_s,
                awid_s
            } = aw_buf_pop_data;
assign      awvalid_s = aw_buf_pop_vld;
assign      aw_buf_pop_rdy = awready_s;

lnrv_gnrl_buf#
(
    .P_DATA_WIDTH               ( LP_AXI_AW_BUF_DATA_WIDTH      ),
    .P_DEEPTH                   ( P_AW_BUF_DEEPTH               ),
    .P_CUT_VALID                ( P_AW_CUT_VALID                ),
    .P_CUT_READY                ( P_AW_CUT_READY                ),
    .P_FLUSH_DELAY              ( 1'b0                          )
)
u_axi_aw_buf
(
    .clk                        ( aclk                          ),
    .reset_n                    ( areset_n                      ),
    .flush_req                  ( 1'b0                          ),
    .flush_ack                  (                               ),

    .push_vld                   ( aw_buf_push_vld               ),
    .push_rdy                   ( aw_buf_push_rdy               ),
    .push_data                  ( aw_buf_push_data              ),
    .pop_vld                    ( aw_buf_pop_vld                ),
    .pop_rdy                    ( aw_buf_pop_rdy                ),
    .pop_data                   ( aw_buf_pop_data               )
);

// W通道buffer
assign      w_buf_push_vld = wvalid_m;
assign      w_buf_push_data =   {
                                    wdata_m,
                                    wstrb_m,
                                    wid_m,
                                    wlast_m,
                                    wuser_m
                                };
assign      wready_m = w_buf_push_rdy;

assign      wvalid_s = w_buf_pop_vld;
assign      {
                wdata_m,
                wstrb_m,
                wid_m,
                wlast_m,
                wuser_m
            } = w_buf_pop_data;
assign      w_buf_pop_rdy = wready_s;
lnrv_gnrl_buf#
(
    .P_DATA_WIDTH               ( LP_AXI_W_BUF_DATA_WIDTH       ),
    .P_DEEPTH                   ( P_W_BUF_DEEPTH                ),
    .P_CUT_VALID                ( P_W_CUT_VALID                 ),
    .P_CUT_READY                ( P_W_CUT_READY                 ),
    .P_FLUSH_DELAY              ( 1'b0                          )
)
u_axi_w_buf
(
    .clk                        ( aclk                          ),
    .reset_n                    ( areset_n                      ),
    .flush_req                  ( 1'b0                          ),
    .flush_ack                  (                               ),

    .push_vld                   ( w_buf_push_vld                ),
    .push_rdy                   ( w_buf_push_rdy                ),
    .push_data                  ( w_buf_push_data               ),
    .pop_vld                    ( w_buf_pop_vld                 ),
    .pop_rdy                    ( w_buf_pop_rdy                 ),
    .pop_data                   ( w_buf_pop_data                )
);
// Write Reponse Channel
assign      b_buf_push_vld = bvalid_s;
assign      b_buf_push_data = {
                                    bresp_s,
                                    buser_s,
                                    bid_s
            };
assign      bready_s = b_buf_push_rdy;
assign      bvalid_m = b_buf_pop_vld;
assign      {
                bresp_m,
                buser_m,
                bid_m
            } = b_buf_pop_data;
assign      b_buf_pop_rdy = bready_m;
lnrv_gnrl_buf#
(
    .P_DATA_WIDTH               ( LP_AXI_B_BUF_DATA_WIDTH       ),
    .P_DEEPTH                   ( P_B_BUF_DEEPTH                ),
    .P_CUT_VALID                ( P_B_CUT_VALID                 ),
    .P_CUT_READY                ( P_B_CUT_READY                 ),
    .P_FLUSH_DELAY              ( 1'b0                          )
)
u_axi_b_buf
(
    .clk                        ( aclk                          ),
    .reset_n                    ( areset_n                      ),
    .flush_req                  ( 1'b0                          ),
    .flush_ack                  (                               ),

    .push_vld                   ( b_buf_push_vld                ),
    .push_rdy                   ( b_buf_push_rdy                ),
    .push_data                  ( b_buf_push_data               ),
    .pop_vld                    ( b_buf_pop_vld                 ),
    .pop_rdy                    ( b_buf_pop_rdy                 ),
    .pop_data                   ( b_buf_pop_data                )
);

// Read Address Channel
assign      ar_buf_push_vld = arvalid_m;
assign      ar_buf_push_data =  {
                                    araddr_m,
                                    arlen_m,
                                    arsize_m,
                                    arburst_m,
                                    arcache_m,
                                    arprot_m,
                                    arqos_m,
                                    arregion_m,
                                    aruser_m,
                                    arid_m
                                };
assign      arready_m = ar_buf_push_rdy;

assign      {
                araddr_s,
                arlen_s,
                arsize_s,
                arburst_s,
                arcache_s,
                arprot_s,
                arqos_s,
                arregion_s,
                aruser_s,
                arid_s
            } = ar_buf_pop_data;
assign      arvalid_s = ar_buf_pop_vld;
assign      ar_buf_pop_rdy = arready_s;
lnrv_gnrl_buf#
(
    .P_DATA_WIDTH               ( LP_AXI_AR_BUF_DATA_WIDTH      ),
    .P_DEEPTH                   ( P_AR_BUF_DEEPTH               ),
    .P_CUT_VALID                ( P_AR_CUT_VALID                ),
    .P_CUT_READY                ( P_AR_CUT_READY                ),
    .P_FLUSH_DELAY              ( 1'b0                          )
)
u_axi_ar_buf
(
    .clk                        ( aclk                          ),
    .reset_n                    ( areset_n                      ),
    .flush_req                  ( 1'b0                          ),
    .flush_ack                  (                               ),

    .push_vld                   ( ar_buf_push_vld               ),
    .push_rdy                   ( ar_buf_push_rdy               ),
    .push_data                  ( ar_buf_push_data              ),
    .pop_vld                    ( ar_buf_pop_vld                ),
    .pop_rdy                    ( ar_buf_pop_rdy                ),
    .pop_data                   ( ar_buf_pop_data               )
);

// Read Data Channel
assign      r_buf_push_vld = rvalid_s;
assign      r_buf_push_data =   {
                                    rdata_s,
                                    rid_s,
                                    rresp_s,
                                    rlast_s,
                                    ruser_s
                                };
assign      rready_s = r_buf_push_rdy;
assign      rvalid_m = r_buf_pop_vld;
assign      {
                rdata_m,
                rid_m,
                rresp_m,
                rlast_m,
                ruser_m
            } = r_buf_pop_data;
assign      r_buf_pop_rdy = rready_m;
lnrv_gnrl_buf#
(
    .P_DATA_WIDTH               ( LP_AXI_R_BUF_DATA_WIDTH       ),
    .P_DEEPTH                   ( P_R_BUF_DEEPTH                ),
    .P_CUT_VALID                ( P_R_CUT_VALID                 ),
    .P_CUT_READY                ( P_R_CUT_READY                 ),
    .P_FLUSH_DELAY              ( 1'b0                          )
)
u_axi_r_buf
(
    .clk                        ( aclk                          ),
    .reset_n                    ( areset_n                      ),
    .flush_req                  ( 1'b0                          ),
    .flush_ack                  (                               ),

    .push_vld                   ( r_buf_push_vld                ),
    .push_rdy                   ( r_buf_push_rdy                ),
    .push_data                  ( r_buf_push_data               ),
    .pop_vld                    ( r_buf_pop_vld                 ),
    .pop_rdy                    ( r_buf_pop_rdy                 ),
    .pop_data                   ( r_buf_pop_data                )
);

endmodule