module mul32x32_booth4
(
    input                           clk,
    input                           reset_n,

    input[31 : 0]                   in1,
    input                           in1_is_unsigned,
    input[31 : 0]                   in2,
    input                           in2_is_unsigned,
    output[63 : 0]                  out,
    input                           op_vld,
    output                          op_rdy
);

wire[2 : 0]                         booth_code;

reg[32 : 0]                         booth_cof_q;
wire                                booth_cof_upd;
wire                                booth_cof_srl;
wire                                booth_cof_rld;
wire[32 : 0]                        booth_cof_d;


reg[3 : 0]                          cycle_q;
wire                                cycle_inc;
wire                                cycle_clr;
wire                                cycle_rld;
wire[3 : 0]                         cycle_d;

wire                                cycle_0th;


localparam                          S_IDLE = 0;
localparam                          S_CALC_PRE = 1;
localparam                          S_CALC = 2;
localparam                          S_SHIFT = 3;
localparam                          S_DONE = 4;

reg[3 : 0]                          cur_status;
reg[3 : 0]                          nxt_status;

wire                                cur_status_is_CALC;
wire                                cur_status_is_IDLE;
wire                                cur_status_is_SHIFT;
wire                                cur_status_is_DONE;
wire                                calc_done;

reg[63 : 0]                         mul_res_q;
wire                                mul_res_rlr;
wire                                mul_res_upd;
wire                                mul_res_rld;
wire[63 : 0]                        mul_res_d;



wire[34 : 0]                        adder_res;
wire[34 : 0]                        adder_in1;
wire[34 : 0]                        adder_in2;

reg[32 : 0]                         part_prdt_hi_q;
wire                                part_prdt_hi_init;
wire                                part_prdt_hi_srl;
wire                                part_prdt_hi_rld;
wire[32 : 0]                        part_prdt_hi_d;

reg[32 : 0]                         part_prdt_lo_q;
wire                                part_prdt_lo_init;
wire                                part_prdt_lo_srl;
wire                                part_prdt_lo_rld;
wire[32 : 0]                        part_prdt_lo_d;

reg                                 part_prdt_ext_q;
wire                                part_prdt_ext_init;
wire                                part_prdt_ext_srl;
wire                                part_prdt_ext_rld;
wire                                part_prdt_ext_d;


reg[67 : 0]                         op_buf_q;
wire                                op_buf_init;
wire                                op_buf_srl;
wire                                op_buf_upd;
wire                                op_buf_rld;
wire[67 : 0]                        op_buf_d;

genvar                              i;

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
            nxt_status = op_vld ? S_CALC : S_IDLE;
        end

        S_CALC_PRE: nxt_status = S_CALC;

        S_CALC: nxt_status = calc_done ? S_DONE : S_CALC;
        // S_CALC: nxt_status = S_SHIFT;
        S_SHIFT: nxt_status = calc_done ? S_DONE : S_CALC;

        default: nxt_status = S_IDLE;
    endcase
end


assign      cur_status_is_CALC = (cur_status == S_CALC);
assign      cur_status_is_IDLE = (cur_status == S_IDLE);
assign      cur_status_is_SHIFT = (cur_status == S_SHIFT);
assign      cur_status_is_DONE = (cur_status == S_DONE);


// generate
//     for(i = 0; i < 16; i = i + 1) begin
//         if(i == 0) begin
//             assign      booth_code[i] = {in2[1 : 0], 1'b0}
//         end else begin
//             assign      booth_code[i] = {in2[i + 2 +: 3]};
//         end
//     end
// endgenerate

assign      booth_cof_upd = cur_status_is_IDLE & op_vld;
assign      booth_cof_srl = cur_status_is_CALC;
assign      booth_cof_rld = booth_cof_srl | booth_cof_upd;
assign      booth_cof_d = booth_cof_upd ? {in2, 1'b0} : {2'b00, booth_cof_q[2 +: 31]};
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        booth_cof_q <= {33{1'b0}};
    end else if(booth_cof_rld) begin
        booth_cof_q <= booth_cof_d;
    end
end

wire                in2_sign = (in2[31] & ~in2_is_unsigned);
wire                in1_sign = (in1[31] & ~in1_is_unsigned);
wire[34 : 0]        in2_signed = {{3{in2_sign}}, in2};
wire[34 : 0]        in2_signed_x2 = {in2_sign, in2_sign, in2, 1'b0};

assign      booth_code =    cur_status_is_IDLE ? {in1[1 : 0], 1'b0} : 
                            cur_status_is_DONE ? {in1_sign, part_prdt_lo_q[0], part_prdt_ext_q} :
                            {part_prdt_lo_q[1 : 0], part_prdt_ext_q};

assign      booth_add_a =   (booth_code == 3'b001) |
                            (booth_code == 3'b010);

assign      booth_add_2a =  (booth_code == 3'b011);

assign      booth_sub_2a =  (booth_code == 3'b100);

assign      booth_sub_a =   (booth_code == 3'b101) | 
                            (booth_code == 3'b110);



assign      adder_in1 = cur_status_is_IDLE ? 35'd0 : {part_prdt_hi_q[32], part_prdt_hi_q[32], part_prdt_hi_q};
assign      adder_in2 = booth_add_a ? in2_signed : 
                        booth_add_2a ? in2_signed_x2 : 
                        booth_sub_a ? (~in2_signed) : 
                        booth_sub_2a ? (~in2_signed_x2) : 
                        35'd0;
assign      adder_res = adder_in1 + adder_in2 + (booth_sub_a | booth_sub_2a);



assign      part_prdt_hi_init = cur_status_is_IDLE & op_vld;
assign      part_prdt_hi_upd = cur_status_is_CALC | cur_status_is_DONE;
assign      part_prdt_hi_rld = part_prdt_hi_init | part_prdt_hi_upd;
assign      part_prdt_hi_d = adder_res[34 : 2];
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
assign      part_prdt_lo_d = part_prdt_hi_init ? {adder_res[1 : 0], in1[31] & (~in1_is_unsigned), in1[31 : 2]} : 
                                {adder_res[1 : 0], part_prdt_lo_q[32 : 2]};
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        part_prdt_lo_q <= 33'd0;
    end else if(part_prdt_lo_rld) begin
        part_prdt_lo_q <= part_prdt_lo_d;
    end
end

assign      part_prdt_ext_rld = part_prdt_lo_rld;
assign      part_prdt_ext_d = part_prdt_hi_init ? in1[1] : part_prdt_lo_q[1];
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        part_prdt_ext_q <= 1'd0;
    end else if(part_prdt_ext_rld) begin
        part_prdt_ext_q <= part_prdt_ext_d;
    end
end

assign      op_buf_init = cur_status_is_IDLE & op_vld;
assign      op_buf_upd = cur_status_is_CALC;
assign      op_buf_srl = cur_status_is_SHIFT;
assign      op_buf_rld = op_buf_init | op_buf_upd | op_buf_srl;
assign      op_buf_d =  op_buf_init ? {35'd0, in2, 1'b0} : 
                        op_buf_upd ? {adder_res[34:0], op_buf_q[32 : 0]} : 
                        op_buf_srl ? {{2{op_buf_q[67]}}, op_buf_q[67:2]} : 
                        op_buf_q;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        op_buf_q <= {35'd0, 33'd0, 1'b0};
    end else if(op_buf_rld) begin
        op_buf_q <= op_buf_d;
    end
end



assign      mul_res_clr = cur_status_is_IDLE & op_vld;
assign      mul_res_upd = cur_status_is_CALC;
assign      mul_res_rld = mul_res_clr | mul_res_upd;
assign      mul_res_d = mul_res_clr ? 64'd0 : {adder_res[0 +: 34], 1'b0};
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        mul_res_q <= 64'd0;
    end else if(mul_res_rld) begin
        mul_res_q <= mul_res_d;
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

assign      cycle_0th = ~(|cycle_q);
assign      calc_done = &cycle_q;

assign      op_rdy = cur_status_is_DONE;
assign      out = {adder_res[31 : 0], part_prdt_lo_q[32 : 1]};

endmodule