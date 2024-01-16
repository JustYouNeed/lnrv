`include "lnrv_def.v"
module lnrv_idu 
(
    output                              idu_active,

    input                               ifu_ir_vld,
    output                              ifu_ir_rdy,
    input[31 : 0]                       ifu_ir,
    input[31 : 0]                       ifu_pc,
    input                               ifu_misalgn,
    input                               ifu_buserr,


    // 流水线暂停请求
    input                               pipe_halt_req,
    output                              pipe_halt_ack,

    // 流水线冲刷请求
    input                               pipe_flush_req,
    output                              pipe_flush_ack,

    input                               d_mode,

    // input[31 : 0]

    // 非法指令
    output                              dec_idu_instr_ilegl,
    output                              dec_ifu_misalgn,
    output                              dec_ifu_buserr,

    output                              dec_rglr_instr,
    output                              dec_lsu_instr,
    output                              dec_csr_instr,
    output                              dec_brch_instr,
    output                              dec_mdv_instr,
    output                              dec_sys_instr,
    output                              dec_amo_instr,
    output                              dec_fpu_instr,
    output[`DEC_OP_BUS_WIDTH - 1 : 0]   dec_op_bus,
    output                              dec_op_vld,
    input                               dec_op_rdy,
    output[31 : 0]                      dec_ir,
    output[31 : 0]                      dec_pc,
    output[31 : 0]                      dec_imm,
    output[4 : 0]                       dec_rs1_idx,
    output[4 : 0]                       dec_rs2_idx,
    output[11 : 0]                      dec_csr_idx,
    output[4 : 0]                       dec_rd_idx,

    output                              dec_rv32,
    output                              dec_rv16,

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

wire[31 : 0]                    decpde_ir;
wire[4 : 0]                     decode_rs1_idx;
wire[4 : 0]                     decode_rs2_idx;
wire[4 : 0]                     decode_rd_idx;
wire[11 : 0]                    decode_csr_idx;
wire[31 : 0]                    decode_imm;
wire                            decode_rv32;
wire                            decode_rv16;
wire                            decode_ilegl_instr;
wire[`DEC_OP_BUS_WIDTH - 1 : 0] decode_op_bus;
wire                            decode_rglr_instr;
wire                            decode_lsu_instr;
wire                            decode_brch_instr;
wire                            decode_mdv_instr;
wire                            decode_sys_instr;
wire                            decode_amo_instr;
wire                            decode_fpu_instr;

wire                            ifu_no_err;

assign      ifu_no_err = (~(ifu_buserr | ifu_misalgn));

// 如果取指出现了错误，则将译码输入变为全0，让译码模块输出非法指令，并且屏蔽
assign      decpde_ir = {32{ifu_ir_vld & ifu_no_err}} & ifu_ir;

lnrv_idu_decode u_lnrv_idu_decode
(
    .ir                 ( decpde_ir                 ),

    .dec_rs1_idx        ( decode_rs1_idx            ),
    .dec_rs2_idx        ( decode_rs2_idx            ),
    .dec_rd_idx         ( decode_rd_idx             ),
    .dec_csr_idx        ( decode_csr_idx            ),
    .dec_imm            ( decode_imm                ),

    .dec_rv32           ( decode_rv32               ),
    .dec_rv16           ( decode_rv16               ),

    .d_mode             ( d_mode                    ),

    .dec_ilegl_instr    ( decode_ilegl_instr        ),
    .dec_op_bus         ( decode_op_bus             ),
    .dec_rglr_instr     ( decode_gnrl_instr         ),
    .dec_lsu_instr      ( decode_lsu_instr          ),
    .dec_csr_instr      ( decode_csr_instr          ),
    .dec_brch_instr     ( decode_brch_instr         ),
    .dec_mdv_instr      ( decode_mdv_instr          ),
    .dec_sys_instr      ( decode_sys_instr          ),
    .dec_amo_instr      ( decode_amo_instr          ),
    .dec_fpu_instr      ( decode_fpu_instr          )
);


// 只有要ifu_ir有效，且没有暂停流水线请求的情况下，才会将译码信息送到下一级
assign      idu_buf_push_vld = ifu_ir_vld & (~pipe_halt_req);
assign      idu_buf_push_data = {
                                    decode_rs1_idx,
                                    decode_rs2_idx,
                                    decode_rd_idx,
                                    decode_csr_idx,
                                    decode_imm,
                                    // 如果ifu模块发生错误，则ir本身不可信，不需要在idu再产生一次解析错误
                                    decode_ilegl_instr & ifu_no_err,
                                    decode_gnrl_instr,
                                    decode_lsu_instr,
                                    decode_csr_instr,
                                    decode_brch_instr,
                                    decode_mdv_instr,
                                    decode_sys_instr,
                                    decode_amo_instr,
                                    decode_fpu_instr,
                                    decode_op_bus,
                                    ifu_ir,
                                    ifu_pc,
                                    ifu_misalgn,
                                    ifu_buserr
                                };


assign      idu_buf_pop_rdy = dec_op_rdy;
// 译码模块缓存buffer
lnrv_gnrl_buffer#
(
    .P_DATA_WIDTH       ( LP_BUFF_WIDTH         ),
    .P_DEEPTH           ( 1                     ),
    .P_CUT_READY        ( "false"               ),
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

assign      ifu_ir_rdy = idu_buf_push_rdy;

assign      dec_op_vld = idu_buf_pop_vld;
assign      {
                dec_rs1_idx,
                dec_rs2_idx,
                dec_rd_idx,
                dec_csr_idx,
                dec_imm,
                dec_idu_instr_ilegl,
                dec_rglr_instr,
                dec_lsu_instr,
                dec_csr_instr,
                dec_brch_instr,
                dec_mdv_instr,
                dec_sys_instr,
                dec_amo_instr,
                dec_fpu_instr,
                dec_op_bus,
                dec_ir,
                dec_pc,
                dec_ifu_misalgn,
                dec_ifu_buserr
            } = idu_buf_pop_data;


assign      idu_active = 1'b1;

endmodule //lnrv_idu
