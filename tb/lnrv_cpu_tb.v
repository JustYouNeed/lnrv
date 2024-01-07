module lnrv_cpu_tb; 


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

reg                             sft_irq;
reg                             tmr_irq;
reg                             ext_irq;
reg                             dbg_halt;
reg                             dbg_irq;
wire                            wfi_mode;

reg                             clk;
reg                             reset_n;

lnrv_cpu#(
    .P_ILM_REGION_BASE  ( 32'h0000_0000         ),
    .P_ILM_ADDR_WIDTH   ( LP_ILM_ADDR_WIDTH     ),
    .P_DLM_REGION_BASE  ( 32'h0002_0000         ),
    .P_DLM_ADDR_WIDTH   ( LP_DLM_ADDR_WIDTH     )
)
u_lnrv_cpu
(
    .reset_vector       ( 32'h0000_0000         ),

    .sft_irq            ( sft_irq               ),
    .tmr_irq            ( tmr_irq               ),
    .ext_irq            ( ext_irq               ),
    .dbg_halt           ( dbg_halt              ),
    .dbg_irq            ( dbg_irq               ),
    .wfi_mode           ( wfi_mode              ),

    .ilm_clk            ( ilm_clk               ),
    .ilm_cs             ( ilm_cs                ),
    .ilm_we             ( ilm_we                ),
    .ilm_wem            ( ilm_wem               ),
    .ilm_addr           ( ilm_addr              ),
    .ilm_wdata          ( ilm_wdata             ),
    .ilm_rdata          ( ilm_rdata             ),

    .dlm_clk            ( dlm_clk               ),
    .dlm_cs             ( dlm_cs                ),
    .dlm_we             ( dlm_we                ),
    .dlm_wem            ( dlm_wem               ),
    .dlm_addr           ( dlm_addr              ),
    .dlm_wdata          ( dlm_wdata             ),
    .dlm_rdata          ( dlm_rdata             ),

    .clk                ( clk                   ),
    .reset_n            ( reset_n               )
);


// ilm
lnrv_gen_ram#
(
    .P_ADDR_WIDTH       ( LP_ILM_ADDR_WIDTH     ),
    .P_DATA_WIDTH       ( 32                    )
)
u_lnrv_ilm
(
    .ram_cs             ( ilm_cs                ),
    .ram_we             ( ilm_we                ),
    .ram_wem            ( ilm_wem               ),
    .ram_addr           ( ilm_addr              ),
    .ram_wdata          ( ilm_wdata             ),
    .ram_rdata          ( ilm_rdata             ),

    .clk                ( clk                   )
);

// dlm
lnrv_gen_ram#
(
    .P_ADDR_WIDTH       ( LP_DLM_ADDR_WIDTH     ),
    .P_DATA_WIDTH       ( 32                    )
)
u_lnrv_dlm
(
    .ram_cs             ( dlm_cs                ),
    .ram_we             ( dlm_we                ),
    .ram_wem            ( dlm_wem               ),
    .ram_addr           ( dlm_addr              ),
    .ram_wdata          ( dlm_wdata             ),
    .ram_rdata          ( dlm_rdata             ),

    .clk                ( clk                   )
);


integer         i;

// initial begin
//     for(i = 0; i < 2 << 20; i = i + 1) begin
//         u_lnrv_cpu.u_sys_ram.mem_q[i] = i;
//     end
// end

reg         fireware_load_cplt;

initial begin
    clk = 1'b0;
    reset_n = 1'b0;

    wait(fireware_load_cplt == 1'b1);
    #100;
    @(negedge clk) begin
        reset_n <= 1'b1;
    end

    #200000;
    $finish;
end

initial begin            
    $dumpfile("wave.vcd");        //生成的vcd文件名称
    $dumpvars(0, lnrv_cpu_tb);    //tb模块名称
end

always #10 clk = ~clk;

initial begin
    wait(u_lnrv_cpu.u_lnrv_core.u_lnrv_gpr.s10 == 32'b1)   // wait sim end, when x26 == 1
    #1000;
    if (u_lnrv_cpu.u_lnrv_core.u_lnrv_gpr.s11 == 32'b1) begin
        $display("~~~~~~~~~~~~~~~~~~~ TEST_PASS ~~~~~~~~~~~~~~~~~~~");
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        $display("~~~~~~~~~ #####     ##     ####    #### ~~~~~~~~~");
        $display("~~~~~~~~~ #    #   #  #   #       #     ~~~~~~~~~");
        $display("~~~~~~~~~ #    #  #    #   ####    #### ~~~~~~~~~");
        $display("~~~~~~~~~ #####   ######       #       #~~~~~~~~~");
        $display("~~~~~~~~~ #       #    #  #    #  #    #~~~~~~~~~");
        $display("~~~~~~~~~ #       #    #   ####    #### ~~~~~~~~~");
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        $finish;
    end else begin
        $display("~~~~~~~~~~~~~~~~~~~ TEST_FAIL ~~~~~~~~~~~~~~~~~~~~");
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        $display("~~~~~~~~~~######    ##       #    #     ~~~~~~~~~~");
        $display("~~~~~~~~~~#        #  #      #    #     ~~~~~~~~~~");
        $display("~~~~~~~~~~#####   #    #     #    #     ~~~~~~~~~~");
        $display("~~~~~~~~~~#       ######     #    #     ~~~~~~~~~~");
        $display("~~~~~~~~~~#       #    #     #    #     ~~~~~~~~~~");
        $display("~~~~~~~~~~#       #    #     #    ######~~~~~~~~~~");
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        $display("fail testnum = %2d", u_lnrv_cpu.u_lnrv_core.u_lnrv_gpr.gp);
        for (i = 0; i < 32; i = i + 1)
            $display("x%2d = 0x%x", i, u_lnrv_cpu.u_lnrv_core.u_lnrv_gpr.gpr_q[i]);

        $finish;
    end
end
reg[8*300:1] testcase;

initial begin
    sft_irq = 1'b0;
    tmr_irq = 1'b0;
    ext_irq = 1'b0;
    dbg_halt = 1'b0;
    dbg_irq = 1'b0;

    if($value$plusargs("TESTCASE=%s",testcase))begin
      $display("TESTCASE=%s",testcase);
    end
end

//   integer i;

integer bin;

reg [7:0] itcm_mem [0 : (LP_ILM_SIZE * 8)-1];
initial begin
    fireware_load_cplt = 1'b0;
    
    // $readmemh("../simulation/isa/generated/rv32ui-p-lb.verilog", itcm_mem);
    // $readmemh("../simulation/riscv-compliance/build_generated/rv32Zicsr/I-CSRRC-01.elf.bin", itcm_mem);
    // F:\CPU\lnrsv\simulation\riscv-compliance\build_generated\rv32Zicsr\I-CSRRC-01.elf.bin

    bin = $fopen("../simulation/riscv-compliance/build_generated/rv32Zicsr/I-CSRRC-01.elf.bin", "rb");

    while(!$feof(bin)) begin
        for (i=0;i<LP_ILM_SIZE;i=i+1) begin
            u_lnrv_ilm.mem_q[i][7 : 0] = $fgetc(bin);
            u_lnrv_ilm.mem_q[i][15 : 8] = $fgetc(bin);
            u_lnrv_ilm.mem_q[i][23 : 16] = $fgetc(bin);
            u_lnrv_ilm.mem_q[i][31 : 24] = $fgetc(bin);
        end
    end

    for (i=0;i<100;i=i+1) begin
         $display("ilm mem[%d]: %x", i, u_lnrv_ilm.mem_q[i]);
    end
    @(posedge clk) begin
        fireware_load_cplt <= 1'b1;
    end

        // $display("ITCM 0x00: %h", `ITCM.mem_r[8'h00]);
        // $display("ITCM 0x01: %h", `ITCM.mem_r[8'h01]);
        // $display("ITCM 0x02: %h", `ITCM.mem_r[8'h02]);
        // $display("ITCM 0x03: %h", `ITCM.mem_r[8'h03]);
        // $display("ITCM 0x04: %h", `ITCM.mem_r[8'h04]);
        // $display("ITCM 0x05: %h", `ITCM.mem_r[8'h05]);
        // $display("ITCM 0x06: %h", `ITCM.mem_r[8'h06]);
        // $display("ITCM 0x07: %h", `ITCM.mem_r[8'h07]);
        // $display("ITCM 0x16: %h", `ITCM.mem_r[8'h16]);
        // $display("ITCM 0x20: %h", `ITCM.mem_r[8'h20]);

end 

endmodule //lnrv_cpu_tb
