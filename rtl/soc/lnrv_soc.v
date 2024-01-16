module	lnrv_soc
(

);


// outports wire
wire                        	wfi_mode;
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

lnrv_cpu u_lnrv_cpu#(
	.P_ILM_REGION_BASE 	( 32'h0000_0000  ),
	.P_ILM_ADDR_WIDTH  	( 17             ),
	.P_DLM_REGION_BASE 	( 32'h0002_0000  ),
	.P_DLM_ADDR_WIDTH  	( 17             )
)
(
    .sft_irq            ( sft_irq    ),
    .tmr_irq            ( tmr_irq    ),
    .ext_irq            ( ext_irq    ),
    .dbg_halt           ( dbg_halt   ),
    .dbg_irq            ( dbg_irq    ),
    .wfi_mode           ( wfi_mode   ),
    .ilm_clk            ( ilm_clk    ),
    .ilm_cs             ( ilm_cs     ),
    .ilm_we             ( ilm_we     ),
    .ilm_wem            ( ilm_wem    ),
    .ilm_addr           ( ilm_addr   ),
    .ilm_wdata          ( ilm_wdata  ),
    .ilm_rdata          ( ilm_rdata  ),
    .dlm_clk            ( dlm_clk    ),
    .dlm_cs             ( dlm_cs     ),
    .dlm_we             ( dlm_we     ),
    .dlm_wem            ( dlm_wem    ),
    .dlm_addr           ( dlm_addr   ),
    .dlm_wdata          ( dlm_wdata  ),
    .dlm_rdata          ( dlm_rdata  ),
    .clk                ( clk        ),
    .reset_n            ( reset_n    )
);


endmodule