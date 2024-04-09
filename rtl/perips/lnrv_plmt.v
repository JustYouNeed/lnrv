module lnrv_plmt
(
    // 定时器中断
    output                              tmr_irq,

    // 软件中断
    input                               sft_irq,

    input                               stop_timer,


    // 寄存器访问接口
    input                               pclk,
    input                               preset_n,
    input                               psel,
    input                               penable,
    input                               pwrite,
    input[7 : 0]                        paddr,
    input[31 : 0]                       pwdata,
    output[31 : 0]                      prdata,
    output                              pslverr,
    output                              pready,

    input                               tclk,
    input                               treset_n
);






endmodule