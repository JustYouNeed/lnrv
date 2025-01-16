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

localparam[1 : 0]                       S_IDLE = 0;
localparam[1 : 0]                       S_CALC = 1;
localparam[1 : 0]                       S_CALI = 2;
localparam[1 : 0]                       S_DONE = 3;

wire                                    instr_is_mul;
wire                                    instr_is_div;
wire                                    op1_is_signed;
wire                                    op2_is_signed;
wire                                    sel_res_high;

wire                                    rs1_signed;
wire                                    rs2_signed;


// ===========================================================================
//  乘法器和除法器的共享buff
// ===========================================================================
reg[32 : 0]                             sbuf_hi_q;
wire                                    sbuf_hi_rld;
wire[32 : 0]                            sbuf_hi_d;


reg[32 : 0]                             sbuf_lo_q;
wire                                    sbuf_lo_rld;
wire[32 : 0]                            sbuf_lo_d;

// ===========================================================================
//  乘法相关信号定义
// ===========================================================================
// 部分乘积高位
wire[32 : 0]                            part_prdt_hi_q;
wire                                    part_prdt_hi_init;
wire                                    part_prdt_hi_upd;
wire                                    part_prdt_hi_rld;
wire[32 : 0]                            part_prdt_hi_d;

// 部分乘积低位
wire[32 : 0]                            part_prdt_lo_q;
wire                                    part_prdt_lo_init;
wire                                    part_prdt_lo_upd;
wire                                    part_prdt_lo_rld;
wire[32 : 0]                            part_prdt_lo_d;

wire                                    alu_op_add_from_mul;
wire                                    alu_op_sub_from_mul;
wire[32 : 0]                            alu_in1_from_mul;
wire[32 : 0]                            alu_in2_from_mul;

wire                                    sbuf_hi_rld_from_mul;
wire[32 : 0]                            sbuf_hi_d_from_mul;
wire                                    sbuf_lo_rld_from_mul;
wire[32 : 0]                            sbuf_lo_d_from_mul;

wire                                    rs1_sign_mul;
wire                                    rs2_sign_mul;
wire[32 : 0]                            rs2_signed_ext_mul;
wire[32 : 0]                            rs2_signed_x2_ext_mul;

reg                                     part_prdt_ext_q;
wire                                    part_prdt_ext_rld;
wire                                    part_prdt_ext_d;

// booth编码值，基-4算法
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

wire                                    mul_calc_done;

// ===========================================================================
//  除法相关信号定义
// ===========================================================================
wire                                    div_rs1_sign;
wire                                    div_rs2_sign;
wire[31 : 0]                            rs1_data_comp;
wire[31 : 0]                            rs2_data_comp;
wire[31 : 0]                            quotitent_comp;
wire[31 : 0]                            alu_res_comp_for_div;
wire[31 : 0]                            divisor;
wire[31 : 0]                            dividend;

// 余数
wire[32 : 0]                            remainder_q;
wire                                    remainder_rld;
wire[32 : 0]                            remainder_d;

// 商
wire[32 : 0]                            quotitent_q;
wire                                    quotitent_rld;
wire[32 : 0]                            quotitent_d;

wire[32 : 0]                            alu_in1_from_div;
wire[32 : 0]                            alu_in2_from_fiv;
wire                                    alu_op_add_from_div;
wire                                    alu_op_sub_from_div;

wire                                    sbuf_hi_rld_from_div;
wire[32 : 0]                            sbuf_hi_d_from_div;
wire                                    sbuf_lo_rld_from_div;
wire[32 : 0]                            sbuf_lo_d_from_div;

wire                                    div_calc_done;

// ===========================================================================
//  需要统计执行的周期数，乘法计算需要16个周期，除法计算需要32+1个校正周期
// ===========================================================================
reg[4 : 0]                              calc_cycle_q;
wire                                    calc_cycle_inc;
wire                                    calc_cycle_clr;
wire                                    calc_cycle_rld;
wire[4 : 0]                             calc_cycle_d;

wire                                    calc_done;

// ===========================================================================
//  状态机
// ===========================================================================
reg[3 : 0]                              cur_status;
reg[3 : 0]                              nxt_status;

wire                                    cur_status_is_CALC;
wire                                    cur_status_is_IDLE;
wire                                    cur_status_is_CALI;
wire                                    cur_status_is_DONE;



assign      instr_is_div        = op_bus[`MDV_DIV_LOC];
assign      instr_is_mul        = op_bus[`MDV_MUL_LOC];
assign      op1_is_signed       = op_bus[`MDV_OP1_SIGNED_LOC];
assign      op2_is_signed       = op_bus[`MDV_OP2_SIGNED_LOC];
assign      sel_res_high        = op_bus[`MDV_RES_HIGH_LOC];

assign      rs1_signed = op1_is_signed & rs1_rdata[31];
assign      rs2_signed = op2_is_signed & rs2_rdata[31];

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
        S_IDLE: nxt_status = op_vld ? S_CALC : S_IDLE;

        // 如果是除法，需要有一个周期校正结果
        S_CALC: nxt_status = calc_done ? S_CALI : S_CALC;

        S_CALI: nxt_status = S_DONE;

        default: nxt_status = S_IDLE;
    endcase
end


assign      cur_status_is_CALC = (cur_status == S_CALC);
assign      cur_status_is_IDLE = (cur_status == S_IDLE);
assign      cur_status_is_CALI = (cur_status == S_CALI);
assign      cur_status_is_DONE = (cur_status == S_DONE);

// ===========================================================================
//  乘法运算
// ===========================================================================
// 根据操作数符号对rs1/rs2进行符号位扩展
assign      rs2_signed_ext_mul      = {rs2_signed, rs2_rdata};
assign      rs2_signed_x2_ext_mul   = {rs2_rdata, 1'b0};

// 生成booth编码值
assign      booth_code =    cur_status_is_IDLE ? {rs1_rdata[1 : 0], 1'b0} :
                            cur_status_is_CALI ? {rs1_signed, part_prdt_lo_q[0], part_prdt_ext_q} :
                            {part_prdt_lo_q[1 : 0], part_prdt_ext_q};

assign      booth_op_sub = booth_code[2] & (~(&booth_code[1 : 0]));
assign      booth_op_add = ~booth_op_sub;

assign      booth_sel_a     = booth_code[1] ^ booth_code[0];
assign      booth_sel_2a    = (booth_code == 3'b011) | (booth_code == 3'b100);
// assign      booth_sel_0 = (booth_code == 3'b000) | (booth_code == 3'b111);

assign      alu_in1_from_mul = {33{instr_is_mul}} &
                                (
                                    cur_status_is_IDLE ? 33'd0 :
                                    part_prdt_hi_q
                                );

assign      alu_in2_from_mul =  {33{instr_is_mul}} &
                                (
                                    booth_sel_a ? rs2_signed_ext_mul :
                                    booth_sel_2a ? rs2_signed_x2_ext_mul :
                                    33'd0
                                );


assign      alu_op_add_from_mul = booth_op_add & instr_is_mul;
assign      alu_op_sub_from_mul = booth_op_sub & instr_is_mul;

assign      alu_in1_is_unsigned_from_mul =  1'b0 & instr_is_mul;
assign      alu_in2_is_unsigned_from_mul = (~op2_is_signed) & instr_is_mul;

// 将中间结果保存到共享buffer中，hi保存部分积高位
assign      part_prdt_hi_rld    =   instr_is_mul &
                                    (
                                        cur_status_is_IDLE |
                                        cur_status_is_CALC |
                                        cur_status_is_CALI
                                    );
assign      part_prdt_hi_d      = cur_status_is_CALI ? {1'b0, alu_res[31 : 0]} : alu_res[34 : 2];
assign      part_prdt_hi_q      = sbuf_hi_q;

assign      sbuf_hi_rld_from_mul = part_prdt_hi_rld;
assign      sbuf_hi_d_from_mul = part_prdt_hi_d;

// lo保存部分积低位
assign      part_prdt_lo_q = sbuf_lo_q;
assign      part_prdt_lo_rld = part_prdt_hi_rld;
assign      part_prdt_lo_d =    cur_status_is_IDLE ? {alu_res[1 : 0], rs1_signed, rs1_rdata[31 : 2]} :
                                cur_status_is_CALI ? {1'b0, part_prdt_lo_q[32 : 1]} :
                                {alu_res[1 : 0], part_prdt_lo_q[32 : 2]};

assign      sbuf_lo_rld_from_mul    = part_prdt_lo_rld;
assign      sbuf_lo_d_from_mul      = part_prdt_lo_d;

// 需要额外一个比特，只有乘法会用到
assign      part_prdt_ext_rld = part_prdt_lo_rld;
assign      part_prdt_ext_d = cur_status_is_IDLE ? rs1_rdata[1] : part_prdt_lo_q[1];
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        part_prdt_ext_q <= 1'd0;
    end else if(part_prdt_ext_rld) begin
        part_prdt_ext_q <= part_prdt_ext_d;
    end
end

// assign      mul_calc_done = &{calc_cycle_q[4 : 0], instr_is_mul};

// ===========================================================================
//  除法运算
// ===========================================================================
assign      divisor_sign = rs2_signed;
assign      dividend_sign = rs1_signed;

// 先转成补码方式
assign      rs1_data_comp = ~rs1_rdata + 1'b1;
assign      rs2_data_comp = ~rs2_rdata + 1'b1;

assign      quotitent_comp = ~quotitent_q + 1'b1;
assign      alu_res_comp_for_div = ~alu_res[31 : 0] + 1'b1;

// 如果是有符号数，需要使用补码
assign      divisor = divisor_sign ? rs2_data_comp : rs2_rdata;
assign      dividend = dividend_sign ? rs1_data_comp : rs1_rdata;

// 我们把余数部分放到sbuf的高位
assign      remainder_q = sbuf_hi_q;
assign      remainder_rld = instr_is_div &
                            (
                                cur_status_is_IDLE |
                                cur_status_is_CALC |
                                cur_status_is_CALI
                            );
assign      remainder_d =   cur_status_is_IDLE ? 33'd0 :
                            cur_status_is_CALC ? alu_res[32 : 0] :
                            dividend_sign ? alu_res_comp_for_div :
                            alu_res[32 : 0];

assign      sbuf_hi_rld_from_div = remainder_rld;
assign      sbuf_hi_d_from_div = {33{instr_is_div}} & remainder_d;

// 商只会用到sbuf_lo的低32比特
assign      quotitent_q = sbuf_lo_q[31 : 0];
assign      quotitent_rld = remainder_rld;
assign      quotitent_d =   cur_status_is_IDLE ? {1'b0, dividend} :
                            cur_status_is_CALC ? {1'b0, quotitent_q[31 : 0], ~alu_res[32]} :
                            (dividend_sign ^ divisor_sign) ? quotitent_comp :
                            quotitent_q[31 : 0];

assign      sbuf_lo_rld_from_div = quotitent_rld;
assign      sbuf_lo_d_from_div = {33{instr_is_div}} & {1'b0, quotitent_d};


assign      alu_in1_from_div =  {33{instr_is_div}} &
                                (
                                    cur_status_is_CALC ? {remainder_q[31 : 0], quotitent_q[31]} :
                                    {1'b0, remainder_q[31 : 0]}
                                );
assign      alu_in2_from_fiv = {33{instr_is_div}} &
                                (
                                    cur_status_is_CALC ? {1'b0, divisor} :
                                    remainder_q[32] ? {divisor[31], divisor} :
                                33'd0
                                );

assign      alu_op_add_from_div = remainder_q[32] & instr_is_div;
assign      alu_op_sub_from_div = (~remainder_q[32]) & instr_is_div;
assign      alu_in1_is_unsigned_from_div = 1'b0 & instr_is_div;
assign      alu_in2_is_unsigned_from_div = 1'b0 & instr_is_div;

// 除法计算需要32个周期
// assign      div_calc_done = &{calc_cycle_q[5 : 0], instr_is_div};


// ===========================================================================
//  共享buffer
// ===========================================================================
assign      sbuf_hi_rld = sbuf_hi_rld_from_div | sbuf_hi_rld_from_mul;
assign      sbuf_hi_d = sbuf_hi_rld_from_mul ? sbuf_hi_d_from_mul : sbuf_hi_d_from_div;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        sbuf_hi_q <= 33'd0;
    end else if(sbuf_hi_rld) begin
        sbuf_hi_q <= sbuf_hi_d;
    end
end

assign      sbuf_lo_rld = sbuf_lo_rld_from_div | sbuf_lo_rld_from_mul;
assign      sbuf_lo_d = sbuf_lo_rld_from_mul ? sbuf_lo_d_from_mul : sbuf_lo_d_from_div;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        sbuf_lo_q <= 33'd0;
    end else if(sbuf_lo_rld) begin
        sbuf_lo_q <= sbuf_lo_d;
    end
end

// 统计执行周期数
assign      calc_cycle_clr = cur_status_is_DONE;
assign      calc_cycle_inc = cur_status_is_CALC | (cur_status_is_IDLE & instr_is_mul);
assign      calc_cycle_rld = calc_cycle_clr | calc_cycle_inc;
assign      calc_cycle_d = calc_cycle_clr ? 5'd0 : (calc_cycle_q + 1'b1);
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        calc_cycle_q <= 5'd0;
    end else if(calc_cycle_rld) begin
        calc_cycle_q <= calc_cycle_d;
    end
end

assign      calc_done = &{(calc_cycle_q[4] | instr_is_mul), calc_cycle_q[3 : 0]};

// ALU操作总线
assign      alu_op_vld                          = op_vld;
assign      alu_op_bus[`ALU_ADD_LOC]            = alu_op_add_from_mul | alu_op_add_from_div;
assign      alu_op_bus[`ALU_SLL_LOC]            = 1'b0;
assign      alu_op_bus[`ALU_SUB_LOC]            = alu_op_sub_from_mul | alu_op_sub_from_div;
assign      alu_op_bus[`ALU_SRL_LOC]            = 1'b0;
assign      alu_op_bus[`ALU_SRA_LOC]            = 1'b0;
assign      alu_op_bus[`ALU_XOR_LOC]            = 1'b0;
assign      alu_op_bus[`ALU_OR_LOC]             = 1'b0;
assign      alu_op_bus[`ALU_AND_LOC]            = 1'b0;
assign      alu_op_bus[`ALU_LT_LOC]             = 1'b0;
assign      alu_op_bus[`ALU_NEQ_LOC]            = 1'b0;
assign      alu_op_bus[`ALU_EQ_LOC]             = 1'b0;
assign      alu_op_bus[`ALU_GTE_LOC]            = 1'b0;
assign      alu_op_bus[`ALU_IN1_IS_UNSIGED]     = alu_in1_is_unsigned_from_mul | alu_in1_is_unsigned_from_div;
assign      alu_op_bus[`ALU_IN2_IS_UNSIGED]     = alu_in2_is_unsigned_from_mul | alu_in2_is_unsigned_from_div;

assign      alu_in1                             = alu_in1_from_mul | alu_in1_from_div;
assign      alu_in2                             = alu_in2_from_mul | alu_in2_from_fiv;


assign      cmt_vld = cur_status_is_DONE;

assign      gpr_wen = op_vld & cmt_rdy;
assign      gpr_wdata = sel_res_high ? sbuf_hi_q[31 : 0] : sbuf_lo_q[31 : 0];

assign      op_rdy = cmt_rdy;


endmodule