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

    // 交付模块的流水线冲刷请求
    input                               cmt_pipe_flush_req,
    output                              cmt_pipe_flush_ack,

    // 分支预测模块的流水线冲刷请求输出
    output                              bpu_pipe_flush_req,
    input                               bpu_pipe_flush_ack,
    output[31 : 0]                      bpu_pipe_flush_pc_op1,
    output[31 : 0]                      bpu_pipe_flush_pc_op2,

    input                               d_mode,

    // 非法指令
    output                              idu_excp_ilglir,
    output                              idu_excp_misalgn,
    output                              idu_excp_buserr,

    // 译码输出
    output                              idu_pc_vld,
    input                               idu_pc_rdy,
    output[31 : 0]                      idu_ir,
    output[31 : 0]                      idu_pc,
    output[31 : 0]                      idu_imm,
    output[4 : 0]                       idu_rs1_idx,
    output[4 : 0]                       idu_rs2_idx,
    output[11 : 0]                      idu_csr_idx,
    output[4 : 0]                       idu_rd_idx,
    output[`DEC_OP_BUS_WIDTH - 1 : 0]   idu_op_bus,
    output[`DEC_OP_TYPE_WIDTH - 1 : 0]  idu_op_type,

    output                              idu_rv32,
    output                              idu_rv16,

    input                               clk,
    input                               reset_n
);

localparam                              LP_BUFF_WIDTH = 134 + `DEC_OP_BUS_WIDTH;
localparam                              LP_BUFF1_WIDTH = 32 + 32 + 3;



wire[LP_BUFF_WIDTH - 1 : 0]             idu_buf_push_data;
wire                                    idu_buf_push_vld;
wire                                    idu_buf_push_rdy;

wire[LP_BUFF_WIDTH - 1 : 0]             idu_buf_pop_data;
wire                                    idu_buf_pop_vld;
wire                                    idu_buf_pop_rdy;

wire[31 : 0]                            dec_ir;
wire[4 : 0]                             dec_rs1_idx;
wire[4 : 0]                             dec_rs2_idx;
wire[4 : 0]                             dec_rd_idx;
wire[11 : 0]                            dec_csr_idx;
wire[31 : 0]                            dec_imm;
wire                                    dec_rv32;
wire                                    dec_rv16;
wire                                    dec_ilegl_instr;
wire[`DEC_OP_BUS_WIDTH - 1 : 0]         dec_op_bus;
wire[`DEC_OP_TYPE_WIDTH - 1 : 0]        dec_op_type;

wire                                    no_errors;


assign      no_errors = (~(ifu_excp_buserr | ifu_excp_misalgn | dec_ilegl_instr));

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
    .dec_op_type        ( dec_op_type               )
);


// 只有要ifu_ir有效，且没有暂停流水线请求的情况下，才会将译码信息送到下一级
assign      idu_buf0_push_vld = ifu_pc_vld & no_errors;
assign      idu_buf0_push_data = {
                                    dec_rs1_idx,
                                    dec_rs2_idx,
                                    dec_rd_idx,
                                    dec_csr_idx,
                                    dec_imm,
                                    dec_op_bus,
                                    dec_op_type
                                };


// 译码模块缓存buffer
lnrv_gnrl_buffer#
(
    .P_DATA_WIDTH       ( LP_BUFF0_WIDTH            ),
    .P_DEEPTH           ( 1                         ),
    .P_CUT_READY        ( "true"                    ),
    .P_BYPASS           ( "false"                   )
)   
u_idu_pipe_stage  
(   
    .clk                ( clk                       ),
    .reset_n            ( reset_n                   ),

    .flush_req          ( cmt_pipe_flush_req        ),
    .flush_ack          ( cmt_pipe_flush_ack        ),

    .push_vld           ( idu_buf_push_vld          ),
    .push_rdy           ( idu_buf_push_rdy          ),
    .push_data          ( idu_buf_push_data         ),

    .pop_vld            ( idu_buf_pop_vld           ),
    .pop_rdy            ( idu_buf_pop_rdy           ),
    .pop_data           ( idu_buf_pop_data          )
);

assign      idu_buf1_push_vld = ifu_pc_vld;
assign      idu_buf1_push_data =    {
                                        ifu_excp_buserr,
                                        ifu_excp_misalgn,
                                        dec_excp_ilglir,
                                        ifu_pc,
                                        ifu_ir
                                    };


lnrv_gnrl_buffer#
(
    .P_DATA_WIDTH       ( LP_BUFF1_WIDTH            ),
    .P_DEEPTH           ( 1                         ),
    .P_CUT_READY        ( "true"                    ),
    .P_BYPASS           ( "false"                   )
)   
u_idu_buff1  
(   
    .clk                ( clk                       ),
    .reset_n            ( reset_n                   ),

    .flush_req          ( cmt_pipe_flush_req        ),
    .flush_ack          ( cmt_pipe_flush_ack        ),

    .push_vld           ( idu_buf1_push_vld         ),
    .push_rdy           ( idu_buf1_push_rdy         ),
    .push_data          ( idu_buf1_push_data        ),

    .pop_vld            ( idu_buf1_pop_vld          ),
    .pop_rdy            ( idu_buf1_pop_rdy          ),
    .pop_data           ( idu_buf1_pop_data         )
);

assign      ifu_pc_rdy = idu_buf0_push_rdy;

assign      idu_buf0_pop_rdy = idu_pc_rdy;
assign      idu_buf1_pop_rdy = idu_pc_rdy;
assign      idu_pc_vld = idu_buf0_pop_vld;
assign      {
                idu_rs1_idx,
                idu_rs2_idx,
                idu_rd_idx,
                idu_csr_idx,
                idu_imm,
                idu_op_bus,
                dec_op_type
            } = idu_buf0_pop_data;

assign      {
                idu_excp_buserr,
                idu_excp_misalgn,
                idu_excp_ilglir,
                idu_pc,
                idu_ir
            } = idu_buf1_pop_data;


assign      idu_active = 1'b1;

endmodule //lnrv_idu
