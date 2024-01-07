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

    output                                  wfi_mode,

    // output                                  sys_awvalid,
    // input                                   sys_awready,
    // output[3 : 0]                           sys_awid,
    // output[31 : 0]                          sys_awaddr,
    // output[7 : 0]                           sys_awlen,
    // output[2 : 0]                           sys_awsize,
    // output[2 : 0]                           sys_awburst,
    // output                                  sys_awlock,
    // output[3 : 0]                           sys_awcache,
    // out

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

    .lsu_cmd_vld            ( exu_cmd_vld               ),
    .lsu_cmd_rdy            ( exu_cmd_rdy               ),
    .lsu_cmd_write          ( exu_cmd_write             ),
    .lsu_cmd_addr           ( exu_cmd_addr              ),
    .lsu_cmd_wdata          ( exu_cmd_wdata             ),
    .lsu_cmd_wstrb          ( exu_cmd_wstrb             ),
    .lsu_rsp_vld            ( exu_rsp_vld               ),
    .lsu_rsp_rdy            ( exu_rsp_rdy               ),
    .lsu_rsp_rdata          ( exu_rsp_rdata             ),
    .lsu_rsp_err            ( exu_rsp_err               ),
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


lnrv_icb2sram#
(
    .P_ICB_ADDR_WIDTH       ( 32                        ),
    .P_RAM_ADDR_WIDTH       ( 20                        ),
    .P_DATA_WIDTH           ( 32                        )
)               
u_sys_ram_ctrl              
(               
    .clk                    ( clk                       ),
    .reset_n                ( reset_n                   ),

    .icb_cmd_vld            ( sys_cmd_vld               ),
    .icb_cmd_rdy            ( sys_cmd_rdy               ),
    .icb_cmd_write          ( sys_cmd_write             ),
    .icb_cmd_addr           ( sys_cmd_addr              ),
    .icb_cmd_wdata          ( sys_cmd_wdata             ),
    .icb_cmd_wstrb          ( sys_cmd_wstrb             ),
    .icb_rsp_rdy            ( sys_rsp_rdy               ),
    .icb_rsp_vld            ( sys_rsp_vld               ),
    .icb_rsp_rdata          ( sys_rsp_rdata             ),
    .icb_rsp_err            ( sys_rsp_err               ),
        
    .ram_cs                 ( sys_cs                    ),
    .ram_we                 ( sys_we                    ),
    .ram_addr               ( sys_addr                  ),
    .ram_wdata              ( sys_wdata                 ),
    .ram_wem                ( sys_wem                   ),
    .ram_rdata              ( sys_rdata                 )
);


lnrv_gen_ram#
(
    .P_ADDR_WIDTH       ( 20                    ),
    .P_DATA_WIDTH       ( 32                    )
)
u_sys_ram
(
    .ram_cs             ( sys_cs                ),
    .ram_we             ( sys_we                ),
    .ram_wem            ( sys_wem               ),
    .ram_addr           ( sys_addr              ),
    .ram_wdata          ( sys_wdata             ),
    .ram_rdata          ( sys_rdata             ),

    .clk                ( clk                   )
);

endmodule