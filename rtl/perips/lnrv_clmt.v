module lnrv_clmt
(
    input                           clk,
    input                           reset_n,

    // 定时器工作时钟
    input                           tclk,
    input                           treset_n,

    // 定时器中断
    output                          irq_tmr,

    // 软件中断
    input                           irq_sft,

    // 在debug模式下停止定时器
    input                           dcsr_stoptime,

    // 寄存器访问接口
    input                           icb_cmd_vld,
    output                          icb_cmd_rdy,
    input                           icb_cmd_write,
    input[15 : 0]                   icb_cmd_addr,
    input[31 : 0]                   icb_cmd_wdata,
    input[3 : 0]                    icb_cmd_wstrb,
    input[2 : 0]                    icb_cmd_size,
    output                          icb_rsp_vld,
    input                           icb_rsp_rdy,
    output[31 : 0]                  icb_rsp_rdata,
    output                          icb_rsp_err
);

localparam              LP_MTIME_ENABLE_REG_ADDR    = 12'h000;
localparam              LP_MTIME_CTRL_REG_ADDR      = 12'h004;
localparam              LP_MTIME_CNT_LO_REG_ADDR    = 12'h008;
localparam              LP_MTIME_CNT_HI_REG_ADDR    = 12'h00c;
localparam              LP_MTIME_CMP_LO_REG_ADDR    = 12'h010;
localparam              LP_MTIME_CMP_HI_REG_ADDR    = 12'h014;
localparam              LP_MTIME_TIP_REG_ADDR       = 12'h018;
localparam              LP_MTIME_SIP_REG_ADDR       = 12'h01c;

reg                     tclk_toggle_q;
wire                    tclk_toggle_d;

wire                    tmr_toggle;
reg                     tmr_toggle_dly_q;
wire                    tmr_toggle_dly_d;
wire                    tmr_toggle_edge;

wire                    icb_cmd_hsked;
wire                    icb_rsp_hsked;
wire                    icb_write_access;
wire                    icb_read_access;
wire                    access_addr_legal;
wire                    access_addr_illegal;

wire                    access_addr_is_MTIME_CNT_HI;
wire                    access_addr_is_MTIME_CNT_LO;
wire                    access_addr_is_MTIME_CTRL;
wire                    access_addr_is_MTIME_CMP_HI;
wire                    access_addr_is_MTIME_CMP_LO;
wire                    access_addr_is_MTIME_ENABLE;
wire                    access_addr_is_MTIME_SIP;
wire                    access_addr_is_MTIME_TIP;

wire                    icb_write_MTIME_CMP_HI;
wire                    icb_write_MTIME_CMP_LO;
wire                    icb_write_MTIME_CTRL;
wire                    icb_write_MTIME_ENABLE;
wire                    icb_write_MTIME_SIP;
wire                    icb_write_MTIME_TIP;

reg[31 : 0]             rdata_q;
wire                    rdata_rld;
wire[31 : 0]            rdata_d;

reg                     slverr_q;
wire                    slverr_rld;
wire                    slverr_d;

reg                     rsp_vld_q;
wire                    rsp_vld_set;
wire                    rsp_vld_clr;
wire                    rsp_vld_rld;
wire                    rsp_vld_d;


reg[31 : 0]             mtime_cnt_hi_q;
wire[31 : 0]            mtime_cnt_hi_d;
reg[31 : 0]             mtime_cnt_lo_q;
wire[31 : 0]            mtime_cnt_lo_d;
wire                    mtime_cnt_clr;
wire                    mtime_cnt_inc;
wire                    mtime_cnt_rld;
wire[63 : 0]            mtime_cnt;

reg[31 : 0]             mtime_cmp_hi_q;
wire                    mtime_cmp_hi_rld;
wire[31 : 0]            mtime_cmp_hi_d;
reg[31 : 0]             mtime_cmp_lo_q;
wire                    mtime_cmp_lo_rld;
wire[31 : 0]            mtime_cmp_lo_d;
wire[63 : 0]            mtime_cmp;

reg                     mtime_enable_q;
wire                    mtime_enable_rld;
wire                    mtime_enable_d;

reg                     mtime_mode_q;
wire                    mtime_mode_rld;
wire                    mtime_mode_d;

reg                     mtime_clk_src_q;
wire                    mtime_clk_src_rld;
wire                    mtime_clk_src_d;

reg                     mtime_tip_q;
wire                    mtime_tip_set;
wire                    mtime_tip_clr;
wire                    mtime_tip_rld;
wire                    mtime_tip_d;

reg                     mtime_sip_q;
wire                    mtime_sip_rld;
wire                    mtime_sip_d;

wire[31 : 0]            mtime_cnt_hi_full;
wire[31 : 0]            mtime_cnt_lo_full;
wire[31 : 0]            mtime_cmp_hi_full;
wire[31 : 0]            mtime_cmp_lo_full;
wire[31 : 0]            mtime_ctrl_full;
wire[31 : 0]            mtime_tip_full;
wire[31 : 0]            mtime_sip_full;
wire[31 : 0]            mtime_enable_full;

wire                    mtime_count_enable;
wire                    mtime_cnt_gt_mtime_cmp;
wire                    mtime_cnt_eq_mtime_cmp;
wire                    mtime_cnt_gte_mtime_cmp;

assign      tclk_toggle_d = ~tclk_toggle_q;
always@(posedge tclk or negedge treset_n) begin
    if(treset_n == 1'b0) begin
        tclk_toggle_q <= 1'b0;
    end else begin
        tclk_toggle_q <= tclk_toggle_d;
    end
end

lnrv_gnrl_dat_sync#
(
    .P_SYNC_STAGE       ( 2                     ),
    .P_DATA_WIDTH       ( 1                     ),
    .P_RESET_VALUE      ( 1'b0                  )
)
u_lnrv_gnrl_dat_sync
(
    .async_data         ( tclk_toggle_q         ),

    .sync_clk           ( clk                  ),
    .sync_rst_n         ( preset_n              ),
    .sync_data          ( tmr_toggle            )
);


assign      tmr_toggle_dly_d = tmr_toggle;
always@(posedge clk or negedge preset_n) begin
    if(preset_n == 1'b0) begin
        tmr_toggle_dly_q <= 1'b0;
    end else begin
        tmr_toggle_dly_q <= tmr_toggle_dly_d;
    end
end

// 获取tclk的双边沿
assign      tmr_toggle_edge = tmr_toggle_dly_q ^ tmr_toggle_dly_d;

assign      mtime_count_enable = tmr_toggle_edge | mtime_clk_src_q;
assign      mtime_cnt_inc = mtime_enable_q & (~dcsr_stoptime) & mtime_count_enable;

// 如果是自动清零模式，则会在mtime_cnt == mtime_cmp时将mtime_cnt复位，从0开始计数
assign      mtime_cnt_clr = mtime_mode_q & mtime_cnt_eq_mtime_cmp & mtime_count_enable;
assign      mtime_cnt_rld = mtime_cnt_inc | mtime_cnt_clr;
assign      {mtime_cnt_hi_d, mtime_cnt_lo_d} =  mtime_cnt_clr ? 64'd0 :
                                                {mtime_cnt_hi_q, mtime_cnt_lo_q} + 1'b1;
always@(posedge clk or negedge preset_n) begin
    if(preset_n == 1'b0) begin
        {mtime_cnt_hi_q, mtime_cnt_lo_q} <= 64'd0;
    end else if(mtime_cnt_rld) begin
        {mtime_cnt_hi_q, mtime_cnt_lo_q} <= {mtime_cnt_hi_d, mtime_cnt_lo_d};
    end
end

assign      mtime_cnt = {mtime_cnt_hi_q, mtime_cnt_lo_q};

// 比较值寄存器
assign      mtime_cmp_hi_rld = icb_write_MTIME_CMP_HI;
assign      mtime_cmp_hi_d = icb_cmd_wdata;
always@(posedge clk or negedge preset_n) begin
    if(preset_n == 1'b0) begin
        mtime_cmp_hi_q <= 32'd0;
    end else if(mtime_cmp_hi_rld) begin
        mtime_cmp_hi_q <= mtime_cmp_hi_d;
    end
end

assign      mtime_cmp_lo_rld = icb_write_MTIME_CMP_LO;
assign      mtime_cmp_lo_d = icb_cmd_wdata;
always@(posedge clk or negedge preset_n) begin
    if(preset_n == 1'b0) begin
        mtime_cmp_lo_q <= 32'd0;
    end else if(mtime_cmp_lo_rld) begin
        mtime_cmp_lo_q <= mtime_cmp_lo_d;
    end
end

assign      mtime_cmp = {mtime_cmp_hi_q, mtime_cmp_lo_q};

// 使能寄存器
assign      mtime_enable_rld = icb_write_MTIME_ENABLE;
assign      mtime_enable_d = icb_cmd_wdata[0];
always@(posedge clk or negedge preset_n) begin
    if(preset_n == 1'b0) begin
        mtime_enable_q <= 1'b0;
    end else if(mtime_enable_rld) begin
        mtime_enable_q <= mtime_enable_d;
    end
end


// 模式寄存器
assign      mtime_mode_rld = icb_write_MTIME_CTRL;
assign      mtime_mode_d = icb_cmd_wdata[0];
always@(posedge clk or negedge preset_n) begin
    if(preset_n == 1'b0) begin
        mtime_mode_q <= 1'b0;
    end else if(mtime_mode_rld) begin
        mtime_mode_q <= mtime_mode_d;
    end
end

// 时钟源寄存器
assign      mtime_clk_src_rld = icb_write_MTIME_CTRL;
assign      mtime_clk_src_d = icb_cmd_wdata[4];
always@(posedge clk or negedge preset_n) begin
    if(preset_n == 1'b0) begin
        mtime_clk_src_q <= 1'b0;
    end else if(mtime_clk_src_rld) begin
        mtime_clk_src_q <= mtime_clk_src_d;
    end
end

assign      mtime_cnt_gt_mtime_cmp = (mtime_cnt > mtime_cmp);
assign      mtime_cnt_eq_mtime_cmp = (mtime_cnt == mtime_cmp);
assign      mtime_cnt_gte_mtime_cmp = mtime_cnt_gt_mtime_cmp | mtime_cnt_eq_mtime_cmp;

// timer中断
assign      mtime_tip_set = mtime_enable_q &
                            (
                                // 如果是自动归零模式，则只会在计数值与比较值相等时置位中断
                                mtime_mode_q ? (mtime_cnt_eq_mtime_cmp & mtime_count_enable) :
                                // 否则只要计数值大于等于比较值，就置位中断
                                mtime_cnt_gt_mtime_cmp
                            );
assign      mtime_tip_clr = icb_write_MTIME_TIP & (~icb_cmd_wdata[0]);
assign      mtime_tip_rld = mtime_tip_set | mtime_tip_clr;
assign      mtime_tip_d = mtime_tip_set;
always@(posedge clk or negedge preset_n) begin
    if(preset_n == 1'b0) begin
        mtime_tip_q <= 1'b0;
    end else if(mtime_tip_rld) begin
        mtime_tip_q <= mtime_tip_d;
    end
end

// 软件中断
assign      mtime_sip_rld = icb_write_MTIME_SIP;
assign      mtime_sip_d = icb_cmd_wdata[0];
always@(posedge clk or negedge preset_n) begin
    if(preset_n == 1'b0) begin
        mtime_sip_q <= 1'b0;
    end else if(mtime_sip_rld) begin
        mtime_sip_q <= mtime_sip_d;
    end
end

assign      mtime_cnt_hi_full   = mtime_cnt_hi_q;
assign      mtime_cnt_lo_full   = mtime_cnt_lo_q;
assign      mtime_cmp_hi_full   = mtime_cmp_hi_q;
assign      mtime_cmp_lo_full   = mtime_cmp_lo_q;
assign      mtime_enable_full   = {31'd0, mtime_enable_q};
assign      mtime_ctrl_full     =   {
                                        24'd0,
                                        3'd0,
                                        mtime_clk_src_q,
                                        3'd0,
                                        mtime_mode_q
                                    };
assign      mtime_tip_full      = {31'd0, mtime_tip_q};
assign      mtime_sip_full      = {31'd0, mtime_sip_q};


assign      icb_cmd_hsked               = icb_cmd_vld & icb_cmd_rdy;
assign      icb_rsp_hsked               = icb_rsp_vld & icb_rsp_rdy;

assign      icb_write_access            = icb_cmd_hsked & icb_cmd_write;
assign      icb_read_access             = icb_cmd_hsked & (~icb_cmd_write);

assign      access_addr_is_MTIME_CMP_HI = (icb_cmd_addr[11 : 0] == LP_MTIME_CMP_HI_REG_ADDR);
assign      access_addr_is_MTIME_CMP_LO = (icb_cmd_addr[11 : 0] == LP_MTIME_CMP_LO_REG_ADDR);
assign      access_addr_is_MTIME_CNT_HI = (icb_cmd_addr[11 : 0] == LP_MTIME_CNT_HI_REG_ADDR);
assign      access_addr_is_MTIME_CNT_LO = (icb_cmd_addr[11 : 0] == LP_MTIME_CNT_LO_REG_ADDR);
assign      access_addr_is_MTIME_CTRL   = (icb_cmd_addr[11 : 0] == LP_MTIME_CTRL_REG_ADDR);
assign      access_addr_is_MTIME_ENABLE = (icb_cmd_addr[11 : 0] == LP_MTIME_ENABLE_REG_ADDR);
assign      access_addr_is_MTIME_SIP    = (icb_cmd_addr[11 : 0] == LP_MTIME_SIP_REG_ADDR);
assign      access_addr_is_MTIME_TIP    = (icb_cmd_addr[11 : 0] == LP_MTIME_TIP_REG_ADDR);

assign      icb_write_MTIME_CTRL        = icb_write_access & access_addr_is_MTIME_CTRL;
assign      icb_write_MTIME_SIP         = icb_write_access & access_addr_is_MTIME_SIP;
assign      icb_write_MTIME_TIP         = icb_write_access & access_addr_is_MTIME_TIP;
assign      icb_write_MTIME_CMP_HI      = icb_write_access & access_addr_is_MTIME_CMP_HI;
assign      icb_write_MTIME_CMP_LO      = icb_write_access & access_addr_is_MTIME_CMP_LO;
assign      icb_write_MTIME_ENABLE      = icb_write_access & access_addr_is_MTIME_ENABLE;

assign      access_addr_illegal         = ~access_addr_legal;
assign      access_addr_legal           =   access_addr_is_MTIME_CMP_HI |
                                            access_addr_is_MTIME_CMP_LO |
                                            access_addr_is_MTIME_CNT_HI |
                                            access_addr_is_MTIME_CNT_LO |
                                            access_addr_is_MTIME_CTRL |
                                            access_addr_is_MTIME_ENABLE |
                                            access_addr_is_MTIME_SIP |
                                            access_addr_is_MTIME_TIP |
                                            1'b0;

// 读数据
assign      rdata_rld = icb_read_access;
assign      rdata_d =   ({32{access_addr_is_MTIME_ENABLE}}  & mtime_enable_full) |
                        ({32{access_addr_is_MTIME_CTRL}}    & mtime_ctrl_full) |
                        ({32{access_addr_is_MTIME_SIP}}     & mtime_sip_full) |
                        ({32{access_addr_is_MTIME_TIP}}     & mtime_tip_full) |
                        ({32{access_addr_is_MTIME_CNT_LO}}  & mtime_cnt_lo_full) |
                        ({32{access_addr_is_MTIME_CNT_HI}}  & mtime_cnt_hi_full) |
                        ({32{access_addr_is_MTIME_CMP_LO}}  & mtime_cmp_lo_full) |
                        ({32{access_addr_is_MTIME_CMP_HI}}  & mtime_cmp_hi_full) |
                        32'd0;
always@(posedge clk or negedge preset_n) begin
    if(preset_n == 1'b0) begin
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

assign      slverr_rld = icb_cmd_hsked;
assign      slverr_d = access_addr_illegal;
always@(posedge clk or negedge preset_n) begin
    if(preset_n == 1'b0) begin
        slverr_q <= 1'b0;
    end else if(slverr_rld) begin
        slverr_q <= slverr_d;
    end
end


assign      irq_tmr = mtime_tip_q;
assign      irq_sft = mtime_sip_q;


assign      icb_cmd_rdy = ~rsp_vld_q;

assign      icb_rsp_vld = rsp_vld_q;
assign      icb_rsp_rdata = rdata_q;
assign      icb_rsp_err = slverr_q;

endmodule