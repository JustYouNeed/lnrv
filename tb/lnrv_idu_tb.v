`include "lnrv_def.v"
module  lnrv_idu_tb;

// outports wire
wire                         	ifu_ir_rdy;
wire                         	pipe_halt_ack;
wire                         	pipe_flush_ack;
wire                         	dec_idu_instr_ilegl;
wire                         	dec_ifu_misalgn;
wire                         	dec_ifu_buserr;
wire                         	dec_rglr_instr;
wire                         	dec_lsu_instr;
wire                         	dec_csr_instr;
wire                         	dec_brch_instr;
wire                         	dec_mdv_instr;
wire                         	dec_sys_instr;
wire                         	dec_amo_instr;
wire                         	dec_fpu_instr;
wire [`DEC_OP_BUS_WIDTH-1:0] 	dec_op_bus;
wire                         	dec_op_vld;
wire [31:0]                  	dec_ir;
wire [31:0]                  	dec_pc;
wire [31:0]                  	dec_imm;
wire [4:0]                   	dec_rs1_idx;
wire [4:0]                   	dec_rs2_idx;
wire [11:0]                  	dec_csr_idx;
wire [4:0]                   	dec_rd_idx;
wire                         	dec_rv32;
wire                         	dec_rv16;

reg                         clk;
reg                         reset_n;

reg[31 : 0]                 ifu_ir;
reg[31 : 0]                 ifu_pc;
reg                         ifu_ir_vld;

lnrv_idu u_lnrv_idu
(
    .ifu_ir_vld             ( ifu_ir_vld           ),
    .ifu_ir_rdy             ( ifu_ir_rdy           ),
    .ifu_ir                 ( ifu_ir               ),
    .ifu_pc                 ( ifu_pc               ),
    .ifu_misalgn            ( 1'b0                  ),
    .ifu_buserr             ( 1'b0                  ),
    .pipe_halt_req          ( 1'b0                  ),
    .pipe_halt_ack          ( pipe_halt_ack        ),
    .pipe_flush_req         ( 1'b0                  ),
    .pipe_flush_ack         ( pipe_flush_ack       ),
    .d_mode                 ( 1'b0                  ),
    .dec_idu_instr_ilegl    ( dec_idu_instr_ilegl  ),
    .dec_ifu_misalgn        ( dec_ifu_misalgn      ),
    .dec_ifu_buserr         ( dec_ifu_buserr       ),
    .dec_rglr_instr         ( dec_rglr_instr       ),
    .dec_lsu_instr          ( dec_lsu_instr        ),
    .dec_csr_instr          ( dec_csr_instr        ),
    .dec_brch_instr         ( dec_brch_instr       ),
    .dec_mdv_instr          ( dec_mdv_instr        ),
    .dec_sys_instr          ( dec_sys_instr        ),
    .dec_amo_instr          ( dec_amo_instr        ),
    .dec_fpu_instr          ( dec_fpu_instr        ),
    .dec_op_bus             ( dec_op_bus           ),
    .dec_op_vld             ( dec_op_vld           ),
    .dec_op_rdy             ( 1'b1           ),
    .dec_ir                 ( dec_ir               ),
    .dec_pc                 ( dec_pc               ),
    .dec_imm                ( dec_imm              ),
    .dec_rs1_idx            ( dec_rs1_idx          ),
    .dec_rs2_idx            ( dec_rs2_idx          ),
    .dec_csr_idx            ( dec_csr_idx          ),
    .dec_rd_idx             ( dec_rd_idx           ),
    .dec_rv32               ( dec_rv32             ),
    .dec_rv16               ( dec_rv16             ),
    .clk                    ( clk                  ),
    .reset_n                ( reset_n              )
);



initial begin
    clk = 1'b0;
    reset_n = 1'b0;

    # 100;
    reset_n = 1'b1;

    #2000;
    $finish;
end

initial
begin            
    $dumpfile("wave.vcd");        //生成的vcd文件名称
    $dumpvars(0, lnrv_idu_tb);    //tb模块名称
end

always #10 clk = ~clk;

	// |		0001000	   |   00101  |   00000   |  000  | 	00000	|   1110011  |
initial begin
    ifu_ir = 0;
    ifu_ir_vld = 0;
    wait(reset_n == 1'b1);
    @(posedge clk) begin
        ifu_ir <= {7'b0001000, 5'b00101, 5'b00000, 3'b000, 5'b00000, 7'b1110011};
        ifu_ir_vld <= 1'b1;
    end
end

endmodule