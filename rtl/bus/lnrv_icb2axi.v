module lnrv_icb2axi#
(
    parameter                           P_ADDR_WIDTH = 32,
    parameter                           P_DATA_WIDTH = 32
)
(
    input                               icb_cmd_vld,
    output                              icb_cmd_rdy,
    input                               icb_cmd_write,
    input[P_ADDR_WIDTH - 1 : 0]         icb_cmd_addr,
    input[P_DATA_WIDTH - 1 : 0]         icb_cmd_wdata,
    input[(P_DATA_WIDTH/8) - 1 : 0]     icb_cmd_wstrb,
    input[2 : 0]                        icb_cmd_size,
    input[2 : 0]                        icb_cmd_prot,
    input[3 : 0]                        icb_cmd_cache,
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

wire                                icb_cmd_vld_s;
wire                                icb_cmd_rdy_s;
wire                                icb_cmd_write_s;
wire[P_ADDR_WIDTH - 1 : 0]          icb_cmd_addr_s;
wire[P_DATA_WIDTH - 1 : 0]          icb_cmd_wdata_s;
wire[(P_DATA_WIDTH/8) - 1 : 0]      icb_cmd_wstrb_s;
wire[2: 0]                          icb_cmd_size_s;
wire                                icb_rsp_vld_s;
wire                                icb_rsp_rdy_s;
wire[P_DATA_WIDTH - 1 : 0]          icb_rsp_rdata_s;
wire                                icb_rsp_err_s;

wire                                icb_write_vld;
wire                                icb_read_vld;
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

wire                                axi_ar_hsked;
wire                                axi_aw_hsked;
wire                                axi_b_hsked;
wire                                axi_r_hsked;
wire                                axi_w_hsked;

wire                                no_aw_ots;
wire                                no_w_ots;
wire                                no_ar_ots;
wire                                axi_read_ots;
wire                                axi_write_ots;

assign      no_aw_ots = (~aw_hsked_q) | aw_hsked_clr;
assign      no_w_ots = (~w_hsked_q) | w_hsked_clr;
assign      no_ar_ots = (~ar_hsked_q) | axi_r_hsked;

// 先在icb路径上插入一个buff
lnrv_icb_buf#
(
    .P_ADDR_WIDTH               ( P_DATA_WIDTH          ),
    .P_DATA_WIDTH               ( P_ADDR_WIDTH          ),

    .P_CMD_BUFF_ENABLE          ( 1'b1                  ),
    .P_CMD_BUFF_CUT_READY       ( 1'b1                  ),
    .P_CMD_BUFF_BYPASS          ( 1'b0                  ),
    .P_CMD_OTS_COUNT            ( 1                     ),

    .P_RSP_BUFF_ENABLE          ( 1'b1                  ),
    .P_RSP_BUFF_CUT_READY       ( 1'b1                  ),
    .P_RSP_BUFF_BYPASS          ( 1'b0                  ),
    .P_RSP_OTS_COUNT            ( 1                     )
)
u_lnrv_icb_buf
(
    .icb_cmd_vld_m              ( icb_cmd_vld           ),
    .icb_cmd_rdy_m              ( icb_cmd_rdy           ),
    .icb_cmd_write_m            ( icb_cmd_write         ),
    .icb_cmd_addr_m             ( icb_cmd_addr          ),
    .icb_cmd_wdata_m            ( icb_cmd_wdata         ),
    .icb_cmd_wstrb_m            ( icb_cmd_wstrb         ),
    .icb_cmd_size_m             ( icb_cmd_size          ),
    .icb_rsp_vld_m              ( icb_rsp_vld           ),
    .icb_rsp_rdy_m              ( icb_rsp_rdy           ),
    .icb_rsp_rdata_m            ( icb_rsp_rdata         ),
    .icb_rsp_err_m              ( icb_rsp_err           ),

    .icb_cmd_vld_s              ( icb_cmd_vld_s         ),
    .icb_cmd_rdy_s              ( icb_cmd_rdy_s         ),
    .icb_cmd_write_s            ( icb_cmd_write_s       ),
    .icb_cmd_addr_s             ( icb_cmd_addr_s        ),
    .icb_cmd_wdata_s            ( icb_cmd_wdata_s       ),
    .icb_cmd_wstrb_s            ( icb_cmd_wstrb_s       ),
    .icb_cmd_size_s             ( icb_cmd_size_s        ),
    .icb_rsp_vld_s              ( icb_rsp_vld_s         ),
    .icb_rsp_rdy_s              ( icb_rsp_rdy_s         ),
    .icb_rsp_rdata_s            ( icb_rsp_rdata_s       ),
    .icb_rsp_err_s              ( icb_rsp_err_s         ),

    .clk                        ( clk                   ),
    .reset_n                    ( reset_n               )
);


assign      axi_aw_hsked = axi_awvalid & axi_awready;
assign      axi_ar_hsked = axi_arvalid & axi_arready;
assign      axi_w_hsked = axi_wvalid & axi_wready;
assign      axi_b_hsked = axi_bvalid & axi_bready;
assign      axi_r_hsked = axi_rvalid & axi_rready;

// 保存aw通道的握手信息
assign      aw_hsked_set = axi_aw_hsked;
assign      aw_hsked_clr = axi_b_hsked;
assign      aw_hsked_rld = aw_hsked_set | aw_hsked_clr;
assign      aw_hsked_d = aw_hsked_set;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        aw_hsked_q <= 1'b0;
    end else if(aw_hsked_rld) begin
        aw_hsked_q <= aw_hsked_d;
    end
end

assign      w_hsked_set = axi_w_hsked;
assign      w_hsked_clr = axi_b_hsked;
assign      w_hsked_rld = w_hsked_set | w_hsked_clr;
assign      w_hsked_d = w_hsked_set;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        w_hsked_q <= 1'b0;
    end else if(w_hsked_rld) begin
        w_hsked_q <= w_hsked_d;
    end
end

assign      ar_hsked_set = axi_ar_hsked;
assign      ar_hsked_clr = axi_r_hsked;
assign      ar_hsked_rld = ar_hsked_set | ar_hsked_clr;
assign      ar_hsked_d = ar_hsked_set;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        ar_hsked_q <= 1'b0;
    end else if(ar_hsked_rld) begin
        ar_hsked_q <= ar_hsked_d;
    end
end


assign      icb_write_vld   = icb_cmd_vld_s & icb_cmd_write_s;
assign      icb_read_vld    = icb_cmd_vld_s & (~icb_cmd_write_s);

assign      axi_read_ots    = ar_hsked_q;
assign      axi_write_ots   = aw_hsked_q & w_hsked_q;

assign      axi_awvalid     = icb_write_vld & no_aw_ots;
assign      axi_awburst     = 2'b01;                    // 固定为INCR传输
assign      axi_awsize      = icb_cmd_size_s;
assign      axi_awlen       = 8'd0;                     // 单笔传输
assign      axi_awaddr      = icb_cmd_addr_s;
assign      axi_awcache     = 4'b0000;
assign      axi_awlock      = 1'b0;
assign      axi_awprot      = 3'b000;
assign      axi_awid        = 4'd0;


assign      axi_wvalid      = icb_write_vld & no_w_ots;
assign      axi_wdata       = icb_cmd_wdata_s;
assign      axi_wstrb       = icb_cmd_wstrb_s;
assign      axi_wlast       = axi_wvalid;

assign      axi_bready      = axi_write_ots & icb_rsp_rdy_s;

assign      axi_arvalid     = icb_read_vld & no_ar_ots;
assign      axi_arburst     = 2'b01;
assign      axi_arsize      = icb_cmd_size_s;
assign      axi_arlen       = 8'd0;
assign      axi_araddr      = icb_cmd_addr_s;
assign      axi_arcache     = 4'b0000;
assign      axi_arlock      = 1'b0;
assign      axi_arprot      = 3'b000;
assign      axi_arid        = 4'd0;


assign      axi_rready = axi_read_ots & icb_rsp_rdy_s;

// icb总线的response通道，如果是写操作，则需要等bvalid
assign      icb_rsp_vld_s = (axi_write_ots & axi_bvalid) |
                            (axi_read_ots & axi_rvalid);

assign      icb_rsp_rdata_s = axi_rdata;
assign      icb_rsp_err_s = (axi_write_ots & axi_bresp[0]) |
                            (axi_read_ots & axi_rresp[0]);

endmodule