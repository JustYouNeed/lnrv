module lnrv_plmt
(
    // 定时器中断
    output                              irq_tmr,

    // 软件中断
    input                               irq_sft,

    input                               dcsr_stoptime,

    // 寄存器访问接口
    input                               pclk,
    input                               preset_n,
    input                               psel,
    input                               penable,
    input                               pwrite,
    input[11 : 0]                       paddr,
    input[31 : 0]                       pwdata,
    output[31 : 0]                      prdata,
    output                              pslverr,
    output                              pready,

    input                               tclk,
    input                               treset_n
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

wire                    apb_write_access;
wire                    apb_read_access;
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

wire                    apb_write_MTIME_CMP_HI;
wire                    apb_write_MTIME_CMP_LO;
wire                    apb_write_MTIME_CTRL;
wire                    apb_write_MTIME_ENABLE;
wire                    apb_write_MTIME_SIP;
wire                    apb_write_MTIME_TIP;

reg[31 : 0]             apb_rdata_q;
wire                    apb_rdata_rld;
wire[31 : 0]            apb_rdata_d;

reg                     apb_slverr_q;
wire                    apb_slverr_rld;
wire                    apb_slverr_d;


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

    .sync_clk           ( pclk                  ),
    .sync_rst_n         ( preset_n              ),
    .sync_data          ( tmr_toggle            )
);


assign      tmr_toggle_dly_d = tmr_toggle;
always@(posedge pclk or negedge preset_n) begin
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
always@(posedge pclk or negedge preset_n) begin
    if(preset_n == 1'b0) begin
        {mtime_cnt_hi_q, mtime_cnt_lo_q} <= 64'd0;
    end else if(mtime_cnt_rld) begin
        {mtime_cnt_hi_q, mtime_cnt_lo_q} <= {mtime_cnt_hi_d, mtime_cnt_lo_d};
    end
end

assign      mtime_cnt = {mtime_cnt_hi_q, mtime_cnt_lo_q};

// 比较值寄存器
assign      mtime_cmp_hi_rld = apb_write_MTIME_CMP_HI;
assign      mtime_cmp_hi_d = pwdata;
always@(posedge pclk or negedge preset_n) begin
    if(preset_n == 1'b0) begin
        mtime_cmp_hi_q <= 32'd0;
    end else if(mtime_cmp_hi_rld) begin
        mtime_cmp_hi_q <= mtime_cmp_hi_d;
    end
end

assign      mtime_cmp_lo_rld = apb_write_MTIME_CMP_LO;
assign      mtime_cmp_lo_d = pwdata;
always@(posedge pclk or negedge preset_n) begin
    if(preset_n == 1'b0) begin
        mtime_cmp_lo_q <= 32'd0;
    end else if(mtime_cmp_lo_rld) begin
        mtime_cmp_lo_q <= mtime_cmp_lo_d;
    end
end

assign      mtime_cmp = {mtime_cmp_hi_q, mtime_cmp_lo_q};

// 使能寄存器
assign      mtime_enable_rld = apb_write_MTIME_ENABLE;
assign      mtime_enable_d = pwdata[0];
always@(posedge pclk or negedge preset_n) begin
    if(preset_n == 1'b0) begin
        mtime_enable_q <= 1'b0;
    end else if(mtime_enable_rld) begin
        mtime_enable_q <= mtime_enable_d;
    end
end


// 模式寄存器
assign      mtime_mode_rld = apb_write_MTIME_CTRL;
assign      mtime_mode_d = pwdata[0];
always@(posedge pclk or negedge preset_n) begin
    if(preset_n == 1'b0) begin
        mtime_mode_q <= 1'b0;
    end else if(mtime_mode_rld) begin
        mtime_mode_q <= mtime_mode_d;
    end
end

// 时钟源寄存器
assign      mtime_clk_src_rld = apb_write_MTIME_CTRL;
assign      mtime_clk_src_d = pwdata[4];
always@(posedge pclk or negedge preset_n) begin
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
assign      mtime_tip_clr = apb_write_MTIME_TIP & (~pwdata[0]);
assign      mtime_tip_rld = mtime_tip_set | mtime_tip_clr;
assign      mtime_tip_d = mtime_tip_set;
always@(posedge pclk or negedge preset_n) begin
    if(preset_n == 1'b0) begin
        mtime_tip_q <= 1'b0;
    end else if(mtime_tip_rld) begin
        mtime_tip_q <= mtime_tip_d;
    end
end

// 软件中断
assign      mtime_sip_rld = apb_write_MTIME_SIP;
assign      mtime_sip_d = pwdata[0];
always@(posedge pclk or negedge preset_n) begin
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


assign      apb_write_access            = psel & penable & pwrite;
assign      apb_read_access             = psel & (~penable) & (~pwrite);

assign      access_addr_is_MTIME_CMP_HI = (paddr[11 : 0] == LP_MTIME_CMP_HI_REG_ADDR);
assign      access_addr_is_MTIME_CMP_LO = (paddr[11 : 0] == LP_MTIME_CMP_LO_REG_ADDR);
assign      access_addr_is_MTIME_CNT_HI = (paddr[11 : 0] == LP_MTIME_CNT_HI_REG_ADDR);
assign      access_addr_is_MTIME_CNT_LO = (paddr[11 : 0] == LP_MTIME_CNT_LO_REG_ADDR);
assign      access_addr_is_MTIME_CTRL   = (paddr[11 : 0] == LP_MTIME_CTRL_REG_ADDR);
assign      access_addr_is_MTIME_ENABLE = (paddr[11 : 0] == LP_MTIME_ENABLE_REG_ADDR);
assign      access_addr_is_MTIME_SIP    = (paddr[11 : 0] == LP_MTIME_SIP_REG_ADDR);
assign      access_addr_is_MTIME_TIP    = (paddr[11 : 0] == LP_MTIME_TIP_REG_ADDR);

assign      apb_write_MTIME_CTRL        = apb_write_access & access_addr_is_MTIME_CTRL;
assign      apb_write_MTIME_SIP         = apb_write_access & access_addr_is_MTIME_SIP;
assign      apb_write_MTIME_TIP         = apb_write_access & access_addr_is_MTIME_TIP;
assign      apb_write_MTIME_CMP_HI      = apb_write_access & access_addr_is_MTIME_CMP_HI;
assign      apb_write_MTIME_CMP_LO      = apb_write_access & access_addr_is_MTIME_CMP_LO;
assign      apb_write_MTIME_ENABLE      = apb_write_access & access_addr_is_MTIME_ENABLE;

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
assign      apb_rdata_rld = apb_read_access;
assign      apb_rdata_d =   ({32{access_addr_is_MTIME_ENABLE}}  & mtime_enable_full) |
                            ({32{access_addr_is_MTIME_CTRL}}    & mtime_ctrl_full) |
                            ({32{access_addr_is_MTIME_SIP}}     & mtime_sip_full) |
                            ({32{access_addr_is_MTIME_TIP}}     & mtime_tip_full) |
                            ({32{access_addr_is_MTIME_CNT_LO}}  & mtime_cnt_lo_full) |
                            ({32{access_addr_is_MTIME_CNT_HI}}  & mtime_cnt_hi_full) |
                            ({32{access_addr_is_MTIME_CMP_LO}}  & mtime_cmp_lo_full) |
                            ({32{access_addr_is_MTIME_CMP_HI}}  & mtime_cmp_hi_full) |
                            32'd0;
always@(posedge pclk or negedge preset_n) begin
    if(preset_n == 1'b0) begin
        apb_rdata_q <= 32'd0;
    end else if(apb_rdata_rld) begin
        apb_rdata_q <= apb_rdata_d;
    end
end

assign      apb_slverr_rld = psel & (~penable);
assign      apb_slverr_d = access_addr_illegal;
always@(posedge pclk or negedge preset_n) begin
    if(preset_n == 1'b0) begin
        apb_slverr_q <= 1'b0;
    end else if(apb_slverr_rld) begin
        apb_slverr_q <= apb_slverr_d;
    end
end


assign      irq_tmr = mtime_tip_q;
assign      irq_sft = mtime_sip_q;


// 接收所有操作
assign      pready  = 1'b1;
assign      pslverr = apb_slverr_q;
assign      prdata  = apb_rdata_q;

endmodule