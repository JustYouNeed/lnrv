module lnrv_biu#
(
    parameter                               P_ILM_REGION_START = 32'h0000_0000,
    parameter                               P_ILM_REGION_END = 32'h0002_0000,

    parameter                               P_DLM_REGION_START = 32'h0002_0000,
    parameter                               P_DLM_REGION_END = 32'h0004_0000,

    parameter                               P_ADDR_WIDTH = 32,
    parameter                               P_DATA_WIDTH = 32
)
(
    input                                   ifu_cmd_vld,
    output                                  ifu_cmd_rdy,
    input                                   ifu_cmd_write,
    input[P_ADDR_WIDTH - 1 : 0]             ifu_cmd_addr,
    input[P_DATA_WIDTH - 1 : 0]             ifu_cmd_wdata,
    input[(P_DATA_WIDTH/8) - 1 : 0]         ifu_cmd_wstrb,
    output                                  ifu_rsp_vld,
    input                                   ifu_rsp_rdy,
    output[P_DATA_WIDTH - 1 : 0]            ifu_rsp_rdata,
    output                                  ifu_rsp_err,

    input                                   exu_cmd_vld,
    output                                  exu_cmd_rdy,
    input                                   exu_cmd_write,
    input[P_ADDR_WIDTH - 1 : 0]             exu_cmd_addr,
    input[P_DATA_WIDTH - 1 : 0]             exu_cmd_wdata,
    input[(P_DATA_WIDTH/8) - 1 : 0]         exu_cmd_wstrb,
    output                                  exu_rsp_vld,
    input                                   exu_rsp_rdy,
    output[P_DATA_WIDTH - 1 : 0]            exu_rsp_rdata,
    output                                  exu_rsp_err,

    input                                   slv_cmd_vld,
    output                                  slv_cmd_rdy,
    input                                   slv_cmd_write,
    input[P_ADDR_WIDTH - 1 : 0]             slv_cmd_addr,
    input[P_DATA_WIDTH - 1 : 0]             slv_cmd_wdata,
    input[(P_DATA_WIDTH/8) - 1 : 0]         slv_cmd_wstrb,
    output                                  slv_rsp_vld,
    input                                   slv_rsp_rdy,
    output[P_DATA_WIDTH - 1 : 0]            slv_rsp_rdata,
    output                                  slv_rsp_err,

    
    output                                  ilm_cmd_vld,
    input                                   ilm_cmd_rdy,
    output                                  ilm_cmd_write,
    output[P_ADDR_WIDTH - 1 : 0]            ilm_cmd_addr,
    output[P_DATA_WIDTH - 1 : 0]            ilm_cmd_wdata,
    output[(P_DATA_WIDTH/8) - 1 : 0]        ilm_cmd_wstrb,
    input                                   ilm_rsp_vld,
    output                                  ilm_rsp_rdy,
    input[P_DATA_WIDTH - 1 : 0]             ilm_rsp_rdata,
    input                                   ilm_rsp_err,

    output                                  dlm_cmd_vld,
    input                                   dlm_cmd_rdy,
    output                                  dlm_cmd_write,
    output[P_ADDR_WIDTH - 1 : 0]            dlm_cmd_addr,
    output[P_DATA_WIDTH - 1 : 0]            dlm_cmd_wdata,
    output[(P_DATA_WIDTH/8) - 1 : 0]        dlm_cmd_wstrb,
    input                                   dlm_rsp_vld,
    output                                  dlm_rsp_rdy,
    input[P_DATA_WIDTH - 1 : 0]             dlm_rsp_rdata,
    input                                   dlm_rsp_err,

    output                                  sys_cmd_vld,
    input                                   sys_cmd_rdy,
    output                                  sys_cmd_write,
    output[P_ADDR_WIDTH - 1 : 0]            sys_cmd_addr,
    output[P_DATA_WIDTH - 1 : 0]            sys_cmd_wdata,
    output[(P_DATA_WIDTH/8) - 1 : 0]        sys_cmd_wstrb,
    input                                   sys_rsp_vld,
    output                                  sys_rsp_rdy,
    input[P_DATA_WIDTH - 1 : 0]             sys_rsp_rdata,
    input                                   sys_rsp_err,

    input                                   clk,
    input                                   reset_n
);

localparam                                  LP_IFU_ICB_COUNT = 3;
localparam                                  LP_IFU_SN_ADDR_WIDTH = LP_IFU_ICB_COUNT * P_ADDR_WIDTH;
localparam                                  LP_IFU_SN_DATA_WIDTH = LP_IFU_ICB_COUNT * P_DATA_WIDTH;
localparam                                  LP_IFU_SN_WSTRB_WIDTH = LP_IFU_ICB_COUNT * (P_DATA_WIDTH/8);

localparam                                  LP_EXU_ICB_COUNT = 3;
localparam                                  LP_EXU_SN_ADDR_WIDTH = LP_EXU_ICB_COUNT * P_ADDR_WIDTH;
localparam                                  LP_EXU_SN_DATA_WIDTH = LP_EXU_ICB_COUNT * P_DATA_WIDTH;
localparam                                  LP_EXU_SN_WSTRB_WIDTH = LP_EXU_ICB_COUNT * (P_DATA_WIDTH/8);


localparam                                  LP_SLV_ICB_COUNT = 2;
localparam                                  LP_SLV_SN_ADDR_WIDTH = LP_SLV_ICB_COUNT * P_ADDR_WIDTH;
localparam                                  LP_SLV_SN_DATA_WIDTH = LP_SLV_ICB_COUNT * P_DATA_WIDTH;
localparam                                  LP_SLV_SN_WSTRB_WIDTH = LP_SLV_ICB_COUNT * (P_DATA_WIDTH/8);


localparam                                  LP_ILM_ICB_COUNT = 3;
localparam                                  LP_ILM_MN_ADDR_WIDTH = LP_ILM_ICB_COUNT * P_ADDR_WIDTH;
localparam                                  LP_ILM_MN_DATA_WIDTH = LP_ILM_ICB_COUNT * P_DATA_WIDTH;
localparam                                  LP_ILM_MN_WSTRB_WIDTH = LP_ILM_ICB_COUNT * (P_DATA_WIDTH/8);

localparam                                  LP_DLM_ICB_COUNT = 3;
localparam                                  LP_DLM_MN_ADDR_WIDTH = LP_DLM_ICB_COUNT * P_ADDR_WIDTH;
localparam                                  LP_DLM_MN_DATA_WIDTH = LP_DLM_ICB_COUNT * P_DATA_WIDTH;
localparam                                  LP_DLM_MN_WSTRB_WIDTH = LP_DLM_ICB_COUNT * (P_DATA_WIDTH/8);


localparam                                  LP_SYS_ICB_COUNT = 2;
localparam                                  LP_SYS_MN_ADDR_WIDTH = LP_SYS_ICB_COUNT * P_ADDR_WIDTH;
localparam                                  LP_SYS_MN_DATA_WIDTH = LP_SYS_ICB_COUNT * P_DATA_WIDTH;
localparam                                  LP_SYS_MN_WSTRB_WIDTH = LP_SYS_ICB_COUNT * (P_DATA_WIDTH/8);



wire[LP_IFU_ICB_COUNT - 1 : 0]              ifu_sn_icb_cmd_vld;
wire[LP_IFU_ICB_COUNT - 1 : 0]              ifu_sn_icb_cmd_rdy;
wire[LP_IFU_ICB_COUNT - 1 : 0]              ifu_sn_icb_cmd_write;
wire[LP_IFU_SN_ADDR_WIDTH - 1 : 0]          ifu_sn_icb_cmd_addr;
wire[LP_IFU_SN_DATA_WIDTH - 1 : 0]          ifu_sn_icb_cmd_wdata;
wire[LP_IFU_SN_WSTRB_WIDTH - 1 : 0]         ifu_sn_icb_cmd_wstrb;
wire[LP_IFU_ICB_COUNT - 1 : 0]              ifu_sn_icb_rsp_vld;
wire[LP_IFU_ICB_COUNT - 1 : 0]              ifu_sn_icb_rsp_rdy;
wire[LP_IFU_SN_DATA_WIDTH - 1 : 0]          ifu_sn_icb_rsp_rdata;
wire[LP_IFU_ICB_COUNT - 1 : 0]              ifu_sn_icb_rsp_err;
wire[LP_IFU_SN_ADDR_WIDTH - 1 : 0]          ifu_sn_region_base;
wire[LP_IFU_SN_ADDR_WIDTH - 1 : 0]          ifu_sn_region_end;


wire[LP_EXU_ICB_COUNT - 1 : 0]              exu_sn_icb_cmd_vld;
wire[LP_EXU_ICB_COUNT - 1 : 0]              exu_sn_icb_cmd_rdy;
wire[LP_EXU_ICB_COUNT - 1 : 0]              exu_sn_icb_cmd_write;
wire[LP_EXU_SN_ADDR_WIDTH - 1 : 0]          exu_sn_icb_cmd_addr;
wire[LP_EXU_SN_DATA_WIDTH - 1 : 0]          exu_sn_icb_cmd_wdata;
wire[LP_EXU_SN_WSTRB_WIDTH - 1 : 0]         exu_sn_icb_cmd_wstrb;
wire[LP_EXU_ICB_COUNT - 1 : 0]              exu_sn_icb_rsp_vld;
wire[LP_EXU_ICB_COUNT - 1 : 0]              exu_sn_icb_rsp_rdy;
wire[LP_EXU_SN_DATA_WIDTH - 1 : 0]          exu_sn_icb_rsp_rdata;
wire[LP_EXU_ICB_COUNT - 1 : 0]              exu_sn_icb_rsp_err;
wire[LP_EXU_SN_ADDR_WIDTH - 1 : 0]          exu_sn_region_base;
wire[LP_EXU_SN_ADDR_WIDTH - 1 : 0]          exu_sn_region_end;


wire[LP_SLV_ICB_COUNT - 1 : 0]              slv_sn_icb_cmd_vld;
wire[LP_SLV_ICB_COUNT - 1 : 0]              slv_sn_icb_cmd_rdy;
wire[LP_SLV_ICB_COUNT - 1 : 0]              slv_sn_icb_cmd_write;
wire[LP_SLV_SN_ADDR_WIDTH - 1 : 0]          slv_sn_icb_cmd_addr;
wire[LP_SLV_SN_DATA_WIDTH - 1 : 0]          slv_sn_icb_cmd_wdata;
wire[LP_SLV_SN_WSTRB_WIDTH - 1 : 0]         slv_sn_icb_cmd_wstrb;
wire[LP_SLV_ICB_COUNT - 1 : 0]              slv_sn_icb_rsp_vld;
wire[LP_SLV_ICB_COUNT - 1 : 0]              slv_sn_icb_rsp_rdy;
wire[LP_SLV_SN_DATA_WIDTH - 1 : 0]          slv_sn_icb_rsp_rdata;
wire[LP_SLV_ICB_COUNT - 1 : 0]              slv_sn_icb_rsp_err;
wire[LP_SLV_SN_ADDR_WIDTH - 1 : 0]          slv_sn_region_base;
wire[LP_SLV_SN_ADDR_WIDTH - 1 : 0]          slv_sn_region_end;


wire[LP_ILM_ICB_COUNT - 1 : 0]              ilm_mn_icb_cmd_vld;
wire[LP_ILM_ICB_COUNT - 1 : 0]              ilm_mn_icb_cmd_rdy;
wire[LP_ILM_ICB_COUNT - 1 : 0]              ilm_mn_icb_cmd_write;
wire[LP_ILM_MN_ADDR_WIDTH - 1 : 0]          ilm_mn_icb_cmd_addr;
wire[LP_ILM_MN_DATA_WIDTH - 1 : 0]          ilm_mn_icb_cmd_wdata;
wire[LP_ILM_MN_WSTRB_WIDTH - 1 : 0]         ilm_mn_icb_cmd_wstrb;
wire[LP_ILM_ICB_COUNT - 1 : 0]              ilm_mn_icb_rsp_rdy;
wire[LP_ILM_ICB_COUNT - 1 : 0]              ilm_mn_icb_rsp_vld;
wire[LP_ILM_MN_DATA_WIDTH - 1 : 0]          ilm_mn_icb_rsp_rdata;
wire[LP_ILM_ICB_COUNT - 1 : 0]              ilm_mn_icb_rsp_err;

wire[LP_DLM_ICB_COUNT - 1 : 0]              dlm_mn_icb_cmd_vld;
wire[LP_DLM_ICB_COUNT - 1 : 0]              dlm_mn_icb_cmd_rdy;
wire[LP_DLM_ICB_COUNT - 1 : 0]              dlm_mn_icb_cmd_write;
wire[LP_DLM_MN_ADDR_WIDTH - 1 : 0]          dlm_mn_icb_cmd_addr;
wire[LP_DLM_MN_DATA_WIDTH - 1 : 0]          dlm_mn_icb_cmd_wdata;
wire[LP_DLM_MN_WSTRB_WIDTH - 1 : 0]         dlm_mn_icb_cmd_wstrb;
wire[LP_DLM_ICB_COUNT - 1 : 0]              dlm_mn_icb_rsp_rdy;
wire[LP_DLM_ICB_COUNT - 1 : 0]              dlm_mn_icb_rsp_vld;
wire[LP_DLM_MN_DATA_WIDTH - 1 : 0]          dlm_mn_icb_rsp_rdata;
wire[LP_DLM_ICB_COUNT - 1 : 0]              dlm_mn_icb_rsp_err;

wire[LP_SYS_ICB_COUNT - 1 : 0]              sys_mn_icb_cmd_vld;
wire[LP_SYS_ICB_COUNT - 1 : 0]              sys_mn_icb_cmd_rdy;
wire[LP_SYS_ICB_COUNT - 1 : 0]              sys_mn_icb_cmd_write;
wire[LP_SYS_MN_ADDR_WIDTH - 1 : 0]          sys_mn_icb_cmd_addr;
wire[LP_SYS_MN_DATA_WIDTH - 1 : 0]          sys_mn_icb_cmd_wdata;
wire[LP_SYS_MN_WSTRB_WIDTH - 1 : 0]         sys_mn_icb_cmd_wstrb;
wire[LP_SYS_ICB_COUNT - 1 : 0]              sys_mn_icb_rsp_rdy;
wire[LP_SYS_ICB_COUNT - 1 : 0]              sys_mn_icb_rsp_vld;
wire[LP_SYS_MN_DATA_WIDTH - 1 : 0]          sys_mn_icb_rsp_rdata;
wire[LP_SYS_ICB_COUNT - 1 : 0]              sys_mn_icb_rsp_err;


wire                                        ifu2ilm_cmd_vld;
wire                                        ifu2ilm_cmd_rdy;
wire                                        ifu2ilm_cmd_write;
wire[P_ADDR_WIDTH - 1 : 0]                  ifu2ilm_cmd_addr;
wire[P_DATA_WIDTH - 1 : 0]                  ifu2ilm_cmd_wdata;
wire[(P_DATA_WIDTH/8) - 1 : 0]              ifu2ilm_cmd_wstrb;
wire                                        ifu2ilm_rsp_vld;
wire                                        ifu2ilm_rsp_rdy;
wire[P_DATA_WIDTH - 1 : 0]                  ifu2ilm_rsp_rdata;


wire                                        ifu2dlm_cmd_vld;
wire                                        ifu2dlm_cmd_rdy;
wire                                        ifu2dlm_cmd_write;
wire[P_ADDR_WIDTH - 1 : 0]                  ifu2dlm_cmd_addr;
wire[P_DATA_WIDTH - 1 : 0]                  ifu2dlm_cmd_wdata;
wire[(P_DATA_WIDTH/8) - 1 : 0]              ifu2dlm_cmd_wstrb;
wire                                        ifu2dlm_rsp_vld;
wire                                        ifu2dlm_rsp_rdy;
wire[P_DATA_WIDTH - 1 : 0]                  ifu2dlm_rsp_rdata;

wire                                        ifu2sys_cmd_vld;
wire                                        ifu2sys_cmd_rdy;
wire                                        ifu2sys_cmd_write;
wire[P_ADDR_WIDTH - 1 : 0]                  ifu2sys_cmd_addr;
wire[P_DATA_WIDTH - 1 : 0]                  ifu2sys_cmd_wdata;
wire[(P_DATA_WIDTH/8) - 1 : 0]              ifu2sys_cmd_wstrb;
wire                                        ifu2sys_rsp_vld;
wire                                        ifu2sys_rsp_rdy;
wire[P_DATA_WIDTH - 1 : 0]                  ifu2sys_rsp_rdata;


wire                                        lsu2ilm_cmd_vld;
wire                                        lsu2ilm_cmd_rdy;
wire                                        lsu2ilm_cmd_write;
wire[P_ADDR_WIDTH - 1 : 0]                  lsu2ilm_cmd_addr;
wire[P_DATA_WIDTH - 1 : 0]                  lsu2ilm_cmd_wdata;
wire[(P_DATA_WIDTH/8) - 1 : 0]              lsu2ilm_cmd_wstrb;
wire                                        lsu2ilm_rsp_vld;
wire                                        lsu2ilm_rsp_rdy;
wire[P_DATA_WIDTH - 1 : 0]                  lsu2ilm_rsp_rdata;


wire                                        lsu2dlm_cmd_vld;
wire                                        lsu2dlm_cmd_rdy;
wire                                        lsu2dlm_cmd_write;
wire[P_ADDR_WIDTH - 1 : 0]                  lsu2dlm_cmd_addr;
wire[P_DATA_WIDTH - 1 : 0]                  lsu2dlm_cmd_wdata;
wire[(P_DATA_WIDTH/8) - 1 : 0]              lsu2dlm_cmd_wstrb;
wire                                        lsu2dlm_rsp_vld;
wire                                        lsu2dlm_rsp_rdy;
wire[P_DATA_WIDTH - 1 : 0]                  lsu2dlm_rsp_rdata;

wire                                        lsu2sys_cmd_vld;
wire                                        lsu2sys_cmd_rdy;
wire                                        lsu2sys_cmd_write;
wire[P_ADDR_WIDTH - 1 : 0]                  lsu2sys_cmd_addr;
wire[P_DATA_WIDTH - 1 : 0]                  lsu2sys_cmd_wdata;
wire[(P_DATA_WIDTH/8) - 1 : 0]              lsu2sys_cmd_wstrb;
wire                                        lsu2sys_rsp_vld;
wire                                        lsu2sys_rsp_rdy;
wire[P_DATA_WIDTH - 1 : 0]                  lsu2sys_rsp_rdata;


wire                                        slv2ilm_cmd_vld;
wire                                        slv2ilm_cmd_rdy;
wire                                        slv2ilm_cmd_write;
wire[P_ADDR_WIDTH - 1 : 0]                  slv2ilm_cmd_addr;
wire[P_DATA_WIDTH - 1 : 0]                  slv2ilm_cmd_wdata;
wire[(P_DATA_WIDTH/8) - 1 : 0]              slv2ilm_cmd_wstrb;
wire                                        slv2ilm_rsp_vld;
wire                                        slv2ilm_rsp_rdy;
wire[P_DATA_WIDTH - 1 : 0]                  slv2ilm_rsp_rdata;


wire                                        slv2dlm_cmd_vld;
wire                                        slv2dlm_cmd_rdy;
wire                                        slv2dlm_cmd_write;
wire[P_ADDR_WIDTH - 1 : 0]                  slv2dlm_cmd_addr;
wire[P_DATA_WIDTH - 1 : 0]                  slv2dlm_cmd_wdata;
wire[(P_DATA_WIDTH/8) - 1 : 0]              slv2dlm_cmd_wstrb;
wire                                        slv2dlm_rsp_vld;
wire                                        slv2dlm_rsp_rdy;
wire[P_DATA_WIDTH - 1 : 0]                  slv2dlm_rsp_rdata;


assign      {
                ifu2sys_cmd_vld,
                ifu2ilm_cmd_vld,
                ifu2dlm_cmd_vld
            } = ifu_sn_icb_cmd_vld;

assign      ifu_sn_icb_cmd_rdy =    {
                                        ifu2sys_cmd_rdy,
                                        ifu2ilm_cmd_rdy,
                                        ifu2dlm_cmd_rdy
                                    };

assign      {
                ifu2sys_cmd_write,
                ifu2ilm_cmd_write,
                ifu2dlm_cmd_write
            } = ifu_sn_icb_cmd_write;

assign      {
                ifu2sys_cmd_addr,
                ifu2ilm_cmd_addr,
                ifu2dlm_cmd_addr
            } = ifu_sn_icb_cmd_addr;

assign      {
                ifu2sys_cmd_wdata,
                ifu2ilm_cmd_wdata,
                ifu2dlm_cmd_wdata
            } = ifu_sn_icb_cmd_wdata;

assign      {
                ifu2sys_cmd_wstrb,
                ifu2ilm_cmd_wstrb,
                ifu2dlm_cmd_wstrb
            } = ifu_sn_icb_cmd_wstrb;

assign      ifu_sn_icb_rsp_vld =    {
                                        ifu2sys_rsp_vld,
                                        ifu2ilm_rsp_vld,
                                        ifu2dlm_rsp_vld
                                    };

assign      {
                ifu2sys_rsp_rdy,
                ifu2ilm_rsp_rdy,
                ifu2dlm_rsp_rdy
            } = ifu_sn_icb_rsp_rdy;

assign      ifu_sn_icb_rsp_rdata =  {
                                        ifu2sys_rsp_rdata,
                                        ifu2ilm_rsp_rdata,
                                        ifu2dlm_rsp_rdata
                                    };

assign      ifu_sn_icb_rsp_err =    {
                                        ifu2sys_rsp_err,
                                        ifu2ilm_rsp_err,
                                        ifu2dlm_rsp_err
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

// ifu可能会访问ilm、dlm以及sys总线
lnrv_icb_demux#
(
    .P_ADDR_WIDTH           ( P_ADDR_WIDTH              ),
    .P_DATA_WIDTH           ( P_DATA_WIDTH              ),
    .P_ICB_COUNT            ( LP_IFU_ICB_COUNT          ),

    .P_CMD_BUFF_ENABLE      ( "false"                   ),
    .P_CMD_BUFF_CUT_READY   ( "false"                   ),
    .P_CMD_BUFF_BYPASS      ( "true"                    ),

    .P_RSP_BUFF_ENABLE      ( "true"                    ),
    .P_RSP_BUFF_CUT_READY   ( "false"                   ),
    .P_RSP_BUFF_BYPASS      ( "true"                    ),

    .P_OTS_COUNT            ( 1                         )
)
u_ifu_bus_demux
(
    .clk                    ( clk                       ),
    .reset_n                ( reset_n                   ),

    .m_icb_cmd_vld          ( ifu_cmd_vld               ),
    .m_icb_cmd_rdy          ( ifu_cmd_rdy               ),
    .m_icb_cmd_write        ( ifu_cmd_write             ),
    .m_icb_cmd_addr         ( ifu_cmd_addr              ),
    .m_icb_cmd_wdata        ( ifu_cmd_wdata             ),
    .m_icb_cmd_wstrb        ( ifu_cmd_wstrb             ),
    .m_icb_rsp_rdy          ( ifu_rsp_rdy               ),
    .m_icb_rsp_vld          ( ifu_rsp_vld               ),
    .m_icb_rsp_rdata        ( ifu_rsp_rdata             ),
    .m_icb_rsp_err          ( ifu_rsp_err               ),

    .sn_icb_cmd_vld         ( ifu_sn_icb_cmd_vld        ),
    .sn_icb_cmd_rdy         ( ifu_sn_icb_cmd_rdy        ),
    .sn_icb_cmd_write       ( ifu_sn_icb_cmd_write      ),
    .sn_icb_cmd_addr        ( ifu_sn_icb_cmd_addr       ),
    .sn_icb_cmd_wdata       ( ifu_sn_icb_cmd_wdata      ),
    .sn_icb_cmd_wstrb       ( ifu_sn_icb_cmd_wstrb      ),
    .sn_icb_rsp_vld         ( ifu_sn_icb_rsp_vld        ),
    .sn_icb_rsp_rdy         ( ifu_sn_icb_rsp_rdy        ),
    .sn_icb_rsp_rdata       ( ifu_sn_icb_rsp_rdata      ),
    .sn_icb_rsp_err         ( ifu_sn_icb_rsp_err        ),

    .sn_region_base         ( ifu_sn_region_base        ),
    .sn_region_end          ( ifu_sn_region_end         )
);


assign      {
                lsu2sys_cmd_vld,
                lsu2ilm_cmd_vld,
                lsu2dlm_cmd_vld
            } = exu_sn_icb_cmd_vld;

assign      exu_sn_icb_cmd_rdy =    {
                                        lsu2sys_cmd_rdy,
                                        lsu2ilm_cmd_rdy,
                                        lsu2dlm_cmd_rdy
                                    };

assign      {
                lsu2sys_cmd_write,
                lsu2ilm_cmd_write,
                lsu2dlm_cmd_write
            } = exu_sn_icb_cmd_write;

assign      {
                lsu2sys_cmd_addr,
                lsu2ilm_cmd_addr,
                lsu2dlm_cmd_addr
            } = exu_sn_icb_cmd_addr;

assign      {
                lsu2sys_cmd_wdata,
                lsu2ilm_cmd_wdata,
                lsu2dlm_cmd_wdata
            } = exu_sn_icb_cmd_wdata;

assign      {
                lsu2sys_cmd_wstrb,
                lsu2ilm_cmd_wstrb,
                lsu2dlm_cmd_wstrb
            } = exu_sn_icb_cmd_wstrb;

assign      exu_sn_icb_rsp_vld =    {
                                        lsu2sys_rsp_vld,
                                        lsu2ilm_rsp_vld,
                                        lsu2dlm_rsp_vld
                                    };

assign      {
                lsu2sys_rsp_rdy,
                lsu2ilm_rsp_rdy,
                lsu2dlm_rsp_rdy
            } = exu_sn_icb_rsp_rdy;

assign      exu_sn_icb_rsp_rdata =  {
                                        lsu2sys_rsp_rdata,
                                        lsu2ilm_rsp_rdata,
                                        lsu2dlm_rsp_rdata
                                    };

assign      exu_sn_icb_rsp_err =    {
                                        lsu2sys_rsp_err,
                                        lsu2ilm_rsp_err,
                                        lsu2dlm_rsp_err
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

// lsu可能访问ilm/dlm/sys
lnrv_icb_demux#
(
    .P_ADDR_WIDTH           ( P_ADDR_WIDTH              ),
    .P_DATA_WIDTH           ( P_DATA_WIDTH              ),
    .P_ICB_COUNT            ( LP_EXU_ICB_COUNT          ),

    .P_CMD_BUFF_ENABLE      ( "false"                   ),
    .P_CMD_BUFF_CUT_READY   ( "false"                   ),
    .P_CMD_BUFF_BYPASS      ( "true"                    ),

    .P_RSP_BUFF_ENABLE      ( "true"                    ),
    .P_RSP_BUFF_CUT_READY   ( "false"                   ),
    .P_RSP_BUFF_BYPASS      ( "true"                    ),

    .P_OTS_COUNT            ( 1                         )
)
u_exu_bus_demux
(
    .clk                    ( clk                       ),
    .reset_n                ( reset_n                   ),
    .m_icb_cmd_vld          ( exu_cmd_vld               ),
    .m_icb_cmd_rdy          ( exu_cmd_rdy               ),
    .m_icb_cmd_write        ( exu_cmd_write             ),
    .m_icb_cmd_addr         ( exu_cmd_addr              ),
    .m_icb_cmd_wdata        ( exu_cmd_wdata             ),
    .m_icb_cmd_wstrb        ( exu_cmd_wstrb             ),
    .m_icb_rsp_rdy          ( exu_rsp_rdy               ),
    .m_icb_rsp_vld          ( exu_rsp_vld               ),
    .m_icb_rsp_rdata        ( exu_rsp_rdata             ),
    .m_icb_rsp_err          ( exu_rsp_err               ),

    .sn_icb_cmd_vld         ( exu_sn_icb_cmd_vld        ),
    .sn_icb_cmd_rdy         ( exu_sn_icb_cmd_rdy        ),
    .sn_icb_cmd_write       ( exu_sn_icb_cmd_write      ),
    .sn_icb_cmd_addr        ( exu_sn_icb_cmd_addr       ),
    .sn_icb_cmd_wdata       ( exu_sn_icb_cmd_wdata      ),
    .sn_icb_cmd_wstrb       ( exu_sn_icb_cmd_wstrb      ),
    .sn_icb_rsp_vld         ( exu_sn_icb_rsp_vld        ),
    .sn_icb_rsp_rdy         ( exu_sn_icb_rsp_rdy        ),
    .sn_icb_rsp_rdata       ( exu_sn_icb_rsp_rdata      ),
    .sn_icb_rsp_err         ( exu_sn_icb_rsp_err        ),

    .sn_region_base         ( exu_sn_region_base        ),
    .sn_region_end          ( exu_sn_region_end         )
);


assign      {
                slv2ilm_cmd_vld,
                slv2dlm_cmd_vld
            } = slv_sn_icb_cmd_vld;

assign      slv_sn_icb_cmd_rdy =    {
                                        slv2ilm_cmd_rdy,
                                        slv2dlm_cmd_rdy
                                    };

assign      {
                slv2ilm_cmd_write,
                slv2dlm_cmd_write
            } = slv_sn_icb_cmd_write;

assign      {
                slv2ilm_cmd_addr,
                slv2dlm_cmd_addr
            } = slv_sn_icb_cmd_addr;

assign      {
                slv2ilm_cmd_wdata,
                slv2dlm_cmd_wdata
            } = slv_sn_icb_cmd_wdata;

assign      {
                slv2ilm_cmd_wstrb,
                slv2dlm_cmd_wstrb
            } = slv_sn_icb_cmd_wstrb;

assign      slv_sn_icb_rsp_vld =    {
                                        slv2ilm_rsp_vld,
                                        slv2dlm_rsp_vld
                                    };

assign      {
                slv2ilm_rsp_rdy,
                slv2dlm_rsp_rdy
            } = slv_sn_icb_rsp_rdy;

assign      slv_sn_icb_rsp_rdata =  {
                                        slv2ilm_rsp_rdata,
                                        slv2dlm_rsp_rdata
                                    };

assign      slv_sn_icb_rsp_err =    {
                                        slv2ilm_rsp_err,
                                        slv2dlm_rsp_err
                                    };

assign      slv_sn_region_base =    {
                                        P_ILM_REGION_START,
                                        P_DLM_REGION_START
                                    };

assign      slv_sn_region_end = {
                                    P_ILM_REGION_END,
                                    P_DLM_REGION_END
                                };

// slave port只能访问ilm\dlm
lnrv_icb_demux#
(
    .P_ADDR_WIDTH           ( P_ADDR_WIDTH              ),
    .P_DATA_WIDTH           ( P_DATA_WIDTH              ),
    .P_ICB_COUNT            ( LP_SLV_ICB_COUNT          ),

    .P_CMD_BUFF_ENABLE      ( "false"                   ),
    .P_CMD_BUFF_CUT_READY   ( "false"                   ),
    .P_CMD_BUFF_BYPASS      ( "true"                    ),

    .P_RSP_BUFF_ENABLE      ( "true"                    ),
    .P_RSP_BUFF_CUT_READY   ( "false"                   ),
    .P_RSP_BUFF_BYPASS      ( "true"                    ),

    .P_OTS_COUNT            ( 1                         )
)
u_slv_bus_demux
(
    .clk                    ( clk                       ),
    .reset_n                ( reset_n                   ),
    .m_icb_cmd_vld          ( slv_cmd_vld               ),
    .m_icb_cmd_rdy          ( slv_cmd_rdy               ),
    .m_icb_cmd_write        ( slv_cmd_write             ),
    .m_icb_cmd_addr         ( slv_cmd_addr              ),
    .m_icb_cmd_wdata        ( slv_cmd_wdata             ),
    .m_icb_cmd_wstrb        ( slv_cmd_wstrb             ),
    .m_icb_rsp_rdy          ( slv_rsp_rdy               ),
    .m_icb_rsp_vld          ( slv_rsp_vld               ),
    .m_icb_rsp_rdata        ( slv_rsp_rdata             ),
    .m_icb_rsp_err          ( slv_rsp_err               ),

    .sn_icb_cmd_vld         ( slv_sn_icb_cmd_vld        ),
    .sn_icb_cmd_rdy         ( slv_sn_icb_cmd_rdy        ),
    .sn_icb_cmd_write       ( slv_sn_icb_cmd_write      ),
    .sn_icb_cmd_addr        ( slv_sn_icb_cmd_addr       ),
    .sn_icb_cmd_wdata       ( slv_sn_icb_cmd_wdata      ),
    .sn_icb_cmd_wstrb       ( slv_sn_icb_cmd_wstrb      ),
    .sn_icb_rsp_vld         ( slv_sn_icb_rsp_vld        ),
    .sn_icb_rsp_rdy         ( slv_sn_icb_rsp_rdy        ),
    .sn_icb_rsp_rdata       ( slv_sn_icb_rsp_rdata      ),
    .sn_icb_rsp_err         ( slv_sn_icb_rsp_err        ),

    .sn_region_base         ( slv_sn_region_base        ),
    .sn_region_end          ( slv_sn_region_end         )
);

assign      ilm_mn_icb_cmd_vld =    {
                                        slv2ilm_cmd_vld,
                                        ifu2ilm_cmd_vld,
                                        lsu2ilm_cmd_vld
                                    };

assign      {
                slv2ilm_cmd_rdy,
                ifu2ilm_cmd_rdy,
                lsu2ilm_cmd_rdy
            } = ilm_mn_icb_cmd_rdy;

assign      ilm_mn_icb_cmd_write =  {
                                        slv2ilm_cmd_write,
                                        ifu2ilm_cmd_write,
                                        lsu2ilm_cmd_write
                                    };

assign      ilm_mn_icb_cmd_addr =   {
                                        slv2ilm_cmd_addr,
                                        ifu2ilm_cmd_addr,
                                        lsu2ilm_cmd_addr
                                    };

assign      ilm_mn_icb_cmd_wdata =  {
                                        slv2ilm_cmd_wdata,
                                        ifu2ilm_cmd_wdata,
                                        lsu2ilm_cmd_wdata
                                    };

assign      ilm_mn_icb_cmd_wstrb =  {
                                        slv2ilm_cmd_wstrb,
                                        ifu2ilm_cmd_wstrb,
                                        lsu2ilm_cmd_wstrb
                                    };

assign      {
                slv2ilm_rsp_vld,
                ifu2ilm_rsp_vld,
                lsu2ilm_rsp_vld
            } = ilm_mn_icb_rsp_vld;

assign      ilm_mn_icb_rsp_rdy =    {
                                        slv2ilm_rsp_rdy,
                                        ifu2ilm_rsp_rdy,
                                        lsu2ilm_rsp_rdy
                                    };

assign      {
                slv2ilm_rsp_rdata,
                ifu2ilm_rsp_rdata,
                lsu2ilm_rsp_rdata
            } = ilm_mn_icb_rsp_rdata;

assign      {
                slv2ilm_rsp_err,
                ifu2ilm_rsp_err,
                lsu2ilm_rsp_err
            } = ilm_mn_icb_rsp_err;

// ifu\lsu\slv都有可能访问ilm
lnrv_icb_mux#
(
    .P_ADDR_WIDTH           ( P_ADDR_WIDTH              ),
    .P_DATA_WIDTH           ( P_DATA_WIDTH              ),
    .P_ICB_COUNT            ( LP_ILM_ICB_COUNT          ),
    .P_OTS_COUNT            ( 1                         ),

    .P_CMD_BUFF_ENABLE      ( "true"                    ),
    .P_CMD_BUFF_CUT_READY   ( "false"                   ),
    .P_CMD_BUFF_BYPASS      ( "true"                    ),

    .P_RSP_BUFF_ENABLE      ( "false"                   ),
    .P_RSP_BUFF_CUT_READY   ( "false"                   ),
    .P_RSP_BUFF_BYPASS      ( "true"                    )
)   
u_ilm_bus_mux  
(   
    .clk                    ( clk                       ),
    .reset_n                ( reset_n                   ),

    .mn_icb_cmd_vld         ( ilm_mn_icb_cmd_vld        ),
    .mn_icb_cmd_rdy         ( ilm_mn_icb_cmd_rdy        ),
    .mn_icb_cmd_write       ( ilm_mn_icb_cmd_write      ),
    .mn_icb_cmd_addr        ( ilm_mn_icb_cmd_addr       ),
    .mn_icb_cmd_wdata       ( ilm_mn_icb_cmd_wdata      ),
    .mn_icb_cmd_wstrb       ( ilm_mn_icb_cmd_wstrb      ),
    .mn_icb_rsp_rdy         ( ilm_mn_icb_rsp_rdy        ),
    .mn_icb_rsp_vld         ( ilm_mn_icb_rsp_vld        ),
    .mn_icb_rsp_rdata       ( ilm_mn_icb_rsp_rdata      ),
    .mn_icb_rsp_err         ( ilm_mn_icb_rsp_err        ),

    .s_icb_cmd_vld          ( ilm_cmd_vld               ),
    .s_icb_cmd_rdy          ( ilm_cmd_rdy               ),
    .s_icb_cmd_write        ( ilm_cmd_write             ),
    .s_icb_cmd_addr         ( ilm_cmd_addr              ),
    .s_icb_cmd_wdata        ( ilm_cmd_wdata             ),
    .s_icb_cmd_wstrb        ( ilm_cmd_wstrb             ),
    .s_icb_rsp_vld          ( ilm_rsp_vld               ),
    .s_icb_rsp_rdy          ( ilm_rsp_rdy               ),
    .s_icb_rsp_rdata        ( ilm_rsp_rdata             ),
    .s_icb_rsp_err          ( ilm_rsp_err               )
);


assign      dlm_mn_icb_cmd_vld =    {
                                        slv2dlm_cmd_vld,
                                        ifu2dlm_cmd_vld,
                                        lsu2dlm_cmd_vld
                                    };

assign      {
                slv2dlm_cmd_rdy,
                ifu2dlm_cmd_rdy,
                lsu2dlm_cmd_rdy
            } = dlm_mn_icb_cmd_rdy;

assign      dlm_mn_icb_cmd_write =  {
                                        slv2dlm_cmd_write,
                                        ifu2dlm_cmd_write,
                                        lsu2dlm_cmd_write
                                    };

assign      dlm_mn_icb_cmd_addr =   {
                                        slv2dlm_cmd_addr,
                                        ifu2dlm_cmd_addr,
                                        lsu2dlm_cmd_addr
                                    };

assign      dlm_mn_icb_cmd_wdata =  {
                                        slv2dlm_cmd_wdata,
                                        ifu2dlm_cmd_wdata,
                                        lsu2dlm_cmd_wdata
                                    };

assign      dlm_mn_icb_cmd_wstrb =  {
                                        slv2dlm_cmd_wstrb,
                                        ifu2dlm_cmd_wstrb,
                                        lsu2dlm_cmd_wstrb
                                    };

assign      {
                slv2dlm_rsp_vld,
                ifu2dlm_rsp_vld,
                lsu2dlm_rsp_vld
            } = dlm_mn_icb_rsp_vld;

assign      dlm_mn_icb_rsp_rdy =    {
                                        slv2dlm_rsp_rdy,
                                        ifu2dlm_rsp_rdy,
                                        lsu2dlm_rsp_rdy
                                    };

assign      {
                slv2dlm_rsp_rdata,
                ifu2dlm_rsp_rdata,
                lsu2dlm_rsp_rdata
            } = dlm_mn_icb_rsp_rdata;

assign      {
                slv2dlm_rsp_err,
                ifu2dlm_rsp_err,
                lsu2dlm_rsp_err
            } = dlm_mn_icb_rsp_err;

// slv\ifu\lsu都有可能访问dlm
lnrv_icb_mux#
(
    .P_ADDR_WIDTH           ( P_ADDR_WIDTH              ),
    .P_DATA_WIDTH           ( P_DATA_WIDTH              ),
    .P_ICB_COUNT            ( LP_DLM_ICB_COUNT          ),
    .P_OTS_COUNT            ( 1                         ),

    .P_CMD_BUFF_ENABLE      ( "true"                    ),
    .P_CMD_BUFF_CUT_READY   ( "false"                   ),
    .P_CMD_BUFF_BYPASS      ( "true"                    ),

    .P_RSP_BUFF_ENABLE      ( "false"                   ),
    .P_RSP_BUFF_CUT_READY   ( "false"                   ),
    .P_RSP_BUFF_BYPASS      ( "true"                    )
)   
u_dlm_bus_mux  
(   
    .clk                    ( clk                       ),
    .reset_n                ( reset_n                   ),
    .mn_icb_cmd_vld         ( dlm_mn_icb_cmd_vld        ),
    .mn_icb_cmd_rdy         ( dlm_mn_icb_cmd_rdy        ),
    .mn_icb_cmd_write       ( dlm_mn_icb_cmd_write      ),
    .mn_icb_cmd_addr        ( dlm_mn_icb_cmd_addr       ),
    .mn_icb_cmd_wdata       ( dlm_mn_icb_cmd_wdata      ),
    .mn_icb_cmd_wstrb       ( dlm_mn_icb_cmd_wstrb      ),
    .mn_icb_rsp_rdy         ( dlm_mn_icb_rsp_rdy        ),
    .mn_icb_rsp_vld         ( dlm_mn_icb_rsp_vld        ),
    .mn_icb_rsp_rdata       ( dlm_mn_icb_rsp_rdata      ),
    .mn_icb_rsp_err         ( dlm_mn_icb_rsp_err        ),

    .s_icb_cmd_vld          ( dlm_cmd_vld               ),
    .s_icb_cmd_rdy          ( dlm_cmd_rdy               ),
    .s_icb_cmd_write        ( dlm_cmd_write             ),
    .s_icb_cmd_addr         ( dlm_cmd_addr              ),
    .s_icb_cmd_wdata        ( dlm_cmd_wdata             ),
    .s_icb_cmd_wstrb        ( dlm_cmd_wstrb             ),
    .s_icb_rsp_vld          ( dlm_rsp_vld               ),
    .s_icb_rsp_rdy          ( dlm_rsp_rdy               ),
    .s_icb_rsp_rdata        ( dlm_rsp_rdata             ),
    .s_icb_rsp_err          ( dlm_rsp_err               )
);

assign      sys_mn_icb_cmd_vld =    {
                                        ifu2sys_cmd_vld,
                                        lsu2sys_cmd_vld
                                    };

assign      {
                ifu2sys_cmd_rdy,
                lsu2sys_cmd_rdy
            } = sys_mn_icb_cmd_rdy;

assign      sys_mn_icb_cmd_write =  {
                                        ifu2sys_cmd_write,
                                        lsu2sys_cmd_write
                                    };

assign      sys_mn_icb_cmd_addr =   {
                                        ifu2sys_cmd_addr,
                                        lsu2sys_cmd_addr
                                    };

assign      sys_mn_icb_cmd_wdata =  {
                                        ifu2sys_cmd_wdata,
                                        lsu2sys_cmd_wdata
                                    };

assign      sys_mn_icb_cmd_wstrb =  {
                                        ifu2sys_cmd_wstrb,
                                        lsu2sys_cmd_wstrb
                                    };

assign      {
                ifu2sys_rsp_vld,
                lsu2sys_rsp_vld
            } = sys_mn_icb_rsp_vld;

assign      sys_mn_icb_rsp_rdy =    {
                                        ifu2sys_rsp_rdy,
                                        lsu2sys_rsp_rdy
                                    };

assign      {
                ifu2sys_rsp_rdata,
                lsu2sys_rsp_rdata
            } = sys_mn_icb_rsp_rdata;

assign      {
                ifu2sys_rsp_err,
                lsu2sys_rsp_err
            } = sys_mn_icb_rsp_err;

// ifu\lsu可能访问系统总线
lnrv_icb_mux#
(
    .P_ADDR_WIDTH           ( P_ADDR_WIDTH              ),
    .P_DATA_WIDTH           ( P_DATA_WIDTH              ),
    .P_ICB_COUNT            ( LP_SYS_ICB_COUNT          ),
    .P_OTS_COUNT            ( 1                         ),

    .P_CMD_BUFF_ENABLE      ( "true"                    ),
    .P_CMD_BUFF_CUT_READY   ( "false"                   ),
    .P_CMD_BUFF_BYPASS      ( "true"                    ),

    .P_RSP_BUFF_ENABLE      ( "false"                   ),
    .P_RSP_BUFF_CUT_READY   ( "false"                   ),
    .P_RSP_BUFF_BYPASS      ( "true"                    )
)   
u_sys_bus_mux  
(   
    .clk                    ( clk                       ),
    .reset_n                ( reset_n                   ),

    .mn_icb_cmd_vld         ( sys_mn_icb_cmd_vld        ),
    .mn_icb_cmd_rdy         ( sys_mn_icb_cmd_rdy        ),
    .mn_icb_cmd_write       ( sys_mn_icb_cmd_write      ),
    .mn_icb_cmd_addr        ( sys_mn_icb_cmd_addr       ),
    .mn_icb_cmd_wdata       ( sys_mn_icb_cmd_wdata      ),
    .mn_icb_cmd_wstrb       ( sys_mn_icb_cmd_wstrb      ),
    .mn_icb_rsp_rdy         ( sys_mn_icb_rsp_rdy        ),
    .mn_icb_rsp_vld         ( sys_mn_icb_rsp_vld        ),
    .mn_icb_rsp_rdata       ( sys_mn_icb_rsp_rdata      ),
    .mn_icb_rsp_err         ( sys_mn_icb_rsp_err        ),

    .s_icb_cmd_vld          ( sys_cmd_vld               ),
    .s_icb_cmd_rdy          ( sys_cmd_rdy               ),
    .s_icb_cmd_write        ( sys_cmd_write             ),
    .s_icb_cmd_addr         ( sys_cmd_addr              ),
    .s_icb_cmd_wdata        ( sys_cmd_wdata             ),
    .s_icb_cmd_wstrb        ( sys_cmd_wstrb             ),
    .s_icb_rsp_vld          ( sys_rsp_vld               ),
    .s_icb_rsp_rdy          ( sys_rsp_rdy               ),
    .s_icb_rsp_rdata        ( sys_rsp_rdata             ),
    .s_icb_rsp_err          ( sys_rsp_err               )
);

endmodule