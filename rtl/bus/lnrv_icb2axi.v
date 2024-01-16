module lnrv_icb2axi#
(
    parameter                   P_ADDR_WIDTH = 32,
    parameter                   P_DATA_WIDTH = 32
)
(
    input                               icb_cmd_vld,
    output                              icb_cmd_rdy,
    input                               icb_cmd_write,
    input[P_ADDR_WIDTH - 1 : 0]         icb_cmd_addr,
    input[P_DATA_WIDTH - 1 : 0]         icb_cmd_wdata,
    input[(P_DATA_WIDTH/8) - 1 : 0]     icb_cmd_wstrb,
    input                               icb_rsp_rdy,
    output                              icb_rsp_vld,
    output                              icb_rsp_err,
    output[P_DATA_WIDTH - 1 : 0]        icb_rsp_rdata,


    output                              axi_awvalid,
    input                               axi_awready,
    output                              axi_awlock,
    output[P_ADDR_WIDTH - 1 : 0]        axi_awaddr,
    output[3 : 0]                       axi_awid,
    output[7 : 0]                       axi_awlen,
    output[2 : 0]                       axi_awsize,
    output[1 : 0]                       axi_awburst,
    output[3 : 0]                       axi_awcache,
    output[2 : 0]                       axi_awprot,

    output                              axi_wvalid,
    input                               axi_wready,
    output[P_DATA_WIDTH - 1 : 0]        axi_wdata,
    output[(P_DATA_WIDTH/8) - 1 : 0]    axi_wstrb,
    output                              axi_wlast,

    output                              axi_bready,
    input                               axi_bvalid,
    input[1 : 0]                        axi_bresp,
    input[3 : 0]                        axi_bid,

    output                              axi_arvalid,
    input                               axi_arready,
    output                              axi_arlock,
    output[P_ADDR_WIDTH - 1 : 0]        axi_araddr,
    output[3 : 0]                       axi_arid,
    output[7 : 0]                       axi_arlen,
    output[2 : 0]                       axi_arsize,
    output[1 : 0]                       axi_arburst,
    output[3 : 0]                       axi_arcache,
    output[2 : 0]                       axi_arprot,

    output                              axi_rready,
    input                               axi_rvalid,
    input[P_DATA_WIDTH - 1 : 0]         axi_rdata,
    input[1 : 0]                        axi_rresp,
    input                               axi_rlast,
    input[3 : 0]                        axi_rid,

    input                               clk,
    input                               reset_n
);

wire                                s_icb_cmd_vld;
wire                                s_icb_cmd_rdy;
wire                                s_icb_cmd_write;
wire[P_ADDR_WIDTH - 1 : 0]          s_icb_cmd_addr;
wire[P_DATA_WIDTH - 1 : 0]          s_icb_cmd_wdata;
wire[(P_DATA_WIDTH/8) - 1 : 0]      s_icb_cmd_wstrb;
wire                                s_icb_rsp_vld;
wire                                s_icb_rsp_rdy;
wire[P_DATA_WIDTH - 1 : 0]          s_icb_rsp_rdata;
wire                                s_icb_rsp_err;

wire                                icb_write;
wire                                icb_read;
wire                                icb_byte_access;
wire                                icb_half_access;
wire                                icb_word_access;

reg                                 aw_hsked_q;
wire                                aw_hsked_set;
wire                                aw_hsked_clr;
wire                                aw_hsked_rld;
wire                                aw_hsked_d;


reg                                 w_hsked_q;
wire                                w_hsked_set;
wire                                w_hsked_clr;
wire                                w_hsked_rld;
wire                                w_hsked_d;


reg                                 ar_hsked_q;
wire                                ar_hsked_set;
wire                                ar_hsked_clr;
wire                                ar_hsked_rld;
wire                                ar_hsked_d;

wire                                no_aw_ots;
wire                                no_w_ots;
wire                                no_ar_ots;
wire                                axi_read_ots;
wire                                axi_write_ots;

assign      no_aw_ots = (~aw_hsked_q) | aw_hsked_clr;
assign      no_w_ots = (~w_hsked_q) | w_hsked_clr;
assign      no_ar_ots = (~ar_hsked_q) | axi_r_hsked;


assign      aw_hsekd_set = axi_aw_hsked;
assign      aw_hsked_clr = axi_b_hsked;
assign      aw_hsked_rld = aw_hsekd_set | aw_hsked_clr;
assign      aw_hsked_d = aw_hsekd_set;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        aw_hsked_q <= 1'b0;
    end else if(aw_hsked_rld) begin
        aw_hsked_q <= aw_hsked_d;
    end
end

assign      w_hsekd_set = axi_w_hsked;
assign      w_hsked_clr = axi_b_hsked;
assign      w_hsked_rld = w_hsekd_set | w_hsked_clr;
assign      w_hsked_d = w_hsekd_set;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        w_hsked_q <= 1'b0;
    end else if(w_hsked_rld) begin
        w_hsked_q <= w_hsked_d;
    end
end

assign      ar_hsekd_set = axi_ar_hsked;
assign      ar_hsked_clr = axi_r_hsked;
assign      ar_hsked_rld = ar_hsekd_set | ar_hsked_clr;
assign      ar_hsked_d = ar_hsekd_set;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        ar_hsked_q <= 1'b0;
    end else if(ar_hsked_rld) begin
        ar_hsked_q <= ar_hsked_d;
    end
end


lnrv_icb_buf#
(
    .P_ADDR_WIDTH               ( P_DATA_WIDTH          ),
    .P_DATA_WIDTH               ( P_ADDR_WIDTH          ),
    .P_CMD_BUFF_ENABLE          ( "true"                ),
    .P_CMD_BUFF_CUT_READY       ( "true"                ),
    .P_CMD_BUFF_BYPASS          ( "false"               ),
    .P_RSP_BUFF_ENABLE          ( "true"                ),
    .P_RSP_BUFF_CUT_READY       ( "true"                ),
    .P_RSP_BUFF_BYPASS          ( "false"               ),
    .P_OTS_COUNT                ( 1                     )
)
u_lnrv_icb_buf
(
    .m_icb_cmd_vld              ( icb_cmd_vld           ),
    .m_icb_cmd_rdy              ( icb_cmd_rdy           ),
    .m_icb_cmd_write            ( icb_cmd_write         ),
    .m_icb_cmd_addr             ( icb_cmd_addr          ),
    .m_icb_cmd_wdata            ( icb_cmd_wdata         ),
    .m_icb_cmd_wstrb            ( icb_cmd_wstrb         ),
    .m_icb_rsp_vld              ( icb_rsp_vld           ),
    .m_icb_rsp_rdy              ( icb_rsp_rdy           ),
    .m_icb_rsp_rdata            ( icb_rsp_rdata         ),
    .m_icb_rsp_err              ( icb_rsp_err           ),

    .s_icb_cmd_vld              ( s_icb_cmd_vld         ),
    .s_icb_cmd_rdy              ( s_icb_cmd_rdy         ),
    .s_icb_cmd_write            ( s_icb_cmd_write       ),
    .s_icb_cmd_addr             ( s_icb_cmd_addr        ),
    .s_icb_cmd_wdata            ( s_icb_cmd_wdata       ),
    .s_icb_cmd_wstrb            ( s_icb_cmd_wstrb       ),
    .s_icb_rsp_vld              ( s_icb_rsp_vld         ),
    .s_icb_rsp_rdy              ( s_icb_rsp_rdy         ),
    .s_icb_rsp_rdata            ( s_icb_rsp_rdata       ),
    .s_icb_rsp_err              ( s_icb_rsp_err         ),

    .clk                        ( clk                   ),
    .reset_n                    ( reset_n               )
);

assign      icb_write = s_icb_cmd_vld & s_icb_cmd_write;
assign      axi_read_ots = ar_hsked_q;
assign      axi_write_ots = aw_hsked_q & w_hsekd_q;

assign      axi_awvalid = icb_write & no_aw_ots;
// 固定为INCR传输
assign      axi_awburst = 2'b01;
assign      axi_awsize = s_icb_cmd_size;
assign      axi_awlen = 0;
assign      axi_awaddr = s_icb_cmd_addr;
assign      axi_awcache = 4'b0000;
assign      axi_awlock = 1'b0;
assign      axi_awprot = 3'b000;
assign      axi_awid = 4'd0;


assign      axi_wvalid = icb_write & no_w_ots;
assign      axi_wdata = s_icb_cmd_wdata;
assign      axi_wstrb = s_icb_cmd_wstrb;
assign      axi_wlast = axi_wvalid;

assign      axi_bready = axi_write_ots & s_icb_rsp_rdy;


assign      axi_arvalid = icb_read & no_ar_ots;
// 固定为INCR传输
assign      axi_arburst = 2'b01;
assign      axi_arsize = s_icb_cmd_size;
assign      axi_arlen = 0;
assign      axi_araddr = s_icb_cmd_addr;
assign      axi_arcache = 4'b0000;
assign      axi_arlock = 1'b0;
assign      axi_arprot = 3'b000;
assign      axi_arid = 4'd0;


assign      axi_rready = axi_read_ots & s_icb_rsp_rdy;

assign      s_icb_rsp_vld = (axi_write_ots & axi_bvalid) | 
                            (axi_read_ots & axi_rvalid);

assign      s_icb_rsp_rdata = axi_rdata;
assign      s_icb_rsp_err = (axi_write_ots & axi_bresp[0]) | 
                            (axi_read_ots & axi_rresp[0]);

endmodule