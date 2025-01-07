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
    input                                   idu_prdt_taken,

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
    output                                  cmt_rv32_ir,
    output                                  cmt_brch_dret,
    output                                  cmt_brch_mret,
    output                                  cmt_brch_fence,
    output                                  cmt_brch_jal,
    output                                  cmt_brch_jalr,
    output                                  cmt_brch_bjp,
    output                                  cmt_prdt_taken,
    output                                  cmt_csr_idx_err,
    output                                  cmt_csr,
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

    input                                   clk,
    input                                   reset_n
);

wire                                sel_rglr;
wire                                op_vld_rglr;
wire                                op_rdy_rglr;
wire[`RGLR_OP_BUS_WIDTH - 1 : 0]    op_bus_rglr;
wire                                cmt_vld_rglr;
wire                                cmt_rdy_rglr;
wire                                gpr_wen_rglr;
wire[31 : 0]                        gpr_wdata_rglr;
wire                                alu_op_vld_rglr;
wire                                alu_op_rdy_rglr;
wire[`ALU_OP_BUS_WIDTH - 1 : 0]     alu_op_bus_rglr;
wire[32 : 0]                        alu_in1_rglr;
wire[32 : 0]                        alu_in2_rglr;

wire                                sel_lsu;
wire                                op_vld_lsu;
wire                                op_rdy_lsu;
wire[`LSU_OP_BUS_WIDTH - 1 : 0]     op_bus_lsu;
wire                                cmt_vld_lsu;
wire                                cmt_rdy_lsu;
wire                                gpr_wen_lsu;
wire[31 : 0]                        gpr_wdata_lsu;
wire                                alu_op_vld_lsu;
wire                                alu_op_rdy_lsu;
wire[`ALU_OP_BUS_WIDTH - 1 : 0]     alu_op_bus_lsu;
wire[32 : 0]                        alu_in1_lsu;
wire[32 : 0]                        alu_in2_lsu;

wire                                sel_brch;
wire                                op_vld_brch;
wire                                op_rdy_brch;
wire[`BRCH_OP_BUS_WIDTH - 1 : 0]    op_bus_brch;
wire                                cmt_vld_brch;
wire                                cmt_rdy_brch;
wire                                gpr_wen_brch;
wire[31 : 0]                        gpr_wdata_brch;
wire                                alu_op_vld_brch;
wire                                alu_op_rdy_brch;
wire[`ALU_OP_BUS_WIDTH - 1 : 0]     alu_op_bus_brch;
wire[32 : 0]                        alu_in1_brch;
wire[32 : 0]                        alu_in2_brch;

wire                                sel_sys;
wire                                op_vld_sys;
wire                                op_rdy_sys;
wire[`SYS_OP_BUS_WIDTH - 1 : 0]     op_bus_sys;
wire                                cmt_vld_sys;
wire                                cmt_rdy_sys;

wire                                sel_csr;
wire                                op_vld_csr;
wire                                op_rdy_csr;
wire[`CSR_OP_BUS_WIDTH - 1 : 0]     op_bus_csr;
wire                                cmt_vld_csr;
wire                                cmt_rdy_csr;
wire                                gpr_wen_csr;
wire[31 : 0]                        gpr_wdata_csr;
wire                                alu_op_vld_csr;
wire                                alu_op_rdy_csr;
wire[`ALU_OP_BUS_WIDTH - 1 : 0]     alu_op_bus_csr;
wire[32 : 0]                        alu_in1_csr;
wire[32 : 0]                        alu_in2_csr;

wire                                sel_mdv;
wire                                op_vld_mdv;
wire                                op_rdy_mdv;
wire[`MDV_OP_BUS_WIDTH - 1 : 0]     op_bus_mdv;
wire                                cmt_vld_mdv;
wire                                cmt_rdy_mdv;
wire                                gpr_wen_mdv;
wire[31 : 0]                        gpr_wdata_mdv;
wire                                alu_op_vld_mdv;
wire                                alu_op_rdy_mdv;
wire[`ALU_OP_BUS_WIDTH - 1 : 0]     alu_op_bus_mdv;
wire[32 : 0]                        alu_in1_mdv;
wire[32 : 0]                        alu_in2_mdv;

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
    .op_bus_rglr                ( op_bus_rglr               ),

    .sel_lsu                    ( sel_lsu                   ),
    .op_bus_lsu                 ( op_bus_lsu                ),

    .sel_brch                   ( sel_brch                  ),
    .op_bus_brch                ( op_bus_brch               ),

    .sel_csr                    ( sel_csr                   ),
    .op_bus_csr                 ( op_bus_csr                ),

    .sel_sys                    ( sel_sys                   ),
    .op_bus_sys                 ( op_bus_sys                ),

    .sel_mdv                    ( sel_mdv                   ),
    .op_bus_mdv                 ( op_bus_mdv                )
);

assign      op_vld_rglr         = sel_rglr & idu_vld;
assign      op_vld_csr          = sel_csr & idu_vld;
assign      op_vld_sys          = sel_sys & idu_vld;
assign      op_vld_mdv          = sel_mdv & idu_vld;
assign      op_vld_brch         = sel_brch & idu_vld;
assign      op_vld_lsu          = sel_lsu & idu_vld;
assign      op_vld_mdv          = sel_mdv & idu_vld;

// 常规指令执行模块
lnrv_exu_rglr u_lnrv_exu_rglr
(
    .op_vld                     ( op_vld_rglr               ),
    .op_rdy                     ( op_rdy_rglr               ),
    .op_bus                     ( op_bus_rglr               ),

    .rs1_rdata                  ( rs1_rdata                 ),
    .rs2_rdata                  ( rs2_rdata                 ),
    .imm                        ( idu_imm                   ),
    .pc                         ( idu_pc                    ),

    .alu_op_vld                 ( alu_op_vld_rglr           ),
    .alu_op_rdy                 ( alu_op_rdy_rglr           ),
    .alu_op_bus                 ( alu_op_bus_rglr           ),
    .alu_in1                    ( alu_in1_rglr              ),
    .alu_in2                    ( alu_in2_rglr              ),
    .alu_res                    ( alu_res                   ),

    .cmt_vld                    ( cmt_vld_rglr              ),
    .cmt_rdy                    ( cmt_rdy_rglr              ),

    .gpr_wen                    ( gpr_wen_rglr              ),
    .gpr_wdata                  ( gpr_wdata_rglr            )
);

// csr指令处理模块
lnrv_exu_csr u_lnrv_exu_csr
(
    .op_vld                     ( op_vld_csr                ),
    .op_rdy                     ( op_rdy_csr                ),
    .op_bus                     ( op_bus_csr                ),

    .imm                        ( idu_imm                   ),

    .csr_idx_err                ( csr_idx_err               ),
    .csr_rdata                  ( csr_rdata                 ),
    .rs1_rdata                  ( rs1_rdata                 ),

    .alu_op_vld                 ( alu_op_vld_csr            ),
    .alu_op_rdy                 ( alu_op_rdy_csr            ),
    .alu_op_bus                 ( alu_op_bus_csr            ),
    .alu_in1                    ( alu_in1_csr               ),
    .alu_in2                    ( alu_in2_csr               ),
    .alu_res                    ( alu_res                   ),

    .cmt_vld                    ( cmt_vld_csr               ),
    .cmt_rdy                    ( cmt_rdy_csr               ),
    .cmt_idx_err                ( cmt_csr_idx_err           ),

    .gpr_wen                    ( gpr_wen_csr               ),
    .gpr_wdata                  ( gpr_wdata_csr             ),

    .csr_wbck_vld               ( csr_wbck_vld              ),
    .csr_wbck_rdy               ( csr_wbck_rdy              ),
    .csr_wbck_wdata             ( csr_wbck_wdata            )
);

// 分支相关指令执行模块
lnrv_exu_brch u_lnrv_exu_brch
(
    .op_vld                     ( op_vld_brch               ),
    .op_rdy                     ( op_rdy_brch               ),
    .op_bus                     ( op_bus_brch               ),

    .rs1_rdata                  ( rs1_rdata                 ),
    .rs2_rdata                  ( rs2_rdata                 ),
    .pc                         ( idu_pc                    ),
    .imm                        ( idu_imm                   ),
    .rv32_ir                    ( idu_rv32                  ),

    .alu_op_vld                 ( alu_op_vld_brch           ),
    .alu_op_rdy                 ( alu_op_rdy_brch           ),
    .alu_op_bus                 ( alu_op_bus_brch           ),
    .alu_in1                    ( alu_in1_brch              ),
    .alu_in2                    ( alu_in2_brch              ),
    .alu_res                    ( alu_res                   ),

    .cmt_vld                    ( cmt_vld_brch              ),
    .cmt_rdy                    ( cmt_rdy_brch              ),

    .cmt_dret                   ( cmt_brch_dret             ),
    .cmt_mret                   ( cmt_brch_mret             ),
    .cmt_fence                  ( cmt_brch_fence            ),
    .cmt_bjp                    ( cmt_brch_bjp              ),
    .cmt_jalr                   ( cmt_brch_jalr             ),
    .cmt_jal                    ( cmt_brch_jal              ),

    .gpr_wen                    ( gpr_wen_brch              ),
    .gpr_wdata                  ( gpr_wdata_brch            )
);


// 乘除法指令执行模块
lnrv_exu_mdv u_lnrv_exu_mdv
(
    .op_vld                     ( op_vld_mdv                ),
    .op_rdy                     ( op_rdy_mdv                ),
    .op_bus                     ( op_bus_mdv                ),

    .rs1_rdata                  ( rs1_rdata                 ),
    .rs2_rdata                  ( rs2_rdata                 ),

    .gpr_wen                    ( gpr_wen_mdv               ),
    .gpr_wdata                  ( gpr_wdata_mdv             ),

    .alu_op_vld                 ( alu_op_vld_mdv            ),
    .alu_op_rdy                 ( alu_op_rdy_mdv            ),
    .alu_op_bus                 ( alu_op_bus_mdv            ),
    .alu_in1                    ( alu_in1_mdv               ),
    .alu_in2                    ( alu_in2_mdv               ),
    .alu_res                    ( alu_res                   ),

    .cmt_vld                    ( cmt_vld_mdv               ),
    .cmt_rdy                    ( cmt_rdy_mdv               ),

    .clk                        ( clk                       ),
    .reset_n                    ( reset_n                   )
);

// 系统相关指令处理模块
lnrv_exu_sys u_lnrv_exu_sys
(
    .op_vld                     ( op_vld_sys                ),
    .op_rdy                     ( op_rdy_sys                ),
    .op_bus                     ( op_bus_sys                ),

    .cmt_vld                    ( cmt_vld_sys               ),
    .cmt_rdy                    ( cmt_rdy_sys               ),
    .cmt_ebreak                 ( cmt_sys_ebreak            ),
    .cmt_ecall                  ( cmt_sys_ecall             ),
    .cmt_wfi                    ( cmt_sys_wfi               )
);

// 访存指令执行模块
lnrv_exu_lsu u_lnrv_exu_lsu
(
    .op_vld                     ( op_vld_lsu                ),
    .op_rdy                     ( op_rdy_lsu                ),
    .op_bus                     ( op_bus_lsu                ),

    .rs1_rdata                  ( rs1_rdata                 ),
    .rs2_rdata                  ( rs2_rdata                 ),
    .imm                        ( idu_imm                   ),

    .cmt_vld                    ( cmt_vld_lsu               ),
    .cmt_rdy                    ( cmt_rdy_lsu               ),
    .cmt_ld                     ( cmt_lsu_ld                ),
    .cmt_st                     ( cmt_lsu_st                ),
    .cmt_excp_misalgn           ( cmt_lsu_excp_misalgn      ),
    .cmt_excp_buserr            ( cmt_lsu_excp_buserr       ),
    .cmt_addr                   ( cmt_lsu_addr              ),

    .gpr_wen                    ( gpr_wen_lsu               ),
    .gpr_wdata                  ( gpr_wdata_lsu             ),

    .alu_op_vld                 ( alu_op_vld_lsu            ),
    .alu_op_rdy                 ( alu_op_rdy_lsu            ),
    .alu_op_bus                 ( alu_op_bus_lsu            ),
    .alu_in1                    ( alu_in1_lsu               ),
    .alu_in2                    ( alu_in2_lsu               ),
    .alu_res                    ( alu_res                   ),

    .icb_cmd_vld_lsu            ( icb_cmd_vld_lsu           ),
    .icb_cmd_rdy_lsu            ( icb_cmd_rdy_lsu           ),
    .icb_cmd_write_lsu          ( icb_cmd_write_lsu         ),
    .icb_cmd_addr_lsu           ( icb_cmd_addr_lsu          ),
    .icb_cmd_wdata_lsu          ( icb_cmd_wdata_lsu         ),
    .icb_cmd_wstrb_lsu          ( icb_cmd_wstrb_lsu         ),
    .icb_cmd_size_lsu           ( icb_cmd_size_lsu          ),
    .icb_rsp_rdy_lsu            ( icb_rsp_rdy_lsu           ),
    .icb_rsp_vld_lsu            ( icb_rsp_vld_lsu           ),
    .icb_rsp_rdata_lsu          ( icb_rsp_rdata_lsu         ),
    .icb_rsp_err_lsu            ( icb_rsp_err_lsu           ),

    .clk                        ( clk                       ),
    .reset_n                    ( reset_n                   )
);

// 运算单元
lnrv_exu_alu u_lnrv_exu_alu
(
    .alu_op_vld_rglr            ( alu_op_vld_rglr           ),
    .alu_op_rdy_rglr            ( alu_op_rdy_rglr           ),
    .alu_op_bus_rglr            ( alu_op_bus_rglr           ),
    .alu_in1_rglr               ( alu_in1_rglr              ),
    .alu_in2_rglr               ( alu_in2_rglr              ),

    .alu_op_vld_brch            ( alu_op_vld_brch           ),
    .alu_op_rdy_brch            ( alu_op_rdy_brch           ),
    .alu_op_bus_brch            ( alu_op_bus_brch           ),
    .alu_in1_brch               ( alu_in1_brch              ),
    .alu_in2_brch               ( alu_in2_brch              ),

    .alu_op_vld_csr             ( alu_op_vld_csr            ),
    .alu_op_rdy_csr             ( alu_op_rdy_csr            ),
    .alu_op_bus_csr             ( alu_op_bus_csr            ),
    .alu_in1_csr                ( alu_in1_csr               ),
    .alu_in2_csr                ( alu_in2_csr               ),

    .alu_op_vld_lsu             ( alu_op_vld_lsu            ),
    .alu_op_rdy_lsu             ( alu_op_rdy_lsu            ),
    .alu_op_bus_lsu             ( alu_op_bus_lsu            ),
    .alu_in1_lsu                ( alu_in1_lsu               ),
    .alu_in2_lsu                ( alu_in2_lsu               ),

    .alu_op_vld_mdv             ( alu_op_vld_mdv            ),
    .alu_op_rdy_mdv             ( alu_op_rdy_mdv            ),
    .alu_op_bus_mdv             ( alu_op_bus_mdv            ),
    .alu_in1_mdv                ( alu_in1_mdv               ),
    .alu_in2_mdv                ( alu_in2_mdv               ),

    .alu_res                    ( alu_res                   )
);

// 指令交付成功，且需要写回寄存器
assign      gpr_wbck_vld =  cmt_vld & cmt_rdy &
                            (
                                (sel_rglr   & gpr_wen_rglr) |
                                (sel_csr    & gpr_wen_csr) |
                                (sel_brch   & gpr_wen_brch) |
                                (sel_lsu    & gpr_wen_lsu) |
                                (sel_mdv    & gpr_wen_mdv) |
                                1'b0
                            );

assign      gpr_wbck_idx = idu_rd;
assign      gpr_wbck_wdata =    ({32{sel_rglr}} & gpr_wdata_rglr) |
                                ({32{sel_csr}}  & gpr_wdata_csr) |
                                ({32{sel_brch}} & gpr_wdata_brch) |
                                ({32{sel_mdv}}  & gpr_wdata_mdv) |
                                ({32{sel_lsu}}  & gpr_wdata_lsu);

// 交付接口
assign      cmt_vld =   sel_lsu ? cmt_vld_lsu :
                        sel_rglr ? cmt_vld_rglr :
                        sel_brch ? cmt_vld_brch :
                        sel_sys ? cmt_vld_sys :
                        sel_csr ? cmt_vld_csr :
                        sel_mdv ? cmt_vld_mdv :
                        idu_vld;

assign      cmt_rv32_ir = idu_rv32;
assign      cmt_prdt_taken = idu_prdt_taken;

assign      cmt_csr     = sel_csr;
assign      cmt_rglr    = sel_rglr;

assign      cmt_ifu_excp_buserr = idu_excp_buserr;
assign      cmt_ifu_excp_misalgn = idu_excp_misalgn;
assign      cmt_idu_excp_ilglir = idu_excp_ilglir;

assign      cmt_rdy_rglr    = sel_rglr & cmt_rdy;
assign      cmt_rdy_csr     = sel_csr & cmt_rdy;
assign      cmt_rdy_sys     = sel_sys & cmt_rdy;
assign      cmt_rdy_lsu     = sel_lsu & cmt_rdy;
assign      cmt_rdy_brch    = sel_brch & cmt_rdy;
assign      cmt_rdy_mdv     = sel_mdv & cmt_rdy;

assign      idu_rdy = cmt_rdy;

assign      exu_active = 1'b1;

endmodule