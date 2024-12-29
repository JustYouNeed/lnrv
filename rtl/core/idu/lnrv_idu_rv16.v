module lnrv_idu_rv16
(
    input[15 : 0]                           ir,

    output[5 : 0]                           dec_rd_idx,
    output[5 : 0]                           dec_rs1_idx,
    output[5 : 0]                           dec_rs2_idx,

    output[31 : 0]                          dec_imm,

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

wire[5 : 0]                                 rs2;
wire                                        rs2_is_0;
wire                                        rs2_not_0;
wire[2 : 0]                                 rs2d;

wire[5 : 0]                                 rs1;
wire[3 : 0]                                 rs1d;

wire[5 : 0]                                 rd;
wire[2 : 0]                                 rdd;
wire                                        rd_is_0;
wire                                        rd_not_0;

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
wire[17 : 12]                               imm_lui;
wire[31 : 0]                                imm_lui_sext;
wire                                        imm_lui_sel;
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
wire[11 : 1]                                imm_jxx;
wire[31 : 0]                                imm_jxx_sext;
wire                                        imm_jxx_sel;
wire[7 : 2]                                 imm_swsp;
wire[31 : 0]                                imm_swsp_uext;
wire                                        imm_swsp_sel;

wire                                        rv16_fmt_ci;
wire                                        rv16_fmt_ciw;
wire                                        rv16_fmt_css;
wire                                        rv16_fmt_cl;
wire                                        rv16_fmt_cs;
wire                                        rv16_fmt_cj;
wire                                        rv16_fmt_cr;
wire                                        rv16_fmt_cb;


assign      funct3              = ir[15 : 13];
assign      opcode              = ir[1 : 0];
assign      ir_bit12            = ir[12];
assign      ir_bit11_10         = ir[11 : 10];
assign      ir_bit6_5           = ir[6 : 5];


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


assign      rv16_fmt_ci =   (opcode_is_01 & (funct3_is_000 | funct3_is_010 | funct3_is_011)) | 
                            (opcode_is_10 & (funct3_is_000 | funct3_is_010));

assign      rv16_fmt_ciw = opcode_is_00 & funct3_is_000;

assign      rv16_fmt_css = opcode_is_10 & funct3_is_110;

assign      rv16_fmt_cl = opcode_is_00 & funct3_is_110;
// assign      rv16_fmt_cs = opcode


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
assign      instr_c_lwsp = funct3_is_010 & opcode_is_10;
assign      instr_c_lwsp_ilgl = instr_c_lwsp & rs1_rd_is_0;

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
assign      instr_c_addi16sp = funct3_is_011 & opcode_is_01;
assign      instr_c_addi16sp_ilgl = instr_c_addi16sp & imm_addi16sp_is_0

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
assign      instr_c_lui = funct3_is_011 & opcode_is_01;
assign      instr_c_lui_ilgl = instr_c_lui & 
                                (
                                    rs1_rd_is_2 |
                                    imm_lui_is_0 | 
                                    1'b0
                                );

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
assign      instr_c_addi4spn = funct3_is_000 & opcode_is_00;


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
assign      instr_c_sub = funct3_is_100 & ir_bit12_10_is_011 & opcode_is_01;

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
assign      instr_c_xor = funct3_is_100 & ir_bit12_10_is_011 & ir_bit6_5_is_01 & opcode_is_01;


assign      instr_c_or = funct3_is_100 & ir_bit12_10_is_011 & ir_bit6_5_is_10 & opcode_is_01;


assign      instr_c_and = funct3_is_110 & ir_bit12_10_is_011 & ir_bit6_5_is_11 & opcode_is_01;

assign      instr_c_jr = funct3_is_100 & ir_bit12_is_0 & rs2_idx_is_0 & opcode_is_10;

assign      instr_c_mv = funct3_is_100 & ir_bit12_is_0 & rs2_idx_not_0 & opcode_is_10;

assign      instr_c_ebreak = funct3_is_100 & ir_bit12_is_1 & rd_idx_is_0 & rs2_idx_is_0 & opcode_is_10;

assign      instr_c_jalr = funct3_is_100 & ir_bit12_is_1 & rs2_idx_is_0 & opcode_is_10;


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
assign      instr_c_add = funct3_is_100 & ir_bit12_is_1 & rd_idx_not_0 & rs2_idx_not_0 & opcode_is_10;


// 生成常规指令的操作总线
assign      rglr_op_bus[`RGLR_ADD_LOC]      = instr_c_add | instr_c_addi | instr_c_mv;
assign      rglr_op_bus[`RGLR_SUB_LOC]      = instr_c_sub;
assign      rglr_op_bus[`RGLR_AND_LOC]      = instr_c_and | instr_c_andi;
assign      rglr_op_bus[`RGLR_OR_LOC]       = instr_c_or;
assign      rglr_op_bus[`RGLR_XOR_LOC]      = instr_c_xor;
assign      rglr_op_bus[`RGLR_SLL_LOC]      = instr_c_slli;
assign      rglr_op_bus[`RGLR_SRA_LOC]      = instr_c_srai;
assign      rglr_op_bus[`RGLR_SRL_LOC]      = instr_c_srli;
assign      rglr_op_bus[`RGLR_AUIPC_LOC]    = 1'b0;
assign      rglr_op_bus[`RGLR_LUI_LOC]      = instr_c_lui;
assign      rglr_op_bus[`RGLR_SLTU_LOC]     = 1'b0;
assign      rglr_op_bus[`RGLR_OP1_IS_PC]    = 1'b0;
assign      rglr_op_bus[`RGLR_OP2_IS_IMM]   = instr_i_type | instr_u_type;
assign      dec_rglr_instr =    opcode_is_0010011 | 
                                (opcode_is_0110011 & (~funct7_is_0000001)) |     //opcode == 0110011 且 funct7 == 0000001时, 为乘除法指令
                                instr_lui | 
                                instr_auipc;



// ===========================================================================
//                                  立即数解析
// ===========================================================================
// 以下指令的立即数编码格式相同
//  c.li
//  c.addi
//  c.andi
assign      {
                imm_addi_andi_li[5],
                imm_addi_andi_li[4 : 0],
            } = {
                ir[12],
                ir[6 : 2]
            };
assign      imm_addi_andi_li_sext = {{26{imm_addi_andi_li[5]}}, imm_addi_andi_li};
assign      imm_addi_andi_li_sel =  opcode_is_01 & 
                                    (
                                        funct3_is_010 | 
                                        funct3_is_000 | 
                                        (funct3_is_100 & ir_bit11_10_is_10) | 
                                        1'b0
                                    );

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
assign      imm_srxi_sel = instr_c_slli | 
                            (
                                opcode_is_01 & funct3_is_100 & 
                                (
                                    ir_bit11_10_is_00 | 
                                    ir_bit11_10_is_01 | 
                                    1'b0
                                )
                            );

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
assign      imm_lwsp_sel = instr_c_lwsp;

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
assign      imm_addi16sp_sel = instr_c_addi16sp;


// lui指令的立即数
assign      {
                imm_lui[17],
                imm_lui[16 : 12]
            } = {
                ir[12],
                ir[6 : 2]
            };
assign      imm_lui_sext = {{14{imm_lui[17]}}, imm_lui, 12'd0};
assign      imm_lui_sel = instr_c_lui;


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
assign      imm_addi4spn_sel = instr_c_addi4spn;

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
assign      imm_bxx_sel =   opcode_is_01 & 
                            (
                                funct3_is_110 | 
                                funct3_is_111 | 
                                1'b0
                            );


// 以下指令的立即数编码格式相同
//  c.lw
//  c.sw
assign      {
                imm_ls[5 : 3],
                imm_ls[2],
                imm_ls[6],
            } = {
                ir[12 : 10],
                ir[6 : 5]
            };
assign      imm_ls_uext = {25'd0, imm_ls, 2'd0};
assign      imm_ls_sel =    opcode_is_00 & 
                            (
                                funct3_is_010 | 
                                funct3_is_110 | 
                                1'b0
                            );

// 以下指令的立即数编码格式相同
//  c.j
//  c.jal
assign      {
                imm_jxx[11],
                imm_jxx[4],
                imm_jxx[9 : 8],
                imm_jxx[10],
                imm_jxx[6],
                imm_jxx[7],
                imm_jxx[3 : 1],
                imm_jxx[5],
            } = {
                ir[12 : 2]
            };
assign      imm_jxx_sext = {{20{imm_jxx[11]}}, imm_jxx, 1'b0};
assign      imm_jxx_sel =   opcode_is_01 & 
                            (
                                funct3_is_101 | 
                                funct3_is_001 | 
                                1'b0
                            );


// swsp指令的立即数
assign      {
                imm_swsp[5 : 2],
                imm_swsp[7 : 6],
            } = {
                ir[12 : 7]
            };
assign      imm_swsp_uext = {24'd0, imm_swsp, 2'd0};
assign      imm_swsp_sel = instr_c_swsp;


// 选取立即数
assign      dec_imm =   ({32{imm_addi_andi_li_sel}} & imm_addi_andi_li  ) | 
                        ({32{imm_srxi_sel}}         & imm_srxi          ) | 
                        ({32{imm_lwsp_sel}}         & imm_lwsp          ) | 
                        ({32{imm_addi16sp_sel}}     & imm_addi16sp      ) | 
                        ({32{imm_addi4spn_sel}}     & imm_addi4spn      ) | 
                        ({32{imm_bxx_sel}}          & imm_bxx           ) | 
                        ({32{imm_jxx_sel}}          & imm_jxx           ) | 
                        ({32{imm_ls_sel}}           & imm_ls            ) | 
                        ({32{imm_lui_sel}}          & imm_lui           ) | 
                        ({32{imm_swsp_sel}}         & imm_swsp          ) | 
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
assign      rs1_rd_is_0     = ~rs1_rd_not_0;
assign      rs1_rd_is_2     = (rs1_rd == 6'd2);

assign      rs2_not_0       = |rs2;
assign      rs2_is_0        = ~rs2_not_0;

// 选择寄存器索引，以下几个指令寄存器索引使用rxd，其余都使用rx
//  c.srli
//  c.srai
//  c.andi
//  c.sub
//  c.xor
//  c.or
//  c.and
assign      ridx_sel_d =    (opcode_is_01 & funct3_is_100) | 
                            instr_is_bxx | 
                            instr_is_ls | 
                            1'b0;

// RV16扩展中，rd和rs1的索引保持一致
assign      dec_rd_idx = ridx_sel_d ? rs1_rd_d : rs1_rd;
assign      dec_rs1_idx = dec_rd_idx;
assign      dec_rs2_idx = ridx_sel_d ? rs2d : rs2;

endmodule