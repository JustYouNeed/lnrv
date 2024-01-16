module lnrv_icb_demux_tb;

localparam                          LP_ILM_BASE = 32'h0000_0000;
localparam                          LP_ILM_SIZE = 32'h20000;
localparam                          LP_ILM_END = LP_ILM_BASE + LP_ILM_SIZE;
localparam                          LP_ILM_ADDR_WIDTH = $clog2(LP_ILM_SIZE / 8);

localparam                          LP_DLM_BASE = 32'h0002_0000;
localparam                          LP_DLM_SIZE = 32'h20000;
localparam                          LP_DLM_END = LP_DLM_BASE + LP_DLM_SIZE;
localparam                          LP_DLM_ADDR_WIDTH = $clog2(LP_DLM_SIZE / 8);

localparam                          LP_ADDR_WIDTH = 32;
localparam                          LP_DATA_WIDTH = 32;

reg                                 m_icb_cmd_vld;
wire                                m_icb_cmd_rdy;
reg                                 m_icb_cmd_write;
reg[LP_ADDR_WIDTH - 1 : 0]          m_icb_cmd_addr;
reg[LP_DATA_WIDTH - 1 : 0]          m_icb_cmd_wdata;
reg[(LP_DATA_WIDTH/8) - 1 : 0]      m_icb_cmd_wstrb;
reg                                 m_icb_rsp_rdy;
wire                                m_icb_rsp_vld;
wire[LP_DATA_WIDTH - 1 : 0]         m_icb_rsp_rdata;
wire                                m_icb_rsp_err;



wire[2 : 0]                         sn_icb_cmd_vld;
wire[2 : 0]                         sn_icb_cmd_rdy;
wire[2 : 0]                         sn_icb_cmd_write;
wire[(LP_ADDR_WIDTH * 3) - 1 : 0]    sn_icb_cmd_addr;
wire[(LP_DATA_WIDTH * 3) - 1 : 0]   sn_icb_cmd_wdata;
wire[(3*(LP_DATA_WIDTH/8)) - 1 : 0] sn_icb_cmd_wstrb;
wire[2 : 0]                         sn_icb_rsp_vld;
wire[2 : 0]                         sn_icb_rsp_rdy;
wire[(LP_DATA_WIDTH * 3) - 1 : 0]   sn_icb_rsp_rdata;
wire[2 : 0]                         sn_icb_rsp_err;
wire[(LP_ADDR_WIDTH * 3) - 1 : 0]    sn_region_base;
wire[(LP_ADDR_WIDTH * 3) - 1 : 0]    sn_region_end;


// ilm总线
wire                                ilm_cmd_vld;
wire                                ilm_cmd_rdy;
wire                                ilm_cmd_write;
wire[LP_ADDR_WIDTH - 1 : 0]          ilm_cmd_addr;
wire[LP_DATA_WIDTH - 1 : 0]         ilm_cmd_wdata;
wire[(LP_DATA_WIDTH/8) - 1 : 0]     ilm_cmd_wstrb;
wire                                ilm_rsp_vld;
wire                                ilm_rsp_rdy;
wire[LP_DATA_WIDTH - 1 : 0]         ilm_rsp_rdata;
wire                                ilm_rsp_err;


wire                                dlm_cmd_vld;
wire                                dlm_cmd_rdy;
wire                                dlm_cmd_write;
wire[LP_ADDR_WIDTH - 1 : 0]          dlm_cmd_addr;
wire[LP_DATA_WIDTH - 1 : 0]         dlm_cmd_wdata;
wire[(LP_DATA_WIDTH/8) - 1 : 0]     dlm_cmd_wstrb;
wire                                dlm_rsp_vld;
wire                                dlm_rsp_rdy;
wire[LP_DATA_WIDTH - 1 : 0]         dlm_rsp_rdata;
wire                                dlm_rsp_err;


wire                                sys_cmd_vld;
reg                                 sys_cmd_rdy;
wire                                sys_cmd_write;
wire[LP_ADDR_WIDTH - 1 : 0]         sys_cmd_addr;
wire[LP_DATA_WIDTH - 1 : 0]         sys_cmd_wdata;
wire[(LP_DATA_WIDTH/8) - 1 : 0]     sys_cmd_wstrb;
reg                                 sys_rsp_vld;
wire                                sys_rsp_rdy;
reg[LP_DATA_WIDTH - 1 : 0]          sys_rsp_rdata;
reg                                 sys_rsp_err;


wire                                dlm_cs;
wire                                dlm_we;
wire[(LP_DATA_WIDTH/8) - 1 : 0]     dlm_wem;
wire[LP_DLM_ADDR_WIDTH - 3 : 0]      dlm_addr;
wire[LP_DATA_WIDTH - 1 : 0]         dlm_wdata;
wire[LP_DATA_WIDTH - 1 : 0]         dlm_rdata;


wire                                ilm_cs;
wire                                ilm_we;
wire[(LP_DATA_WIDTH/8) - 1 : 0]     ilm_wem;
wire[LP_DLM_ADDR_WIDTH - 3 : 0]      ilm_addr;
wire[LP_DATA_WIDTH - 1 : 0]         ilm_wdata;
wire[LP_DATA_WIDTH - 1 : 0]         ilm_rdata;


reg                                 clk;
reg                                 reset_n;

assign      sn_region_base = {32'd0, LP_ILM_BASE, LP_DLM_BASE};
assign      sn_region_end = {32'd0, LP_ILM_END, LP_DLM_END};

assign      sn_icb_cmd_rdy = {
                                sys_cmd_rdy,
                                ilm_cmd_rdy,
                                dlm_cmd_rdy
                            };

assign      {
                sys_cmd_vld,
                ilm_cmd_vld,
                dlm_cmd_vld
            } = sn_icb_cmd_vld;

assign      {
                sys_cmd_write,
                ilm_cmd_write,
                dlm_cmd_write
            } = sn_icb_cmd_write;

assign      {
                sys_cmd_addr,
                ilm_cmd_addr,
                dlm_cmd_addr
            } = sn_icb_cmd_addr;

assign      {
                sys_cmd_wdata,
                ilm_cmd_wdata,
                dlm_cmd_wdata
            } = sn_icb_cmd_wdata;

assign      {
                sys_cmd_wstrb,
                ilm_cmd_wstrb,
                dlm_cmd_wstrb
            } = sn_icb_cmd_wstrb;

assign     sn_icb_rsp_vld = {
                sys_rsp_vld,
                ilm_rsp_vld,
                dlm_rsp_vld
            };

assign      {
                sys_rsp_rdy,
                ilm_rsp_rdy,
                dlm_rsp_rdy
            } = sn_icb_rsp_rdy;

assign      sn_icb_rsp_rdata = {
                sys_rsp_rdata,
                ilm_rsp_rdata,
                dlm_rsp_rdata
            };

assign      sn_icb_rsp_err = {
                sys_rsp_err,
                ilm_rsp_err,
                dlm_rsp_err
            };

lnrv_icb_demux#(
    .P_ADDR_WIDTH               ( LP_ADDR_WIDTH         ),
    .P_DATA_WIDTH               ( LP_DATA_WIDTH         ),
    .P_ICB_COUNT                ( 3                     ),
    .P_INSERT_BUFF              ( "false"               ),
    .P_OTS_COUNT                ( 4                     )
)
u_lnrv_icb_demux
(
    .clk                        ( clk                   ),
    .reset_n                    ( reset_n               ),

    .m_icb_cmd_vld              ( m_icb_cmd_vld         ),
    .m_icb_cmd_rdy              ( m_icb_cmd_rdy         ),
    .m_icb_cmd_write            ( m_icb_cmd_write       ),
    .m_icb_cmd_addr             ( m_icb_cmd_addr        ),
    .m_icb_cmd_wdata            ( m_icb_cmd_wdata       ),
    .m_icb_cmd_wstrb            ( m_icb_cmd_wstrb       ),
    .m_icb_rsp_rdy              ( m_icb_rsp_rdy         ),
    .m_icb_rsp_vld              ( m_icb_rsp_vld         ),
    .m_icb_rsp_rdata            ( m_icb_rsp_rdata       ),
    .m_icb_rsp_err              ( m_icb_rsp_err         ),

    .sn_icb_cmd_vld             ( sn_icb_cmd_vld        ),
    .sn_icb_cmd_rdy             ( sn_icb_cmd_rdy        ),
    .sn_icb_cmd_write           ( sn_icb_cmd_write      ),
    .sn_icb_cmd_addr            ( sn_icb_cmd_addr       ),
    .sn_icb_cmd_wdata           ( sn_icb_cmd_wdata      ),
    .sn_icb_cmd_wstrb           ( sn_icb_cmd_wstrb      ),
    .sn_icb_rsp_vld             ( sn_icb_rsp_vld        ),
    .sn_icb_rsp_rdy             ( sn_icb_rsp_rdy        ),
    .sn_icb_rsp_rdata           ( sn_icb_rsp_rdata      ),
    .sn_icb_rsp_err             ( sn_icb_rsp_err        ),

    .sn_region_base       ( sn_region_base  ),
    .sn_region_end         ( sn_region_end    )
);
// outports wire
wire [LP_DATA_WIDTH-1:0]     	ram_rdata;


lnrv_icb2sram#(
    .P_ADDR_WIDTH               ( LP_ILM_ADDR_WIDTH     ),
    .P_DATA_WIDTH               ( LP_DATA_WIDTH         )
)
u_lnrv_ilm_ctrl
(
    .clk                        ( clk                   ),
    .reset_n                    ( reset_n               ),

    .icb_cmd_vld                ( ilm_cmd_vld           ),
    .icb_cmd_rdy                ( ilm_cmd_rdy           ),
    .icb_cmd_write              ( ilm_cmd_write         ),
    .icb_cmd_addr               ( ilm_cmd_addr[LP_ILM_ADDR_WIDTH - 1 : 0] ),
    .icb_cmd_wdata              ( ilm_cmd_wdata         ),
    .icb_cmd_wstrb              ( ilm_cmd_wstrb         ),
    .icb_rsp_rdy                ( ilm_rsp_rdy           ),
    .icb_rsp_vld                ( ilm_rsp_vld           ),
    .icb_rsp_rdata              ( ilm_rsp_rdata         ),
    .icb_rsp_err                ( ilm_rsp_err           ),

    .ram_cs                     ( ilm_cs                ),
    .ram_we                     ( ilm_we                ),
    .ram_wem                    ( ilm_wem               ),
    .ram_addr                   ( ilm_addr              ),
    .ram_wdata                  ( ilm_wdata             ),
    .ram_rdata                  ( ilm_rdata             )
);

// ilm
lnrv_gen_ram#
(
    .P_ADDR_WIDTH               ( LP_ILM_ADDR_WIDTH - 2 ),
    .P_DATA_WIDTH               ( LP_DATA_WIDTH         )
)
u_lnrv_ilm
(
    .ram_cs                     ( ilm_cs                ),
    .ram_we                     ( ilm_we                ),
    .ram_wem                    ( ilm_wem               ),
    .ram_addr                   ( ilm_addr              ),
    .ram_wdata                  ( ilm_wdata             ),
    .ram_rdata                  ( ilm_rdata             ),

    .clk                        ( clk                   )
);



lnrv_icb2sram#(
    .P_ADDR_WIDTH               ( LP_DLM_ADDR_WIDTH     ),
    .P_DATA_WIDTH               ( LP_DATA_WIDTH         )
)
u_lnrv_dlm_ctrl
(
    .clk                        ( clk                   ),
    .reset_n                    ( reset_n               ),

    .icb_cmd_vld                ( dlm_cmd_vld           ),
    .icb_cmd_rdy                ( dlm_cmd_rdy           ),
    .icb_cmd_write              ( dlm_cmd_write         ),
    .icb_cmd_addr               ( dlm_cmd_addr[LP_DLM_ADDR_WIDTH - 1 : 0] ),
    .icb_cmd_wdata              ( dlm_cmd_wdata         ),
    .icb_cmd_wstrb              ( dlm_cmd_wstrb         ),
    .icb_rsp_rdy                ( dlm_rsp_rdy           ),
    .icb_rsp_vld                ( dlm_rsp_vld           ),
    .icb_rsp_rdata              ( dlm_rsp_rdata         ),
    .icb_rsp_err                ( dlm_rsp_err           ),

    .ram_cs                     ( dlm_cs                ),
    .ram_we                     ( dlm_we                ),
    .ram_wem                    ( dlm_wem               ),
    .ram_addr                   ( dlm_addr              ),
    .ram_wdata                  ( dlm_wdata             ),
    .ram_rdata                  ( dlm_rdata             )
);


// dlm
lnrv_gen_ram#
(
    .P_ADDR_WIDTH               ( LP_DLM_ADDR_WIDTH - 2 ),
    .P_DATA_WIDTH               ( LP_DATA_WIDTH         )
)
u_lnrv_dlm
(
    .ram_cs                     ( dlm_cs                ),
    .ram_we                     ( dlm_we                ),
    .ram_wem                    ( dlm_wem               ),
    .ram_addr                   ( dlm_addr              ),
    .ram_wdata                  ( dlm_wdata             ),
    .ram_rdata                  ( dlm_rdata             ),

    .clk                        ( clk                   )
);

integer         i;

initial begin
    for(i = 0; i < LP_ILM_SIZE; i = i + 1) begin
        u_lnrv_ilm.mem_q[i] = i;
    end

    for(i = 0; i < LP_DLM_SIZE; i = i + 1) begin
        u_lnrv_dlm.mem_q[i] = i * 3 + 1;
    end
end


initial begin
    clk = 1'b0;
    reset_n = 1'b0;

    # 100;
    reset_n = 1'b1;

    #2000;
    $finish;
end

initial
begin            
    $dumpfile("wave.vcd");        //生成的vcd文件名称
    $dumpvars(0, lnrv_icb_demux_tb);    //tb模块名称
end

always #10 clk = ~clk;


initial begin
    m_icb_cmd_vld = 1'b0;
    m_icb_cmd_write = 1'b0;
    m_icb_cmd_addr = 32'd0;
    m_icb_cmd_wdata = 32'd0;
    m_icb_cmd_wstrb = 4'b1111;
    m_icb_rsp_rdy = 1'b1;

    sys_cmd_rdy = 1'b1;
    sys_rsp_vld = 1'b1;
    sys_rsp_err = 1'b0;
    sys_rsp_rdata = 32'd2;


    wait(reset_n == 1'b1);

    #20;
    for(i = 0; i < 100; i = i + 1) begin
        // read_ilm(i * 4);
        // read_dlm(i * 4);
        read_sys(i * 4);
    end

    #200;

end


task read_ilm;
    input[LP_ADDR_WIDTH - 1 : 0]    addr;

    begin
        @(posedge clk) begin
            m_icb_cmd_vld <= 1'b1;
            m_icb_cmd_write <= 1'b0;
            m_icb_cmd_addr <= addr + LP_ILM_BASE;
        end
        wait(m_icb_rsp_rdy == 1'b1);
        @(posedge clk) begin
            m_icb_cmd_vld <= 1'b0;
        end
    end
endtask

task read_dlm;
    input[LP_ADDR_WIDTH - 1 : 0]    addr;

    begin
        @(posedge clk) begin
            m_icb_cmd_vld <= 1'b1;
            m_icb_cmd_write <= 1'b0;
            m_icb_cmd_addr <= addr + LP_DLM_BASE;
        end
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        wait(m_icb_rsp_rdy == 1'b1);
        @(posedge clk) begin
            m_icb_cmd_vld <= 1'b0;
        end
    end
endtask


task read_sys;
    input[LP_ADDR_WIDTH - 1 : 0]    addr;

    begin
        @(posedge clk) begin
            m_icb_cmd_vld <= 1'b1;
            m_icb_cmd_write <= 1'b0;
            m_icb_cmd_addr <= addr + 32'h2000_0000;
        end
        wait(m_icb_rsp_rdy == 1'b1);
        @(posedge clk) begin
            m_icb_cmd_vld <= 1'b0;
        end
    end
endtask


endmodule
