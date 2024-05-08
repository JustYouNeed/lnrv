`include    "lnrv_def.v"
module	lnrv_exu_disp
(
    input                               idu_rglr_instr,
    input                               idu_brch_instr,
    input                               idu_csr_instr,
    input                               idu_sys_instr,
    input                               idu_mdv_instr,
    input                               idu_lsu_instr,

    input[`DEC_OP_BUS_WIDTH - 1 : 0]    idu_op_bus,
    input                               idu_op_vld,
    output                              idu_op_rdy,

    // 前级模块产生的异常信息
    input                               ifu_excp_misalgn,        // 地址非对齐
    input                               ifu_excp_buserr,         // 总线错误
    input                               idu_excp_ilgl_ir,   // 非法指令

    // 常规指令 
    output                              rglr_op_vld,
    input                               rglr_op_rdy,
    output[`RGLR_OP_BUS_WIDTH - 1 : 0]  rglr_op_bus,

    // 访问指令
    output                              lsu_op_vld,
    input                               lsu_op_rdy,
    output[`LSU_OP_BUS_WIDTH - 1 : 0]   lsu_op_bus,

    // 分支指令
    output                              brch_op_vld,
    input                               brch_op_rdy,
    output[`BRCH_OP_BUS_WIDTH - 1 : 0]  brch_op_bus,

    // csr相关指令 
    output                              csr_op_vld,
    input                               csr_op_rdy,
    output[`CSR_OP_BUS_WIDTH - 1 : 0]   csr_op_bus,

    // 系统指令
    output                              sys_op_vld,
    input                               sys_op_rdy,
    output[`SYS_OP_BUS_WIDTH - 1 : 0]   sys_op_bus,

    // 乘除法指令
    output                              mdv_op_vld,
    input                               mdv_op_rdy,
    output[`MDV_OP_BUS_WIDTH - 1 : 0]   mdv_op_bus,


    output                              disp_idu_excp_ilgl_ir,
    output                              disp_ifu_excp_buserr,
    output                              disp_ifu_excp_misalgn,

    output                              disp_condition,
    output                              disp_hsked,
    output                              disp_idle
);


wire                                    pre_stg_err;
wire                                    no_pre_stg_err;


assign      pre_stg_err     = ifu_excp_buserr | ifu_excp_misalgn | idu_excp_ilgl_ir;
assign      no_pre_stg_err  = ~pre_stg_err;
assign      disp_condition  = idu_pc_vld & no_pre_stg_err;

// 将来自前级模块的异常派发
assign      disp_idu_excp_ilgl_ir = idu_pc_vld & idu_excp_ilgl_ir;
assign      disp_ifu_excp_buserr = idu_pc_vld & ifu_excp_buserr;
assign      disp_ifu_excp_misalgn = idu_pc_vld & ifu_excp_misalgn;

// 派发到常规指令模块执行
assign      rglr_op_vld = idu_rglr_instr & disp_condition;
assign      rglr_op_bus = {`RGLR_OP_BUS_WIDTH{rglr_op_vld}} & idu_op_bus[0 +: `RGLR_OP_BUS_WIDTH];

// 派发到访存模块执行
assign      lsu_op_vld = idu_lsu_instr & disp_condition; 
assign      lsu_op_bus = {`LSU_OP_BUS_WIDTH{lsu_op_vld}} & idu_op_bus[0 +: `LSU_OP_BUS_WIDTH];

// 派发到分支模块执行
assign      brch_op_vld = idu_brch_instr & disp_condition;
assign      brch_op_bus = {`BRCH_OP_BUS_WIDTH{brch_op_vld}} & idu_op_bus[0 +: `BRCH_OP_BUS_WIDTH];

// 派发到CSR模块执行
assign      csr_op_vld = idu_csr_instr & disp_condition;
assign      csr_op_bus = {`CSR_OP_BUS_WIDTH{csr_op_vld}} & idu_op_bus[0 +: `CSR_OP_BUS_WIDTH];

// 派发到系统指令模块执行
assign      sys_op_vld = idu_sys_instr & disp_condition;
assign      sys_op_bus = {`SYS_OP_BUS_WIDTH{sys_op_vld}} & idu_op_bus[0 +: `SYS_OP_BUS_WIDTH];

// 派发到乘除法指令模块执行
assign      mdv_op_vld = idu_mdv_instr & disp_condition;
assign      mdv_op_bus = {`MDV_OP_BUS_WIDTH{mdv_op_vld}} & idu_op_bus[0 +: `MDV_OP_BUS_WIDTH];


assign      idu_op_rdy =    (rglr_op_vld & rglr_op_rdy) | 
                            (lsu_op_vld & lsu_op_rdy) | 
                            (brch_op_vld & brch_op_rdy) | 
                            (csr_op_vld & csr_op_rdy) | 
                            (sys_op_vld & sys_op_rdy) | 
                            (mdv_op_vld & mdv_op_rdy);

assign      disp_hsked = idu_op_vld & idu_op_rdy;
assign      disp_idle = (~idu_op_vld) | disp_hsked;

endmodule	
