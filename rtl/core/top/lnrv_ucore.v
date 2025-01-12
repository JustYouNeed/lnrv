`include	"lnrv_def.v"
module  lnrv_ucore#
(
    // 取指模块的预取数
    parameter                               P_IFU_OTS_COUNT = 3
)
(
    input[31 : 0]                           reset_vector,
    input[31 : 0]                           reset_mtvec,

    input                                   firmware_loading,

    // 中断信号
    input                                   irq_sft,
    input                                   irq_ext,
    input                                   irq_tmr,

    input                                   dbg_halt,
    input                                   irq_dbg,

    // wfi模式指示信号，为高时表示处于wfi模式中
    output                                  wfi_mode,

    // debug mode指示信号
    output                                  d_mode,

    output                                  dcsr_stoptime,
    output                                  dcsr_stopcount,

    // 取指总线
    output                                  icb_cmd_vld_ifu,
    input                                   icb_cmd_rdy_ifu,
    output                                  icb_cmd_write_ifu,
    output[31 : 0]                          icb_cmd_addr_ifu,
    output[31 : 0]                          icb_cmd_wdata_ifu,
    output[3 : 0]                           icb_cmd_wstrb_ifu,
    output[2 : 0]                           icb_cmd_size_ifu,
    input                                   icb_rsp_vld_ifu,
    output                                  icb_rsp_rdy_ifu,
    input[31 : 0]                           icb_rsp_rdata_ifu,
    input                                   icb_rsp_err_ifu,

    // 系统访存总线
    output                                  icb_cmd_vld_lsu,
    input                                   icb_cmd_rdy_lsu,
    output                                  icb_cmd_write_lsu,
    output[31 : 0]                          icb_cmd_addr_lsu,
    output[31 : 0]                          icb_cmd_wdata_lsu,
    output[3 : 0]                           icb_cmd_wstrb_lsu,
    output[2 : 0]                           icb_cmd_size_lsu,
    input                                   icb_rsp_vld_lsu,
    output                                  icb_rsp_rdy_lsu,
    input[31 : 0]                           icb_rsp_rdata_lsu,
    input                                   icb_rsp_err_lsu,

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

wire                                    pipe_flush_req_cmt;
wire                                    pipe_flush_ack_cmt;
wire                                    pipe_flush_ack_cmt_ifu;
wire                                    pipe_flush_ack_cmt_idu;
wire[31 : 0]                            pipe_flush_pc_op1_cmt;
wire[31 : 0]                            pipe_flush_pc_op2_cmt;

wire                                    pipe_flush_req_bpu;
wire                                    pipe_flush_ack_bpu;
wire[31 : 0]                            pipe_flush_pc_op1_bpu;
wire[31 : 0]                            pipe_flush_pc_op2_bpu;

wire                                    ifu_vld;
wire                                    ifu_rdy;
wire[`CPU_ADDR_WIDTH - 1 : 0]           ifu_pc;
wire[`CPU_DATA_WIDTH - 1 : 0]           ifu_ir;
wire                                    ifu_excp_misalgn;
wire                                    ifu_excp_buserr;

wire                                    idu_vld;
wire                                    idu_rdy;
wire                                    idu_excp_ilglir;
wire                                    idu_excp_misalgn;
wire                                    idu_excp_buserr;
wire[31 : 0]                            idu_ir;
wire[31 : 0]                            idu_pc;
wire[31 : 0]                            idu_imm;
wire[4 : 0]                             idu_rs1;
wire[4 : 0]                             idu_rs2;
wire[4 : 0]                             idu_rd;
wire[11 : 0]                            idu_csr;
wire[`DEC_OP_BUS_WIDTH - 1 : 0]         idu_op_bus;
wire[`DEC_OP_TYPE_WIDTH - 1 : 0]        idu_op_type;
wire                                    idu_rv32;
wire                                    idu_prdt_taken;

wire                                    pipe_halt_req;
wire                                    pipe_halt_ack;
wire                                    pipe_halt_ack_ifu;
wire                                    pipe_halt_ack_idu;

wire                                    cmt_vld;
wire                                    cmt_rdy;
wire                                    cmt_rv32_ir;
wire                                    cmt_prdt_taken;
wire                                    cmt_brch_dret;
wire                                    cmt_brch_mret;
wire                                    cmt_brch_fence;
wire                                    cmt_brch_jal;
wire                                    cmt_brch_jalr;
wire                                    cmt_brch_bjp;
wire                                    cmt_csr_idx_err;
wire                                    cmt_csr;
wire                                    cmt_rglr;
wire                                    cmt_ifu_excp_buserr;
wire                                    cmt_ifu_excp_misalgn;
wire                                    cmt_idu_excp_ilglir;
wire                                    cmt_sys_ebreak;
wire                                    cmt_sys_ecall;
wire                                    cmt_sys_wfi;
wire                                    cmt_lsu_ld;
wire                                    cmt_lsu_st;
wire                                    cmt_lsu_excp_misalgn;
wire                                    cmt_lsu_excp_buserr;
wire[31 : 0]                            cmt_lsu_addr;

wire                                    cmted_dret;
wire                                    cmted_mret;
wire                                    irq_taken;
wire                                    excp_taken;
wire                                    dbg_taken;

wire                                    mepc_wen;
wire[31 : 0]                            mepc_wdata;

wire                                    mcause_wen;
wire[31 : 0]                            mcause_wdata;

wire                                    mtval_wen;
wire[31 : 0]                            mtval_wdata;

wire                                    dpc_wen;
wire[31 : 0]                            dpc_wdata;

wire                                    dcause_wen;
wire[2 : 0]                             dcause_wdata;

wire                                    csr_idx_err;

wire                                    m_mode;

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

wire                                    dec_ir_jal;
wire                                    dec_ir_jalr;
wire                                    dec_ir_fence;
wire                                    dec_ir_bxx;
wire[31 : 0]                            dec_imm_bxx;
wire[31 : 0]                            dec_imm_jal;
wire[31 : 0]                            dec_imm_jalr;
wire                                    dec_rs1_x1;

wire                                    bpu_prdt_res;
wire[31 : 0]                            gpr_x1;

wire[31 : 0]                            mepc;
wire[31 : 0]                            dpc;
wire[31 : 0]                            mtvec;
wire                                    mie_msie;
wire                                    mie_mtie;
wire                                    mie_meie;
wire                                    mstatus_mie;


assign      pipe_flush_ack_cmt = pipe_flush_ack_cmt_ifu & pipe_flush_ack_cmt_idu;

assign      pipe_halt_ack = pipe_halt_ack_ifu & pipe_halt_ack_idu;

// 取指模块
lnrv_ifu#
(
    .P_OTS_COUNT                ( P_IFU_OTS_COUNT           )
)
u_lnrv_ifu
(
    .clk                        ( clk                       ),
    .reset_n                    ( reset_n                   ),

    .ifu_active                 ( ifu_active                ),

    .firmware_loading           ( firmware_loading          ),

    .reset_vector               ( reset_vector              ),

    .pipe_flush_req_cmt         ( pipe_flush_req_cmt        ),
    .pipe_flush_ack_cmt         ( pipe_flush_ack_cmt_ifu    ),
    .pipe_flush_pc_op1_cmt      ( pipe_flush_pc_op1_cmt     ),
    .pipe_flush_pc_op2_cmt      ( pipe_flush_pc_op2_cmt     ),

    .pipe_flush_req_bpu         ( pipe_flush_req_bpu        ),
    .pipe_flush_ack_bpu         ( pipe_flush_ack_bpu        ),
    .pipe_flush_pc_op1_bpu      ( pipe_flush_pc_op1_bpu     ),
    .pipe_flush_pc_op2_bpu      ( pipe_flush_pc_op2_bpu     ),

    .pipe_halt_req              ( pipe_halt_req             ),
    .pipe_halt_ack              ( pipe_halt_ack_ifu         ),

    .ifu_vld                    ( ifu_vld                   ),
    .ifu_rdy                    ( ifu_rdy                   ),
    .ifu_pc                     ( ifu_pc                    ),
    .ifu_ir                     ( ifu_ir                    ),
    .ifu_excp_misalgn           ( ifu_excp_misalgn          ),
    .ifu_excp_buserr            ( ifu_excp_buserr           ),

    .icb_cmd_vld                ( icb_cmd_vld_ifu           ),
    .icb_cmd_rdy                ( icb_cmd_rdy_ifu           ),
    .icb_cmd_write              ( icb_cmd_write_ifu         ),
    .icb_cmd_addr               ( icb_cmd_addr_ifu          ),
    .icb_cmd_wdata              ( icb_cmd_wdata_ifu         ),
    .icb_cmd_wstrb              ( icb_cmd_wstrb_ifu         ),
    .icb_cmd_size               ( icb_cmd_size_ifu          ),
    .icb_rsp_vld                ( icb_rsp_vld_ifu           ),
    .icb_rsp_rdy                ( icb_rsp_rdy_ifu           ),
    .icb_rsp_rdata              ( icb_rsp_rdata_ifu         ),
    .icb_rsp_err                ( icb_rsp_err_ifu           )
);

// 译码模块
lnrv_idu u_lnrv_idu
(
    .idu_active                 ( idu_active                ),

    .pipe_halt_req              ( pipe_halt_req             ),
    .pipe_halt_ack              ( pipe_halt_ack_idu         ),

    .ifu_vld                    ( ifu_vld                   ),
    .ifu_rdy                    ( ifu_rdy                   ),
    .ifu_ir                     ( ifu_ir                    ),
    .ifu_pc                     ( ifu_pc                    ),
    .ifu_excp_misalgn           ( ifu_excp_misalgn          ),
    .ifu_excp_buserr            ( ifu_excp_buserr           ),

    .pipe_flush_req_cmt         ( pipe_flush_req_cmt        ),
    .pipe_flush_ack_cmt         ( pipe_flush_ack_cmt_idu    ),

    .d_mode                     ( d_mode                    ),

    .gpr_x1                     ( gpr_x1                    ),

    .pipe_flush_req_bpu         ( pipe_flush_req_bpu        ),
    .pipe_flush_ack_bpu         ( pipe_flush_ack_bpu        ),
    .pipe_flush_pc_op1_bpu      ( pipe_flush_pc_op1_bpu     ),
    .pipe_flush_pc_op2_bpu      ( pipe_flush_pc_op2_bpu     ),

    .idu_excp_ilglir            ( idu_excp_ilglir           ),
    .idu_excp_misalgn           ( idu_excp_misalgn          ),
    .idu_excp_buserr            ( idu_excp_buserr           ),

    .idu_vld                    ( idu_vld                   ),
    .idu_rdy                    ( idu_rdy                   ),
    .idu_ir                     ( idu_ir                    ),
    .idu_pc                     ( idu_pc                    ),
    .idu_imm                    ( idu_imm                   ),
    .idu_rs1                    ( idu_rs1                   ),
    .idu_rs2                    ( idu_rs2                   ),
    .idu_csr                    ( idu_csr                   ),
    .idu_rd                     ( idu_rd                    ),
    .idu_op_bus                 ( idu_op_bus                ),
    .idu_op_type                ( idu_op_type               ),
    .idu_rv32                   ( idu_rv32                  ),
    .idu_prdt_taken             ( idu_prdt_taken            ),


    .clk                        ( clk                       ),
    .reset_n                    ( reset_n                   )
);

// 指令执行模块
lnrv_exu u_lnrv_exu
(
    .exu_active                 ( exu_active                ),

    // 译码模块输入
    .idu_vld                    ( idu_vld                   ),
    .idu_rdy                    ( idu_rdy                   ),
    .idu_op_bus                 ( idu_op_bus                ),
    .idu_op_type                ( idu_op_type               ),
    .idu_imm                    ( idu_imm                   ),
    .idu_pc                     ( idu_pc                    ),
    .idu_ir                     ( idu_ir                    ),
    .idu_rd                     ( idu_rd                    ),
    .idu_excp_ilglir            ( idu_excp_ilglir           ),
    .idu_excp_misalgn           ( idu_excp_misalgn          ),
    .idu_excp_buserr            ( idu_excp_buserr           ),
    .idu_rv32                   ( idu_rv32                  ),
    .idu_prdt_taken             ( idu_prdt_taken            ),

    // 寄存器读接口
    .rs1_rdata                  ( rs1_rdata                 ),
    .rs2_rdata                  ( rs2_rdata                 ),
    .csr_rdata                  ( csr_rdata                 ),
    .csr_idx_err                ( csr_idx_err               ),

    // 交付接口
    .cmt_vld                    ( cmt_vld                   ),
    .cmt_rdy                    ( cmt_rdy                   ),
    .cmt_rv32_ir                ( cmt_rv32_ir               ),
    .cmt_brch_dret              ( cmt_brch_dret             ),
    .cmt_brch_mret              ( cmt_brch_mret             ),
    .cmt_brch_fence             ( cmt_brch_fence            ),
    .cmt_brch_bjp               ( cmt_brch_bjp              ),
    .cmt_brch_jal               ( cmt_brch_jal              ),
    .cmt_brch_jalr              ( cmt_brch_jalr             ),
    .cmt_prdt_taken             ( cmt_prdt_taken            ),

    .cmt_idu_excp_ilglir        ( cmt_idu_excp_ilglir       ),
    .cmt_ifu_excp_buserr        ( cmt_ifu_excp_buserr       ),
    .cmt_ifu_excp_misalgn       ( cmt_ifu_excp_misalgn      ),

    .cmt_csr_idx_err            ( cmt_csr_idx_err           ),
    .cmt_csr                    ( cmt_csr                   ),

    .cmt_rglr                   ( cmt_rglr                  ),
    .cmt_sys_ebreak             ( cmt_sys_ebreak            ),
    .cmt_sys_ecall              ( cmt_sys_ecall             ),
    .cmt_sys_wfi                ( cmt_sys_wfi               ),

    .cmt_lsu_ld                 ( cmt_lsu_ld                ),
    .cmt_lsu_st                 ( cmt_lsu_st                ),
    .cmt_lsu_excp_misalgn       ( cmt_lsu_excp_misalgn      ),
    .cmt_lsu_excp_buserr        ( cmt_lsu_excp_buserr       ),
    .cmt_lsu_addr               ( cmt_lsu_addr              ),

    // 通用寄存器写回接口
    .gpr_wbck_vld               ( gpr_wbck_vld              ),
    .gpr_wbck_rdy               ( gpr_wbck_rdy              ),
    .gpr_wbck_idx               ( gpr_wbck_idx              ),
    .gpr_wbck_wdata             ( gpr_wbck_wdata            ),

    // CSR寄存器写回接口
    .csr_wbck_vld               ( csr_wbck_vld              ),
    .csr_wbck_rdy               ( csr_wbck_rdy              ),
    .csr_wbck_wdata             ( csr_wbck_wdata            ),

    // 访存接口
    .icb_cmd_vld                ( icb_cmd_vld_lsu           ),
    .icb_cmd_rdy                ( icb_cmd_rdy_lsu           ),
    .icb_cmd_write              ( icb_cmd_write_lsu         ),
    .icb_cmd_addr               ( icb_cmd_addr_lsu          ),
    .icb_cmd_wdata              ( icb_cmd_wdata_lsu         ),
    .icb_cmd_wstrb              ( icb_cmd_wstrb_lsu         ),
    .icb_cmd_size               ( icb_cmd_size_lsu          ),
    .icb_rsp_vld                ( icb_rsp_vld_lsu           ),
    .icb_rsp_rdy                ( icb_rsp_rdy_lsu           ),
    .icb_rsp_rdata              ( icb_rsp_rdata_lsu         ),
    .icb_rsp_err                ( icb_rsp_err_lsu           ),

    .clk                        ( clk                       ),
    .reset_n                    ( reset_n                   )
);

lnrv_cmt u_lnrv_cmt
(
    .ifu_vld                    ( ifu_vld                   ),
    .ifu_pc                     ( ifu_pc                    ),

    .idu_vld                    ( idu_vld                   ),
    .idu_pc                     ( idu_pc                    ),
    .idu_ir                     ( idu_ir                    ),
    .idu_imm                    ( idu_imm                   ),

    .cmt_vld                    ( cmt_vld                   ),
    .cmt_rdy                    ( cmt_rdy                   ),
    .cmt_rv32_ir                ( cmt_rv32_ir               ),
    .cmt_idu_excp_ilglir        ( cmt_idu_excp_ilglir       ),
    .cmt_ifu_excp_buserr        ( cmt_ifu_excp_buserr       ),
    .cmt_ifu_excp_misalgn       ( cmt_ifu_excp_misalgn      ),
    .cmt_brch_dret              ( cmt_brch_dret             ),
    .cmt_brch_mret              ( cmt_brch_mret             ),
    .cmt_brch_jal               ( cmt_brch_jal              ),
    .cmt_brch_jalr              ( cmt_brch_jalr             ),
    .cmt_brch_fence             ( cmt_brch_fence            ),
    .cmt_brch_bjp               ( cmt_brch_bjp              ),
    .cmt_prdt_taken             ( cmt_prdt_taken            ),
    .cmt_rglr                   ( cmt_rglr                  ),
    .cmt_csr                    ( cmt_csr                   ),
    .cmt_csr_idx_err            ( cmt_csr_idx_err           ),
    .cmt_sys_ebreak             ( cmt_sys_ebreak            ),
    .cmt_sys_ecall              ( cmt_sys_ecall             ),
    .cmt_sys_wfi                ( cmt_sys_wfi               ),
    .cmt_lsu_ld                 ( cmt_lsu_ld                ),
    .cmt_lsu_st                 ( cmt_lsu_st                ),
    .cmt_lsu_excp_misalgn       ( cmt_lsu_excp_misalgn      ),
    .cmt_lsu_excp_buserr        ( cmt_lsu_excp_buserr       ),
    .cmt_lsu_addr               ( cmt_lsu_addr              ),

    .irq_sft                    ( irq_sft                   ),
    .irq_ext                    ( irq_ext                   ),
    .irq_tmr                    ( irq_tmr                   ),

    .mie_meie                   ( mie_meie                  ),
    .mie_mtie                   ( mie_mtie                  ),
    .mie_msie                   ( mie_msie                  ),
    .mstatus_mie                ( mstatus_mie               ),

    .dpc                        ( dpc                       ),
    .mepc                       ( mepc                      ),
    .mtvec                      ( mtvec                     ),
    .rs1_rdata                  ( rs1_rdata                 ),

    .d_mode                     ( d_mode                    ),
    .m_mode                     ( m_mode                    ),
    .wfi_mode                   ( wfi_mode                  ),

    .irq_taken                  ( irq_taken                 ),
    .dbg_taken                  ( dbg_taken                 ),
    .excp_taken                 ( excp_taken                ),

    .irq_dbg                    ( irq_dbg                   ),
    .dbg_halt                   ( dbg_halt                  ),
    .dbg_step                   ( 1'b0                      ),
    .dbg_trig                   ( 1'b0                      ),

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

    .pipe_flush_req             ( pipe_flush_req_cmt        ),
    .pipe_flush_ack             ( pipe_flush_ack_cmt        ),
    .pipe_flush_pc_op1          ( pipe_flush_pc_op1_cmt     ),
    .pipe_flush_pc_op2          ( pipe_flush_pc_op2_cmt     ),

    .pipe_halt_req              ( pipe_halt_req             ),
    .pipe_halt_ack              ( pipe_halt_ack             ),

    .cmted_mret                 ( cmted_mret                ),
    .cmted_dret                 ( cmted_dret                ),

    .clk                        ( clk                       ),
    .reset_n                    ( reset_n                   )
);


// 通用寄存器组
lnrv_gpr#(
    .P_ADDR_WIDTH               ( 5                         )
)
u_lnrv_gpr
(
    .rs1_idx                    ( idu_rs1                   ),
    .rs1_rdata                  ( rs1_rdata                 ),
    .rs2_idx                    ( idu_rs2                   ),
    .rs2_rdata                  ( rs2_rdata                 ),

    .wr_vld                     ( gpr_wbck_vld              ),
    .wr_rdy                     ( gpr_wbck_rdy              ),
    .wr_idx                     ( gpr_wbck_idx              ),
    .wr_data                    ( gpr_wbck_wdata            ),

    .gpr_x1                     ( gpr_x1                    ),

    .clk                        ( clk                       ),
    .reset_n                    ( reset_n                   )
);

// control and status regter
lnrv_csr u_lnrv_csr
(
    .reset_mtvec                ( reset_mtvec               ),

    .mepc                       ( mepc                      ),
    .mtvec                      ( mtvec                     ),

    .dcsr_step                  ( dcsr_step                 ),
    .dcsr_stepie                ( dcsr_stepie               ),
    .dcsr_ebreakm               ( dcsr_ebreakm              ),
    .dcsr_stoptime              ( dcsr_stoptime             ),
    .dcsr_stopcount             ( dcsr_stopcount            ),
    .dpc                        ( dpc                       ),
    .d_mode                     ( d_mode                    ),
    .m_mode                     ( m_mode                    ),

    .irq_sft                    ( irq_sft                   ),
    .irq_tmr                    ( irq_tmr                   ),
    .irq_ext                    ( irq_ext                   ),

    .mie_msie                   ( mie_msie                  ),
    .mie_mtie                   ( mie_mtie                  ),
    .mie_meie                   ( mie_meie                  ),
    .mstatus_mie                ( mstatus_mie               ),


    .excp_taken                 ( excp_taken                ),
    .irq_taken                  ( irq_taken                 ),
    .dbg_taken                  ( dbg_taken                 ),
    .cmted_mret                 ( cmted_mret                ),
    .cmted_dret                 ( cmted_dret                ),

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

    .csr_idx_err                ( csr_idx_err               ),
    .csr_idx                    ( idu_csr                   ),
    .csr_rdata                  ( csr_rdata                 ),

    .wbck_vld                   ( csr_wbck_vld              ),
    .wbck_rdy                   ( csr_wbck_rdy              ),
    .wbck_wdata                 ( csr_wbck_wdata            ),

    .clk                        ( clk                       ),
    .reset_n                    ( reset_n                   )
);


endmodule