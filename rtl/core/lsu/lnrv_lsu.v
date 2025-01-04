`include "lnrv_def.v"
module lnrv_exu_lsu
(
    input                               lsu_op_vld,
    output                              lsu_op_rdy,
    input[`LSU_OP_BUS_WIDTH - 1 : 0]    op_bus_lsu,

    input[31 : 0]                       rs1_rdata,
    input[31 : 0]                       rs2_rdata,
    input[31 : 0]                       imm,

    // 交付接口
    output                              cmt_lsu_vld,
    input                               cmt_lsu_rdy,
    output                              cmt_lsu_ld,
    output                              cmt_lsu_st,
    output                              cmt_lsu_misalgn,
    output                              cmt_lsu_buserr,
    output[31 : 0]                      cmt_lsu_addr,
    output[31 : 0]                      gpr_wdata_lsu_cmt,

    // alu
    output                              alu_op_vld_lsu,
    input                               alu_op_rdy_lsu,
    output[`ALU_OP_BUS_WIDTH - 1 : 0]   alu_op_bus_lsu,
    output[31 : 0]                      alu_in1_lsu,
    output[31 : 0]                      alu_in2_lsu,
    input[31 : 0]                       lsu2alu_add_res,

    // 系统总线
    output                              icb_cmd_vld_lsu,
    input                               icb_cmd_rdy_lsu,
    output                              icb_cmd_write_lsu,
    output[31 : 0]                      icb_cmd_addr_lsu,
    output[31 : 0]                      icb_cmd_wdata_lsu,
    output[3 : 0]                       icb_cmd_wstrb_lsu,
    output[2 : 0]                       icb_cmd_size_lsu,
    output                              icb_rsp_rdy_lsu,
    input                               icb_rsp_vld_lsu,
    input[31 : 0]                       icb_rsp_rdata_lsu,
    input                               icb_rsp_err_lsu,


    input                               clk,
    input                               reset_n
);


reg                 cmd_vld_q;
wire                cmd_vld_set;
wire                cmd_vld_clr;
wire                cmd_vld_rld;
wire                cmd_vld_d;

// reg[31 : 0]         cmd_addr_q;
// wire                cmd_addr_rld;
// wire[31 : 0]        cmd_addr_d;

// reg[31 : 0]         cmd_wdata_q;
// wire                cmd_wdata_rld;
// wire[31 : 0]        cmd_wdata_d;

reg[3 : 0]          cmd_wstrb_q;
wire                cmd_wstrb_rld;
wire[3 : 0]         cmd_wstrb_d;
wire[3 : 0]         byte_access_wstrb;
wire[3 : 0]         half_access_wstrb;
wire[3 : 0]         word_access_wstrb;

reg                 cmd_ots_q;
wire                cmd_ots_set;
wire                cmd_ots_clr;
wire                cmd_ots_rld;
wire                cmd_ots_d;

wire                no_ots_cmd;

wire                instr_is_load;
wire                instr_is_store;

wire[1 : 0]         ls_size;
wire                ls_uext;

wire                addr_algn_byte;
wire                addr_algn_half;
wire                addr_algn_word;
wire                addr_algn;
wire                addr_misalgn;

wire                byte_access;
wire                half_access;
wire                word_access;

wire[7 : 0]         load_byte;
wire[15 : 0]        load_half;
wire[31 : 0]        sext_byte;
wire[31 : 0]        uext_byte;
wire[31 : 0]        ext_byte;
wire[31 : 0]        sext_half;
wire[31 : 0]        uext_half;
wire[31 : 0]        ext_half;

wire[31 : 0]        store_byte;
wire[31 : 0]        store_half;
wire[31 : 0]        store_word;


wire                icb_cmd_hsked_lsu;
wire                icb_rsp_hsked_lsu;


assign      icb_cmd_hsked_lsu = icb_cmd_vld_lsu & icb_cmd_rdy_lsu;
assign      icb_rsp_hsked_lsu = icb_rsp_vld_lsu & icb_rsp_rdy_lsu;


assign      instr_is_load   = op_bus_lsu[`LSU_LOAD_LOC];
assign      instr_is_store  = op_bus_lsu[`LSU_STORE_LOC];
assign      ls_size         = op_bus_lsu[`LSU_SIZE_LOC];
assign      ls_uext         = op_bus_lsu[`LSU_UEXT_LOC];


assign      byte_access = (ls_size == 2'd0);
assign      half_access = (ls_size == 2'd1);
assign      word_access = (ls_size == 2'd2);

assign      addr_algn_byte = 1'b1;
assign      addr_algn_half = ~lsu2alu_add_res[0];
assign      addr_algn_word = ~(|lsu2alu_add_res[1 : 0]);

// 判断访问地址是否对齐
assign      addr_algn = (byte_access & addr_algn_byte) |
                        (half_access & addr_algn_half) |
                        (word_access & addr_algn_word);

assign      addr_misalgn = ~addr_algn;

assign      no_ots_cmd = (~(cmd_ots_q | cmd_ots_set));

// 访存的地址信息需要通过alu计算得到，因此我们只有在alu计算结束后，才可以输出总线访问请求，
// 不支持非对齐访问
assign      cmd_vld_set = addr_algn & lsu_op_vld & no_ots_cmd & alu_op_rdy_lsu;
assign      cmd_vld_clr = icb_cmd_hsked_lsu;
assign      cmd_vld_rld = cmd_vld_set | cmd_vld_clr;
assign      cmd_vld_d = ~cmd_vld_clr;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        cmd_vld_q <= 1'b0;
    end else if(cmd_vld_rld) begin
        cmd_vld_q <= cmd_vld_d;
    end
end



// assign      cmd_wdata_rld = cmd_vld_set;
// assign      cmd_wdata_d =   byte_access ? store_byte :
//                             half_access ? store_half :
//                             store_word;
// always@(posedge clk or negedge reset_n) begin
//     if(reset_n == 1'b0) begin
//         cmd_wdata_q <= 32'b0;
//     end else if(cmd_wdata_rld) begin
//         cmd_wdata_q <= cmd_wdata_d;
//     end
// end

// 滞外交易
assign      cmd_ots_set = icb_cmd_hsked_lsu;
assign      cmd_ots_clr = icb_rsp_hsked_lsu;
assign      cmd_ots_rld = cmd_ots_set | cmd_ots_clr;
assign      cmd_ots_d = (cmd_ots_set & cmd_ots_q) |
                        (~(cmd_ots_clr | cmd_ots_q));
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        cmd_ots_q <= 1'b0;
    end else if(cmd_ots_rld) begin
        cmd_ots_q <= cmd_ots_d;
    end
end

// 访问地址
// assign      cmd_addr_rld = cmd_vld_set;
// assign      cmd_addr_d = alu_res;
// always@(posedge clk or negedge reset_n) begin
//     if(reet_n == 1'b0) begin
//         cmd_addr_q <= 32'd0;
//     end else if(cmd_addr_rld) begin
//         cmd_addr_q <= cmd_addr_d;
//     end
// end

// 需要根据不同的访问以及地址来设置wstrb
assign      byte_access_wstrb = 4'b0001 << alu_res[1 : 0];
assign      half_access_wstrb = 4'b0011 << {alu_res[1], 1'b0};
assign      word_access_wstrb = 4'b1111;

assign      cmd_wstrb_rld = cmd_vld_set;
assign      cmd_wstrb_d =   byte_access ? byte_access_wstrb :
                            half_access ? half_access_wstrb :
                            word_access ? word_access_wstrb :
                            4'b0000;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        cmd_wstrb_q <= 4'b0000;
    end else if(cmd_wstrb_rld) begin
        cmd_wstrb_q <= cmd_wstrb_d;
    end
end



// assign      lsu_ld_access_fault = icb_rsp_err_lsu & instr_is_load;
// assign      lsu_st_access_fault = icb_rsp_err_lsu & instr_is_store;
// assign      lsu_ld_addr_misalgn = addr_misalgn & instr_is_load;
// assign      lsu_st_addr_misalgn = addr_misalgn & instr_is_store;
// assign      lsu_bad_addr = alu_res;

// 根据当前地址以及访问模式决定输出数据
assign      store_byte =    (icb_cmd_addr_lsu[1 : 0] == 2'b00) ? {24'd0, rs2_rdata[7 : 0]} :
                            (icb_cmd_addr_lsu[1 : 0] == 2'b01) ? {16'd0, rs2_rdata[7 : 0], 8'd0}:
                            (icb_cmd_addr_lsu[1 : 0] == 2'b10) ? {8'd0, rs2_rdata[7 : 0], 16'd0} :
                            {rs2_rdata[7 : 0], 24'd0};
assign      store_half = icb_cmd_addr_lsu[1] ? {rs2_rdata[15 : 0], 16'd0} : {16'd0, rs2_rdata[15 : 0]};
assign      store_word = rs2_rdata;

// 请求lsu模块完成访存操作
assign      icb_cmd_vld_lsu     = cmd_vld_q;
assign      icb_cmd_addr_lsu    = alu_res;
assign      icb_cmd_write_lsu   = instr_is_store;
assign      icb_cmd_size_lsu    = ls_size;
assign      icb_cmd_wstrb_lsu   = cmd_wstrb_q;
assign      icb_cmd_wdata_lsu   =   byte_access ? store_byte :
                                half_access ? store_half :
                                store_word;

// 如果有异常发生，则需要请求处理异常，否则直接写回即可
assign      icb_rsp_rdy_lsu =   lsu_excp_vld ? lsu_excp_rdy:
                            gpr_wbck_rdy;

assign      load_byte = (icb_cmd_addr_lsu[1 : 0] == 2'b00) ? icb_rsp_rdata_lsu[7 : 0] :
                        (icb_cmd_addr_lsu[1 : 0] == 2'b01) ? icb_rsp_rdata_lsu[15 : 8] :
                        (icb_cmd_addr_lsu[1 : 0] == 2'b10) ? icb_rsp_rdata_lsu[23 : 16] :
                        icb_rsp_rdata_lsu[31 : 24];
                        // (icb_cmd_addr_lsu[1 : 0] == 2'b00) ? icb_rsp_rdata_lsu[7 : 0] :

assign      load_half = icb_cmd_addr_lsu[1] ? icb_rsp_rdata_lsu[31 : 16] :
                        icb_rsp_rdata_lsu[15 : 0];

assign      sext_byte = {{24{load_byte[7]}}, load_byte};
assign      uext_byte = {{24{1'b0}}, load_byte};
assign      ext_byte = ls_uext ? uext_byte : sext_byte;

assign      sext_half = {{16{load_half[15]}}, load_half};
assign      uext_half = {{16{1'b0}}, load_half};
assign      ext_half = ls_uext ? uext_half : sext_half;

assign      alu_op_vld = lsu_op_vld;
assign      alu_op_bus[`ALU_ADD_LOC]    = instr_is_load | instr_is_store;
assign      alu_op_bus[`ALU_SUB_LOC]    = 1'b0;
assign      alu_op_bus[`ALU_OR_LOC]     = 1'b0;
assign      alu_op_bus[`ALU_AND_LOC]    = 1'b0;
assign      alu_op_bus[`ALU_XOR_LOC]    = 1'b0;
assign      alu_op_bus[`ALU_SLL_LOC]    = 1'b0;
assign      alu_op_bus[`ALU_SRL_LOC]    = 1'b0;
assign      alu_op_bus[`ALU_SRA_LOC]    = 1'b0;
assign      alu_op_bus[`ALU_LT_LOC]     = 1'b0;
assign      alu_op_bus[`ALU_LTU_LOC]    = 1'b0;
assign      alu_op_bus[`ALU_GTE_LOC]    = 1'b0;
assign      alu_op_bus[`ALU_GTEU_LOC]   = 1'b0;
assign      alu_op_bus[`ALU_NEQ_LOC]    = 1'b0;
assign      alu_op_bus[`ALU_EQ_LOC]     = 1'b0;
assign      alu_in1                     = rs1_rdata;
assign      alu_in2                     = imm;



assign      lsu_op_rdy = cmt_lsu_rdy;

// // 在没有发生异常的情况下才可以写回
// assign      gpr_wbck_vld    = icb_rsp_vld_lsu & (~lsu_excp_vld) & instr_is_load;
// assign      gpr_wbck_wdata  =   byte_access ? ext_byte :
//                                 half_access ? ext_half :
//                                 icb_rsp_rdata_lsu;

// assign      op_rdy =    lsu_excp_vld ? lsu_excp_rdy :
//                         instr_is_load ? gpr_wbck_rdy & gpr_wbck_vld :
//                         icb_rsp_hsked_lsu;

// 我们直接将lsu的resp接到异常处理模块
// 对于地址非对齐异常，我们不会发出总线访问请求，直接申请异常处理
// lsu交付
// 1、如果当前发生了地址非对齐错误，则不会有访问操作发出，直接将该指令交付，产生异常
// 2、如果正常发出了访问操作，但是有错误，则产生总线错误异常
assign      cmt_lsu_vld = addr_misalgn ? lsu_op_vld : icb_rsp_vld_lsu;
assign      cmt_lsu_misalgn = addr_misalgn;
assign      cmt_lsu_buserr = icb_rsp_err_lsu;
assign      cmt_lsu_ld = instr_is_load;
assign      cmt_lsu_st = instr_is_store;
assign      cmt_lsu_addr = icb_cmd_addr_lsu;
assign      gpr_wdata_lsu_cmt = byte_access ? ext_byte :
                                half_access ? ext_half :
                                icb_rsp_rdata_lsu;

endmodule

