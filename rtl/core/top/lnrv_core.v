`include	"lnrv_def.v"
module  lnrv_core
(
    input[31 : 0]                           reset_vector,
    input[31 : 0]                           reset_mtvec,

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
    output[2 : 0]                           ifu_cmd_size,
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
    output[2 : 0]                           lsu_cmd_size,
    input                                   lsu_rsp_vld,
    output                                  lsu_rsp_rdy,
    input[31 : 0]                           lsu_rsp_rdata,
    input                                   lsu_rsp_err,

    // 
    input                                   ifu_clk,
    output                                  ifu_active,

    input                                   idu_clk,
    output                                  idu_active,

    input                                   exu_clk,
    input                                   exu_active,

    input                                   clk,
    input                                   reset_n
);

wire                                    ifu_pipe_halt_req;
wire                                    ifu_pipe_halt_ack;
wire                                    ifu_pipe_flush_req;
wire                                    ifu_pipe_flush_ack;
wire                                    ifu_pc_vld;
wire[`CPU_ADDR_WIDTH - 1 : 0]           ifu_pc;
wire[`CPU_DATA_WIDTH - 1 : 0]           ifu_ir;


wire                                    ifu_pc_rdy;
wire                                    idu_pipe_halt_req;
wire                                    idu_pipe_halt_ack;
wire                                    idu_pipe_flush_req;
wire                                    idu_pipe_flush_ack;
wire                                    dec_op_vld;
wire                                    dec_op_rdy;
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
wire                                    dec_csr_instr;
wire                                    dec_brch_instr;
wire                                    dec_mdv_instr;
wire                                    dec_sys_instr;
wire                                    dec_amo_instr;
wire                                    dec_fpu_instr;
wire[`DEC_OP_BUS_WIDTH - 1 : 0]         dec_op_bus;
wire                                    dec_rv32;
wire                                    dec_rv16;

wire                                    pipe_halt_req;
wire                                    pipe_halt_ack;

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


wire                                    dcsr_ebreakm;
wire                                    dcsr_stepie;
wire                                    dcsr_step;
wire                                    dcsr_stopcount;
wire                                    dcsr_stoptime;


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

    .ifu_active                 ( ifu_active                ),

    .reset_vector               ( reset_vector              ),

    .pipe_flush_req             ( ifu_pipe_flush_req        ),
    .pipe_flush_ack             ( ifu_pipe_flush_ack        ),

    .pipe_flush_pc_op1          ( pipe_flush_pc_op1         ),
    .pipe_flush_pc_op2          ( pipe_flush_pc_op2         ),

    .pipe_halt_req              ( ifu_pipe_halt_req         ),
    .pipe_halt_ack              ( ifu_pipe_halt_ack         ),

    .ifu_pc_vld                 ( ifu_pc_vld                ),
    .ifu_pc_rdy                 ( ifu_pc_rdy                ),
    .ifu_pc                     ( ifu_pc                    ),
    .ifu_ir                     ( ifu_ir                    ),

    .ifu_cmd_vld                ( ifu_cmd_vld               ),
    .ifu_cmd_rdy                ( ifu_cmd_rdy               ),
    .ifu_cmd_write              ( ifu_cmd_write             ),
    .ifu_cmd_addr               ( ifu_cmd_addr              ),
    .ifu_cmd_wdata              ( ifu_cmd_wdata             ),
    .ifu_cmd_wstrb              ( ifu_cmd_wstrb             ),
    .ifu_cmd_size               ( ifu_cmd_size              ),
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
    .idu_active                 ( idu_active                ),

    .ifu_pc_vld                 ( ifu_pc_vld                ),
    .ifu_pc_rdy                 ( ifu_pc_rdy                ),
    .ifu_ir                     ( ifu_ir                    ),
    .ifu_pc                     ( ifu_pc                    ),
    .ifu_misalgn                ( 1'b0                      ),
    .ifu_buserr                 ( 1'b0                      ),

    .cmt_pipe_flush_req         ( cmt_pipe_flush_req        ),
    .cmt_pipe_flush_ack         ( cmt_pipe_flush_ack_idu    ),

    .idu_excp_ilgl_ir           ( idu_excp_ilgl_ir          ),
    .idu_excp_misalgn           ( idu_excp_misalgn          ),
    .idu_excp_buserr            ( idu_excp_buserr           ),

    .d_mode                     ( d_mode                    ),

    .idu_rs1_idx                ( idu_rs1_idx               ),
    .idu_rs2_idx                ( idu_rs2_idx               ),
    .idu_csr_idx                ( idu_csr_idx               ),
    .idu_rd_idx                 ( idu_rd_idx                ),
    .idu_imm                    ( idu_imm                   ),
    .idu_ir                     ( idu_ir                    ),
    .idu_pc                     ( idu_pc                    ),

    .idu_rglr_instr             ( idu_rglr_instr            ),
    .idu_lsu_instr              ( idu_lsu_instr             ),
    .idu_csr_instr              ( idu_csr_instr             ),
    .idu_brch_instr             ( idu_brch_instr            ),
    .idu_mdv_instr              ( idu_mdv_instr             ),
    .idu_sys_instr              ( idu_sys_instr             ),
    .idu_amo_instr              ( idu_amo_instr             ),
    .idu_fpu_instr              ( idu_fpu_instr             ),
    
    .idu_op_vld                 ( idu_op_vld                ),
    .idu_op_rdy                 ( idu_op_rdy                ),
    .idu_op_bus                 ( idu_op_bus                ),


    .idu_rv32                   ( idu_rv32                  ),
    .idu_rv16                   ( idu_rv16                  ),
    
    .clk                        ( clk                       ),
    .reset_n                    ( reset_n                   )
);

assign      pipe_halt_ack = ifu_pipe_halt_ack & idu_pipe_halt_ack;
assign      pipe_flush_ack = ifu_pipe_flush_ack & idu_pipe_flush_ack;

// 指令执行模块
lnrv_exu u_lnrv_exu
(
    .exu_active                 ( exu_active                ),

    .idu_rglr_instr             ( idu_rglr_instr            ),
    .idu_lsu_instr              ( idu_lsu_instr             ),
    .idu_brch_instr             ( idu_brch_instr            ),
    .idu_mdv_instr              ( idu_mdv_instr             ),
    .idu_amo_instr              ( idu_amo_instr             ),
    .idu_fpu_instr              ( idu_fpu_instr             ),
    .idu_sys_instr              ( idu_sys_instr             ),
    .idu_csr_instr              ( idu_csr_instr             ),
    .idu_op_bus                 ( idu_op_bus                ),
    .idu_op_vld                 ( idu_op_vld                ),
    .idu_op_rdy                 ( idu_op_rdy                ),
    .idu_rs1_idx                ( idu_rs1_idx               ),
    .idu_rs2_idx                ( idu_rs2_idx               ),
    .idu_rd_idx                 ( idu_rd_idx                ),
    .idu_csr_idx                ( idu_csr_idx               ),
    .idu_imm                    ( idu_imm                   ),
    .idu_pc                     ( idu_pc                    ),
    .idu_ir                     ( idu_ir                    ),

    .rs1_rdata                  ( rs1_rdata                 ),
    .rs2_rdata                  ( rs2_rdata                 ),
    .csr_rdata                  ( csr_rdata                 ),

    .pipe_halt_req              ( pipe_halt_req             ),
    .pipe_halt_ack              ( pipe_halt_ack             ),


    .wfi_mode                   ( wfi_mode                  ),

    .lsu_cmd_vld                ( lsu_cmd_vld               ),
    .lsu_cmd_rdy                ( lsu_cmd_rdy               ),
    .lsu_cmd_write              ( lsu_cmd_write             ),
    .lsu_cmd_addr               ( lsu_cmd_addr              ),
    .lsu_cmd_wdata              ( lsu_cmd_wdata             ),
    .lsu_cmd_wstrb              ( lsu_cmd_wstrb             ),
    .lsu_cmd_size               ( lsu_cmd_size              ),
    .lsu_rsp_vld                ( lsu_rsp_vld               ),
    .lsu_rsp_rdy                ( lsu_rsp_rdy               ),
    .lsu_rsp_rdata              ( lsu_rsp_rdata             ),
    .lsu_rsp_err                ( lsu_rsp_err               ),

    .clk                        ( clk                       ),
    .reset_n                    ( reset_n                   )
);

lnrv_cmt u_lnrv_cmt
(
    .ifu_pc_vld                 ( ifu_pc_vld                ),
    .ifu_pc                     ( ifu_pc                    ),

    .idu_pc_vld                 ( idu_pc_vld                ),
    .idu_pc                     ( idu_pc                    ),
    .idu_ir                     ( idu_ir                    ),
    .idu_rd_idx                 ( idu_rd_idx                ),
    .idu_csr_idx                ( idu_csr_idx               ),
    .idu_excp_ilgl_ir           ( idu_excp_ilgl_ir          ),
    .idu_excp_buserr            ( idu_excp_buserr           ),
    .idu_excp_misalgn           ( idu_excp_misalgn          ),

    .lsu_cmt_vld                ( lsu_cmt_vld               ),
    .lsu_cmt_rdy                ( lsu_cmt_rdy               ),
    .lsu_cmt_misalgn            ( lsu_cmt_misalgn           ),
    .lsu_cmt_buserr             ( lsu_cmt_buserr            ),
    .lsu_cmt_st                 ( lsu_cmt_st                ),
    .lsu_cmt_ld                 ( lsu_cmt_ld                ),
    .lsu_cmt_bad_addr           ( lsu_cmt_bad_addr          ),
    .lsu_cmt_gpr_wen            ( lsu_cmt_gpr_wen           ),
    .lsu_cmt_gpr_wdata          ( lsu_cmt_gpr_wdata         ),

    .sys_cmt_vld                ( sys_cmt_vld               ),
    .sys_cmt_rdy                ( sys_cmt_rdy               ),
    .sys_cmt_ecall              ( sys_cmt_ecall             ),
    .sys_cmt_ebreak             ( sys_cmt_ebreak            ),
    .sys_cmt_wfi                ( sys_cmt_wfi               ),

    .rglr_cmt_vld               ( rglr_cmt_vld              ),
    .rglr_cmt_rdy               ( rglr_cmt_rdy              ),
    .rglr_cmt_gpr_wen           ( rglr_cmt_gpr_wen          ),

    .brch_cmt_vld               ( brch_cmt_vld              ),
    .brch_cmt_rdy               ( brch_cmt_rdy              ),
    .brch_cmt_bjp               ( brch_cmt_bjp              ),
    .brch_cmt_jal               ( brch_cmt_jal              ),
    .brch_cmt_jalr              ( brch_cmt_jalr             ),
    .brch_cmt_mret              ( brch_cmt_mret             ),
    .brch_cmt_dret              ( brch_cmt_dret             ),
    .brch_cmt_fence             ( brch_cmt_fence            ),
    .brch_cmt_gpr_wen           ( brch_cmt_gpr_wen          ),

    .csr_cmt_vld                ( csr_cmt_vld               ),
    .csr_cmt_rdy                ( csr_cmt_rdy               ),
    .csr_cmt_idx_err            ( csr_cmt_idx_err           ),
    .csr_cmt_gpr_wen            ( csr_cmt_gpr_wen           ),
    .csr_cmt_csr_wen            ( csr_cmt_csr_wen           ),
    .csr_rdata                  ( csr_rdata                 ),

    .alu_res                    ( alu_res                   ),
    .bpu_prdt_res               ( bpu_prdt_res              ),

    .sft_irq                    ( sft_irq                   ),
    .ext_irq                    ( ext_irq                   ),
    .tmr_irq                    ( tmr_irq                   ),
    .mie_meie                   ( mie_meie                  ),
    .mie_mtie                   ( mie_mtie                  ),
    .mie_msie                   ( mie_msie                  ),
    .mstatus_mie                ( mstatus_mie               ),

    .dbg_mode                   ( dbg_mode                  ),

    .irq_taken                  ( irq_taken                 ),
    .dbg_taken                  ( dbg_taken                 ),
    .excp_taken                 ( excp_taken                ),

    .dbg_irq                    ( dbg_irq                   ),
    .dbg_halt                   ( dbg_halt                  ),
    .dbg_step                   ( dbg_step                  ),
    .dbg_trig                   ( dbg_trig                  ),

    .dcsr_ebreakm               ( dcsr_ebreakm              ),
    .dcsr_step                  ( dcsr_step                 ),
    .dcsr_stepie                ( dcsr_stepie               ),

    .mepc_wen                   ( mepc_wen                  ),
    .mepc_wdata                 ( mepc_wdata                ),
    .mcause_wen                 ( mcause_wen                ),
    .mcause_wdata               ( mcause_wdata              ),
    .mtval_wen                  ( mtval_wen                 ),
    .mtval_wdata                ( mtval_wdata               ),
    .dpc_wen                    ( dpc_wen                   ),
    .dpc_wdata                  ( dpc_wdata                 ),
    .dcause_wen                 ( dcause_wen                ),
    .dcause_wdata               ( dcause_wdata              ),

    .pipe_flush_req             ( pipe_flush_req            ),
    .pipe_flush_ack             ( pipe_flush_ack            ),
    .pipe_flush_pc_op1          ( pipe_flush_pc_op1         ),
    .pipe_flush_pc_op2          ( pipe_flush_pc_op2         ),

    .gpr_wbck_vld               ( gpr_wbck_vld              ),
    .gpr_wbck_rdy               ( gpr_wbck_rdy              ),
    .gpr_wbck_idx               ( gpr_wbck_idx              ),
    .gpr_wbck_data              ( gpr_wbck_data             ),

    .csr_wbck_vld               ( csr_wbck_vld              ),
    .csr_wbck_rdy               ( csr_wbck_rdy              ),
    .csr_wbck_idx               ( csr_wbck_idx              ),
    .csr_wbck_data              ( csr_wbck_data             ),

    .cmt_mret                   ( cmt_mret                  ),
    .cmt_dret                   ( cmt_dret                  ),

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
    .reset_mtvec                ( reset_mtvec               ),
    
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