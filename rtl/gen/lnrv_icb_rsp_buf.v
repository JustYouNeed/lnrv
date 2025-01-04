
module icb_rsp_buf_lnrv#
(
    parameter                           P_BUFF_ENABLE = "true",
    parameter                           P_BUFF_CUT_READY = "true",
    parameter                           P_BUFF_BYPASS = "false",
    parameter                           P_OTS_COUNT = 1,

    parameter                           P_DATA_WIDTH = 32
)
(
    input                               icb_rsp_vld_s,
    output                              icb_rsp_rdy_s,
    input[P_DATA_WIDTH - 1 : 0]         icb_rsp_rdata_s,
    input                               icb_rsp_err_s,

    output                              icb_rsp_vld_m,
    input                               icb_rsp_rdy_m,
    output[P_DATA_WIDTH - 1 : 0]        icb_rsp_rdata_m,
    output                              icb_rsp_err_m,

    input                               clk,
    input                               reset_n
);


localparam                  LP_BUF_WIDTH = P_DATA_WIDTH + 1;


generate
    if(P_BUFF_ENABLE == "true") begin
        wire[LP_BUF_WIDTH - 1 : 0]          buf_push_data;
        wire                                buf_push_vld;
        wire                                buf_push_rdy;

        wire[LP_BUF_WIDTH - 1 : 0]          buf_pop_data;
        wire                                buf_pop_vld;
        wire                                buf_pop_rdy;


        assign      buf_push_vld = icb_rsp_vld_s;
        assign      buf_push_data = {
                                        icb_rsp_err_s,
                                        icb_rsp_rdata_s
                                    };
        assign      icb_rsp_rdy_s = buf_push_rdy;

        assign      buf_pop_rdy = icb_rsp_rdy_m;
        assign      {
                        icb_rsp_err_m,
                        icb_rsp_rdata_m
                    } = buf_pop_data;
        assign      icb_rsp_vld_m = buf_pop_vld;

        lnrv_gnrl_buffer#
        (
            .P_DATA_WIDTH       ( LP_BUF_WIDTH              ),
            .P_DEEPTH           ( P_OTS_COUNT               ),
            .P_CUT_READY        ( P_BUFF_CUT_READY          ),
            .P_BYPASS           ( P_BUFF_BYPASS             )
        )
        icb_cmd_buff_u
        (
            .clk                ( clk                       ),
            .reset_n            ( reset_n                   ),

            .flush_req          ( 1'b0                      ),
            .flush_ack          (                           ),

            .push_vld           ( buf_push_vld              ),
            .push_rdy           ( buf_push_rdy              ),
            .push_data          ( buf_push_data             ),
            .pop_vld            ( buf_pop_vld               ),
            .pop_rdy            ( buf_pop_rdy               ),
            .pop_data           ( buf_pop_data              )
        );

    end else begin
        assign      icb_rsp_vld_m   = icb_rsp_vld_s;
        assign      icb_rsp_err_m   = icb_rsp_err_s;
        assign      icb_rsp_rdata_m = icb_rsp_rdata_s;

        assign      icb_rsp_rdy_s   = icb_rsp_rdy_m;
    end
endgenerate

endmodule