`timescale 1ns / 1ps
`include	"lnrv_def.v"
module  lnrv_core
(
    input[31 : 0]                           reset_vector,

    // 中断信号
    input                                   sft_irq,
    input                                   ext_irq,
    input                                   tmr_irq,

    input                                   dbg_halt,
    input                                   dbg_irq,

    // wfi模式指示信号，为高时表示处于wfi模式中
    output                                  wfi_mode,

    // debug mode指示信号
    output                                  d_mode,

    output                                  stop_time,
    output                                  stop_count,

    // 取指总线
    output                                  ifu_cmd_vld,
    input                                   ifu_cmd_rdy,
    output                                  ifu_cmd_write,
    output[31 : 0]                          ifu_cmd_addr,
    output[31 : 0]                          ifu_cmd_wdata,
    output[3 : 0]                           ifu_cmd_wstrb,
    input                                   ifu_rsp_vld,
    output                                  ifu_rsp_rdy,
    input[31 : 0]                           ifu_rsp_rdata,
    input                                   ifu_rsp_err,

    // 系统访存总线
    output                                  lsu_cmd_vld,
    input                                   lsu_cmd_rdy,
    output                                  lsu_cmd_write,
    output[31 : 0]                          lsu_cmd_addr,
    output[31 : 0]                          lsu_cmd_wdata,
    output[3 : 0]                           lsu_cmd_wstrb,
    input                                   lsu_rsp_vld,
    output                                  lsu_rsp_rdy,
    input[31 : 0]                           lsu_rsp_rdata,
    input                                   lsu_rsp_err,

    input                                   clk,
    input                                   reset_n
);

wire                                    ifu_pipe_halt_req;
wire                                    ifu_pipe_halt_ack;
wire                                    ifu_pipe_flush_req;
wire                                    ifu_pipe_flush_ack;
wire                                    ifu_ir_vld;
wire[`CPU_ADDR_WIDTH - 1 : 0]           ifu_pc;
wire[`CPU_DATA_WIDTH - 1 : 0]           ifu_ir;


wire                                    ifu_ir_rdy;
wire                                    idu_pipe_halt_req;
wire                                    idu_pipe_halt_ack;
wire                                    idu_pipe_flush_req;
wire                                    idu_pipe_flush_ack;
wire                                    dec_op_vld;
wire[31 : 0]                            dec_ir;
wire[31 : 0]                            dec_pc;
wire                                    dec_idu_instr_ilegl;
wire                                    dec_ifu_misalgn;
wire                                    dec_ifu_buserr;
wire[4 : 0]                             dec_rs1_idx;
wire[4 : 0]                             dec_rs2_idx;
wire[11 : 0]                            dec_csr_idx;
wire[4 : 0]                             dec_rd_idx;
wire[31 : 0]                            dec_imm;
wire                                    dec_rglr_instr;
wire                                    dec_lsu_instr;
wire                                    dec_brch_instr;
wire                                    dec_mdv_instr;
wire                                    dec_sys_instr;
wire                                    dec_amo_instr;
wire                                    dec_fpu_instr;
wire[`DEC_OP_BUS_WIDTH - 1 : 0]         dec_op_bus;
wire                                    dec_rv32;
wire                                    dec_rv16;

wire                                    pipe_flush_req;
wire                                    pipe_flush_ack;
wire[31 : 0]                            pipe_flush_pc_op1;
wire[31 : 0]                            pipe_flush_pc_op2;


wire                                    cmt_mret;
wire                                    cmt_dret;
wire                                    cmt_irq;
wire                                    cmt_excp;
wire                                    cmt_debug;
wire[31 : 0]                            cmt_mepc;
wire[31 : 0]                            cmt_mcause;
wire[31 : 0]                            cmt_mtval;
wire[31 : 0]                            cmt_dpc;
wire[2 : 0]                             cmt_dcause;


wire[31 : 0]                            rs1_rdata;
wire[31 : 0]                            rs2_rdata;
wire                                    gpr_wbck_vld;
wire                                    gpr_wbck_rdy;
wire[4 : 0]                             gpr_wbck_idx;
wire[31 : 0]                            gpr_wbck_wdata;

wire[31 : 0]                            csr_rdata;
wire                                    csr_wbck_vld;
wire                                    csr_wbck_rdy;
wire[11 : 0]                            csr_wbck_idx;
wire[31 : 0]                            csr_wbck_wdata;

// outports wire
wire [31 : 0]                           mepc;
wire[31 : 0]                            dpc;
wire [31 : 0]                           mtvec;
wire                                    sft_irq_en;
wire                                    tmr_irq_en;
wire                                    ext_irq_en;
wire                                    mstatus_mie;


assign      ifu_pipe_halt_req = pipe_halt_req;
assign      ifu_pipe_flush_req = pipe_flush_req;

// 取指模块
lnrv_ifu u_lnrv_ifu
(
    .clk                        ( clk                       ),
    .reset_n                    ( reset_n                   ),

    .reset_vector               ( reset_vector              ),

    .pipe_flush_req             ( ifu_pipe_flush_req        ),
    .pipe_flush_ack             ( ifu_pipe_flush_ack        ),

    .pipe_flush_pc_op1          ( pipe_flush_pc_op1         ),
    .pipe_flush_pc_op2          ( pipe_flush_pc_op2         ),

    .pipe_halt_req              ( ifu_pipe_halt_req         ),
    .pipe_halt_ack              ( ifu_pipe_halt_ack         ),

    .ifu_ir_vld                 ( ifu_ir_vld                ),
    .ifu_ir_rdy                 ( ifu_ir_rdy                ),
    .ifu_pc                     ( ifu_pc                    ),
    .ifu_ir                     ( ifu_ir                    ),

    .ifu_cmd_vld                ( ifu_cmd_vld               ),
    .ifu_cmd_rdy                ( ifu_cmd_rdy               ),
    .ifu_cmd_write              ( ifu_cmd_write             ),
    .ifu_cmd_addr               ( ifu_cmd_addr              ),
    .ifu_cmd_wdata              ( ifu_cmd_wdata             ),
    .ifu_cmd_wstrb              ( ifu_cmd_wstrb             ),
    .ifu_rsp_vld                ( ifu_rsp_vld               ),
    .ifu_rsp_rdy                ( ifu_rsp_rdy               ),
    .ifu_rsp_rdata              ( ifu_rsp_rdata             ),
    .ifu_rsp_err                ( ifu_rsp_err               )
);

assign      idu_pipe_halt_req = pipe_halt_req;
assign      idu_pipe_flush_req = pipe_flush_req;

// 译码模块
lnrv_idu u_lnrv_idu
(
    .ifu_ir_vld                 ( ifu_ir_vld                ),
    .ifu_ir_rdy                 ( ifu_ir_rdy                ),
    .ifu_ir                     ( ifu_ir                    ),
    .ifu_pc                     ( ifu_pc                    ),
    .ifu_misalgn                ( 1'b0                      ),
    .ifu_buserr                 ( 1'b0                      ),

    .pipe_halt_req              ( idu_pipe_halt_req         ),
    .pipe_halt_ack              ( idu_pipe_halt_ack         ),

    .pipe_flush_req             ( idu_pipe_flush_req        ),
    .pipe_flush_ack             ( idu_pipe_flush_ack        ),

    .dec_idu_instr_ilegl        ( dec_idu_instr_ilegl       ),
    .dec_ifu_misalgn            ( dec_ifu_misalgn           ),
    .dec_ifu_buserr             ( dec_ifu_buserr            ),

    .d_mode                     ( d_mode                    ),

    .dec_rs1_idx                ( dec_rs1_idx               ),
    .dec_rs2_idx                ( dec_rs2_idx               ),
    .dec_csr_idx                ( dec_csr_idx               ),
    .dec_rd_idx                 ( dec_rd_idx                ),
    .dec_imm                    ( dec_imm                   ),
    .dec_ir                     ( dec_ir                    ),
    .dec_pc                     ( dec_pc                    ),

    .dec_rglr_instr             ( dec_rglr_instr            ),
    .dec_lsu_instr              ( dec_lsu_instr             ),
    .dec_csr_instr              ( dec_csr_instr             ),
    .dec_brch_instr             ( dec_brch_instr            ),
    .dec_mdv_instr              ( dec_mdv_instr             ),
    .dec_sys_instr              ( dec_sys_instr             ),
    .dec_amo_instr              ( dec_amo_instr             ),
    .dec_fpu_instr              ( dec_fpu_instr             ),
    
    .dec_op_vld                 ( dec_op_vld                ),
    .dec_op_rdy                 ( dec_op_rdy                ),
    .dec_op_bus                 ( dec_op_bus                ),


    .dec_rv32                   ( dec_rv32                  ),
    .dec_rv16                   ( dec_rv16                  ),
    
    .clk                        ( clk                       ),
    .reset_n                    ( reset_n                   )
);

assign      pipe_halt_ack = ifu_pipe_halt_ack & idu_pipe_halt_ack;
assign      pipe_flush_ack = ifu_pipe_flush_ack & idu_pipe_flush_ack;

// 指令执行模块
lnrv_exu u_lnrv_exu
(
    .dec_rglr_instr             ( dec_rglr_instr            ),
    .dec_lsu_instr              ( dec_lsu_instr             ),
    .dec_brch_instr             ( dec_brch_instr            ),
    .dec_mdv_instr              ( dec_mdv_instr             ),
    .dec_amo_instr              ( dec_amo_instr             ),
    .dec_fpu_instr              ( dec_fpu_instr             ),
    .dec_sys_instr              ( dec_sys_instr             ),
    .dec_csr_instr              ( dec_csr_instr             ),
    .dec_op_bus                 ( dec_op_bus                ),
    .dec_op_vld                 ( dec_op_vld                ),
    .dec_op_rdy                 ( dec_op_rdy                ),
    .dec_rs1_idx                ( dec_rs1_idx               ),
    .dec_rs2_idx                ( dec_rs2_idx               ),
    .dec_rd_idx                 ( dec_rd_idx                ),
    .dec_csr_idx                ( dec_csr_idx               ),
    .dec_imm                    ( dec_imm                   ),
    .dec_pc                     ( dec_pc                    ),
    .dec_ir                     ( dec_ir                    ),
    .dec_ifu_misalgn            ( dec_ifu_misalgn           ),
    .dec_ifu_buserr             ( dec_ifu_buserr            ),
    .dec_ilegal_instr           ( dec_idu_instr_ilegl       ),

    .ifu_pc_vld                 ( ifu_ir_vld                ),
    .ifu_pc                     ( ifu_pc                    ),

    .rs1_rdata                  ( rs1_rdata                 ),
    .rs2_rdata                  ( rs2_rdata                 ),
    .csr_rdata                  ( csr_rdata                 ),

    .pipe_flush_req             ( pipe_flush_req            ),
    .pipe_flush_ack             ( pipe_flush_ack            ),
    .pipe_flush_pc_op1          ( pipe_flush_pc_op1         ),
    .pipe_flush_pc_op2          ( pipe_flush_pc_op2         ),

    .pipe_halt_req              ( pipe_halt_req             ),
    .pipe_halt_ack              ( pipe_halt_ack             ),

    .sft_irq                    ( sft_irq                   ),
    .ext_irq                    ( ext_irq                   ),
    .tmr_irq                    ( tmr_irq                   ),

    .sft_irq_en                 ( sft_irq_en                ),
    .ext_irq_en                 ( ext_irq_en                ),
    .tmr_irq_en                 ( tmr_irq_en                ),

    .d_mode                     ( d_mode                    ),
    .m_mode                     ( m_mode                    ),

    .dbg_halt                   ( dbg_halt                  ),
    .dbg_irq                    ( dbg_irq                   ),

    .dcsr_ebreakm               ( dcsr_ebreakm              ),
    .dcsr_stepie                ( dcsr_stepie               ),
    .dcsr_step                  ( dcsr_step                 ),

    .wfi_mode                   ( wfi_mode                  ),

    .gpr_wbck_vld               ( gpr_wbck_vld              ),
    .gpr_wbck_rdy               ( gpr_wbck_rdy              ),
    .gpr_wbck_idx               ( gpr_wbck_idx              ),
    .gpr_wbck_wdata             ( gpr_wbck_wdata            ),

    .csr_wbck_vld               ( csr_wbck_vld              ),
    .csr_wbck_rdy               ( csr_wbck_rdy              ),
    .csr_wbck_idx               ( csr_wbck_idx              ),
    .csr_wbck_wdata             ( csr_wbck_wdata            ),

    .mstatus_mie                ( mstatus_mie               ),
    .mtvec                      ( mtvec                     ),
    .mepc                       ( mepc                      ),
    .dpc                        ( dpc                       ),

    .cmt_irq                    ( cmt_irq                   ),
    .cmt_excp                   ( cmt_excp                  ),
    .cmt_debug                  ( cmt_debug                 ),
    .cmt_mret                   ( cmt_mret                  ),
    .cmt_dret                   ( cmt_dret                  ),
    .cmt_mepc                   ( cmt_mepc                  ),
    .cmt_mcause                 ( cmt_mcause                ),
    .cmt_mtval                  ( cmt_mtval                 ),
    .cmt_dpc                    ( cmt_dpc                   ),
    .cmt_dcause                 ( cmt_dcause                ),


    .lsu_cmd_vld                ( lsu_cmd_vld               ),
    .lsu_cmd_rdy                ( lsu_cmd_rdy               ),
    .lsu_cmd_write              ( lsu_cmd_write             ),
    .lsu_cmd_addr               ( lsu_cmd_addr              ),
    .lsu_cmd_wdata              ( lsu_cmd_wdata             ),
    .lsu_cmd_wstrb              ( lsu_cmd_wstrb             ),
    .lsu_rsp_vld                ( lsu_rsp_vld               ),
    .lsu_rsp_rdy                ( lsu_rsp_rdy               ),
    .lsu_rsp_rdata              ( lsu_rsp_rdata             ),
    .lsu_rsp_err                ( lsu_rsp_err               ),

    .clk                        ( clk                       ),
    .reset_n                    ( reset_n                   )
);

// 通用寄存器组
lnrv_gpr#(
    .P_ADDR_WIDTH               ( 5                         )
)
u_lnrv_gpr
(
    .rs1_idx                    ( dec_rs1_idx               ),
    .rs1_rdata                  ( rs1_rdata                 ),
    .rs2_idx                    ( dec_rs2_idx               ),
    .rs2_rdata                  ( rs2_rdata                 ),

    .wr_vld                     ( gpr_wbck_vld              ),
    .wr_rdy                     ( gpr_wbck_rdy              ),
    .wr_idx                     ( gpr_wbck_idx              ),
    .wr_data                    ( gpr_wbck_wdata            ),

    .ra                         (                           ),

    .clk                        ( clk                       ),
    .reset_n                    ( reset_n                   )
);

// control and status regter
lnrv_csr u_lnrv_csr
(
    .reset_mtvec                ( 32'd0                     ),
    
    .mepc                       ( mepc                      ),
    .mtvec                      ( mtvec                     ),
    .mstatus_mie                ( mstatus_mie               ),
    .dpc                        ( dpc                       ),
    .d_mode                     ( d_mode                    ),

    .non_msk_irq                ( 1'b0                      ),
    .sft_irq_en                 ( sft_irq_en                ),
    .tmr_irq_en                 ( tmr_irq_en                ),
    .ext_irq_en                 ( ext_irq_en                ),


    .cmt_irq                    ( cmt_irq                   ),
    .cmt_excp                   ( cmt_excp                  ),
    .cmt_debug                  ( cmt_debug                 ),
    .cmt_mret                   ( cmt_mret                  ),
    .cmt_dret                   ( cmt_dret                  ),
    .cmt_mepc                   ( cmt_mepc                  ),
    .cmt_mcause                 ( cmt_mcause                ),
    .cmt_mtval                  ( cmt_mtval                 ),
    .cmt_dpc                    ( cmt_dpc                   ),
    .cmt_dcause                 ( cmt_dcause                ),

    .dcsr_step                  ( dcsr_step                 ),
    .dcsr_stepie                ( dcsr_stepie               ),
    .dcsr_ebreakm               ( dcsr_ebreakm              ),
    .dcsr_stoptime              ( stop_time                 ),
    .dcsr_stopcount             ( stop_count                ),

    .csr_idx                    ( dec_csr_idx               ),
    .csr_rdata                  ( csr_rdata                 ),

    .wbck_vld                   ( csr_wbck_vld              ),
    .wbck_rdy                   ( csr_wbck_rdy              ),
    .wbck_wdata                 ( csr_wbck_wdata            ),

    .clk                        ( clk                       ),
    .reset_n                    ( reset_n                   )
);


endmodule