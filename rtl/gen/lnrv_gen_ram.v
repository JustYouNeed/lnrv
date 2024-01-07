module  lnrv_gen_ram#
(
    parameter                           P_DATA_WIDTH = 32,
    parameter                           P_ADDR_WIDTH = 32
)
(
    input                               ram_cs,
    input                               ram_we,
    input[(P_DATA_WIDTH/8) - 1 : 0]     ram_wem,
    input[P_ADDR_WIDTH - 1 : 0]         ram_addr,
    input[P_DATA_WIDTH - 1 : 0]         ram_wdata,
    output[P_DATA_WIDTH - 1 : 0]        ram_rdata,

    input                               clk
);

// 由地址宽度计算ram大小
localparam                      LP_RAM_SIZE = 2**P_ADDR_WIDTH;


reg[P_DATA_WIDTH - 1 : 0]       mem_q[LP_RAM_SIZE - 1 : 0];
wire[P_DATA_WIDTH - 1 : 0]      mem_d;

reg[P_ADDR_WIDTH - 1 : 0]       raddr_q;
wire[P_ADDR_WIDTH - 1 : 0]      raddr_d;

wire                            mem_wen;

genvar                          i;

generate
    // byte mask
    for(i = 0; i < (P_DATA_WIDTH/8); i = i + 1) begin
        assign      mem_d[i * 8 +: 8] = ram_wem[i] ? ram_wdata[i * 8 +: 8] : mem_q[ram_addr][i * 8 +: 8];
    end        
endgenerate

assign      mem_wen = ram_cs & ram_we;

always@(posedge clk) begin
    if(mem_wen) begin
        mem_q[ram_addr] = mem_d;
    end
end

always@(posedge clk) begin
	raddr_q <= ram_addr;
end

assign      ram_rdata = mem_q[raddr_q];

endmodule