module lnrv_icb_mux_tb;

localparam                                  LP_ICB_COUNT = 3;
localparam                                  LP_ICB_ADDR_WIDTH = 32;
localparam                                  LP_ILM_ADDR_WIDTH = 15;
localparam                                  LP_DATA_WIDTH = 32;
localparam                                  LP_ILM_SIZE = 2 ** LP_ILM_ADDR_WIDTH;

localparam                                  LP_MN_ICB_ADDR_WIDTH = LP_ICB_COUNT * LP_ICB_ADDR_WIDTH;
localparam                                  LP_MN_ICB_DATA_WIDTH = LP_ICB_COUNT * LP_DATA_WIDTH;
localparam                                  LP_MN_ICB_WSTRB_WIDTH = LP_ICB_COUNT * (LP_DATA_WIDTH/8);

wire[LP_ICB_COUNT - 1 : 0]                  mn_icb_cmd_vld;
wire[LP_ICB_COUNT - 1 : 0]                  mn_icb_cmd_rdy;
wire[LP_ICB_COUNT - 1 : 0]                  mn_icb_cmd_write;
wire[LP_MN_ICB_ADDR_WIDTH - 1 : 0]          mn_icb_cmd_addr;
wire[LP_MN_ICB_DATA_WIDTH - 1 : 0]          mn_icb_cmd_wdata;
wire[LP_MN_ICB_WSTRB_WIDTH - 1 : 0]         mn_icb_cmd_wstrb;
wire[LP_ICB_COUNT - 1 : 0]                  mn_icb_rsp_rdy;
wire[LP_ICB_COUNT - 1 : 0]                  mn_icb_rsp_vld;
wire[LP_MN_ICB_DATA_WIDTH - 1 : 0]          mn_icb_rsp_rdata;
wire[LP_ICB_COUNT - 1 : 0]                  mn_icb_rsp_err;


reg                                         ifu2icb_cmd_vld_ilm;
wire                                        ifu2icb_cmd_rdy_ilm;
reg                                         ifu2icb_cmd_write_ilm;
reg[LP_ICB_ADDR_WIDTH - 1 : 0]              ifu2icb_cmd_addr_ilm;
reg[LP_DATA_WIDTH - 1 : 0]                  ifu2icb_cmd_wdata_ilm;
reg[(LP_DATA_WIDTH/8) - 1 : 0]              ifu2icb_cmd_wstrb_ilm;
wire                                        ifu2icb_rsp_vld_ilm;
reg                                         ifu2icb_rsp_rdy_ilm;
wire[LP_DATA_WIDTH - 1 : 0]                 ifu2icb_rsp_rdata_ilm;
wire                                        ifu2icb_rsp_err_ilm;

reg                                         lsu2icb_cmd_vld_ilm;
wire                                        lsu2icb_cmd_rdy_ilm;
reg                                         lsu2icb_cmd_write_ilm;
reg[LP_ICB_ADDR_WIDTH - 1 : 0]              lsu2icb_cmd_addr_ilm;
reg[LP_DATA_WIDTH - 1 : 0]                  lsu2icb_cmd_wdata_ilm;
reg[(LP_DATA_WIDTH/8) - 1 : 0]              lsu2icb_cmd_wstrb_ilm;
wire                                        lsu2icb_rsp_vld_ilm;
reg                                         lsu2icb_rsp_rdy_ilm;
wire[LP_DATA_WIDTH - 1 : 0]                 lsu2icb_rsp_rdata_ilm;
wire                                        lsu2icb_rsp_err_ilm;

reg                                         slv2icb_cmd_vld_ilm;
wire                                        slv2icb_cmd_rdy_ilm;
reg                                         slv2icb_cmd_write_ilm;
reg[LP_ICB_ADDR_WIDTH - 1 : 0]              slv2icb_cmd_addr_ilm;
reg[LP_DATA_WIDTH - 1 : 0]                  slv2icb_cmd_wdata_ilm;
reg[(LP_DATA_WIDTH/8) - 1 : 0]              slv2icb_cmd_wstrb_ilm;
wire                                        slv2icb_rsp_vld_ilm;
reg                                         slv2icb_rsp_rdy_ilm;
wire[LP_DATA_WIDTH - 1 : 0]                 slv2icb_rsp_rdata_ilm;
wire                                        slv2icb_rsp_err_ilm;

// ilm总线
wire                                        icb_cmd_vld_ilm;
wire                                        icb_cmd_rdy_ilm;
wire                                        icb_cmd_write_ilm;
wire[LP_ICB_ADDR_WIDTH - 1 : 0]             icb_cmd_addr_ilm;
wire[LP_DATA_WIDTH - 1 : 0]                 icb_cmd_wdata_ilm;
wire[(LP_DATA_WIDTH/8) - 1 : 0]             icb_cmd_wstrb_ilm;
wire                                        icb_rsp_vld_ilm;
wire                                        icb_rsp_rdy_ilm;
wire[LP_DATA_WIDTH - 1 : 0]                 icb_rsp_rdata_ilm;
wire                                        icb_rsp_err_ilm;

wire                                        ilm_cs;
wire                                        ilm_we;
wire[(LP_DATA_WIDTH/8) - 1 : 0]             ilm_wem;
wire[LP_ILM_ADDR_WIDTH - 1 : 0]             ilm_addr;
wire[LP_DATA_WIDTH - 1 : 0]                 ilm_wdata;
wire[LP_DATA_WIDTH - 1 : 0]                 ilm_rdata;


reg                                         clk;
reg                                         reset_n;


assign      mn_icb_cmd_vld =    {
                                    ifu2icb_cmd_vld_ilm,
                                    lsu2icb_cmd_vld_ilm,
                                    slv2icb_cmd_vld_ilm
                                };

assign      {
                ifu2icb_cmd_rdy_ilm,
                lsu2icb_cmd_rdy_ilm,
                slv2icb_cmd_rdy_ilm
            } = mn_icb_cmd_rdy;

assign      mn_icb_cmd_write =  {
                                    ifu2icb_cmd_write_ilm,
                                    lsu2icb_cmd_write_ilm,
                                    slv2icb_cmd_write_ilm
                                };

assign      mn_icb_cmd_wdata =  {
                                    ifu2icb_cmd_wdata_ilm,
                                    lsu2icb_cmd_wdata_ilm,
                                    slv2icb_cmd_wdata_ilm
                                };

assign      mn_icb_cmd_addr =   {
                                    ifu2icb_cmd_addr_ilm,
                                    lsu2icb_cmd_addr_ilm,
                                    slv2icb_cmd_addr_ilm
                                };

assign      mn_icb_cmd_wstrb =  {
                                    ifu2icb_cmd_wstrb_ilm,
                                    lsu2icb_cmd_wstrb_ilm,
                                    slv2icb_cmd_wstrb_ilm
                                };

assign      {
                ifu2icb_rsp_vld_ilm,
                lsu2icb_rsp_vld_ilm,
                slv2icb_rsp_vld_ilm
            } = mn_icb_rsp_vld;

assign      mn_icb_rsp_rdy =  {
                                    ifu2icb_rsp_rdy_ilm,
                                    lsu2icb_rsp_rdy_ilm,
                                    slv2icb_rsp_rdy_ilm
                                };

assign      {
                ifu2icb_rsp_rdata_ilm,
                lsu2icb_rsp_rdata_ilm,
                slv2icb_rsp_rdata_ilm
            } = mn_icb_rsp_rdata;

assign      {
                ifu2icb_rsp_err_ilm,
                lsu2icb_rsp_err_ilm,
                slv2icb_rsp_err_ilm
            } = mn_icb_rsp_err;

lnrv_icb_mux#
(
    .P_ADDR_WIDTH               ( LP_ICB_ADDR_WIDTH             ),
    .P_DATA_WIDTH               ( LP_DATA_WIDTH                 ),
    .P_ICB_COUNT                ( LP_ICB_COUNT                  ),
    .P_OTS_COUNT                ( 4                             ),
    .P_INSERT_BUFF              ( "true"                        )
)
u_lnrv_icb_mux
(
    .clk                        ( clk                           ),
    .reset_n                    ( reset_n                       ),

    .mn_icb_cmd_vld             ( mn_icb_cmd_vld                ),
    .mn_icb_cmd_rdy             ( mn_icb_cmd_rdy                ),
    .mn_icb_cmd_write           ( mn_icb_cmd_write              ),
    .mn_icb_cmd_addr            ( mn_icb_cmd_addr               ),
    .mn_icb_cmd_wdata           ( mn_icb_cmd_wdata              ),
    .mn_icb_cmd_wstrb           ( mn_icb_cmd_wstrb              ),
    .mn_icb_rsp_rdy             ( mn_icb_rsp_rdy                ),
    .mn_icb_rsp_vld             ( mn_icb_rsp_vld                ),
    .mn_icb_rsp_rdata           ( mn_icb_rsp_rdata              ),
    .mn_icb_rsp_err             ( mn_icb_rsp_err                ),

    .s_icb_cmd_vld              ( icb_cmd_vld_ilm                   ),
    .s_icb_cmd_rdy              ( icb_cmd_rdy_ilm                   ),
    .s_icb_cmd_write            ( icb_cmd_write_ilm                 ),
    .s_icb_cmd_addr             ( icb_cmd_addr_ilm                  ),
    .s_icb_cmd_wdata            ( icb_cmd_wdata_ilm                 ),
    .s_icb_cmd_wstrb            ( icb_cmd_wstrb_ilm                 ),
    .s_icb_rsp_vld              ( icb_rsp_vld_ilm                   ),
    .s_icb_rsp_rdy              ( icb_rsp_rdy_ilm                   ),
    .s_icb_rsp_rdata            ( icb_rsp_rdata_ilm                 ),
    .s_icb_rsp_err              ( icb_rsp_err_ilm                   )
);

lnrv_icb2sram#(
    .P_ICB_ADDR_WIDTH           ( LP_ICB_ADDR_WIDTH             ),
    .P_RAM_ADDR_WIDTH           ( LP_ILM_ADDR_WIDTH             ),
    .P_DATA_WIDTH               ( LP_DATA_WIDTH                 )
)
u_lnrv_ilm_ctrl
(
    .clk                        ( clk                           ),
    .reset_n                    ( reset_n                       ),

    .icb_cmd_vld                ( icb_cmd_vld_ilm                   ),
    .icb_cmd_rdy                ( icb_cmd_rdy_ilm                   ),
    .icb_cmd_write              ( icb_cmd_write_ilm                 ),
    .icb_cmd_addr               ( icb_cmd_addr_ilm                  ),
    .icb_cmd_wdata              ( icb_cmd_wdata_ilm                 ),
    .icb_cmd_wstrb              ( icb_cmd_wstrb_ilm                 ),
    .icb_rsp_rdy                ( icb_rsp_rdy_ilm                   ),
    .icb_rsp_vld                ( icb_rsp_vld_ilm                   ),
    .icb_rsp_rdata              ( icb_rsp_rdata_ilm                 ),
    .icb_rsp_err                ( icb_rsp_err_ilm                   ),

    .ram_cs                     ( ilm_cs                        ),
    .ram_we                     ( ilm_we                        ),
    .ram_wem                    ( ilm_wem                       ),
    .ram_addr                   ( ilm_addr                      ),
    .ram_wdata                  ( ilm_wdata                     ),
    .ram_rdata                  ( ilm_rdata                     )
);

// ilm
lnrv_gen_ram#
(
    .P_ADDR_WIDTH               ( LP_ILM_ADDR_WIDTH             ),
    .P_DATA_WIDTH               ( LP_DATA_WIDTH                 )
)
u_lnrv_ilm
(
    .ram_cs                     ( ilm_cs                        ),
    .ram_we                     ( ilm_we                        ),
    .ram_wem                    ( ilm_wem                       ),
    .ram_addr                   ( ilm_addr                      ),
    .ram_wdata                  ( ilm_wdata                     ),
    .ram_rdata                  ( ilm_rdata                     ),

    .clk                        ( clk                           )
);


integer         i;

initial begin
    for(i = 0; i < LP_ILM_SIZE; i = i + 1) begin
        u_lnrv_ilm.mem_q[i] = i;
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

initial begin
    $dumpfile("wave.vcd");        //生成的vcd文件名称
    $dumpvars(0, lnrv_icb_mux_tb);    //tb模块名称
end

always #10 clk = ~clk;


initial begin
    ifu2icb_cmd_vld_ilm = 1'b0;
    ifu2icb_cmd_write_ilm = 1'b0;
    ifu2icb_cmd_addr_ilm = {LP_ICB_ADDR_WIDTH{1'b0}};
    ifu2icb_cmd_wdata_ilm = {LP_DATA_WIDTH{1'b0}};
    ifu2icb_cmd_wstrb_ilm = {(LP_DATA_WIDTH/8){1'b1}};
    ifu2icb_rsp_rdy_ilm = 1'b1;
end

initial begin
    lsu2icb_cmd_vld_ilm = 1'b0;
    lsu2icb_cmd_write_ilm = 1'b0;
    lsu2icb_cmd_addr_ilm = {LP_ICB_ADDR_WIDTH{1'b0}};
    lsu2icb_cmd_wdata_ilm = {LP_DATA_WIDTH{1'b0}};
    lsu2icb_cmd_wstrb_ilm = {(LP_DATA_WIDTH/8){1'b1}};
    lsu2icb_rsp_rdy_ilm = 1'b1;
end

initial begin
    slv2icb_cmd_vld_ilm = 1'b0;
    slv2icb_cmd_write_ilm = 1'b0;
    slv2icb_cmd_addr_ilm = {LP_ICB_ADDR_WIDTH{1'b0}};
    slv2icb_cmd_wdata_ilm = {LP_DATA_WIDTH{1'b0}};
    slv2icb_cmd_wstrb_ilm = {(LP_DATA_WIDTH/8){1'b1}};
    slv2icb_rsp_rdy_ilm = 1'b1;
end


always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        ifu2icb_cmd_vld_ilm <= 1'b0;

        ifu2icb_cmd_addr_ilm <= {LP_ICB_ADDR_WIDTH{1'b0}};
        ifu2icb_cmd_wdata_ilm <= {LP_DATA_WIDTH{1'b0}};
        ifu2icb_cmd_wstrb_ilm <= {(LP_DATA_WIDTH/8){1'b1}};
    end else begin
        ifu2icb_cmd_vld_ilm <= 1'b1;
        if(ifu2icb_cmd_rdy_ilm) begin
            ifu2icb_cmd_addr_ilm <= ifu2icb_cmd_addr_ilm + 4;
            ifu2icb_cmd_wdata_ilm <= ifu2icb_cmd_wdata_ilm + 1;
        end
        ifu2icb_cmd_write_ilm <= 1'b0;
    end
end

always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        lsu2icb_cmd_vld_ilm <= 1'b0;

        lsu2icb_cmd_addr_ilm <= 32'h000;
        lsu2icb_cmd_wdata_ilm <= {LP_DATA_WIDTH{1'b0}};
        lsu2icb_cmd_wstrb_ilm <= {(LP_DATA_WIDTH/8){1'b1}};
    end else begin
        lsu2icb_cmd_vld_ilm <= 1'b1;
        if(lsu2icb_cmd_rdy_ilm) begin
            lsu2icb_cmd_addr_ilm <= lsu2icb_cmd_addr_ilm + 4;
            lsu2icb_cmd_wdata_ilm <= lsu2icb_cmd_addr_ilm + 8;
        end
        lsu2icb_cmd_write_ilm <= 1'b1;
    end
end

always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        slv2icb_cmd_vld_ilm <= 1'b0;

        slv2icb_cmd_addr_ilm <= 32'h100;
        slv2icb_cmd_wdata_ilm <= {LP_DATA_WIDTH{1'b0}};
        slv2icb_cmd_wstrb_ilm <= {(LP_DATA_WIDTH/8){1'b1}};
    end else begin
        slv2icb_cmd_vld_ilm <= 1'b0;
        if(slv2icb_cmd_rdy_ilm) begin
            slv2icb_cmd_addr_ilm <= slv2icb_cmd_addr_ilm + 4;
            slv2icb_cmd_wdata_ilm <= slv2icb_cmd_wdata_ilm + 1;
        end
        slv2icb_cmd_write_ilm <= 1'b1;
    end
end

endmodule