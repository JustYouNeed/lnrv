`include "lnrv_def.v"
module lnrv_exu_lsu
(
    input                               op_vld,
    output                              op_rdy,
    input[`LSU_OP_BUS_WIDTH - 1 : 0]    op_bus,

    input[31 : 0]                       rs1_rdata,
    input[31 : 0]                       rs2_rdata,
    input[31 : 0]                       imm,

    // 异常接口
    output                              cmt_vld,
    input                               cmt_rdy,
    output                              cmt_ld,
    output                              cmt_st,
    output                              cmt_excp_misalgn,
    output                              cmt_excp_buserr,
    output[31 : 0]                      cmt_addr,


    output                              gpr_wen,
    output[31 : 0]                      gpr_wdata,

    // alu
    output                              alu_op_vld,
    input                               alu_op_rdy,
    output[`ALU_OP_BUS_WIDTH - 1 : 0]   alu_op_bus,
    output[32 : 0]                      alu_in1,
    output[32 : 0]                      alu_in2,
    input[34 : 0]                       alu_res,

    // 系统总线
    output                              icb_cmd_vld,
    input                               icb_cmd_rdy,
    output                              icb_cmd_write,
    output[31 : 0]                      icb_cmd_addr,
    output[31 : 0]                      icb_cmd_wdata,
    output[3 : 0]                       icb_cmd_wstrb,
    output[2 : 0]                       icb_cmd_size,
    output[1 : 0]                       icb_cmd_burst,
    output[3 : 0]                       icb_cmd_len,
    output[2 : 0]                       icb_cmd_prot,
    output[3 : 0]                       icb_cmd_cache,
    output                              icb_rsp_rdy,
    input                               icb_rsp_vld,
    input[31 : 0]                       icb_rsp_rdata,
    input                               icb_rsp_err,


    input                               clk,
    input                               reset_n
);

wire[3 : 0]                             byte_access_wstrb;
wire[3 : 0]                             half_access_wstrb;
wire[3 : 0]                             word_access_wstrb;

reg                                     cmd_ots_q;
wire                                    cmd_ots_set;
wire                                    cmd_ots_clr;
wire                                    cmd_ots_rld;
wire                                    cmd_ots_d;

wire                                    no_ots_cmd;

wire                                    instr_is_load;
wire                                    instr_is_store;

wire[1 : 0]                             ls_size;
wire                                    ls_uext;

wire                                    addr_algn_byte;
wire                                    addr_algn_half;
wire                                    addr_algn_word;
wire                                    addr_algn;
wire                                    addr_misalgn;

wire                                    byte_access;
wire                                    half_access;
wire                                    word_access;

wire[7 : 0]                             load_byte;
wire[15 : 0]                            load_half;
wire[31 : 0]                            sext_byte;
wire[31 : 0]                            uext_byte;
wire[31 : 0]                            ext_byte;
wire[31 : 0]                            sext_half;
wire[31 : 0]                            uext_half;
wire[31 : 0]                            ext_half;

wire[31 : 0]                            store_byte;
wire[31 : 0]                            store_half;
wire[31 : 0]                            store_word;

wire                                    no_excp;

wire                                    icb_cmd_hsked;
wire                                    icb_rsp_hsked;


assign       icb_cmd_hsked =  icb_cmd_vld &  icb_cmd_rdy;
assign       icb_rsp_hsked =  icb_rsp_vld &  icb_rsp_rdy;


assign      instr_is_load   = op_bus[`LSU_LOAD_LOC];
assign      instr_is_store  = op_bus[`LSU_STORE_LOC];
assign      ls_size         = op_bus[`LSU_SIZE_LOC];
assign      ls_uext         = op_bus[`LSU_UEXT_LOC];

// 需要ALU计算操作地址
assign      alu_op_vld                          = op_vld;
assign      alu_op_bus[`ALU_ADD_LOC]            = instr_is_load | instr_is_store;
assign      alu_op_bus[`ALU_SUB_LOC]            = 1'b0;
assign      alu_op_bus[`ALU_OR_LOC]             = 1'b0;
assign      alu_op_bus[`ALU_AND_LOC]            = 1'b0;
assign      alu_op_bus[`ALU_XOR_LOC]            = 1'b0;
assign      alu_op_bus[`ALU_SLL_LOC]            = 1'b0;
assign      alu_op_bus[`ALU_SRL_LOC]            = 1'b0;
assign      alu_op_bus[`ALU_SRA_LOC]            = 1'b0;
assign      alu_op_bus[`ALU_LT_LOC]             = 1'b0;
assign      alu_op_bus[`ALU_GTE_LOC]            = 1'b0;
assign      alu_op_bus[`ALU_NEQ_LOC]            = 1'b0;
assign      alu_op_bus[`ALU_EQ_LOC]             = 1'b0;
assign      alu_op_bus[`ALU_IN1_IS_UNSIGED]     = 1'b0;
assign      alu_op_bus[`ALU_IN2_IS_UNSIGED]     = 1'b0;

assign      alu_in1[0 +: 32]                    = rs1_rdata;
assign      alu_in1[32 +: 1]                    = alu_in1[31];
assign      alu_in2[0 +: 32]                    = imm;
assign      alu_in2[32 +: 1]                    = alu_in2[31];


assign      byte_access = (ls_size == 2'd0);
assign      half_access = (ls_size == 2'd1);
assign      word_access = (ls_size == 2'd2);

assign      addr_algn_byte = 1'b1;
assign      addr_algn_half = ~alu_res[0];
assign      addr_algn_word = ~(|alu_res[1 : 0]);

// 判断访问地址是否对齐
assign      addr_algn = (byte_access & addr_algn_byte) |
                        (half_access & addr_algn_half) |
                        (word_access & addr_algn_word);
assign      addr_misalgn = ~addr_algn;

// 滞外交易
assign      cmd_ots_set =  icb_cmd_hsked;
assign      cmd_ots_clr =  icb_rsp_hsked;
assign      cmd_ots_rld = cmd_ots_set | cmd_ots_clr;
assign      cmd_ots_d = cmd_ots_q ? cmd_ots_set : (~cmd_ots_clr);
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        cmd_ots_q <= 1'b0;
    end else if(cmd_ots_rld) begin
        cmd_ots_q <= cmd_ots_d;
    end
end

// 这里我们只使用寄存器输出，当cmd_ots_clr有效时，当前也不可以发出下一笔操作
assign      no_ots_cmd = (~cmd_ots_q);

// 根据当前地址以及访问模式决定输出数据
assign      store_byte =    (alu_res[1 : 0] == 2'b00) ? {24'd0, rs2_rdata[7 : 0]} :
                            (alu_res[1 : 0] == 2'b01) ? {16'd0, rs2_rdata[7 : 0], 8'd0}:
                            (alu_res[1 : 0] == 2'b10) ? {8'd0, rs2_rdata[7 : 0], 16'd0} :
                            {rs2_rdata[7 : 0], 24'd0};
assign      store_half = alu_res[1] ? {rs2_rdata[15 : 0], 16'd0} : {16'd0, rs2_rdata[15 : 0]};
assign      store_word = rs2_rdata;


// 需要根据不同的访问以及地址来设置wstrb
assign      byte_access_wstrb = 4'b0001 << alu_res[1 : 0];
assign      half_access_wstrb = 4'b0011 << {alu_res[1], 1'b0};
assign      word_access_wstrb = 4'b1111;

assign      icb_cmd_vld     = addr_algn & op_vld & no_ots_cmd & alu_op_rdy;
assign      icb_cmd_write   = instr_is_store;
assign      icb_cmd_addr    = alu_res[0 +: 32];
assign      icb_cmd_wdata   =   byte_access ? store_byte :
                                    half_access ? store_half :
                                    store_word;
// 如果是读操作，wstrb设置为0
assign      icb_cmd_wstrb   =   instr_is_load ? 4'b0000 :
                                byte_access ? byte_access_wstrb :
                                half_access ? half_access_wstrb :
                                4'b1111;
assign      icb_cmd_size    = ls_size;
assign      icb_cmd_burst   = 2'b01;
assign      icb_cmd_len     = 4'b0000;
assign      icb_cmd_prot    = 3'b001;
assign      icb_cmd_cache   = 4'b0010;

assign      icb_rsp_rdy = cmt_rdy;

assign      load_byte = ( icb_cmd_addr[1 : 0] == 2'b00) ?  icb_rsp_rdata[7 : 0] :
                        ( icb_cmd_addr[1 : 0] == 2'b01) ?  icb_rsp_rdata[15 : 8] :
                        ( icb_cmd_addr[1 : 0] == 2'b10) ?  icb_rsp_rdata[23 : 16] :
                         icb_rsp_rdata[31 : 24];
                        // ( icb_cmd_addr[1 : 0] == 2'b00) ?  icb_rsp_rdata[7 : 0] :

assign      load_half =  icb_cmd_addr[1] ?  icb_rsp_rdata[31 : 16] :
                         icb_rsp_rdata[15 : 0];

assign      sext_byte   = {{24{load_byte[7]}}, load_byte};
assign      uext_byte   = {{24{1'b0}}, load_byte};
assign      ext_byte    = ls_uext ? uext_byte : sext_byte;

assign      sext_half   = {{16{load_half[15]}}, load_half};
assign      uext_half   = {{16{1'b0}}, load_half};
assign      ext_half    = ls_uext ? uext_half : sext_half;


// 我们直接将lsu的resp接到异常处理模块
// 对于地址非对齐异常，我们不会发出总线访问请求，直接申请异常处理
// lsu交付
// 1、如果当前发生了地址非对齐错误，则不会有访问操作发出，直接将该指令交付，产生异常
// 2、如果正常发出了访问操作，但是有错误，则产生总线错误异常
assign      cmt_vld             = addr_misalgn ? op_vld :  icb_rsp_vld;
assign      cmt_excp_misalgn    = addr_misalgn;
assign      cmt_excp_buserr     =  icb_rsp_err;
assign      cmt_ld              = instr_is_load;
assign      cmt_st              = instr_is_store;
assign      cmt_addr            =  icb_cmd_addr;


assign      no_excp = ~(addr_misalgn |  icb_rsp_err);

assign      gpr_wen = instr_is_load & no_excp & cmt_rdy;
assign      gpr_wdata = byte_access ? ext_byte :
                        half_access ? ext_half :
                         icb_rsp_rdata;

assign      op_rdy = cmt_rdy;

endmodule

