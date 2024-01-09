module lnrv_plmt
(
    output                              irq_req,
    input                               irq_ack,


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