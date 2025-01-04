module lnrv_idu_rv16
(
    input[15 : 0]                           ir,

    output[4 : 0]                           dec_rd,
    output[4 : 0]                           dec_rs1,
    output[4 : 0]                           dec_rs2,
    output[31 : 0]                          dec_imm,

    // 送给分支预测模块
    output[31 : 0]                          dec_imm_jal,
    output[31 : 0]                          dec_imm_jalr,
    output[31 : 0]                          dec_imm_bxx,
    output                                  dec_ir_bxx,
    output                                  dec_ir_jal,
    output                                  dec_ir_jalr,
    output                                  dec_rs1_x1,

    // 非法指令
    output                                  dec_ilegl_ir,

    output[`DEC_OP_BUS_WIDTH - 1 : 0]       dec_op_bus,
    output[`DEC_OP_TYPE_WIDTH -1 : 0]       dec_op_type
);

wire[1 : 0]                                 opcode;
wire                                        opcode_is_00;
wire                                        opcode_is_01;
wire                                        opcode_is_10;
wire                                        opcode_is_11;

wire[2 : 0]                                 funct3;
wire                                        funct3_is_000;
wire                                        funct3_is_001;
wire                                        funct3_is_010;
wire                                        funct3_is_011;
wire                                        funct3_is_100;
wire                                        funct3_is_101;
wire                                        funct3_is_110;
wire                                        funct3_is_111;

wire                                        ir_bit12;
wire                                        ir_bit12_is_0;
wire                                        ir_bit12_is_1;

wire[1 : 0]                                 ir_bit6_5;
wire                                        ir_bit6_5_is_00;
wire                                        ir_bit6_5_is_01;
wire                                        ir_bit6_5_is_10;
wire                                        ir_bit6_5_is_11;

wire[2 : 0]                                 ir_bit11_10;
wire                                        ir_bit11_10_is_00;
wire                                        ir_bit11_10_is_01;
wire                                        ir_bit11_10_is_10;
wire                                        ir_bit11_10_is_11;

wire                                        ir_bit12_10_is_011;
wire                                        ir_bit12_10_is_111;

wire[4 : 0]                                 rs1_rd;
wire[4 : 0]                                 rs1_rd_d;
wire[4 : 0]                                 rs2;
wire[4 : 0]                                 rs2d;

wire                                        rs1_rd_is_0;
wire                                        rx1_rd_is_1;
wire                                        rs1_rd_not_0;
wire                                        rs1_rd_is_2;
wire                                        rs1_rd_not_2;
wire                                        rs2_not_0;
wire                                        rs2_is_0;

wire                                        ridx_sel_d;

wire                                        instr_c_add;
wire                                        instr_c_addi;
wire                                        instr_c_addi16sp;
wire                                        instr_c_addi4spn;
wire                                        instr_c_and;
wire                                        instr_c_andi;
wire                                        instr_c_beqz;
wire                                        instr_c_bnez;
wire                                        instr_c_ebreak;
wire                                        instr_c_j;
wire                                        instr_c_jal;
wire                                        instr_c_jalr;
wire                                        instr_c_jr;
wire                                        instr_c_li;
wire                                        instr_c_lui;
wire                                        instr_c_lw;
wire                                        instr_c_lwsp;
wire                                        instr_c_mv;
wire                                        instr_c_or;
wire                                        instr_c_slli;
wire                                        instr_c_srai;
wire                                        instr_c_srli;
wire                                        instr_c_sub;
wire                                        instr_c_sw;
wire                                        instr_c_swsp;
wire                                        instr_c_xor;

// 立即数相关信号
wire[5 : 0]                                 imm_addi_andi_li;
wire[31 : 0]                                imm_addi_andi_li_sext;
wire                                        imm_addi_andi_li_sel;

wire[5 : 0]                                 imm_srxi;
wire[31 : 0]                                imm_srxi_uext;
wire                                        imm_srxi_sel;

wire[7 : 2]                                 imm_lwsp;
wire[31 : 0]                                imm_lwsp_uext;
wire                                        imm_lwsp_sel;
wire                                        imm_lwsp_is_0;
wire                                        imm_lwsp_not_0;

wire[9 : 4]                                 imm_addi16sp;
wire[31 : 0]                                imm_addi16sp_sext;
wire                                        imm_addi16sp_sel;
wire                                        imm_addi16sp_is_0;
wire                                        imm_addi16sp_not_0;

wire[17 : 12]                               imm_lui;
wire[31 : 0]                                imm_lui_sext;
wire                                        imm_lui_sel;
wire                                        imm_lui_not_0;
wire                                        imm_lui_is_0;

wire[9 : 2]                                 imm_addi4spn;
wire[31 : 0]                                imm_addi4spn_uext;
wire                                        imm_addi4spn_sel;
wire                                        imm_addi4spn_is_0;
wire                                        imm_addi4spn_not_0;

wire[8 : 1]                                 imm_bxx;
wire[31 : 0]                                imm_bxx_sext;
wire                                        imm_bxx_sel;

wire[6 : 2]                                 imm_ls;
wire[31 : 0]                                imm_ls_uext;
wire                                        imm_ls_sel;

wire[11 : 1]                                imm_j_jal;
wire[31 : 0]                                imm_j_jal_sext;
wire                                        imm_j_jal_sel;

wire[7 : 2]                                 imm_swsp;
wire[31 : 0]                                imm_swsp_uext;
wire                                        imm_swsp_sel;

wire                                        instr_one_of_sub_xor_or_and;
wire                                        instr_one_of_srxi_andi;
wire                                        instr_one_of_ebreak_jalr_add;
wire                                        instr_one_of_jr_mv;
wire                                        instr_one_of_bxx;
wire                                        instr_one_of_li_addi;
wire                                        instr_one_of_slli_lwsp;
wire                                        instr_one_of_lui_addi16sp;

wire                                        instr_fmt_ci;
wire                                        instr_fmt_ciw;
wire                                        instr_fmt_css;
wire                                        instr_fmt_cl;
wire                                        instr_fmt_cs;
wire                                        instr_fmt_cj;
wire                                        instr_fmt_cr;
wire                                        instr_fmt_cb;

wire                                        op_bus_brch_sel;
wire                                        op_bus_lsu_sel;
wire                                        op_bus_sys_sel;
wire                                        op_bus_rglr_sel;

wire[`RGLR_OP_BUS_WIDTH - 1 : 0]            op_bus_rglr;
wire[`BRCH_OP_BUS_WIDTH - 1 : 0]            op_bus_brch;
wire[`SYS_OP_BUS_WIDTH - 1 : 0]             op_bus_sys;
wire[`LSU_OP_BUS_WIDTH - 1 : 0]             op_bus_lsu;
wire[`DEC_OP_BUS_WIDTH : 0]                 dec_op_bus_mux;


assign      funct3              = ir[15 : 13];
assign      opcode              = ir[1 : 0];
assign      ir_bit12            = ir[12];
assign      ir_bit11_10         = ir[11 : 10];
assign      ir_bit6_5           = ir[6 : 5];

assign      opcode_is_00        = (opcode == 2'b00);
assign      opcode_is_01        = (opcode == 2'b01);
assign      opcode_is_10        = (opcode == 2'b10);

assign      funct3_is_000       = (funct3 == 3'b000);
assign      funct3_is_001       = (funct3 == 3'b001);
assign      funct3_is_010       = (funct3 == 3'b010);
assign      funct3_is_011       = (funct3 == 3'b011);
assign      funct3_is_100       = (funct3 == 3'b100);
assign      funct3_is_101       = (funct3 == 3'b101);
assign      funct3_is_110       = (funct3 == 3'b110);
assign      funct3_is_111       = (funct3 == 3'b111);

assign      ir_bit12_is_1       = ir_bit12;
assign      ir_bit12_is_0       = (~ir_bit12_is_1);

assign      ir_bit11_10_is_00   = (ir_bit11_10 == 2'b00);
assign      ir_bit11_10_is_01   = (ir_bit11_10 == 2'b01);
assign      ir_bit11_10_is_10   = (ir_bit11_10 == 2'b10);
assign      ir_bit11_10_is_11   = (ir_bit11_10 == 2'b11);

assign      ir_bit12_10_is_011  = ir_bit12_is_0 & ir_bit11_10_is_11;
assign      ir_bit12_10_is_111  = ir_bit12_is_1 & ir_bit11_10_is_11;

assign      ir_bit6_5_is_00     = (ir_bit6_5 == 2'b00);
assign      ir_bit6_5_is_01     = (ir_bit6_5 == 2'b01);
assign      ir_bit6_5_is_10     = (ir_bit6_5 == 2'b10);
assign      ir_bit6_5_is_11     = (ir_bit6_5 == 2'b11);



/* 对指令进行分类，根据spec，可以分为以下几类
    +----------------------------------------------------+
    |  fmt  |                 instructions               |
    +-------+--------------------------------------------+
    |  ci   | c.li c.addi c.slli c.lwsp c.addi16sp c.lui |
    +-------+--------------------------------------------+
    |  cb   |     c.srli c.srai c.andi c.beqz c.bnez     |
    +-------+--------------------------------------------+
    |  ciw  |               c.addi16spn                  |
    +-------+--------------------------------------------+
    |  cl   |                    c.lw                    |
    +-------+--------------------------------------------+
    |  cs   |        c.sw c.sub c.xor c.or c.and         |
    +-------+--------------------------------------------+
    |  cj   |                  c.j c.jal                 |
    +-------+--------------------------------------------+
    |  css  |                    c.swsp                  |
    +-------+--------------------------------------------+
    |  cr   |       c.jr c.mv c.jalr c.add c.ebreak      |
    +-------+--------------------------------------------+
*/
assign      instr_fmt_ci    = instr_one_of_li_addi | instr_one_of_slli_lwsp | instr_one_of_lui_addi16sp;
assign      instr_fmt_ciw   = instr_c_addi4spn;
assign      instr_fmt_cb    = instr_one_of_srxi_andi | instr_one_of_bxx;
assign      instr_fmt_cl    = instr_c_lw;
assign      instr_fmt_cs    = instr_c_sw | instr_one_of_sub_xor_or_and;
assign      instr_fmt_css   = instr_c_swsp;
assign      instr_fmt_cr    = funct3_is_100 & opcode_is_10;
assign      instr_fmt_cj    = opcode_is_01 & (funct3_is_101 | funct3_is_001);


// 有些指令有相同的部分，提取出来，共用逻辑
assign      instr_one_of_li_addi            = opcode_is_01 & (funct3_is_000 | funct3_is_010);
assign      instr_one_of_slli_lwsp          = opcode_is_10 & (funct3_is_000 | funct3_is_010);
assign      instr_one_of_lui_addi16sp       = opcode_is_01 & funct3_is_011;
assign      instr_one_of_sub_xor_or_and     = opcode_is_01 & funct3_is_100 & ir_bit12_10_is_011;
assign      instr_one_of_srxi_andi          = opcode_is_01 & funct3_is_100 & (~ir_bit11_10_is_11);
assign      instr_one_of_bxx               = opcode_is_01 & (funct3_is_110 | funct3_is_111);
assign      instr_one_of_jr_mv              = opcode_is_10 & funct3_is_100 & ir_bit12_is_0;
assign      instr_one_of_ebreak_jalr_add    = opcode_is_10 & funct3_is_100 & ir_bit12_is_1;

// ===========================================================================
//                                  译码
// ===========================================================================
/*
    c.li            x[rd] = sext(imm)
    立即数加载, RV32IC and RV64IC
    扩展形式 addi rd, x0, imm
    +--------------------------------------------+
    |15   13|  12  |11       7|6           2|1  0|
    +-------+------+----------+-------------+----+
    |  010  |imm[5]|    rd    |  imm[4:0]|  | 01 |
    +--------------------------------------------+
*/
assign      instr_c_li = funct3_is_010 & opcode_is_01;

/*
    c.addi          x[rd] = x[rd] + sext(imm)
    立即数加, RV32IC and RV64IC
    扩展形式 addi rd, rd, imm
    +--------------------------------------------+
    |15   13|  12  |11       7|6           2|1  0|
    +-------+------+----------+-------------+----+
    |  000  |imm[5]|    rd    |  imm[4:0]|  | 01 |
    +--------------------------------------------+
*/
assign      instr_c_addi = funct3_is_000 & opcode_is_01;

/*
    c.srli          x[8 + rd'] = x[8 + rd'] >> uext(imm)
    立即数逻辑右移, RV32IC and RV64IC
    扩展形式 srli rd, rd, uimm，其中rd = 8 + rd'
    +----------------------------------------------+
    |15   13|  12  |11  10|9   7|6           2|1  0|
    +-------+------+------+-----+-------------+----+
    |  100  |imm[5]|  00  | rd' |  imm[4:0]|  | 01 |
    +----------------------------------------------+
*/
assign      instr_c_srli = funct3_is_100 & ir_bit11_10_is_00 & opcode_is_01;

/*
    c.srai          x[8 + rd'] = x[8 + rd'] >>s uext(imm)
    立即数算术右移, RV32IC and RV64IC
    扩展形式 srai rd, rd, uimm，其中rd = 8 + rd'
    +----------------------------------------------+
    |15   13|  12  |11  10|9   7|6           2|1  0|
    +-------+------+------+-----+-------------+----+
    |  100  |imm[5]|  01  | rd' |  imm[4:0]|  | 01 |
    +----------------------------------------------+
*/
assign      instr_c_srai = funct3_is_100 & ir_bit11_10_is_01 & opcode_is_01;

/*
    c.andi          x[8 + rd'] = x[8 + rd'] & sext(imm)
    立即数算术右移, RV32IC and RV64IC
    扩展形式 andi rd, rd, uimm，其中rd = 8 + rd'
    +----------------------------------------------+
    |15   13|  12  |11  10|9   7|6           2|1  0|
    +-------+------+------+-----+-------------+----+
    |  100  |imm[5]|  10  | rd' |  imm[4:0]|  | 01 |
    +----------------------------------------------+
*/
assign      instr_c_andi = funct3_is_100 & ir_bit11_10_is_10 & opcode_is_01;

/*
    c.slli          x[rd] = x[rd] << uext(imm)
    立即数加载, RV32IC and RV64IC
    扩展形式 slli rd, rd, imm
    +--------------------------------------------+
    |15   13|  12  |11       7|6           2|1  0|
    +-------+------+----------+-------------+----+
    |  000  |imm[5]|    rd    |  imm[4:0]|  | 10 |
    +--------------------------------------------+
*/
assign      instr_c_slli = funct3_is_000 & opcode_is_10;

/*
    c.lwsp          x[rd] = M[x[2] + uext(imm)]
    立即数加载, RV32IC and RV64IC
    扩展形式 lw rd, imm(x2), 当rd=0时为非法指令
    +--------------------------------------------+
    |15   13|  12  |11       7|6           2|1  0|
    +-------+------+----------+-------------+----+
    |  010  |imm[5]|    rd    |  imm[4:0]|  | 10 |
    +--------------------------------------------+
*/
assign      instr_c_lwsp = funct3_is_010 & opcode_is_10 & rs1_rd_not_0;

/*
    c.addi16sp      x[2] = x[2] + sext(imm)
    立即数加载, RV32IC and RV64IC
    扩展形式 addi x2, x2, imm, imm=0时为非法指令
    +--------------------------------------------+
    |15   13|  12  |11       7|6           2|1  0|
    +-------+------+----------+-------------+----+
    |  011  |imm[5]|  00010   |imm[4|6|:7|5]| 01 |
    +--------------------------------------------+
*/
assign      instr_c_addi16sp = instr_one_of_lui_addi16sp & rs1_rd_is_2 & imm_addi16sp_not_0;

/*
    c.lui           x[rd] = sext(imm)
    立即数加载, RV32IC and RV64IC
    扩展形式 lui rd, imm, rd=x2或者imm=0时为非法指令
    +--------------------------------------------+
    |15   13|  12   |11       7|6           2|1  0|
    +-------+-------+----------+-------------+----+
    |  011  |imm[17]|    rd    | imm[16:12]| | 01 |
    +--------------------------------------------+
*/
assign      instr_c_lui = instr_one_of_lui_addi16sp & rs1_rd_not_2 & imm_lui_not_0;

/*
    c.addi4spn      x[8+rd'] = x[8+rd'] + uext(imm)
    立即数加载, RV32IC and RV64IC
    扩展形式 addi rd, x2, imm. imm=0时为非法指令
    +--------------------------------------------+
    |15   13|12                   5|4       2|1  0|
    +-------+----------------------+---------+----+
    |  000  |   imm[5:4|9:6|2|3]   |   rd'   | 00 |
    +--------------------------------------------+
*/
assign      instr_c_addi4spn = funct3_is_000 & opcode_is_00 & imm_addi4spn_not_0;


assign      instr_c_beqz = funct3_is_110 & opcode_is_01;


assign      instr_c_bnez = funct3_is_111 & opcode_is_01;


assign      instr_c_lw = funct3_is_010 & opcode_is_00;

/*
    c.sw            M[x[+rs1'] + uimm][31 : 0] = x[8+rs2']
    字存储, RV32IC and RV64IC
    扩展形式 sw rs2, uimm(rs1), 其中: rs2 = 8 + rs2', rs1 = 8 + rs1'
    +---------------------------------------------------------+
    |15   13|12     10|9          7|6       5|4         2|1  0|
    +-------+---------+------------+---------+-----------+----+
    |  110  |uimm[5:3]|    rs1'    |uimm[2|6]|   rs2'    | 00 |
    +---------------------------------------------------------+
*/
assign      instr_c_sw = funct3_is_110 & opcode_is_00;

assign      instr_c_j = funct3_is_101 & opcode_is_01;


assign      instr_c_jal = funct3_is_001 & opcode_is_01;

/*
    c.swsp          M[x[2] + uimm][31 : 0] = x[rs2]
    栈指针相关字存储, RV32IC and RV64IC
    扩展形式 sw rs, uimm(x2)
    +---------------------------------------------------------+
    |15   13|12                             7|6         2|1  0|
    +-------+--------------------------------+-----------+----+
    |  110  |          uimm[5:2|7:6]         |    rs2    | 01 |
    +---------------------------------------------------------+
*/
assign      instr_c_swsp = funct3_is_110 & opcode_is_10;

/*
    c.sub           x[8+rd'] = x[8+rd'] - x[8+rs2']
    减, RV32IC and RV64IC
    扩展形式 sub rd, rd, rs2, 其中: rd = 8 + rd', rs2 = 8 + rs2'
    +---------------------------------------------------------+
    |15                  10|9         7|6  5|4          2|1  0|
    +----------------------+-----------+----+------------+----+
    |        100011        |    rd'    | 00 |    rs2'    | 01 |
    +---------------------------------------------------------+
*/
assign      instr_c_sub = instr_one_of_sub_xor_or_and & ir_bit6_5_is_00;

/*
    c.xor           x[8+rd'] = x[8+rd'] ^ x[+rs2']
    异或, RV32IC and RV64IC
    扩展形式 xor rd, rd, rs2, 其中: rd = 8 + rd',rs2 = 8 + rs2'
    +---------------------------------------------------------+
    |15                  10|9         7|6  5|4          2|1  0|
    +----------------------+-----------+----+------------+----+
    |        100011        |    rd'    | 01 |    rs2'    | 01 |
    +---------------------------------------------------------+
*/
assign      instr_c_xor     = instr_one_of_sub_xor_or_and & ir_bit6_5_is_01;
assign      instr_c_or      = instr_one_of_sub_xor_or_and & ir_bit6_5_is_10;
assign      instr_c_and     = instr_one_of_sub_xor_or_and & ir_bit6_5_is_11;

assign      instr_c_jr      = instr_one_of_jr_mv & rs1_rd_not_0 & rs2_is_0;
assign      instr_c_mv      = instr_one_of_jr_mv & rs2_not_0;


assign      instr_c_ebreak  = instr_one_of_ebreak_jalr_add & rs1_rd_is_0 & rs2_is_0;
assign      instr_c_jalr    = instr_one_of_ebreak_jalr_add & rs1_rd_not_0 & rs2_is_0;


/*
    c.add   rd, rs2                             x[rd] = x[rs1] + x[rs2]
    加, R-Type, RV32IC and RV64IC
    rd=x0或者rs2=x0时非法
    +--------------------------------------------------------------------------------------------------+
    |31                   25|24         20|19         15|14     12|11         7|6                     0|
    +-----------------------+-------------+-------------+---------+------------+-----------------------+
    |        0000000        |     rs2     |     rs1     |   000   |     rd     |        0110011        |
    +--------------------------------------------------------------------------------------------------+
*/
assign      instr_c_add = instr_one_of_ebreak_jalr_add & rs1_rd_not_0 & rs2_not_0;


// 生成常规指令的操作总线

assign      op_bus_rglr[`RGLR_SUB_LOC]      = instr_c_sub;
assign      op_bus_rglr[`RGLR_AND_LOC]      = instr_c_and | instr_c_andi;
assign      op_bus_rglr[`RGLR_OR_LOC]       = instr_c_or;
assign      op_bus_rglr[`RGLR_XOR_LOC]      = instr_c_xor;
assign      op_bus_rglr[`RGLR_SLT_LOC]      = 1'b0;
assign      op_bus_rglr[`RGLR_SLL_LOC]      = instr_c_slli;
assign      op_bus_rglr[`RGLR_SRA_LOC]      = instr_c_srai;
assign      op_bus_rglr[`RGLR_SRL_LOC]      = instr_c_srli;
assign      op_bus_rglr[`RGLR_AUIPC_LOC]    = 1'b0;
assign      op_bus_rglr[`RGLR_LUI_LOC]      = instr_c_lui;
assign      op_bus_rglr[`RGLR_SLTU_LOC]     = 1'b0;
assign      op_bus_rglr[`RGLR_OP1_IS_PC]    = 1'b0;
assign      op_bus_rglr[`RGLR_OP2_IS_IMM]   = instr_fmt_ci | instr_fmt_cb | instr_fmt_ciw;
assign      op_bus_rglr[`RGLR_ADD_LOC]      =   instr_c_add |
                                                instr_c_addi |
                                                instr_c_mv |
                                                instr_c_li |
                                                instr_c_addi16sp |
                                                instr_c_addi4spn |
                                                1'b0;
// ===========================================================================
//                                      访存指令
// ===========================================================================
assign      op_bus_lsu[`LSU_LOAD_LOC]   = instr_c_lwsp | instr_c_lw;
assign      op_bus_lsu[`LSU_STORE_LOC]  = instr_c_swsp | instr_c_sw;
assign      op_bus_lsu[`LSU_SIZE_LOC]   = 2'd2;
assign      op_bus_lsu[`LSU_UEXT_LOC]   = 1'b0;


// ===========================================================================
//                                      分支指令
// ===========================================================================
assign      op_bus_brch[`BRCH_BEQ_LOC]      = instr_c_beqz;
assign      op_bus_brch[`BRCH_BGE_LOC]      = 1'b0;
assign      op_bus_brch[`BRCH_BGEU_LOC]     = 1'b0;
assign      op_bus_brch[`BRCH_BLT_LOC]      = 1'b0;
assign      op_bus_brch[`BRCH_BLTU_LOC]     = 1'b0;
assign      op_bus_brch[`BRCH_BNE_LOC]      = instr_c_bnez;
assign      op_bus_brch[`BRCH_JAL_LOC]      = instr_c_j | instr_c_jal;
assign      op_bus_brch[`BRCH_JALR_LOC]     = instr_c_jr | instr_c_jalr;
assign      op_bus_brch[`BRCH_MRET_LOC]     = 1'b0;
assign      op_bus_brch[`BRCH_DRET_LOC]     = 1'b0;
assign      op_bus_brch[`BRCH_FENCE_LOC]    = 1'b0 | 1'b0;
assign      op_bus_brch[`BRCH_OP1_IS_PC]    = (~instr_one_of_bxx);
assign      op_bus_brch[`BRCH_OP2_IS_IMM]   = (~instr_one_of_bxx);


// ===========================================================================
//                                      系统相关指令
// ===========================================================================
assign      op_bus_sys[`SYS_WFI_LOC]        = 1'b0;
assign      op_bus_sys[`SYS_EBREAK_LOC]     = instr_c_ebreak;
assign      op_bus_sys[`SYS_ECALL_LOC]      = 1'b0;

// 选出一个译码信息, 由于OP_BUS_WIDTH使用的是各个OP_BUS_WIDTH中最大的那个, 如果直接使用OP_BUS_WIDTH - RGLR_OP_BUS_WIDTH,
// 有可能出现{0{1'b0}}的情况, 为了避免这个情况发生, 我们将op_bus_mux的位宽定义为OP_BUS_WIDTH+1, 这样可以保证相减后至少为1,
// 只需要在输出的时候忽略最高位即可.
assign      op_bus_rglr_sel =    instr_one_of_sub_xor_or_and |
                                instr_c_addi4spn |
                                (instr_fmt_ci & (~instr_c_lwsp)) |
                                instr_one_of_srxi_andi |
                                instr_c_mv |
                                instr_c_add |
                                1'b0;

assign      op_bus_lsu_sel = (opcode_is_00 | opcode_is_10) & (funct3_is_010 | funct3_is_110);

assign      op_bus_brch_sel = instr_one_of_bxx | instr_fmt_cj | instr_c_jr | instr_c_jalr;

assign      op_bus_sys_sel = instr_c_ebreak;

assign      dec_op_bus_mux =    ({(`DEC_OP_BUS_WIDTH + 1){op_bus_rglr_sel}} & {{(`DEC_OP_BUS_WIDTH + 1 - `RGLR_OP_BUS_WIDTH){1'b0}},    op_bus_rglr}) |
                                ({(`DEC_OP_BUS_WIDTH + 1){op_bus_brch_sel}} & {{(`DEC_OP_BUS_WIDTH + 1 - `BRCH_OP_BUS_WIDTH){1'b0}},    op_bus_brch}) |
                                ({(`DEC_OP_BUS_WIDTH + 1){op_bus_lsu_sel}}  & {{(`DEC_OP_BUS_WIDTH + 1 - `LSU_OP_BUS_WIDTH){1'b0}},     op_bus_lsu}) |
                                ({(`DEC_OP_BUS_WIDTH + 1){op_bus_sys_sel}}  & {{(`DEC_OP_BUS_WIDTH + 1 - `SYS_OP_BUS_WIDTH){1'b0}},     op_bus_sys});

assign      dec_op_bus = dec_op_bus_mux[0 +: `DEC_OP_BUS_WIDTH];
assign      dec_op_type =   op_bus_rglr_sel ? `DEC_RGLR_BUS :
                            op_bus_brch_sel ? `DEC_BRCH_BUS :
                            op_bus_lsu_sel ? `DEC_LSU_BUS :
                            op_bus_sys_sel ? `DEC_SYS_BUS :
                            `DEC_NONE_BUS;

// ===========================================================================
//                                  立即数解析
// ===========================================================================
// 以下指令的立即数编码格式相同
//  c.li
//  c.addi
//  c.andi
assign      {
                imm_addi_andi_li[5],
                imm_addi_andi_li[4 : 0]
            } = {
                ir[12],
                ir[6 : 2]
            };
assign      imm_addi_andi_li_sext = {{26{imm_addi_andi_li[5]}}, imm_addi_andi_li};


// 以下指令的立即数编码格式相同
//  c.srli
//  c.srai
//  c.slli
assign      {
                imm_srxi[5],
                imm_srxi[4 : 0]
            } = {
                ir[12],
                ir[6 : 2]
            };
assign      imm_srxi_uext = {26'd0, imm_srxi};

// lwsp指令的立即数
assign      {
                imm_lwsp[5],
                imm_lwsp[4 : 2],
                imm_lwsp[7 : 6]
            } = {
                ir[12],
                ir[6 : 2]
            };
assign      imm_lwsp_uext = {24'd0, imm_lwsp, 2'd0};

assign      imm_lwsp_not_0  = |imm_lwsp;
assign      imm_lwsp_is_0   = ~imm_lwsp_not_0;


// addi16sp的立即数
assign      {
                imm_addi16sp[9],
                imm_addi16sp[4],
                imm_addi16sp[6],
                imm_addi16sp[8 : 7],
                imm_addi16sp[5]
            } = {
                ir[12],
                ir[6 : 2]
            };
assign      imm_addi16sp_sext = {{22{imm_addi16sp[9]}}, imm_addi16sp, 4'd0};
assign      imm_addi16sp_not_0 = |imm_addi16sp;
assign      imm_addi16sp_is_0 = ~imm_addi16sp_not_0;

// lui指令的立即数
assign      {
                imm_lui[17],
                imm_lui[16 : 12]
            } = {
                ir[12],
                ir[6 : 2]
            };
assign      imm_lui_sext = {{14{imm_lui[17]}}, imm_lui, 12'd0};
assign      imm_lui_not_0 = |imm_lui;
assign      imm_lui_is_0 = ~imm_lui_not_0;

// addi4spn指令的立即数
assign      {
                imm_addi4spn[5 : 4],
                imm_addi4spn[9 : 6],
                imm_addi4spn[2],
                imm_addi4spn[3]
            } = {
                ir[12 : 5]
            };
assign      imm_addi4spn_uext = {22'd0, imm_addi4spn, 2'd0};

assign      imm_addi4spn_not_0  = |imm_addi4spn;
assign      imm_addi4spn_is_0   = ~imm_addi4spn_not_0;


// 以下指令的立即数编码格式相同
//  c.beqz
//  c.bnez
assign      {
                imm_bxx[8],
                imm_bxx[4 : 3],
                imm_bxx[7 : 6],
                imm_bxx[2 : 1],
                imm_bxx[5]
            } = {
                ir[12 : 10],
                ir[6 : 2]
            };
assign      imm_bxx_sext = {{23{imm_bxx[8]}}, imm_bxx, 1'b0};



// 以下指令的立即数编码格式相同
//  c.lw
//  c.sw
assign      {
                imm_ls[5 : 3],
                imm_ls[2],
                imm_ls[6]
            } = {
                ir[12 : 10],
                ir[6 : 5]
            };
assign      imm_ls_uext = {25'd0, imm_ls, 2'd0};


// 以下指令的立即数编码格式相同
//  c.j
//  c.jal
assign      {
                imm_j_jal[11],
                imm_j_jal[4],
                imm_j_jal[9 : 8],
                imm_j_jal[10],
                imm_j_jal[6],
                imm_j_jal[7],
                imm_j_jal[3 : 1],
                imm_j_jal[5]
            } = {
                ir[12 : 2]
            };
assign      imm_j_jal_sext = {{20{imm_j_jal[11]}}, imm_j_jal, 1'b0};



// swsp指令的立即数
assign      {
                imm_swsp[5 : 2],
                imm_swsp[7 : 6]
            } = {
                ir[12 : 7]
            };
assign      imm_swsp_uext = {24'd0, imm_swsp, 2'd0};

// 选取立即数
assign      imm_addi_andi_li_sel =  opcode_is_01 &
                                    (
                                        funct3_is_010 |
                                        funct3_is_000 |
                                        (funct3_is_100 & ir_bit11_10_is_10) |
                                        1'b0
                                    );

assign      imm_addi16sp_sel = instr_c_addi16sp;

assign      imm_srxi_sel = instr_c_slli |
                            (
                                opcode_is_01 & funct3_is_100 &
                                (
                                    ir_bit11_10_is_00 |
                                    ir_bit11_10_is_01 |
                                    1'b0
                                )
                            );

assign      imm_lwsp_sel = instr_c_lwsp;

assign      imm_lui_sel = instr_c_lui;

assign      imm_addi4spn_sel = instr_c_addi4spn;

assign      imm_bxx_sel =   opcode_is_01 &
                            (
                                funct3_is_110 |
                                funct3_is_111 |
                                1'b0
                            );

assign      imm_ls_sel =    opcode_is_00 &
                            (
                                funct3_is_010 |
                                funct3_is_110 |
                                1'b0
                            );

assign      imm_j_jal_sel =   opcode_is_01 &
                            (
                                funct3_is_101 |
                                funct3_is_001 |
                                1'b0
                            );

assign      imm_swsp_sel = instr_c_swsp;


assign      dec_imm =   ({32{imm_addi_andi_li_sel}} & imm_addi_andi_li_sext  ) |
                        ({32{imm_srxi_sel}}         & imm_srxi_uext          ) |
                        ({32{imm_lwsp_sel}}         & imm_lwsp_uext          ) |
                        ({32{imm_addi16sp_sel}}     & imm_addi16sp_sext      ) |
                        ({32{imm_addi4spn_sel}}     & imm_addi4spn_uext      ) |
                        ({32{imm_bxx_sel}}          & imm_bxx_sext           ) |
                        ({32{imm_j_jal_sel}}        & imm_j_jal_sext           ) |
                        ({32{imm_ls_sel}}           & imm_ls_uext            ) |
                        ({32{imm_lui_sel}}          & imm_lui_sext           ) |
                        ({32{imm_swsp_sel}}         & imm_swsp_uext          ) |
                        32'd0;

// ===========================================================================
//                             寄存器索引解析
// ===========================================================================
assign      rs1_rd      = ir[11 : 7];
assign      rs2         = ir[6 : 2];
assign      rs1_rd_d    = {2'b01, ir[9 : 7]};
assign      rs2d        = {2'b01, ir[4 : 2]};

// 判断索引是否为0，有些指令寄存器索引为0时是非法的
assign      rs1_rd_not_0    = |rs1_rd;
assign      rx1_rd_is_1     = &{~rs1_rd[4 : 1], rs1_rd[0]};
assign      rs1_rd_is_0     = ~rs1_rd_not_0;
assign      rs1_rd_is_2     = (rs1_rd == 6'd2);
assign      rs1_rd_not_2    = ~rs1_rd_is_2;

assign      rs2_not_0       = |rs2;
assign      rs2_is_0        = ~rs2_not_0;


wire        rd_sel_x0       = instr_c_jr |instr_c_j;
wire        rd_sel_x1       = instr_c_jalr | instr_c_jal;
wire        rd_sel_x2       = instr_c_addi16sp;
wire        rd_sel_rs2d     = instr_c_addi4spn | instr_c_lw;

wire        rs1_sel_x0      = instr_c_j | instr_c_li | instr_c_mv;
wire        rs1_sel_x1      = instr_c_jal;
wire        rs1_sel_x2      = instr_c_addi4spn | instr_c_lwsp | instr_c_swsp | instr_c_addi16sp;

wire        rs2_sel_x0      = instr_one_of_bxx;

// 选择寄存器索引，以下几个指令寄存器索引使用rxd，其余都使用rx
//  c.srli
//  c.srai
//  c.andi
//  c.sub
//  c.xor
//  c.or
//  c.and
assign      ridx_sel_d = instr_fmt_cb | instr_fmt_cs | instr_fmt_cl | instr_fmt_ciw;

// RV16扩展中，rd和rs1的索引保持一致
assign      dec_rd =    rd_sel_x0 ? 5'd0 :
                        rd_sel_x1 ? 5'd1 :
                        rd_sel_x2 ? 5'd2 :
                        rd_sel_rs2d ? rs2d :
                        ridx_sel_d ? rs1_rd_d :
                        rs1_rd;
assign      dec_rs1 =   rs1_sel_x0 ? 5'd0 :
                        rs1_sel_x1 ? 5'd1 :
                        rs1_sel_x2 ? 5'd2 :
                        ridx_sel_d ? rs1_rd_d :
                        rs1_rd;
assign      dec_rs2 =   rs2_sel_x0 ? 5'd0 :
                        ridx_sel_d ? rs2d :
                        rs2;

// 非法指令
assign      dec_ilegl_ir =  ~(
                                op_bus_rglr_sel |
                                op_bus_brch_sel |
                                op_bus_lsu_sel |
                                op_bus_sys_sel
                            );


assign      dec_imm_bxx = imm_bxx_sext;
assign      dec_imm_jal = imm_j_jal_sext;
// 对于16位指令来说，jalr指令的立即数都是0
assign      dec_imm_jalr = 32'd0;

assign      dec_ir_bxx = instr_one_of_bxx;
assign      dec_ir_jal = instr_fmt_cj;
assign      dec_ir_jalr = instr_c_jr | instr_c_jalr;

assign      dec_rs1_x1 = rx1_rd_is_1;
endmodule