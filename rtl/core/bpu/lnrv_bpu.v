module lnrv_bpu
(
    input[31 : 0]               ifu_pc,

    input                       ifu_vld,
    input                       ifu_rdy,

    input                       idu_vld,
    input                       idu_rdy,

    input[4 : 0]                idu_rd,

    input[31 : 0]               gpr_x1,


    input                       dec_ir_jal,
    input                       dec_ir_jalr,
    input                       dec_ir_fence,
    input                       dec_ir_bxx,
    input[31 : 0]               dec_imm_bxx,
    input[31 : 0]               dec_imm_jal,
    input[31 : 0]               dec_imm_jalr,
    input                       dec_rs1_x1,


    output                      pipe_flush_req,
    input                       pipe_flush_ack,
    output[31 : 0]              pipe_flush_pc_op1,
    output[31 : 0]              pipe_flush_pc_op2,

    output                      bpu_prdt_res,

    input                       clk,
    input                       reset_n
);

wire                            pipe_flush_hsked;
wire                            idu_push_hsked;
wire                            idu_pop_hsked;

reg                             bpu_prdt_res_q;
wire                            bpu_prdt_res_set;
wire                            bpu_prdt_res_clr;
wire                            bpu_prdt_res_rld;
wire                            bpu_prdt_res_d;

wire                            pipe_flush_req_bxx;
wire                            pipe_flush_req_jal;
wire                            pipe_flush_req_jalr;
wire                            pipe_flush_req_fence;

wire                            bxx_jump_backward;
wire                            idu_rd_not_x1;


assign      pipe_flush_hsked = pipe_flush_req & pipe_flush_ack;

assign      idu_push_hsked = ifu_vld & ifu_rdy;
assign      idu_pop_hsked = idu_vld & idu_rdy;

assign      idu_rd_not_x1 = |{idu_rd[4 : 1], ~idu_rd[0]};

assign      bpu_prdt_res_set = pipe_flush_hsked;
assign      bpu_prdt_res_clr = idu_pop_hsked;
assign      bpu_prdt_res_rld = bpu_prdt_res_set | bpu_prdt_res_clr;
assign      bpu_prdt_res_d = bpu_prdt_res_set;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        bpu_prdt_res_q <= 1'b0;
    end else if(bpu_prdt_res_rld) begin
        bpu_prdt_res_q <= bpu_prdt_res_d;
    end
end

// 对于bneq/bnez/bge/bgeu/blt/bltu等指令，如果是身后跳，则认为分支成立，
assign      bxx_jump_backward = dec_imm_bxx[31];
assign      pipe_flush_req_bxx = dec_ir_bxx & bxx_jump_backward;

// jal指令一定会跳转
assign      pipe_flush_req_jal = dec_ir_jal;

// fence指令一定会冲刷流水线
assign      pipe_flush_req_fence = dec_ir_fence;

// 对于jalr指令，只有在rs1是x1寄存器，且前一条指令的rd不是x1时，我们才跳转，防止上一条指令修改了x1寄存器
assign      pipe_flush_req_jalr = dec_ir_jalr & dec_rs1_x1 & idu_rd_not_x1;

assign      pipe_flush_req =    idu_push_hsked &
                                (
                                    pipe_flush_req_bxx |
                                    pipe_flush_req_jal |
                                    pipe_flush_req_jalr |
                                    pipe_flush_req_fence
                                );

assign      pipe_flush_pc_op1 = pipe_flush_req_jalr ? gpr_x1 : ifu_pc;

assign      pipe_flush_pc_op2 = pipe_flush_req_jalr ? dec_imm_jalr :
                                pipe_flush_req_bxx ? dec_imm_bxx :
                                pipe_flush_req_jal ? dec_imm_jal :
                                32'd4;

assign      bpu_prdt_res = bpu_prdt_res_q;

endmodule
