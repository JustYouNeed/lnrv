module lnrv_icb_buf#
(
    parameter                           P_ADDR_WIDTH            = 32,
    parameter                           P_DATA_WIDTH            = 32,

    parameter                           P_CMD_BUFF_ENABLE       = 1'b1,
    parameter                           P_CMD_BUFF_CUT_READY    = 1'b1,
    parameter                           P_CMD_BUFF_BYPASS       = 1'b0,
    parameter                           P_CMD_OTS_COUNT         = 1,

    parameter                           P_RSP_BUFF_ENABLE       = 1'b1,
    parameter                           P_RSP_BUFF_CUT_READY    = 1'b1,
    parameter                           P_RSP_BUFF_BYPASS       = 1'b0,
    parameter                           P_RSP_OTS_COUNT         = 1
)
(
    input                               icb_cmd_vld_m,
    output                              icb_cmd_rdy_m,
    input                               icb_cmd_write_m,
    input[P_ADDR_WIDTH - 1 : 0]         icb_cmd_addr_m,
    input[P_DATA_WIDTH - 1 : 0]         icb_cmd_wdata_m,
    input[(P_DATA_WIDTH/8) - 1 : 0]     icb_cmd_wstrb_m,
    input[2 : 0]                        icb_cmd_size_m,

    output                              icb_rsp_vld_m,
    input                               icb_rsp_rdy_m,
    output[P_DATA_WIDTH - 1 : 0]        icb_rsp_rdata_m,
    output                              icb_rsp_err_m,

    output                              icb_cmd_vld_s,
    input                               icb_cmd_rdy_s,
    output                              icb_cmd_write_s,
    output[P_ADDR_WIDTH - 1 : 0]        icb_cmd_addr_s,
    output[P_DATA_WIDTH - 1 : 0]        icb_cmd_wdata_s,
    output[(P_DATA_WIDTH/8) - 1 : 0]    icb_cmd_wstrb_s,
    output[2 : 0]                       icb_cmd_size_s,

    input                               icb_rsp_vld_s,
    output                              icb_rsp_rdy_s,
    input[P_DATA_WIDTH - 1 : 0]         icb_rsp_rdata_s,
    input                               icb_rsp_err_s,

    input                               clk,
    input                               reset_n
);

// command
icb_cmd_buf_lnrv#
(
    .P_BUFF_ENABLE          ( P_CMD_BUFF_ENABLE         ),
    .P_BUFF_CUT_READY       ( P_CMD_BUFF_CUT_READY      ),
    .P_BUFF_BYPASS          ( P_CMD_BUFF_BYPASS         ),
    .P_OTS_COUNT            ( P_CMD_OTS_COUNT           ),
    .P_ADDR_WIDTH           ( P_ADDR_WIDTH              ),
    .P_DATA_WIDTH           ( P_DATA_WIDTH              )
)
icb_cmd_buf_u_lnrv
(
    .icb_cmd_vld_m          ( icb_cmd_vld_m             ),
    .icb_cmd_rdy_m          ( icb_cmd_rdy_m             ),
    .icb_cmd_write_m        ( icb_cmd_write_m           ),
    .icb_cmd_addr_m         ( icb_cmd_addr_m            ),
    .icb_cmd_wdata_m        ( icb_cmd_wdata_m           ),
    .icb_cmd_wstrb_m        ( icb_cmd_wstrb_m           ),
    .icb_cmd_size_m         ( icb_cmd_size_m            ),

    .icb_cmd_vld_s          ( icb_cmd_vld_s             ),
    .icb_cmd_rdy_s          ( icb_cmd_rdy_s             ),
    .icb_cmd_write_s        ( icb_cmd_write_s           ),
    .icb_cmd_addr_s         ( icb_cmd_addr_s            ),
    .icb_cmd_wdata_s        ( icb_cmd_wdata_s           ),
    .icb_cmd_wstrb_s        ( icb_cmd_wstrb_s           ),
    .icb_cmd_size_s         ( icb_cmd_size_s            ),

    .clk                    ( clk                       ),
    .reset_n                ( reset_n                   )
);

// response
icb_rsp_buf_lnrv#
(
    .P_BUFF_ENABLE          ( P_RSP_BUFF_ENABLE         ),
    .P_BUFF_CUT_READY       ( P_RSP_BUFF_CUT_READY      ),
    .P_BUFF_BYPASS          ( P_RSP_BUFF_BYPASS         ),
    .P_OTS_COUNT            ( P_RSP_OTS_COUNT           ),
    .P_DATA_WIDTH           ( P_DATA_WIDTH              )
)
icb_rsp_buf_u_lnrv
(
    .icb_rsp_vld_s          ( icb_rsp_vld_s             ),
    .icb_rsp_rdy_s          ( icb_rsp_rdy_s             ),
    .icb_rsp_rdata_s        ( icb_rsp_rdata_s           ),
    .icb_rsp_err_s          ( icb_rsp_err_s             ),

    .icb_rsp_vld_m          ( icb_rsp_vld_m             ),
    .icb_rsp_rdy_m          ( icb_rsp_rdy_m             ),
    .icb_rsp_rdata_m        ( icb_rsp_rdata_m           ),
    .icb_rsp_err_m          ( icb_rsp_err_m             ),

    .clk                    ( clk                       ),
    .reset_n                ( reset_n                   )
);


endmodule