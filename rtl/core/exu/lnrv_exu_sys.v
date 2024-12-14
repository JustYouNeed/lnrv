`include "lnrv_def.v"
module	lnrv_exu_sys
(
    input                               op_vld,
    output                              op_rdy,
    input[`SYS_OP_BUS_WIDTH - 1 : 0]    op_bus,

    output                              cmt_vld,
    input                               cmt_rdy,
    output                              cmt_ebreak,
    output                              cmt_ecall,
    output                              cmt_wfi
);


wire                        instr_is_ecall;
wire                        instr_is_ebreak;
// wire                        instr_is_fence;
// wire                        instr_is_fencei;
wire                        instr_is_wfi;


// 首先从总线中解析指令
assign      instr_is_ecall  = op_bus[`SYS_ECALL_LOC];
assign      instr_is_ebreak = op_bus[`SYS_EBREAK_LOC];
assign      instr_is_wfi    = op_bus[`SYS_WFI_LOC];

assign      cmt_vld = op_vld;
assign      cmt_ebreak = instr_is_ebreak;
assign      cmt_ecall = instr_is_ecall;
assign      cmt_wfi = instr_is_wfi;

assign      op_rdy = cmt_rdy;

endmodule