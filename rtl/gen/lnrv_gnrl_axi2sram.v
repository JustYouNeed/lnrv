module lnrv_gnrl_axi2sram#
(
    parameter                           P_AXI_ADDR_WIDTH = 32,
    parameter                           P_RAM_ADDR_WIDTH = 17,

    parameter                           P_DATA_WIDTH = 32
)
(
    // axi4
    input                               axi_awvalid,
    output                              axi_awready,
    input                               axi_awlock,
    input[P_AXI_ADDR_WIDTH - 1 : 0]     axi_awaddr,
    input[3 : 0]                        axi_awid,
    input[7 : 0]                        axi_awlen,
    input[2 : 0]                        axi_awsize,
    input[1 : 0]                        axi_awburst,
    input[3 : 0]                        axi_awcache,
    input[2 : 0]                        axi_awprot,

    input                               axi_wvalid,
    output                              axi_wready,
    input[P_DATA_WIDTH - 1 : 0]         axi_wdata,
    input[(P_DATA_WIDTH/8) - 1 : 0]     axi_wstrb,
    input                               axi_wlast,

    input                               axi_bready,
    output                              axi_bvalid,
    output[1 : 0]                       axi_bresp,
    output[3 : 0]                       axi_bid,

    input                               axi_arvalid,
    output                              axi_arready,
    input                               axi_arlock,
    input[P_AXI_ADDR_WIDTH - 1 : 0]     axi_araddr,
    input[3 : 0]                        axi_arid,
    input[7 : 0]                        axi_arlen,
    input[2 : 0]                        axi_arsize,
    input[1 : 0]                        axi_arburst,
    input[3 : 0]                        axi_arcache,
    input[2 : 0]                        axi_arprot,

    input                               axi_rready,
    output                              axi_rvalid,
    output[P_DATA_WIDTH - 1 : 0]        axi_rdata,
    output[1 : 0]                       axi_rresp,
    output                              axi_rlast,
    output[3 : 0]                       axi_rid,

    output                              ram_clk,
    output                              ram_cs,
    output                              ram_we,
    output[(P_DATA_WIDTH/8) - 1 : 0]    ram_wem,
    output[P_RAM_ADDR_WIDTH - 1 : 0]    ram_addr,
    output[P_DATA_WIDTH - 1 : 0]        ram_wdata,
    input[P_DATA_WIDTH - 1 : 0]         ram_rdata
);



endmodule