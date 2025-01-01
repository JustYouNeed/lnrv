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
    input                                   idu_vld,
    output                                  idu_rdy,
    input[`DEC_OP_BUS_WIDTH - 1 : 0]        idu_op_bus,
    input[`DEC_OP_TYPE_WIDTH - 1 : 0]       idu_op_type,
    input[31 : 0]                           idu_imm,
    input[31 : 0]                           idu_pc,
    input[31 : 0]                           idu_ir,
    input[4 : 0]                            idu_rd,
    input                                   idu_excp_buserr,
    input                                   idu_excp_ilglir,
    input                                   idu_excp_misalgn,
    input                                   idu_rv32,

    // 寄存器读取接口
    input[31 : 0]                           rs1_rdata,
    input[31 : 0]                           rs2_rdata,

    // 通用寄存器写回接口
    output                                  gpr_wbck_vld,
    input                                   gpr_wbck_rdy,
    output[4 : 0]                           gpr_wbck_idx,
    output[31 : 0]                          gpr_wbck_wdata,

    // CSR寄存器读取接口
    input[31 : 0]                           csr_rdata,
    input                                   csr_idx_err,

    // CSR寄存器写回接口
    output                                  csr_wbck_vld,
    input                                   csr_wbck_rdy,
    output[31 : 0]                          csr_wbck_wdata,

    // 交付接口
    output                                  cmt_vld,
    input                                   cmt_rdy,
    output                                  cmt_brch_dret,
    output                                  cmt_brch_mret,
    output                                  cmt_brch_fence,
    output                                  cmt_brch_jal,
    output                                  cmt_brch_jalr,
    output                                  cmt_brch_bjp,
    output                                  cmt_csr_idxerr,
    input                                   cmt_csr,
    output                                  cmt_rglr,
    output                                  cmt_ifu_excp_buserr,
    output                                  cmt_ifu_excp_misalgn,
    output                                  cmt_idu_excp_ilglir,
    output                                  cmt_sys_ebreak,
    output                                  cmt_sys_ecall,
    output                                  cmt_sys_wfi,
    output                                  cmt_lsu_ld,
    output                                  cmt_lsu_st,
    output                                  cmt_lsu_excp_misalgn,
    output                                  cmt_lsu_excp_buserr,
    output[31 : 0]                          cmt_lsu_addr,

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

wire                                sel_rglr;
wire                                rglr_op_vld;
wire                                rglr_op_rdy;
wire[`RGLR_OP_BUS_WIDTH - 1 : 0]    rglr_op_bus;
wire                                rglr_cmt_vld;
wire                                rglr_cmt_rdy;
wire                                rglr_gpr_wen;
wire[31 : 0]                        rglr_gpr_wdata;
wire                                rglr2alu_op_vld;
wire                                rglr2alu_op_rdy;
wire[`ALU_OP_BUS_WIDTH - 1 : 0]     rglr2alu_op_bus;
wire[32 : 0]                        rglr2alu_in1;
wire[32 : 0]                        rglr2alu_in2;

wire                                sel_lsu;
wire                                lsu_op_vld;
wire                                lsu_op_rdy;
wire[`LSU_OP_BUS_WIDTH - 1 : 0]     lsu_op_bus;
wire                                lsu_cmt_vld;
wire                                lsu_cmt_rdy;
wire                                lsu_cmt_ld;
wire                                lsu_cmt_st;
wire                                lsu_cmt_excp_buserr;
wire                                lsu_cmt_excp_misalg;
wire[31 : 0]                        lsu_cmt_addr;
wire                                lsu_gpr_wen;
wire[31 : 0]                        lsu_gpr_wdata;
wire                                lsu2alu_op_vld;
wire                                lsu2alu_op_rdy;
wire[`ALU_OP_BUS_WIDTH - 1 : 0]     lsu2alu_op_bus;
wire[32 : 0]                        lsu2alu_in1;
wire[32 : 0]                        lsu2alu_in2;

wire                                sel_brch;
wire                                brch_op_vld;
wire                                brch_op_rdy;
wire[`BRCH_OP_BUS_WIDTH - 1 : 0]    brch_op_bus;
wire                                brch_cmt_vld;
wire                                brch_cmt_rdy;
wire                                brch_cmt_bjp;
wire                                brch_cmt_dret;
wire                                brch_cmt_fence;
wire                                brch_cmt_jal;
wire                                brch_cmt_jalr;
wire                                brch_cmt_mret;
wire                                brch_gpr_wen;
wire[31 : 0]                        brch_gpr_wdata;
wire                                brch2alu_op_vld;
wire                                brch2alu_op_rdy;
wire[`ALU_OP_BUS_WIDTH - 1 : 0]     brch2alu_op_bus;
wire[32 : 0]                        brch2alu_in1;
wire[32 : 0]                        brch2alu_in2;

wire                                sel_sys;
wire                                sys_op_vld;
wire                                sys_op_rdy;
wire[`SYS_OP_BUS_WIDTH - 1 : 0]     sys_op_bus;
wire                                sys_cmt_vld;
wire                                sys_cmt_rdy;
wire                                sys_cmt_ebreak;
wire                                sys_cmt_ecall;
wire                                sys_cmt_wfi;

wire                                sel_csr;
wire                                csr_op_vld;
wire                                csr_op_rdy;
wire[`CSR_OP_BUS_WIDTH - 1 : 0]     csr_op_bus;
wire                                csr_cmt_vld;
wire                                csr_cmt_rdy;
wire                                csr_cmt_idx_err;
wire                                csr_gpr_wen;
wire[31 : 0]                        csr_gpr_wdata;
wire                                csr2alu_op_vld;
wire                                csr2alu_op_rdy;
wire[`ALU_OP_BUS_WIDTH - 1 : 0]     csr2alu_op_bus;
wire[32 : 0]                        csr2alu_in1;
wire[32 : 0]                        csr2alu_in2;

wire                                sel_mdv;
wire                                mdv_op_vld;
wire                                mdv_op_rdy;
wire[`MDV_OP_BUS_WIDTH - 1 : 0]     mdv_op_bus;
wire                                mdv_cmt_vld;
wire                                mdv_cmt_rdy;
wire                                mdv_gpr_wen;
wire[31 : 0]                        mdv_gpr_wdata;
wire                                mdv2alu_op_vld;
wire                                mdv2alu_op_rdy;
wire[`ALU_OP_BUS_WIDTH - 1 : 0]     mdv2alu_op_bus;
wire[32 : 0]                        mdv2alu_in1;
wire[32 : 0]                        mdv2alu_in2;

wire[34 : 0]                        alu_res;

// 指令派遣模块
lnrv_exu_disp u_lnrv_exu_disp
(
    .idu_op_bus                 ( idu_op_bus                ),
    .idu_op_type                ( idu_op_type               ),
    .idu_excp_buserr            ( idu_excp_buserr           ),
    .idu_excp_ilglir            ( idu_excp_ilglir           ),
    .idu_excp_misalgn           ( idu_excp_misalgn          ),

    .sel_rglr                   ( sel_rglr                  ),
    .rglr_op_bus                ( rglr_op_bus               ),

    .sel_lsu                    ( sel_lsu                   ),
    .lsu_op_bus                 ( lsu_op_bus                ),

    .sel_brch                   ( sel_brch                  ),
    .brch_op_bus                ( brch_op_bus               ),

    .sel_csr                    ( sel_csr                   ),
    .csr_op_bus                 ( csr_op_bus                ),

    .sel_sys                    ( sel_sys                   ),
    .sys_op_bus                 ( sys_op_bus                ),

    .sel_mdv                    ( sel_mdv                   ),
    .mdv_op_bus                 ( mdv_op_bus                )
);

assign      rglr_op_vld = sel_rglr & idu_vld;
assign      csr_op_vld = sel_csr & idu_vld;
assign      sys_op_vld = sel_sys & idu_vld;
assign      mdv_op_vld = sel_mdv & idu_vld;
assign      brch_op_vld = sel_brch & idu_vld;
assign      lsu_op_vld = sel_lsu & idu_vld;
assign      mdv_op_vld = sel_mdv & idu_vld;

// 常规指令执行模块
lnrv_exu_rglr u_lnrv_exu_rglr
(
    .op_vld                     ( rglr_op_vld               ),
    .op_rdy                     ( rglr_op_rdy               ),
    .op_bus                     ( rglr_op_bus               ),

    .rs1_rdata                  ( rs1_rdata                 ),
    .rs2_rdata                  ( rs2_rdata                 ),
    .imm                        ( idu_imm                   ),
    .pc                         ( idu_pc                    ),

    .alu_op_vld                 ( rglr2alu_op_vld           ),
    .alu_op_rdy                 ( rglr2alu_op_rdy           ),
    .alu_op_bus                 ( rglr2alu_op_bus           ),
    .alu_in1                    ( rglr2alu_in1              ),
    .alu_in2                    ( rglr2alu_in2              ),
    .alu_res                    ( alu_res                   ),

    .cmt_vld                    ( rglr_cmt_vld              ),
    .cmt_rdy                    ( rglr_cmt_rdy              ),

    .gpr_wen                    ( rglr_gpr_wen              ),
    .gpr_wdata                  ( rglr_gpr_wdata            )
);

// csr指令处理模块 
lnrv_exu_csr u_lnrv_exu_csr
(
    .op_vld                     ( csr_op_vld                ),
    .op_rdy                     ( csr_op_rdy                ),
    .op_bus                     ( csr_op_bus                ),

    .imm                        ( idu_imm                   ),

    .csr_idx_err                ( csr_idx_err               ),
    .csr_rdata                  ( csr_rdata                 ),
    .rs1_rdata                  ( rs1_rdata                 ),

    .alu_op_vld                 ( csr2alu_op_vld            ),
    .alu_op_rdy                 ( csr2alu_op_rdy            ),
    .alu_op_bus                 ( csr2alu_op_bus            ),
    .alu_in1                    ( csr2alu_in1               ),
    .alu_in2                    ( csr2alu_in2               ),
    .alu_res                    ( alu_res                   ),

    .cmt_vld                    ( csr_cmt_vld               ),
    .cmt_rdy                    ( csr_cmt_rdy               ),
    .cmt_idx_err                ( csr_cmt_idx_err           ),

    .gpr_wen                    ( csr_gpr_wen               ),
    .gpr_wdata                  ( csr_gpr_wdata             ),

    .csr_wbck_vld               ( csr_wbck_vld              ),
    .csr_wbck_rdy               ( csr_wbck_rdy              ),
    .csr_wbck_wdata             ( csr_wbck_wdata            )
);

// 分支相关指令执行模块
lnrv_exu_brch u_lnrv_exu_brch
(
    .op_vld                     ( brch_op_vld               ),
    .op_rdy                     ( brch_op_rdy               ),
    .op_bus                     ( brch_op_bus               ),
    
    .rs1_rdata                  ( rs1_rdata                 ),
    .rs2_rdata                  ( rs2_rdata                 ),
    .pc                         ( idu_pc                    ),
    .imm                        ( idu_imm                   ),
    .rv32_ir                    ( idu_rv32                  ),
    
    .alu_op_vld                 ( brch2alu_op_vld           ),
    .alu_op_rdy                 ( brch2alu_op_rdy           ),
    .alu_op_bus                 ( brch2alu_op_bus           ),
    .alu_in1                    ( brch2alu_in1              ),
    .alu_in2                    ( brch2alu_in2              ),
    .alu_res                    ( alu_res                   ),

    .cmt_vld                    ( brch_cmt_vld              ),
    .cmt_rdy                    ( brch_cmt_rdy              ),
    .cmt_dret                   ( brch_cmt_dret             ),
    .cmt_mret                   ( brch_cmt_mret             ),
    .cmt_fence                  ( brch_cmt_fence            ),
    .cmt_bjp                    ( brch_cmt_bjp              ),
    .cmt_jalr                   ( brch_cmt_jalr             ),
    .cmt_jal                    ( brch_cmt_jal              ),

    .gpr_wen                    ( brch_gpr_wen              ),
    .gpr_wdata                  ( brch_gpr_wdata            )
);


// 乘除法指令执行模块
lnrv_exu_mdv u_lnrv_exu_mdv
(
    .op_vld                     ( mdv_op_vld                ),
    .op_rdy                     ( mdv_op_rdy                ),
    .op_bus                     ( mdv_op_bus                ),

    .rs1_rdata                  ( rs1_rdata                 ),
    .rs2_rdata                  ( rs2_rdata                 ),

    .gpr_wen                    ( mdv_gpr_wen               ),
    .gpr_wdata                  ( mdv_gpr_wdata             ),

    .alu_op_vld                 ( mdv2alu_op_vld            ),
    .alu_op_rdy                 ( mdv2alu_op_rdy            ),
    .alu_op_bus                 ( mdv2alu_op_bus            ),
    .alu_in1                    ( mdv2alu_in1               ),
    .alu_in2                    ( mdv2alu_in2               ),
    .alu_res                    ( alu_res                   ),

    .cmt_vld                    ( mdv_cmt_vld               ),
    .cmt_rdy                    ( mdv_cmt_rdy               ),

    .clk                        ( clk                       ),
    .reset_n                    ( reset_n                   )
);

// 系统相关指令处理模块 
lnrv_exu_sys u_lnrv_exu_sys
(
    .op_vld                     ( sys_op_vld                ),
    .op_rdy                     ( sys_op_rdy                ),
    .op_bus                     ( sys_op_bus                ),

    .cmt_vld                    ( sys_cmt_vld               ),
    .cmt_rdy                    ( sys_cmt_rdy               ),
    .cmt_ebreak                 ( sys_cmt_ebreak            ),
    .cmt_ecall                  ( sys_cmt_ecall             ),
    .cmt_wfi                    ( sys_cmt_wfi               )
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

    .cmt_vld                    ( lsu_cmt_vld               ),
    .cmt_rdy                    ( lsu_cmt_rdy               ),
    .cmt_ld                     ( lsu_cmt_ld                ),
    .cmt_st                     ( lsu_cmt_st                ),
    .cmt_excp_misalgn           ( lsu_cmt_excp_misalgn      ),
    .cmt_excp_buserr            ( lsu_cmt_excp_buserr       ),
    .cmt_addr                   ( lsu_cmt_addr              ),

    .gpr_wen                    ( lsu_gpr_wen               ),
    .gpr_wdata                  ( lsu_gpr_wdata             ),

    .alu_op_vld                 ( lsu2alu_op_vld            ),
    .alu_op_rdy                 ( lsu2alu_op_rdy            ),
    .alu_op_bus                 ( lsu2alu_op_bus            ),
    .alu_in1                    ( lsu2alu_in1               ),
    .alu_in2                    ( lsu2alu_in2               ),
    .alu_res                    ( alu_res                   ),

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

    .mdv2alu_op_vld             ( mdv2alu_op_vld            ),
    .mdv2alu_op_rdy             ( mdv2alu_op_rdy            ),
    .mdv2alu_op_bus             ( mdv2alu_op_bus            ),
    .mdv2alu_in1                ( mdv2alu_in1               ),
    .mdv2alu_in2                ( mdv2alu_in2               ),

    .alu_res                    ( alu_res                   )
);

// 指令交付成功，且需要写回寄存器
assign      gpr_wbck_vld =  cmt_vld & cmt_rdy & 
                            (
                                (sel_rglr & rglr_gpr_wen) | 
                                (sel_csr & csr_gpr_wen) | 
                                (sel_brch & brch_gpr_wen) | 
                                (sel_lsu & lsu_gpr_wen) | 
                                (sel_mdv & mdv_gpr_wen) | 
                                1'b0
                            );

assign      gpr_wbck_idx = idu_rd;
assign      gpr_wbck_wdata =    ({32{sel_rglr}} & rglr_gpr_wdata) | 
                                ({32{sel_csr}} & csr_gpr_wdata) | 
                                ({32{sel_brch}} & brch_gpr_wdata) | 
                                ({32{sel_mdv}} & mdv_gpr_wdata) |
                                ({32{sel_lsu}} & lsu_gpr_wdata);

// 交付接口
assign      cmt_vld =   sel_lsu ? lsu_cmt_vld : 
                        sel_rglr ? rglr_cmt_vld : 
                        sel_brch ? brch_cmt_vld : 
                        sel_sys ? sys_cmt_vld : 
                        sel_csr ? csr_cmt_vld : 
                        sel_mdv ? mdv_cmt_vld :
                        idu_vld;

assign      cmt_csr = sel_csr;
assign      cmt_csr_idxerr = csr_cmt_idx_err;

assign      cmt_rglr = sel_rglr;

assign      cmt_brch_bjp = brch_cmt_bjp;
assign      cmt_brch_dret = brch_cmt_dret;
assign      cmt_brch_mret = brch_cmt_mret;
assign      cmt_brch_fence = brch_cmt_fence;
assign      cmt_brch_jal = brch_cmt_jal;
assign      cmt_brch_jalr = brch_cmt_jalr;

assign      cmt_lsu_ld = lsu_cmt_ld;
assign      cmt_lsu_st = lsu_cmt_st;
assign      cmt_lsu_addr = lsu_cmt_addr;
assign      cmt_lsu_excp_buserr = lsu_cmt_excp_buserr;
assign      cmt_lsu_excp_misalgn = lsu_cmt_excp_misalgn;

assign      cmt_sys_ecall = sys_cmt_ecall;
assign      cmt_sys_ebreak = sys_cmt_ebreak;
assign      cmt_sys_wfi = sys_cmt_wfi;

assign      cmt_ifu_excp_buserr = idu_excp_buserr;
assign      cmt_ifu_excp_misalgn = idu_excp_misalgn;
assign      cmt_idu_excp_ilglir = idu_excp_ilglir;

assign      rglr_cmt_rdy = sel_rglr & cmt_rdy;
assign      csr_cmt_rdy = sel_csr & cmt_rdy;
assign      sys_cmt_rdy = sel_sys & cmt_rdy;
assign      lsu_cmt_rdy = sel_lsu & cmt_rdy;
assign      brch_cmt_rdy = sel_brch & cmt_rdy;
assign      mdv_cmt_rdy = sel_mdv & cmt_rdy;

assign      idu_rdy = cmt_rdy;

assign      exu_active = 1'b1;

endmodule