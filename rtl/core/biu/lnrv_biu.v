module lnrv_biu#
(
    parameter                               P_ILM_REGION_START      = 32'h0000_0000,
    parameter                               P_ILM_REGION_END        = 32'h0002_0000,

    parameter                               P_DLM_REGION_START      = 32'h0002_0000,
    parameter                               P_DLM_REGION_END        = 32'h0004_0000,

    parameter                               P_ADDR_WIDTH            = 32,
    parameter                               P_DATA_WIDTH            = 32,

    // IFU接口配置参数
    parameter                               P_CMD_CUT_VALID_IFU     = 1'b1,
    parameter                               P_CMD_CUT_READY_IFU     = 1'b1,
    parameter                               P_CMD_BUF_DEEPTH_IFU    = 1,
    parameter                               P_RSP_CUT_VALID_IFU     = 1'b1,
    parameter                               P_RSP_CUT_READY_IFU     = 1'b1,
    parameter                               P_RSP_BUF_DEEPTH_IFU    = 1,
    parameter                               P_OTS_COUNT_IFU         = 1,
    parameter                               P_OTS_CTRL_ENABLE_IFU   = 0,

    // EXU接口配置参数
    parameter                               P_CMD_CUT_VALID_EXU     = 1'b1,
    parameter                               P_CMD_CUT_READY_EXU     = 1'b1,
    parameter                               P_CMD_BUF_DEEPTH_EXU    = 1,
    parameter                               P_RSP_CUT_VALID_EXU     = 1'b1,
    parameter                               P_RSP_CUT_READY_EXU     = 1'b1,
    parameter                               P_RSP_BUF_DEEPTH_EXU    = 1,
    parameter                               P_OTS_COUNT_EXU         = 1,
    parameter                               P_OTS_CTRL_ENABLE_EXU   = 0,

    // SLV接口配置参数
    parameter                               P_CMD_CUT_VALID_SLV     = 1'b1,
    parameter                               P_CMD_CUT_READY_SLV     = 1'b1,
    parameter                               P_CMD_BUF_DEEPTH_SLV    = 1,
    parameter                               P_RSP_CUT_VALID_SLV     = 1'b1,
    parameter                               P_RSP_CUT_READY_SLV     = 1'b1,
    parameter                               P_RSP_BUF_DEEPTH_SLV    = 1,
    parameter                               P_OTS_COUNT_SLV         = 1,
    parameter                               P_OTS_CTRL_ENABLE_SLV   = 0,

    // ILM接口配置参数
    parameter                               P_CMD_CUT_VALID_ILM     = 1'b1,
    parameter                               P_CMD_CUT_READY_ILM     = 1'b1,
    parameter                               P_CMD_BUF_DEEPTH_ILM    = 1,
    parameter                               P_RSP_CUT_VALID_ILM     = 1'b1,
    parameter                               P_RSP_CUT_READY_ILM     = 1'b1,
    parameter                               P_RSP_BUF_DEEPTH_ILM    = 1,
    parameter                               P_OTS_COUNT_ILM         = 1,
    parameter                               P_OTS_CTRL_ENABLE_ILM   = 0,

    // DLM接口配置参数
    parameter                               P_CMD_CUT_VALID_DLM     = 1'b1,
    parameter                               P_CMD_CUT_READY_DLM     = 1'b1,
    parameter                               P_CMD_BUF_DEEPTH_DLM    = 1,
    parameter                               P_RSP_CUT_VALID_DLM     = 1'b1,
    parameter                               P_RSP_CUT_READY_DLM     = 1'b1,
    parameter                               P_RSP_BUF_DEEPTH_DLM    = 1,
    parameter                               P_OTS_COUNT_DLM         = 1,
    parameter                               P_OTS_CTRL_ENABLE_DLM   = 0,

    // SYS接口配置参数
    parameter                               P_CMD_CUT_VALID_SYS     = 1'b1,
    parameter                               P_CMD_CUT_READY_SYS     = 1'b1,
    parameter                               P_CMD_BUF_DEEPTH_SYS    = 1,
    parameter                               P_RSP_CUT_VALID_SYS     = 1'b1,
    parameter                               P_RSP_CUT_READY_SYS     = 1'b1,
    parameter                               P_RSP_BUF_DEEPTH_SYS    = 1,
    parameter                               P_OTS_COUNT_SYS         = 1,
    parameter                               P_OTS_CTRL_ENABLE_SYS   = 0
)
(
    // 取指模块
    input                                   icb_cmd_vld_ifu,
    output                                  icb_cmd_rdy_ifu,
    input                                   icb_cmd_write_ifu,
    input[P_ADDR_WIDTH - 1 : 0]             icb_cmd_addr_ifu,
    input[P_DATA_WIDTH - 1 : 0]             icb_cmd_wdata_ifu,
    input[(P_DATA_WIDTH/8) - 1 : 0]         icb_cmd_wstrb_ifu,
    input[2 : 0]                            icb_cmd_size_ifu,
    output                                  icb_rsp_vld_ifu,
    input                                   icb_rsp_rdy_ifu,
    output[P_DATA_WIDTH - 1 : 0]            icb_rsp_rdata_ifu,
    output                                  icb_rsp_err_ifu,

    // exu模块
    input                                   icb_cmd_vld_exu,
    output                                  icb_cmd_rdy_exu,
    input                                   icb_cmd_write_exu,
    input[P_ADDR_WIDTH - 1 : 0]             icb_cmd_addr_exu,
    input[P_DATA_WIDTH - 1 : 0]             icb_cmd_wdata_exu,
    input[(P_DATA_WIDTH/8) - 1 : 0]         icb_cmd_wstrb_exu,
    input[2 : 0]                            icb_cmd_size_exu,
    output                                  icb_rsp_vld_exu,
    input                                   icb_rsp_rdy_exu,
    output[P_DATA_WIDTH - 1 : 0]            icb_rsp_rdata_exu,
    output                                  icb_rsp_err_exu,

    // slave访问接口
    input                                   icb_cmd_vld_slv,
    output                                  icb_cmd_rdy_slv,
    input                                   icb_cmd_write_slv,
    input[P_ADDR_WIDTH - 1 : 0]             icb_cmd_addr_slv,
    input[P_DATA_WIDTH - 1 : 0]             icb_cmd_wdata_slv,
    input[(P_DATA_WIDTH/8) - 1 : 0]         icb_cmd_wstrb_slv,
    input[2 : 0]                            icb_cmd_size_slv,
    output                                  icb_rsp_vld_slv,
    input                                   icb_rsp_rdy_slv,
    output[P_DATA_WIDTH - 1 : 0]            icb_rsp_rdata_slv,
    output                                  icb_rsp_err_slv,

    // 连接到ILM控制模块
    output                                  icb_cmd_vld_ilm,
    input                                   icb_cmd_rdy_ilm,
    output                                  icb_cmd_write_ilm,
    output[P_ADDR_WIDTH - 1 : 0]            icb_cmd_addr_ilm,
    output[P_DATA_WIDTH - 1 : 0]            icb_cmd_wdata_ilm,
    output[(P_DATA_WIDTH/8) - 1 : 0]        icb_cmd_wstrb_ilm,
    output[2 : 0]                           icb_cmd_size_ilm,
    input                                   icb_rsp_vld_ilm,
    output                                  icb_rsp_rdy_ilm,
    input[P_DATA_WIDTH - 1 : 0]             icb_rsp_rdata_ilm,
    input                                   icb_rsp_err_ilm,

    // 连接到DLM控制模块
    output                                  icb_cmd_vld_dlm,
    input                                   icb_cmd_rdy_dlm,
    output                                  icb_cmd_write_dlm,
    output[P_ADDR_WIDTH - 1 : 0]            icb_cmd_addr_dlm,
    output[P_DATA_WIDTH - 1 : 0]            icb_cmd_wdata_dlm,
    output[(P_DATA_WIDTH/8) - 1 : 0]        icb_cmd_wstrb_dlm,
    output[2 : 0]                           icb_cmd_size_dlm,
    input                                   icb_rsp_vld_dlm,
    output                                  icb_rsp_rdy_dlm,
    input[P_DATA_WIDTH - 1 : 0]             icb_rsp_rdata_dlm,
    input                                   icb_rsp_err_dlm,

    // 连接到系统总线
    output                                  icb_cmd_vld_sys,
    input                                   icb_cmd_rdy_sys,
    output                                  icb_cmd_write_sys,
    output[P_ADDR_WIDTH - 1 : 0]            icb_cmd_addr_sys,
    output[P_DATA_WIDTH - 1 : 0]            icb_cmd_wdata_sys,
    output[(P_DATA_WIDTH/8) - 1 : 0]        icb_cmd_wstrb_sys,
    output[2 : 0]                           icb_cmd_size_sys,
    input                                   icb_rsp_vld_sys,
    output                                  icb_rsp_rdy_sys,
    input[P_DATA_WIDTH - 1 : 0]             icb_rsp_rdata_sys,
    input                                   icb_rsp_err_sys,

    input                                   clk,
    input                                   reset_n
);

// ifu模块可以访问ILM/DLM和系统总线
localparam                                  LP_ICB_COUNT_IFU = 3;
localparam                                  LP_SN_ADDR_WIDTH_IFU = LP_ICB_COUNT_IFU * P_ADDR_WIDTH;
localparam                                  LP_SN_DATA_WIDTH_IFU = LP_ICB_COUNT_IFU * P_DATA_WIDTH;
localparam                                  LP_SN_SIZE_WIDTH_IFU = LP_ICB_COUNT_IFU * 3;
localparam                                  LP_SN_WSTRB_WIDTH_IFU = LP_ICB_COUNT_IFU * (P_DATA_WIDTH/8);

// exu模块可以访问ILM/DLM以及系统总线
localparam                                  LP_ICB_COUNT_EXU = 3;
localparam                                  LP_SN_ADDR_WIDTH_EXU = LP_ICB_COUNT_EXU * P_ADDR_WIDTH;
localparam                                  LP_SN_DATA_WIDTH_EXU = LP_ICB_COUNT_EXU * P_DATA_WIDTH;
localparam                                  LP_SN_SIZE_WIDTH_EXU = LP_ICB_COUNT_EXU * 3;
localparam                                  LP_SN_WSTRB_WIDTH_EXU = LP_ICB_COUNT_EXU * (P_DATA_WIDTH/8);

// slave接口提供外部访问内部ILM/DLM的能力
localparam                                  LP_ICB_COUNT_SLV = 2;
localparam                                  LP_SN_ADDR_WIDTH_SLV = LP_ICB_COUNT_SLV * P_ADDR_WIDTH;
localparam                                  LP_SN_DATA_WIDTH_SLV = LP_ICB_COUNT_SLV * P_DATA_WIDTH;
localparam                                  LP_SN_SIZE_WIDTH_SLV = LP_ICB_COUNT_SLV * 3;
localparam                                  LP_SN_WSTRB_WIDTH_SLV = LP_ICB_COUNT_SLV * (P_DATA_WIDTH/8);

// 有三个接口可能访问ILM
localparam                                  LP_ICB_COUNT_ILM = 3;
localparam                                  LP_MN_ADDR_WIDTH_ILM = LP_ICB_COUNT_ILM * P_ADDR_WIDTH;
localparam                                  LP_MN_DATA_WIDTH_ILM = LP_ICB_COUNT_ILM * P_DATA_WIDTH;
localparam                                  LP_MN_SIZE_WIDTH_ILM = LP_ICB_COUNT_ILM * 3;
localparam                                  LP_MN_WSTRB_WIDTH_ILM = LP_ICB_COUNT_ILM * (P_DATA_WIDTH/8);

// 有三个接口可能访问DLM
localparam                                  LP_ICB_COUNT_DLM = 3;
localparam                                  LP_MN_ADDR_WIDTH_DLM = LP_ICB_COUNT_DLM * P_ADDR_WIDTH;
localparam                                  LP_MN_DATA_WIDTH_DLM = LP_ICB_COUNT_DLM * P_DATA_WIDTH;
localparam                                  LP_MN_SIZE_WIDTH_DLM = LP_ICB_COUNT_DLM * 3;
localparam                                  LP_MN_WSTRB_WIDTH_DLM = LP_ICB_COUNT_DLM * (P_DATA_WIDTH/8);

// 有两个接口可以访问系统总线
localparam                                  LP_ICB_COUNT_SYS = 2;
localparam                                  LP_MN_ADDR_WIDTH_SYS = LP_ICB_COUNT_SYS * P_ADDR_WIDTH;
localparam                                  LP_MN_DATA_WIDTH_SYS = LP_ICB_COUNT_SYS * P_DATA_WIDTH;
localparam                                  LP_MN_SIZE_WIDTH_SYS = LP_ICB_COUNT_SYS * 3;
localparam                                  LP_MN_WSTRB_WIDTH_SYS = LP_ICB_COUNT_SYS * (P_DATA_WIDTH/8);

// 拆分ifu接口
wire[LP_ICB_COUNT_IFU - 1 : 0]              icb_cmd_vld_ifu_sn;
wire[LP_ICB_COUNT_IFU - 1 : 0]              icb_cmd_rdy_ifu_sn;
wire[LP_ICB_COUNT_IFU - 1 : 0]              icb_cmd_write_ifu_sn;
wire[LP_SN_ADDR_WIDTH_IFU - 1 : 0]          icb_cmd_addr_ifu_sn;
wire[LP_SN_DATA_WIDTH_IFU - 1 : 0]          icb_cmd_wdata_ifu_sn;
wire[LP_SN_WSTRB_WIDTH_IFU - 1 : 0]         icb_cmd_wstrb_ifu_sn;
wire[LP_SN_SIZE_WIDTH_IFU - 1 : 0]          icb_cmd_size_ifu_sn;
wire[LP_ICB_COUNT_IFU - 1 : 0]              icb_rsp_vld_ifu_sn;
wire[LP_ICB_COUNT_IFU - 1 : 0]              icb_rsp_rdy_ifu_sn;
wire[LP_SN_DATA_WIDTH_IFU - 1 : 0]          icb_rsp_rdata_ifu_sn;
wire[LP_ICB_COUNT_IFU - 1 : 0]              icb_rsp_err_ifu_sn;
wire[LP_SN_ADDR_WIDTH_IFU - 1 : 0]          ifu_sn_region_base;
wire[LP_SN_ADDR_WIDTH_IFU - 1 : 0]          ifu_sn_region_end;

// 拆分exu接口
wire[LP_ICB_COUNT_EXU - 1 : 0]              icb_cmd_vld_exu_sn;
wire[LP_ICB_COUNT_EXU - 1 : 0]              icb_cmd_rdy_exu_sn;
wire[LP_ICB_COUNT_EXU - 1 : 0]              icb_cmd_write_exu_sn;
wire[LP_SN_ADDR_WIDTH_EXU - 1 : 0]          icb_cmd_addr_exu_sn;
wire[LP_SN_DATA_WIDTH_EXU - 1 : 0]          icb_cmd_wdata_exu_sn;
wire[LP_SN_WSTRB_WIDTH_EXU - 1 : 0]         icb_cmd_wstrb_exu_sn;
wire[LP_SN_SIZE_WIDTH_EXU - 1 : 0]          icb_cmd_size_exu_sn;
wire[LP_ICB_COUNT_EXU - 1 : 0]              icb_rsp_vld_exu_sn;
wire[LP_ICB_COUNT_EXU - 1 : 0]              icb_rsp_rdy_exu_sn;
wire[LP_SN_DATA_WIDTH_EXU - 1 : 0]          icb_rsp_rdata_exu_sn;
wire[LP_ICB_COUNT_EXU - 1 : 0]              icb_rsp_err_exu_sn;
wire[LP_SN_ADDR_WIDTH_EXU - 1 : 0]          exu_sn_region_base;
wire[LP_SN_ADDR_WIDTH_EXU - 1 : 0]          exu_sn_region_end;

// 拆分slave接口
wire[LP_ICB_COUNT_SLV - 1 : 0]              icb_cmd_vld_slv_sn;
wire[LP_ICB_COUNT_SLV - 1 : 0]              icb_cmd_rdy_slv_sn;
wire[LP_ICB_COUNT_SLV - 1 : 0]              icb_cmd_write_slv_sn;
wire[LP_SN_ADDR_WIDTH_SLV - 1 : 0]          icb_cmd_addr_slv_sn;
wire[LP_SN_DATA_WIDTH_SLV - 1 : 0]          icb_cmd_wdata_slv_sn;
wire[LP_SN_WSTRB_WIDTH_SLV - 1 : 0]         icb_cmd_wstrb_slv_sn;
wire[LP_SN_SIZE_WIDTH_SLV - 1 : 0]          icb_cmd_size_slv_sn;
wire[LP_ICB_COUNT_SLV - 1 : 0]              icb_rsp_vld_slv_sn;
wire[LP_ICB_COUNT_SLV - 1 : 0]              icb_rsp_rdy_slv_sn;
wire[LP_SN_DATA_WIDTH_SLV - 1 : 0]          icb_rsp_rdata_slv_sn;
wire[LP_ICB_COUNT_SLV - 1 : 0]              icb_rsp_err_slv_sn;
wire[LP_SN_ADDR_WIDTH_SLV - 1 : 0]          slv_sn_region_base;
wire[LP_SN_ADDR_WIDTH_SLV - 1 : 0]          slv_sn_region_end;

// 合并去往ilm的访问
wire[LP_ICB_COUNT_ILM - 1 : 0]              icb_cmd_vld_ilm_mn;
wire[LP_ICB_COUNT_ILM - 1 : 0]              icb_cmd_rdy_ilm_mn;
wire[LP_ICB_COUNT_ILM - 1 : 0]              icb_cmd_write_ilm_mn;
wire[LP_MN_ADDR_WIDTH_ILM - 1 : 0]          icb_cmd_addr_ilm_mn;
wire[LP_MN_DATA_WIDTH_ILM - 1 : 0]          icb_cmd_wdata_ilm_mn;
wire[LP_MN_WSTRB_WIDTH_ILM - 1 : 0]         icb_cmd_wstrb_ilm_mn;
wire[LP_MN_SIZE_WIDTH_ILM - 1 : 0]          icb_cmd_size_ilm_mn;
wire[LP_ICB_COUNT_ILM - 1 : 0]              icb_rsp_rdy_ilm_mn;
wire[LP_ICB_COUNT_ILM - 1 : 0]              icb_rsp_vld_ilm_mn;
wire[LP_MN_DATA_WIDTH_ILM - 1 : 0]          icb_rsp_rdata_ilm_mn;
wire[LP_ICB_COUNT_ILM - 1 : 0]              icb_rsp_err_ilm_mn;

//合并去往dlm的访问
wire[LP_ICB_COUNT_DLM - 1 : 0]              icb_cmd_vld_dlm_mn;
wire[LP_ICB_COUNT_DLM - 1 : 0]              icb_cmd_rdy_dlm_mn;
wire[LP_ICB_COUNT_DLM - 1 : 0]              icb_cmd_write_dlm_mn;
wire[LP_MN_ADDR_WIDTH_DLM - 1 : 0]          icb_cmd_addr_dlm_mn;
wire[LP_MN_DATA_WIDTH_DLM - 1 : 0]          icb_cmd_wdata_dlm_mn;
wire[LP_MN_WSTRB_WIDTH_DLM - 1 : 0]         icb_cmd_wstrb_dlm_mn;
wire[LP_MN_SIZE_WIDTH_DLM - 1 : 0]          icb_cmd_size_dlm_mn;
wire[LP_ICB_COUNT_DLM - 1 : 0]              icb_rsp_rdy_dlm_mn;
wire[LP_ICB_COUNT_DLM - 1 : 0]              icb_rsp_vld_dlm_mn;
wire[LP_MN_DATA_WIDTH_DLM - 1 : 0]          icb_rsp_rdata_dlm_mn;
wire[LP_ICB_COUNT_DLM - 1 : 0]              icb_rsp_err_dlm_mn;

// 合并去往系统总线的访问
wire[LP_ICB_COUNT_SYS - 1 : 0]              icb_cmd_vld_sys_mn;
wire[LP_ICB_COUNT_SYS - 1 : 0]              icb_cmd_rdy_sys_mn;
wire[LP_ICB_COUNT_SYS - 1 : 0]              icb_cmd_write_sys_mn;
wire[LP_MN_ADDR_WIDTH_SYS - 1 : 0]          icb_cmd_addr_sys_mn;
wire[LP_MN_DATA_WIDTH_SYS - 1 : 0]          icb_cmd_wdata_sys_mn;
wire[LP_MN_WSTRB_WIDTH_SYS - 1 : 0]         icb_cmd_wstrb_sys_mn;
wire[LP_MN_SIZE_WIDTH_SYS - 1 : 0]          icb_cmd_size_sys_mn;
wire[LP_ICB_COUNT_SYS - 1 : 0]              icb_rsp_rdy_sys_mn;
wire[LP_ICB_COUNT_SYS - 1 : 0]              icb_rsp_vld_sys_mn;
wire[LP_MN_DATA_WIDTH_SYS - 1 : 0]          icb_rsp_rdata_sys_mn;
wire[LP_ICB_COUNT_SYS - 1 : 0]              icb_rsp_err_sys_mn;


wire                                        icb_cmd_vld_ifu_ilm;
wire                                        icb_cmd_rdy_ifu_ilm;
wire                                        icb_cmd_write_ifu_ilm;
wire[P_ADDR_WIDTH - 1 : 0]                  icb_cmd_addr_ifu_ilm;
wire[P_DATA_WIDTH - 1 : 0]                  icb_cmd_wdata_ifu_ilm;
wire[(P_DATA_WIDTH/8) - 1 : 0]              icb_cmd_wstrb_ifu_ilm;
wire[2 : 0]                                 icb_cmd_size_ifu_ilm;
wire                                        icb_rsp_vld_ifu_ilm;
wire                                        icb_rsp_rdy_ifu_ilm;
wire                                        icb_rsp_err_ifu_ilm;
wire[P_DATA_WIDTH - 1 : 0]                  icb_rsp_rdata_ifu_ilm;


wire                                        icb_cmd_vld_ifu_dlm;
wire                                        icb_cmd_rdy_ifu_dlm;
wire                                        icb_cmd_write_ifu_dlm;
wire[P_ADDR_WIDTH - 1 : 0]                  icb_cmd_addr_ifu_dlm;
wire[P_DATA_WIDTH - 1 : 0]                  icb_cmd_wdata_ifu_dlm;
wire[(P_DATA_WIDTH/8) - 1 : 0]              icb_cmd_wstrb_ifu_dlm;
wire[2 : 0]                                 icb_cmd_size_ifu_dlm;
wire                                        icb_rsp_vld_ifu_dlm;
wire                                        icb_rsp_rdy_ifu_dlm;
wire                                        icb_rsp_err_ifu_dlm;
wire[P_DATA_WIDTH - 1 : 0]                  icb_rsp_rdata_ifu_dlm;

wire                                        icb_cmd_vld_ifu_sys;
wire                                        icb_cmd_rdy_ifu_sys;
wire                                        icb_cmd_write_ifu_sys;
wire[P_ADDR_WIDTH - 1 : 0]                  icb_cmd_addr_ifu_sys;
wire[P_DATA_WIDTH - 1 : 0]                  icb_cmd_wdata_ifu_sys;
wire[(P_DATA_WIDTH/8) - 1 : 0]              icb_cmd_wstrb_ifu_sys;
wire[2 : 0]                                 icb_cmd_size_ifu_sys;
wire                                        icb_rsp_vld_ifu_sys;
wire                                        icb_rsp_rdy_ifu_sys;
wire                                        icb_rsp_err_ifu_sys;
wire[P_DATA_WIDTH - 1 : 0]                  icb_rsp_rdata_ifu_sys;


wire                                        icb_cmd_vld_exu_ilm;
wire                                        icb_cmd_rdy_exu_ilm;
wire                                        icb_cmd_write_exu_ilm;
wire[P_ADDR_WIDTH - 1 : 0]                  icb_cmd_addr_exu_ilm;
wire[P_DATA_WIDTH - 1 : 0]                  icb_cmd_wdata_exu_ilm;
wire[(P_DATA_WIDTH/8) - 1 : 0]              icb_cmd_wstrb_exu_ilm;
wire[2 : 0]                                 icb_cmd_size_exu_ilm;
wire                                        icb_rsp_vld_exu_ilm;
wire                                        icb_rsp_rdy_exu_ilm;
wire                                        icb_rsp_err_exu_ilm;
wire[P_DATA_WIDTH - 1 : 0]                  icb_rsp_rdata_exu_ilm;


wire                                        icb_cmd_vld_exu_dlm;
wire                                        icb_cmd_rdy_exu_dlm;
wire                                        icb_cmd_write_exu_dlm;
wire[P_ADDR_WIDTH - 1 : 0]                  icb_cmd_addr_exu_dlm;
wire[P_DATA_WIDTH - 1 : 0]                  icb_cmd_wdata_exu_dlm;
wire[(P_DATA_WIDTH/8) - 1 : 0]              icb_cmd_wstrb_exu_dlm;
wire[2 : 0]                                 icb_cmd_size_exu_dlm;
wire                                        icb_rsp_vld_exu_dlm;
wire                                        icb_rsp_rdy_exu_dlm;
wire                                        icb_rsp_err_exu_dlm;
wire[P_DATA_WIDTH - 1 : 0]                  icb_rsp_rdata_exu_dlm;

wire                                        icb_cmd_vld_exu_sys;
wire                                        icb_cmd_rdy_exu_sys;
wire                                        icb_cmd_write_exu_sys;
wire[P_ADDR_WIDTH - 1 : 0]                  icb_cmd_addr_exu_sys;
wire[P_DATA_WIDTH - 1 : 0]                  icb_cmd_wdata_exu_sys;
wire[(P_DATA_WIDTH/8) - 1 : 0]              icb_cmd_wstrb_exu_sys;
wire[2 : 0]                                 icb_cmd_size_exu_sys;
wire                                        icb_rsp_vld_exu_sys;
wire                                        icb_rsp_rdy_exu_sys;
wire                                        icb_rsp_err_exu_sys;
wire[P_DATA_WIDTH - 1 : 0]                  icb_rsp_rdata_exu_sys;


wire                                        icb_cmd_vld_slv_ilm;
wire                                        icb_cmd_rdy_slv_ilm;
wire                                        icb_cmd_write_slv_ilm;
wire[P_ADDR_WIDTH - 1 : 0]                  icb_cmd_addr_slv_ilm;
wire[P_DATA_WIDTH - 1 : 0]                  icb_cmd_wdata_slv_ilm;
wire[(P_DATA_WIDTH/8) - 1 : 0]              icb_cmd_wstrb_slv_ilm;
wire[2 : 0]                                 icb_cmd_size_slv_ilm;
wire                                        icb_rsp_vld_slv_ilm;
wire                                        icb_rsp_rdy_slv_ilm;
wire                                        icb_rsp_err_slv_ilm;
wire[P_DATA_WIDTH - 1 : 0]                  icb_rsp_rdata_slv_ilm;


wire                                        icb_cmd_vld_slv_dlm;
wire                                        icb_cmd_rdy_slv_dlm;
wire                                        icb_cmd_write_slv_dlm;
wire[P_ADDR_WIDTH - 1 : 0]                  icb_cmd_addr_slv_dlm;
wire[P_DATA_WIDTH - 1 : 0]                  icb_cmd_wdata_slv_dlm;
wire[(P_DATA_WIDTH/8) - 1 : 0]              icb_cmd_wstrb_slv_dlm;
wire[2 : 0]                                 icb_cmd_size_slv_dlm;
wire                                        icb_rsp_vld_slv_dlm;
wire                                        icb_rsp_rdy_slv_dlm;
wire                                        icb_rsp_err_slv_dlm;
wire[P_DATA_WIDTH - 1 : 0]                  icb_rsp_rdata_slv_dlm;


// 先拆分ifu/exu/slv接口，1 to n
// ifu可能会访问ilm、dlm以及sys总线
lnrv_icb_demux#
(
    .P_ADDR_WIDTH           ( P_ADDR_WIDTH              ),
    .P_DATA_WIDTH           ( P_DATA_WIDTH              ),
    .P_ICB_COUNT            ( LP_ICB_COUNT_IFU          ),

    .P_CMD_CUT_VALID        ( P_CMD_CUT_VALID_IFU       ),
    .P_CMD_CUT_READY        ( P_CMD_CUT_READY_IFU       ),
    .P_CMD_BUF_DEEPTH       ( P_CMD_BUF_DEEPTH_IFU      ),

    .P_RSP_CUT_VALID        ( P_RSP_CUT_VALID_IFU       ),
    .P_RSP_CUT_READY        ( P_RSP_CUT_READY_IFU       ),
    .P_RSP_BUF_DEEPTH       ( P_RSP_BUF_DEEPTH_IFU      ),

    .P_OTS_COUNT            ( P_OTS_COUNT_IFU           )
)
u_ifu_bus_demux
(
    .clk                    ( clk                       ),
    .reset_n                ( reset_n                   ),

    .icb_cmd_vld_m          ( icb_cmd_vld_ifu           ),
    .icb_cmd_rdy_m          ( icb_cmd_rdy_ifu           ),
    .icb_cmd_write_m        ( icb_cmd_write_ifu         ),
    .icb_cmd_addr_m         ( icb_cmd_addr_ifu          ),
    .icb_cmd_wdata_m        ( icb_cmd_wdata_ifu         ),
    .icb_cmd_wstrb_m        ( icb_cmd_wstrb_ifu         ),
    .icb_cmd_size_m         ( icb_cmd_size_ifu          ),
    .icb_rsp_rdy_m          ( icb_rsp_rdy_ifu           ),
    .icb_rsp_vld_m          ( icb_rsp_vld_ifu           ),
    .icb_rsp_rdata_m        ( icb_rsp_rdata_ifu         ),
    .icb_rsp_err_m          ( icb_rsp_err_ifu           ),

    .icb_cmd_vld_sn         ( icb_cmd_vld_ifu_sn        ),
    .icb_cmd_rdy_sn         ( icb_cmd_rdy_ifu_sn        ),
    .icb_cmd_write_sn       ( icb_cmd_write_ifu_sn      ),
    .icb_cmd_addr_sn        ( icb_cmd_addr_ifu_sn       ),
    .icb_cmd_wdata_sn       ( icb_cmd_wdata_ifu_sn      ),
    .icb_cmd_wstrb_sn       ( icb_cmd_wstrb_ifu_sn      ),
    .icb_cmd_size_sn        ( icb_cmd_size_ifu_sn       ),
    .icb_rsp_vld_sn         ( icb_rsp_vld_ifu_sn        ),
    .icb_rsp_rdy_sn         ( icb_rsp_rdy_ifu_sn        ),
    .icb_rsp_rdata_sn       ( icb_rsp_rdata_ifu_sn      ),
    .icb_rsp_err_sn         ( icb_rsp_err_ifu_sn        ),

    .sn_region_base         ( ifu_sn_region_base        ),
    .sn_region_end          ( ifu_sn_region_end         )
);


assign      {
                icb_cmd_vld_ifu_sys,
                icb_cmd_vld_ifu_ilm,
                icb_cmd_vld_ifu_dlm
            } = icb_cmd_vld_ifu_sn;

assign      icb_cmd_rdy_ifu_sn =    {
                                        icb_cmd_rdy_ifu_sys,
                                        icb_cmd_rdy_ifu_ilm,
                                        icb_cmd_rdy_ifu_dlm
                                    };

assign      {
                icb_cmd_write_ifu_sys,
                icb_cmd_write_ifu_ilm,
                icb_cmd_write_ifu_dlm
            } = icb_cmd_write_ifu_sn;

assign      {
                icb_cmd_addr_ifu_sys,
                icb_cmd_addr_ifu_ilm,
                icb_cmd_addr_ifu_dlm
            } = icb_cmd_addr_ifu_sn;

assign      {
                icb_cmd_wdata_ifu_sys,
                icb_cmd_wdata_ifu_ilm,
                icb_cmd_wdata_ifu_dlm
            } = icb_cmd_wdata_ifu_sn;

assign      {
                icb_cmd_wstrb_ifu_sys,
                icb_cmd_wstrb_ifu_ilm,
                icb_cmd_wstrb_ifu_dlm
            } = icb_cmd_wstrb_ifu_sn;

assign      {
                icb_cmd_size_ifu_sys,
                icb_cmd_size_ifu_ilm,
                icb_cmd_size_ifu_dlm
            } = icb_cmd_size_ifu_sn;

assign      icb_rsp_vld_ifu_sn =    {
                                        icb_rsp_vld_ifu_sys,
                                        icb_rsp_vld_ifu_ilm,
                                        icb_rsp_vld_ifu_dlm
                                    };

assign      {
                icb_rsp_rdy_ifu_sys,
                icb_rsp_rdy_ifu_ilm,
                icb_rsp_rdy_ifu_dlm
            } = icb_rsp_rdy_ifu_sn;

assign      icb_rsp_rdata_ifu_sn =  {
                                        icb_rsp_rdata_ifu_sys,
                                        icb_rsp_rdata_ifu_ilm,
                                        icb_rsp_rdata_ifu_dlm
                                    };

assign      icb_rsp_err_ifu_sn =    {
                                        icb_rsp_err_ifu_sys,
                                        icb_rsp_err_ifu_ilm,
                                        icb_rsp_err_ifu_dlm
                                    };

assign      ifu_sn_region_base =    {
                                        32'd0,
                                        P_ILM_REGION_START,
                                        P_DLM_REGION_START
                                    };

assign      ifu_sn_region_end = {
                                    32'd0,
                                    P_ILM_REGION_END,
                                    P_DLM_REGION_END
                                };


// exu可能访问ilm/dlm/sys
lnrv_icb_demux#
(
    .P_ADDR_WIDTH           ( P_ADDR_WIDTH              ),
    .P_DATA_WIDTH           ( P_DATA_WIDTH              ),
    .P_ICB_COUNT            ( LP_ICB_COUNT_EXU          ),

    .P_CMD_CUT_VALID        ( P_CMD_CUT_VALID_EXU       ),
    .P_CMD_CUT_READY        ( P_CMD_CUT_READY_EXU       ),
    .P_CMD_BUF_DEEPTH       ( P_CMD_BUF_DEEPTH_EXU      ),

    .P_RSP_CUT_VALID        ( P_RSP_CUT_VALID_EXU       ),
    .P_RSP_CUT_READY        ( P_RSP_CUT_READY_EXU       ),
    .P_RSP_BUF_DEEPTH       ( P_RSP_BUF_DEEPTH_EXU      ),

    .P_OTS_COUNT            ( P_OTS_COUNT_EXU           )
)
u_exu_bus_demux
(
    .clk                    ( clk                       ),
    .reset_n                ( reset_n                   ),

    .icb_cmd_vld_m          ( icb_cmd_vld_exu           ),
    .icb_cmd_rdy_m          ( icb_cmd_rdy_exu           ),
    .icb_cmd_write_m        ( icb_cmd_write_exu         ),
    .icb_cmd_addr_m         ( icb_cmd_addr_exu          ),
    .icb_cmd_wdata_m        ( icb_cmd_wdata_exu         ),
    .icb_cmd_wstrb_m        ( icb_cmd_wstrb_exu         ),
    .icb_cmd_size_m         ( icb_cmd_size_exu          ),
    .icb_rsp_rdy_m          ( icb_rsp_rdy_exu           ),
    .icb_rsp_vld_m          ( icb_rsp_vld_exu           ),
    .icb_rsp_rdata_m        ( icb_rsp_rdata_exu         ),
    .icb_rsp_err_m          ( icb_rsp_err_exu           ),

    .icb_cmd_vld_sn         ( icb_cmd_vld_exu_sn        ),
    .icb_cmd_rdy_sn         ( icb_cmd_rdy_exu_sn        ),
    .icb_cmd_write_sn       ( icb_cmd_write_exu_sn      ),
    .icb_cmd_addr_sn        ( icb_cmd_addr_exu_sn       ),
    .icb_cmd_wdata_sn       ( icb_cmd_wdata_exu_sn      ),
    .icb_cmd_wstrb_sn       ( icb_cmd_wstrb_exu_sn      ),
    .icb_cmd_size_sn        ( icb_cmd_size_exu_sn       ),
    .icb_rsp_vld_sn         ( icb_rsp_vld_exu_sn        ),
    .icb_rsp_rdy_sn         ( icb_rsp_rdy_exu_sn        ),
    .icb_rsp_rdata_sn       ( icb_rsp_rdata_exu_sn      ),
    .icb_rsp_err_sn         ( icb_rsp_err_exu_sn        ),

    .sn_region_base         ( exu_sn_region_base        ),
    .sn_region_end          ( exu_sn_region_end         )
);

assign      {
                icb_cmd_vld_exu_sys,
                icb_cmd_vld_exu_ilm,
                icb_cmd_vld_exu_dlm
            } = icb_cmd_vld_exu_sn;

assign      icb_cmd_rdy_exu_sn =    {
                                        icb_cmd_rdy_exu_sys,
                                        icb_cmd_rdy_exu_ilm,
                                        icb_cmd_rdy_exu_dlm
                                    };

assign      {
                icb_cmd_write_exu_sys,
                icb_cmd_write_exu_ilm,
                icb_cmd_write_exu_dlm
            } = icb_cmd_write_exu_sn;

assign      {
                icb_cmd_addr_exu_sys,
                icb_cmd_addr_exu_ilm,
                icb_cmd_addr_exu_dlm
            } = icb_cmd_addr_exu_sn;

assign      {
                icb_cmd_wdata_exu_sys,
                icb_cmd_wdata_exu_ilm,
                icb_cmd_wdata_exu_dlm
            } = icb_cmd_wdata_exu_sn;

assign      {
                icb_cmd_wstrb_exu_sys,
                icb_cmd_wstrb_exu_ilm,
                icb_cmd_wstrb_exu_dlm
            } = icb_cmd_wstrb_exu_sn;

assign      {
                icb_cmd_size_exu_sys,
                icb_cmd_size_exu_ilm,
                icb_cmd_size_exu_dlm
            } = icb_cmd_size_exu_sn;

assign      icb_rsp_vld_exu_sn =    {
                                        icb_rsp_vld_exu_sys,
                                        icb_rsp_vld_exu_ilm,
                                        icb_rsp_vld_exu_dlm
                                    };

assign      {
                icb_rsp_rdy_exu_sys,
                icb_rsp_rdy_exu_ilm,
                icb_rsp_rdy_exu_dlm
            } = icb_rsp_rdy_exu_sn;

assign      icb_rsp_rdata_exu_sn =  {
                                        icb_rsp_rdata_exu_sys,
                                        icb_rsp_rdata_exu_ilm,
                                        icb_rsp_rdata_exu_dlm
                                    };

assign      icb_rsp_err_exu_sn =    {
                                        icb_rsp_err_exu_sys,
                                        icb_rsp_err_exu_ilm,
                                        icb_rsp_err_exu_dlm
                                    };

assign      exu_sn_region_base =    {
                                        32'd0,
                                        P_ILM_REGION_START,
                                        P_DLM_REGION_START
                                    };

assign      exu_sn_region_end = {
                                    32'd0,
                                    P_ILM_REGION_END,
                                    P_DLM_REGION_END
                                };

// slave port只能访问ilm\dlm
lnrv_icb_demux#
(
    .P_ADDR_WIDTH           ( P_ADDR_WIDTH              ),
    .P_DATA_WIDTH           ( P_DATA_WIDTH              ),
    .P_ICB_COUNT            ( LP_ICB_COUNT_SLV          ),

    .P_CMD_CUT_VALID        ( P_CMD_CUT_VALID_SLV       ),
    .P_CMD_CUT_READY        ( P_CMD_CUT_READY_SLV       ),
    .P_CMD_BUF_DEEPTH       ( P_CMD_BUF_DEEPTH_SLV      ),

    .P_RSP_CUT_VALID        ( P_RSP_CUT_VALID_SLV       ),
    .P_RSP_CUT_READY        ( P_RSP_CUT_READY_SLV       ),
    .P_RSP_BUF_DEEPTH       ( P_RSP_BUF_DEEPTH_SLV      ),

    .P_OTS_COUNT            ( P_OTS_COUNT_SLV           )
)
u_slv_bus_demux
(
    .clk                    ( clk                       ),
    .reset_n                ( reset_n                   ),

    .icb_cmd_vld_m          ( icb_cmd_vld_slv           ),
    .icb_cmd_rdy_m          ( icb_cmd_rdy_slv           ),
    .icb_cmd_write_m        ( icb_cmd_write_slv         ),
    .icb_cmd_addr_m         ( icb_cmd_addr_slv          ),
    .icb_cmd_wdata_m        ( icb_cmd_wdata_slv         ),
    .icb_cmd_wstrb_m        ( icb_cmd_wstrb_slv         ),
    .icb_cmd_size_m         ( icb_cmd_size_slv          ),
    .icb_rsp_rdy_m          ( icb_rsp_rdy_slv           ),
    .icb_rsp_vld_m          ( icb_rsp_vld_slv           ),
    .icb_rsp_rdata_m        ( icb_rsp_rdata_slv         ),
    .icb_rsp_err_m          ( icb_rsp_err_slv           ),

    .icb_cmd_vld_sn         ( icb_cmd_vld_slv_sn        ),
    .icb_cmd_rdy_sn         ( icb_cmd_rdy_slv_sn        ),
    .icb_cmd_write_sn       ( icb_cmd_write_slv_sn      ),
    .icb_cmd_addr_sn        ( icb_cmd_addr_slv_sn       ),
    .icb_cmd_wdata_sn       ( icb_cmd_wdata_slv_sn      ),
    .icb_cmd_wstrb_sn       ( icb_cmd_wstrb_slv_sn      ),
    .icb_cmd_size_sn        ( icb_cmd_size_slv_sn       ),
    .icb_rsp_vld_sn         ( icb_rsp_vld_slv_sn        ),
    .icb_rsp_rdy_sn         ( icb_rsp_rdy_slv_sn        ),
    .icb_rsp_rdata_sn       ( icb_rsp_rdata_slv_sn      ),
    .icb_rsp_err_sn         ( icb_rsp_err_slv_sn        ),

    .sn_region_base         ( slv_sn_region_base        ),
    .sn_region_end          ( slv_sn_region_end         )
);

assign      {
                icb_cmd_vld_slv_ilm,
                icb_cmd_vld_slv_dlm
            } = icb_cmd_vld_slv_sn;

assign      icb_cmd_rdy_slv_sn =    {
                                        icb_cmd_rdy_slv_ilm,
                                        icb_cmd_rdy_slv_dlm
                                    };

assign      {
                icb_cmd_write_slv_ilm,
                icb_cmd_write_slv_dlm
            } = icb_cmd_write_slv_sn;

assign      {
                icb_cmd_addr_slv_ilm,
                icb_cmd_addr_slv_dlm
            } = icb_cmd_addr_slv_sn;

assign      {
                icb_cmd_wdata_slv_ilm,
                icb_cmd_wdata_slv_dlm
            } = icb_cmd_wdata_slv_sn;

assign      {
                icb_cmd_wstrb_slv_ilm,
                icb_cmd_wstrb_slv_dlm
            } = icb_cmd_wstrb_slv_sn;

assign      {
                icb_cmd_size_slv_ilm,
                icb_cmd_size_slv_dlm
            } = icb_cmd_size_slv_sn;

assign      icb_rsp_vld_slv_sn =    {
                                        icb_rsp_vld_slv_ilm,
                                        icb_rsp_vld_slv_dlm
                                    };

assign      {
                icb_rsp_rdy_slv_ilm,
                icb_rsp_rdy_slv_dlm
            } = icb_rsp_rdy_slv_sn;

assign      icb_rsp_rdata_slv_sn =  {
                                        icb_rsp_rdata_slv_ilm,
                                        icb_rsp_rdata_slv_dlm
                                    };

assign      icb_rsp_err_slv_sn =    {
                                        icb_rsp_err_slv_ilm,
                                        icb_rsp_err_slv_dlm
                                    };

assign      slv_sn_region_base =    {
                                        P_ILM_REGION_START,
                                        P_DLM_REGION_START
                                    };

assign      slv_sn_region_end = {
                                    P_ILM_REGION_END,
                                    P_DLM_REGION_END
                                };

// 再合并总线
assign      icb_cmd_vld_ilm_mn =    {
                                        icb_cmd_vld_slv_ilm,
                                        icb_cmd_vld_ifu_ilm,
                                        icb_cmd_vld_exu_ilm
                                    };

assign      {
                icb_cmd_rdy_slv_ilm,
                icb_cmd_rdy_ifu_ilm,
                icb_cmd_rdy_exu_ilm
            } = icb_cmd_rdy_ilm_mn;

assign      icb_cmd_write_ilm_mn =  {
                                        icb_cmd_write_slv_ilm,
                                        icb_cmd_write_ifu_ilm,
                                        icb_cmd_write_exu_ilm
                                    };

assign      icb_cmd_addr_ilm_mn =   {
                                        icb_cmd_addr_slv_ilm,
                                        icb_cmd_addr_ifu_ilm,
                                        icb_cmd_addr_exu_ilm
                                    };

assign      icb_cmd_wdata_ilm_mn =  {
                                        icb_cmd_wdata_slv_ilm,
                                        icb_cmd_wdata_ifu_ilm,
                                        icb_cmd_wdata_exu_ilm
                                    };

assign      icb_cmd_wstrb_ilm_mn =  {
                                        icb_cmd_wstrb_slv_ilm,
                                        icb_cmd_wstrb_ifu_ilm,
                                        icb_cmd_wstrb_exu_ilm
                                    };

assign      icb_cmd_size_ilm_mn =   {
                                        icb_cmd_size_slv_ilm,
                                        icb_cmd_size_ifu_ilm,
                                        icb_cmd_size_exu_ilm
                                    };

assign      {
                icb_rsp_vld_slv_ilm,
                icb_rsp_vld_ifu_ilm,
                icb_rsp_vld_exu_ilm
            } = icb_rsp_vld_ilm_mn;

assign      icb_rsp_rdy_ilm_mn =    {
                                        icb_rsp_rdy_slv_ilm,
                                        icb_rsp_rdy_ifu_ilm,
                                        icb_rsp_rdy_exu_ilm
                                    };

assign      {
                icb_rsp_rdata_slv_ilm,
                icb_rsp_rdata_ifu_ilm,
                icb_rsp_rdata_exu_ilm
            } = icb_rsp_rdata_ilm_mn;

assign      {
                icb_rsp_err_slv_ilm,
                icb_rsp_err_ifu_ilm,
                icb_rsp_err_exu_ilm
            } = icb_rsp_err_ilm_mn;

// ifu\lsu\slv都有可能访问ilm
lnrv_icb_mux#
(
    .P_ADDR_WIDTH           ( P_ADDR_WIDTH              ),
    .P_DATA_WIDTH           ( P_DATA_WIDTH              ),
    .P_ICB_COUNT            ( LP_ICB_COUNT_ILM          ),

    .P_CMD_CUT_VALID        ( P_CMD_CUT_VALID_ILM       ),
    .P_CMD_CUT_READY        ( P_CMD_CUT_READY_ILM       ),
    .P_CMD_BUF_DEEPTH       ( P_CMD_BUF_DEEPTH_ILM      ),

    .P_RSP_CUT_VALID        ( P_RSP_CUT_VALID_ILM       ),
    .P_RSP_CUT_READY        ( P_RSP_CUT_READY_ILM       ),
    .P_RSP_BUF_DEEPTH       ( P_RSP_BUF_DEEPTH_ILM      ),

    .P_OTS_COUNT            ( P_OTS_COUNT_ILM           )
)
u_ilm_bus_mux
(
    .clk                    ( clk                       ),
    .reset_n                ( reset_n                   ),

    .icb_cmd_vld_mn         ( icb_cmd_vld_ilm_mn        ),
    .icb_cmd_rdy_mn         ( icb_cmd_rdy_ilm_mn        ),
    .icb_cmd_write_mn       ( icb_cmd_write_ilm_mn      ),
    .icb_cmd_addr_mn        ( icb_cmd_addr_ilm_mn       ),
    .icb_cmd_wdata_mn       ( icb_cmd_wdata_ilm_mn      ),
    .icb_cmd_wstrb_mn       ( icb_cmd_wstrb_ilm_mn      ),
    .icb_cmd_size_mn        ( icb_cmd_size_ilm_mn       ),
    .icb_rsp_rdy_mn         ( icb_rsp_rdy_ilm_mn        ),
    .icb_rsp_vld_mn         ( icb_rsp_vld_ilm_mn        ),
    .icb_rsp_rdata_mn       ( icb_rsp_rdata_ilm_mn      ),
    .icb_rsp_err_mn         ( icb_rsp_err_ilm_mn        ),

    .icb_cmd_vld_s          ( icb_cmd_vld_ilm           ),
    .icb_cmd_rdy_s          ( icb_cmd_rdy_ilm           ),
    .icb_cmd_write_s        ( icb_cmd_write_ilm         ),
    .icb_cmd_addr_s         ( icb_cmd_addr_ilm          ),
    .icb_cmd_wdata_s        ( icb_cmd_wdata_ilm         ),
    .icb_cmd_wstrb_s        ( icb_cmd_wstrb_ilm         ),
    .icb_cmd_size_s         ( icb_cmd_size_ilm          ),
    .icb_rsp_vld_s          ( icb_rsp_vld_ilm           ),
    .icb_rsp_rdy_s          ( icb_rsp_rdy_ilm           ),
    .icb_rsp_rdata_s        ( icb_rsp_rdata_ilm         ),
    .icb_rsp_err_s          ( icb_rsp_err_ilm           )
);

// 合并访问DLM的总线
assign      icb_cmd_vld_dlm_mn =    {
                                        icb_cmd_vld_slv_dlm,
                                        icb_cmd_vld_ifu_dlm,
                                        icb_cmd_vld_exu_dlm
                                    };

assign      {
                icb_cmd_rdy_slv_dlm,
                icb_cmd_rdy_ifu_dlm,
                icb_cmd_rdy_exu_dlm
            } = icb_cmd_rdy_dlm_mn;

assign      icb_cmd_write_dlm_mn =  {
                                        icb_cmd_write_slv_dlm,
                                        icb_cmd_write_ifu_dlm,
                                        icb_cmd_write_exu_dlm
                                    };

assign      icb_cmd_addr_dlm_mn =   {
                                        icb_cmd_addr_slv_dlm,
                                        icb_cmd_addr_ifu_dlm,
                                        icb_cmd_addr_exu_dlm
                                    };

assign      icb_cmd_wdata_dlm_mn =  {
                                        icb_cmd_wdata_slv_dlm,
                                        icb_cmd_wdata_ifu_dlm,
                                        icb_cmd_wdata_exu_dlm
                                    };

assign      icb_cmd_wstrb_dlm_mn =  {
                                        icb_cmd_wstrb_slv_dlm,
                                        icb_cmd_wstrb_ifu_dlm,
                                        icb_cmd_wstrb_exu_dlm
                                    };
assign      icb_cmd_size_dlm_mn =   {
                                        icb_cmd_size_slv_dlm,
                                        icb_cmd_size_ifu_dlm,
                                        icb_cmd_size_exu_dlm
                                    };

assign      {
                icb_rsp_vld_slv_dlm,
                icb_rsp_vld_ifu_dlm,
                icb_rsp_vld_exu_dlm
            } = icb_rsp_vld_dlm_mn;

assign      icb_rsp_rdy_dlm_mn =    {
                                        icb_rsp_rdy_slv_dlm,
                                        icb_rsp_rdy_ifu_dlm,
                                        icb_rsp_rdy_exu_dlm
                                    };

assign      {
                icb_rsp_rdata_slv_dlm,
                icb_rsp_rdata_ifu_dlm,
                icb_rsp_rdata_exu_dlm
            } = icb_rsp_rdata_dlm_mn;

assign      {
                icb_rsp_err_slv_dlm,
                icb_rsp_err_ifu_dlm,
                icb_rsp_err_exu_dlm
            } = icb_rsp_err_dlm_mn;

// slv\ifu\lsu都有可能访问dlm
lnrv_icb_mux#
(
    .P_ADDR_WIDTH           ( P_ADDR_WIDTH              ),
    .P_DATA_WIDTH           ( P_DATA_WIDTH              ),
    .P_ICB_COUNT            ( LP_ICB_COUNT_DLM          ),

    .P_CMD_CUT_VALID        ( P_CMD_CUT_VALID_DLM       ),
    .P_CMD_CUT_READY        ( P_CMD_CUT_READY_DLM       ),
    .P_CMD_BUF_DEEPTH       ( P_CMD_BUF_DEEPTH_DLM      ),

    .P_RSP_CUT_VALID        ( P_RSP_CUT_VALID_DLM       ),
    .P_RSP_CUT_READY        ( P_RSP_CUT_READY_DLM       ),
    .P_RSP_BUF_DEEPTH       ( P_RSP_BUF_DEEPTH_DLM      ),

    .P_OTS_COUNT            ( P_OTS_COUNT_DLM           )
)
u_dlm_bus_mux
(
    .clk                    ( clk                       ),
    .reset_n                ( reset_n                   ),

    .icb_cmd_vld_mn         ( icb_cmd_vld_dlm_mn        ),
    .icb_cmd_rdy_mn         ( icb_cmd_rdy_dlm_mn        ),
    .icb_cmd_write_mn       ( icb_cmd_write_dlm_mn      ),
    .icb_cmd_addr_mn        ( icb_cmd_addr_dlm_mn       ),
    .icb_cmd_wdata_mn       ( icb_cmd_wdata_dlm_mn      ),
    .icb_cmd_wstrb_mn       ( icb_cmd_wstrb_dlm_mn      ),
    .icb_cmd_size_mn        ( icb_cmd_size_dlm_mn       ),
    .icb_rsp_rdy_mn         ( icb_rsp_rdy_dlm_mn        ),
    .icb_rsp_vld_mn         ( icb_rsp_vld_dlm_mn        ),
    .icb_rsp_rdata_mn       ( icb_rsp_rdata_dlm_mn      ),
    .icb_rsp_err_mn         ( icb_rsp_err_dlm_mn        ),

    .icb_cmd_vld_s          ( icb_cmd_vld_dlm           ),
    .icb_cmd_rdy_s          ( icb_cmd_rdy_dlm           ),
    .icb_cmd_write_s        ( icb_cmd_write_dlm         ),
    .icb_cmd_addr_s         ( icb_cmd_addr_dlm          ),
    .icb_cmd_wdata_s        ( icb_cmd_wdata_dlm         ),
    .icb_cmd_wstrb_s        ( icb_cmd_wstrb_dlm         ),
    .icb_cmd_size_s         ( icb_cmd_size_dlm          ),
    .icb_rsp_vld_s          ( icb_rsp_vld_dlm           ),
    .icb_rsp_rdy_s          ( icb_rsp_rdy_dlm           ),
    .icb_rsp_rdata_s        ( icb_rsp_rdata_dlm         ),
    .icb_rsp_err_s          ( icb_rsp_err_dlm           )
);

assign      icb_cmd_vld_sys_mn =    {
                                        icb_cmd_vld_ifu_sys,
                                        icb_cmd_vld_exu_sys
                                    };

assign      {
                icb_cmd_rdy_ifu_sys,
                icb_cmd_rdy_exu_sys
            } = icb_cmd_rdy_sys_mn;

assign      icb_cmd_write_sys_mn =  {
                                        icb_cmd_write_ifu_sys,
                                        icb_cmd_write_exu_sys
                                    };

assign      icb_cmd_addr_sys_mn =   {
                                        icb_cmd_addr_ifu_sys,
                                        icb_cmd_addr_exu_sys
                                    };

assign      icb_cmd_wdata_sys_mn =  {
                                        icb_cmd_wdata_ifu_sys,
                                        icb_cmd_wdata_exu_sys
                                    };

assign      icb_cmd_wstrb_sys_mn =  {
                                        icb_cmd_wstrb_ifu_sys,
                                        icb_cmd_wstrb_exu_sys
                                    };

assign      icb_cmd_size_sys_mn =   {
                                        icb_cmd_size_ifu_sys,
                                        icb_cmd_size_exu_sys
                                    };

assign      {
                icb_rsp_vld_ifu_sys,
                icb_rsp_vld_exu_sys
            } = icb_rsp_vld_sys_mn;

assign      icb_rsp_rdy_sys_mn =    {
                                        icb_rsp_rdy_ifu_sys,
                                        icb_rsp_rdy_exu_sys
                                    };

assign      {
                icb_rsp_rdata_ifu_sys,
                icb_rsp_rdata_exu_sys
            } = icb_rsp_rdata_sys_mn;

assign      {
                icb_rsp_err_ifu_sys,
                icb_rsp_err_exu_sys
            } = icb_rsp_err_sys_mn;

// ifu\lsu可能访问系统总线
lnrv_icb_mux#
(
    .P_ADDR_WIDTH           ( P_ADDR_WIDTH              ),
    .P_DATA_WIDTH           ( P_DATA_WIDTH              ),
    .P_ICB_COUNT            ( LP_ICB_COUNT_SYS          ),

    .P_CMD_CUT_VALID        ( P_CMD_CUT_VALID_SYS       ),
    .P_CMD_CUT_READY        ( P_CMD_CUT_READY_SYS       ),
    .P_CMD_BUF_DEEPTH       ( P_CMD_BUF_DEEPTH_SYS      ),

    .P_RSP_CUT_VALID        ( P_RSP_CUT_VALID_SYS       ),
    .P_RSP_CUT_READY        ( P_RSP_CUT_READY_SYS       ),
    .P_RSP_BUF_DEEPTH       ( P_RSP_BUF_DEEPTH_SYS      ),

    .P_OTS_COUNT            ( P_OTS_COUNT_SYS           )
)
u_sys_bus_mux
(
    .clk                    ( clk                       ),
    .reset_n                ( reset_n                   ),

    .icb_cmd_vld_mn         ( icb_cmd_vld_sys_mn        ),
    .icb_cmd_rdy_mn         ( icb_cmd_rdy_sys_mn        ),
    .icb_cmd_write_mn       ( icb_cmd_write_sys_mn      ),
    .icb_cmd_addr_mn        ( icb_cmd_addr_sys_mn       ),
    .icb_cmd_wdata_mn       ( icb_cmd_wdata_sys_mn      ),
    .icb_cmd_wstrb_mn       ( icb_cmd_wstrb_sys_mn      ),
    .icb_cmd_size_mn        ( icb_cmd_size_sys_mn       ),
    .icb_rsp_rdy_mn         ( icb_rsp_rdy_sys_mn        ),
    .icb_rsp_vld_mn         ( icb_rsp_vld_sys_mn        ),
    .icb_rsp_rdata_mn       ( icb_rsp_rdata_sys_mn      ),
    .icb_rsp_err_mn         ( icb_rsp_err_sys_mn        ),

    .icb_cmd_vld_s          ( icb_cmd_vld_sys           ),
    .icb_cmd_rdy_s          ( icb_cmd_rdy_sys           ),
    .icb_cmd_write_s        ( icb_cmd_write_sys         ),
    .icb_cmd_addr_s         ( icb_cmd_addr_sys          ),
    .icb_cmd_wdata_s        ( icb_cmd_wdata_sys         ),
    .icb_cmd_wstrb_s        ( icb_cmd_wstrb_sys         ),
    .icb_cmd_size_s         ( icb_cmd_size_sys          ),
    .icb_rsp_vld_s          ( icb_rsp_vld_sys           ),
    .icb_rsp_rdy_s          ( icb_rsp_rdy_sys           ),
    .icb_rsp_rdata_s        ( icb_rsp_rdata_sys         ),
    .icb_rsp_err_s          ( icb_rsp_err_sys           )
);

endmodule