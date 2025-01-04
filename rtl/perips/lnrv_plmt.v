module lnrv_plmt
(
    // 定时器中断
    output                              irq_tmr,

    // 软件中断
    input                               irq_sft,

    input                               stop_timer,


    // 寄存器访问接口
    input                               pclk,
    input                               preset_n,
    input                               psel,
    input                               penable,
    input                               pwrite,
    input[11 : 0]                       paddr,
    input[31 : 0]                       pwdata,
    output[31 : 0]                      prdata,
    output                              pslverr,
    output                              pready,

    input                               tclk,
    input                               treset_n
);


reg                     tclk_toggle_q;
wire                    tclk_toggle_d;

wire                    tmr_toggle;


assign      tclk_toggle_d = ~tclk_toggle_q;
always@(posedge tclk or negedge treset_n) begin
    if(treset_n == 1'b0) begin
        tclk_toggle_q <= 1'b0;
    end else begin
        tclk_toggle_q <= tclk_toggle_d;
    end
end

lnrv_gnrl_dat_sync#
(
    .P_SYNC_STAGE       ( 2                     ),
    .P_DATA_WIDTH       ( 1                     ),
    .P_RESET_VALUE      ( 1'b0                  )
)
u_lnrv_gnrl_dat_sync
(
    .async_data         ( tclk_toggle_q         ),

    .sync_clk           ( pclk                  ),
    .sync_rst_n         ( preset_n              ),
    .sync_data          ( tmr_toggle            )
);




endmodule