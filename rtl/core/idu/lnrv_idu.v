`include "lnrv_def.v"
module lnrv_idu 
(
    output                              idu_active,

    input                               ifu_pc_vld,
    output                              ifu_pc_rdy,
    input[31 : 0]                       ifu_ir,
    input[31 : 0]                       ifu_pc,
    input                               ifu_excp_misalgn,
    input                               ifu_excp_buserr,


    // 流水线暂停请求
    input                               pipe_halt_req,
    output                              pipe_halt_ack,

    // 流水线冲刷请求
    input                               pipe_flush_req,
    output                              pipe_flush_ack,

    input                               d_mode,

    // input[31 : 0]

    // 非法指令
    output                              idu_excp_instr_ilegl,
    output                              ifu_excp_misalgn,
    output                              ifu_excp_buserr,

    output                              idu_rglr_instr,
    output                              idu_lsu_instr,
    output                              idu_csr_instr,
    output                              idu_brch_instr,
    output                              idu_mdv_instr,
    output                              idu_sys_instr,
    output                              idu_amo_instr,
    output                              idu_fpu_instr,
    output[`DEC_OP_BUS_WIDTH - 1 : 0]   idu_op_bus,

    output                              idu_pc_vld,
    input                               idu_pc_rdy,
    output[31 : 0]                      idu_ir,
    output[31 : 0]                      idu_pc,
    output[31 : 0]                      idu_imm,
    output[4 : 0]                       idu_rs1_idx,
    output[4 : 0]                       idu_rs2_idx,
    output[11 : 0]                      idu_csr_idx,
    output[4 : 0]                       idu_rd_idx,

    output                              idu_rv32,
    output                              idu_rv16,

    input                               clk,
    input                               reset_n
);

localparam                      LP_BUFF_WIDTH = 134 + `DEC_OP_BUS_WIDTH;




wire[LP_BUFF_WIDTH - 1 : 0]     idu_buf_push_data;
wire                            idu_buf_push_vld;
wire                            idu_buf_push_rdy;

wire[LP_BUFF_WIDTH - 1 : 0]     idu_buf_pop_data;
wire                            idu_buf_pop_vld;
wire                            idu_buf_pop_rdy;

wire[31 : 0]                    dec_ir;
wire[4 : 0]                     dec_rs1_idx;
wire[4 : 0]                     dec_rs2_idx;
wire[4 : 0]                     dec_rd_idx;
wire[11 : 0]                    dec_csr_idx;
wire[31 : 0]                    dec_imm;
wire                            dec_rv32;
wire                            dec_rv16;
wire                            dec_ilegl_instr;
wire[`DEC_OP_BUS_WIDTH - 1 : 0] dec_op_bus;
wire                            dec_rglr_instr;
wire                            dec_lsu_instr;
wire                            dec_brch_instr;
wire                            dec_mdv_instr;
wire                            dec_sys_instr;
wire                            dec_amo_instr;
wire                            dec_fpu_instr;

wire                            ifu_no_err;

assign      ifu_no_err = (~(ifu_excp_buserr | ifu_excp_misalgn));

lnrv_idu_decode u_lnrv_idu_decode
(
    .ir                 ( dec_ir                    ),

    .dec_rs1_idx        ( dec_rs1_idx               ),
    .dec_rs2_idx        ( dec_rs2_idx               ),
    .dec_rd_idx         ( dec_rd_idx                ),
    .dec_csr_idx        ( dec_csr_idx               ),
    .dec_imm            ( dec_imm                   ),

    .dec_rv32           ( dec_rv32                  ),
    .dec_rv16           ( dec_rv16                  ),

    .d_mode             ( d_mode                    ),

    .dec_ilegl_instr    ( dec_ilegl_instr           ),
    .dec_op_bus         ( dec_op_bus                ),
    .dec_rglr_instr     ( dec_rglr_instr            ),
    .dec_lsu_instr      ( dec_lsu_instr             ),
    .dec_csr_instr      ( dec_csr_instr             ),
    .dec_brch_instr     ( dec_brch_instr            ),
    .dec_mdv_instr      ( dec_mdv_instr             ),
    .dec_sys_instr      ( dec_sys_instr             ),
    .dec_amo_instr      ( dec_amo_instr             ),
    .dec_fpu_instr      ( dec_fpu_instr             )
);


// 只有要ifu_ir有效，且没有暂停流水线请求的情况下，才会将译码信息送到下一级
assign      idu_buf_push_vld = ifu_pc_vld & (~pipe_halt_req);
assign      idu_buf_push_data = {
                                    dec_rs1_idx,
                                    dec_rs2_idx,
                                    dec_rd_idx,
                                    dec_csr_idx,
                                    dec_imm,
                                    // 如果ifu模块发生错误，则ir本身不可信，不需要在idu再产生一次解析错误
                                    dec_ilegl_instr & ifu_no_err,
                                    dec_rglr_instr,
                                    dec_lsu_instr,
                                    dec_csr_instr,
                                    dec_brch_instr,
                                    dec_mdv_instr,
                                    dec_sys_instr,
                                    dec_amo_instr,
                                    dec_fpu_instr,
                                    dec_op_bus,
                                    ifu_ir,
                                    ifu_pc,
                                    ifu_excp_misalgn,
                                    ifu_excp_buserr
                                };


// 译码模块缓存buffer
lnrv_gnrl_buffer#
(
    .P_DATA_WIDTH       ( LP_BUFF_WIDTH         ),
    .P_DEEPTH           ( 1                     ),
    .P_CUT_READY        ( "true"                ),
    .P_BYPASS           ( "false"               )
)   
u_idu_pipe_stage  
(   
    .clk                ( clk                   ),
    .reset_n            ( reset_n               ),

    .flush_req          ( pipe_flush_req        ),
    .flush_ack          ( pipe_flush_ack        ),

    .push_vld           ( idu_buf_push_vld      ),
    .push_rdy           ( idu_buf_push_rdy      ),
    .push_data          ( idu_buf_push_data     ),

    .pop_vld            ( idu_buf_pop_vld       ),
    .pop_rdy            ( idu_buf_pop_rdy       ),
    .pop_data           ( idu_buf_pop_data      )
);


assign      pipe_halt_ack = 1'b1;

assign      ifu_pc_rdy = idu_buf_push_rdy;

assign      idu_buf_pop_rdy = idu_pc_rdy;
assign      idu_pc_vld = idu_buf_pop_vld;
assign      {
                idu_rs1_idx,
                idu_rs2_idx,
                idu_rd_idx,
                idu_csr_idx,
                idu_imm,
                idu_excp_instr_ilegl,
                idu_rglr_instr,
                idu_lsu_instr,
                idu_csr_instr,
                idu_brch_instr,
                idu_mdv_instr,
                idu_sys_instr,
                idu_amo_instr,
                idu_fpu_instr,
                idu_op_bus,
                idu_ir,
                idu_pc,
                ifu_excp_misalgn,
                ifu_excp_buserr
            } = idu_buf_pop_data;


assign      idu_active = 1'b1;

endmodule //lnrv_idu
