module lnrv_exu_cmt
(
    input                       exu_idle,
    input                       exu_hsked,
    input[31 : 0]               exu_pc,
    input[31 : 0]               exu_ir,

    input                       ifu_pc_vld,
    input[31 : 0]               ifu_pc,


    // 来自前级模块的异常
    input                       idu_excp_ilgl_ir,       // 非法指令
    input                       ifu_excp_buserr,             // 取指总线错误
    input                       ifu_excp_misalgn,            // 取指地址非对齐

    // 来自lsu模块的异常，包括:
    // 1、非对齐访问
    // 2、总线错误
    input                       lsu_cmt_vld,
    output                      lsu_cmt_rdy,
    input                       lsu_cmt_misalgn,
    input                       lsu_cmt_buserr,
    input                       lsu_cmt_st,
    input                       lsu_cmt_ld,
    input[31 : 0]               lsu_cmt_addr,
    input                       lsu_cmt_gpr_wen,
    input[31 : 0]               lsu_cmt_gpr_wdata,

    // 来自sys指令处理模块的异常，主要为ecall以及ebreak
    input                       sys_cmt_vld,
    output                      sys_cmt_rdy,
    input                       sys_cmt_ecall,
    input                       sys_cmt_ebreak,
    input                       sys_cmt_wfi,

    // 常规指令交付请求
    input                       rglr_cmt_vld,
    output                      rglr_cmt_rdy,
    input                       rglr_cmt_gpr_wen,

    // 分支指令交付请求
    input                       brch_cmt_vld,
    output                      brch_cmt_rdy,
    input                       brch_cmt_bjp,
    input                       brch_cmt_jal,
    input                       brch_cmt_jalr,
    input                       brch_cmt_mret,
    input                       brch_cmt_dret,
    input                       brch_cmt_fence,
    input                       brch_cmt_gpr_wen,

    // csr相关指令交付请求
    input                       csr_cmt_vld,
    output                      csr_cmt_rdy,
    input                       csr_cmt_idx_err,
    input                       csr_cmt_gpr_wen,
    input[31 : 0]               csr_cmt_gpr_wdata,
    input                       csr_cmt_csr_wen,
    input[31 : 0]               csr_cmt_csr_wdata,

    // alu结果输入
    input[31 : 0]               alu_add_res,
    input                       alu_cmp_res,

    // 分支预测结果
    input                       bpu_prdt_res,

    // 中断输入
    input                       sft_irq,            // 软件中断
    input                       ext_irq,            // 外部中断
    input                       tmr_irq,            // 定时器中断

    // 中断使能
    input                       mie_meie,
    input                       mie_mtie,
    input                       mie_msie,
    input                       mstatus_mie,

    // 调试模式
    input                       dbg_mode,

    // 有中断发生
    output                      irq_taken,
    output                      dbg_taken,
    output                      excp_taken,

    input                       dbg_irq,
    input                       dbg_halt,
    input                       dbg_step,
    input                       dbg_trig,

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
    output[31 : 0]              dcause_wdata,

    // 流水线冲刷请求
    output                      pipe_flush_req,
    input                       pipe_flush_ack,
    output[31 : 0]              pipe_flush_pc_op1,
    output[31 : 0]              pipe_flush_pc_op2,

    // 通用寄存器写回接口
    output                      gpr_wbck_vld,
    input                       gpr_wbck_rdy,
    output[31 : 0]              gpr_wbck_data,

    // csr寄存器写回接口
    output                      csr_wbck_vld,
    input                       csr_wbck_rdy,
    output[11 : 0]              csr_wbck_idx,
    output[31 : 0]              csr_wbck_data,

    output                      cmt_mret,
    output                      cmt_dret,

    input                       clk,
    input                       reset_n
);

wire                            rglr_need_wbck;
wire                            brch_need_wbck;
wire                            csr_need_wbck;
wire                            lsu_need_wbck;
wire                            sys_need_wbck;

wire                            wbck_need_abort;

wire                            pipe_flush_req_irq;
wire                            pipe_flush_ack_irq;
wire[31 : 0]                    pipe_flush_pc_op1_irq;
wire[31 : 0]                    pipe_flush_pc_op2_irq;
wire                            pipe_flush_hsked_irq;
wire[31 : 0]                    mepc_wdata_irq;
wire[31 : 0]                    mcause_wdata_irq;

wire                            pipe_flush_req_excp;
wire                            pipe_flush_ack_excp;
wire[31 : 0]                    pipe_flush_pc_op1_excp;
wire[31 : 0]                    pipe_flush_pc_op2_excp;
wire                            pipe_flush_hsked_excp;
wire[31 : 0]                    mepc_wdata_excp;
wire[31 : 0]                    mcause_wdata_excp;
wire[31 : 0]                    mtval_wdata_excp;

wire                            pipe_flush_req_dbg;
wire                            pipe_flush_ack_dbg;
wire[31 : 0]                    pipe_flush_pc_op1_dbg;
wire[31 : 0]                    pipe_flush_pc_op2_dbg;
wire                            pipe_flush_hsked_dbg;
wire[31 : 0]                    dpc_wdata_dbg;
wire[2 : 0]                     dcause_wdata_dbg;

wire                            pipe_flush_req_brch;
wire                            pipe_flush_ack_brch;
wire[31 : 0]                    pipe_flush_pc_op1_brch;
wire[31 : 0]                    pipe_flush_pc_op2_brch;
wire                            pipe_flush_hsked_brch;


wire                            lsu_excp_ld_misalgn;
wire                            lsu_excp_ld_buserr;
wire                            lsu_excp_st_buserr;
wire                            lsu_excp_st_misalgn;
wire                            sys_excp_ecall;
wire                            sys_excp_ebreak;
wire                            csr_excp_idxerr;

// 中断处理模块
lnrv_exu_irq u_lnrv_exu_irq
(
    .exu_idle               ( exu_idle                      ),

    .ifu_pc_vld             ( ifu_pc_vld                    ),
    .ifu_pc                 ( ifu_pc                        ),

    .sft_irq                ( sft_irq                       ),
    .ext_irq                ( ext_irq                       ),
    .tmr_irq                ( tmr_irq                       ),

    .mie_meie               ( mie_meie                      ),
    .mie_mtie               ( mie_mtie                      ),
    .mie_msie               ( mie_msie                      ),
    .mstatus_mie            ( mstatus_mie                   ),

    .d_mode                 ( d_mode                        ),

    .mepc_wdata             ( mepc_wdata_irq                ),
    .mcause_wdata           ( mcause_wdata_irq              ),

    .irq_taken              ( irq_taken                     ),

    .dcsr_step              ( dcsr_step                     ),
    .dcsr_stepie            ( dcsr_stepie                   ),

    .mtvec                  ( mtvec                         ),

    .pipe_flush_req         ( pipe_flush_req_irq            ),
    .pipe_flush_ack         ( pipe_flush_ack_irq            ),
    .pipe_flush_pc_op1      ( pipe_flush_pc_op1_irq         ),
    .pipe_flush_pc_op2      ( pipe_flush_pc_op2_irq         ),

    .clk                    ( clk                           ),
    .reset_n                ( reset_n                       )
);

assign      lsu_excp_ld_misalgn = lsu_cmt_ld & lsu_cmt_misalgn;
assign      lsu_excp_ld_buserr = lsu_cmt_ld & lsu_cmt_buserr;

assign      lsu_excp_st_buserr = lsu_cmt_st & lsu_cmt_buserr;
assign      lsu_excp_st_misalgn = lsu_cmt_st & lsu_cmt_misalgn;

assign      sys_excp_ecall = sys_cmt_ecall;
assign      sys_excp_ebreak = sys_cmt_ebreak;

assign      csr_excp_idxerr = csr_cmt_idx_err;

// 异常处理模块
lnrv_exu_excp u_lnrv_exu_excp
(
    .exu_pc                 ( exu_pc                        ),
    .exu_ir                 ( exu_ir                        ),
    
    .excp_taken             ( excp_taken                    ),

    .idu_excp_ilgl_ir       ( idu_excp_ilgl_ir              ),
    .ifu_excp_buserr        ( ifu_excp_buserr               ),
    .ifu_excp_misalgn       ( ifu_excp_misalgn              ),

    .lsu_excp_ld_misalgn    ( lsu_excp_ld_misalgn           ),
    .lsu_excp_ld_buserr     ( lsu_excp_ld_buserr            ),
    .lsu_excp_st_misalgn    ( lsu_excp_st_misalgn           ),
    .lsu_excp_st_buserr     ( lsu_excp_st_buserr            ),
    .lsu_excp_addr          ( lsu_excp_addr                 ),

    .sys_excp_ecall         ( sys_excp_ecall                ),
    .sys_excp_ebreak        ( sys_excp_ebreak               ),

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
lnrv_exu_dbg u_lnrv_exu_dbg
(
    .exu_pc                 ( exu_pc                        ),
    .exu_idle               ( exu_idle                      ),
    
    .cmt_hsked              ( cmt_hsked                     ),

    .ifu_pc_vld             ( ifu_pc_vld                    ),
    .ifu_pc                 ( ifu_pc                        ),

    .dbg_taken              ( dbg_taken                     ),

    .dbg_irq                ( dbg_irq                       ),
    .dbg_halt               ( dbg_halt                      ),
    .dbg_step               ( dcsr_step                     ),
    .dbg_trig               ( 1'b0                          ),

    .sys_cmt_ebreak         ( sys_cmt_ebreak                ),

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


lnrv_exu_cmt_brch u_lnrv_exu_cmt_brch
(
    .brch_cmt_vld           ( brch_cmt_vld                  ),
    .brch_cmt_rdy           ( brch_cmt_rdy                  ),
    .brch_cmt_bjp           ( brch_cmt_bjp                  ),
    .brch_cmt_jal           ( brch_cmt_jal                  ),
    .brch_cmt_jalr          ( brch_cmt_jalr                 ),
    .brch_cmt_mret          ( brch_cmt_mret                 ),
    .brch_cmt_dret          ( brch_cmt_dret                 ),
    .brch_cmt_fence         ( brch_cmt_fence                ),
    
    .bpu_prdt_res           ( bpu_prdt_res                  ),
    
    .pipe_flush_req         ( pipe_flush_req_brch           ),
    .pipe_flush_ack         ( pipe_flush_ack_brch           ),
    .pipe_flush_pc_op1      ( pipe_flush_pc_op1_brch        ),
    .pipe_flush_pc_op2      ( pipe_flush_pc_op2_brch        ),

    .clk                    ( clk                           ),
    .reset_n                ( reset_n                       )
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


// 有中断/异常发生时需要更新以下寄存器
// 1、mepc
// 2、mcause
// 3、mtval(仅发生异常时需要更新)
assign      mepc_wen      = pipe_flush_hsked_irq | pipe_flush_hsked_excp;
assign      mepc_wdata          = pipe_flush_hsked_irq ? mepc_wdata_irq : mepc_wdata_excp;
assign      mcause_wen    = mepc_wen;
assign      mcause_wdata        = pipe_flush_hsked_irq ? mcause_wdata_irq : mcause_wdata_excp;
assign      mtval_wen     = pipe_flush_hsked_excp;
assign      mtval_wdata         = mtval_wdata_excp;

// 操作dcsr寄存器
assign      dpc_wen = pipe_flush_hsked_dbg;
assign      dpc_wdata = dpc_wdata_dbg;

assign      dcause_wen = pipe_flush_hsked_dbg;
assign      dcause_wdata = dcause_wdata_dbg;


// // 所有常规指令都需要写回
// assign      rglr_need_wbck = rglr_cmt_vld;

// // 分支指令只有jal和jalr需要写回
// assign      brch_need_wbck = brch_cmt_vld & 
//                              (
//                                 brch_cmt_jal | 
//                                 brch_cmt_jalr
//                              );
// // lsu指令只有load需要写回
// assign      lsu_need_wbck = lsu_cmt_vld & 
//                             (
//                                 lsu_cmt_ld
//                             );

// // csr寄存器操作指令，需要在csr idx正确的情况下才会写回
// assign      csr_need_wbck = csr_cmt_vld & (~csr_cmt_idx_err);

// 如是有异常或者中断请求冲刷流水线，则当前指令都不能与回
assign      wbck_need_abort = pipe_flush_req_excp | pipe_flush_req_dbg;

assign      gpr_wbck_vld = (~wbck_need_abort) & 
                           (
                                rglr_cmt_gpr_wen | 
                                brch_cmt_gpr_wen | 
                                csr_cmt_gpr_wen | 
                                lsu_cmt_gpr_wen
                           );

// lsu模块要写回的数据来自总线
// 常规指令以及分支指令要写回的数据都来自于alu的运算结果
// 
assign      gpr_wbck_data = lsu_need_wbck ? lsu_cmt_gpr_wdata : 
                            (rglr_need_wbck | brch_need_wbck) ? alu_add_res : 
                            csr_need_wbck ? csr_cmt_gpr_wdata : 
                            32'd0;

// 只有csr相关指令需要操作csr寄存器
assign      csr_wbck_vld = (~wbck_need_abort) & csr_cmt_csr_wen;
assign      csr_wbck_data = csr_cmt_csr_wdata;

assign      cmt_mret = brch_cmt_mret & pipe_flush_hsked_brch;
assign      cmt_dret = brch_cmt_dret & pipe_flush_hsked_brch;

// assign      gpr_wbck_idx = rd_idx;


// 常规指令都需要写回
assign      rglr_cmt_rdy    = gpr_wbck_rdy;

// csr相关指令都需要写回
assign      csr_wbck_gpr_rdy = csr_need_wbck ? gpr_wbck_rdy : 1'b1;
assign      csr_wbck_csr_rdy = csr_cmt_csr_wen ? csr_wbck_rdy : 1'b1;
assign      csr_cmt_rdy     = csr_wbck_gpr_rdy & csr_wbck_csr_rdy;

// 对于分支指令，有可能需要写回和冲刷流水线，任意操作没
assign      brch_wbck_rdy   = brch_need_wbck  ? gpr_wbck_rdy : 1'b1;
assign      brch_flush_rdy  = pipe_flush_req_brch ? pipe_flush_ack_brch : 1'b1;
assign      brch_cmt_rdy    = brch_wbck_rdy & brch_flush_rdy;

// sys相关指令，不需要写回，只要没有其他原因冲刷
assign      sys_cmt_rdy     = (~pipe_flush_req);

// lsu相关指令，如果不需要写回则只要没有流水线冲刷请求就表示交付成功，如果需要写回，则写回成功就表示交付成功
assign      lsu_cmt_rdy     = lsu_need_wbck ? gpr_wbck_rdy : (~pipe_flush_req);

endmodule

