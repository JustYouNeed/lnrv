module  lnrv_icb_mux#
(
    parameter                                       P_ADDR_WIDTH = 32,
    parameter                                       P_DATA_WIDTH = 32,

    parameter                                       P_ICB_COUNT = 4,

    parameter                                       P_OTS_COUNT = 1,

    // 是否在slave端口插入buff，以优化时序，但是会带来额外的latency
    parameter                                       P_CMD_BUFF_ENABLE = "true",
    parameter                                       P_CMD_BUFF_CUT_READY = "true",
    parameter                                       P_CMD_BUFF_BYPASS = "false",

    parameter                                       P_RSP_BUFF_ENABLE = "true",
    parameter                                       P_RSP_BUFF_CUT_READY = "true",
    parameter                                       P_RSP_BUFF_BYPASS = "false"
)
(
    input                                           clk,
    input                                           reset_n,

    // master port
    input[P_ICB_COUNT - 1 : 0]                      mn_icb_cmd_vld,
    output[P_ICB_COUNT - 1 : 0]                     mn_icb_cmd_rdy,
    input[P_ICB_COUNT - 1 : 0]                      mn_icb_cmd_write,
    input[(P_ADDR_WIDTH * P_ICB_COUNT) - 1 : 0]     mn_icb_cmd_addr,
    input[(P_DATA_WIDTH * P_ICB_COUNT) - 1 : 0]     mn_icb_cmd_wdata,
    input[((P_DATA_WIDTH/8) * P_ICB_COUNT) - 1 : 0] mn_icb_cmd_wstrb,

    input[P_ICB_COUNT - 1 : 0]                      mn_icb_rsp_rdy,
    output[P_ICB_COUNT - 1 : 0]                     mn_icb_rsp_vld,
    output[(P_DATA_WIDTH * P_ICB_COUNT) - 1 : 0]    mn_icb_rsp_rdata,
    output[P_ICB_COUNT - 1 : 0]                     mn_icb_rsp_err,

    // slave port
    output                                          s_icb_cmd_vld,
    input                                           s_icb_cmd_rdy,
    output                                          s_icb_cmd_write,
    output[P_ADDR_WIDTH - 1 : 0]                    s_icb_cmd_addr,
    output[P_DATA_WIDTH - 1 : 0]                    s_icb_cmd_wdata,
    output[(P_DATA_WIDTH / 8) - 1 : 0]              s_icb_cmd_wstrb,

    input                                           s_icb_rsp_vld,
    output                                          s_icb_rsp_rdy,
    input[P_DATA_WIDTH - 1 : 0]                     s_icb_rsp_rdata,
    input                                           s_icb_rsp_err
);
localparam                                  LP_DISP_BUF_DATA_WIDTH = P_ICB_COUNT;

// 分发信息fifo
wire[LP_DISP_BUF_DATA_WIDTH - 1 : 0]        disp_buf_push_data;
wire                                        disp_buf_push_vld;
wire                                        disp_buf_push_rdy;

wire[LP_DISP_BUF_DATA_WIDTH - 1 : 0]        disp_buf_pop_data;
wire                                        disp_buf_pop_vld;
wire                                        disp_buf_pop_rdy;

wire[P_ICB_COUNT - 1 : 0]       mst_icb_request;
wire[P_ICB_COUNT - 1 : 0]       mst_icb_grant;
wire[P_ICB_COUNT - 1 : 0]       mst_icb_grant_bufed;

// 各个master的信息
wire[P_ICB_COUNT - 1 : 0]       mst_icb_cmd_vld;
wire[P_ICB_COUNT - 1 : 0]       mst_icb_cmd_rdy;
wire[P_ICB_COUNT - 1 : 0]       mst_icb_cmd_write;
wire[P_ADDR_WIDTH - 1 : 0]      mst_icb_cmd_addr[P_ICB_COUNT - 1 : 0];
wire[P_DATA_WIDTH - 1 : 0]      mst_icb_cmd_wdata[P_ICB_COUNT - 1 : 0];
wire[(P_DATA_WIDTH/8) - 1 : 0]  mst_icb_cmd_wstrb[P_ICB_COUNT - 1 : 0];

wire[P_ICB_COUNT - 1 : 0]       mst_icb_rsp_vld;
wire[P_ICB_COUNT - 1 : 0]       mst_icb_rsp_rdy;
wire[P_ICB_COUNT - 1 : 0]       mst_icb_rsp_err;
wire[P_DATA_WIDTH - 1 : 0]      mst_icb_rsp_rdata[P_ICB_COUNT - 1 : 0];


reg                             mst_icb_cmd_vld_mux;
reg                             mst_icb_cmd_write_mux;
reg[P_ADDR_WIDTH - 1 : 0]       mst_icb_cmd_addr_mux;
reg[P_DATA_WIDTH - 1 : 0]       mst_icb_cmd_wdata_mux;
reg[(P_DATA_WIDTH/8) - 1 : 0]   mst_icb_cmd_wstrb_mux;

reg                             mst_icb_rsp_rdy_mux;

wire                            m_icb_cmd_vld;
wire                            m_icb_cmd_rdy;
wire                            m_icb_cmd_write;
wire[P_ADDR_WIDTH - 1 : 0]      m_icb_cmd_addr;
wire[P_DATA_WIDTH - 1 : 0]      m_icb_cmd_wdata;
wire[(P_DATA_WIDTH/8) - 1 : 0]  m_icb_cmd_wstrb;

wire                            m_icb_rsp_vld;
wire                            m_icb_rsp_rdy;
wire[P_DATA_WIDTH - 1 : 0]      m_icb_rsp_rdata;
wire                            m_icb_rsp_err;


wire                            m_icb_cmd_vld_bufed;
wire                            m_icb_cmd_rdy_bufed;
wire                            m_icb_cmd_write_bufed;
wire[P_ADDR_WIDTH - 1 : 0]      m_icb_cmd_addr_bufed;
wire[P_DATA_WIDTH - 1 : 0]      m_icb_cmd_wdata_bufed;
wire[(P_DATA_WIDTH/8) - 1 : 0]  m_icb_cmd_wstrb_bufed;

wire                            m_icb_rsp_vld_bufed;
wire                            m_icb_rsp_rdy_bufed;
wire[P_DATA_WIDTH - 1 : 0]      m_icb_rsp_rdata_bufed;
wire                            m_icb_rsp_err_bufed;

genvar                          i;
integer                         j;


// 只要command通道有效，就需要请求总线使用权限
assign      mst_icb_request = mn_icb_cmd_vld & {P_ICB_COUNT{disp_buf_push_rdy}};

// 需要对多个master进行仲裁，以决定当前传输哪个master的数据
lnrv_gnrl_arbiter#
(
    .P_ARBT_NUM         ( P_ICB_COUNT       ),
    .P_ARBT_TYPE        ( "round-robin"     )
) 
u_lnrv_gnrl_arbiter
(
    .clk                ( clk               ),
    .reset_n            ( reset_n           ),

    .request            ( mst_icb_request   ),
    .grant              ( mst_icb_grant     )
);


// 先分离各个master输入的控制信息
generate
    for(i = 0; i < P_ICB_COUNT; i = i + 1) begin
        assign      mst_icb_cmd_vld[i] = mst_icb_grant[i] & mn_icb_cmd_vld[i];
        assign      mst_icb_cmd_write[i] = mst_icb_grant[i] & mn_icb_cmd_write[i];
        assign      mst_icb_cmd_addr[i] = {P_ADDR_WIDTH{mst_icb_grant[i]}} & mn_icb_cmd_addr[i * P_ADDR_WIDTH +: P_ADDR_WIDTH];
        assign      mst_icb_cmd_wdata[i] = {P_DATA_WIDTH{mst_icb_grant[i]}} & mn_icb_cmd_wdata[i * P_DATA_WIDTH +: P_DATA_WIDTH];
        assign      mst_icb_cmd_wstrb[i] = {(P_DATA_WIDTH/8){mst_icb_grant[i]}} & mn_icb_cmd_wstrb[i * (P_DATA_WIDTH/8) +: (P_DATA_WIDTH/8)];
        assign      mst_icb_cmd_rdy[i] = mst_icb_grant[i] & m_icb_cmd_rdy;

        assign      mst_icb_rsp_rdy[i] = mst_icb_grant_bufed[i] & mn_icb_rsp_rdy[i];
        assign      mst_icb_rsp_vld[i] = mst_icb_grant_bufed[i] & m_icb_rsp_vld_real;
        assign      mst_icb_rsp_err[i] = mst_icb_grant_bufed[i] & m_icb_rsp_err;
        assign      mst_icb_rsp_rdata[i] = {P_DATA_WIDTH{mst_icb_grant_bufed[i]}} & m_icb_rsp_rdata;
    end
endgenerate

// 合并所有master command通道的输入
always@(*) begin
    mst_icb_cmd_vld_mux = 1'b0;
    mst_icb_cmd_write_mux = 1'b0;
    mst_icb_cmd_addr_mux = {P_ADDR_WIDTH{1'b0}};
    mst_icb_cmd_wdata_mux = {P_DATA_WIDTH{1'b0}};
    mst_icb_cmd_wstrb_mux = {(P_DATA_WIDTH/8){1'b0}};

    for(j = 0; j < P_ICB_COUNT; j = j + 1) begin
        mst_icb_cmd_vld_mux   = mst_icb_cmd_vld_mux | mst_icb_cmd_vld[j];
        mst_icb_cmd_write_mux = mst_icb_cmd_write_mux | mst_icb_cmd_write[j];
        mst_icb_cmd_addr_mux  = mst_icb_cmd_addr_mux | mst_icb_cmd_addr[j];
        mst_icb_cmd_wdata_mux = mst_icb_cmd_wdata_mux | mst_icb_cmd_wdata[j];
        mst_icb_cmd_wstrb_mux  = mst_icb_cmd_wstrb_mux | mst_icb_cmd_wstrb[j];
    end
end

// 合并所有master response通道的输入
always@(*) begin
    mst_icb_rsp_rdy_mux = 1'b0;

    for(j = 0; j < P_ICB_COUNT; j = j + 1) begin
        mst_icb_rsp_rdy_mux   = mst_icb_rsp_rdy_mux | mst_icb_rsp_rdy[j];
    end
end

// 需要等分发buff就绪才可以将command下发
assign      m_icb_cmd_vld   = mst_icb_cmd_vld_mux & disp_buf_push_rdy;
assign      m_icb_cmd_write = mst_icb_cmd_write_mux;
assign      m_icb_cmd_addr  = mst_icb_cmd_addr_mux;
assign      m_icb_cmd_wdata = mst_icb_cmd_wdata_mux;
assign      m_icb_cmd_wstrb = mst_icb_cmd_wstrb_mux;



// 只有分发fifo中有分发信息就表示rsp通道真正就绪
assign      m_icb_rsp_vld_real  = m_icb_rsp_vld & disp_buf_pop_vld;
assign      m_icb_rsp_rdy       = mst_icb_rsp_rdy_mux;

assign      m_icb_cmd_hsked = m_icb_cmd_vld & m_icb_cmd_rdy;
assign      m_icb_rsp_hsked = m_icb_rsp_vld & m_icb_rsp_rdy;

// command成功握手就将分发信息压入fifo
assign      disp_buf_push_vld   = m_icb_cmd_hsked;
assign      disp_buf_push_data  = mst_icb_grant;

assign      disp_buf_pop_rdy    = m_icb_rsp_hsked;
assign      mst_icb_grant_bufed = disp_buf_pop_data;

// 将分发信息保存下来，用于rsp通道
lnrv_gnrl_buffer#
(
    .P_DATA_WIDTH       ( LP_DISP_BUF_DATA_WIDTH    ),
    .P_DEEPTH           ( P_OTS_COUNT               ),
    .P_CUT_READY        ( "false"                   ),
    .P_BYPASS           ( "true"                    )
) 
u_icb_disp_buf
(
    .clk                ( clk                       ),
    .reset_n            ( reset_n                   ),

    .flush_req          ( 1'b0                      ),
    .flush_ack          (                           ),

    .push_vld           ( disp_buf_push_vld         ),
    .push_rdy           ( disp_buf_push_rdy         ),
    .push_data          ( disp_buf_push_data        ),

    .pop_vld            ( disp_buf_pop_vld          ),
    .pop_rdy            ( disp_buf_pop_rdy          ),
    .pop_data           ( disp_buf_pop_data         )
);


// 插入buff
lnrv_icb_buf#(
    .P_ADDR_WIDTH                   ( P_ADDR_WIDTH              ),
    .P_DATA_WIDTH                   ( P_DATA_WIDTH              ),
    .P_CMD_BUFF_ENABLE              ( P_CMD_BUFF_ENABLE         ),
    .P_CMD_BUFF_CUT_READY           ( P_CMD_BUFF_CUT_READY      ),
    .P_CMD_BUFF_BYPASS              ( P_CMD_BUFF_BYPASS         ),
    .P_RSP_BUFF_ENABLE              ( P_RSP_BUFF_ENABLE         ),
    .P_RSP_BUFF_CUT_READY           ( P_RSP_BUFF_CUT_READY      ),
    .P_RSP_BUFF_BYPASS              ( P_RSP_BUFF_BYPASS         ),
    .P_OTS_COUNT                    ( P_OTS_COUNT               )
)
u_lnrv_icb_buf
(
    .m_icb_cmd_vld                  ( m_icb_cmd_vld             ),
    .m_icb_cmd_rdy                  ( m_icb_cmd_rdy             ),
    .m_icb_cmd_write                ( m_icb_cmd_write           ),
    .m_icb_cmd_addr                 ( m_icb_cmd_addr            ),
    .m_icb_cmd_wdata                ( m_icb_cmd_wdata           ),
    .m_icb_cmd_wstrb                ( m_icb_cmd_wstrb           ),

    .m_icb_rsp_vld                  ( m_icb_rsp_vld             ),
    .m_icb_rsp_rdy                  ( m_icb_rsp_rdy             ),
    .m_icb_rsp_rdata                ( m_icb_rsp_rdata           ),
    .m_icb_rsp_err                  ( m_icb_rsp_err             ),

    .s_icb_cmd_vld                  ( s_icb_cmd_vld             ),
    .s_icb_cmd_rdy                  ( s_icb_cmd_rdy             ),
    .s_icb_cmd_write                ( s_icb_cmd_write           ),
    .s_icb_cmd_addr                 ( s_icb_cmd_addr            ),
    .s_icb_cmd_wdata                ( s_icb_cmd_wdata           ),
    .s_icb_cmd_wstrb                ( s_icb_cmd_wstrb           ),
    .s_icb_rsp_vld                  ( s_icb_rsp_vld             ),
    .s_icb_rsp_rdy                  ( s_icb_rsp_rdy             ),
    .s_icb_rsp_rdata                ( s_icb_rsp_rdata           ),
    .s_icb_rsp_err                  ( s_icb_rsp_err             ),

    .clk                            ( clk                       ),
    .reset_n                        ( reset_n                   )
);

generate
    for(i = 0; i < P_ICB_COUNT; i = i + 1) begin
        assign      mn_icb_cmd_rdy[i] = mst_icb_cmd_rdy[i];

        assign      mn_icb_rsp_vld[i] = mst_icb_rsp_vld[i];
        assign      mn_icb_rsp_err[i] = mst_icb_rsp_err[i];
        assign      mn_icb_rsp_rdata[i * P_DATA_WIDTH +: P_DATA_WIDTH] = mst_icb_rsp_rdata[i];
    end
endgenerate


endmodule