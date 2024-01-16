`include "lnrv_def.v"
module	lnrv_exu_sys
(
    input                               op_vld,
    output                              op_rdy,
    input[`SYS_OP_BUS_WIDTH - 1 : 0]    op_bus,
    input[31 : 0]                       pc,
    input[31 : 0]                       imm,


    output                              sys_excp_vld,
    input                               sys_excp_rdy,
    output                              sys_excp_ecall,
    output                              sys_excp_ebreak,

    // 流水线暂停请求
    output                              pipe_halt_req,
    input                               pipe_halt_ack,


    // 中断有效和debug请求，用于从wfi mode中唤醒cpu
    input                               irq_taken,
    input                               dbg_taken,

    input                               d_mode,

    output                              wfi_mode,

    input                               clk,
    input                               reset_n
);


wire                        instr_is_ecall;
wire                        instr_is_ebreak;
// wire                        instr_is_fence;
// wire                        instr_is_fencei;
wire                        instr_is_wfi;

reg                         wfi_mode_q;
wire                        wfi_mode_set;
wire                        wfi_mode_clr;
wire                        wfi_mode_rld;
wire                        wfi_mode_d;

reg                         pipe_halt_req_q;
wire                        pipe_halt_req_set;
wire                        pipe_halt_req_clr;
wire                        pipe_halt_req_rld;
wire                        pipe_halt_req_d;

wire                        pipe_halt_hsked;

// 首先从总线中解析指令
assign      instr_is_ecall  = op_bus[`SYS_ECALL_LOC];
assign      instr_is_ebreak = op_bus[`SYS_EBREAK_LOC];
assign      instr_is_wfi    = op_bus[`SYS_WFI_LOC];


assign      pipe_halt_hsked = pipe_halt_req & pipe_halt_ack;


// 执行wfi指令后，请求暂停流水线
assign      pipe_halt_req_set = (op_vld & instr_is_wfi) & (~d_mode);
assign      pipe_halt_req_clr = (irq_taken | dbg_taken);
assign      pipe_halt_req_rld = pipe_halt_req_set | pipe_halt_req_clr;
assign      pipe_halt_req_d = ~pipe_halt_req_clr;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        pipe_halt_req_q <= 1'b0;
    end else if(pipe_halt_req_rld) begin
        pipe_halt_req_q <= pipe_halt_req_d;
    end
end

assign      wfi_mode_set = pipe_halt_hsked;
assign      wfi_mode_clr = pipe_halt_req_clr;
assign      wfi_mode_rld = wfi_mode_set | wfi_mode_clr;
assign      wfi_mode_d = ~wfi_mode_clr;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        wfi_mode_q <= 1'b0;
    end else if(wfi_mode_rld) begin
        wfi_mode_q <= wfi_mode_d;
    end
end


assign      pipe_halt_req = pipe_halt_req_q;
assign      wfi_mode = wfi_mode_q & (~wfi_mode_clr);

assign      sys_excp_vld = op_vld;
assign      sys_excp_ecall = instr_is_ecall;
assign      sys_excp_ebreak = instr_is_ebreak;

assign      op_rdy =    instr_is_wfi ? pipe_halt_hsked : 
                        sys_excp_rdy;

endmodule