`include	"lnrv_def.v"
module	lnrv_exu_alu_mux
(
    // 有四个模块需要使用alu，但是不会同时使用，因为是单发射流水线
    input                               rglr2alu_op_vld,
    output                              rglr2alu_op_rdy,
    input[`ALU_OP_BUS_WIDTH - 1 : 0]    rglr2alu_op_bus,
    input[31 : 0]                       rglr2alu_in1,
    input[31 : 0]                       rglr2alu_in2,

    input                               brch2alu_op_vld,
    output                              brch2alu_op_rdy,
    input[`ALU_OP_BUS_WIDTH - 1 : 0]    brch2alu_op_bus,
    input[31 : 0]                       brch2alu_in1,
    input[31 : 0]                       brch2alu_in2,

    input                               csr2alu_op_vld,
    output                              csr2alu_op_rdy,
    input[`ALU_OP_BUS_WIDTH - 1 : 0]    csr2alu_op_bus,
    input[31 : 0]                       csr2alu_in1,
    input[31 : 0]                       csr2alu_in2,

    input                               lsu2alu_op_vld,
    output                              lsu2alu_op_rdy,
    input[`ALU_OP_BUS_WIDTH - 1 : 0]    lsu2alu_op_bus,
    input[31 : 0]                       lsu2alu_in1,
    input[31 : 0]                       lsu2alu_in2,

    output                              alu_op_vld,
    input                               alu_op_rdy,
    output[`ALU_OP_BUS_WIDTH - 1 : 0]   alu_op_bus,
    output[31 : 0]                      alu_in1,
    output[31 : 0]                      alu_in2
);

assign      alu_op_vld = rglr2alu_op_vld | brch2alu_op_vld | csr2alu_op_vld | lsu2alu_op_vld;
assign      alu_op_bus = {{`ALU_OP_BUS_WIDTH{rglr2alu_op_vld}} & rglr2alu_op_bus} | 
                         {{`ALU_OP_BUS_WIDTH{brch2alu_op_vld}} & brch2alu_op_bus} | 
                         {{`ALU_OP_BUS_WIDTH{csr2alu_op_vld}} & csr2alu_op_bus} | 
                         {{`ALU_OP_BUS_WIDTH{lsu2alu_op_vld}} & lsu2alu_op_bus};

assign      alu_in1 =   {{32{rglr2alu_op_vld}} & rglr2alu_in1} | 
                        {{32{brch2alu_op_vld}} & brch2alu_in1} | 
                        {{32{csr2alu_op_vld}} & csr2alu_in1} | 
                        {{32{lsu2alu_op_vld}} & lsu2alu_in1};

assign      alu_in2 =   {{32{rglr2alu_op_vld}} & rglr2alu_in2} | 
                        {{32{brch2alu_op_vld}} & brch2alu_in2} | 
                        {{32{csr2alu_op_vld}} & csr2alu_in2} | 
                        {{32{lsu2alu_op_vld}} & lsu2alu_in2};

assign      rglr2alu_op_rdy = alu_op_rdy;
assign      brch2alu_op_rdy = alu_op_rdy;
assign      csr2alu_op_rdy = alu_op_rdy;
assign      lsu2alu_op_rdy = alu_op_rdy;

endmodule