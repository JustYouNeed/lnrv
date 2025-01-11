module  lnrv_icb2apb#
(
    parameter                           P_ADDR_WIDTH        = 32,
    parameter                           P_DATA_WIDTH        = 32,

    parameter                           P_CMD_CUT_VALID     = 1'b1,
    parameter                           P_CMD_CUT_READY     = 1'b1,

    parameter                           P_RSP_CUT_VALID     = 1'b1,
    parameter                           P_RSP_CUT_READY     = 1'b1,

    parameter                           P_OTS_COUNT         = 1
)
(
    input                               clk,
    input                               reset_n,

    // ICB总线接口
    input                               icb_cmd_vld,
    output                              icb_cmd_rdy,
    input                               icb_cmd_write,
    input[(P_DATA_WIDTH/8) - 1 : 0]     icb_cmd_wstrb,
    input[P_ADDR_WIDTH - 1 : 0]         icb_cmd_addr,
    input[P_DATA_WIDTH - 1 : 0]         icb_cmd_wdata,
    input[2 : 0]                        icb_cmd_size,
    output                              icb_rsp_vld,
    input                               icb_rsp_rdy,
    output[P_DATA_WIDTH - 1 : 0]        icb_rsp_rdata,
    output                              icb_rsp_err,

    // APB总线接口
    output                              psel,
    output                              penable,
    output                              pwrite,
    output[P_ADDR_WIDTH - 1 : 0]        paddr,
    output[P_DATA_WIDTH - 1 : 0]        pwdata,
    output[(P_DATA_WIDTH/8) - 1 : 0]    pstrb,
    input                               pready,
    input                               pslverr,
    input[P_DATA_WIDTH - 1 : 0]         prdata
);

localparam                              LP_ICB_RSP_BUF_DATA_WIDTH = P_DATA_WIDTH + 1;

reg                                     penable_q;
wire                                    penable_set;
wire                                    penable_clr;
wire                                    penable_rld;
wire                                    penable_d;


wire                                    icb_cmd_vld_bufed;
wire                                    icb_cmd_rdy_bufed;
wire                                    icb_cmd_write_bufed;
wire[P_ADDR_WIDTH - 1 : 0]              icb_cmd_addr_bufed;
wire[P_DATA_WIDTH - 1 : 0]              icb_cmd_wdata_bufed;
wire[(P_DATA_WIDTH/8) - 1 : 0]          icb_cmd_wstrb_bufed;
wire[2 : 0]                             icb_cmd_size_bufed;
wire                                    icb_rsp_vld_bufed;
wire                                    icb_rsp_rdy_bufed;
wire[P_DATA_WIDTH - 1 : 0]              icb_rsp_rdata_bufed;
wire                                    icb_rsp_err_bufed;

wire                                    apb_hsked;

assign      apb_hsked = psel & penable & pready;

// 插入buff
lnrv_icb_slice#
(
    .P_ADDR_WIDTH                   ( P_ADDR_WIDTH              ),
    .P_DATA_WIDTH                   ( P_DATA_WIDTH              ),

    .P_CMD_CUT_VALID                ( P_CMD_CUT_VALID           ),
    .P_CMD_CUT_READY                ( P_CMD_CUT_READY           ),
    .P_CMD_BUF_DEEPTH               ( P_OTS_COUNT               ),

    .P_RSP_CUT_VALID                ( P_RSP_CUT_VALID           ),
    .P_RSP_CUT_READY                ( P_RSP_CUT_READY           ),
    .P_RSP_BUF_DEEPTH               ( P_OTS_COUNT               ),

    .P_OTS_COUNT                    ( 0                         ),
    .P_OTS_CTRL_ENABLE              ( 1'b0                      ),
    .P_FLUSH_ENABLE                 ( 1'b0                      )
)
u_lnrv_icb_buf
(
    .flush_req                      ( 1'b0                      ),
    .flush_ack                      (                           ),

    .icb_cmd_vld_m                  ( icb_cmd_vld               ),
    .icb_cmd_rdy_m                  ( icb_cmd_rdy               ),
    .icb_cmd_write_m                ( icb_cmd_write             ),
    .icb_cmd_addr_m                 ( icb_cmd_addr              ),
    .icb_cmd_wdata_m                ( icb_cmd_wdata             ),
    .icb_cmd_wstrb_m                ( icb_cmd_wstrb             ),
    .icb_cmd_size_m                 ( icb_cmd_size              ),
    .icb_rsp_vld_m                  ( icb_rsp_vld               ),
    .icb_rsp_rdy_m                  ( icb_rsp_rdy               ),
    .icb_rsp_rdata_m                ( icb_rsp_rdata             ),
    .icb_rsp_err_m                  ( icb_rsp_err               ),

    .icb_cmd_vld_s                  ( icb_cmd_vld_bufed         ),
    .icb_cmd_rdy_s                  ( icb_cmd_rdy_bufed         ),
    .icb_cmd_write_s                ( icb_cmd_write_bufed       ),
    .icb_cmd_addr_s                 ( icb_cmd_addr_bufed        ),
    .icb_cmd_wdata_s                ( icb_cmd_wdata_bufed       ),
    .icb_cmd_wstrb_s                ( icb_cmd_wstrb_bufed       ),
    .icb_cmd_size_s                 ( icb_cmd_size_bufed        ),
    .icb_rsp_vld_s                  ( icb_rsp_vld_bufed         ),
    .icb_rsp_rdy_s                  ( icb_rsp_rdy_bufed         ),
    .icb_rsp_rdata_s                ( icb_rsp_rdata_bufed       ),
    .icb_rsp_err_s                  ( icb_rsp_err_bufed         ),

    .clk                            ( clk                       ),
    .reset_n                        ( reset_n                   )
);


// 在指令有效，且penable没有拉高，同时rsp buf中有空位的情况下，才可以发送apb操作
assign      penable_set = psel & (~penable_q);
assign      penable_clr = apb_hsked;
assign      penable_rld = penable_set | penable_clr;
assign      penable_d = (~penable_clr);
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        penable_q <= 1'b0;
    end else if(penable_rld) begin
        penable_q <= penable_d;
    end
end


assign      icb_cmd_rdy_bufed   = apb_hsked;

assign      icb_rsp_vld_bufed   = apb_hsked;
assign      icb_rsp_rdata_bufed = prdata;
assign      icb_rsp_err_bufed   = pslverr;


// 可以接收response才发送apb操作
assign      psel        = icb_cmd_vld_bufed & icb_rsp_rdy_bufed;
assign      penable     = penable_q;
assign      paddr       = icb_cmd_addr;
assign      pwrite      = icb_cmd_write;
assign      pwdata      = icb_cmd_wdata;

endmodule