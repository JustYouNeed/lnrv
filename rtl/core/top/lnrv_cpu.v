`include    "lnrv_def.v"
module  lnrv_cpu#
(
    parameter                               P_ILM_REGION_BASE = 32'h0000_0000,
    parameter                               P_ILM_ADDR_WIDTH = 17,

    parameter                               P_DLM_REGION_BASE = 32'h0002_0000,
    parameter                               P_DLM_ADDR_WIDTH = 17
)
(
    input[31 : 0]                           reset_vector,
    input[31 : 0]                           reset_mtvec,

    input                                   firmware_loading,

    input                                   irq_sft,
    input                                   irq_tmr,
    input                                   irq_ext,

    input                                   dbg_halt,
    input                                   irq_dbg,

    //
    output                                  wfi_mode,
    output                                  d_mode,

    output                                  dcsr_stoptime,
    output                                  dcsr_stopcount,

    output                                  icb_cmd_vld_sys,
    input                                   icb_cmd_rdy_sys,
    output                                  icb_cmd_write_sys,
    output[31 : 0]                          icb_cmd_addr_sys,
    output[31 : 0]                          icb_cmd_wdata_sys,
    output[3 : 0]                           icb_cmd_wstrb_sys,
    output[2 : 0]                           icb_cmd_size_sys,
    input                                   icb_rsp_vld_sys,
    output                                  icb_rsp_rdy_sys,
    input[31 : 0]                           icb_rsp_rdata_sys,
    input                                   icb_rsp_err_sys,

    // // 系统总线
    // output                                  sys_awvalid,
    // input                                   sys_awready,
    // output                                  sys_awlock,
    // output[31 : 0]                          sys_awaddr,
    // output[3 : 0]                           sys_awid,
    // output[7 : 0]                           sys_awlen,
    // output[2 : 0]                           sys_awsize,
    // output[1 : 0]                           sys_awburst,
    // output[3 : 0]                           sys_awcache,
    // output[2 : 0]                           sys_awprot,

    // output                                  sys_wvalid,
    // input                                   sys_wready,
    // output[31 : 0]                          sys_wdata,
    // output[3 : 0]                           sys_wstrb,
    // output                                  sys_wlast,

    // output                                  sys_bready,
    // input                                   sys_bvalid,
    // input[1 : 0]                            sys_bresp,
    // input[3 : 0]                            sys_bid,

    // output                                  sys_arvalid,
    // input                                   sys_arready,
    // output                                  sys_arlock,
    // output[31 : 0]                          sys_araddr,
    // output[3 : 0]                           sys_arid,
    // output[7 : 0]                           sys_arlen,
    // output[2 : 0]                           sys_arsize,
    // output[1 : 0]                           sys_arburst,
    // output[3 : 0]                           sys_arcache,
    // output[2 : 0]                           sys_arprot,

    // output                                  sys_rready,
    // input                                   sys_rvalid,
    // input[31 : 0]                           sys_rdata,
    // input[1 : 0]                            sys_rresp,
    // input                                   sys_rlast,
    // input[3 : 0]                            sys_rid,

    // Slave Port
    input                                   slv_awvalid,
    output                                  slv_awready,
    input                                   slv_awlock,
    input[31 : 0]                           slv_awaddr,
    input[3 : 0]                            slv_awid,
    input[7 : 0]                            slv_awlen,
    input[2 : 0]                            slv_awsize,
    input[1 : 0]                            slv_awburst,
    input[3 : 0]                            slv_awcache,
    input[2 : 0]                            slv_awprot,

    input                                   slv_wvalid,
    output                                  slv_wready,
    input[31 : 0]                           slv_wdata,
    input[3 : 0]                            slv_wstrb,
    input                                   slv_wlast,

    input                                   slv_bready,
    output                                  slv_bvalid,
    output[1 : 0]                           slv_bresp,
    output[3 : 0]                           slv_bid,

    input                                   slv_arvalid,
    output                                  slv_arready,
    input                                   slv_arlock,
    input[31 : 0]                           slv_araddr,
    input[3 : 0]                            slv_arid,
    input[7 : 0]                            slv_arlen,
    input[2 : 0]                            slv_arsize,
    input[1 : 0]                            slv_arburst,
    input[3 : 0]                            slv_arcache,
    input[2 : 0]                            slv_arprot,

    input                                   slv_rready,
    output                                  slv_rvalid,
    output[31 : 0]                          slv_rdata,
    output[1 : 0]                           slv_rresp,
    output                                  slv_rlast,
    output[3 : 0]                           slv_rid,

    // ilm接口
    output                                  ilm_clk,
    output                                  ilm_cs,
    output                                  ilm_we,
    output[3 : 0]                           ilm_wem,
    output[P_ILM_ADDR_WIDTH - 1 : 0]        ilm_addr,
    output[31 : 0]                          ilm_wdata,
    input[31 : 0]                           ilm_rdata,

    // dlm接口
    output                                  dlm_clk,
    output                                  dlm_cs,
    output                                  dlm_we,
    output[3 : 0]                           dlm_wem,
    output[P_DLM_ADDR_WIDTH - 1 : 0]        dlm_addr,
    output[31 : 0]                          dlm_wdata,
    input[31 : 0]                           dlm_rdata,


    input                                   clk,
    input                                   reset_n
);

localparam                      LP_ILM_SIZE = 2 ** P_ILM_ADDR_WIDTH;
localparam                      LP_ILM_REGION_START = P_ILM_REGION_BASE;
localparam                      LP_ILM_REGION_END = P_ILM_REGION_BASE + LP_ILM_SIZE;

localparam                      LP_DLM_SIZE = 2 ** P_DLM_ADDR_WIDTH;
localparam                      LP_DLM_REGION_START = P_DLM_REGION_BASE;
localparam                      LP_DLM_REGION_END = P_DLM_REGION_BASE + LP_DLM_SIZE;

localparam                      LP_CMD_CUT_VALID_IFU            = 1'b0;
localparam                      LP_CMD_CUT_READY_IFU            = 1'b1;
localparam                      LP_CMD_BUF_DEEPTH_IFU           = 1;
localparam                      LP_RSP_CUT_VALID_IFU            = 1'b1;
localparam                      LP_RSP_CUT_READY_IFU            = 1'b1;
localparam                      LP_RSP_BUF_DEEPTH_IFU           = 1;
localparam                      LP_OTS_CTRL_ENABLE_IFU          = 0;

localparam                      LP_CMD_CUT_VALID_EXU            = 1'b1;
localparam                      LP_CMD_CUT_READY_EXU            = 1'b1;
localparam                      LP_CMD_BUF_DEEPTH_EXU           = 1;
localparam                      LP_RSP_CUT_VALID_EXU            = 1'b1;
localparam                      LP_RSP_CUT_READY_EXU            = 1'b1;
localparam                      LP_RSP_BUF_DEEPTH_EXU           = 1;
localparam                      LP_OTS_CTRL_ENABLE_EXU          = 0;

localparam                      LP_CMD_CUT_VALID_SLV            = 1'b1;
localparam                      LP_CMD_CUT_READY_SLV            = 1'b1;
localparam                      LP_CMD_BUF_DEEPTH_SLV           = 1;
localparam                      LP_RSP_CUT_VALID_SLV            = 1'b1;
localparam                      LP_RSP_CUT_READY_SLV            = 1'b1;
localparam                      LP_RSP_BUF_DEEPTH_SLV           = 1;
localparam                      LP_OTS_CTRL_ENABLE_SLV          = 0;

localparam                      LP_CMD_CUT_VALID_ILM            = 1'b1;
localparam                      LP_CMD_CUT_READY_ILM            = 1'b1;
localparam                      LP_CMD_BUF_DEEPTH_ILM           = 1;
localparam                      LP_RSP_CUT_VALID_ILM            = 1'b1;
localparam                      LP_RSP_CUT_READY_ILM            = 1'b1;
localparam                      LP_RSP_BUF_DEEPTH_ILM           = 1;
localparam                      LP_OTS_CTRL_ENABLE_ILM          = 0;

localparam                      LP_CMD_CUT_VALID_DLM            = 1'b1;
localparam                      LP_CMD_CUT_READY_DLM            = 1'b1;
localparam                      LP_CMD_BUF_DEEPTH_DLM           = 1;
localparam                      LP_RSP_CUT_VALID_DLM            = 1'b1;
localparam                      LP_RSP_CUT_READY_DLM            = 1'b1;
localparam                      LP_RSP_BUF_DEEPTH_DLM           = 1;
localparam                      LP_OTS_CTRL_ENABLE_DLM          = 0;

localparam                      LP_CMD_CUT_VALID_SYS            = 1'b1;
localparam                      LP_CMD_CUT_READY_SYS            = 1'b1;
localparam                      LP_CMD_BUF_DEEPTH_SYS           = 1;
localparam                      LP_RSP_CUT_VALID_SYS            = 1'b1;
localparam                      LP_RSP_CUT_READY_SYS            = 1'b1;
localparam                      LP_RSP_BUF_DEEPTH_SYS           = 1;
localparam                      LP_OTS_CTRL_ENABLE_SYS          = 0;


wire                            icb_cmd_vld_ifu;
wire                            icb_cmd_rdy_ifu;
wire                            icb_cmd_write_ifu;
wire[31 : 0]                    icb_cmd_addr_ifu;
wire[31 : 0]                    icb_cmd_wdata_ifu;
wire[3 : 0]                     icb_cmd_wstrb_ifu;
wire[2 : 0]                     icb_cmd_size_ifu;
wire                            icb_rsp_vld_ifu;
wire                            icb_rsp_rdy_ifu;
wire[31 : 0]                    icb_rsp_rdata_ifu;
wire                            icb_rsp_err_ifu;


wire                            icb_cmd_vld_exu;
wire                            icb_cmd_rdy_exu;
wire                            icb_cmd_write_exu;
wire[31 : 0]                    icb_cmd_addr_exu;
wire[31 : 0]                    icb_cmd_wdata_exu;
wire[3 : 0]                     icb_cmd_wstrb_exu;
wire[2 : 0]                     icb_cmd_size_exu;
wire                            icb_rsp_vld_exu;
wire                            icb_rsp_rdy_exu;
wire[31 : 0]                    icb_rsp_rdata_exu;
wire                            icb_rsp_err_exu;


wire                            icb_cmd_vld_slv;
wire                            icb_cmd_rdy_slv;
wire                            icb_cmd_write_slv;
wire[31 : 0]                    icb_cmd_addr_slv;
wire[31 : 0]                    icb_cmd_wdata_slv;
wire[3 : 0]                     icb_cmd_wstrb_slv;
wire[2  : 0]                    icb_cmd_size_slv;
wire                            icb_rsp_vld_slv;
wire                            icb_rsp_rdy_slv;
wire[31 : 0]                    icb_rsp_rdata_slv;
wire                            icb_rsp_err_slv;

wire                            icb_cmd_vld_ilm;
wire                            icb_cmd_rdy_ilm;
wire                            icb_cmd_write_ilm;
wire[31 : 0]                    icb_cmd_addr_ilm;
wire[31 : 0]                    icb_cmd_wdata_ilm;
wire[3 : 0]                     icb_cmd_wstrb_ilm;
wire[2 : 0]                     icb_cmd_size_ilm;
wire                            icb_rsp_vld_ilm;
wire                            icb_rsp_rdy_ilm;
wire[31 : 0]                    icb_rsp_rdata_ilm;
wire                            icb_rsp_err_ilm;

wire                            icb_cmd_vld_dlm;
wire                            icb_cmd_rdy_dlm;
wire                            icb_cmd_write_dlm;
wire[31 : 0]                    icb_cmd_addr_dlm;
wire[31 : 0]                    icb_cmd_wdata_dlm;
wire[3 : 0]                     icb_cmd_wstrb_dlm;
wire[2 : 0]                     icb_cmd_size_dlm;
wire                            icb_rsp_vld_dlm;
wire                            icb_rsp_rdy_dlm;
wire[31 : 0]                    icb_rsp_rdata_dlm;
wire                            icb_rsp_err_dlm;


// wire                            icb_cmd_vld_sys;
// wire                            icb_cmd_rdy_sys;
// wire                            icb_cmd_write_sys;
// wire[31 : 0]                    icb_cmd_addr_sys;
// wire[31 : 0]                    icb_cmd_wdata_sys;
// wire[3 : 0]                     icb_cmd_wstrb_sys;
// wire[2 : 0]                     icb_cmd_size_sys;
// wire                            icb_rsp_vld_sys;
// wire                            icb_rsp_rdy_sys;
// wire[31 : 0]                    icb_rsp_rdata_sys;
// wire                            icb_rsp_err_sys;



//
lnrv_core u_lnrv_core
(
    .reset_vector           ( reset_vector              ),
    .reset_mtvec            ( reset_mtvec               ),
    .firmware_loading       ( firmware_loading          ),

    .irq_sft                ( irq_sft                   ),
    .irq_ext                ( irq_ext                   ),
    .irq_tmr                ( irq_tmr                   ),

    .dbg_halt               ( dbg_halt                  ),
    .irq_dbg                ( irq_dbg                   ),

    .wfi_mode               ( wfi_mode                  ),
    .d_mode                 ( d_mode                    ),

    .dcsr_stoptime          ( dcsr_stoptime             ),
    .dcsr_stopcount         ( dcsr_stopcount            ),

    // ifu访存接口
    .icb_cmd_vld_ifu        ( icb_cmd_vld_ifu           ),
    .icb_cmd_rdy_ifu        ( icb_cmd_rdy_ifu           ),
    .icb_cmd_write_ifu      ( icb_cmd_write_ifu         ),
    .icb_cmd_addr_ifu       ( icb_cmd_addr_ifu          ),
    .icb_cmd_wdata_ifu      ( icb_cmd_wdata_ifu         ),
    .icb_cmd_wstrb_ifu      ( icb_cmd_wstrb_ifu         ),
    .icb_cmd_size_ifu       ( icb_cmd_size_ifu          ),
    .icb_rsp_vld_ifu        ( icb_rsp_vld_ifu           ),
    .icb_rsp_rdy_ifu        ( icb_rsp_rdy_ifu           ),
    .icb_rsp_rdata_ifu      ( icb_rsp_rdata_ifu         ),
    .icb_rsp_err_ifu        ( icb_rsp_err_ifu           ),

    // exu访存接口
    .icb_cmd_vld_lsu        ( icb_cmd_vld_exu           ),
    .icb_cmd_rdy_lsu        ( icb_cmd_rdy_exu           ),
    .icb_cmd_write_lsu      ( icb_cmd_write_exu         ),
    .icb_cmd_addr_lsu       ( icb_cmd_addr_exu          ),
    .icb_cmd_wdata_lsu      ( icb_cmd_wdata_exu         ),
    .icb_cmd_wstrb_lsu      ( icb_cmd_wstrb_exu         ),
    .icb_cmd_size_lsu       ( icb_cmd_size_exu          ),
    .icb_rsp_vld_lsu        ( icb_rsp_vld_exu           ),
    .icb_rsp_rdy_lsu        ( icb_rsp_rdy_exu           ),
    .icb_rsp_rdata_lsu      ( icb_rsp_rdata_exu         ),
    .icb_rsp_err_lsu        ( icb_rsp_err_exu           ),

    .ifu_clk                ( clk                       ),
    .ifu_active             ( ifu_active                ),

    .idu_clk                ( clk                       ),
    .idu_active             ( idu_active                ),

    .exu_clk                ( clk                       ),
    .exu_active             ( exu_active                ),

    .clk                    ( clk                       ),
    .reset_n                ( reset_n                   )
);

// 总线矩阵
lnrv_biu#
(
    .P_ILM_REGION_START     ( LP_ILM_REGION_START       ),
    .P_ILM_REGION_END       ( LP_ILM_REGION_END         ),

    .P_DLM_REGION_START     ( LP_DLM_REGION_START       ),
    .P_DLM_REGION_END       ( LP_DLM_REGION_END         ),

    .P_ADDR_WIDTH           ( 32                        ),
    .P_DATA_WIDTH           ( 32                        ),

    // IFU接口配置参数
    .P_CMD_CUT_VALID_IFU    ( 1'b0                      ),
    .P_CMD_CUT_READY_IFU    ( 1'b1                      ),
    .P_CMD_BUF_DEEPTH_IFU   ( 1                         ),
    .P_RSP_CUT_VALID_IFU    ( 1'b1                      ),
    .P_RSP_CUT_READY_IFU    ( 1'b0                      ),
    .P_RSP_BUF_DEEPTH_IFU   ( 1                         ),
    .P_OTS_COUNT_IFU        ( 1                         ),
    .P_OTS_CTRL_ENABLE_IFU  ( 1'b0                      ),

    // EXU接口配置参数
    .P_CMD_CUT_VALID_EXU    ( 1'b0                      ),
    .P_CMD_CUT_READY_EXU    ( 1'b1                      ),
    .P_CMD_BUF_DEEPTH_EXU   ( 1                         ),
    .P_RSP_CUT_VALID_EXU    ( 1'b0                      ),
    .P_RSP_CUT_READY_EXU    ( 1'b1                      ),
    .P_RSP_BUF_DEEPTH_EXU   ( 1                         ),
    .P_OTS_COUNT_EXU        ( 1                         ),
    .P_OTS_CTRL_ENABLE_EXU  ( 1'b0                      ),

    // SLV接口配置参数
    .P_CMD_CUT_VALID_SLV    ( LP_CMD_CUT_VALID_SLV      ),
    .P_CMD_CUT_READY_SLV    ( LP_CMD_CUT_READY_SLV      ),
    .P_CMD_BUF_DEEPTH_SLV   ( LP_CMD_BUF_DEEPTH_SLV     ),
    .P_RSP_CUT_VALID_SLV    ( LP_RSP_CUT_VALID_SLV      ),
    .P_RSP_CUT_READY_SLV    ( LP_RSP_CUT_READY_SLV      ),
    .P_RSP_BUF_DEEPTH_SLV   ( LP_RSP_BUF_DEEPTH_SLV     ),
    .P_OTS_COUNT_SLV        ( 1                         ),
    .P_OTS_CTRL_ENABLE_SLV  ( LP_OTS_CTRL_ENABLE_SLV    ),

    // ILM接口配置参数
    .P_CMD_CUT_VALID_ILM    ( 1'b0                      ),
    .P_CMD_CUT_READY_ILM    ( 1'b0                      ),
    .P_CMD_BUF_DEEPTH_ILM   ( 0                         ),
    .P_RSP_CUT_VALID_ILM    ( 1'b0                      ),
    .P_RSP_CUT_READY_ILM    ( 1'b0                      ),
    .P_RSP_BUF_DEEPTH_ILM   ( 1'b0                      ),
    .P_OTS_COUNT_ILM        ( 1                         ),
    .P_OTS_CTRL_ENABLE_ILM  ( LP_OTS_CTRL_ENABLE_ILM    ),

    // DLM接口配置参数
    .P_CMD_CUT_VALID_DLM    ( LP_CMD_CUT_VALID_DLM      ),
    .P_CMD_CUT_READY_DLM    ( LP_CMD_CUT_READY_DLM      ),
    .P_CMD_BUF_DEEPTH_DLM   ( LP_CMD_BUF_DEEPTH_DLM     ),
    .P_RSP_CUT_VALID_DLM    ( LP_RSP_CUT_VALID_DLM      ),
    .P_RSP_CUT_READY_DLM    ( LP_RSP_CUT_READY_DLM      ),
    .P_RSP_BUF_DEEPTH_DLM   ( LP_RSP_BUF_DEEPTH_DLM     ),
    .P_OTS_COUNT_DLM        ( 1                         ),
    .P_OTS_CTRL_ENABLE_DLM  ( LP_OTS_CTRL_ENABLE_DLM    ),

    // SYS接口配置参数
    .P_CMD_CUT_VALID_SYS    ( LP_CMD_CUT_VALID_SYS      ),
    .P_CMD_CUT_READY_SYS    ( LP_CMD_CUT_READY_SYS      ),
    .P_CMD_BUF_DEEPTH_SYS   ( LP_CMD_BUF_DEEPTH_SYS     ),
    .P_RSP_CUT_VALID_SYS    ( LP_RSP_CUT_VALID_SYS      ),
    .P_RSP_CUT_READY_SYS    ( LP_RSP_CUT_READY_SYS      ),
    .P_RSP_BUF_DEEPTH_SYS   ( LP_RSP_BUF_DEEPTH_SYS     ),
    .P_OTS_COUNT_SYS        ( 1                         ),
    .P_OTS_CTRL_ENABLE_SYS  ( LP_OTS_CTRL_ENABLE_SYS    )
)
u_lnrv_biu
(
    .icb_cmd_vld_ifu        ( icb_cmd_vld_ifu           ),
    .icb_cmd_rdy_ifu        ( icb_cmd_rdy_ifu           ),
    .icb_cmd_write_ifu      ( icb_cmd_write_ifu         ),
    .icb_cmd_addr_ifu       ( icb_cmd_addr_ifu          ),
    .icb_cmd_wdata_ifu      ( icb_cmd_wdata_ifu         ),
    .icb_cmd_wstrb_ifu      ( icb_cmd_wstrb_ifu         ),
    .icb_cmd_size_ifu       ( icb_cmd_size_ifu          ),
    .icb_rsp_vld_ifu        ( icb_rsp_vld_ifu           ),
    .icb_rsp_rdy_ifu        ( icb_rsp_rdy_ifu           ),
    .icb_rsp_rdata_ifu      ( icb_rsp_rdata_ifu         ),
    .icb_rsp_err_ifu        ( icb_rsp_err_ifu           ),

    .icb_cmd_vld_exu        ( icb_cmd_vld_exu           ),
    .icb_cmd_rdy_exu        ( icb_cmd_rdy_exu           ),
    .icb_cmd_write_exu      ( icb_cmd_write_exu         ),
    .icb_cmd_addr_exu       ( icb_cmd_addr_exu          ),
    .icb_cmd_wdata_exu      ( icb_cmd_wdata_exu         ),
    .icb_cmd_wstrb_exu      ( icb_cmd_wstrb_exu         ),
    .icb_cmd_size_exu       ( icb_cmd_size_exu          ),
    .icb_rsp_vld_exu        ( icb_rsp_vld_exu           ),
    .icb_rsp_rdy_exu        ( icb_rsp_rdy_exu           ),
    .icb_rsp_rdata_exu      ( icb_rsp_rdata_exu         ),
    .icb_rsp_err_exu        ( icb_rsp_err_exu           ),

    .icb_cmd_vld_slv        ( icb_cmd_vld_slv           ),
    .icb_cmd_rdy_slv        ( icb_cmd_rdy_slv           ),
    .icb_cmd_write_slv      ( icb_cmd_write_slv         ),
    .icb_cmd_addr_slv       ( icb_cmd_addr_slv          ),
    .icb_cmd_wdata_slv      ( icb_cmd_wdata_slv         ),
    .icb_cmd_wstrb_slv      ( icb_cmd_wstrb_slv         ),
    .icb_cmd_size_slv       ( icb_cmd_size_slv          ),
    .icb_rsp_vld_slv        ( icb_rsp_vld_slv           ),
    .icb_rsp_rdy_slv        ( icb_rsp_rdy_slv           ),
    .icb_rsp_rdata_slv      ( icb_rsp_rdata_slv         ),
    .icb_rsp_err_slv        ( icb_rsp_err_slv           ),

    .icb_cmd_vld_ilm        ( icb_cmd_vld_ilm           ),
    .icb_cmd_rdy_ilm        ( icb_cmd_rdy_ilm           ),
    .icb_cmd_write_ilm      ( icb_cmd_write_ilm         ),
    .icb_cmd_addr_ilm       ( icb_cmd_addr_ilm          ),
    .icb_cmd_wdata_ilm      ( icb_cmd_wdata_ilm         ),
    .icb_cmd_wstrb_ilm      ( icb_cmd_wstrb_ilm         ),
    .icb_cmd_size_ilm       ( icb_cmd_size_ilm          ),
    .icb_rsp_vld_ilm        ( icb_rsp_vld_ilm           ),
    .icb_rsp_rdy_ilm        ( icb_rsp_rdy_ilm           ),
    .icb_rsp_rdata_ilm      ( icb_rsp_rdata_ilm         ),
    .icb_rsp_err_ilm        ( icb_rsp_err_ilm           ),

    .icb_cmd_vld_dlm        ( icb_cmd_vld_dlm           ),
    .icb_cmd_rdy_dlm        ( icb_cmd_rdy_dlm           ),
    .icb_cmd_write_dlm      ( icb_cmd_write_dlm         ),
    .icb_cmd_addr_dlm       ( icb_cmd_addr_dlm          ),
    .icb_cmd_wdata_dlm      ( icb_cmd_wdata_dlm         ),
    .icb_cmd_wstrb_dlm      ( icb_cmd_wstrb_dlm         ),
    .icb_cmd_size_dlm       ( icb_cmd_size_dlm          ),
    .icb_rsp_vld_dlm        ( icb_rsp_vld_dlm           ),
    .icb_rsp_rdy_dlm        ( icb_rsp_rdy_dlm           ),
    .icb_rsp_rdata_dlm      ( icb_rsp_rdata_dlm         ),
    .icb_rsp_err_dlm        ( icb_rsp_err_dlm           ),

    .icb_cmd_vld_sys        ( icb_cmd_vld_sys           ),
    .icb_cmd_rdy_sys        ( icb_cmd_rdy_sys           ),
    .icb_cmd_write_sys      ( icb_cmd_write_sys         ),
    .icb_cmd_addr_sys       ( icb_cmd_addr_sys          ),
    .icb_cmd_wdata_sys      ( icb_cmd_wdata_sys         ),
    .icb_cmd_wstrb_sys      ( icb_cmd_wstrb_sys         ),
    .icb_cmd_size_sys       ( icb_cmd_size_sys          ),
    .icb_rsp_vld_sys        ( icb_rsp_vld_sys           ),
    .icb_rsp_rdy_sys        ( icb_rsp_rdy_sys           ),
    .icb_rsp_rdata_sys      ( icb_rsp_rdata_sys         ),
    .icb_rsp_err_sys        ( icb_rsp_err_sys           ),

    .clk                    ( clk                       ),
    .reset_n                ( reset_n                   )
);

// ilm
lnrv_icb2sram#
(
    .P_ICB_ADDR_WIDTH       ( 32                        ),
    .P_RAM_ADDR_WIDTH       ( P_ILM_ADDR_WIDTH          ),
    .P_DATA_WIDTH           ( 32                        )
)
u_ilm_ctrl
(
    .clk                    ( clk                       ),
    .reset_n                ( reset_n                   ),

    .icb_cmd_vld            ( icb_cmd_vld_ilm           ),
    .icb_cmd_rdy            ( icb_cmd_rdy_ilm           ),
    .icb_cmd_write          ( icb_cmd_write_ilm         ),
    .icb_cmd_addr           ( icb_cmd_addr_ilm          ),
    .icb_cmd_wdata          ( icb_cmd_wdata_ilm         ),
    .icb_cmd_wstrb          ( icb_cmd_wstrb_ilm         ),
    .icb_cmd_size           ( icb_cmd_size_ilm          ),
    .icb_rsp_rdy            ( icb_rsp_rdy_ilm           ),
    .icb_rsp_vld            ( icb_rsp_vld_ilm           ),
    .icb_rsp_rdata          ( icb_rsp_rdata_ilm         ),
    .icb_rsp_err            ( icb_rsp_err_ilm           ),

    .ram_cs                 ( ilm_cs                    ),
    .ram_we                 ( ilm_we                    ),
    .ram_addr               ( ilm_addr                  ),
    .ram_wdata              ( ilm_wdata                 ),
    .ram_wem                ( ilm_wem                   ),
    .ram_rdata              ( ilm_rdata                 ),
    .ram_clk                (                           )
);

// dlm
lnrv_icb2sram#
(
    .P_ICB_ADDR_WIDTH       ( 32                        ),
    .P_RAM_ADDR_WIDTH       ( P_ILM_ADDR_WIDTH          ),
    .P_DATA_WIDTH           ( 32                        )
)
u_dlm_ctrl
(
    .clk                    ( clk                       ),
    .reset_n                ( reset_n                   ),

    .icb_cmd_vld            ( icb_cmd_vld_dlm           ),
    .icb_cmd_rdy            ( icb_cmd_rdy_dlm           ),
    .icb_cmd_write          ( icb_cmd_write_dlm         ),
    .icb_cmd_addr           ( icb_cmd_addr_dlm          ),
    .icb_cmd_wdata          ( icb_cmd_wdata_dlm         ),
    .icb_cmd_wstrb          ( icb_cmd_wstrb_dlm         ),
    .icb_cmd_size           ( icb_cmd_size_dlm          ),
    .icb_rsp_rdy            ( icb_rsp_rdy_dlm           ),
    .icb_rsp_vld            ( icb_rsp_vld_dlm           ),
    .icb_rsp_rdata          ( icb_rsp_rdata_dlm         ),
    .icb_rsp_err            ( icb_rsp_err_dlm           ),

    .ram_cs                 ( dlm_cs                    ),
    .ram_we                 ( dlm_we                    ),
    .ram_addr               ( dlm_addr                  ),
    .ram_wdata              ( dlm_wdata                 ),
    .ram_wem                ( dlm_wem                   ),
    .ram_rdata              ( dlm_rdata                 ),
    .ram_clk                (                           )
);


// // 系统总线，axi4
// lnrv_icb2axi#
// (
//     .P_ADDR_WIDTH           ( 32                        ),
//     .P_DATA_WIDTH           ( 32                        )
// )
// u_lnrv_icb2axi
// (
//     .icb_cmd_vld            ( icb_cmd_vld_sys           ),
//     .icb_cmd_rdy            ( icb_cmd_rdy_sys           ),
//     .icb_cmd_write          ( icb_cmd_write_sys         ),
//     .icb_cmd_addr           ( icb_cmd_addr_sys          ),
//     .icb_cmd_wdata          ( icb_cmd_wdata_sys         ),
//     .icb_cmd_wstrb          ( icb_cmd_wstrb_sys         ),
//     .icb_cmd_size           ( icb_cmd_size_sys          ),
//     .icb_rsp_rdy            ( icb_rsp_rdy_sys           ),
//     .icb_rsp_vld            ( icb_rsp_vld_sys           ),
//     .icb_rsp_err            ( icb_rsp_err_sys           ),
//     .icb_rsp_rdata          ( icb_rsp_rdata_sys         ),

//     .axi_awvalid            ( sys_awvalid               ),
//     .axi_awready            ( sys_awready               ),
//     .axi_awlock             ( sys_awlock                ),
//     .axi_awaddr             ( sys_awaddr                ),
//     .axi_awid               ( sys_awid                  ),
//     .axi_awlen              ( sys_awlen                 ),
//     .axi_awsize             ( sys_awsize                ),
//     .axi_awburst            ( sys_awburst               ),
//     .axi_awcache            ( sys_awcache               ),
//     .axi_awprot             ( sys_awprot                ),

//     .axi_wvalid             ( sys_wvalid                ),
//     .axi_wready             ( sys_wready                ),
//     .axi_wdata              ( sys_wdata                 ),
//     .axi_wstrb              ( sys_wstrb                 ),
//     .axi_wlast              ( sys_wlast                 ),

//     .axi_bready             ( sys_bready                ),
//     .axi_bvalid             ( sys_bvalid                ),
//     .axi_bresp              ( sys_bresp                 ),
//     .axi_bid                ( sys_bid                   ),

//     .axi_arvalid            ( sys_arvalid               ),
//     .axi_arready            ( sys_arready               ),
//     .axi_arlock             ( sys_arlock                ),
//     .axi_araddr             ( sys_araddr                ),
//     .axi_arid               ( sys_arid                  ),
//     .axi_arlen              ( sys_arlen                 ),
//     .axi_arsize             ( sys_arsize                ),
//     .axi_arburst            ( sys_arburst               ),
//     .axi_arcache            ( sys_arcache               ),
//     .axi_arprot             ( sys_arprot                ),

//     .axi_rready             ( sys_rready                ),
//     .axi_rvalid             ( sys_rvalid                ),
//     .axi_rdata              ( sys_rdata                 ),
//     .axi_rresp              ( sys_rresp                 ),
//     .axi_rlast              ( sys_rlast                 ),
//     .axi_rid                ( sys_rid                   ),

//     .clk                    ( clk                       ),
//     .reset_n                ( reset_n                   )
// );


lnrv_axi2icb#
(
    .P_ADDR_WIDTH           ( 32                        ),
    .P_DATA_WIDTH           ( 32                        )
)
u_lnrv_axi2icb
(
    .icb_cmd_vld            ( icb_cmd_vld_slv           ),
    .icb_cmd_rdy            ( icb_cmd_rdy_slv           ),
    .icb_cmd_write          ( icb_cmd_write_slv         ),
    .icb_cmd_addr           ( icb_cmd_addr_slv          ),
    .icb_cmd_wdata          ( icb_cmd_wdata_slv         ),
    .icb_cmd_wstrb          ( icb_cmd_wstrb_slv         ),
    .icb_cmd_size           ( icb_cmd_size_slv          ),
    .icb_rsp_rdy            ( icb_rsp_rdy_slv           ),
    .icb_rsp_vld            ( icb_rsp_vld_slv           ),
    .icb_rsp_err            ( icb_rsp_err_slv           ),
    .icb_rsp_rdata          ( icb_rsp_rdata_slv         ),

    .axi_awvalid            ( slv_awvalid               ),
    .axi_awready            ( slv_awready               ),
    .axi_awlock             ( slv_awlock                ),
    .axi_awaddr             ( slv_awaddr                ),
    .axi_awid               ( slv_awid                  ),
    .axi_awlen              ( slv_awlen                 ),
    .axi_awsize             ( slv_awsize                ),
    .axi_awburst            ( slv_awburst               ),
    .axi_awcache            ( slv_awcache               ),
    .axi_awprot             ( slv_awprot                ),

    .axi_wvalid             ( slv_wvalid                ),
    .axi_wready             ( slv_wready                ),
    .axi_wdata              ( slv_wdata                 ),
    .axi_wstrb              ( slv_wstrb                 ),
    .axi_wlast              ( slv_wlast                 ),

    .axi_bready             ( slv_bready                ),
    .axi_bvalid             ( slv_bvalid                ),
    .axi_bresp              ( slv_bresp                 ),
    .axi_bid                ( slv_bid                   ),

    .axi_arvalid            ( slv_arvalid               ),
    .axi_arready            ( slv_arready               ),
    .axi_arlock             ( slv_arlock                ),
    .axi_araddr             ( slv_araddr                ),
    .axi_arid               ( slv_arid                  ),
    .axi_arlen              ( slv_arlen                 ),
    .axi_arsize             ( slv_arsize                ),
    .axi_arburst            ( slv_arburst               ),
    .axi_arcache            ( slv_arcache               ),
    .axi_arprot             ( slv_arprot                ),

    .axi_rready             ( slv_rready                ),
    .axi_rvalid             ( slv_rvalid                ),
    .axi_rdata              ( slv_rdata                 ),
    .axi_rresp              ( slv_rresp                 ),
    .axi_rlast              ( slv_rlast                 ),
    .axi_rid                ( slv_rid                   ),

    .clk                    ( clk                       ),
    .reset_n                ( reset_n                   )
);


endmodule