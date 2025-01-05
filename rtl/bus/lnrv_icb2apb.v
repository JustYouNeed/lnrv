module  lnrv_icb2apb#
(
    parameter                           P_ADDR_WIDTH = 32,
    parameter                           P_DATA_WIDTH = 32,

    parameter                           P_OTS_COUNT = 1
)
(
    input                               clk,
    input                               reset_n,

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

wire                                    icb_rsp_buf_push_vld;
wire                                    icb_rsp_buf_push_rdy;
wire[LP_ICB_RSP_BUF_DATA_WIDTH - 1 : 0] icb_rsp_buf_push_data;

wire                                    icb_rsp_buf_pop_vld;
wire                                    icb_rsp_buf_pop_rdy;
wire[LP_ICB_RSP_BUF_DATA_WIDTH - 1 : 0] icb_rsp_buf_pop_data;

wire                                    apb_hsked;

assign      apb_hsked = psel & penable & pready;


// 在指令有效，且penable没有拉高，同时rsp buf中有空位的情况下，才可以发送apb操作
assign      penable_set = psel & (~penable_q);
assign      penable_clr = icb_cmd_rdy;
assign      penable_rld = penable_set | penable_clr;
assign      penable_d = (~penable_clr);
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        penable_q <= 1'b0;
    end else if(penable_rld) begin
        penable_q <= penable_d;
    end
end


assign      icb_rsp_buf_push_data = {
                                        prdata,
                                        pslverr
                                    };
assign      icb_rsp_buf_push_vld = apb_hsked;

assign      icb_rsp_buf_pop_rdy = icb_rsp_rdy;

lnrv_gnrl_buffer#
(
    .P_DATA_WIDTH       ( LP_ICB_RSP_BUF_DATA_WIDTH     ),
    .P_DEEPTH           ( P_OTS_COUNT                   ),
    .P_CUT_READY        ( "false"                       ),
    .P_BYPASS           ( "false"                       )
)
u_icb_rsp_buf
(
    .clk                ( clk                           ),
    .reset_n            ( reset_n                       ),

    .flush_req          ( 1'b0                          ),
    .flush_ack          (                               ),

    .push_vld           ( icb_rsp_buf_push_vld          ),
    .push_rdy           ( icb_rsp_buf_push_rdy          ),
    .push_data          ( icb_rsp_buf_push_data         ),

    .pop_vld            ( icb_rsp_buf_pop_vld           ),
    .pop_rdy            ( icb_rsp_buf_pop_rdy           ),
    .pop_data           ( icb_rsp_buf_pop_data          )
);


assign      icb_cmd_rdy = penable_q & pready;

assign      icb_rsp_vld = icb_rsp_buf_pop_vld;
assign      {
                icb_rsp_rdata,
                icb_rsp_err
            } = icb_rsp_buf_pop_data;

assign      psel        = icb_cmd_vld & icb_rsp_buf_push_rdy;
assign      penable     = penable_q;
assign      paddr       = icb_cmd_addr;
assign      pwrite      = icb_cmd_write;
assign      pwdata      = icb_cmd_wdata;

endmodule