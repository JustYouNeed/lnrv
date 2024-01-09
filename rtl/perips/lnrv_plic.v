module lnrv_plic#
(
    parameter                           P_IRQ_COUNT = 32,

    parameter                           P_BUS_TYPE = "apb"
)
(
    input[P_IRQ_COUNT - 1 : 0]          irq,

    output                              intr_req,
    input                               intr_ack,
    output[9 : 0]                       intr_id,

    // 寄存器访问接口
    input                               psel,
    input                               penable,
    input                               pwrite,
    input[7 : 0]                        paddr,
    input[31 : 0]                       pwdata,
    output[31 : 0]                      prdata,
    output                              pslverr,
    output                              pready,

    input                               clk,
    input                               reset_n
);


endmodule