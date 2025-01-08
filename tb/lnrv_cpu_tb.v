module lnrv_cpu_tb;

`define PC_WRITE_TOHOST         32'h0000_007c
`define PC_EXT_IRQ_ISR          32'h0000_00a8
`define PC_SFT_IRQ_ISR          32'h0000_00c0
`define PC_TMR_IRQ_ISR          32'h0000_00d8
`define PC_POST_MTVEC_DONE      32'h0000_01b0


localparam                      LP_ILM_ADDR_WIDTH = 16;
localparam                      LP_ILM_SIZE = 2 ** LP_ILM_ADDR_WIDTH;
localparam                      LP_DLM_ADDR_WIDTH = 16;
localparam                      LP_DLM_SIZE = 2 ** LP_DLM_ADDR_WIDTH;

wire                            ilm_clk;
wire                            ilm_cs;
wire                            ilm_we;
wire[3 : 0]                     ilm_wem;
wire[LP_ILM_ADDR_WIDTH - 1 :0 ] ilm_addr;
wire[31 : 0]                    ilm_wdata;
wire[31 : 0]                    ilm_rdata;
wire                            dlm_clk;
wire                            dlm_cs;
wire                            dlm_we;
wire[3 : 0]                     dlm_wem;
wire[LP_DLM_ADDR_WIDTH - 1 :0 ] dlm_addr;
wire[31 : 0]                    dlm_wdata;
wire[31 : 0]                    dlm_rdata;

wire                            irq_sft;
wire                            irq_tmr;
reg                             irq_ext;
reg                             dbg_halt;
reg                             irq_dbg;
wire                            wfi_mode;

reg                             firmware_loading;

reg                             clk;
reg                             reset_n;

wire[31 : 0]                    gp;
wire[31 : 0]                    pc;
wire                            cmt_vld;
wire                            cmt_rdy;
wire                            cmt_hsked;

wire                            dcsr_stoptime;
wire                            dcsr_stopcount;

integer                         i;
reg                             fireware_load_cplt;
reg [31:0]                      pc_write_to_host_cnt;
reg [31:0]                      pc_write_to_host_cycle;
reg[8*300:1]                    testcase;

wire                            icb_cmd_vld_sys;
wire                            icb_cmd_rdy_sys;
wire                            icb_cmd_write_sys;
wire[31 : 0]                    icb_cmd_addr_sys;
wire[31 : 0]                    icb_cmd_wdata_sys;
wire[3 : 0]                     icb_cmd_wstrb_sys;
wire[2 : 0]                     icb_cmd_size_sys;
wire                            icb_rsp_vld_sys;
wire                            icb_rsp_rdy_sys;
wire[31 : 0]                    icb_rsp_rdata_sys;
wire                            icb_rsp_err_sys;


wire                            psel;
wire                            penable;
wire                            pwrite;
wire[31 : 0]                    paddr;
wire[31 : 0]                    pwdata;
wire[31 : 0]                    prdata;
wire                            pready;
wire                            pslverr;

reg                             tclk;
reg                             treset_n;


lnrv_cpu#(
    .P_ILM_REGION_BASE          ( 32'h0000_0000             ),
    .P_ILM_ADDR_WIDTH           ( LP_ILM_ADDR_WIDTH         ),
    .P_DLM_REGION_BASE          ( 32'h0002_0000             ),
    .P_DLM_ADDR_WIDTH           ( LP_DLM_ADDR_WIDTH         )
)
u_lnrv_cpu
(
    .reset_vector               ( 32'h0000_0000             ),
    .reset_mtvec                ( 32'd0                     ),

    .firmware_loading           ( firmware_loading          ),

    .irq_sft                    ( irq_sft                   ),
    .irq_tmr                    ( irq_tmr                   ),
    .irq_ext                    ( irq_ext                   ),
    .irq_dbg                    ( irq_dbg                   ),

    .dbg_halt                   ( dbg_halt                  ),
    .wfi_mode                   ( wfi_mode                  ),

    .dcsr_stoptime              ( dcsr_stoptime             ),
    .dcsr_stopcount             ( dcsr_stopcount            ),

    .icb_cmd_vld_sys            ( icb_cmd_vld_sys           ),
    .icb_cmd_rdy_sys            ( icb_cmd_rdy_sys           ),
    .icb_cmd_write_sys          ( icb_cmd_write_sys         ),
    .icb_cmd_addr_sys           ( icb_cmd_addr_sys          ),
    .icb_cmd_wdata_sys          ( icb_cmd_wdata_sys         ),
    .icb_cmd_wstrb_sys          ( icb_cmd_wstrb_sys         ),
    .icb_cmd_size_sys           ( icb_cmd_size_sys          ),
    .icb_rsp_vld_sys            ( icb_rsp_vld_sys           ),
    .icb_rsp_rdy_sys            ( icb_rsp_rdy_sys           ),
    .icb_rsp_rdata_sys          ( icb_rsp_rdata_sys         ),
    .icb_rsp_err_sys            ( icb_rsp_err_sys           ),

    .ilm_clk                    ( ilm_clk                   ),
    .ilm_cs                     ( ilm_cs                    ),
    .ilm_we                     ( ilm_we                    ),
    .ilm_wem                    ( ilm_wem                   ),
    .ilm_addr                   ( ilm_addr                  ),
    .ilm_wdata                  ( ilm_wdata                 ),
    .ilm_rdata                  ( ilm_rdata                 ),

    .dlm_clk                    ( dlm_clk                   ),
    .dlm_cs                     ( dlm_cs                    ),
    .dlm_we                     ( dlm_we                    ),
    .dlm_wem                    ( dlm_wem                   ),
    .dlm_addr                   ( dlm_addr                  ),
    .dlm_wdata                  ( dlm_wdata                 ),
    .dlm_rdata                  ( dlm_rdata                 ),

    .clk                        ( clk                       ),
    .reset_n                    ( reset_n                   )
);


// ilm
lnrv_gen_ram#
(
    .P_ADDR_WIDTH               ( LP_ILM_ADDR_WIDTH         ),
    .P_DATA_WIDTH               ( 32                        )
)
u_lnrv_ilm
(
    .ram_cs                     ( ilm_cs                    ),
    .ram_we                     ( ilm_we                    ),
    .ram_wem                    ( ilm_wem                   ),
    .ram_addr                   ( ilm_addr                  ),
    .ram_wdata                  ( ilm_wdata                 ),
    .ram_rdata                  ( ilm_rdata                 ),

    .clk                        ( clk                       )
);

// dlm
lnrv_gen_ram#
(
    .P_ADDR_WIDTH               ( LP_DLM_ADDR_WIDTH         ),
    .P_DATA_WIDTH               ( 32                        )
)
u_lnrv_dlm
(
    .ram_cs                     ( dlm_cs                    ),
    .ram_we                     ( dlm_we                    ),
    .ram_wem                    ( dlm_wem                   ),
    .ram_addr                   ( dlm_addr                  ),
    .ram_wdata                  ( dlm_wdata                 ),
    .ram_rdata                  ( dlm_rdata                 ),

    .clk                        ( clk                       )
);


lnrv_icb2apb#
(
    .P_ADDR_WIDTH               ( 32                        ),
    .P_DATA_WIDTH               ( 32                        ),
    .P_OTS_COUNT                ( 1                         )
)
u_lnrv_icb2apb
(
    .clk                        ( clk                       ),
    .reset_n                    ( reset_n                   ),

    .icb_cmd_vld                ( icb_cmd_vld_sys           ),
    .icb_cmd_rdy                ( icb_cmd_rdy_sys           ),
    .icb_cmd_write              ( icb_cmd_write_sys         ),
    .icb_cmd_addr               ( icb_cmd_addr_sys          ),
    .icb_cmd_wdata              ( icb_cmd_wdata_sys         ),
    .icb_cmd_wstrb              ( icb_cmd_wstrb_sys         ),
    .icb_cmd_size               ( icb_cmd_size_sys          ),
    .icb_rsp_rdy                ( icb_rsp_rdy_sys           ),
    .icb_rsp_vld                ( icb_rsp_vld_sys           ),
    .icb_rsp_err                ( icb_rsp_err_sys           ),
    .icb_rsp_rdata              ( icb_rsp_rdata_sys         ),

    .psel                       ( psel                      ),
    .penable                    ( penable                   ),
    .pwrite                     ( pwrite                    ),
    .paddr                      ( paddr                     ),
    .pwdata                     ( pwdata                    ),
    .prdata                     ( prdata                    ),
    .pslverr                    ( pslverr                   ),
    .pready                     ( pready                    )
);


lnrv_plmt u_lnrv_plmt
(
    .irq_tmr                    ( irq_tmr                   ),
    .irq_sft                    ( irq_sft                   ),

    .dcsr_stoptime              ( dcsr_stoptime             ),

    .pclk                       ( clk                       ),
    .preset_n                   ( reset_n                   ),
    .psel                       ( psel                      ),
    .penable                    ( penable                   ),
    .pwrite                     ( pwrite                    ),
    .paddr                      ( paddr[11 : 0]             ),
    .pwdata                     ( pwdata                    ),
    .prdata                     ( prdata                    ),
    .pslverr                    ( pslverr                   ),
    .pready                     ( pready                    ),

    .tclk                       ( tclk                      ),
    .treset_n                   ( treset_n                  )
);


assign      gp = u_lnrv_cpu.u_lnrv_core.u_lnrv_gpr.gp;
assign      pc = u_lnrv_cpu.u_lnrv_core.u_lnrv_cmt.idu_pc;
assign      cmt_vld = u_lnrv_cpu.u_lnrv_core.u_lnrv_cmt.cmt_vld;
assign      cmt_rdy = u_lnrv_cpu.u_lnrv_core.u_lnrv_cmt.cmt_rdy;
assign      cmt_hsked = cmt_vld & cmt_rdy;


always @(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        pc_write_to_host_cnt <= 32'b0;
    end else if (cmt_hsked & (pc == `PC_WRITE_TOHOST)) begin
        pc_write_to_host_cnt <= pc_write_to_host_cnt + 1'b1;
    end
end

initial begin
    clk = 1'b0;
    reset_n = 1'b0;

    #100;
    @(posedge clk) begin
        reset_n <= 1'b1;
    end

    wait(firmware_loading == 1'b0);
    // force u_lnrv_cpu.u_lnrv_core.u_lnrv_csr.mstatus_mie = 1'b0;

    @(pc_write_to_host_cnt == 32'd8) #10 reset_n <=1;
    #40000000;
    $finish;
end

always #10 clk = ~clk;


initial begin
    tclk = 1'b0;
    treset_n = 1'b0;

    #100;
    @(posedge tclk) begin
        treset_n <= 1'b1;
    end
end

always #1525.8789 tclk = ~tclk;


initial begin
    wait(pc == `PC_POST_MTVEC_DONE ); // Wait the program goes out the reset_vector program
    wait(wfi_mode == 1'b1);
    #100;
    forever begin
        repeat ($urandom_range(1, 1000)) @(posedge clk) irq_ext = 1'b0; // Wait random times
        @(posedge clk) irq_ext = 1'b1;
        wait(pc == `PC_EXT_IRQ_ISR); // Wait the program run into the IRQ handler by check PC values
        @(posedge clk) irq_ext = 1'b0;
        // if(stop_assert_irq) begin
        //     break;
        // end
    end
end

// initial begin
//     #100
//     wait(pc == `PC_POST_MTVEC_DONE ); // Wait the program goes out the reset_vector program
//     #100;
//     forever begin
//         repeat ($urandom_range(1, 1000)) @(posedge clk) irq_sft = 1'b0; // Wait random times
//         @(posedge clk) irq_sft = 1'b1;
//         wait(pc == `PC_SFT_IRQ_ISR); // Wait the program run into the IRQ handler by check PC values
//         @(posedge clk) irq_sft = 1'b0;
//         // if(stop_assert_irq) begin
//         //     break;
//         // end
//     end
// end

// initial begin
//     #100
//     wait(pc == `PC_POST_MTVEC_DONE ); // Wait the program goes out the reset_vector program
//     #100;
//     forever begin
//         repeat ($urandom_range(1, 1000)) @(posedge clk) irq_tmr = 1'b0; // Wait random times
//         @(posedge clk) irq_tmr = 1'b1;
//         wait(pc == `PC_TMR_IRQ_ISR); // Wait the program run into the IRQ handler by check PC values
//         @(posedge clk) irq_tmr = 1'b0;
//         // if(stop_assert_irq) begin
//         //     break;
//         // end
//     end
// end


integer dumpwave;
initial begin
    if($value$plusargs("DUMPWAVE=%d",dumpwave)) begin
      if(dumpwave != 0) begin

        $display("VCS used");
        $fsdbDumpfile("lnrv_cpu_tb.fsdb");
        $fsdbDumpvars(0, lnrv_cpu_tb, "+mda");

	//  `ifdef iverilog
    //         $display("iverlog used");
	//     $dumpfile("tb_top.vcd");
    //         $dumpvars(0, tb_top);
    //      `endif
      end
    end
end


initial begin
    $display("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
    if($value$plusargs("TEST_CASE=%s",testcase))begin
        $display("TEST_CASE=%s",testcase);
    end

    wait(pc_write_to_host_cnt == 32'd8) #10 reset_n <= 1'b0;

    $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
    $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
    $display("~~~~~~~~~~~~~ Test Result Summary ~~~~~~~~~~~~~~~~~~~~~~");
    $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
    $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
    // $display("~TEST_CASE: %s ~~~~~~~~~~~~~", testcase);
    // $display("~~~~~~~~~~~~~~Total cycle_count value: %d ~~~~~~~~~~~~~", cycle_count);
    // $display("~~~~~~~~~~The valid Instruction Count: %d ~~~~~~~~~~~~~", valid_ir_cycle);
    // $display("~~~~~The test ending reached at cycle: %d ~~~~~~~~~~~~~", pc_write_to_host_cycle);
    $display("~~~~~~~~~~~~~~~The final gp Reg value:%d ~~~~~~~~~~~~~", gp);
    $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
    if (gp == 1) begin
        $display("~~~~~~~~~~~~~~~~ TEST_PASS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        $display("~~~~~~~~~ #####     ##     ####    #### ~~~~~~~~~~~~~~~~");
        $display("~~~~~~~~~ #    #   #  #   #       #     ~~~~~~~~~~~~~~~~");
        $display("~~~~~~~~~ #    #  #    #   ####    #### ~~~~~~~~~~~~~~~~");
        $display("~~~~~~~~~ #####   ######       #       #~~~~~~~~~~~~~~~~");
        $display("~~~~~~~~~ #       #    #  #    #  #    #~~~~~~~~~~~~~~~~");
        $display("~~~~~~~~~ #       #    #   ####    #### ~~~~~~~~~~~~~~~~");
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
    end
    else begin
        $display("~~~~~~~~~~~~~~~~ TEST_FAIL ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        $display("~~~~~~~~~~######    ##       #    #     ~~~~~~~~~~~~~~~~");
        $display("~~~~~~~~~~#        #  #      #    #     ~~~~~~~~~~~~~~~~");
        $display("~~~~~~~~~~#####   #    #     #    #     ~~~~~~~~~~~~~~~~");
        $display("~~~~~~~~~~#       ######     #    #     ~~~~~~~~~~~~~~~~");
        $display("~~~~~~~~~~#       #    #     #    #     ~~~~~~~~~~~~~~~~");
        $display("~~~~~~~~~~#       #    #     #    ######~~~~~~~~~~~~~~~~");
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
    end
    #10
    $finish;
end

initial begin
    irq_ext = 1'b0;
    dbg_halt = 1'b0;
    irq_dbg = 1'b0;

    // if($value$plusargs("TEST_CASE=%s",testcase))begin
    //   $display("TEST_CASE=%s",testcase);
    // end
end

//   integer i;

integer bin;

reg [7:0] itcm_mem [0 : (LP_ILM_SIZE * 8)-1];
initial begin
    firmware_loading = 1'b1;

    $readmemh({testcase, ".verilog"}, itcm_mem);
    // $readmemh("../simulation/riscv-compliance/build_generated/rv32Zicsr/I-CSRRC-01.elf.bin", itcm_mem);
    // F:\CPU\lnrsv\simulation\riscv-compliance\build_generated\rv32Zicsr\I-CSRRC-01.elf.bin

    // bin = $fopen("../simulation/riscv-compliance/build_generated/rv32Zicsr/I-CSRRC-01.elf.bin", "rb");
    wait(reset_n == 1'b1);
    for (i=0;i<LP_ILM_SIZE;i=i+1) begin
        u_lnrv_ilm.mem_q[i][7 : 0] = itcm_mem[i * 4 + 0];
        u_lnrv_ilm.mem_q[i][15 : 8] = itcm_mem[i * 4 + 1];
        u_lnrv_ilm.mem_q[i][23 : 16] = itcm_mem[i * 4 + 2];
        u_lnrv_ilm.mem_q[i][31 : 24] = itcm_mem[i * 4 + 3];
    end

    for (i=0;i<LP_DLM_SIZE;i=i+1) begin
        u_lnrv_dlm.mem_q[i][7 : 0] = 0;
        u_lnrv_dlm.mem_q[i][15 : 8] = 0;
        u_lnrv_dlm.mem_q[i][23 : 16] = 0;
        u_lnrv_dlm.mem_q[i][31 : 24] = 0;
    end

    // for (i=0;i<100;i=i+1) begin
    //      $display("ilm mem[%d]: %x", i, u_lnrv_ilm.mem_q[i]);
    // end
    #1000;
    @(posedge clk) begin
        firmware_loading <= 1'b0;
    end

    $display("ITCM 0x00: %h", u_lnrv_ilm.mem_q[8'h00]);
    $display("ITCM 0x01: %h", u_lnrv_ilm.mem_q[8'h01]);
    $display("ITCM 0x02: %h", u_lnrv_ilm.mem_q[8'h02]);
    $display("ITCM 0x03: %h", u_lnrv_ilm.mem_q[8'h03]);
    $display("ITCM 0x04: %h", u_lnrv_ilm.mem_q[8'h04]);
    $display("ITCM 0x05: %h", u_lnrv_ilm.mem_q[8'h05]);
    $display("ITCM 0x06: %h", u_lnrv_ilm.mem_q[8'h06]);
    $display("ITCM 0x07: %h", u_lnrv_ilm.mem_q[8'h07]);
    $display("ITCM 0x16: %h", u_lnrv_ilm.mem_q[8'h16]);
    $display("ITCM 0x20: %h", u_lnrv_ilm.mem_q[8'h20]);

end

endmodule //lnrv_cpu_tb
