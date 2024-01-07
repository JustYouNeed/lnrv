module lnrv_icb2sram#
(
    parameter                           P_ICB_ADDR_WIDTH = 32,
    parameter                           P_RAM_ADDR_WIDTH = 17,

    parameter                           P_DATA_WIDTH = 32
)
(
    input                               clk,
    input                               reset_n,


    input                               icb_cmd_vld,
    output                              icb_cmd_rdy,
    input                               icb_cmd_write,
    input[P_ICB_ADDR_WIDTH - 1 : 0]     icb_cmd_addr,
    input[P_DATA_WIDTH - 1 : 0]         icb_cmd_wdata,
    input[(P_DATA_WIDTH/8) - 1 : 0]     icb_cmd_wstrb,

    input                               icb_rsp_rdy,
    output                              icb_rsp_vld,
    output[P_DATA_WIDTH - 1 : 0]        icb_rsp_rdata,
    output                              icb_rsp_err,


    output                              ram_cs,
    output                              ram_we,
    output[(P_DATA_WIDTH/8) - 1 : 0]    ram_wem,
    output[P_RAM_ADDR_WIDTH - 1 : 0]    ram_addr,
    output[P_DATA_WIDTH - 1 : 0]        ram_wdata,
    input[P_DATA_WIDTH - 1 : 0]         ram_rdata
);


localparam              LP_RAM_ADDR_LSB = $clog2(P_DATA_WIDTH/8);

reg                     rsp_vld_q;
wire                    rsp_vld_set;
wire                    rsp_vld_clr;
wire                    rsp_vld_rld;
wire                    rsp_vld_d;

wire                    icb_cmd_hsked;
wire                    icb_rsp_hsked;

assign      icb_cmd_hsked = icb_cmd_vld & icb_cmd_rdy;
assign      icb_rsp_hsked = icb_rsp_vld & icb_rsp_rdy;

assign      rsp_vld_set = icb_cmd_hsked;
assign      rsp_vld_clr = icb_rsp_hsked;
assign      rsp_vld_rld = rsp_vld_set | rsp_vld_clr;
assign      rsp_vld_d = rsp_vld_set;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        rsp_vld_q <= 1'b0;
    end else if(rsp_vld_rld) begin
        rsp_vld_q <= rsp_vld_d;
    end
end


assign      icb_cmd_rdy = (~rsp_vld_q) | rsp_vld_clr;

assign      icb_rsp_vld = rsp_vld_q;
assign      icb_rsp_rdata = ram_rdata;
assign      icb_rsp_err = 1'b0;

assign      ram_cs = icb_cmd_hsked;
assign      ram_we = icb_cmd_write;
assign      ram_wem = icb_cmd_wstrb;
assign      ram_addr = icb_cmd_addr[LP_RAM_ADDR_LSB +: P_RAM_ADDR_WIDTH];
assign      ram_wdata = icb_cmd_wdata;



endmodule