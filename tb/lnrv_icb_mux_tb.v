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


reg                                         ifu2ilm_cmd_vld;
wire                                        ifu2ilm_cmd_rdy;
reg                                         ifu2ilm_cmd_write;
reg[LP_ICB_ADDR_WIDTH - 1 : 0]              ifu2ilm_cmd_addr;
reg[LP_DATA_WIDTH - 1 : 0]                  ifu2ilm_cmd_wdata;
reg[(LP_DATA_WIDTH/8) - 1 : 0]              ifu2ilm_cmd_wstrb;
wire                                        ifu2ilm_rsp_vld;
reg                                         ifu2ilm_rsp_rdy;
wire[LP_DATA_WIDTH - 1 : 0]                 ifu2ilm_rsp_rdata;
wire                                        ifu2ilm_rsp_err;

reg                                         lsu2ilm_cmd_vld;
wire                                        lsu2ilm_cmd_rdy;
reg                                         lsu2ilm_cmd_write;
reg[LP_ICB_ADDR_WIDTH - 1 : 0]              lsu2ilm_cmd_addr;
reg[LP_DATA_WIDTH - 1 : 0]                  lsu2ilm_cmd_wdata;
reg[(LP_DATA_WIDTH/8) - 1 : 0]              lsu2ilm_cmd_wstrb;
wire                                        lsu2ilm_rsp_vld;
reg                                         lsu2ilm_rsp_rdy;
wire[LP_DATA_WIDTH - 1 : 0]                 lsu2ilm_rsp_rdata;
wire                                        lsu2ilm_rsp_err;

reg                                         slv2ilm_cmd_vld;
wire                                        slv2ilm_cmd_rdy;
reg                                         slv2ilm_cmd_write;
reg[LP_ICB_ADDR_WIDTH - 1 : 0]              slv2ilm_cmd_addr;
reg[LP_DATA_WIDTH - 1 : 0]                  slv2ilm_cmd_wdata;
reg[(LP_DATA_WIDTH/8) - 1 : 0]              slv2ilm_cmd_wstrb;
wire                                        slv2ilm_rsp_vld;
reg                                         slv2ilm_rsp_rdy;
wire[LP_DATA_WIDTH - 1 : 0]                 slv2ilm_rsp_rdata;
wire                                        slv2ilm_rsp_err;

// ilm总线
wire                                        ilm_cmd_vld;
wire                                        ilm_cmd_rdy;
wire                                        ilm_cmd_write;
wire[LP_ICB_ADDR_WIDTH - 1 : 0]             ilm_cmd_addr;
wire[LP_DATA_WIDTH - 1 : 0]                 ilm_cmd_wdata;
wire[(LP_DATA_WIDTH/8) - 1 : 0]             ilm_cmd_wstrb;
wire                                        ilm_rsp_vld;
wire                                        ilm_rsp_rdy;
wire[LP_DATA_WIDTH - 1 : 0]                 ilm_rsp_rdata;
wire                                        ilm_rsp_err;

wire                                        ilm_cs;
wire                                        ilm_we;
wire[(LP_DATA_WIDTH/8) - 1 : 0]             ilm_wem;
wire[LP_ILM_ADDR_WIDTH - 1 : 0]             ilm_addr;
wire[LP_DATA_WIDTH - 1 : 0]                 ilm_wdata;
wire[LP_DATA_WIDTH - 1 : 0]                 ilm_rdata;


reg                                         clk;
reg                                         reset_n;


assign      mn_icb_cmd_vld =    {
                                    ifu2ilm_cmd_vld,
                                    lsu2ilm_cmd_vld,
                                    slv2ilm_cmd_vld
                                };

assign      {
                ifu2ilm_cmd_rdy,
                lsu2ilm_cmd_rdy,
                slv2ilm_cmd_rdy
            } = mn_icb_cmd_rdy;

assign      mn_icb_cmd_write =  {
                                    ifu2ilm_cmd_write,
                                    lsu2ilm_cmd_write,
                                    slv2ilm_cmd_write
                                };

assign      mn_icb_cmd_wdata =  {
                                    ifu2ilm_cmd_wdata,
                                    lsu2ilm_cmd_wdata,
                                    slv2ilm_cmd_wdata
                                };

assign      mn_icb_cmd_addr =   {
                                    ifu2ilm_cmd_addr,
                                    lsu2ilm_cmd_addr,
                                    slv2ilm_cmd_addr
                                };

assign      mn_icb_cmd_wstrb =  {
                                    ifu2ilm_cmd_wstrb,
                                    lsu2ilm_cmd_wstrb,
                                    slv2ilm_cmd_wstrb
                                };

assign      {
                ifu2ilm_rsp_vld,
                lsu2ilm_rsp_vld,
                slv2ilm_rsp_vld
            } = mn_icb_rsp_vld;

assign      mn_icb_rsp_rdy =  {
                                    ifu2ilm_rsp_rdy,
                                    lsu2ilm_rsp_rdy,
                                    slv2ilm_rsp_rdy
                                };

assign      {
                ifu2ilm_rsp_rdata,
                lsu2ilm_rsp_rdata,
                slv2ilm_rsp_rdata
            } = mn_icb_rsp_rdata;

assign      {
                ifu2ilm_rsp_err,
                lsu2ilm_rsp_err,
                slv2ilm_rsp_err
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

    .s_icb_cmd_vld              ( ilm_cmd_vld                   ),
    .s_icb_cmd_rdy              ( ilm_cmd_rdy                   ),
    .s_icb_cmd_write            ( ilm_cmd_write                 ),
    .s_icb_cmd_addr             ( ilm_cmd_addr                  ),
    .s_icb_cmd_wdata            ( ilm_cmd_wdata                 ),
    .s_icb_cmd_wstrb            ( ilm_cmd_wstrb                 ),
    .s_icb_rsp_vld              ( ilm_rsp_vld                   ),
    .s_icb_rsp_rdy              ( ilm_rsp_rdy                   ),
    .s_icb_rsp_rdata            ( ilm_rsp_rdata                 ),
    .s_icb_rsp_err              ( ilm_rsp_err                   )
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

    .icb_cmd_vld                ( ilm_cmd_vld                   ),
    .icb_cmd_rdy                ( ilm_cmd_rdy                   ),
    .icb_cmd_write              ( ilm_cmd_write                 ),
    .icb_cmd_addr               ( ilm_cmd_addr                  ),
    .icb_cmd_wdata              ( ilm_cmd_wdata                 ),
    .icb_cmd_wstrb              ( ilm_cmd_wstrb                 ),
    .icb_rsp_rdy                ( ilm_rsp_rdy                   ),
    .icb_rsp_vld                ( ilm_rsp_vld                   ),
    .icb_rsp_rdata              ( ilm_rsp_rdata                 ),
    .icb_rsp_err                ( ilm_rsp_err                   ),

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
    ifu2ilm_cmd_vld = 1'b0;
    ifu2ilm_cmd_write = 1'b0;
    ifu2ilm_cmd_addr = {LP_ICB_ADDR_WIDTH{1'b0}};
    ifu2ilm_cmd_wdata = {LP_DATA_WIDTH{1'b0}};
    ifu2ilm_cmd_wstrb = {(LP_DATA_WIDTH/8){1'b1}};
    ifu2ilm_rsp_rdy = 1'b1;
end

initial begin
    lsu2ilm_cmd_vld = 1'b0;
    lsu2ilm_cmd_write = 1'b0;
    lsu2ilm_cmd_addr = {LP_ICB_ADDR_WIDTH{1'b0}};
    lsu2ilm_cmd_wdata = {LP_DATA_WIDTH{1'b0}};
    lsu2ilm_cmd_wstrb = {(LP_DATA_WIDTH/8){1'b1}};
    lsu2ilm_rsp_rdy = 1'b1;
end

initial begin
    slv2ilm_cmd_vld = 1'b0;
    slv2ilm_cmd_write = 1'b0;
    slv2ilm_cmd_addr = {LP_ICB_ADDR_WIDTH{1'b0}};
    slv2ilm_cmd_wdata = {LP_DATA_WIDTH{1'b0}};
    slv2ilm_cmd_wstrb = {(LP_DATA_WIDTH/8){1'b1}};
    slv2ilm_rsp_rdy = 1'b1;
end


always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        ifu2ilm_cmd_vld <= 1'b0;

        ifu2ilm_cmd_addr <= {LP_ICB_ADDR_WIDTH{1'b0}};
        ifu2ilm_cmd_wdata <= {LP_DATA_WIDTH{1'b0}};
        ifu2ilm_cmd_wstrb <= {(LP_DATA_WIDTH/8){1'b1}};
    end else begin
        ifu2ilm_cmd_vld <= 1'b1;
        if(ifu2ilm_cmd_rdy) begin
            ifu2ilm_cmd_addr <= ifu2ilm_cmd_addr + 4;
            ifu2ilm_cmd_wdata <= ifu2ilm_cmd_wdata + 1;
        end
        ifu2ilm_cmd_write <= 1'b0;
    end
end

always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        lsu2ilm_cmd_vld <= 1'b0;

        lsu2ilm_cmd_addr <= 32'h000;
        lsu2ilm_cmd_wdata <= {LP_DATA_WIDTH{1'b0}};
        lsu2ilm_cmd_wstrb <= {(LP_DATA_WIDTH/8){1'b1}};
    end else begin
        lsu2ilm_cmd_vld <= 1'b1;
        if(lsu2ilm_cmd_rdy) begin
            lsu2ilm_cmd_addr <= lsu2ilm_cmd_addr + 4;
            lsu2ilm_cmd_wdata <= lsu2ilm_cmd_addr + 8;
        end
        lsu2ilm_cmd_write <= 1'b1;
    end
end

always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        slv2ilm_cmd_vld <= 1'b0;

        slv2ilm_cmd_addr <= 32'h100;
        slv2ilm_cmd_wdata <= {LP_DATA_WIDTH{1'b0}};
        slv2ilm_cmd_wstrb <= {(LP_DATA_WIDTH/8){1'b1}};
    end else begin
        slv2ilm_cmd_vld <= 1'b0;
        if(slv2ilm_cmd_rdy) begin
            slv2ilm_cmd_addr <= slv2ilm_cmd_addr + 4;
            slv2ilm_cmd_wdata <= slv2ilm_cmd_wdata + 1;
        end
        slv2ilm_cmd_write <= 1'b1;
    end
end

endmodule