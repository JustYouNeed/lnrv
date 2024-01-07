`include "lnrv_def.v"
module  lnrv_exu_wbck
(
    // 对于常规指令、brch指令，写回数据都来自于alu运算单元，
    // 所以不需要额外输入写回数据
    input                   rglr2gpr_wbck_vld,
    output                  rglr2gpr_wbck_rdy,

    input                   brch2gpr_wbck_vld,
    output                  brch2gpr_wbck_rdy,

    // 对于lsu指令，写回数据并不来自alu，需要额外输入
    input                   lsu2gpr_wbck_vld,
    output                  lsu2gpr_wbck_rdy,
    input[31 : 0]           lsu2gpr_wbck_wdata,

    input                   csr2gpr_wbck_vld,
    output                  csr2gpr_wbck_rdy,
    input[31 : 0]           csr2gpr_wbck_wdata,

    input                   mdv2gpr_wbck_vld,
    output                  mdv2gpr_wbck_rdy,
    input[31 : 0]           mdv2gpr_wbck_wdata,

    // 无论是什么指令，写回寄存器都是来自于rd
    input[4 : 0]            rd_idx,
    input[31 : 0]           alu_res,

    output                  gpr_wbck_vld,
    input                   gpr_wbck_rdy,
    output[4 : 0]           gpr_wbck_idx,
    output[31 : 0]          gpr_wbck_wdata
);

assign      gpr_wbck_vld =  rglr2gpr_wbck_vld | 
                            csr2gpr_wbck_vld | 
                            brch2gpr_wbck_vld | 
                            lsu2gpr_wbck_vld | 
                            mdv2gpr_wbck_vld;

assign      gpr_wbck_idx = rd_idx;

assign      gpr_wbck_wdata =   lsu2gpr_wbck_vld ? lsu2gpr_wbck_wdata : 
                            mdv2gpr_wbck_vld ? mdv2gpr_wbck_wdata : 
                            csr2gpr_wbck_vld ? csr2gpr_wbck_wdata : 
                            alu_res;

assign      rglr2gpr_wbck_rdy = gpr_wbck_rdy;
assign      brch2gpr_wbck_rdy = gpr_wbck_rdy;
assign      lsu2gpr_wbck_rdy = gpr_wbck_rdy;
assign      mdv2gpr_wbck_rdy = gpr_wbck_rdy;
assign      csr2gpr_wbck_rdy = gpr_wbck_rdy;

endmodule