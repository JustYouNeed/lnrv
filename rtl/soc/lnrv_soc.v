module	lnrv_soc
(
    input                       clk,
    input                       reset_n
);

// outports wire
wire                        	wfi_mode;
wire                        	stop_time;
wire                        	stop_count;
wire                        	sys_awvalid;
wire                        	sys_awlock;
wire [31:0]                 	sys_awaddr;
wire [3:0]                  	sys_awid;
wire [7:0]                  	sys_awlen;
wire [2:0]                  	sys_awsize;
wire [1:0]                  	sys_awburst;
wire [3:0]                  	sys_awcache;
wire [2:0]                  	sys_awprot;
wire                        	sys_wvalid;
wire [31:0]                 	sys_wdata;
wire [3:0]                  	sys_wstrb;
wire                        	sys_wlast;
wire                        	sys_bready;
wire                        	sys_arvalid;
wire                        	sys_arlock;
wire [31:0]                 	sys_araddr;
wire [3:0]                  	sys_arid;
wire [7:0]                  	sys_arlen;
wire [2:0]                  	sys_arsize;
wire [1:0]                  	sys_arburst;
wire [3:0]                  	sys_arcache;
wire [2:0]                  	sys_arprot;
wire                        	sys_rready;
wire                        	slv_awready;
wire                        	slv_wready;
wire                        	slv_bvalid;
wire [1:0]                  	slv_bresp;
wire [3:0]                  	slv_bid;
wire                        	slv_arready;
wire                        	slv_rvalid;
wire [31:0]                 	slv_rdata;
wire [1:0]                  	slv_rresp;
wire                        	slv_rlast;
wire [3:0]                  	slv_rid;
wire                        	ilm_clk;
wire                        	ilm_cs;
wire                        	ilm_we;
wire [3:0]                  	ilm_wem;
wire [P_ILM_ADDR_WIDTH-1:0] 	ilm_addr;
wire [31:0]                 	ilm_wdata;
wire                        	dlm_clk;
wire                        	dlm_cs;
wire                        	dlm_we;
wire [3:0]                  	dlm_wem;
wire [P_DLM_ADDR_WIDTH-1:0] 	dlm_addr;
wire [31:0]                 	dlm_wdata;

lnrv_cpu#
(
    .P_ILM_REGION_BASE      ( 32'h0000_0000             ),
    .P_ILM_ADDR_WIDTH       ( 17                        ),
    .P_DLM_REGION_BASE      ( 32'h0002_0000             ),
    .P_DLM_ADDR_WIDTH       ( 17                        )
)
u_lnrv_cpu
(
    .reset_vector           ( 32'd0                     ),
    .reset_mtvec            ( 32'h0000_0000             ),

    .irq_sft                ( irq_sft                   ),
    .irq_tmr                ( irq_tmr                   ),
    .irq_ext                ( irq_ext                   ),

    .dbg_halt               ( dbg_halt                  ),
    .irq_dbg                ( irq_dbg                   ),

    .wfi_mode               ( wfi_mode                  ),

    .stop_time              ( stop_time                 ),
    .stop_count             ( stop_count                ),

    .dlod_mode              ( dlod_mode                 ),

    .sys_awvalid            ( sys_awvalid               ),
    .sys_awready            ( sys_awready               ),
    .sys_awlock             ( sys_awlock                ),
    .sys_awaddr             ( sys_awaddr                ),
    .sys_awid               ( sys_awid                  ),
    .sys_awlen              ( sys_awlen                 ),
    .sys_awsize             ( sys_awsize                ),
    .sys_awburst            ( sys_awburst               ),
    .sys_awcache            ( sys_awcache               ),
    .sys_awprot             ( sys_awprot                ),
    .sys_wvalid             ( sys_wvalid                ),
    .sys_wready             ( sys_wready                ),
    .sys_wdata              ( sys_wdata                 ),
    .sys_wstrb              ( sys_wstrb                 ),
    .sys_wlast              ( sys_wlast                 ),
    .sys_bready             ( sys_bready                ),
    .sys_bvalid             ( sys_bvalid                ),
    .sys_bresp              ( sys_bresp                 ),
    .sys_bid                ( sys_bid                   ),
    .sys_arvalid            ( sys_arvalid               ),
    .sys_arready            ( sys_arready               ),
    .sys_arlock             ( sys_arlock                ),
    .sys_araddr             ( sys_araddr                ),
    .sys_arid               ( sys_arid                  ),
    .sys_arlen              ( sys_arlen                 ),
    .sys_arsize             ( sys_arsize                ),
    .sys_arburst            ( sys_arburst               ),
    .sys_arcache            ( sys_arcache               ),
    .sys_arprot             ( sys_arprot                ),
    .sys_rready             ( sys_rready                ),
    .sys_rvalid             ( sys_rvalid                ),
    .sys_rdata              ( sys_rdata                 ),
    .sys_rresp              ( sys_rresp                 ),
    .sys_rlast              ( sys_rlast                 ),
    .sys_rid                ( sys_rid                   ),

    .slv_awvalid            ( slv_awvalid               ),
    .slv_awready            ( slv_awready               ),
    .slv_awlock             ( slv_awlock                ),
    .slv_awaddr             ( slv_awaddr                ),
    .slv_awid               ( slv_awid                  ),
    .slv_awlen              ( slv_awlen                 ),
    .slv_awsize             ( slv_awsize                ),
    .slv_awburst            ( slv_awburst               ),
    .slv_awcache            ( slv_awcache               ),
    .slv_awprot             ( slv_awprot                ),
    .slv_wvalid             ( slv_wvalid                ),
    .slv_wready             ( slv_wready                ),
    .slv_wdata              ( slv_wdata                 ),
    .slv_wstrb              ( slv_wstrb                 ),
    .slv_wlast              ( slv_wlast                 ),
    .slv_bready             ( slv_bready                ),
    .slv_bvalid             ( slv_bvalid                ),
    .slv_bresp              ( slv_bresp                 ),
    .slv_bid                ( slv_bid                   ),
    .slv_arvalid            ( slv_arvalid               ),
    .slv_arready            ( slv_arready               ),
    .slv_arlock             ( slv_arlock                ),
    .slv_araddr             ( slv_araddr                ),
    .slv_arid               ( slv_arid                  ),
    .slv_arlen              ( slv_arlen                 ),
    .slv_arsize             ( slv_arsize                ),
    .slv_arburst            ( slv_arburst               ),
    .slv_arcache            ( slv_arcache               ),
    .slv_arprot             ( slv_arprot                ),
    .slv_rready             ( slv_rready                ),
    .slv_rvalid             ( slv_rvalid                ),
    .slv_rdata              ( slv_rdata                 ),
    .slv_rresp              ( slv_rresp                 ),
    .slv_rlast              ( slv_rlast                 ),
    .slv_rid                ( slv_rid                   ),

    .ilm_clk                ( ilm_clk                   ),
    .ilm_cs                 ( ilm_cs                    ),
    .ilm_we                 ( ilm_we                    ),
    .ilm_wem                ( ilm_wem                   ),
    .ilm_addr               ( ilm_addr                  ),
    .ilm_wdata              ( ilm_wdata                 ),
    .ilm_rdata              ( ilm_rdata                 ),

    .dlm_clk                ( dlm_clk                   ),
    .dlm_cs                 ( dlm_cs                    ),
    .dlm_we                 ( dlm_we                    ),
    .dlm_wem                ( dlm_wem                   ),
    .dlm_addr               ( dlm_addr                  ),
    .dlm_wdata              ( dlm_wdata                 ),
    .dlm_rdata              ( dlm_rdata                 ),

    .clk                    ( clk                       ),
    .reset_n                ( reset_n                   )
);


// ilm
lnrv_gen_ram#
(
    .P_ADDR_WIDTH           ( LP_ILM_ADDR_WIDTH         ),
    .P_DATA_WIDTH           ( 32                        )
)
u_lnrv_ilm
(
    .ram_cs                 ( ilm_cs                    ),
    .ram_we                 ( ilm_we                    ),
    .ram_wem                ( ilm_wem                   ),
    .ram_addr               ( ilm_addr                  ),
    .ram_wdata              ( ilm_wdata                 ),
    .ram_rdata              ( ilm_rdata                 ),

    .clk                    ( clk                       )
);


// dlm
lnrv_gen_ram#
(
    .P_ADDR_WIDTH           ( LP_DLM_ADDR_WIDTH         ),
    .P_DATA_WIDTH           ( 32                        )
)
u_lnrv_dlm
(
    .ram_cs                 ( dlm_cs                    ),
    .ram_we                 ( dlm_we                    ),
    .ram_wem                ( dlm_wem                   ),
    .ram_addr               ( dlm_addr                  ),
    .ram_wdata              ( dlm_wdata                 ),
    .ram_rdata              ( dlm_rdata                 ),

    .clk                    ( clk                       )
);

endmodule