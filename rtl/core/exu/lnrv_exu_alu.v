`include    "lnrv_def.v"
module  lnrv_exu_alu
(
    input                               alu_op_vld,
    output                              alu_op_rdy,
    input[`ALU_OP_BUS_WIDTH - 1 : 0]    alu_op_bus,
    input[31 : 0]                       alu_in1,
    input[31 : 0]                       alu_in2,

    output[31 : 0]                      alu_res
);

wire                    alu_op_add;
wire                    alu_op_and;
wire                    alu_op_or;
wire                    alu_op_xor;
wire                    alu_op_sll;
wire                    alu_op_srl;
wire                    alu_op_sra;
wire                    alu_op_sub;

wire                    alu_cmp_lt;
wire                    alu_cmp_ltu;
wire                    alu_cmp_gteu;
wire                    alu_cmp_gte;
wire                    alu_cmp_eq;
wire                    alu_cmp_neq;



wire                    adder_sub;
wire[32 : 0]            adder_in1;
wire[32 : 0]            adder_in2;
wire[32 : 0]            adder_res;

wire                    adder_in1_signed;
wire                    adder_in2_signed;

wire[31 : 0]            in1_add_in2;
wire[31 : 0]            in1_or_in2;
wire[31 : 0]            in1_xor_in2;
wire[31 : 0]            in1_and_in2;
wire[31 : 0]            in1_sll_in2;
wire[31 : 0]            in1_srl_in2;
wire[31 : 0]            in1_sra_in2;
wire                    in1_eq_in2;
wire                    in1_neq_in2;
wire                    in1_lt_in2;
wire                    in1_lte_in2;
wire                    in1_gt_in2;
wire                    in1_gte_in2;

reg[31 : 0]             in1_bit_invert;
wire[31 : 0]            shift_in1;
reg[31 : 0]             shift_res_invert;
wire[31 : 0]            shift_res;

wire[31 : 0]            sra_mask;

wire                    op_unsigned;

integer                 i;

//从总线中取出各个操作符
assign      alu_op_add  = alu_op_bus[`ALU_ADD_LOC];      // 加法     res = in1 + in2
assign      alu_op_sub  = alu_op_bus[`ALU_SUB_LOC];       
assign      alu_op_and  = alu_op_bus[`ALU_AND_LOC];      // 与       res = in1 & in2
assign      alu_op_or   = alu_op_bus[`ALU_OR_LOC];       // 或       res = in1 | in2
assign      alu_op_xor  = alu_op_bus[`ALU_XOR_LOC];      // 异或     res = in1 ^ in2
assign      alu_op_sll  = alu_op_bus[`ALU_SLL_LOC];      // 逻辑左移 res = in1 << in2
assign      alu_op_srl  = alu_op_bus[`ALU_SRL_LOC];      // 逻辑右移 res = in1 >> in2
assign      alu_op_sra  = alu_op_bus[`ALU_SRA_LOC];      // 算术右移 res = in1 >> in2
assign      alu_cmp_eq   = alu_op_bus[`ALU_EQ_LOC];      // 等于     res = in1 == in2
assign      alu_cmp_neq  = alu_op_bus[`ALU_NEQ_LOC];     // 不等于   res = in1 != in2
assign      alu_cmp_lt   = alu_op_bus[`ALU_LT_LOC];      // 小于     res = in1 < in2
assign      alu_cmp_ltu  = alu_op_bus[`ALU_LTU_LOC];     // 夫符号小于     res = in1 <= in2
assign      alu_cmp_gteu = alu_op_bus[`ALU_GTEU_LOC];    // 无符号大于等于		res = in1 > in2
assign      alu_cmp_gte  = alu_op_bus[`ALU_GTE_LOC];     // 大于等于		res = in1 >= in2


assign      op_unsigned = alu_cmp_ltu | alu_cmp_gteu;

// 需要使用做减法的操作
// 我们同时使用减法实现比大小操作
assign      adder_sub = alu_op_sub | 
                        alu_cmp_lt | 
                        alu_cmp_ltu | 
                        alu_cmp_gteu | 
                        alu_cmp_gte;

assign      adder_in1_signed = alu_in1[31] & (~op_unsigned);
assign      adder_in2_signed = alu_in2[31] & (~op_unsigned);

assign      adder_in1 = {adder_in1_signed, alu_in1};
// 如果是做减法，则先对输入取补码，然后再相加
assign      adder_in2 = adder_sub ? (~{adder_in2_signed, alu_in2}) : {adder_in2_signed, alu_in2};
assign      adder_res = adder_in1 + adder_in2 + adder_sub;


assign      in1_add_in2 = adder_res[31 : 0];

// 先对in1进行进行倒序，这样可以只使用右移操作来实现左移功能
always@(*) begin
    for(i = 0 ; i < 32; i = i + 1) begin
        in1_bit_invert[i] = alu_in1[31 - i];
    end
end
assign      shift_in1 = alu_op_sll ? in1_bit_invert : alu_in1;
assign      shift_res = shift_in1 >> alu_in2[0 +: 5];

// 需要再对移位结果进行倒序
always@(*) begin
    for(i = 0; i < 32; i = i + 1) begin
        shift_res_invert[i] = shift_res[31 - i];
    end
end

// 右移操作直接使用移位操作的输出即可
assign      in1_srl_in2 = shift_res;

// 对于左移操作，还需要对结果进行倒序
assign      in1_sll_in2 = shift_res_invert;

assign      in1_xor_in2 = alu_in1 ^ alu_in2;
assign      in1_or_in2 = alu_in1 | alu_in2;
assign      in1_and_in2 = alu_in1 & alu_in2;

// 算术右移，需要保留符号位
assign      sra_mask = {`CPU_DATA_WIDTH{1'b1}} >> alu_in2[0 +: `GPR_ADDR_WIDTH];
assign      in1_sra_in2 =   (in1_srl_in2 & sra_mask) | 
                            ({`CPU_DATA_WIDTH{alu_in1[`CPU_DATA_WIDTH - 1]}} & (~sra_mask));


assign      in1_neq_in2 = |in1_xor_in2;
assign      in1_eq_in2 = (~in1_neq_in2);

// 对于比较操作，我们使用了减法完成，因此只需要判断运算结果的最高位即可，为1表示结果
// 为负，即in1 < in2
assign      in1_lt_in2 = adder_res[32];
// assign      in1_lte_in2 = in1_lt_in2 | in1_eq_in2;
// assign      in1_gt_in2 = (~in1_lt_in2) & in1_neq_in2;
assign      in1_gte_in2 = (~in1_lt_in2);

assign      alu_res =   (alu_op_add | alu_op_sub) ? in1_add_in2 : 
                        (alu_op_and) ? in1_and_in2 : 
                        (alu_op_or) ? in1_or_in2 : 
                        (alu_op_xor) ? in1_xor_in2 : 
                        (alu_op_sll) ? in1_sll_in2 : 
                        (alu_op_srl) ? in1_srl_in2 : 
                        (alu_op_sra) ? in1_sra_in2 : 
                        (alu_cmp_lt | alu_cmp_ltu) ? {31'd0, in1_lt_in2} : 
                        // alu_cmp_ltu ? {31'd0, in1_lte_in2} : 
                        alu_cmp_eq ? {31'd0, in1_eq_in2} : 
                        // alu_cmp_gteu ? {31'd0, in1_gt_in2} : 
                        (alu_cmp_gte | alu_cmp_gteu) ? {31'd0, in1_gte_in2} : 
                        alu_cmp_neq ? {31'd0, in1_neq_in2} : 
                        32'd0;

// alu运算模块是纯组合逻辑，只要valid拉高，ready就有效
assign      alu_op_rdy = alu_op_vld;

endmodule