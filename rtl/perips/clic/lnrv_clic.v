// core local interrupt controller
module lnrv_clic#
(
    parameter                       P_LEN_WIDTH     =4,
    // 中断个数，最大为248个
    parameter                       P_IRQ_COUNT     = 32
)
(
    input                           clk,
    input                           reset_n,

    // 操作总线
    input                           icb_cmd_vld,
    output                          icb_cmd_rdy,
    input                           icb_cmd_write,
    input[15 : 0]                   icb_cmd_addr,
    input[31 : 0]                   icb_cmd_wdata,
    input[3 : 0]                    icb_cmd_wstrb,
    input[2 : 0]                    icb_cmd_size,
    input[1 : 0]                    icb_cmd_burst,
    input[P_LEN_WIDTH - 1 : 0]      icb_cmd_len,
    input[2 : 0]                    icb_cmd_prot,
    input[3 : 0]                    icb_cmd_cache,
    output                          icb_rsp_vld,
    input                           icb_rsp_rdy,
    output[31 : 0]                  icb_rsp_rdata,
    output                          icb_rsp_err,

    input                           irq_tmr,
    input                           irq_sft,

    // 中断源
    input[P_IRQ_COUNT - 1 : 0]      irq_src,

    // 输出到Core
    output                          clic_irq_req,
    input                           clic_irq_ack,
    output                          clic_irq_mode,
    output[7 : 0]                   clic_irq_id
);

localparam[12 : 0]                  LP_VLD_IRQ_COUNT = P_IRQ_COUNT + 8;

// 中断通道数只能是2^n个，最大支持256个
localparam                          LP_IRQ_CHANNEL =    (P_IRQ_COUNT > 128) ? 256 :
                                                        (P_IRQ_COUNT > 64) ? 128 :
                                                        (P_IRQ_COUNT > 32) ? 64 :
                                                        (P_IRQ_COUNT > 16) ? 32 :
                                                        (P_IRQ_COUNT > 8) ? 16 :
                                                        8;

localparam                          LP_CLIC_CFG_ADDR        = 16'h0000;
localparam                          LP_CLIC_INFO_ADDR       = 16'h0004;
localparam                          LP_CLIC_MTH_ADDR        = 16'h0008;
localparam                          LP_CLIC_IRQn_BASE_ADDR  = 16'h1000;

wire                                clic_irq_hsked;

wire                                icb_cmd_hsked;
wire                                icb_rsp_hsked;
wire                                icb_write_access;
wire                                icb_read_access;

wire                                access_addr_CLIC_CFG;
wire                                access_addr_CLIC_INFO;
wire                                access_addr_CLIC_MTH;
wire[LP_VLD_IRQ_COUNT - 1 : 0]      access_addr_CLIC_IRQn;

wire                                write_CLIC_MTH;


reg[31 : 0]                         rdata_q;
wire                                rdata_rld;
wire[31 : 0]                        rdata_d;

reg                                 rsp_vld_q;
wire                                rsp_vld_set;
wire                                rsp_vld_clr;
wire                                rsp_vld_rld;
wire                                rsp_vld_d;

reg[7 : 0]                          clic_mth_q;
wire                                clic_mth_rld;
wire[7 : 0]                         clic_mth_d;

wire[31 : 0]                        clic_cfg_full;
wire[31 : 0]                        clic_info_full;
wire[31 : 0]                        clic_mth_full;
reg[31 : 0]                         clic_irqn_full;

wire[31 : 0]                        irqn_reg_full[LP_IRQ_CHANNEL - 1 : 0];
wire[LP_IRQ_CHANNEL - 1 : 0]        irqn_ip;
wire[1 : 0]                         irqn_level[LP_IRQ_CHANNEL - 1 : 0];
wire[1 : 0]                         irqn_pri[LP_IRQ_CHANNEL - 1 : 0];
wire[LP_IRQ_CHANNEL - 1 : 0]        irqn_shv;


wire[4 : 0]                         irqn_pri_lvl7[127 : 0];
wire[7 : 0]                         irqn_id_lvl7[127 : 0];

wire[4 : 0]                         irqn_pri_lvl6[63 : 0];
wire[7 : 0]                         irqn_id_lvl6[63 : 0];

wire[4 : 0]                         irqn_pri_lvl5[31 : 0];
wire[7 : 0]                         irqn_id_lvl5[31 : 0];

wire[4 : 0]                         irqn_pri_lvl4[15 : 0];
wire[7 : 0]                         irqn_id_lvl4[15 : 0];

wire[4 : 0]                         irqn_pri_lvl3[7 : 0];
wire[7 : 0]                         irqn_id_lvl3[7 : 0];
wire[3 : 0]                         irqn_win_lvl3;

wire[4 : 0]                         irqn_pri_lvl2[3 : 0];
wire[7 : 0]                         irqn_id_lvl2[3 : 0];
wire[1 : 0]                         irqn_win_lvl2;

wire[4 : 0]                         irqn_pri_lvl1[1 : 0];
wire[7 : 0]                         irqn_id_lvl1[1 : 0];
wire                                irqn_win_lvl1;

wire[4 : 0]                         irqn_pri_lvl0;
wire[7 : 0]                         irqn_id_lvl0;

reg                                 clic_irq_req_q;
wire                                clic_irq_req_set;
wire                                clic_irq_req_clr;
wire                                clic_irq_req_rld;
wire                                clic_irq_req_d;

reg[7 : 0]                          clic_irq_id_q;
wire                                clic_irq_id_rld;
wire[7 : 0]                         clic_irq_id_d;

reg                                 clic_irq_mode_q;
wire                                clic_irq_mode_rld;
wire                                clic_irq_mode_d;

wire                                unused;

genvar                              i;
integer                             j;

assign      clic_irq_hsked = clic_irq_req & clic_irq_ack;

assign      icb_cmd_hsked = icb_cmd_vld & icb_cmd_rdy;
assign      icb_rsp_hsked = icb_rsp_vld & icb_rsp_rdy;

assign      icb_write_access = icb_cmd_hsked & icb_cmd_write;
assign      icb_read_access = icb_cmd_hsked & (~icb_cmd_write);

assign      access_addr_CLIC_CFG = (icb_cmd_addr[15 : 0] == LP_CLIC_CFG_ADDR);
assign      access_addr_CLIC_INFO = (icb_cmd_addr[15 : 0] == LP_CLIC_INFO_ADDR);
assign      access_addr_CLIC_MTH = (icb_cmd_addr[15 : 0] == LP_CLIC_MTH_ADDR);

assign      write_CLIC_MTH = icb_write_access & access_addr_CLIC_MTH & icb_cmd_wstrb[3];

generate
    for(i = 0; i < LP_VLD_IRQ_COUNT; i = i + 1) begin
        assign      access_addr_CLIC_IRQn[i] = (icb_cmd_addr[15 : 0] == (LP_CLIC_IRQn_BASE_ADDR + (4 * i)));
    end
endgenerate


// 定时器中断
lnrv_clic_irqn#
(
    .P_IRQ_ID           ( 3                     )
)
u_lnrv_clic_irq_tmr
(
    .clk                ( clk                   ),
    .reset_n            ( reset_n               ),

    .irq                ( irq_tmr               ),

    .icb_write_access   ( icb_write_access      ),
    .icb_cmd_addr       ( icb_cmd_addr          ),
    .icb_cmd_wdata      ( icb_cmd_wdata         ),
    .icb_cmd_wstrb      ( icb_cmd_wstrb         ),

    .irq_reg_full       ( irqn_reg_full[3]      ),

    .ip_clr_hw          ( clic_irq_hsked        ),
    .ip_clr_id_hw       ( clic_irq_id           )
);

// 软件中断
lnrv_clic_irqn#
(
    .P_IRQ_ID           ( 7                     )
)
u_lnrv_clic_irq_sft
(
    .clk                ( clk                   ),
    .reset_n            ( reset_n               ),

    .irq                ( irq_tmr               ),

    .icb_write_access   ( icb_write_access      ),
    .icb_cmd_addr       ( icb_cmd_addr          ),
    .icb_cmd_wdata      ( icb_cmd_wdata         ),
    .icb_cmd_wstrb      ( icb_cmd_wstrb         ),

    .irq_reg_full       ( irqn_reg_full[7]      ),

    .ip_clr_hw          ( clic_irq_hsked        ),
    .ip_clr_id_hw       ( clic_irq_id           )
);

// 没有使用的中断通道
assign      irqn_reg_full[0] = {8'hff, 2'd3, 6'd0, 8'd0, 8'd0};
assign      irqn_reg_full[1] = {8'hff, 2'd3, 6'd0, 8'd0, 8'd0};
assign      irqn_reg_full[2] = {8'hff, 2'd3, 6'd0, 8'd0, 8'd0};
assign      irqn_reg_full[4] = {8'hff, 2'd3, 6'd0, 8'd0, 8'd0};
assign      irqn_reg_full[5] = {8'hff, 2'd3, 6'd0, 8'd0, 8'd0};
assign      irqn_reg_full[6] = {8'hff, 2'd3, 6'd0, 8'd0, 8'd0};

generate
    for(i = 8; i < P_IRQ_COUNT; i = i + 1) begin: GEN_IRQN
        lnrv_clic_irqn#
        (
            .P_IRQ_ID           ( i                     )
        )
        u_lnrv_clic_irqn
        (
            .clk                ( clk                   ),
            .reset_n            ( reset_n               ),

            .irq                ( irq_src[i - 8]        ),

            .icb_write_access   ( icb_write_access      ),
            .icb_cmd_addr       ( icb_cmd_addr          ),
            .icb_cmd_wdata      ( icb_cmd_wdata         ),
            .icb_cmd_wstrb      ( icb_cmd_wstrb         ),

            .irq_reg_full       ( irqn_reg_full[i]      ),

            .ip_clr_hw          ( clic_irq_hsked        ),
            .ip_clr_id_hw       ( clic_irq_id           )
        );
    end

    // 对于没有使用的通道，直接tie0处理
    for(i = LP_VLD_IRQ_COUNT; i < LP_IRQ_CHANNEL; i = i + 1) begin: UNUSED_CHANNEL
        assign      irqn_reg_full[i] = {8'hff, 2'd3, 6'd0, 8'd0, 8'd0};
    end

    for(i = 0; i < LP_IRQ_CHANNEL; i = i + 1) begin
        assign      irqn_level[i]   = irqn_reg_full[i][31 : 30];
        assign      irqn_pri[i]     = irqn_reg_full[i][29 : 28];
        assign      irqn_shv[i]     = irqn_reg_full[i][16];
        assign      irqn_ip[i]      = irqn_reg_full[i][0] & irqn_reg_full[i][8];
    end
endgenerate

// 仲裁逻辑
generate
    // 第7级仲裁
    if(LP_IRQ_CHANNEL == 256) begin: GEN_IRQN_ARBT_LVL7
        wire[127 : 0]           irqn_win_lvl8;
        wire[4 : 0]             irqn_pri_lvl8[255 : 0];
        wire[7 : 0]             irqn_id_lvl8[255 : 0];

        for(i = 0; i < 256; i = i + 1) begin
            assign      irqn_pri_lvl8[i]    = {irqn_ip[i], irqn_level[i], irqn_pri[i]};
            assign      irqn_id_lvl8[i]     = i[7 : 0];
        end

        for(i = 0; i < 128; i = i + 1) begin
            assign      irqn_win_lvl8[i]    = irqn_pri_lvl8[(2 * i) + 1] > irqn_pri_lvl8[(2 * i)];
            assign      irqn_id_lvl7[i]     = irqn_win_lvl8[i] ? irqn_id_lvl8[(2 * i) + 1] : irqn_id_lvl8[(2 * i)];
            assign      irqn_pri_lvl7[i]    = irqn_win_lvl8[i] ? irqn_pri_lvl8[(2 * i) + 1] : irqn_pri_lvl8[(2 * i)];
        end
    end

    // 第6级仲裁
    if(P_IRQ_COUNT > 64) begin: IRQN_ARBT_LVL6
        wire[63 : 0]            irqn_win_lvl7;

        if(P_IRQ_COUNT <= 128) begin
            for(i = 0; i < 128; i = i + 1) begin
                assign      irqn_id_lvl7[i]     = {irqn_ip[i], irqn_level[i], irqn_pri[i]};
                assign      irqn_pri_lvl7[i]    = i[7 : 0];
            end
        end

        for(i = 0; i < 64; i = i + 1) begin
            assign      irqn_win_lvl7[i]    = irqn_pri_lvl7[(2 * i) + 1] > irqn_pri_lvl7[(2 * i)];
            assign      irqn_id_lvl6[i]     = irqn_win_lvl7[i] ? irqn_id_lvl7[(2 * i) + 1] : irqn_id_lvl7[(2 * i)];
            assign      irqn_pri_lvl6[i]    = irqn_win_lvl7[i] ? irqn_pri_lvl7[(2 * i) + 1] : irqn_pri_lvl7[(2 * i)];
        end
    end else begin
        for(i = 0; i < 128; i = i + 1) begin
            assign      irqn_pri_lvl7[i]     = {1'b0, 2'b00, 2'b00};
            assign      irqn_id_lvl7[i]    = 8'd0;
        end
    end

    // 第5级仲裁
    if(P_IRQ_COUNT > 32) begin: IRQN_ARBT_LVL5
        wire[31 : 0]            irqn_win_lvl6;

        if(P_IRQ_COUNT <= 64) begin
            for(i = 0; i < 64; i = i + 1) begin
                assign      irqn_pri_lvl6[i]    = {irqn_ip[i], irqn_level[i], irqn_pri[i]};
                assign      irqn_id_lvl6[i]     = i[7 : 0];
            end
        end

        for(i = 0; i < 32; i = i + 1) begin
            assign      irqn_win_lvl6[i]    = irqn_pri_lvl6[(2 * i) + 1] > irqn_pri_lvl6[(2 * i)];
            assign      irqn_id_lvl5[i]     = irqn_win_lvl6[i] ? irqn_id_lvl6[(2 * i) + 1] : irqn_id_lvl6[(2 * i)];
            assign      irqn_pri_lvl5[i]    = irqn_win_lvl6[i] ? irqn_pri_lvl6[(2 * i) + 1] : irqn_pri_lvl6[(2 * i)];
        end
    end else begin
        for(i = 0; i < 64; i = i + 1) begin
            assign      irqn_id_lvl6[i]     = 8'd0;
            assign      irqn_pri_lvl6[i]    = {1'b0, 2'b00, 2'b00};
        end
    end

    // 第4级仲裁
    if(P_IRQ_COUNT > 16) begin: IRQN_ARBT_LVL4
        wire[15 : 0]            irqn_win_lvl5;

        if(P_IRQ_COUNT <= 32) begin
            for(i = 0; i < 32; i = i + 1) begin
                assign      irqn_pri_lvl5[i]     = {irqn_ip[i], irqn_level[i], irqn_pri[i]};
                assign      irqn_id_lvl5[i]    = i[7 : 0];
            end
        end

        for(i = 0; i < 16; i = i + 1) begin
            assign      irqn_win_lvl5[i]    = irqn_pri_lvl5[(2 * i) + 1] > irqn_pri_lvl5[(2 * i)];
            assign      irqn_id_lvl4[i]     = irqn_win_lvl5[i] ? irqn_id_lvl5[(2 * i) + 1] : irqn_id_lvl5[(2 * i)];
            assign      irqn_pri_lvl4[i]    = irqn_win_lvl5[i] ? irqn_pri_lvl5[(2 * i) + 1] : irqn_pri_lvl5[(2 * i)];
        end
    end else begin
        for(i = 0; i < 32; i = i + 1) begin
            assign      irqn_id_lvl5[i]     = 8'd0;
            assign      irqn_pri_lvl5[i]    = {1'b0, 2'b00, 2'b00};
        end
    end

    // 第3级仲裁
    if(P_IRQ_COUNT > 8) begin: IRQN_ARBT_LVL3
        wire[7 : 0]            irqn_win_lvl4;

        if(P_IRQ_COUNT <= 16) begin
            for(i = 0; i < 16; i = i + 1) begin
                assign      irqn_pri_lvl4[i]    = {irqn_ip[i], irqn_level[i], irqn_pri[i]};
                assign      irqn_id_lvl4[i]     = i[7 : 0];
            end
        end

        for(i = 0; i < 8; i = i + 1) begin
            assign      irqn_win_lvl4[i]    = irqn_pri_lvl4[(2 * i) + 1] > irqn_pri_lvl4[(2 * i)];
            assign      irqn_id_lvl3[i]     = irqn_win_lvl4[i] ? irqn_id_lvl4[(2 * i) + 1] : irqn_id_lvl4[(2 * i)];
            assign      irqn_pri_lvl3[i]    = irqn_win_lvl4[i] ? irqn_pri_lvl4[(2 * i) + 1] : irqn_pri_lvl4[(2 * i)];
        end
    end else begin
        for(i = 0; i < 16; i = i + 1) begin
            assign      irqn_id_lvl4[i]     = 8'd0;
            assign      irqn_pri_lvl4[i]    = {1'b0, 2'b00, 2'b00};
        end
    end
endgenerate

// 因为我们内部还保留了8个中断，因此第2/1/0级仲裁肯定有
generate
    if(P_IRQ_COUNT <= 8) begin
        for(i = 0; i < 8; i = i + 1) begin
            assign      irqn_pri_lvl3[i]    = {irqn_ip[i], irqn_level[i], irqn_pri[i]};
            assign      irqn_id_lvl3[i]     = i[7 : 0];
        end
    end

    // 第2级仲裁
    for(i = 0; i < 4; i = i + 1) begin: IRQN_ARBT_LVL2
        assign      irqn_win_lvl3[i]    = irqn_pri_lvl3[(2 * i) + 1] > irqn_pri_lvl3[(2 * i)];
        assign      irqn_id_lvl2[i]     = irqn_win_lvl3[i] ? irqn_id_lvl3[(2 * i) + 1] : irqn_id_lvl3[(2 * i)];
        assign      irqn_pri_lvl2[i]    = irqn_win_lvl3[i] ? irqn_pri_lvl3[(2 * i) + 1] : irqn_pri_lvl3[(2 * i)];
    end

    for(i = 0; i < 2; i = i + 1) begin: IRQN_ARBT_LVL1
        assign      irqn_win_lvl2[i]    = irqn_pri_lvl2[(2 * i) + 1] > irqn_pri_lvl2[(2 * i)];
        assign      irqn_id_lvl1[i]     = irqn_win_lvl2[i] ? irqn_id_lvl2[(2 * i) + 1] : irqn_id_lvl2[(2 * i)];
        assign      irqn_pri_lvl1[i]    = irqn_win_lvl2[i] ? irqn_pri_lvl2[(2 * i) + 1] : irqn_pri_lvl2[(2 * i)];
    end

    assign      irqn_win_lvl1    = irqn_pri_lvl1[1] > irqn_pri_lvl1[0];
    assign      irqn_id_lvl0     = irqn_win_lvl1 ? irqn_id_lvl1[1] : irqn_id_lvl1[0];
    assign      irqn_pri_lvl0    = irqn_win_lvl1 ? irqn_pri_lvl1[1] : irqn_pri_lvl1[0];
endgenerate

assign      clic_irq_req_set = (~clic_irq_req) & irqn_pri_lvl0[4] & ({irqn_pri_lvl0[3 : 0], 4'b1111} > clic_mth_q);
assign      clic_irq_req_clr = clic_irq_hsked;
assign      clic_irq_req_rld = clic_irq_req_set | clic_irq_req_clr;
assign      clic_irq_req_d = clic_irq_req_set;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        clic_irq_req_q <= 1'b0;
    end else if(clic_irq_req_rld) begin
        clic_irq_req_q <= clic_irq_req_d;
    end
end

assign      clic_irq_id_rld = clic_irq_req_set;
assign      clic_irq_id_d = irqn_id_lvl0;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        clic_irq_id_q <= 8'b0;
    end else if(clic_irq_id_rld) begin
        clic_irq_id_q <= clic_irq_id_d;
    end
end

assign      clic_irq_mode_rld = clic_irq_req_set;
assign      clic_irq_mode_d = irqn_shv[irqn_id_lvl0];
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        clic_irq_mode_q <= 1'b0;
    end else if(clic_irq_mode_rld) begin
        clic_irq_mode_q <=clic_irq_mode_d;
    end
end

assign      clic_mth_rld = write_CLIC_MTH;
assign      clic_mth_d = icb_cmd_wdata[31 : 24];
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        clic_mth_q <= 8'd0;
    end else if(clic_mth_rld) begin
        clic_mth_q <= clic_mth_d;
    end
end

// 寄存器读接口
assign      clic_cfg_full = 32'd0;
assign      clic_info_full = {11'd0, 8'd1, LP_VLD_IRQ_COUNT[12 : 0]};
assign      clic_mth_full = {clic_mth_q, 24'd0};

always@(*) begin
    clic_irqn_full = 32'd0;

    for(j = 0; j < LP_VLD_IRQ_COUNT; j = j + 1) begin
        clic_irqn_full = clic_irqn_full | ({32{access_addr_CLIC_IRQn[j]}} & irqn_reg_full[j]);
    end
end

assign      rdata_rld = icb_read_access;
assign      rdata_d =   ({32{access_addr_CLIC_INFO}} & clic_info_full) |
                        ({32{access_addr_CLIC_MTH}} & clic_mth_full) |
                        ({32{access_addr_CLIC_CFG}} & clic_cfg_full) |
                        clic_irqn_full;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        rdata_q <= 32'd0;
    end else if(rdata_rld) begin
        rdata_q <= rdata_d;
    end
end

assign      rsp_vld_set = icb_cmd_hsked;
assign      rsp_vld_clr = icb_rsp_hsked;
assign      rsp_vld_rld = rsp_vld_set ^ rsp_vld_clr;
assign      rsp_vld_d = rsp_vld_set;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        rsp_vld_q <= 1'b0;
    end else if(rsp_vld_rld) begin
        rsp_vld_q <= rsp_vld_d;
    end
end



assign      clic_irq_req    = clic_irq_req_q;
assign      clic_irq_id     = clic_irq_id_q;
assign      clic_irq_mode   = clic_irq_mode_q;

assign      icb_rsp_vld     = rsp_vld_q;
assign      icb_rsp_rdata   = rdata_q;
assign      icb_rsp_err     = 1'b0;

assign      icb_cmd_rdy     = ~rsp_vld_q;

// 这些信号不会使用
assign      unused =    &{
                            icb_cmd_size,
                            icb_cmd_burst,
                            icb_cmd_len,
                            icb_cmd_prot,
                            icb_cmd_cache
                        };

endmodule