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
    output                                  exu_idle,

    // 译码信息
    input                                   idu_pc_vld,
    output                                  idu_pc_rdy,
    input[`DEC_OP_BUS_WIDTH - 1 : 0]        idu_op_bus,
    input[`DEC_OP_TYPE_WIDTH - 1 : 0]       idu_op_type,
    input[31 : 0]                           idu_imm,
    input[31 : 0]                           idu_pc,
    input[31 : 0]                           idu_ir,


    // 寄存器读取接口
    input[31 : 0]                           rs1_rdata,
    input[31 : 0]                           rs2_rdata,
    input[31 : 0]                           csr_rdata,

    output                                  exu_cmt_vld,
    input                                   exu_cmt_rdy,
    output                                  exu_cmt_dret,
    output                                  exu_cmt_mret,
    output                                  exu_cmt_fence,
    output                                  exu_cmt_bjp,
    output                                  exu_cmt_bjp_res,

    output                                  exu_cmt_csr_idxerr,
    output                                  exu_cmt_csr_wen,
    output[31 : 0]                          exu_cmt_csr_wdata,

    output                                  exu_cmt_rglr,
    
    output                                  exu_cmt_ebreak,
    output                                  exu_cmt_ecall,
    output                                  exu_cmt_wfi,

    output                                  exu_cmt_ld,
    output                                  exu_cmt_st,
    output                                  exu_cmt_excp_misalgn,
    output                                  exu_cmt_excp_buserr,
    output[31 : 0]                          exu_cmt_baddr,

    //访存接口
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

wire                                rglr2alu_op_vld;
wire                                rglr2alu_op_rdy;
wire[`ALU_OP_BUS_WIDTH - 1 : 0]     rglr2alu_op_bus;
wire[31 : 0]                        rglr2alu_in1;
wire[31 : 0]                        rglr2alu_in2;

wire                                brch2alu_op_vld;
wire                                brch2alu_op_rdy;
wire[`ALU_OP_BUS_WIDTH - 1 : 0]     brch2alu_op_bus;
wire[31 : 0]                        brch2alu_in1;
wire[31 : 0]                        brch2alu_in2;

wire                                lsu2alu_op_vld;
wire                                lsu2alu_op_rdy;
wire[`ALU_OP_BUS_WIDTH - 1 : 0]     lsu2alu_op_bus;
wire[31 : 0]                        lsu2alu_in1;
wire[31 : 0]                        lsu2alu_in2;

wire                                csr2alu_op_vld;
wire                                csr2alu_op_rdy;
wire[`ALU_OP_BUS_WIDTH - 1 : 0]     csr2alu_op_bus;
wire[31 : 0]                        csr2alu_in1;
wire[31 : 0]                        csr2alu_in2;

// 指令派遣模块
lnrv_exu_disp u_lnrv_exu_disp
(
    .idu_rglr_instr             ( idu_rglr_instr            ),
    .idu_brch_instr             ( idu_brch_instr            ),
    .idu_csr_instr              ( idu_csr_instr             ),
    .idu_sys_instr              ( idu_sys_instr             ),
    .idu_mdv_instr              ( idu_mdv_instr             ),
    .idu_lsu_instr              ( idu_lsu_instr             ),
    .idu_op_bus                 ( idu_op_bus                ),
    .idu_op_vld                 ( idu_op_vld                ),
    .idu_op_rdy                 ( idu_op_rdy                ),

    .idu_excp_ilgl_ir           ( idu_excp_ilgl_ir          ),
    .idu_excp_buserr            ( idu_excp_buserr           ),
    .idu_excp_misalgn           ( idu_excp_misalgn          ),

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

    .rglr_cmt_vld               ( rglr_cmt_vld              ),
    .rglr_cmt_rdy               ( rglr_cmt_rdy              ),
    .rglr_cmt_gpr_wen           ( rglr_cmt_gpr_wen          )
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

    .csr_cmt_vld                ( csr_cmt_vld               ),
    .csr_cmt_rdy                ( csr_cmt_rdy               ),
    .csr_cmt_gpr_wen            ( csr_cmt_gpr_wen           ),
    .csr_cmt_csr_wen            ( csr_cmt_csr_wen           ),
    .csr_cmt_idx_err            ( csr_cmt_idx_err           )
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

    .brch_cmt_vld               ( brch_cmt_vld              ),
    .brch_cmt_rdy               ( brch_cmt_rdy              ),
    .brch_cmt_dret              ( brch_cmt_dret             ),
    .brch_cmt_mret              ( brch_cmt_mret             ),
    .brch_cmt_fence             ( brch_cmt_fence            ),
    .brch_cmt_bjp               ( brch_cmt_bjp              ),
    .brch_cmt_bjp_res           ( brch_cmt_bjp_res          ),
    .brch_cmt_gpr_wen           ( brch_cmt_gpr_wen          )
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

    .sys_cmt_vld                ( sys_cmt_vld               ),
    .sys_cmt_rdy                ( sys_cmt_rdy               ),
    .sys_cmt_ebreak             ( sys_cmt_ebreak            ),
    .sys_cmt_ecall              ( sys_cmt_ecall             ),
    .sys_cmt_wfi                ( sys_cmt_wfi               ),

    .clk                        ( clk                       ),
    .reset_n                    ( reset_n                   )
);

// 访存指令执行模块
lnrv_exu_lsu u_lnrv_exu_lsu
(
    .op_vld                     ( lsu_op_vld                ),
    .op_rdy                     ( lsu_op_rdy                ),
    .op_bus                     ( lsu_op_bus                ),

    .rs1_rdata                  ( rs1_rdata                 ),
    .rs2_rdata                  ( rs2_rdata                 ),
    .imm                        ( idu_imm                   ),

    .lsu_cmt_vld                ( lsu_cmt_vld               ),
    .lsu_cmt_rdy                ( lsu_cmt_rdy               ),
    .lsu_cmt_ld                 ( lsu_cmt_ld                ),
    .lsu_cmt_st                 ( lsu_cmt_st                ),
    .lsu_cmt_misalgn            ( lsu_cmt_misalgn           ),
    .lsu_cmt_buserr             ( lsu_cmt_buserr            ),
    .lsu_cmt_addr               ( lsu_cmt_addr              ),
    .lsu_cmt_gpr_wdata          ( lsu_cmt_gpr_wdata         ),

    .lsu2alu_op_vld             ( lsu2alu_op_vld            ),
    .lsu2alu_op_rdy             ( lsu2alu_op_rdy            ),
    .lsu2alu_op_bus             ( lsu2alu_op_bus            ),
    .lsu2alu_in1                ( lsu2alu_in1               ),
    .lsu2alu_in2                ( lsu2alu_in2               ),
    .lsu2alu_res                ( alu_res                   ),

    .lsu_cmd_vld                ( lsu_cmd_vld               ),
    .lsu_cmd_rdy                ( lsu_cmd_rdy               ),
    .lsu_cmd_write              ( lsu_cmd_write             ),
    .lsu_cmd_addr               ( lsu_cmd_addr              ),
    .lsu_cmd_wdata              ( lsu_cmd_wdata             ),
    .lsu_cmd_wstrb              ( lsu_cmd_wstrb             ),
    .lsu_cmd_size               ( lsu_cmd_size              ),
    .lsu_rsp_rdy                ( lsu_rsp_rdy               ),
    .lsu_rsp_vld                ( lsu_rsp_vld               ),
    .lsu_rsp_rdata              ( lsu_rsp_rdata             ),
    .lsu_rsp_err                ( lsu_rsp_err               ),

    .clk                        ( clk                       ),
    .reset_n                    ( reset_n                   )
);

// 运算单元
lnrv_exu_alu u_lnrv_exu_alu
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

    .alu_res                    ( alu_res                   )
);

assign      exu_active = 1'b1;

endmodule