
`define		CPU_DATA_WIDTH				        32
`define		CPU_ADDR_WIDTH				        32

`define		GPR_ADDR_WIDTH				        5		/* 通用寄存器组地址宽度 */
`define		CSR_ADDR_WIDTH				        12		/* CSR寄存器地址宽度 */
		
`define		CPU_RESET_VECTOR			        `CPU_ADDR_WIDTH'h0


`define		INSTR_FENCE_I				        32'b000000000000_00000_001_00000_0001111
`define		INSTR_ECALL					        32'b000000000000_00000_000_00000_1110011
`define		INSTR_EBREAK					    32'b000000000001_00000_000_00000_1110011
`define 	INSTR_MRET    				        32'h30200073

//opcode在instr中的僧
`define     INSTR_OPCODE_WIDTH                  7
`define     INSTR_OPCODE_LSB                    0
`define     INSTR_OPCODE_MSB                    `INSTR_OPCODE_LSB + `INSTR_OPCODE_WIDTH
`define		INSTR_OPCODE_LOC			        `INSTR_OPCODE_MSB : `INSTR_OPCODE_LSB

//rd在instr位置
`define     INSTR_RD_WIDTH                      `GPR_ADDR_WIDTH
`define     INSTR_RD_LSB                        6
`define     INSTR_RD_MSB                        `INSTR_RD_LSB + `INSTR_RD_WIDTH
`define		INSTR_RD_LOC				        `INSTR_RD_LSB +: `INSTR_RD_WIDTH

//rs位置
`define     INSTR_RS1_WIDTH                      `GPR_ADDR_WIDTH
`define     INSTR_RS1_LSB                       15
`define     INSTR_RS1_MSB                       `INSTR_RS1_LSB + `INSTR_RS1_WIDTH
`define		INSTR_RS1_LOC				        `INSTR_RS1_LSB +: `INSTR_RS1_WIDTH

//rs2位置
`define     INSTR_RS2_WIDTH                     `GPR_ADDR_WIDTH
`define     INSTR_RS2_LSB                       20
`define     INSTR_RS2_MSB                       `INSTR_RS2_LSB + `INSTR_RS2_WIDTH
`define		INSTR_RS2_LOC				        `INSTR_RS2_LSB +: `INSTR_RS2_WIDTH

//funct3位置
`define     INSTR_FUNCT3_WIDTH                  3
`define     INSTR_FUNCT3_LSB                    12
`define     INSTR_FUNCT3_MSB                    `INSTR_FUNCT3_LSB + `INSTR_FUNCT3_WIDTH
`define		INSTR_FUNCT3_LOC				    `INSTR_FUNCT3_LSB +: `INSTR_FUNCT3_WIDTH

//funct7位置
`define     INSTR_FUNCT7_WIDTH                  7
`define     INSTR_FUNCT7_LSB                    25
`define     INSTR_FUNCT7_MSB                    `INSTR_FUNCT7_LSB + `INSTR_FUNCT7_WIDTH
`define		INSTR_FUNCT7_LOC				    `INSTR_FUNCT7_LSB +: `INSTR_FUNCT7_WIDTH

//csr寄存器索引位置
`define     INSTR_CSR_WIDTH                     `CSR_ADDR_WIDTH
`define     INSTR_CSR_LSB                       20
`define     INSTR_CSR_MSB                       `INSTR_CSR_LSB + `INSTR_CSR_WIDTH
`define		INSTR_CSR_LOC				        `INSTR_CSR_LSB +: `INSTR_CSR_WIDTH
		
`define		INSTR_S_IMM4_0_LOC			11 : 7
`define		INSTR_S_IMM11_5_LOC			31 : 25
`define		INSTR_S_IMM_MSB_LOC			31

`define		INSTR_B_IMM11_LOC			7
`define		INSTR_B_IMM4_1_LOC			11 : 8
`define		INSTR_B_IMM10_5_LOC			30 : 25
`define		INSTR_B_IMM12_LOC			31
`define		INSTR_B_IMM_MSB_LOC			31

`define		INSTR_U_IMM31_12_LOC			31 : 12
`define		INSTR_U_IMM_MSB_LOC			31

`define		INSTR_J_IMM19_12_LOC			19 : 12
`define		INSTR_J_IMM11_LOC			20
`define		INSTR_J_IMM10_1_LOC			30 : 21
`define		INSTR_J_IMM20_LOC			31
`define		INSTR_J_IMM_MSB_LOC			31

`define		INSTR_I_IMM11_0_LOC			31 : 20
`define		INSTR_I_IMM_MSB_LOC			31

`define     GET_INSTR_OPCODE(ir)      ir[`INSTR_OPCODE_LOC]		/* 获取指令中的操作码 */
`define     GET_INSTR_RD(ir)          ir[`INSTR_RD_LOC]			/* 获取指令中的RD寄存器地址 */
`define     GET_INSTR_RS1(ir)         ir[`INSTR_RS1_LOC]			/* 获取指令中的RS1寄存器地址 */
`define     GET_INSTR_RS2(ir)         ir[`INSTR_RS2_LOC]			/* 获取指令中RS2寄存器地址 */
`define     GET_INSTR_CSR(ir)         ir[`INSTR_CSR_LOC]
`define     GET_INSTR_FUNCT3(ir)      ir[`INSTR_FUNCT3_LOC]		/* 获取指令中funct3信息 */
`define     GET_INSTR_FUNCT7(ir)      ir[`INSTR_FUNCT7_LOC]		/* 获取指令中funct7信息 */

// csr指令相关的zimm
`define     I_TYPE_ZIMM_MSB             19
`define     I_TYPE_ZIMM_LSB             15
`define     I_TYPE_ZIMM_LOC             `I_TYPE_ZIMM_MSB : `I_TYPE_ZIMM_LSB
`define     I_TYPE_ZIMM_WIDTH           (`I_TYPE_ZIMM_MSB - `I_TYPE_ZIMM_LSB + 1)

`define     I_TYPE_SHAMT_MSB            25
`define     I_TYPE_SHAMT_LSB            20
`define     I_TYPE_SHAMT_LOC            `I_TYPE_SHAMT_MSB : `I_TYPE_SHAMT_LSB
`define     I_TYPE_SHAMT_WIDTH          (`I_TYPE_SHAMT_MSB - `I_TYPE_SHAMT_LSB + 1)

`define     I_TYPE_IMM_MSB              31
`define     I_TYPE_IMM_LSB              20
`define     I_TYPE_IMM_LOC              `I_TYPE_IMM_MSB : `I_TYPE_IMM_LSB
`define     I_TYPE_IMM_WIDTH            (`I_TYPE_IMM_MSB - `I_TYPE_IMM_LSB + 1)

`define     U_TYPE_IMM_MSB              31
`define     U_TYPE_IMM_LSB              12
`define     U_TYPE_IMM_LOC              `U_TYPE_IMM_MSB : `U_TYPE_IMM_LSB
`define     U_TYPE_IMM_WIDTH            (`U_TYPE_IMM_MSB - `U_TYPE_IMM_LSB + 1)

// 获取I型指令立即数
// shamt和zimm都是0扩展，imm是符号位扩展
`define     GET_I_TYPE_IMM(ir)          {{20{ir[31]}}, ir[31 : 20]}
`define     GET_I_TYPE_SHAMT(ir)        {{27{1'b0}}, ir[24 : 20]}
`define     GET_I_TYPE_ZIMM(ir)         {{27{1'b0}}, ir[19 : 15]}
`define     GET_B_TYPE_BXX_IMM(ir)      {{19{ir[31]}}, ir[31], ir[7], ir[30 : 25], ir[11 : 8], 1'b0}
`define     GET_B_TYPE_JAL_IMM(ir)      {{11{ir[31]}}, ir[31], ir[19 : 12], ir[20], ir[30 : 21], 1'b0}
`define     GET_U_TYPE_IMM(ir)          {ir[31 : 12], 12'd0}
`define     GET_S_TYPE_IMM(ir)          {{20{ir[31]}}, ir[31 : 25], ir[11 : 7]}

/* 获取S型指令立即数 */
`define		INSTR_GET_S_TYPE_IMM(ir)	{{20{ir[`INSTR_S_IMM_MSB_LOC]}}, ir[`INSTR_S_IMM11_5_LOC], ir[`INSTR_S_IMM4_0_LOC]}

/* 获取B型指令立即数 */
`define		INSTR_GET_B_TYPE_IMM(ir)	{{19{ir[`INSTR_B_IMM_MSB_LOC]}}, ir[`INSTR_B_IMM12_LOC], ir[`INSTR_B_IMM11_LOC], ir[`INSTR_B_IMM10_5_LOC], ir[`INSTR_B_IMM4_1_LOC], 1'b0}

/* 获取U型指令立即数 */
`define		INSTR_GET_U_TYPE_IMM(ir)	{ir[`INSTR_U_IMM31_12_LOC], 12'h0}

/* 获取J型指令立即数 */
`define		INSTR_GET_J_TYPE_IMM(ir)	{{12{ir[`INSTR_J_IMM_MSB_LOC]}}, ir[`INSTR_J_IMM20_LOC], ir[`INSTR_J_IMM19_12_LOC], ir[`INSTR_J_IMM11_LOC], ir[`INSTR_J_IMM10_1_LOC], 1'b0}



`define 	DEC_BUS_TYPE_WIDTH             3
`define     DEC_BUS_TYPE_LSB               0
`define     DEC_BUS_TYPE_LOC               `DEC_BUS_TYPE_LSB +: `DEC_BUS_TYPE_WIDTH

//译码信息总线类型
`define     DEC_NONE_BUS                    `DEC_BUS_TYPE_WIDTH'd0
`define 	DEC_RGLR_BUS          	        `DEC_BUS_TYPE_WIDTH'd1     //常规运算指令
`define 	DEC_BJP_BUS          	        `DEC_BUS_TYPE_WIDTH'd2     //分支运算指令
`define 	DEC_MDV_BUS       	            `DEC_BUS_TYPE_WIDTH'd3     //乘除法指令
`define 	DEC_CSR_BUS          	        `DEC_BUS_TYPE_WIDTH'd4     //CSR指令
`define 	DEC_MEM_BUS          	        `DEC_BUS_TYPE_WIDTH'd5     //内存操作指令
`define 	DEC_SYS_BUS          	        `DEC_BUS_TYPE_WIDTH'd6     //系统相关指令

`define     DEC_OP_BUS_WIDTH                14

`define     RGLR_OP_BUS_WIDTH               14
`define     RGLR_ADD_LOC                    0
`define     RGLR_SUB_LOC                    1
`define     RGLR_AND_LOC                    2
`define     RGLR_OR_LOC                     3
`define     RGLR_XOR_LOC                    4
`define     RGLR_SLL_LOC                    5
`define     RGLR_SLT_LOC                    6
`define     RGLR_SRA_LOC                    7
`define     RGLR_SRL_LOC                    8
`define     RGLR_AUIPC_LOC                  9
`define     RGLR_LUI_LOC                    10
`define     RGLR_SLTU_LOC                   11
`define     RGLR_OP1_IS_PC                  12
`define     RGLR_OP2_IS_IMM                 13

`define     BRCH_OP_BUS_WIDTH               13
`define     BRCH_BEQ_LOC                    0
`define     BRCH_BGE_LOC                    1
`define     BRCH_BGEU_LOC                   2
`define     BRCH_BLT_LOC                    3
`define     BRCH_BLTU_LOC                   4
`define     BRCH_BNE_LOC                    5
`define     BRCH_JAL_LOC                    6
`define     BRCH_JALR_LOC                   7
`define     BRCH_MRET_LOC                   8
`define     BRCH_DRET_LOC                   9
`define     BRCH_FENCE_LOC                  10
`define     BRCH_OP1_IS_PC                  11
`define     BRCH_OP2_IS_IMM                 12

`define     SYS_OP_BUS_WIDTH                3
`define     SYS_WFI_LOC                     0
`define     SYS_EBREAK_LOC                  1
`define     SYS_ECALL_LOC                   2
// `define     SYS_FENCE_LOC                   3
// `define     SYS_FENCEI_LOC                  4


`define     CSR_OP_BUS_WIDTH                5
`define     CSR_CSRRC_LOC                   0
`define     CSR_CSRRS_LOC                   1
`define     CSR_CSRRW_LOC                   2
`define     CSR_OP1_IS_ZERO                 3
`define     CSR_OP2_IS_IMM                  4

`define     LSU_OP_BUS_WIDTH                5
`define     LSU_LOAD_LOC                    0
`define     LSU_STORE_LOC                   1
`define     LSU_SIZE_LOC                    3:2
`define     LSU_UEXT_LOC                    4

`define     MDV_OP_BUS_WIDTH                6
`define     MDV_DIV_LOC                     0
`define     MDV_MUL_LOC                     1
`define     MDV_REM_LOC                     2
`define     MDV_OP1_UNSIGNED_LOC            3
`define     MDV_OP2_UNSIGNED_LOC            4
`define     MDV_RES_HIGH_LOC                5


`define     ALU_OP_BUS_WIDTH                14
`define     ALU_ADD_LOC                     0
`define     ALU_SUB_LOC                     1
`define     ALU_AND_LOC                     2
`define     ALU_OR_LOC                      3
`define     ALU_XOR_LOC                     4
`define     ALU_SLL_LOC                     5
`define     ALU_SRL_LOC                     6
`define     ALU_SRA_LOC                     7
`define     ALU_EQ_LOC                      8
`define     ALU_GTEU_LOC                    9
`define     ALU_GTE_LOC                     10
`define     ALU_LT_LOC                      11
`define     ALU_LTU_LOC                     12
`define     ALU_NEQ_LOC                     13


/* 控制和状态寄存器地址 */
`define     CSR_MSTATUS_ADDR                 `CSR_ADDR_WIDTH'h300
`define     CSR_MISA_ADDR	                 `CSR_ADDR_WIDTH'h301
`define     CSR_MEDELEG_ADDR                 `CSR_ADDR_WIDTH'h302
`define     CSR_MIDELEG_ADDR                 `CSR_ADDR_WIDTH'h303
`define     CSR_MIE_ADDR	                 `CSR_ADDR_WIDTH'h304
`define     CSR_MTVEC_ADDR	                 `CSR_ADDR_WIDTH'h305
`define     CSR_MCOUNTEREN_ADDR              `CSR_ADDR_WIDTH'h306

`define     CSR_MSCRATCH_ADDR                `CSR_ADDR_WIDTH'h340
`define     CSR_MEPC_ADDR	                 `CSR_ADDR_WIDTH'h341
`define     CSR_MCAUSE_ADDR	                 `CSR_ADDR_WIDTH'h342
`define     CSR_MTVAL_ADDR	                 `CSR_ADDR_WIDTH'h343
`define     CSR_MIP_ADDR	                 `CSR_ADDR_WIDTH'h344


`define     CSR_MCYCLE_ADDR	                 `CSR_ADDR_WIDTH'hb00
`define     CSR_MCYCLEH_ADDR                 `CSR_ADDR_WIDTH'hb80

`define     WFI_INSTR                           {7'b0001000, 5'b00101, 5'b00000, 3'b000, 7'b1110011}








