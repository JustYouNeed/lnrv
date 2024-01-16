module lnrv_icb_demux#
(
    parameter                                           P_ADDR_WIDTH = 32,
    parameter                                           P_DATA_WIDTH = 32,
    parameter                                           P_ICB_COUNT = 4,

    // 是否在master通路上插入一个buffer，可以优化时序
    parameter                                           P_CMD_BUFF_ENABLE = "true",
    parameter                                           P_CMD_BUFF_CUT_READY = "true",
    parameter                                           P_CMD_BUFF_BYPASS = "false",

    parameter                                           P_RSP_BUFF_ENABLE = "true",
    parameter                                           P_RSP_BUFF_CUT_READY = "true",
    parameter                                           P_RSP_BUFF_BYPASS = "false",

    parameter                                           P_OTS_COUNT = 1
)   
(   
    input                                               clk,
    input                                               reset_n,

    // master
    input                                               m_icb_cmd_vld,
    output                                              m_icb_cmd_rdy,
    input                                               m_icb_cmd_write,
    input[P_ADDR_WIDTH - 1 : 0]                         m_icb_cmd_addr,
    input[P_DATA_WIDTH - 1 : 0]                         m_icb_cmd_wdata,
    input[(P_DATA_WIDTH/8) - 1 : 0]                     m_icb_cmd_wstrb,
    input                                               m_icb_rsp_rdy,
    output                                              m_icb_rsp_vld,
    output[P_DATA_WIDTH - 1 : 0]                        m_icb_rsp_rdata,
    output                                              m_icb_rsp_err,

    // slave
    output[P_ICB_COUNT - 1 : 0]                         sn_icb_cmd_vld,
    input[P_ICB_COUNT - 1 : 0]                          sn_icb_cmd_rdy,
    output[P_ICB_COUNT - 1 : 0]                         sn_icb_cmd_write,
    output[(P_ADDR_WIDTH * P_ICB_COUNT) - 1 : 0]        sn_icb_cmd_addr,
    output[(P_DATA_WIDTH * P_ICB_COUNT) - 1 : 0]        sn_icb_cmd_wdata,
    output[((P_DATA_WIDTH/8) * P_ICB_COUNT) - 1 : 0]    sn_icb_cmd_wstrb,
    input[P_ICB_COUNT - 1 : 0]                          sn_icb_rsp_vld,
    output[P_ICB_COUNT - 1 : 0]                         sn_icb_rsp_rdy,
    input[(P_DATA_WIDTH * P_ICB_COUNT) - 1 : 0]         sn_icb_rsp_rdata,
    input[P_ICB_COUNT - 1 : 0]                          sn_icb_rsp_err,

    // 地址指示
    input[(P_ADDR_WIDTH * P_ICB_COUNT) - 1 : 0]         sn_region_base,
    input[(P_ADDR_WIDTH * P_ICB_COUNT) - 1 : 0]         sn_region_end
);

localparam                                  LP_DISP_BUF_DATA_WIDTH = P_ICB_COUNT;

wire[LP_DISP_BUF_DATA_WIDTH - 1 : 0]        disp_buf_push_data;
wire                                        disp_buf_push_vld;
wire                                        disp_buf_push_rdy;

wire[LP_DISP_BUF_DATA_WIDTH - 1 : 0]        disp_buf_pop_data;
wire                                        disp_buf_pop_vld;
wire                                        disp_buf_pop_rdy;

wire                                        m_icb_cmd_vld_bufed;
wire                                        m_icb_cmd_rdy_bufed;
wire                                        m_icb_cmd_write_bufed;
wire[P_ADDR_WIDTH - 1 : 0]                  m_icb_cmd_addr_bufed;
wire[P_DATA_WIDTH - 1 : 0]                  m_icb_cmd_wdata_bufed;
wire[(P_DATA_WIDTH/8) - 1 : 0]              m_icb_cmd_wstrb_bufed;

wire                                        m_icb_rsp_vld_bufed;
wire                                        m_icb_rsp_rdy_bufed;
wire[P_DATA_WIDTH - 1 : 0]                  m_icb_rsp_rdata_bufed;
wire                                        m_icb_rsp_err_bufed;


wire[P_ICB_COUNT - 1 : 0]                   slv_icb_cmd_vld;
wire[P_ICB_COUNT - 1 : 0]                   slv_icb_cmd_rdy;
wire[P_ICB_COUNT - 1 : 0]                   slv_icb_cmd_write;
wire[P_ADDR_WIDTH - 1 : 0]                  slv_icb_cmd_addr[P_ICB_COUNT - 1 : 0];
wire[P_DATA_WIDTH - 1 : 0]                  slv_icb_cmd_wdata[P_ICB_COUNT - 1 : 0];
wire[(P_DATA_WIDTH/8) - 1 : 0]              slv_icb_cmd_wstrb[P_ICB_COUNT - 1 : 0];
wire[P_ICB_COUNT - 1 : 0]                   slv_icb_rsp_vld;
wire[P_ICB_COUNT - 1 : 0]                   slv_icb_rsp_rdy;
wire[P_DATA_WIDTH - 1 : 0]                  slv_icb_rsp_rdata[P_ICB_COUNT - 1 : 0];
wire[P_ICB_COUNT - 1 : 0]                   slv_icb_rsp_err;

wire[P_ADDR_WIDTH - 1 : 0]                  slv_region_start_addr[P_ICB_COUNT - 1 : 0];
wire[P_ADDR_WIDTH - 1 : 0]                  slv_region_end_addr[P_ICB_COUNT - 1 : 0];
wire[P_ICB_COUNT - 1 : 0]                   slv_region_match;
wire[P_ICB_COUNT - 1 : 0]                   slv_region_match_bufed;

wire[P_ICB_COUNT - 1 : 0]                   addr_gte_start_addr;
wire[P_ICB_COUNT - 1 : 0]                   addr_ls_end_addr;
wire[P_ICB_COUNT - 1 : 0]                   end_addr_is_zero;

wire                                        no_region_match;
wire                                        no_region_match_bufed;


wire                                        m_icb_cmd_rdy_mux;
wire                                        m_icb_rsp_vld_mux;
reg[P_DATA_WIDTH - 1 : 0]                   m_icb_rsp_rdata_mux;
reg                                         m_icb_rsp_err_mux;

wire                                        m_icb_cmd_hsked;
wire                                        m_icb_rsp_hsked;

genvar                                      i;
integer                                     j;


assign      m_icb_cmd_hsked = m_icb_cmd_vld & m_icb_cmd_rdy;
assign      m_icb_rsp_hsked = m_icb_rsp_vld & m_icb_rsp_rdy;

// 根据参数决定是否需要在输入端口插入一个buff
lnrv_icb_buf#
(
    .P_ADDR_WIDTH           ( P_ADDR_WIDTH              ),
    .P_DATA_WIDTH           ( P_DATA_WIDTH              ),

    .P_CMD_BUFF_ENABLE      ( P_CMD_BUFF_ENABLE         ),
    .P_CMD_BUFF_CUT_READY   ( P_CMD_BUFF_CUT_READY      ),
    .P_CMD_BUFF_BYPASS      ( P_CMD_BUFF_BYPASS         ),

    .P_RSP_BUFF_ENABLE      ( P_RSP_BUFF_ENABLE         ),
    .P_RSP_BUFF_CUT_READY   ( P_RSP_BUFF_CUT_READY      ),
    .P_RSP_BUFF_BYPASS      ( P_RSP_BUFF_BYPASS         ),

    .P_OTS_COUNT            ( P_OTS_COUNT               )
)
u_lnrv_icb_buf
(
    .m_icb_cmd_vld          ( m_icb_cmd_vld             ),
    .m_icb_cmd_rdy          ( m_icb_cmd_rdy             ),
    .m_icb_cmd_write        ( m_icb_cmd_write           ),
    .m_icb_cmd_addr         ( m_icb_cmd_addr            ),
    .m_icb_cmd_wdata        ( m_icb_cmd_wdata           ),
    .m_icb_cmd_wstrb        ( m_icb_cmd_wstrb           ),
    .m_icb_rsp_vld          ( m_icb_rsp_vld             ),
    .m_icb_rsp_rdy          ( m_icb_rsp_rdy             ),
    .m_icb_rsp_rdata        ( m_icb_rsp_rdata           ),
    .m_icb_rsp_err          ( m_icb_rsp_err             ),

    .s_icb_cmd_vld          ( m_icb_cmd_vld_bufed       ),
    .s_icb_cmd_rdy          ( m_icb_cmd_rdy_bufed       ),
    .s_icb_cmd_write        ( m_icb_cmd_write_bufed     ),
    .s_icb_cmd_addr         ( m_icb_cmd_addr_bufed      ),
    .s_icb_cmd_wdata        ( m_icb_cmd_wdata_bufed     ),
    .s_icb_cmd_wstrb        ( m_icb_cmd_wstrb_bufed     ),
    .s_icb_rsp_vld          ( m_icb_rsp_vld_bufed       ),
    .s_icb_rsp_rdy          ( m_icb_rsp_rdy_bufed       ),
    .s_icb_rsp_rdata        ( m_icb_rsp_rdata_bufed     ),
    .s_icb_rsp_err          ( m_icb_rsp_err_bufed       ),

    .clk                    ( clk                       ),
    .reset_n                ( reset_n                   )
);

// 指令通道握手成功后，将当前选择的通道信息推入disp_fifo中
assign      disp_buf_push_vld   = m_icb_cmd_hsked;
assign      disp_buf_push_data  = slv_region_match;

assign      no_region_match = ~(|slv_region_match);

// 应答通道握手成功，表示已经完成一次通信，将保存的通道信息弹出
assign      disp_buf_pop_rdy        = m_icb_rsp_hsked;
assign      slv_region_match_bufed  = disp_buf_pop_data;
assign      no_region_match_bufed = ~(|slv_region_match_bufed);

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

 // 分离出各个地址区间的base和mask信息，进行匹配
generate
    for(i = 0; i < P_ICB_COUNT; i = i + 1) begin
        assign      slv_region_start_addr[i] = sn_region_base[i * P_ADDR_WIDTH +: P_ADDR_WIDTH];
        assign      slv_region_end_addr[i] = sn_region_end[i * P_ADDR_WIDTH +: P_ADDR_WIDTH];

        assign      addr_gte_start_addr[i] = (m_icb_cmd_addr_bufed >= slv_region_start_addr[i]);
        assign      addr_ls_end_addr[i] = (m_icb_cmd_addr_bufed < slv_region_end_addr[i]);
        assign      end_addr_is_zero[i] = ~(|slv_region_end_addr[i]);
    end

    
    for(i = 0; i < P_ICB_COUNT - 1; i = i + 1) begin
        assign      slv_region_match[i] = addr_gte_start_addr[i] & addr_ls_end_addr[i];
    end

    // 最后一个通道的匹配规则不一样，如果结束地址为0，则不需要进行匹配，没有选中其他通道时，默认选中最后一个通道
    // 如果最后一个通道的结束地址不为0，则正常进行匹配
    assign      slv_region_match[P_ICB_COUNT - 1] = end_addr_is_zero[P_ICB_COUNT - 1] ? (~|(slv_region_match[P_ICB_COUNT - 2 : 0])) : 
                                                    (addr_gte_start_addr[P_ICB_COUNT - 1] & addr_ls_end_addr[P_ICB_COUNT - 1]);
endgenerate

// 根据地址匹配，进行分发
generate
    // 分离slave port
    for(i = 0; i < P_ICB_COUNT; i = i + 1) begin
        assign      slv_icb_cmd_vld[i]      = slv_region_match[i] & m_icb_cmd_vld_bufed;
        assign      slv_icb_cmd_write[i]    = slv_region_match[i] & m_icb_cmd_write_bufed;
        assign      slv_icb_cmd_addr[i]     = {P_ADDR_WIDTH{slv_region_match[i]}} & m_icb_cmd_addr_bufed;
        assign      slv_icb_cmd_wdata[i]    = {P_DATA_WIDTH{slv_region_match[i]}} & m_icb_cmd_wdata_bufed;
        assign      slv_icb_cmd_wstrb[i]    = {(P_DATA_WIDTH/8){slv_region_match[i]}} & m_icb_cmd_wstrb_bufed;
        assign      slv_icb_cmd_rdy[i]      = slv_region_match[i] & sn_icb_cmd_rdy[i];

        assign      slv_icb_rsp_rdy[i]      = slv_region_match_bufed[i] & m_icb_rsp_rdy_bufed;
        assign      slv_icb_rsp_vld[i]      = slv_region_match_bufed[i] & sn_icb_rsp_vld[i];
        assign      slv_icb_rsp_rdata[i]    = {P_DATA_WIDTH{slv_region_match_bufed[i]}} & sn_icb_rsp_rdata[i * P_DATA_WIDTH +: P_DATA_WIDTH];
        assign      slv_icb_rsp_err[i]      = slv_region_match_bufed[i] & sn_icb_rsp_err[i];
    end

    for(i = 0; i < P_ICB_COUNT; i = i + 1) begin
        assign      sn_icb_cmd_vld[i]                                           = slv_icb_cmd_vld[i];
        assign      sn_icb_cmd_addr[i * P_ADDR_WIDTH +: P_ADDR_WIDTH]           = slv_icb_cmd_addr[i];
        assign      sn_icb_cmd_write[i]                                         = slv_icb_cmd_write[i];
        assign      sn_icb_cmd_wdata[i * P_DATA_WIDTH +: P_DATA_WIDTH]          = slv_icb_cmd_wdata[i];
        assign      sn_icb_cmd_wstrb[i * (P_DATA_WIDTH/8) +: (P_DATA_WIDTH/8)]  = slv_icb_cmd_wstrb[i];

        assign      sn_icb_rsp_rdy[i] = slv_icb_rsp_rdy[i];
    end
endgenerate



// 从slave中选中一个数据
assign      m_icb_cmd_rdy_mux = |{slv_icb_cmd_rdy};
assign      m_icb_rsp_vld_mux = |{slv_icb_rsp_vld};
generate
    always@(*) begin
        m_icb_rsp_rdata_mux = {P_DATA_WIDTH{1'b0}};
        m_icb_rsp_err_mux = 1'b0;

        // 从slave中选出rsp
        for(j = 0; j < P_ICB_COUNT; j = j + 1) begin
            m_icb_rsp_rdata_mux     = m_icb_rsp_rdata_mux | slv_icb_rsp_rdata[j];
            m_icb_rsp_err_mux       = m_icb_rsp_err_mux | slv_icb_rsp_err[j];
        end
    end
endgenerate


// 如果没有匹配到任一地址区间，则立即回rdy
assign      m_icb_cmd_rdy_bufed = no_region_match ? m_icb_cmd_vld : m_icb_cmd_rdy_mux;

assign      m_icb_rsp_vld_bufed = no_region_match_bufed ? disp_buf_pop_vld : m_icb_rsp_vld_mux;
assign      m_icb_rsp_err_bufed = m_icb_rsp_err_mux | no_region_match_bufed;
assign      m_icb_rsp_rdata_bufed = m_icb_rsp_rdata_mux;

    
endmodule //lnrv_icb_demux
