`include	"lnrv_def.v"
module  lnrv_exu#
(
    parameter                               P_ILM_REGION_START = 32'h8000_0000,
    parameter                               P_ILM_REGION_END = 32'hf000_0000,

    parameter                               P_DLM_REGION_START = 32'h8000_0000,
    parameter                               P_DLM_REGION_END = 32'hf000_0000,

    parameter                               P_BIU_REGION_START = 32'h8000_0000,
    parameter                               P_BIU_REGION_END = 32'hf000_0000
)
(
    output                                  exu_active,

    // 译码信息
    input                                   idu_pc_vld,
    output                                  idu_pc_rdy,
    input                                   idu_rlgr_instr,
    input                                   idu_lsu_instr,
    input                                   idu_brch_instr,
    input                                   idu_mdv_instr,
    input                                   idu_sys_instr,
    input                                   idu_csr_instr,
    input                                   idu_amo_instr,
    input[`DEC_OP_BUS_WIDTH - 1 : 0]        idu_op_bus,
    input[4 : 0]                            idu_rs1_idx,
    input[4 : 0]                            idu_rs2_idx,
    input[4 : 0]                            idu_rd_idx,
    input[11 : 0]                           idu_csr_idx,
    input[31 : 0]                           idu_imm,
    input[31 : 0]                           idu_pc,
    input[31 : 0]                           idu_ir,

    // 前级模块产生的异常信息
    input                                   ifu_excp_misalgn,        // 地址非对齐
    input                                   ifu_excp_buserr,         // 总线错误
    input                                   idu_excp_ilgl_ir,   // 非法指令

    input                                   ifu_pc_vld,
    input[31 : 0]                           ifu_pc,

    input[31 : 0]                           rs1_rdata,
    input[31 : 0]                           rs2_rdata,
    input[31 : 0]                           csr_rdata,
    input                                   csr_idx_err,

    // 流水线冲刷请求
    output                                  pipe_flush_req,
    input                                   pipe_flush_ack,
    output[31 : 0]                          pipe_flush_pc_op1,
    output[31 : 0]                          pipe_flush_pc_op2,

    // 流水线暂停请求
    output                                  pipe_halt_req,
    input                                   pipe_halt_ack,

    // 中断信号
    input                                   sft_irq,
    input                                   ext_irq,
    input                                   tmr_irq,
    
    // 中断使能
    input                                   sft_irq_en,
    input                                   ext_irq_en,
    input                                   tmr_irq_en,

    input                                   d_mode,
    input                                   m_mode,
    // wfi模式指示信号，为高时表示处于wfi模式中
    output                                  wfi_mode,


    input                                   dbg_halt,
    input                                   dbg_irq,

    input                                   dcsr_ebreakm,
    input                                   dcsr_stepie,
    input                                   dcsr_step,

    // 通用寄存器写回接口       
    output                                  gpr_wbck_vld,
    input                                   gpr_wbck_rdy,
    output[4 : 0]                           gpr_wbck_idx,
    output[31 : 0]                          gpr_wbck_wdata,

    // csr寄存器写回接口
    output                                  csr_wbck_vld,
    input                                   csr_wbck_rdy,
    output[11 : 0]                          csr_wbck_idx,
    output[31 : 0]                          csr_wbck_wdata,

    input                                   mstatus_mie,
    input[31 : 0]                           mtvec,
    input[31 : 0]                           mepc,
    input[31 : 0]                           dpc,

    // 交付接口
    output                                  irq_taken,
    output                                  excp_taken,
    output                                  dbg_taken,

    output                                  mepc_wdata_vld,
    output[31 : 0]                          mepc_wdata,
    output                                  mtval_wdata_vld,
    output[31 : 0]                          mtval_wdata,
    output                                  mcause_wdata_vld,
    output[31 : 0]                          mcause_wdata,
    
    output                                  dpc_wdata_vld,
    output[31 : 0]                          dpc_wdata,
    output                                  dcause_wdata_vld,
    output[2 : 0]                           dcause_wdata,

    output                                  exu_cmd_vld,
    input                                   exu_cmd_rdy,
    output                                  exu_cmd_write,
    output[31 : 0]                          exu_cmd_addr,
    output[31 : 0]                          exu_cmd_wdata,
    output[3 : 0]                           exu_cmd_wstrb,
    output[2 : 0]                           exu_cmd_size,
    input                                   exu_rsp_vld,
    output                                  exu_rsp_rdy,
    input[31 : 0]                           exu_rsp_rdata,
    input                                   exu_rsp_err,

    input                                   clk,
    input                                   reset_n
);

wire                                rglr_op_vld;
wire                                rglr_op_rdy;
wire[`RGLR_OP_BUS_WIDTH - 1 : 0]    rglr_op_bus;

wire                                lsu_op_vld;
wire                                lsu_op_rdy;
wire[`LSU_OP_BUS_WIDTH - 1 : 0]     lsu_op_bus;

wire                                brch_op_vld;
wire                                brch_op_rdy;
wire[`BRCH_OP_BUS_WIDTH - 1 : 0]    brch_op_bus;

wire                                sys_op_vld;
wire                                sys_op_rdy;
wire[`SYS_OP_BUS_WIDTH - 1 : 0]     sys_op_bus;

wire                                csr_op_vld;
wire                                csr_op_rdy;
wire[`CSR_OP_BUS_WIDTH - 1 : 0]     csr_op_bus;

wire                                mdv_op_vld;
wire                                mdv_op_rdy;
wire[`MDV_OP_BUS_WIDTH - 1 : 0]     mdv_op_bus;

wire                            disp_vld;
wire                            disp_hsked;
wire                            disp_idle;

wire                            rglr2alu_op_vld;
wire                            rglr2alu_op_rdy;
wire[`ALU_OP_BUS_WIDTH - 1 : 0] rglr2alu_op_bus;
wire[31 : 0]                    rglr2alu_in1;
wire[31 : 0]                    rglr2alu_in2;

wire                            brch2alu_op_vld;
wire                            brch2alu_op_rdy;
wire[`ALU_OP_BUS_WIDTH - 1 : 0] brch2alu_op_bus;
wire[31 : 0]                    brch2alu_in1;
wire[31 : 0]                    brch2alu_in2;

wire                            lsu2alu_op_vld;
wire                            lsu2alu_op_rdy;
wire[`ALU_OP_BUS_WIDTH - 1 : 0] lsu2alu_op_bus;
wire[31 : 0]                    lsu2alu_in1;
wire[31 : 0]                    lsu2alu_in2;

wire                            csr2alu_op_vld;
wire                            csr2alu_op_rdy;
wire[`ALU_OP_BUS_WIDTH - 1 : 0] csr2alu_op_bus;
wire[31 : 0]                    csr2alu_in1;
wire[31 : 0]                    csr2alu_in2;

wire                            alu_op_vld;
wire                            alu_op_rdy;
wire[`ALU_OP_BUS_WIDTH - 1 : 0] alu_op_bus;
wire[31 : 0]                    alu_in1;
wire[31 : 0]                    alu_in2;
wire[31 : 0]                    alu_res;

wire                            rglr2gpr_wbck_vld;
wire                            rglr2gpr_wbck_rdy;

wire                            brch2gpr_wbck_vld;
wire                            brch2gpr_wbck_rdy;

wire                            lsu2gpr_wbck_vld;
wire                            lsu2gpr_wbck_rdy;
wire [31:0]                     lsu2gpr_wbck_wdata;

wire                            csr2gpr_wbck_vld;
wire                            csr2gpr_wbck_rdy;
wire[31 : 0]                    csr2gpr_wbck_wdata;

wire                            mdv2gpr_wbck_vld;
wire                            mdv2gpr_wbck_rdy;
wire[31 : 0]                    mdv2gpr_wbck_wdata;


wire                            brch_pipe_flush_req;
wire                            brch_pipe_flush_ack;
wire[31 : 0]                    brch_pipe_flush_pc_op1;
wire[31 : 0]                    brch_pipe_flush_pc_op2;

wire                            excp_pipe_flush_req;
wire                            excp_pipe_flush_ack;
wire[31 : 0]                    excp_pipe_flush_pc_op1;
wire[31 : 0]                    excp_pipe_flush_pc_op2;

wire                            irq_pipe_flush_req;
wire                            irq_pipe_flush_ack;
wire[31 : 0]                    irq_pipe_flush_pc_op1;
wire[31 : 0]                    irq_pipe_flush_pc_op2;

wire                            debug_pipe_flush_req;
wire                            debug_pipe_flush_ack;
wire[31 : 0]                    debug_pipe_flush_pc_op1;
wire[31 : 0]                    debug_pipe_flush_pc_op2;


wire                            sys_excp_vld;
wire                            sys_excp_rdy;
wire                            sys_excp_ecall;
wire                            sys_excp_ebreak;

wire                            lsu_excp_vld;
wire                            lsu_excp_rdy;
wire                            lsu_ld_addr_misalgn;
wire                            lsu_ld_access_fault;
wire                            lsu_st_addr_misalgn;
wire                            lsu_st_access_fault;
wire[31 : 0]                    lsu_bad_addr;


wire                            irq_taken;
wire                            dbg_taken;

wire                            irq_cmt_csr;
wire[31 : 0]                    irq_cmt_mepc;
wire[31 : 0]                    irq_cmt_mcause;


wire                            excp_cmt_csr;
wire[31 : 0]                    excp_cmt_mepc;
wire[31 : 0]                    excp_cmt_mcause;
wire[31 : 0]                    excp_cmt_mtval;
wire                            excp_cmt_dcsr;
wire[31 : 0]                    excp_cmt_dpc;
wire[2 : 0]                     excp_cmt_dcause;



wire                            debug_cmt_dcsr;
wire[31 : 0]                    debug_cmt_dpc;
wire[2 : 0]                     debug_cmt_dcause;



// 指令派遣模块
lnrv_exu_disp u_lnrv_exu_disp
(
    .dec_rglr_instr             ( dec_rglr_instr            ),
    .dec_brch_instr             ( dec_brch_instr            ),
    .dec_csr_instr              ( dec_csr_instr             ),
    .dec_sys_instr              ( dec_sys_instr             ),
    .dec_mdv_instr              ( dec_mdv_instr             ),
    .dec_lsu_instr              ( dec_lsu_instr             ),
    .dec_op_bus                 ( dec_op_bus                ),
    .dec_op_vld                 ( dec_op_vld                ),
    .dec_op_rdy                 ( dec_op_rdy                ),
    .dec_idu_ilegal_instr       ( dec_idu_ilegal_instr      ),
    .dec_ifu_buserr             ( dec_ifu_buserr            ),
    .dec_ifu_misalgn            ( dec_ifu_misalgn           ),

    .rglr_op_vld                ( rglr_op_vld               ),
    .rglr_op_rdy                ( rglr_op_rdy               ),
    .rglr_op_bus                ( rglr_op_bus               ),

    .lsu_op_vld                 ( lsu_op_vld                ),
    .lsu_op_rdy                 ( lsu_op_rdy                ),
    .lsu_op_bus                 ( lsu_op_bus                ),

    .brch_op_vld                ( brch_op_vld               ),
    .brch_op_rdy                ( brch_op_rdy               ),
    .brch_op_bus                ( brch_op_bus               ),

    .csr_op_vld                 ( csr_op_vld                ),
    .csr_op_rdy                 ( csr_op_rdy                ),
    .csr_op_bus                 ( csr_op_bus                ),

    .sys_op_vld                 ( sys_op_vld                ),
    .sys_op_rdy                 ( sys_op_rdy                ),
    .sys_op_bus                 ( sys_op_bus                ),

    .mdv_op_vld                 ( mdv_op_vld                ),
    .mdv_op_rdy                 ( mdv_op_rdy                ),
    .mdv_op_bus                 ( mdv_op_bus                ),

    .disp_vld                   ( disp_vld                  ),
    .disp_hsked                 ( disp_hsked                ),
    .disp_idle                  ( disp_idle                 )
);

// 常规指令执行模块
lnrv_exu_rglr u_lnrv_exu_rglr
(
    .rglr_op_vld                ( rglr_op_vld               ),
    .rglr_op_rdy                ( rglr_op_rdy               ),
    .rglr_op_bus                ( rglr_op_bus               ),

    .rs1_rdata                  ( rs1_rdata                 ),
    .rs2_rdata                  ( rs2_rdata                 ),
    .imm                        ( dec_imm                   ),
    .pc                         ( dec_pc                    ),

    .rglr2alu_op_vld            ( rglr2alu_op_vld           ),
    .rglr2alu_op_rdy            ( rglr2alu_op_rdy           ),
    .rglr2alu_op_bus            ( rglr2alu_op_bus           ),
    .rglr2alu_in1               ( rglr2alu_in1              ),
    .rglr2alu_in2               ( rglr2alu_in2              ),

    .rglr2gpr_wbck_vld          ( rglr2gpr_wbck_vld         ),
    .rglr2gpr_wbck_rdy          ( rglr2gpr_wbck_rdy         )
);

// csr指令处理模块 
lnrv_exu_csr u_lnrv_exu_csr
(
    .csr_op_vld                 ( csr_op_vld                ),
    .csr_op_rdy                 ( csr_op_rdy                ),
    .csr_op_bus                 ( csr_op_bus                ),

    .imm                        ( dec_imm                   ),

    .csr_idx                    ( dec_csr_idx               ),
    .csr_rdata                  ( csr_rdata                 ),
    .rs1_rdata                  ( rs1_rdata                 ),

    .alu_op_vld                 ( csr2alu_op_vld            ),
    .alu_op_rdy                 ( csr2alu_op_rdy            ),
    .alu_op_bus                 ( csr2alu_op_bus            ),
    .alu_in1                    ( csr2alu_in1               ),
    .alu_in2                    ( csr2alu_in2               ),
    .alu_res                    ( alu_res                   ),

    .csr2gpr_wbck_vld           ( csr2gpr_wbck_vld          ),
    .csr2gpr_wbck_rdy           ( csr2gpr_wbck_rdy          ),
    .csr2gpr_wbck_wdata         ( csr2gpr_wbck_wdata        ),

    .csr_wbck_vld               ( csr_wbck_vld              ),
    .csr_wbck_rdy               ( csr_wbck_rdy              ),
    .csr_wbck_idx               ( csr_wbck_idx              ),
    .csr_wbck_wdata             ( csr_wbck_wdata            )
);

// 分支相关指令执行模块
lnrv_exu_brch u_lnrv_exu_brch
(
    .brch_op_vld                ( brch_op_vld               ),
    .brch_op_rdy                ( brch_op_rdy               ),
    .brch_op_bus                ( brch_op_bus               ),
    
    .rs1_rdata                  ( rs1_rdata                 ),
    .rs2_rdata                  ( rs2_rdata                 ),
    .pc                         ( dec_pc                    ),
    .imm                        ( dec_imm                   ),
    
    .alu_op_vld                 ( brch2alu_op_vld           ),
    .alu_op_rdy                 ( brch2alu_op_rdy           ),
    .alu_op_bus                 ( brch2alu_op_bus           ),
    .alu_in1                    ( brch2alu_in1              ),
    .alu_in2                    ( brch2alu_in2              ),
    .alu_res                    ( alu_res                   ),

    .dpc                        ( dpc                       ),
    .mepc                       ( mepc                      ),

    .cmt_mret                   ( cmt_mret                  ),
    .cmt_dret                   ( cmt_dret                  ),

    .pipe_flush_req             ( brch_pipe_flush_req       ),
    .pipe_flush_ack             ( brch_pipe_flush_ack       ),
    .pipe_flush_pc_op1          ( brch_pipe_flush_pc_op1    ),
    .pipe_flush_pc_op2          ( brch_pipe_flush_pc_op2    ),

    .brch2gpr_wbck_vld          ( brch2gpr_wbck_vld         ),
    .brch2gpr_wbck_rdy          ( brch2gpr_wbck_rdy         )
);


// 乘除法指令执行模块
lnrv_exu_mdv u_lnrv_exu_mdv
(
    .mdv_op_vld                 ( mdv_op_vld                ),
    .mdv_op_rdy                 ( mdv_op_rdy                ),
    .mdv_op_bus                 ( mdv_op_bus                ),

    .gpr_wbck_vld               ( mdv2gpr_wbck_vld          ),
    .gpr_wbck_rdy               ( mdv2gpr_wbck_rdy          ),
    .gpr_wbck_wdata             ( mdv2gpr_wbck_wdata        ),

    .clk                        ( clk                       ),
    .reset_n                    ( reset_n                   )
);




// 系统相关指令处理模块 
lnrv_exu_sys u_lnrv_exu_sys
(
    .sys_op_vld                 ( sys_op_vld                ),
    .sys_op_rdy                 ( sys_op_rdy                ),
    .sys_op_bus                 ( sys_op_bus                ),

    .pc                         ( dec_pc                    ),
    .imm                        ( dec_imm                   ),

    .irq_taken                  ( irq_taken                 ),
    .dbg_taken                  ( dbg_taken                 ),
    .d_mode                     ( d_mode                    ),

    .sys_excp_vld               ( sys_excp_vld              ),
    .sys_excp_rdy               ( sys_excp_rdy              ),
    .sys_excp_ecall             ( sys_excp_ecall            ),
    .sys_excp_ebreak            ( sys_excp_ebreak           ),

    .pipe_halt_req              ( pipe_halt_req             ),
    .pipe_halt_ack              ( pipe_halt_ack             ),

    .wfi_mode                   ( wfi_mode                  ),

    .clk                        ( clk                       ),
    .reset_n                    ( reset_n                   )
);

// 访存指令执行模块
lnrv_exu_lsu u_lnrv_exu_lsu
(
    .op_vld                 ( lsu_op_vld                    ),
    .op_rdy                 ( lsu_op_rdy                    ),
    .op_bus                 ( lsu_op_bus                    ),

    .rs1_rdata              ( rs1_rdata                     ),
    .rs2_rdata              ( rs2_rdata                     ),
    .imm                    ( dec_imm                       ),

    .lsu_excp_vld           ( lsu_excp_vld                  ),
    .lsu_excp_rdy           ( lsu_excp_rdy                  ),
    .lsu_ld_addr_misalgn    ( lsu_ld_addr_misalgn           ),
    .lsu_ld_access_fault    ( lsu_ld_access_fault           ),
    .lsu_st_addr_misalgn    ( lsu_st_addr_misalgn           ),
    .lsu_st_access_fault    ( lsu_st_access_fault           ),
    .lsu_bad_addr           ( lsu_bad_addr                  ),

    .alu_op_vld             ( lsu2alu_op_vld                ),
    .alu_op_rdy             ( lsu2alu_op_rdy                ),
    .alu_op_bus             ( lsu2alu_op_bus                ),
    .alu_in1                ( lsu2alu_in1                   ),
    .alu_in2                ( lsu2alu_in2                   ),
    .alu_res                ( alu_res                       ),

    .lsu2gpr_wbck_vld       ( lsu2gpr_wbck_vld              ),
    .lsu2gpr_wbck_rdy       ( lsu2gpr_wbck_rdy              ),
    .lsu2gpr_wbck_wdata     ( lsu2gpr_wbck_wdata            ),

    .lsu_cmd_vld            ( exu_cmd_vld                   ),
    .lsu_cmd_rdy            ( exu_cmd_rdy                   ),
    .lsu_cmd_write          ( exu_cmd_write                 ),
    .lsu_cmd_addr           ( exu_cmd_addr                  ),
    .lsu_cmd_wdata          ( exu_cmd_wdata                 ),
    .lsu_cmd_wstrb          ( exu_cmd_wstrb                 ),
    .lsu_cmd_size           ( exu_cmd_size                  ),
    .lsu_rsp_rdy            ( exu_rsp_rdy                   ),
    .lsu_rsp_vld            ( exu_rsp_vld                   ),
    .lsu_rsp_rdata          ( exu_rsp_rdata                 ),
    .lsu_rsp_err            ( exu_rsp_err                   ),

    .clk                    ( clk                           ),
    .reset_n                ( reset_n                       )
);

// 有多个模块需要使用alu单元
lnrv_exu_alu_mux u_lnrv_exu_alu_mux
(
    .rglr2alu_op_vld            ( rglr2alu_op_vld           ),
    .rglr2alu_op_rdy            ( rglr2alu_op_rdy           ),
    .rglr2alu_op_bus            ( rglr2alu_op_bus           ),
    .rglr2alu_in1               ( rglr2alu_in1              ),
    .rglr2alu_in2               ( rglr2alu_in2              ),

    .brch2alu_op_vld            ( brch2alu_op_vld           ),
    .brch2alu_op_rdy            ( brch2alu_op_rdy           ),
    .brch2alu_op_bus            ( brch2alu_op_bus           ),
    .brch2alu_in1               ( brch2alu_in1              ),
    .brch2alu_in2               ( brch2alu_in2              ),

    .csr2alu_op_vld             ( csr2alu_op_vld            ),
    .csr2alu_op_rdy             ( csr2alu_op_rdy            ),
    .csr2alu_op_bus             ( csr2alu_op_bus            ),
    .csr2alu_in1                ( csr2alu_in1               ),
    .csr2alu_in2                ( csr2alu_in2               ),

    .lsu2alu_op_vld             ( lsu2alu_op_vld            ),
    .lsu2alu_op_rdy             ( lsu2alu_op_rdy            ),
    .lsu2alu_op_bus             ( lsu2alu_op_bus            ),
    .lsu2alu_in1                ( lsu2alu_in1               ),
    .lsu2alu_in2                ( lsu2alu_in2               ),

    .alu_op_vld                 ( alu_op_vld                ),
    .alu_op_rdy                 ( alu_op_rdy                ),
    .alu_op_bus                 ( alu_op_bus                ),
    .alu_in1                    ( alu_in1                   ),
    .alu_in2                    ( alu_in2                   )
);


// 运算单元
lnrv_exu_alu u_lnrv_exu_alu
(
    .alu_op_vld                 ( alu_op_vld                ),
    .alu_op_rdy                 ( alu_op_rdy                ),
    .alu_op_bus                 ( alu_op_bus                ),
    .alu_in1                    ( alu_in1                   ),
    .alu_in2                    ( alu_in2                   ),

    .alu_res                    ( alu_res                   )
);

// 交付椟
lnrv_exu_cmt u_lnrv_exu_cmt
(
    .brch_pipe_flush_req        ( brch_pipe_flush_req      ),
    .brch_pipe_flush_ack        ( brch_pipe_flush_ack      ),
    .brch_pipe_flush_pc_op1     ( brch_pipe_flush_pc_op1   ),
    .brch_pipe_flush_pc_op2     ( brch_pipe_flush_pc_op2   ),

    .excp_pipe_flush_req        ( excp_pipe_flush_req      ),
    .excp_pipe_flush_ack        ( excp_pipe_flush_ack      ),
    .excp_pipe_flush_pc_op1     ( excp_pipe_flush_pc_op1   ),
    .excp_pipe_flush_pc_op2     ( excp_pipe_flush_pc_op2   ),

    .irq_pipe_flush_req         ( irq_pipe_flush_req       ),
    .irq_pipe_flush_ack         ( irq_pipe_flush_ack       ),
    .irq_pipe_flush_pc_op1      ( irq_pipe_flush_pc_op1    ),
    .irq_pipe_flush_pc_op2      ( irq_pipe_flush_pc_op2    ),

    .debug_pipe_flush_req       ( debug_pipe_flush_req     ),
    .debug_pipe_flush_ack       ( debug_pipe_flush_ack     ),
    .debug_pipe_flush_pc_op1    ( debug_pipe_flush_pc_op1  ),
    .debug_pipe_flush_pc_op2    ( debug_pipe_flush_pc_op2  ),

    .irq_cmt_csr                ( irq_cmt_csr              ),
    .irq_cmt_mepc               ( irq_cmt_mepc             ),
    .irq_cmt_mcause             ( irq_cmt_mcause           ),

    .excp_cmt_csr               ( excp_cmt_csr             ),
    .excp_cmt_mepc              ( excp_cmt_mepc            ),
    .excp_cmt_mcause            ( excp_cmt_mcause          ),
    .excp_cmt_mtval             ( excp_cmt_mtval           ),

    .excp_cmt_dcsr              ( excp_cmt_dcsr            ),
    .excp_cmt_dpc               ( excp_cmt_dpc             ),
    .excp_cmt_dcause            ( excp_cmt_dcause          ),

    .debug_cmt_dcsr             ( debug_cmt_dcsr           ),
    .debug_cmt_dpc              ( debug_cmt_dpc            ),
    .debug_cmt_dcause           ( debug_cmt_dcause         ),

    .cmt_irq                    ( cmt_irq                  ),
    .cmt_excp                   ( cmt_excp                 ),
    .cmt_debug                  ( cmt_debug                ),
    .cmt_mepc                   ( cmt_mepc                 ),
    .cmt_mcause                 ( cmt_mcause               ),
    .cmt_mtval                  ( cmt_mtval                ),
    .cmt_dpc                    ( cmt_dpc                  ),
    .cmt_dcause                 ( cmt_dcause               ),

    .pipe_flush_req             ( pipe_flush_req           ),
    .pipe_flush_ack             ( pipe_flush_ack           ),
    .pipe_flush_pc_op1          ( pipe_flush_pc_op1        ),
    .pipe_flush_pc_op2          ( pipe_flush_pc_op2        ),

    .clk                        ( clk                      ),
    .reset_n                    ( reset_n                  )
);



// 写回模块
lnrv_exu_wbck u_lnrv_exu_wbck
(
    .rglr2gpr_wbck_vld          ( rglr2gpr_wbck_vld         ),
    .rglr2gpr_wbck_rdy          ( rglr2gpr_wbck_rdy         ),

    .brch2gpr_wbck_vld          ( brch2gpr_wbck_vld         ),
    .brch2gpr_wbck_rdy          ( brch2gpr_wbck_rdy         ),

    .lsu2gpr_wbck_vld           ( lsu2gpr_wbck_vld          ),
    .lsu2gpr_wbck_rdy           ( lsu2gpr_wbck_rdy          ),
    .lsu2gpr_wbck_wdata         ( lsu2gpr_wbck_wdata        ),

    .csr2gpr_wbck_vld           ( csr2gpr_wbck_vld          ),
    .csr2gpr_wbck_rdy           ( csr2gpr_wbck_rdy          ),
    .csr2gpr_wbck_wdata         ( csr2gpr_wbck_wdata        ),

    .mdv2gpr_wbck_vld           ( mdv2gpr_wbck_vld          ),
    .mdv2gpr_wbck_rdy           ( mdv2gpr_wbck_rdy          ),
    .mdv2gpr_wbck_wdata         ( mdv2gpr_wbck_wdata        ),

    .rd_idx                     ( dec_rd_idx                ),
    .alu_res                    ( alu_res                   ),

    .gpr_wbck_vld               ( gpr_wbck_vld              ),
    .gpr_wbck_rdy               ( gpr_wbck_rdy              ),
    .gpr_wbck_idx               ( gpr_wbck_idx              ),
    .gpr_wbck_wdata             ( gpr_wbck_wdata            )
);


assign      exu_active = 1'b1;

endmodule