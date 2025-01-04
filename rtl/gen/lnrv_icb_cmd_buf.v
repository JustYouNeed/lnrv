module icb_cmd_buf_lnrv#
(
    parameter                           P_BUFF_ENABLE = "true",
    parameter                           P_BUFF_CUT_READY = "true",
    parameter                           P_BUFF_BYPASS = "false",
    parameter                           P_OTS_COUNT = 1,

    parameter                           P_ADDR_WIDTH = 32,
    parameter                           P_DATA_WIDTH = 32
)
(
    input                               icb_cmd_vld_m,
    output                              icb_cmd_rdy_m,
    input                               icb_cmd_write_m,
    input[P_ADDR_WIDTH - 1 : 0]         icb_cmd_addr_m,
    input[P_DATA_WIDTH - 1 : 0]         icb_cmd_wdata_m,
    input[(P_DATA_WIDTH/8) - 1 : 0]     icb_cmd_wstrb_m,
    input[2 : 0]                        icb_cmd_size_m,

    output                              icb_cmd_vld_s,
    input                               icb_cmd_rdy_s,
    output                              icb_cmd_write_s,
    output[P_ADDR_WIDTH - 1 : 0]        icb_cmd_addr_s,
    output[P_DATA_WIDTH - 1 : 0]        icb_cmd_wdata_s,
    output[(P_DATA_WIDTH/8) - 1 : 0]    icb_cmd_wstrb_s,
    output[2 : 0]                       icb_cmd_size_s,

    input                               clk,
    input                               reset_n
);


localparam                  LP_WSTRB_WIDTH = P_DATA_WIDTH/8;
localparam                  LP_BUF_WIDTH = P_ADDR_WIDTH + P_DATA_WIDTH + LP_WSTRB_WIDTH + 1 + 3;


generate
    if(P_BUFF_ENABLE == "true") begin
        wire[LP_BUF_WIDTH - 1 : 0]          buf_push_data;
        wire                                buf_push_vld;
        wire                                buf_push_rdy;

        wire[LP_BUF_WIDTH - 1 : 0]          buf_pop_data;
        wire                                buf_pop_vld;
        wire                                buf_pop_rdy;


        assign      buf_push_vld = icb_cmd_vld_m;
        assign      buf_push_data = {
                                        icb_cmd_write_m,
                                        icb_cmd_wdata_m,
                                        icb_cmd_wstrb_m,
                                        icb_cmd_size_m,
                                        icb_cmd_addr_m
                                    };
        assign      icb_cmd_rdy_m = buf_push_rdy;

        assign      buf_pop_rdy = icb_cmd_rdy_s;
        assign      {
                        icb_cmd_write_s,
                        icb_cmd_wdata_s,
                        icb_cmd_wstrb_s,
                        icb_cmd_size_s,
                        icb_cmd_addr_s
                    } = buf_pop_data;
        assign      icb_cmd_vld_s = buf_pop_vld;

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
        assign      icb_cmd_vld_s   = icb_cmd_vld_m;
        assign      icb_cmd_write_s = icb_cmd_write_m;
        assign      icb_cmd_addr_s  = icb_cmd_addr_m;
        assign      icb_cmd_wdata_s = icb_cmd_wdata_m;
        assign      icb_cmd_wstrb_s = icb_cmd_wstrb_m;
        assign      icb_cmd_size_s  = icb_cmd_size_m;

        assign      icb_cmd_rdy_m   = icb_cmd_rdy_s;
    end
endgenerate

endmodule
