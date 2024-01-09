module lnrv_apb2icb#
(
    parameter                           P_ADDR_WIDTH = 32,
    parameter                           P_DATA_WIDTH = 32
)
(
    input                               psel,
    input                               penable,
    input                               pwrite,
    input[P_ADDR_WIDTH : 0]             paddr,
    input[P_DATA_WIDTH - 1 : 0]         pwdata,
    input[(P_DATA_WIDTH/8) - 1 : 0]     pstrb,
    output[P_DATA_WIDTH - 1 : 0]        prdata,
    output                              pslverr,
    output                              pready,


    output                              icb_cmd_vld,
    input                               icb_cmd_rdy,
    output                              icb_cmd_write,
    output[P_ADDR_WIDTH - 1 : 0]        icb_cmd_addr,
    output[P_DATA_WIDTH - 1 : 0]        icb_cmd_wdata,
    output[(P_DATA_WIDTH/8) - 1 : 0]    icb_cmd_wstrb,
    input                               icb_rsp_vld,
    output                              icb_rsp_rdy,
    input                               icb_rsp_err,
    input[P_DATA_WIDTH - 1 : 0]         icb_rsp_rdata,

    input                               clk,
    input                               reset_n
);



reg             cmd_vld_q;
wire            cmd_vld_set;
wire            cmd_vld_clr;
wire            cmd_vld_rld;
wire            cmd_vld_d;




assign      cmd_vld_set = psel & (~penable);
assign      cmd_vld_clr = icb_cmd_hsked;
assign      cmd_vld_rld = cmd_vld_set | cmd_vld_clr;
assign      cmd_vld_d = cmd_vld_set;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        cmd_vld_q <= 1'b0;
    end else if(cmd_vld_rld) begin
        cmd_vld_q <= cmd_vld_d;
    end
end



assign      icb_cmd_vld = cmd_vld_q;
assign      icb_cmd_addr = paddr;
assign      icb_cmd_wdata = pwdata;
assign      icb_cmd_wstrb = pstrb;


endmodule