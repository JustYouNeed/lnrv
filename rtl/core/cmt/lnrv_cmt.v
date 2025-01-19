module lnrv_cmt
(
    input                       ifu_vld,
    input[31 : 0]               ifu_pc,

    input                       idu_vld,
    input[31 : 0]               idu_pc,
    input[31 : 0]               idu_ir,
    input[31 : 0]               idu_imm,

    // 来自exu模块的交付信号
    input                       cmt_vld,
    output                      cmt_rdy,
    input                       cmt_rv32_ir,
    input                       cmt_idu_excp_ilglir,
    input                       cmt_ifu_excp_buserr,
    input                       cmt_ifu_excp_misalgn,
    input                       cmt_brch_dret,
    input                       cmt_brch_mret,
    input                       cmt_brch_jal,
    input                       cmt_brch_jalr,
    input                       cmt_brch_fence,
    input                       cmt_brch_bjp,
    input                       cmt_prdt_taken,
    input                       cmt_csr,
    input                       cmt_csr_idx_err,
    input                       cmt_rglr,
    input                       cmt_sys_ebreak,
    input                       cmt_sys_ecall,
    input                       cmt_sys_wfi,
    input                       cmt_lsu_ld,
    input                       cmt_lsu_st,
    input                       cmt_lsu_excp_misalgn,
    input                       cmt_lsu_excp_buserr,
    input[31 : 0]               cmt_lsu_addr,

    // 中断输入
    input                       irq_sft,            // 软件中断
    input                       irq_ext,            // 外部中断
    input                       irq_tmr,            // 定时器中断

    // clic接口
    input                       clic_irq_req,
    output                      clic_irq_ack,
    input[7 : 0]                clic_irq_id,
    input                       clic_irq_mode,

    // 中断使能
    input                       mie_meie,
    input                       mie_mtie,
    input                       mie_msie,
    input                       mstatus_mie,

    input[31 : 0]               dpc,
    input[31 : 0]               mepc,
    input[31 : 0]               mtvec,
    input[31 : 0]               mtvt,
    input[31 : 0]               rs1_rdata,

    // 调试模式
    input                       d_mode,
    input                       m_mode,
    output                      wfi_mode,

    // 有中断发生
    output                      irq_taken,
    output                      dbg_taken,
    output                      excp_taken,
    output                      vec_irq_taken,

    input                       irq_dbg,
    input                       dbg_halt,
    input                       dbg_step,
    input                       dbg_trig,


    input                       dcsr_ebreakm,
    input                       dcsr_step,      // 单步调试模式
    input                       dcsr_stepie,    // 在单步调试模式下是否使能中断

    output                      mepc_wen,
    output[31 : 0]              mepc_wdata,

    output                      mcause_wen,
    output[31 : 0]              mcause_wdata,

    output                      mtval_wen,
    output[31 : 0]              mtval_wdata,

    output                      dpc_wen,
    output[31 : 0]              dpc_wdata,

    output                      dcause_wen,
    output[2 : 0]               dcause_wdata,

    // 流水线冲刷请求
    output                      pipe_flush_req,
    input                       pipe_flush_ack,
    output[31 : 0]              pipe_flush_pc_op1,
    output[31 : 0]              pipe_flush_pc_op2,

    output                      pipe_halt_req,
    input                       pipe_halt_ack,

    output                      cmted_mret,
    output                      cmted_dret,

    input                       clk,
    input                       reset_n
);

wire                            exu_idle;
wire                            brch_taken;

wire                            pipe_flush_req_irq;
wire                            pipe_flush_ack_irq;
wire[31 : 0]                    pipe_flush_pc_op1_irq;
wire[31 : 0]                    pipe_flush_pc_op2_irq;
wire[31 : 0]                    mepc_wdata_irq;
wire[31 : 0]                    mcause_wdata_irq;

wire                            pipe_flush_req_excp;
wire                            pipe_flush_ack_excp;
wire[31 : 0]                    pipe_flush_pc_op1_excp;
wire[31 : 0]                    pipe_flush_pc_op2_excp;
wire[31 : 0]                    mepc_wdata_excp;
wire[31 : 0]                    mcause_wdata_excp;
wire[31 : 0]                    mtval_wdata_excp;

wire                            pipe_flush_req_dbg;
wire                            pipe_flush_ack_dbg;
wire[31 : 0]                    pipe_flush_pc_op1_dbg;
wire[31 : 0]                    pipe_flush_pc_op2_dbg;
wire[31 : 0]                    dpc_wdata_dbg;
wire[2 : 0]                     dcause_wdata_dbg;

wire                            pipe_flush_req_brch;
wire                            pipe_flush_ack_brch;
wire[31 : 0]                    pipe_flush_pc_op1_brch;
wire[31 : 0]                    pipe_flush_pc_op2_brch;

wire                            irq_req_raw;
wire                            dbg_req_raw;
wire                            vec_irq_taken_raw;


assign      exu_idle = cmt_vld | (~idu_vld);

// 中断处理模块
lnrv_cmt_irq u_lnrv_cmt_irq
(
    .exu_idle               ( exu_idle                      ),

    .ifu_vld                ( ifu_vld                       ),
    .ifu_pc                 ( ifu_pc                        ),

    .irq_sft                ( irq_sft                       ),
    .irq_ext                ( irq_ext                       ),
    .irq_tmr                ( irq_tmr                       ),

    .clic_irq_req           ( clic_irq_req                  ),
    .clic_irq_ack           ( clic_irq_ack                  ),
    .clic_irq_id            ( clic_irq_id                   ),
    .clic_irq_mode          ( clic_irq_mode                 ),

    .mie_meie               ( mie_meie                      ),
    .mie_mtie               ( mie_mtie                      ),
    .mie_msie               ( mie_msie                      ),
    .mstatus_mie            ( mstatus_mie                   ),

    .d_mode                 ( d_mode                        ),

    .irq_taken              ( irq_taken                     ),
    .irq_req_raw            ( irq_req_raw                   ),
    .vec_irq_taken          ( vec_irq_taken_raw             ),

    .mepc_wdata             ( mepc_wdata_irq                ),
    .mcause_wdata           ( mcause_wdata_irq              ),

    .dcsr_step              ( dcsr_step                     ),
    .dcsr_stepie            ( dcsr_stepie                   ),

    .mtvec                  ( mtvec                         ),
    .mtvt                   ( mtvt                          ),

    .pipe_flush_req         ( pipe_flush_req_irq            ),
    .pipe_flush_ack         ( pipe_flush_ack_irq            ),
    .pipe_flush_pc_op1      ( pipe_flush_pc_op1_irq         ),
    .pipe_flush_pc_op2      ( pipe_flush_pc_op2_irq         ),

    .clk                    ( clk                           ),
    .reset_n                ( reset_n                       )
);

// 异常处理模块
lnrv_cmt_excp u_lnrv_cmt_excp
(
    .idu_pc                 ( idu_pc                        ),
    .idu_ir                 ( idu_ir                        ),

    .excp_taken             ( excp_taken                    ),

    .cmt_vld                ( cmt_vld                       ),
    .cmt_idu_excp_ilglir    ( cmt_idu_excp_ilglir           ),
    .cmt_ifu_excp_buserr    ( cmt_ifu_excp_buserr           ),
    .cmt_ifu_excp_misalgn   ( cmt_ifu_excp_misalgn          ),
    .cmt_lsu_ld             ( cmt_lsu_ld                    ),
    .cmt_lsu_st             ( cmt_lsu_st                    ),
    .cmt_lsu_buserr         ( cmt_lsu_excp_buserr           ),
    .cmt_lsu_misalgn        ( cmt_lsu_excp_misalgn          ),
    .cmt_lsu_addr           ( cmt_lsu_addr                  ),
    .cmt_sys_ebreak         ( cmt_sys_ebreak                ),
    .cmt_sys_ecall          ( cmt_sys_ecall                 ),
    .cmt_csr_idx_err        ( cmt_csr_idx_err               ),

    .mepc_wdata             ( mepc_wdata_excp               ),
    .mcause_wdata           ( mcause_wdata_excp             ),
    .mtval_wdata            ( mtval_wdata_excp              ),

    .m_mode                 ( m_mode                        ),
    .d_mode                 ( d_mode                        ),

    .dcsr_ebreakm           ( dcsr_ebreakm                  ),
    .mtvec                  ( mtvec                         ),

    .pipe_flush_req         ( pipe_flush_req_excp           ),
    .pipe_flush_ack         ( pipe_flush_ack_excp           ),
    .pipe_flush_pc_op1      ( pipe_flush_pc_op1_excp        ),
    .pipe_flush_pc_op2      ( pipe_flush_pc_op2_excp        ),

    .clk                    ( clk                           ),
    .reset_n                ( reset_n                       )
);

// 调试相关请求处理模块
lnrv_cmt_dbg u_lnrv_cmt_dbg
(
    .idu_pc                 ( idu_pc                        ),

    .ifu_vld                ( ifu_vld                       ),
    .ifu_pc                 ( ifu_pc                        ),

    .cmt_vld                ( cmt_vld                       ),
    .cmt_sys_ebreak         ( cmt_sys_ebreak                ),

    .dbg_req_raw            ( dbg_req_raw                   ),
    .dbg_taken              ( dbg_taken                     ),

    .irq_dbg                ( irq_dbg                       ),
    .dbg_halt               ( dbg_halt                      ),
    .dbg_step               ( dcsr_step                     ),
    .dbg_trig               ( 1'b0                          ),


    .d_mode                 ( d_mode                        ),

    .dcsr_ebreakm           ( dcsr_ebreakm                  ),

    .pipe_flush_req         ( pipe_flush_req_dbg            ),
    .pipe_flush_ack         ( pipe_flush_ack_dbg            ),
    .pipe_flush_pc_op1      ( pipe_flush_pc_op1_dbg         ),
    .pipe_flush_pc_op2      ( pipe_flush_pc_op2_dbg         ),

    .dpc_wdata              ( dpc_wdata_dbg                 ),
    .dcause_wdata           ( dcause_wdata_dbg              ),

    .clk                    ( clk                           ),
    .reset_n                ( reset_n                       )
);

// 分支指令交付处理模块
lnrv_cmt_brch u_lnrv_cmt_brch
(
    .cmt_vld                ( cmt_vld                       ),
    .cmt_rv32_ir            ( cmt_rv32_ir                   ),
    .cmt_brch_bjp           ( cmt_brch_bjp                  ),
    .cmt_brch_jal           ( cmt_brch_jal                  ),
    .cmt_brch_jalr          ( cmt_brch_jalr                 ),
    .cmt_brch_mret          ( cmt_brch_mret                 ),
    .cmt_brch_dret          ( cmt_brch_dret                 ),
    .cmt_brch_fence         ( cmt_brch_fence                ),
    .cmt_prdt_taken         ( cmt_prdt_taken                ),

    .brch_taken             ( brch_taken                    ),

    .dpc                    ( dpc                           ),
    .mepc                   ( mepc                          ),
    .rs1_rdata              ( rs1_rdata                     ),
    .idu_pc                 ( idu_pc                        ),
    .imm                    ( idu_imm                       ),

    .pipe_flush_req         ( pipe_flush_req_brch           ),
    .pipe_flush_ack         ( pipe_flush_ack_brch           ),
    .pipe_flush_pc_op1      ( pipe_flush_pc_op1_brch        ),
    .pipe_flush_pc_op2      ( pipe_flush_pc_op2_brch        ),

    .clk                    ( clk                           ),
    .reset_n                ( reset_n                       )
);


lnrv_cmt_wfi u_lnrv_cmt_wfi
(
    .clk                    ( clk                           ),      // I
    .reset_n                ( reset_n                       ),      // I

    .exu_idle               ( exu_idle                      ),      // I

    .cmt_vld                ( cmt_vld                       ),      // I
    .cmt_sys_wfi            ( cmt_sys_wfi                   ),      // I

    .wfi_mode               ( wfi_mode                      ),      // O

    .pipe_halt_req          ( pipe_halt_req                 ),      // O
    .pipe_halt_ack          ( pipe_halt_ack                 ),      // I

    .excp_req_raw           ( excp_taken                    ),      // I
    .irq_req_raw            ( irq_req_raw                   ),      // I
    .dbg_req_raw            ( dbg_req_raw                   ),      // I

    .d_mode                 ( d_mode                        ),      // I
    .dcsr_step              ( dcsr_step                     )       // I
);

// 流水线冲刷请求优先级如下：
// 1、debug请求
// 2、分支指令
// 3、中断
// 4、异常
assign      pipe_flush_req  =   pipe_flush_req_dbg |
                                pipe_flush_req_excp |
                                pipe_flush_req_irq |
                                pipe_flush_req_brch;

assign      pipe_flush_pc_op1 = pipe_flush_req_dbg ? pipe_flush_pc_op1_dbg :
                                pipe_flush_req_brch ? pipe_flush_pc_op1_brch :
                                pipe_flush_req_irq ? pipe_flush_pc_op1_irq :
                                pipe_flush_req_excp ? pipe_flush_pc_op1_excp :
                                32'd0;

assign      pipe_flush_pc_op2 = pipe_flush_req_dbg ? pipe_flush_pc_op2_dbg :
                                pipe_flush_req_brch ? pipe_flush_pc_op2_brch :
                                pipe_flush_req_irq ? pipe_flush_pc_op2_irq :
                                pipe_flush_req_excp ? pipe_flush_pc_op2_excp :
                                32'd0;

assign      pipe_flush_ack_dbg = pipe_flush_ack;

assign      pipe_flush_ack_brch =   pipe_flush_ack &
                                    (
                                        ~pipe_flush_req_dbg
                                    );

assign      pipe_flush_ack_irq =    pipe_flush_ack &
                                    (
                                        ~(
                                            pipe_flush_req_dbg |
                                            pipe_flush_req_brch
                                        )
                                    );

assign      pipe_flush_ack_excp =  pipe_flush_ack &
                                    (
                                        ~(
                                            pipe_flush_req_dbg |
                                            pipe_flush_req_brch |
                                            pipe_flush_req_irq
                                        )
                                    );

assign      vec_irq_taken = vec_irq_taken_raw &
                            (
                                ~(pipe_flush_req_dbg | pipe_flush_req_brch)
                            );

// 有中断/异常发生时需要更新以下寄存器
// 1、mepc
// 2、mcause
// 3、mtval(仅发生异常时需要更新)
assign      mepc_wen      = irq_taken | excp_taken;
assign      mepc_wdata    = irq_taken ? mepc_wdata_irq : mepc_wdata_excp;
assign      mcause_wen    = mepc_wen;
assign      mcause_wdata  = irq_taken ? mcause_wdata_irq : mcause_wdata_excp;
assign      mtval_wen     = excp_taken;
assign      mtval_wdata   = mtval_wdata_excp;

// 操作dcsr寄存器
assign      dpc_wen = dbg_taken;
assign      dpc_wdata = dpc_wdata_dbg;

assign      dcause_wen = dbg_taken;
assign      dcause_wdata = dcause_wdata_dbg;


assign      cmted_mret = cmt_brch_mret & brch_taken;
assign      cmted_dret = cmt_brch_dret & brch_taken;

// 如果需要冲刷流水线，则需要等流水线冲刷完成，否则可以直接交付
assign      cmt_rdy = pipe_flush_req ? pipe_flush_ack : cmt_vld;

endmodule

