module lnrv_axi2icb#
(
    parameter                           P_ADDR_WIDTH = 32,
    parameter                           P_DATA_WIDTH = 32
)
(
    // icb
    output                              icb_cmd_vld,
    input                               icb_cmd_rdy,
    output                              icb_cmd_write,
    output[P_ADDR_WIDTH - 1 : 0]        icb_cmd_addr,
    output[P_DATA_WIDTH - 1 : 0]        icb_cmd_wdata,
    output[(P_DATA_WIDTH/8) - 1 : 0]    icb_cmd_wstrb,
    output[2 : 0]                       icb_cmd_size,
    output                              icb_rsp_rdy,
    input                               icb_rsp_vld,
    input                               icb_rsp_err,
    input[P_DATA_WIDTH - 1 : 0]         icb_rsp_rdata,

    // axi4
    input                               axi_awvalid,
    output                              axi_awready,
    input                               axi_awlock,
    input[P_ADDR_WIDTH - 1 : 0]         axi_awaddr,
    input[3 : 0]                        axi_awid,
    input[7 : 0]                        axi_awlen,
    input[2 : 0]                        axi_awsize,
    input[1 : 0]                        axi_awburst,
    input[3 : 0]                        axi_awcache,
    input[2 : 0]                        axi_awprot,

    input                               axi_wvalid,
    output                              axi_wready,
    input[P_DATA_WIDTH - 1 : 0]         axi_wdata,
    input[(P_DATA_WIDTH/8) - 1 : 0]     axi_wstrb,
    input                               axi_wlast,

    input                               axi_bready,
    output                              axi_bvalid,
    output[1 : 0]                       axi_bresp,
    output[3 : 0]                       axi_bid,

    input                               axi_arvalid,
    output                              axi_arready,
    input                               axi_arlock,
    input[P_ADDR_WIDTH - 1 : 0]         axi_araddr,
    input[3 : 0]                        axi_arid,
    input[7 : 0]                        axi_arlen,
    input[2 : 0]                        axi_arsize,
    input[1 : 0]                        axi_arburst,
    input[3 : 0]                        axi_arcache,
    input[2 : 0]                        axi_arprot,

    input                               axi_rready,
    output                              axi_rvalid,
    output[P_DATA_WIDTH - 1 : 0]        axi_rdata,
    output[1 : 0]                       axi_rresp,
    output                              axi_rlast,
    output[3 : 0]                       axi_rid,

    input                               clk,
    input                               reset_n
);

// addr + write/read + id + len + size + burst + cache + prot + lock
localparam                              LP_AXI_XFR_BUF_WIDTH = P_ADDR_WIDTH + 1 + 4 + 8 + 3 + 2 + 4 + 3 + 1;

wire[1 : 0]                             arbt_request;
wire[1 : 0]                             arbt_grant;


wire[LP_AXI_XFR_BUF_WIDTH - 1 : 0]      axi_aw_info;
wire[LP_AXI_XFR_BUF_WIDTH - 1 : 0]      axi_ar_info;

wire                                    axi_lock_bufed;
wire[P_ADDR_WIDTH - 1 : 0]              axi_addr_bufed;
wire[3 : 0]                             axi_id_bufed;
wire[7 : 0]                             axi_len_bufed;
wire[2 : 0]                             axi_size_bufed;
wire[1 : 0]                             axi_burst_bufed;
wire[3 : 0]                             axi_cache_bufed;
wire[2 : 0]                             axi_prot_bufed;

wire                                    axi_xfr_buf_push_vld;
wire                                    axi_xfr_buf_push_rdy;
wire[LP_AXI_XFR_BUF_WIDTH - 1 : 0]      axi_xfr_buf_push_data;
wire                                    axi_xfr_buf_pop_vld;
wire                                    axi_xfr_buf_pop_rdy;
wire[LP_AXI_XFR_BUF_WIDTH - 1 : 0]      axi_xfr_buf_pop_data;

wire                                    axi_xfr_type;
wire                                    axi_write_xfr;
wire                                    axi_read_xfr;
wire                                    axi_xfr_cplt;
wire                                    axi_xfr_info_vld;


reg[7 : 0]                              axi_xfr_cnt_q;
wire                                    axi_xfr_cnt_inc;
wire                                    axi_xfr_cnt_clr;
wire                                    axi_xfr_cnt_rld;
wire[7 : 0]                             axi_xfr_cnt_d;





assign      arbt_request = {2{axi_xfr_buf_push_rdy}} & {axi_awvalid, axi_arvalid};

// 对aw和ar通道进行仲裁，选择一个通道的信息保存到buf中
lnrv_gnrl_arbiter#
(
    .P_ARBT_NUM         ( 2                         ),
    .P_ARBT_TYPE        ( "round-robin"             )
)       
u_lnrv_gnrl_arbiter     
(       
    .request            ( arbt_request              ),
    .grant              ( arbt_grant                ),

    .clk                ( clk                       ),
    .reset_n            ( reset_n                   )
);


assign      axi_aw_info =   {
                                1'b1,           // 写操作
                                axi_awlock,
                                axi_awaddr,
                                axi_awid,
                                axi_awlen,
                                axi_awsize,
                                axi_awburst,
                                axi_awcache,
                                axi_awprot
                            };

assign      axi_ar_info =   {
                                1'b0,           // 读操作
                                axi_arlock,
                                axi_araddr,
                                axi_arid,
                                axi_arlen,
                                axi_arsize,
                                axi_arburst,
                                axi_arcache,
                                axi_arprot
                            };


assign      axi_xfr_buf_push_vld = axi_awvalid | axi_arvalid;
assign      axi_xfr_buf_push_data = ({LP_AXI_XFR_BUF_WIDTH{arbt_grant[0]}} & axi_ar_info) | 
                                    ({LP_AXI_XFR_BUF_WIDTH{arbt_grant[1]}} & axi_aw_info);

// 处理完一个axi读或者写传输后，从buf从弹出信息
assign      axi_xfr_buf_pop_rdy = axi_xfr_cplt;
assign      {
                axi_xfr_type,
                axi_lock_bufed,
                axi_addr_bufed,
                axi_id_bufed,
                axi_len_bufed,
                axi_size_bufed,
                axi_burst_bufed,
                axi_cache_bufed,
                axi_prot_bufed
            } = axi_xfr_buf_pop_data;

assign      axi_xfr_buf_push_hsked = axi_xfr_buf_push_vld & axi_xfr_buf_push_rdy;
assign      axi_xfr_buf_pop_hsked = axi_xfr_buf_pop_vld & axi_xfr_buf_pop_rdy;


// 保存aw/ar通道的控制信息
lnrv_gnrl_buffer#
(
    .P_DATA_WIDTH       ( LP_AXI_XFR_BUF_WIDTH      ),
    .P_DEEPTH           ( 1                         ),
    .P_CUT_READY        ( "true"                    ),
    .P_BYPASS           ( "false"                   )
)       
u_axi_xfr_buf        
(       
    .clk                ( clk                       ),
    .reset_n            ( reset_n                   ),

    .flush_req          ( 1'b0                      ),
    .flush_ack          (                           ),

    .push_vld           ( axi_xfr_buf_push_vld      ),
    .push_rdy           ( axi_xfr_buf_push_rdy      ),
    .push_data          ( axi_xfr_buf_push_data     ),

    .pop_vld            ( axi_xfr_buf_pop_vld       ),
    .pop_rdy            ( axi_xfr_buf_pop_rdy       ),
    .pop_data           ( axi_xfr_buf_pop_data      )
);



// 统计axi传输的数据量
assign      axi_xfr_cnt_inc = icb_rsp_hsked;
assign      axi_xfr_cnt_clr = axi_xfr_buf_pop_hsked;
assign      axi_xfr_cnt_rld = axi_xfr_cnt_inc | axi_xfr_cnt_clr;
assign      axi_xfr_cnt_d = axi_xfr_cnt_clr ? 8'd0 : (axi_xfr_cnt_q + 1'b1);
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        axi_xfr_cnt_q <= 8'd0;
    end else if(axi_xfr_cnt_rld) begin
        axi_xfr_cnt_q <= axi_xfr_cnt_d;
    end
end

// 最后一笔传输
assign      axi_xfr_last = (axi_xfr_cnt_q == axi_len_bufed);
assign      axi_xfr_cplt = axi_xfr_last & icb_rsp_hsked;


assign      axi_write_xfr = axi_xfr_type;
assign      axi_read_xfr = (~axi_xfr_type);

assign      axi_xfr_info_vld = axi_xfr_buf_pop_vld;
assign      axi_write_xfr_vld = axi_write_xfr & axi_xfr_info_vld;
assign      axi_read_xfr_vld = axi_read_xfr & axi_xfr_info_vld;

// 由于ICB总线只有一个command通道，与写通道共用，因此如果是AXI写操作，则需要等W通道的数据有效，才可以发送command
// 如果是读操作，则可以直接发送command
assign      icb_send_cmd_allow =    (axi_write_xfr & axi_wvalid) | 
                                    axi_read_xfr;

// 对于ICB总线，每个传输都会有一个地址信息，如果AXI传输信息有效，同时ots队列没有满，则可以继续发送指令
assign      icb_cmd_vld = axi_xfr_info_vld & ots_queue_not_full & icb_send_cmd_allow;
assign      icb_cmd_size = axi_size_bufed;
assign      icb_cmd_wstrb = {(P_DATA_WIDTH/8){axi_write_xfr}} & axi_wstrb;
assign      icb_cmd_wdata = axi_wdata;
assign      icb_cmd_addr = axi_addr_bufed + ({8'd0, axi_xfr_cnt_q} << axi_size_bufed);

//
assign      axi_awready = axi_xfr_buf_push_rdy & arbt_grant[1];

//
assign      axi_wready = axi_write_xfr_vld & icb_rsp_vld;

//
assign      axi_bvalid      = bvalid_q;
assign      axi_bid         = axi_id_bufed;
assign      axi_bresp[1]    = 1'b0;
assign      axi_bresp[0]    = axi_write_err_q;

//
assign      axi_arready = axi_xfr_buf_push_rdy & arbt_grant[0];

// 
assign      axi_rdata   = {P_DATA_WIDTH{axi_read_xfr_vld}} & icb_rsp_rdata;
assign      axi_rvalid  = axi_read_xfr_vld & icb_rsp_vld;
assign      axi_rlast   = axi_read_xfr_vld & axi_xfr_last;
assign      axi_rid     = {4{axi_read_xfr_vld}} & axi_id_bufed;
assign      axi_rresp[1] = 1'b0;
assign      axi_rresp[0] = axi_read_xfr_vld & icb_rsp_err;

endmodule