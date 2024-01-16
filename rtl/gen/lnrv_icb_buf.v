module lnrv_icb_buf#
(
    parameter                           P_ADDR_WIDTH = 32,
    parameter                           P_DATA_WIDTH = 32,

    parameter                           P_CMD_BUFF_ENABLE = "true",
    parameter                           P_CMD_BUFF_CUT_READY = "true",
    parameter                           P_CMD_BUFF_BYPASS = "false",

    parameter                           P_RSP_BUFF_ENABLE = "true",
    parameter                           P_RSP_BUFF_CUT_READY = "true",
    parameter                           P_RSP_BUFF_BYPASS = "false",

    parameter                           P_OTS_COUNT = 1
)
(
    input                               m_icb_cmd_vld,
    output                              m_icb_cmd_rdy,
    input                               m_icb_cmd_write,
    input[P_ADDR_WIDTH - 1 : 0]         m_icb_cmd_addr,
    input[P_DATA_WIDTH - 1 : 0]         m_icb_cmd_wdata,
    input[(P_DATA_WIDTH/8) - 1 : 0]     m_icb_cmd_wstrb,

    output                              m_icb_rsp_vld,
    input                               m_icb_rsp_rdy,
    output[P_DATA_WIDTH - 1 : 0]        m_icb_rsp_rdata,
    output                              m_icb_rsp_err,

    output                              s_icb_cmd_vld,
    input                               s_icb_cmd_rdy,
    output                              s_icb_cmd_write,
    output[P_ADDR_WIDTH - 1 : 0]        s_icb_cmd_addr,
    output[P_DATA_WIDTH - 1 : 0]        s_icb_cmd_wdata,
    output[(P_DATA_WIDTH/8) - 1 : 0]    s_icb_cmd_wstrb,

    input                               s_icb_rsp_vld,
    output                              s_icb_rsp_rdy,
    input[P_DATA_WIDTH - 1 : 0]         s_icb_rsp_rdata,
    input                               s_icb_rsp_err,

    input                               clk,
    input                               reset_n
);

// command
lnrv_icb_cmd_buf#
(
    .P_BUFF_ENABLE          ( P_CMD_BUFF_ENABLE         ),
    .P_BUFF_CUT_READY       ( P_CMD_BUFF_CUT_READY      ),
    .P_BUFF_BYPASS          ( P_CMD_BUFF_BYPASS         ),
    .P_OTS_COUNT            ( P_OTS_COUNT               ),
    .P_ADDR_WIDTH           ( P_ADDR_WIDTH              ),
    .P_DATA_WIDTH           ( P_DATA_WIDTH              )
)
u_lnrv_icb_cmd_buf
(
    .m_icb_cmd_vld          ( m_icb_cmd_vld             ),
    .m_icb_cmd_rdy          ( m_icb_cmd_rdy             ),
    .m_icb_cmd_write        ( m_icb_cmd_write           ),
    .m_icb_cmd_addr         ( m_icb_cmd_addr            ),
    .m_icb_cmd_wdata        ( m_icb_cmd_wdata           ),
    .m_icb_cmd_wstrb        ( m_icb_cmd_wstrb           ),

    .s_icb_cmd_vld          ( s_icb_cmd_vld             ),
    .s_icb_cmd_rdy          ( s_icb_cmd_rdy             ),
    .s_icb_cmd_write        ( s_icb_cmd_write           ),
    .s_icb_cmd_addr         ( s_icb_cmd_addr            ),
    .s_icb_cmd_wdata        ( s_icb_cmd_wdata           ),
    .s_icb_cmd_wstrb        ( s_icb_cmd_wstrb           ),

    .clk                    ( clk                       ),
    .reset_n                ( reset_n                   )
);

// response
lnrv_icb_rsp_buf#
(
    .P_BUFF_ENABLE          ( P_RSP_BUFF_ENABLE         ),
    .P_BUFF_CUT_READY       ( P_RSP_BUFF_CUT_READY      ),
    .P_BUFF_BYPASS          ( P_RSP_BUFF_BYPASS         ),
    .P_OTS_COUNT            ( P_OTS_COUNT               ),
    .P_DATA_WIDTH           ( P_DATA_WIDTH              )
)
u_lnrv_icb_rsp_buf
(
    .s_icb_rsp_vld          ( s_icb_rsp_vld             ),
    .s_icb_rsp_rdy          ( s_icb_rsp_rdy             ),
    .s_icb_rsp_rdata        ( s_icb_rsp_rdata           ),
    .s_icb_rsp_err          ( s_icb_rsp_err             ),

    .m_icb_rsp_vld          ( m_icb_rsp_vld             ),
    .m_icb_rsp_rdy          ( m_icb_rsp_rdy             ),
    .m_icb_rsp_rdata        ( m_icb_rsp_rdata           ),
    .m_icb_rsp_err          ( m_icb_rsp_err             ),

    .clk                    ( clk                       ),
    .reset_n                ( reset_n                   )
);


endmodule