`include    "lnrv_def.v"
module	lnrv_exu_disp
(
    input[`DEC_OP_BUS_WIDTH - 1 : 0]    idu_op_bus,
    input[`DEC_OP_TYPE_WIDTH - 1 : 0]   idu_op_type,
    input                               idu_excp_buserr,
    input                               idu_excp_ilglir,
    input                               idu_excp_misalgn,

    // 常规指令 
    output                              sel_rglr,
    output[`RGLR_OP_BUS_WIDTH - 1 : 0]  rglr_op_bus,

    // 访问指令
    output                              sel_lsu,
    output[`LSU_OP_BUS_WIDTH - 1 : 0]   lsu_op_bus,

    // 分支指令
    output                              sel_brch,
    output[`BRCH_OP_BUS_WIDTH - 1 : 0]  brch_op_bus,

    // csr相关指令 
    output                              sel_csr,
    output[`CSR_OP_BUS_WIDTH - 1 : 0]   csr_op_bus,

    // 系统指令
    output                              sel_sys,
    output[`SYS_OP_BUS_WIDTH - 1 : 0]   sys_op_bus,

    // 乘除法指令
    output                              sel_mdv,
    output[`MDV_OP_BUS_WIDTH - 1 : 0]   mdv_op_bus
);

wire                                    idu_rglr_instr;
wire                                    idu_amo_instr;
wire                                    idu_brch_instr;
wire                                    idu_sys_instr;
wire                                    idu_lsu_instr;
wire                                    idu_csr_instr;
wire                                    idu_mdv_instr;
wire                                    disp_abort;
wire                                    disp_enable;

assign      disp_abort = idu_excp_buserr | 
                         idu_excp_ilglir | 
                         idu_excp_misalgn;

assign      disp_enable = ~disp_abort;

assign      idu_amo_instr = (idu_op_type == `DEC_AMO_BUS) & disp_enable;
assign      idu_rglr_instr = (idu_op_type == `DEC_RGLR_BUS) & disp_enable;
assign      idu_brch_instr = (idu_op_type == `DEC_BRCH_BUS) & disp_enable;
assign      idu_sys_instr = (idu_op_type == `DEC_SYS_BUS) & disp_enable;
assign      idu_csr_instr = (idu_op_type == `DEC_CSR_BUS) & disp_enable;
assign      idu_lsu_instr = (idu_op_type == `DEC_LSU_BUS) & disp_enable;
assign      idu_mdv_instr = (idu_op_type == `DEC_MDV_BUS) & disp_enable;

// 派发到常规指令模块执行
assign      sel_rglr = idu_rglr_instr;
assign      rglr_op_bus = {`RGLR_OP_BUS_WIDTH{sel_rglr}} & idu_op_bus[0 +: `RGLR_OP_BUS_WIDTH];

// 派发到访存模块执行
assign      sel_lsu = idu_lsu_instr; 
assign      lsu_op_bus = {`LSU_OP_BUS_WIDTH{sel_lsu}} & idu_op_bus[0 +: `LSU_OP_BUS_WIDTH];

// 派发到分支模块执行
assign      sel_brch = idu_brch_instr;
assign      brch_op_bus = {`BRCH_OP_BUS_WIDTH{sel_brch}} & idu_op_bus[0 +: `BRCH_OP_BUS_WIDTH];

// 派发到CSR模块执行
assign      sel_csr = idu_csr_instr;
assign      csr_op_bus = {`CSR_OP_BUS_WIDTH{sel_csr}} & idu_op_bus[0 +: `CSR_OP_BUS_WIDTH];

// 派发到系统指令模块执行
assign      sel_sys = idu_sys_instr;
assign      sys_op_bus = {`SYS_OP_BUS_WIDTH{sel_sys}} & idu_op_bus[0 +: `SYS_OP_BUS_WIDTH];

// 派发到乘除法指令模块执行
assign      sel_mdv = idu_mdv_instr;
assign      mdv_op_bus = {`MDV_OP_BUS_WIDTH{sel_mdv}} & idu_op_bus[0 +: `MDV_OP_BUS_WIDTH];


endmodule	
