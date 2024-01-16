`include    "lnrv_def.v"
module	lnrv_exu_disp
(
    input                               dec_rglr_instr,
    input                               dec_brch_instr,
    input                               dec_csr_instr,
    input                               dec_sys_instr,
    input                               dec_mdv_instr,
    input                               dec_lsu_instr,

    input[`DEC_OP_BUS_WIDTH - 1 : 0]    dec_op_bus,
    input                               dec_op_vld,
    output                              dec_op_rdy,

    output                              rglr_op_vld,
    input                               rglr_op_rdy,
    output[`RGLR_OP_BUS_WIDTH - 1 : 0]  rglr_op_bus,

    output                              lsu_op_vld,
    input                               lsu_op_rdy,
    output[`LSU_OP_BUS_WIDTH - 1 : 0]   lsu_op_bus,

    output                              brch_op_vld,
    input                               brch_op_rdy,
    output[`BRCH_OP_BUS_WIDTH - 1 : 0]  brch_op_bus,

    output                              csr_op_vld,
    input                               csr_op_rdy,
    output[`CSR_OP_BUS_WIDTH - 1 : 0]   csr_op_bus,

    output                              sys_op_vld,
    input                               sys_op_rdy,
    output[`SYS_OP_BUS_WIDTH - 1 : 0]   sys_op_bus,

    output                              mdv_op_vld,
    input                               mdv_op_rdy,
    output[`MDV_OP_BUS_WIDTH - 1 : 0]   mdv_op_bus,


    output                              disp_vld,
    output                              disp_hsked,
    output                              disp_idle
);



assign      rglr_op_vld = dec_rglr_instr & dec_op_vld;
assign      rglr_op_bus = {`RGLR_OP_BUS_WIDTH{rglr_op_vld}} & dec_op_bus[0 +: `RGLR_OP_BUS_WIDTH];

assign      lsu_op_vld = dec_lsu_instr & dec_op_vld;
assign      lsu_op_bus = {`LSU_OP_BUS_WIDTH{lsu_op_vld}} & dec_op_bus[0 +: `LSU_OP_BUS_WIDTH];

assign      brch_op_vld = dec_brch_instr & dec_op_vld;
assign      brch_op_bus = {`BRCH_OP_BUS_WIDTH{brch_op_vld}} & dec_op_bus[0 +: `BRCH_OP_BUS_WIDTH];

assign      csr_op_vld = dec_csr_instr & dec_op_vld;
assign      csr_op_bus = {`CSR_OP_BUS_WIDTH{csr_op_vld}} & dec_op_bus[0 +: `CSR_OP_BUS_WIDTH];

assign      sys_op_vld = dec_sys_instr & dec_op_vld;
assign      sys_op_bus = {`SYS_OP_BUS_WIDTH{sys_op_vld}} & dec_op_bus[0 +: `SYS_OP_BUS_WIDTH];

assign      mdv_op_vld = dec_mdv_instr & dec_op_vld;
assign      mdv_op_bus = {`MDV_OP_BUS_WIDTH{mdv_op_vld}} & dec_op_bus[0 +: `MDV_OP_BUS_WIDTH];


assign      dec_op_rdy =    (dec_rglr_instr & rglr_op_rdy) | 
                            (dec_lsu_instr & lsu_op_rdy) | 
                            (dec_brch_instr & brch_op_rdy) | 
                            (dec_sys_instr & sys_op_rdy) | 
                            (dec_mdv_instr & mdv_op_rdy) | 
                            (dec_csr_instr & csr_op_rdy);

assign      disp_vld =  dec_op_vld & 
                        (
                            dec_rglr_instr | 
                            dec_lsu_instr | 
                            dec_brch_instr | 
                            dec_sys_instr |
                            dec_mdv_instr | 
                            dec_csr_instr
                        );


assign      disp_hsked = dec_op_vld & dec_op_rdy;
assign      disp_idle = (~disp_vld) | disp_hsked;

endmodule	
