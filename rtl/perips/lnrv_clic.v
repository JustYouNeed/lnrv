// core local interrupt controller
module lnrv_clic#
(
    parameter                       P_IRQ_COUNT = 32
)
(
    input                           clk,
    input                           reset_n,

    // 操作总线
    input                           icb_cmd_vld,
    output                          icb_cmd_rdy,
    input                           icb_cmd_write,
    input[15 : 0]                   icb_cmd_addr,
    input[31 : 0]                   icb_cmd_wdata,
    input[3 : 0]                    icb_cmd_wstrb,
    input[2 : 0]                    icb_cmd_size,
    output                          icb_rsp_vld,
    input                           icb_rsp_rdy,
    output[31 : 0]                  icb_rsp_rdata,
    output                          icb_rsp_err,

    input                           irq_tmr,
    input                           irq_sft,

    // 中断源
    input[P_IRQ_COUNT - 1 : 0]      irq_src,

    // 输出到Core
    output                          irq_req,
    input                           irq_ack,
    output                          irq_mode,
    output[9 : 0]                   irq_id
);


endmodule