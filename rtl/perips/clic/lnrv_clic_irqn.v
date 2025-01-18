module lnrv_clic_irqn#
(
    parameter                   P_IRQ_ID = 8
)
(
    input                       clk,
    input                       reset_n,

    input                       irq,

    // 软件操作接口
    input                       icb_write_access,
    input[15 : 0]               icb_cmd_addr,
    input[31 : 0]               icb_cmd_wdata,
    input[3 : 0]                icb_cmd_wstrb,

    output[31 : 0]              irq_reg_full,

    // 硬件清中断
    input                       ip_clr_hw,
    input[7 : 0]                ip_clr_id_hw
);

localparam                      LP_IRQN_REG_ADDR = (16'h1000 + 4 * P_IRQ_ID);

wire                            cmd_addr_match;
wire                            reg_write_enable;
wire                            reg_write_byte0;
wire                            reg_write_byte1;
wire                            reg_write_byte2;
wire                            reg_write_byte3;

reg                             ip_q;
wire                            ip_set;
wire                            ip_clr;
wire                            ip_rld;
wire                            ip_d;

reg                             ie_q;
wire                            ie_rld;
wire                            ie_d;

reg[1 : 0]                      trig_q;
wire                            trig_rld;
wire[1 : 0]                     trig_d;

reg                             shv_q;
wire                            shv_rld;
wire                            shv_d;

reg[1 : 0]                      level_q;
wire                            level_rld;
wire[1 : 0]                     level_d;

reg[1 : 0]                      priority_q;
wire                            priority_rld;
wire[1 : 0]                     priority_d;

reg                             irq_dly_q;
wire                            irq_dly_d;

wire                            irq_pdg;
wire                            irq_ndg;

wire                            pdg_trig_mode;
wire                            ndg_trig_mode;
wire                            h_level_trig_mode;
wire                            ip_clr_id_match;

assign      cmd_addr_match = (icb_cmd_addr == LP_IRQN_REG_ADDR);
assign      reg_write_enable = cmd_addr_match & icb_write_access;

assign      reg_write_byte0 = reg_write_enable & icb_cmd_wstrb[0];
assign      reg_write_byte1 = reg_write_enable & icb_cmd_wstrb[1];
assign      reg_write_byte2 = reg_write_enable & icb_cmd_wstrb[2];
assign      reg_write_byte3 = reg_write_enable & icb_cmd_wstrb[3];

assign      ip_clr_id_match = (ip_clr_id_hw == P_IRQ_ID[7 : 0]);


assign      irq_dly_d = irq;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        irq_dly_q <= 1'b0;
    end else begin
        irq_dly_q <= irq_dly_d;
    end
end

assign      irq_pdg = (~irq_dly_q) & irq_dly_d;
assign      irq_ndg = irq_dly_q & (~irq_dly_d);

assign      pdg_trig_mode       = (trig_q == 2'b01);
assign      ndg_trig_mode       = (trig_q == 2'b10);
assign      h_level_trig_mode   = (trig_q == 2'b00);

// interrupt pending register
assign      ip_set =    (pdg_trig_mode & irq_pdg) |
                        (ndg_trig_mode & irq_ndg) |
                        (h_level_trig_mode & irq_dly_q) |
                        1'b0;
assign      ip_clr = ip_clr_hw & ip_clr_id_match;
assign      ip_rld = ip_set | ip_clr | reg_write_byte0;
assign      ip_d = reg_write_byte0 ? icb_cmd_wdata[0] : ip_set;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        ip_q <= 1'b0;
    end else if(ip_rld) begin
        ip_q <= ip_d;
    end
end

// interrupt enable
assign      ie_rld = reg_write_byte1;
assign      ie_d = icb_cmd_wdata[8];
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        ie_q <= 1'b1;
    end else if(ie_rld) begin
        ie_q <= ie_d;
    end
end

// interrupt trigger mode
assign      trig_rld = reg_write_byte2;
assign      trig_d = icb_cmd_wdata[18 : 17];
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        trig_q <= 2'b00;
    end else if(trig_rld) begin
        trig_q <= trig_d;
    end
end

// 中断模式：0：非向量模式，1：向量模式
assign      shv_rld = reg_write_byte2;
assign      shv_d = icb_cmd_wdata[16];
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        shv_q <= 1'b1;
    end else if(shv_rld) begin
        shv_q <= shv_d;
    end
end

// 中断level
assign      level_rld = reg_write_byte3;
assign      level_d = icb_cmd_wdata[31 : 30];
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        level_q <= 2'b00;
    end else if(level_rld) begin
        level_q <= level_d;
    end
end


assign      priority_rld = reg_write_byte3;
assign      priority_d = icb_cmd_wdata[29 : 28];
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        priority_q <= 2'b00;
    end else if(priority_rld) begin
        priority_q <= priority_d;
    end
end

assign      irq_reg_full[7 : 0]     = {7'd0, ip_q};
assign      irq_reg_full[15 : 8]    = {7'd0, ie_q};
assign      irq_reg_full[23 : 16]   = {2'd3, 3'd0, trig_q, shv_q};
assign      irq_reg_full[31 : 24]   = {level_q, priority_q, 4'b1111};


endmodule