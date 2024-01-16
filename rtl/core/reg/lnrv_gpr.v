`include    "lnrv_def.v"
module	lnrv_gpr#
(
    parameter                       P_ADDR_WIDTH = 5
)
(
    // 读接口
    input[P_ADDR_WIDTH - 1 : 0]     rs1_idx,
    output[31 : 0]                  rs1_rdata,
    input[P_ADDR_WIDTH - 1 : 0]     rs2_idx,
    output[31 : 0]                  rs2_rdata,

    // 写接口
    input                           wr_vld,
    output                          wr_rdy,
    input[`GPR_ADDR_WIDTH - 1 : 0]  wr_idx,
    input[31 : 0]                   wr_data,

    // 特别引出x1
    output[31 : 0]                  ra,

    input                           clk,
    input                           reset_n
);

localparam                      LP_REG_COUNT = (2 << P_ADDR_WIDTH);

// 第0个寄存器固定为0
reg[`CPU_DATA_WIDTH - 1 : 0]    gpr_q[LP_REG_COUNT - 1 : 1];
wire[LP_REG_COUNT - 1 : 1]      gpr_rld;
wire[`CPU_DATA_WIDTH - 1 : 0]   gpr_d[LP_REG_COUNT - 1 : 1];

wire[`CPU_DATA_WIDTH - 1 : 0]   gpr[LP_REG_COUNT - 1 : 0];

wire                            rs1_wr_idx_eq;
wire                            rs1_raw;
wire                            rs2_wr_idx_eq;
wire                            rs2_raw;
genvar                          i;


generate
    for(i = 1; i < LP_REG_COUNT; i = i + 1) begin: gpr_inst
        assign      gpr_rld[i] = wr_vld & (wr_idx == i);
        assign      gpr_d[i] = wr_data;
        always@(posedge clk or negedge reset_n) begin
            if(reset_n == 1'b0) begin
                gpr_q[i] <= {`CPU_DATA_WIDTH{1'b0}};
            end else if(gpr_rld[i]) begin
                gpr_q[i] <= gpr_d[i];
            end
        end
    end

    for(i = 0; i < LP_REG_COUNT; i = i + 1) begin
        if(i == 0) begin
            assign      gpr[i] = {`CPU_DATA_WIDTH{1'b0}};
        end else begin
            assign      gpr[i] = gpr_q[i];
        end
    end
endgenerate

// 检测相关性，读写同时发生
assign      rs1_wr_idx_eq   = 1'b0;//(rs1_idx == wr_idx);
assign      rs1_raw         = 1'b0;//wr_vld & rs1_wr_idx_eq;
assign      rs2_wr_idx_eq   = 1'b0;//(rs2_idx == wr_idx);
assign      rs2_raw         = 1'b0;//wr_vld & rs2_wr_idx_eq;



assign	rs1_rdata =     rs1_raw ? wr_data : 
						gpr[rs1_idx];

assign	rs2_rdata =     rs2_raw ? wr_data : 	/* 读取正在写的寄存器，则直接将写入的数据输出 */
						gpr[rs2_idx];

// 写寄存器只需要一个时钟周期，wr_rdy总是有效
assign	wr_rdy = 1'b1;

/* 仿真时使用 */
wire[31 : 0]        zero = gpr[0];
assign              ra = gpr[1];
wire[31 : 0]        sp = gpr[2];
wire[31 : 0]        gp = gpr[3];
wire[31 : 0]        tp = gpr[4];
wire[31 : 0]        t0 = gpr[5];
wire[31 : 0]        t1 = gpr[6];
wire[31 : 0]        t2 = gpr[7];
wire[31 : 0]        s0 = gpr[8];
wire[31 : 0]        s1 = gpr[9];
wire[31 : 0]        a0 = gpr[10];
wire[31 : 0]        a1 = gpr[11];
wire[31 : 0]        a2 = gpr[12];
wire[31 : 0]        a3 = gpr[13];
wire[31 : 0]        a4 = gpr[14];
wire[31 : 0]        a5 = gpr[15];
wire[31 : 0]        a6 = gpr[16];
wire[31 : 0]        a7 = gpr[17];
wire[31 : 0]        s2 = gpr[18];
wire[31 : 0]        s3 = gpr[19];
wire[31 : 0]        s4 = gpr[20];
wire[31 : 0]        s5 = gpr[21];
wire[31 : 0]        s6 = gpr[22];
wire[31 : 0]        s7 = gpr[23];
wire[31 : 0]        s8 = gpr[24];
wire[31 : 0]        s9 = gpr[25];
wire[31 : 0]        s10 = gpr[26];
wire[31 : 0]        s11 = gpr[27];
wire[31 : 0]        t3 = gpr[28];
wire[31 : 0]        t4 = gpr[29];
wire[31 : 0]        t5 = gpr[30];
wire[31 : 0]        t6 = gpr[31];

endmodule