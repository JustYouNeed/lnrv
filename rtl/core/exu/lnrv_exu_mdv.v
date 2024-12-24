module  lnrv_exu_mdv
(
    input                               op_vld,
    output                              op_rdy,
    input[`MDV_OP_BUS_WIDTH - 1 : 0]    op_bus,


    input[31 : 0]                       rs1_rdata,
    input[31 : 0]                       rs2_rdata,

    output                              gpr_wen,
    output[31 : 0]                      gpr_wdata,

    output                              alu_op_vld,
    input                               alu_op_rdy,
    output[`ALU_OP_BUS_WIDTH - 1 : 0]   alu_op_bus,
    output[32 : 0]                      alu_in1,
    output[32 : 0]                      alu_in2,
    input[34 : 0]                       alu_res,

    output                              cmt_vld,
    input                               cmt_rdy,

    input                               clk,
    input                               reset_n
);

localparam                              S_IDLE = 0;
localparam                              S_CALC = 1;
localparam                              S_DONE = 2;

wire                                    instr_is_mul;
wire                                    instr_is_div;
wire                                    instr_is_rem;
wire                                    op1_is_unsigned;
wire                                    op2_is_unsigned;
wire                                    sel_res_high;

wire[2 : 0]                             booth_code;
wire                                    booth_op_add;
wire                                    booth_op_sub;
wire                                    booth_sel_2a;
wire                                    booth_sel_a;
wire                                    booth_sel_0;

wire                                    booth_add_a;
wire                                    booth_add_2a;
wire                                    booth_sub_a;
wire                                    booth_sub_2a;

reg[3 : 0]                              cycle_q;
wire                                    cycle_inc;
wire                                    cycle_clr;
wire                                    cycle_rld;
wire[3 : 0]                             cycle_d;


// wire[34 : 0]                            adder_res;
wire[32 : 0]                            adder_rs1;
wire[32 : 0]                            adder_rs2;

wire                                    rs1_sign;
wire                                    rs2_sign;
wire[32 : 0]                            rs2_signed_ext;
wire[32 : 0]                            rs2_signed_x2_ext;

reg[32 : 0]                             part_prdt_hi_q;
wire                                    part_prdt_hi_init;
wire                                    part_prdt_hi_srl;
wire                                    part_prdt_hi_rld;
wire[32 : 0]                            part_prdt_hi_d;

reg[32 : 0]                             part_prdt_lo_q;
wire                                    part_prdt_lo_init;
wire                                    part_prdt_lo_srl;
wire                                    part_prdt_lo_rld;
wire[32 : 0]                            part_prdt_lo_d;

reg                                     part_prdt_ext_q;
wire                                    part_prdt_ext_init;
wire                                    part_prdt_ext_srl;
wire                                    part_prdt_ext_rld;
wire                                    part_prdt_ext_d;


reg[3 : 0]                              cur_status;
reg[3 : 0]                              nxt_status;

wire                                    cur_status_is_CALC;
wire                                    cur_status_is_IDLE;
wire                                    cur_status_is_DONE;
wire                                    calc_done;




assign      instr_is_div        = op_bus[`MDV_DIV_LOC];
assign      instr_is_mul        = op_bus[`MDV_MUL_LOC];
assign      instr_is_rem        = op_bus[`MDV_REM_LOC];
assign      op1_is_unsigned     = op_bus[`MDV_OP1_UNSIGNED_LOC];
assign      op2_is_unsigned     = op_bus[`MDV_OP2_UNSIGNED_LOC];
assign      sel_res_high        = op_bus[`MDV_RES_HIGH_LOC];



always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        cur_status <= S_IDLE;
    end else begin
        cur_status <= nxt_status;
    end
end


always@(*) begin
    nxt_status = S_IDLE;

    case(cur_status) 
        S_IDLE: begin
            nxt_status = (op_vld & instr_is_mul) ? S_CALC : S_IDLE;
        end


        S_CALC: nxt_status = calc_done ? S_DONE : S_CALC;
        // S_CALC: nxt_status = S_SHIFT;
        // S_SHIFT: nxt_status = calc_done ? S_DONE : S_CALC;

        default: nxt_status = S_IDLE;
    endcase
end


assign      cur_status_is_CALC = (cur_status == S_CALC);
assign      cur_status_is_IDLE = (cur_status == S_IDLE);
// assign      cur_status_is_SHIFT = (cur_status == S_SHIFT);
assign      cur_status_is_DONE = (cur_status == S_DONE);


assign      rs2_sign = (rs2_rdata[31] & ~op2_is_unsigned);
assign      rs1_sign = (rs1_rdata[31] & ~op1_is_unsigned);
assign      rs2_signed_ext = {rs2_sign, rs2_rdata};
assign      rs2_signed_x2_ext = {rs2_rdata, 1'b0};

assign      booth_code =    cur_status_is_IDLE ? {rs1_rdata[1 : 0], 1'b0} : 
                            cur_status_is_DONE ? {rs1_sign, part_prdt_lo_q[0], part_prdt_ext_q} :
                            {part_prdt_lo_q[1 : 0], part_prdt_ext_q};

assign      booth_op_sub = booth_code[2] & (~(&booth_code[1 : 0]));
assign      booth_op_add = ~booth_op_sub;

assign      booth_sel_a = booth_code[1] ^ booth_code[0];
assign      booth_sel_2a = (booth_code == 3'b011) | (booth_code == 3'b100);
// assign      booth_sel_0 = (booth_code == 3'b000) | (booth_code == 3'b111);

assign      adder_rs1 = cur_status_is_IDLE ? 33'd0 : part_prdt_hi_q;
assign      adder_rs2 = booth_sel_a ? rs2_signed_ext : 
                        booth_sel_2a ? rs2_signed_x2_ext : 
                        33'd0;

// ALU操作总线
assign      alu_op_vld                          = op_vld;
assign      alu_op_bus[`ALU_ADD_LOC]            = booth_op_add;
assign      alu_op_bus[`ALU_SLL_LOC]            = 1'b0;
assign      alu_op_bus[`ALU_SUB_LOC]            = booth_op_sub;
assign      alu_op_bus[`ALU_SRL_LOC]            = 1'b0;
assign      alu_op_bus[`ALU_SRA_LOC]            = 1'b0;
assign      alu_op_bus[`ALU_XOR_LOC]            = 1'b0;
assign      alu_op_bus[`ALU_OR_LOC]             = 1'b0;
assign      alu_op_bus[`ALU_AND_LOC]            = 1'b0;
assign      alu_op_bus[`ALU_LT_LOC]             = 1'b0;
assign      alu_op_bus[`ALU_LTU_LOC]            = 1'b0;
assign      alu_op_bus[`ALU_NEQ_LOC]            = 1'b0;
assign      alu_op_bus[`ALU_EQ_LOC]             = 1'b0;
assign      alu_op_bus[`ALU_GTEU_LOC]           = 1'b0;
assign      alu_op_bus[`ALU_GTE_LOC]            = 1'b0;
assign      alu_op_bus[`ALU_IN1_IS_UNSIGED]     = 1'b0;
assign      alu_op_bus[`ALU_IN2_IS_UNSIGED]     = op2_is_unsigned;

assign      alu_in1                             = adder_rs1;
assign      alu_in2                             = adder_rs2;


assign      part_prdt_hi_init = cur_status_is_IDLE & op_vld;
assign      part_prdt_hi_upd = cur_status_is_CALC | cur_status_is_DONE;
assign      part_prdt_hi_rld = part_prdt_hi_init | part_prdt_hi_upd;
assign      part_prdt_hi_d = alu_res[34 : 2];
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        part_prdt_hi_q <= 33'd0;
    end else if(part_prdt_hi_rld) begin
        part_prdt_hi_q <= part_prdt_hi_d;
    end
end

// assign      part_prdt_lo_init = cur_status_is_IDLE & op_vld;
// assign      part_prdt_lo_upd = cur_status_is_CALC;
assign      part_prdt_lo_rld = part_prdt_hi_rld;
assign      part_prdt_lo_d = part_prdt_hi_init ? {alu_res[1 : 0], rs1_rdata[31] & (~op1_is_unsigned), rs1_rdata[31 : 2]} : 
                                {alu_res[1 : 0], part_prdt_lo_q[32 : 2]};
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        part_prdt_lo_q <= 33'd0;
    end else if(part_prdt_lo_rld) begin
        part_prdt_lo_q <= part_prdt_lo_d;
    end
end

assign      part_prdt_ext_rld = part_prdt_lo_rld;
assign      part_prdt_ext_d = part_prdt_hi_init ? rs1_rdata[1] : part_prdt_lo_q[1];
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        part_prdt_ext_q <= 1'd0;
    end else if(part_prdt_ext_rld) begin
        part_prdt_ext_q <= part_prdt_ext_d;
    end
end

assign      cycle_clr = cur_status_is_DONE;
assign      cycle_inc = cur_status_is_CALC | 
                        (cur_status_is_IDLE & op_vld);
assign      cycle_rld = cycle_clr | cycle_inc;
assign      cycle_d = cycle_clr ? 4'd0 : (cycle_q + 1'b1);
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        cycle_q <= 4'd0;
    end else if(cycle_rld) begin
        cycle_q <= cycle_d;
    end
end

assign      calc_done = &cycle_q;


assign      cmt_vld = cur_status_is_DONE;

assign      gpr_wen = op_vld & cmt_rdy;
assign      gpr_wdata = sel_res_high ? alu_res[31 : 0] : part_prdt_lo_q[32 : 1];

assign      op_rdy = cmt_rdy;


endmodule