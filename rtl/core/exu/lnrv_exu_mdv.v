module  lnrv_exu_mdv
(
    input                               op_vld,
    output                              op_rdy,
    input[`MDV_OP_BUS_WIDTH - 1 : 0]    op_bus,


    output                              gpr_wbck_vld,
    input                               gpr_wbck_rdy,
    output[31 : 0]                      gpr_wbck_wdata,

    input                               clk,
    input                               reset_n
);


assign      op_rdy = 1'b1;
assign      gpr_wbck_vld = 1'b0;
assign      gpr_wbck_wdata = 32'd0;

endmodule