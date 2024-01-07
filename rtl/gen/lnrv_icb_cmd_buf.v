module lnrv_icb_cmd_buf#
(
    parameter                           P_BUFF_ENABLE = "true",
    parameter                           P_BUFF_CUT_READY = "true",
    parameter                           P_BUFF_BYPASS = "false",
    parameter                           P_OTS_COUNT = 1,

    parameter                           P_ADDR_WIDTH = 32,
    parameter                           P_DATA_WIDTH = 32
)
(
    input                               m_icb_cmd_vld,
    output                              m_icb_cmd_rdy,
    input                               m_icb_cmd_write,
    input[P_ADDR_WIDTH - 1 : 0]         m_icb_cmd_addr,
    input[P_DATA_WIDTH - 1 : 0]         m_icb_cmd_wdata,
    input[(P_DATA_WIDTH/8) - 1 : 0]     m_icb_cmd_wstrb,

    output                              s_icb_cmd_vld,
    input                               s_icb_cmd_rdy,
    output                              s_icb_cmd_write,
    output[P_ADDR_WIDTH - 1 : 0]        s_icb_cmd_addr,
    output[P_DATA_WIDTH - 1 : 0]        s_icb_cmd_wdata,
    output[(P_DATA_WIDTH/8) - 1 : 0]    s_icb_cmd_wstrb,

    input                               clk,
    input                               reset_n
);


localparam                  LP_WSTRB_WIDTH = P_DATA_WIDTH/8;
localparam                  LP_BUF_WIDTH = P_ADDR_WIDTH + P_DATA_WIDTH + LP_WSTRB_WIDTH + 1;


generate
    if(P_BUFF_ENABLE == "true") begin
        wire[LP_BUF_WIDTH - 1 : 0]          buf_push_data;
        wire                                buf_push_vld;
        wire                                buf_push_rdy;

        wire[LP_BUF_WIDTH - 1 : 0]          buf_pop_data;
        wire                                buf_pop_vld;
        wire                                buf_pop_rdy;


        assign      buf_push_vld = m_icb_cmd_vld;
        assign      buf_push_data = {
                                        m_icb_cmd_write,
                                        m_icb_cmd_wdata,
                                        m_icb_cmd_wstrb,
                                        m_icb_cmd_addr
                                    };
        assign      m_icb_cmd_rdy = buf_push_rdy;

        assign      buf_pop_rdy = s_icb_cmd_rdy;
        assign      {
                        s_icb_cmd_write,
                        s_icb_cmd_wdata,
                        s_icb_cmd_wstrb,
                        s_icb_cmd_addr
                    } = buf_pop_data;
        assign      s_icb_cmd_vld = buf_pop_vld;

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
        assign      s_icb_cmd_vld   = m_icb_cmd_vld;
        assign      s_icb_cmd_write = m_icb_cmd_write;
        assign      s_icb_cmd_addr  = m_icb_cmd_addr;
        assign      s_icb_cmd_wdata = m_icb_cmd_wdata;
        assign      s_icb_cmd_wstrb = m_icb_cmd_wstrb;

        assign      m_icb_cmd_rdy   = s_icb_cmd_rdy;
    end
endgenerate

endmodule
