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

    input                                   sft_irq,
    input                                   tmr_irq,
    input                                   ext_irq,

    input                                   dbg_halt,
    input                                   dbg_irq,

    // 
    output                                  wfi_mode,

    // 固件下载模式
    input                                   download_mode,

    // 系统总线
    output                                  sys_awvalid,
    input                                   sys_awready,
    output                                  sys_awlock,
    output[31 : 0]                          sys_awaddr,
    output[3 : 0]                           sys_awid,
    output[7 : 0]                           sys_awlen,
    output[2 : 0]                           sys_awsize,
    output[1 : 0]                           sys_awburst,
    output[3 : 0]                           sys_awcache,
    output[2 : 0]                           sys_awprot,

    output                                  sys_wvalid,
    input                                   sys_wready,
    output[31 : 0]                          sys_wdata,
    output[3 : 0]                           sys_wstrb,
    output                                  sys_wlast,

    output                                  sys_bready,
    input                                   sys_bvalid,
    input[1 : 0]                            sys_bresp,
    input[3 : 0]                            sys_bid,

    output                                  sys_arvalid,
    input                                   sys_arready,
    output                                  sys_arlock,
    output[31 : 0]                          sys_araddr,
    output[3 : 0]                           sys_arid,
    output[7 : 0]                           sys_arlen,
    output[2 : 0]                           sys_arsize,
    output[1 : 0]                           sys_arburst,
    output[3 : 0]                           sys_arcache,
    output[2 : 0]                           sys_arprot,

    output                                  sys_rready,
    input                                   sys_rvalid,
    input[31 : 0]                           sys_rdata,
    input[1 : 0]                            sys_rresp,
    input                                   sys_rlast,
    input[3 : 0]                            sys_rid,

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

    input                                   axi_wvalid,
    output                                  axi_wready,
    input[31 : 0]                           axi_wdata,
    input[31 : 0]                           axi_wstrb,
    input                                   axi_wlast,

    input                                   axi_bready,
    output                                  axi_bvalid,
    output[1 : 0]                           axi_bresp,
    output[3 : 0]                           axi_bid,

    input                                   axi_arvalid,
    output                                  axi_arready,
    input                                   axi_arlock,
    input[31 : 0]                           axi_araddr,
    input[3 : 0]                            axi_arid,
    input[7 : 0]                            axi_arlen,
    input[2 : 0]                            axi_arsize,
    input[1 : 0]                            axi_arburst,
    input[3 : 0]                            axi_arcache,
    input[2 : 0]                            axi_arprot,

    input                                   axi_rready,
    output                                  axi_rvalid,
    output[31 : 0]                          axi_rdata,
    output[1 : 0]                           axi_rresp,
    output                                  axi_rlast,
    output[3 : 0]                           axi_rid,

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

wire                            ifu_cmd_vld;
wire                            ifu_cmd_rdy;
wire                            ifu_cmd_write;
wire[31 : 0]                    ifu_cmd_addr;
wire[31 : 0]                    ifu_cmd_wdata;
wire[3 : 0]                     ifu_cmd_wstrb;
wire                            ifu_rsp_vld;
wire                            ifu_rsp_rdy;
wire[31 : 0]                    ifu_rsp_rdata;
wire                            ifu_rsp_err;


wire                            exu_cmd_vld;
wire                            exu_cmd_rdy;
wire                            exu_cmd_write;
wire[31 : 0]                    exu_cmd_addr;
wire[31 : 0]                    exu_cmd_wdata;
wire[3 : 0]                     exu_cmd_wstrb;
wire                            exu_rsp_vld;
wire                            exu_rsp_rdy;
wire[31 : 0]                    exu_rsp_rdata;
wire                            exu_rsp_err;


wire                            slv_cmd_vld;
wire                            slv_cmd_rdy;
wire                            slv_cmd_write;
wire[31 : 0]                    slv_cmd_addr;
wire[31 : 0]                    slv_cmd_wdata;
wire[3 : 0]                     slv_cmd_wstrb;
wire                            slv_rsp_vld;
wire                            slv_rsp_rdy;
wire[31 : 0]                    slv_rsp_rdata;
wire                            slv_rsp_err;

wire                            ilm_cmd_vld;
wire                            ilm_cmd_rdy;
wire                            ilm_cmd_write;
wire[31 : 0]                    ilm_cmd_addr;
wire[31 : 0]                    ilm_cmd_wdata;
wire[3 : 0]                     ilm_cmd_wstrb;
wire                            ilm_rsp_vld;
wire                            ilm_rsp_rdy;
wire[31 : 0]                    ilm_rsp_rdata;
wire                            ilm_rsp_err;

wire                            dlm_cmd_vld;
wire                            dlm_cmd_rdy;
wire                            dlm_cmd_write;
wire[31 : 0]                    dlm_cmd_addr;
wire[31 : 0]                    dlm_cmd_wdata;
wire[3 : 0]                     dlm_cmd_wstrb;
wire                            dlm_rsp_vld;
wire                            dlm_rsp_rdy;
wire[31 : 0]                    dlm_rsp_rdata;
wire                            dlm_rsp_err;


wire                            sys_cmd_vld;
wire                            sys_cmd_rdy;
wire                            sys_cmd_write;
wire[31 : 0]                    sys_cmd_addr;
wire[31 : 0]                    sys_cmd_wdata;
wire[3 : 0]                     sys_cmd_wstrb;
wire                            sys_rsp_vld;
wire                            sys_rsp_rdy;
wire[31 : 0]                    sys_rsp_rdata;
wire                            sys_rsp_err;


wire                            sys_cs;
wire                            sys_we;
wire[3 : 0]                     sys_wem;
wire[19 : 0]                    sys_addr;
wire[31 : 0]                    sys_rdata;
wire[31 : 0]                    sys_wdata;


assign      slv_cmd_vld = 1'b0;
assign      slv_cmd_write = 1'b0;
assign      slv_cmd_addr = 32'd0;
assign      slv_cmd_wdata = 32'd0;
assign      slv_cmd_wstrb = 4'd0;

assign      slv_rsp_rdy = 1'b1;


// 
lnrv_core u_lnrv_core
(           
    .reset_vector           ( reset_vector              ),

    .sft_irq                ( sft_irq                   ),
    .ext_irq                ( ext_irq                   ),
    .tmr_irq                ( tmr_irq                   ),

    .dbg_halt               ( dbg_halt                  ),
    .dbg_irq                ( dbg_irq                   ),

    .wfi_mode               ( wfi_mode                  ),

    .stop_time              ( stop_time                 ),
    .stop_count             ( stop_count                ),

    // ifu访存接口
    .ifu_cmd_vld            ( ifu_cmd_vld               ),
    .ifu_cmd_rdy            ( ifu_cmd_rdy               ),
    .ifu_cmd_write          ( ifu_cmd_write             ),
    .ifu_cmd_addr           ( ifu_cmd_addr              ),
    .ifu_cmd_wdata          ( ifu_cmd_wdata             ),
    .ifu_cmd_wstrb          ( ifu_cmd_wstrb             ),
    .ifu_rsp_vld            ( ifu_rsp_vld               ),
    .ifu_rsp_rdy            ( ifu_rsp_rdy               ),
    .ifu_rsp_rdata          ( ifu_rsp_rdata             ),
    .ifu_rsp_err            ( ifu_rsp_err               ),

    // exu访存接口
    .exu_cmd_vld            ( exu_cmd_vld               ),
    .exu_cmd_rdy            ( exu_cmd_rdy               ),
    .exu_cmd_write          ( exu_cmd_write             ),
    .exu_cmd_addr           ( exu_cmd_addr              ),
    .exu_cmd_wdata          ( exu_cmd_wdata             ),
    .exu_cmd_wstrb          ( exu_cmd_wstrb             ),
    .exu_rsp_vld            ( exu_rsp_vld               ),
    .exu_rsp_rdy            ( exu_rsp_rdy               ),
    .exu_rsp_rdata          ( exu_rsp_rdata             ),
    .exu_rsp_err            ( exu_rsp_err               ),

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
    .P_DATA_WIDTH           ( 32                        )
)
u_lnrv_biu
(
    .ifu_cmd_vld            ( ifu_cmd_vld               ),
    .ifu_cmd_rdy            ( ifu_cmd_rdy               ),
    .ifu_cmd_write          ( ifu_cmd_write             ),
    .ifu_cmd_addr           ( ifu_cmd_addr              ),
    .ifu_cmd_wdata          ( ifu_cmd_wdata             ),
    .ifu_cmd_wstrb          ( ifu_cmd_wstrb             ),
    .ifu_rsp_vld            ( ifu_rsp_vld               ),
    .ifu_rsp_rdy            ( ifu_rsp_rdy               ),
    .ifu_rsp_rdata          ( ifu_rsp_rdata             ),
    .ifu_rsp_err            ( ifu_rsp_err               ),

    .exu_cmd_vld            ( exu_cmd_vld               ),
    .exu_cmd_rdy            ( exu_cmd_rdy               ),
    .exu_cmd_write          ( exu_cmd_write             ),
    .exu_cmd_addr           ( exu_cmd_addr              ),
    .exu_cmd_wdata          ( exu_cmd_wdata             ),
    .exu_cmd_wstrb          ( exu_cmd_wstrb             ),
    .exu_rsp_vld            ( exu_rsp_vld               ),
    .exu_rsp_rdy            ( exu_rsp_rdy               ),
    .exu_rsp_rdata          ( exu_rsp_rdata             ),
    .exu_rsp_err            ( exu_rsp_err               ),

    .slv_cmd_vld            ( slv_cmd_vld               ),
    .slv_cmd_rdy            ( slv_cmd_rdy               ),
    .slv_cmd_write          ( slv_cmd_write             ),
    .slv_cmd_addr           ( slv_cmd_addr              ),
    .slv_cmd_wdata          ( slv_cmd_wdata             ),
    .slv_cmd_wstrb          ( slv_cmd_wstrb             ),
    .slv_rsp_vld            ( slv_rsp_vld               ),
    .slv_rsp_rdy            ( slv_rsp_rdy               ),
    .slv_rsp_rdata          ( slv_rsp_rdata             ),
    .slv_rsp_err            ( slv_rsp_err               ),

    .ilm_cmd_vld            ( ilm_cmd_vld               ),
    .ilm_cmd_rdy            ( ilm_cmd_rdy               ),
    .ilm_cmd_write          ( ilm_cmd_write             ),
    .ilm_cmd_addr           ( ilm_cmd_addr              ),
    .ilm_cmd_wdata          ( ilm_cmd_wdata             ),
    .ilm_cmd_wstrb          ( ilm_cmd_wstrb             ),
    .ilm_rsp_vld            ( ilm_rsp_vld               ),
    .ilm_rsp_rdy            ( ilm_rsp_rdy               ),
    .ilm_rsp_rdata          ( ilm_rsp_rdata             ),
    .ilm_rsp_err            ( ilm_rsp_err               ),

    .dlm_cmd_vld            ( dlm_cmd_vld               ),
    .dlm_cmd_rdy            ( dlm_cmd_rdy               ),
    .dlm_cmd_write          ( dlm_cmd_write             ),
    .dlm_cmd_addr           ( dlm_cmd_addr              ),
    .dlm_cmd_wdata          ( dlm_cmd_wdata             ),
    .dlm_cmd_wstrb          ( dlm_cmd_wstrb             ),
    .dlm_rsp_vld            ( dlm_rsp_vld               ),
    .dlm_rsp_rdy            ( dlm_rsp_rdy               ),
    .dlm_rsp_rdata          ( dlm_rsp_rdata             ),
    .dlm_rsp_err            ( dlm_rsp_err               ),

    .sys_cmd_vld            ( sys_cmd_vld               ),
    .sys_cmd_rdy            ( sys_cmd_rdy               ),
    .sys_cmd_write          ( sys_cmd_write             ),
    .sys_cmd_addr           ( sys_cmd_addr              ),
    .sys_cmd_wdata          ( sys_cmd_wdata             ),
    .sys_cmd_wstrb          ( sys_cmd_wstrb             ),
    .sys_rsp_vld            ( sys_rsp_vld               ),
    .sys_rsp_rdy            ( sys_rsp_rdy               ),
    .sys_rsp_rdata          ( sys_rsp_rdata             ),
    .sys_rsp_err            ( sys_rsp_err               ),

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

    .icb_cmd_vld            ( ilm_cmd_vld               ),
    .icb_cmd_rdy            ( ilm_cmd_rdy               ),
    .icb_cmd_write          ( ilm_cmd_write             ),
    .icb_cmd_addr           ( ilm_cmd_addr              ),
    .icb_cmd_wdata          ( ilm_cmd_wdata             ),
    .icb_cmd_wstrb          ( ilm_cmd_wstrb             ),
    .icb_rsp_rdy            ( ilm_rsp_rdy               ),
    .icb_rsp_vld            ( ilm_rsp_vld               ),
    .icb_rsp_rdata          ( ilm_rsp_rdata             ),
    .icb_rsp_err            ( ilm_rsp_err               ),
        
    .ram_cs                 ( ilm_cs                    ),
    .ram_we                 ( ilm_we                    ),
    .ram_addr               ( ilm_addr                  ),
    .ram_wdata              ( ilm_wdata                 ),
    .ram_wem                ( ilm_wem                   ),
    .ram_rdata              ( ilm_rdata                 )
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

    .icb_cmd_vld            ( dlm_cmd_vld               ),
    .icb_cmd_rdy            ( dlm_cmd_rdy               ),
    .icb_cmd_write          ( dlm_cmd_write             ),
    .icb_cmd_addr           ( dlm_cmd_addr              ),
    .icb_cmd_wdata          ( dlm_cmd_wdata             ),
    .icb_cmd_wstrb          ( dlm_cmd_wstrb             ),
    .icb_rsp_rdy            ( dlm_rsp_rdy               ),
    .icb_rsp_vld            ( dlm_rsp_vld               ),
    .icb_rsp_rdata          ( dlm_rsp_rdata             ),
    .icb_rsp_err            ( dlm_rsp_err               ),
        
    .ram_cs                 ( dlm_cs                    ),
    .ram_we                 ( dlm_we                    ),
    .ram_addr               ( dlm_addr                  ),
    .ram_wdata              ( dlm_wdata                 ),
    .ram_wem                ( dlm_wem                   ),
    .ram_rdata              ( dlm_rdata                 )
);


// 系统总线，axi4
lnrv_icb2axi#
(
    .P_ADDR_WIDTH           ( 32                        ),
    .P_DATA_WIDTH           ( 32                        )
)
u_lnrv_icb2axi
(
    .icb_cmd_vld            ( sys_cmd_vld               ),
    .icb_cmd_rdy            ( sys_cmd_rdy               ),
    .icb_cmd_write          ( sys_cmd_write             ),
    .icb_cmd_addr           ( sys_cmd_addr              ),
    .icb_cmd_wdata          ( sys_cmd_wdata             ),
    .icb_cmd_wstrb          ( sys_cmd_wstrb             ),
    .icb_rsp_rdy            ( sys_rsp_rdy               ),
    .icb_rsp_vld            ( sys_rsp_vld               ),
    .icb_rsp_err            ( sys_rsp_err               ),
    .icb_rsp_rdata          ( sys_rsp_rdata             ),

    .axi_awvalid            ( sys_awvalid               ),
    .axi_awready            ( sys_awready               ),
    .axi_awlock             ( sys_awlock                ),
    .axi_awaddr             ( sys_awaddr                ),
    .axi_awid               ( sys_awid                  ),
    .axi_awlen              ( sys_awlen                 ),
    .axi_awsize             ( sys_awsize                ),
    .axi_awburst            ( sys_awburst               ),
    .axi_awcache            ( sys_awcache               ),
    .axi_awprot             ( sys_awprot                ),
    .axi_wvalid             ( sys_wvalid                ),
    .axi_wready             ( sys_wready                ),
    .axi_wdata              ( sys_wdata                 ),
    .axi_wstrb              ( sys_wstrb                 ),
    .axi_wlast              ( sys_wlast                 ),
    .axi_bready             ( sys_bready                ),
    .axi_bvalid             ( sys_bvalid                ),
    .axi_bresp              ( sys_bresp                 ),
    .axi_bid                ( sys_bid                   ),
    .axi_arvalid            ( sys_arvalid               ),
    .axi_arready            ( sys_arready               ),
    .axi_arlock             ( sys_arlock                ),
    .axi_awaddr             ( sys_awaddr                ),
    .axi_arid               ( sys_arid                  ),
    .axi_arlen              ( sys_arlen                 ),
    .axi_arsize             ( sys_arsize                ),
    .axi_arburst            ( sys_arburst               ),
    .axi_arcache            ( sys_arcache               ),
    .axi_arprot             ( sys_arprot                ),
    .axi_rready             ( sys_rready                ),
    .axi_rvalid             ( sys_rvalid                ),
    .axi_rdata              ( sys_rdata                 ),
    .axi_rresp              ( sys_rresp                 ),
    .axi_rlast              ( sys_rlast                 ),
    .axi_rid                ( sys_rid                   ),

    .clk                    ( clk                       ),
    .reset_n                ( reset_n                   )
);


lnrv_axi2icb#
(
    .P_ADDR_WIDTH           ( 32  ),
    .P_DATA_WIDTH           ( 32  )
)
u_lnrv_axi2icb
(
    .icb_cmd_vld            ( slv_cmd_vld               ),
    .icb_cmd_rdy            ( slv_cmd_rdy               ),
    .icb_cmd_write          ( slv_cmd_write             ),
    .icb_cmd_addr           ( slv_cmd_addr              ),
    .icb_cmd_wdata          ( slv_cmd_wdata             ),
    .icb_cmd_wstrb          ( slv_cmd_wstrb             ),
    .icb_rsp_rdy            ( slv_rsp_rdy               ),
    .icb_rsp_vld            ( slv_rsp_vld               ),
    .icb_rsp_err            ( slv_rsp_err               ),
    .icb_rsp_rdata          ( slv_rsp_rdata             ),

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