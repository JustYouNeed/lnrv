module lnrv_ifu_pipe
(
    input               pipe_flush_req,
    output              pipe_flush_ack,


    input               ifu_buf_push_vld,
    input               ifu_icb_rsp_err,
    input[31 : 0]       ifu_icb_rsp_rdata,

    input[31 : 0]       ifu_instr_addr,


    output              ifu_pc_vld,

    output              
    output              ifu_bus_err,
);

assign      ifu_buf_push_vld = ifu_rsp_vld;
assign      ifu_buf_push_data = {
                                    ifu_rsp_err,
                                    ifu_rsp_rdata,
                                    instr_addr_q
                                };

assign      ifu_buf_pop_rdy = ifu_pc_rdy;
assign      {
                ifu_buserr,
                ifu_ir,
                ifu_pc
            } = ifu_buf_pop_data;

// assign      ifu_rsp_rdy = ifu_buf_push_rdy;
assign      ifu_pc_vld = ifu_buf_pop_vld;

lnrv_gnrl_buffer#
(
    .P_DATA_WIDTH       ( LP_IFU_BUF_WIDTH          ),
    .P_DEEPTH           ( 1                         ),
    .P_CUT_READY        ( "true"                    ),
    .P_BYPASS           ( "true"                    )
)       
u_ifu_buffer        
(       
    .clk                ( clk                       ),
    .reset_n            ( reset_n                   ),

    .flush_req          ( pipe_flush_vld            ),
    .flush_ack          (                           ),

    .push_vld           ( ifu_buf_push_vld          ),
    .push_rdy           ( ifu_buf_push_rdy          ),
    .push_data          ( ifu_buf_push_data         ),

    .pop_vld            ( ifu_buf_pop_vld           ),
    .pop_rdy            ( ifu_buf_pop_rdy           ),
    .pop_data           ( ifu_buf_pop_data          )
);

endmodule