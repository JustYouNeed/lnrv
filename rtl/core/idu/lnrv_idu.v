`include "lnrv_def.v"
module lnrv_idu
(
    output                              idu_active,

    input                               pipe_halt_req,
    output                              pipe_halt_ack,

    input                               ifu_vld,
    output                              ifu_rdy,
    input[31 : 0]                       ifu_ir,
    input[31 : 0]                       ifu_pc,
    input                               ifu_excp_misalgn,
    input                               ifu_excp_buserr,

    // 交付模块的流水线冲刷请求
    input                               pipe_flush_req_cmt,
    output                              pipe_flush_ack_cmt,

    input                               d_mode,

    input[31 : 0]                       gpr_x1,

    output                              pipe_flush_req_bpu,
    input                               pipe_flush_ack_bpu,
    output[31 : 0]                      pipe_flush_pc_op1_bpu,
    output[31 : 0]                      pipe_flush_pc_op2_bpu,

    // 非法指令
    output                              idu_excp_ilglir,
    output                              idu_excp_misalgn,
    output                              idu_excp_buserr,

    // 译码输出，送到exu模块执行
    output                              idu_vld,
    input                               idu_rdy,
    output[31 : 0]                      idu_ir,
    output[31 : 0]                      idu_pc,
    output[31 : 0]                      idu_imm,
    output[4 : 0]                       idu_rs1,
    output[4 : 0]                       idu_rs2,
    output[11 : 0]                      idu_csr,
    output[4 : 0]                       idu_rd,
    output[`DEC_OP_BUS_WIDTH - 1 : 0]   idu_op_bus,
    output[`DEC_OP_TYPE_WIDTH - 1 : 0]  idu_op_type,
    output                              idu_prdt_taken,


    output                              idu_rv32,

    input                               clk,
    input                               reset_n
);

localparam                              LP_BUFF_WIDTH = 128 + `DEC_OP_BUS_WIDTH + `DEC_OP_TYPE_WIDTH;

wire[LP_BUFF_WIDTH - 1 : 0]             idu_buf_push_data;
wire                                    idu_buf_push_vld;
wire                                    idu_buf_push_rdy;

wire[LP_BUFF_WIDTH - 1 : 0]             idu_buf_pop_data;
wire                                    idu_buf_pop_vld;
wire                                    idu_buf_pop_rdy;

wire[4 : 0]                             dec_rs1;
wire[4 : 0]                             dec_rs2;
wire[4 : 0]                             dec_rd;
wire[11 : 0]                            dec_csr;
wire[31 : 0]                            dec_imm;
wire                                    dec_ilegl_ir;
wire[`DEC_OP_BUS_WIDTH - 1 : 0]         dec_op_bus;
wire[`DEC_OP_TYPE_WIDTH - 1 : 0]        dec_op_type;

wire                                    rv32_sel;
wire[31 : 0]                            ir_rv32;
wire[15 : 0]                            ir_rv16;


wire[4 : 0]                             dec_rs1_rv32;
wire[4 : 0]                             dec_rs2_rv32;
wire[4 : 0]                             dec_rd_rv32;
wire[11 : 0]                            dec_csr_rv32;
wire[31 : 0]                            dec_imm_rv32;
wire                                    dec_ilegl_ir_rv32;
wire[`DEC_OP_BUS_WIDTH - 1 : 0]         dec_op_bus_rv32;
wire[`DEC_OP_TYPE_WIDTH - 1 : 0]        dec_op_type_rv32;

wire[4 : 0]                             dec_rs1_rv16;
wire[4 : 0]                             dec_rs2_rv16;
wire[4 : 0]                             dec_rd_rv16;
wire[31 : 0]                            dec_imm_rv16;
wire                                    dec_ilegl_ir_rv16;
wire[`DEC_OP_BUS_WIDTH - 1 : 0]         dec_op_bus_rv16;
wire[`DEC_OP_TYPE_WIDTH - 1 : 0]        dec_op_type_rv16;

wire                                    dec_ir_jal_rv16;
wire                                    dec_ir_jalr_rv16;
wire                                    dec_ir_bxx_rv16;
wire[31 : 0]                            dec_imm_bxx_rv16;
wire[31 : 0]                            dec_imm_jal_rv16;
wire[31 : 0]                            dec_imm_jalr_rv16;
wire                                    dec_rs1_x1_rv16;

wire                                    dec_ir_jal_rv32;
wire                                    dec_ir_jalr_rv32;
wire                                    dec_ir_bxx_rv32;
wire                                    dec_ir_fence_rv32;
wire[31 : 0]                            dec_imm_bxx_rv32;
wire[31 : 0]                            dec_imm_jal_rv32;
wire[31 : 0]                            dec_imm_jalr_rv32;
wire                                    dec_rs1_x1_rv32;

wire                                    dec_ir_bxx;
wire                                    dec_ir_fence;
wire                                    dec_ir_jal;
wire                                    dec_ir_jalr;
wire[31 : 0]                            dec_imm_bxx;
wire[31 : 0]                            dec_imm_jal;
wire[31 : 0]                            dec_imm_jalr;
wire                                    dec_rs1_x1;

wire                                    bpu_prdt_res;

assign      rv32_sel        = (ifu_ir[1 : 0] == 2'b11);
assign      ir_rv16         = {16{~rv32_sel}} & ifu_ir[15 : 0];
assign      ir_rv32         = {32{rv32_sel}} & ifu_ir;


// 16位指令解析模块
lnrv_idu_rv16   u_lnrv_idu_rv16
(
    .ir                 ( ir_rv16                   ),

    .dec_rd             ( dec_rd_rv16               ),
    .dec_rs1            ( dec_rs1_rv16              ),
    .dec_rs2            ( dec_rs2_rv16              ),
    .dec_imm            ( dec_imm_rv16              ),
    .dec_ilegl_ir       ( dec_ilegl_ir_rv16         ),

    .dec_ir_jal         ( dec_ir_jal_rv16           ),
    .dec_ir_jalr        ( dec_ir_jalr_rv16          ),
    .dec_ir_bxx         ( dec_ir_bxx_rv16           ),
    .dec_imm_bxx        ( dec_imm_bxx_rv16          ),
    .dec_imm_jal        ( dec_imm_jal_rv16          ),
    .dec_imm_jalr       ( dec_imm_jalr_rv16         ),
    .dec_rs1_x1         ( dec_rs1_x1_rv16           ),

    .dec_op_bus         ( dec_op_bus_rv16           ),
    .dec_op_type        ( dec_op_type_rv16          )
);


// 32位指令解析模块
lnrv_idu_rv32   u_lnrv_idu_rv32
(
    .ir                 ( ir_rv32                   ),

    .d_mode             ( d_mode                    ),

    .dec_rd             ( dec_rd_rv32               ),
    .dec_rs1            ( dec_rs1_rv32              ),
    .dec_rs2            ( dec_rs2_rv32              ),
    .dec_csr            ( dec_csr_rv32              ),
    .dec_imm            ( dec_imm_rv32              ),
    .dec_ilegl_ir       ( dec_ilegl_ir_rv32         ),

    .dec_ir_jal         ( dec_ir_jal_rv32           ),
    .dec_ir_jalr        ( dec_ir_jalr_rv32          ),
    .dec_ir_fence       ( dec_ir_fence_rv32         ),
    .dec_ir_bxx         ( dec_ir_bxx_rv32           ),
    .dec_imm_bxx        ( dec_imm_bxx_rv32          ),
    .dec_imm_jal        ( dec_imm_jal_rv32          ),
    .dec_imm_jalr       ( dec_imm_jalr_rv32         ),
    .dec_rs1_x1         ( dec_rs1_x1_rv32           ),

    .dec_op_bus         ( dec_op_bus_rv32           ),
    .dec_op_type        ( dec_op_type_rv32          )
);


// 分支预测模块
lnrv_bpu u_lnrv_bpu
(
    .ifu_vld            ( ifu_vld                   ),
    .ifu_rdy            ( ifu_rdy                   ),
    .ifu_pc             ( ifu_pc                    ),

    .idu_vld            ( idu_vld                   ),
    .idu_rdy            ( idu_rdy                   ),
    .idu_rd             ( idu_rd                    ),

    .gpr_x1             ( gpr_x1                    ),

    .dec_ir_jal         ( dec_ir_jal                ),
    .dec_ir_jalr        ( dec_ir_jalr               ),
    .dec_ir_fence       ( dec_ir_fence              ),
    .dec_ir_bxx         ( dec_ir_bxx                ),
    .dec_imm_bxx        ( dec_imm_bxx               ),
    .dec_imm_jal        ( dec_imm_jal               ),
    .dec_imm_jalr       ( dec_imm_jalr              ),
    .dec_rs1_x1         ( dec_rs1_x1                ),

    .pipe_flush_req     ( pipe_flush_req_bpu        ),
    .pipe_flush_ack     ( pipe_flush_ack_bpu        ),
    .pipe_flush_pc_op1  ( pipe_flush_pc_op1_bpu     ),
    .pipe_flush_pc_op2  ( pipe_flush_pc_op2_bpu     ),

    .bpu_prdt_res       ( bpu_prdt_res              ),

    .clk                ( clk                       ),
    .reset_n            ( reset_n                   )
);


assign      dec_imm         = rv32_sel ? dec_imm_rv32 : dec_imm_rv16;
assign      dec_rd          = rv32_sel ? dec_rd_rv32 : dec_rd_rv16;
assign      dec_rs1         = rv32_sel ? dec_rs1_rv32 : dec_rs1_rv16;
assign      dec_rs2         = rv32_sel ? dec_rs2_rv32 : dec_rs2_rv16;
assign      dec_csr         = dec_csr_rv32;
assign      dec_ilegl_ir    = rv32_sel ? dec_ilegl_ir_rv32 : dec_ilegl_ir_rv16;
assign      dec_op_bus      = rv32_sel ? dec_op_bus_rv32 : dec_op_bus_rv16;
assign      dec_op_type     = rv32_sel ? dec_op_type_rv32 : dec_op_type_rv16;

// 只有要ifu_ir有效，且没有暂停流水线请求的情况下，才会将译码信息送到下一级
assign      idu_buf_push_vld = ifu_vld & (~pipe_halt_req);
assign      idu_buf_push_data = {
                                    dec_rs1,
                                    dec_rs2,
                                    dec_rd,
                                    dec_csr,
                                    dec_imm,
                                    dec_op_bus,
                                    dec_op_type,
                                    ifu_excp_buserr,
                                    ifu_excp_misalgn,
                                    dec_ilegl_ir,
                                    ifu_pc,
                                    ifu_ir,
                                    rv32_sel,
                                    bpu_prdt_res
                                };


// 译码模块缓存buffer
lnrv_gnrl_buffer#
(
    .P_DATA_WIDTH       ( LP_BUFF_WIDTH             ),
    .P_DEEPTH           ( 1                         ),
    .P_CUT_VALID        ( 1'b0                   ),
    .P_CUT_READY        ( 1'b0                   ),
    .P_BYPASS           ( 1'b0                   ),

    // forward mode
    .P_MODE             ( 0                         )
)
u_idu_pipe_stage
(
    .clk                ( clk                       ),
    .reset_n            ( reset_n                   ),

    .flush_req          ( pipe_flush_req_cmt        ),
    .flush_ack          ( pipe_flush_ack_cmt        ),

    .push_vld           ( idu_buf_push_vld          ),
    .push_rdy           ( idu_buf_push_rdy          ),
    .push_data          ( idu_buf_push_data         ),

    .pop_vld            ( idu_buf_pop_vld           ),
    .pop_rdy            ( idu_buf_pop_rdy           ),
    .pop_data           ( idu_buf_pop_data          )
);

assign      ifu_rdy = idu_buf_push_rdy & (~pipe_halt_req);

assign      idu_buf_pop_rdy = idu_rdy;
assign      idu_vld = idu_buf_pop_vld;
assign      {
                idu_rs1,
                idu_rs2,
                idu_rd,
                idu_csr,
                idu_imm,
                idu_op_bus,
                idu_op_type,
                idu_excp_buserr,
                idu_excp_misalgn,
                idu_excp_ilglir,
                idu_pc,
                idu_ir,
                idu_rv32,
                idu_prdt_taken
            } = idu_buf_pop_data;

assign      idu_active = 1'b1;

assign      pipe_halt_ack = idu_buf_push_rdy;

assign      dec_ir_bxx      = rv32_sel ? dec_ir_bxx_rv32 : dec_ir_bxx_rv16;
assign      dec_ir_fence    = dec_ir_fence_rv32;
assign      dec_ir_jal      = rv32_sel ? dec_ir_jal_rv32 : dec_ir_jal_rv16;
assign      dec_ir_jalr     = rv32_sel ? dec_ir_jalr_rv32 : dec_ir_jalr_rv16;
assign      dec_imm_bxx     = rv32_sel ? dec_imm_bxx_rv32 : dec_imm_bxx_rv16;
assign      dec_imm_jal     = rv32_sel ? dec_imm_jal_rv32 : dec_imm_jal_rv16;
assign      dec_imm_jalr    = rv32_sel ? dec_imm_jalr_rv32 : dec_imm_jal_rv16;
assign      dec_rs1_x1      = rv32_sel ? dec_rs1_x1_rv32 : dec_rs1_x1_rv16;

endmodule //lnrv_idu
