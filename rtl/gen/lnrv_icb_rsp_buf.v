
module lnrv_icb_rsp_buf#
(
    parameter                           P_BUFF_ENABLE = "true",
    parameter                           P_BUFF_CUT_READY = "true",
    parameter                           P_BUFF_BYPASS = "false",
    parameter                           P_OTS_COUNT = 1,

    parameter                           P_DATA_WIDTH = 32
)
(
    input                               s_icb_rsp_vld,
    output                              s_icb_rsp_rdy,
    input[P_DATA_WIDTH - 1 : 0]         s_icb_rsp_rdata,
    input                               s_icb_rsp_err,

    output                              m_icb_rsp_vld,
    input                               m_icb_rsp_rdy,
    output[P_DATA_WIDTH - 1 : 0]        m_icb_rsp_rdata,
    output                              m_icb_rsp_err,

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


        assign      buf_push_vld = s_icb_rsp_vld;
        assign      buf_push_data = {
                                        s_icb_rsp_err,
                                        s_icb_rsp_rdata
                                    };
        assign      s_icb_rsp_rdy = buf_push_rdy;

        assign      buf_pop_rdy = m_icb_rsp_rdy;
        assign      {
                        m_icb_rsp_err,
                        m_icb_rsp_rdata
                    } = buf_pop_data;
        assign      m_icb_rsp_vld = buf_pop_vld;

        lnrv_gnrl_buffer#
        (
            .P_DATA_WIDTH       ( LP_BUF_WIDTH              ),
            .P_DEEPTH           ( P_OTS_COUNT               ),
            .P_CUT_READY        ( P_BUFF_CUT_READY          ),
            .P_BYPASS           ( P_BUFF_BYPASS             )
        )
        u_icb_cmd_buff
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
        assign      m_icb_rsp_vld   = s_icb_rsp_vld;
        assign      m_icb_rsp_err   = s_icb_rsp_err;
        assign      m_icb_rsp_rdata = s_icb_rsp_rdata;

        assign      s_icb_rsp_rdy   = m_icb_rsp_rdy;
    end
endgenerate

endmodule