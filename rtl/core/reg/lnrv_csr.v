module lnrv_csr
(
    output[31 : 0]                  mepc,
    output[31 : 0]                  mtvec,
    output[31 : 0]                  mtvt,
    output                          m_mode,

    // debug csr
    output                          dcsr_step,
    output                          dcsr_stepie,
    output                          dcsr_ebreakm,
    output                          dcsr_stoptime,
    output[31 : 0]                  dpc,
    output                          d_mode,

    // 中断输入
    input                           irq_sft,
    input                           irq_tmr,
    input                           irq_ext,

    // 中断使能
    output                          mie_msie,       // 机器模式软件中断使能
    output                          mie_mtie,       // 机器模式定时器中断使能
    output                          mie_meie,       // 机器模式外部中断使能
    output                          mstatus_mie,    // 机器模式全局中断使能

    input                           excp_taken,
    input                           irq_taken,
    input                           dbg_taken,
    input                           cmted_mret,
    input                           cmted_dret,

    input                           mepc_wen,
    input[31 : 0]                   mepc_wdata,

    input                           mcause_wen,
    input[31 : 0]                   mcause_wdata,

    input                           mtval_wen,
    input[31 : 0]                   mtval_wdata,

    input                           dpc_wen,
    input[31 : 0]                   dpc_wdata,

    input                           dcause_wen,
    input[2 : 0]                    dcause_wdata,

    // 非法访问
    // 当访问不存在的csr时
    // 在非debug mode下访问dcsr时
    output                          csr_idx_err,

    // 读写共用一个索引
    input[11 : 0]                   csr_idx,
    output[31 : 0]                  csr_rdata,

    // 写回接口
    input                           wbck_vld,
    output                          wbck_rdy,
    input[31 : 0]                   wbck_wdata,

    input                           clk,
    input                           reset_n
);



// Machine Information Registers Map
localparam[11 : 0]                  LP_MVENDORID_REG_ADDR   = 12'hf11;
localparam[11 : 0]                  LP_MARCHID_REG_ADDR     = 12'hf12;
localparam[11 : 0]                  LP_MIMPID_REG_ADDR      = 12'hf13;
localparam[11 : 0]                  LP_MHARTID_REG_ADDR     = 12'hf14;


// Machine Trap Setup Registers Map
localparam[11 : 0]                  LP_MSTATUS_REG_ADDR     = 12'h300;
localparam[11 : 0]                  LP_MISA_REG_ADDR        = 12'h301;
localparam[11 : 0]                  LP_MEDELEG_REG_ADDR     = 12'h302;
localparam[11 : 0]                  LP_MIDELEG_REG_ADDR     = 12'h303;
localparam[11 : 0]                  LP_MIE_REG_ADDR         = 12'h304;
localparam[11 : 0]                  LP_MTVEC_REG_ADDR       = 12'h305;
localparam[11 : 0]                  LP_MTVT_REG_ADDR        = 12'h307;
localparam[11 : 0]                  LP_MCOUNTEREN_REG_ADDR  = 12'h306;


// Machine Trap Handing Registers Map
localparam[11 : 0]                  LP_MSCRATCH_REG_ADDR    = 12'h340;
localparam[11 : 0]                  LP_MEPC_REG_ADDR        = 12'h341;
localparam[11 : 0]                  LP_MCAUSE_REG_ADDR      = 12'h342;
localparam[11 : 0]                  LP_MTVAL_REG_ADDR       = 12'h343;
localparam[11 : 0]                  LP_MIP_REG_ADDR         = 12'h344;


// Machine Counter/Timers
localparam[11 : 0]                  LP_MCYCLE_REG_ADDR      = 12'hb00;
localparam[11 : 0]                  LP_MINSTRET_REG_ADDR    = 12'hb02;
localparam[11 : 0]                  LP_MCYCLEH_REG_ADDR     = 12'hb80;
localparam[11 : 0]                  LP_MINSTRETH_REG_ADDR   = 12'hb82;


// Debug/Trace Registers Map
localparam[11 : 0]                  LP_TSELECT_REG_ADDR     = 12'h7a0;
localparam[11 : 0]                  LP_TDATA1_REG_ADDR      = 12'h7a1;
localparam[11 : 0]                  LP_TDATA2_REG_ADDR      = 12'h7a2;
localparam[11 : 0]                  LP_TDATA3_REG_ADDR      = 12'h7a3;


// Debug Mode Registers
localparam[11 : 0]                  LP_DCSR_REG_ADDR        = 12'h7b0;
localparam[11 : 0]                  LP_DPC_REG_ADDR         = 12'h7b1;
localparam[11 : 0]                  LP_DSCRATCH0_REG_ADDR   = 12'h7b2;
localparam[11 : 0]                  LP_DSCRATCH1_REG_ADDR   = 12'h7b3;

wire                                csr_idx_is_MVENDORID;
wire                                csr_idx_is_MARCHID;
wire                                csr_idx_is_MIMPID;
wire                                csr_idx_is_MHARTID;
wire                                csr_idx_is_MSTATUS;
wire                                csr_idx_is_MISA;
wire                                csr_idx_is_MEDELEG;
wire                                csr_idx_is_MIDELEG;
wire                                csr_idx_is_MIE;
wire                                csr_idx_is_MTVEC;
wire                                csr_idx_is_MTVT;
wire                                csr_idx_is_MCOUNTEREN;
wire                                csr_idx_is_MSCRATCH;
wire                                csr_idx_is_MEPC;
wire                                csr_idx_is_MCAUSE;
wire                                csr_idx_is_MTVAL;
wire                                csr_idx_is_MIP;
wire                                csr_idx_is_MCYCLE;
wire                                csr_idx_is_MINSTRET;
wire                                csr_idx_is_MCYCLEH;
wire                                csr_idx_is_MINSTRETH;
wire                                csr_idx_is_TSELECT;
wire                                csr_idx_is_TDATA1;
wire                                csr_idx_is_TDATA2;
wire                                csr_idx_is_TDATA3;
wire                                csr_idx_is_DCSR;
wire                                csr_idx_is_DPC;
wire                                csr_idx_is_DSCRATCH0;
wire                                csr_idx_is_DSCRATCH1;

wire                                wbck_MVENDORID;
wire                                wbck_MARCHID;
wire                                wbck_MIMPID;
wire                                wbck_MHARTID;
wire                                wbck_MSTATUS;
wire                                wbck_MISA;
wire                                wbck_MEDELEG;
wire                                wbck_MIDELEG;
wire                                wbck_MIE;
wire                                wbck_MTVEC;
wire                                wbck_MTVT;
wire                                wbck_MCOUNTEREN;
wire                                wbck_MSCRATCH;
wire                                wbck_MEPC;
wire                                wbck_MCAUSE;
wire                                wbck_MTVAL;
wire                                wbck_MIP;
wire                                wbck_MCYCLE;
wire                                wbck_MINSTRET;
wire                                wbck_MCYCLEH;
wire                                wbck_MINSTRETH;
wire                                wbck_TSELECT;
wire                                wbck_TDATA1;
wire                                wbck_TDATA2;
wire                                wbck_TDATA3;
wire                                wbck_DCSR;
wire                                wbck_DPC;
wire                                wbck_DSCRATCH0;
wire                                wbck_DSCRATCH1;

wire                                mmode_access_legal;
wire                                mmode_access_ilgl;

wire                                dmode_access_legal;
wire                                dmode_access_ilgl;


reg                                 mstatus_mie_q;
wire                                mstatus_mie_rld;
wire                                mstatus_mie_d;

reg                                 mstatus_mpie_q;
wire                                mstatus_mpie_rld;
wire                                mstatus_mpie_d;

wire                                mstatus_rld;
wire[31 : 0]                        mstatus_full;

wire[31 : 0]                        misa_full;

wire[31 : 0]                        mimpid_full;

// Machine interrupt enable register
reg                                 mie_mtie_q;
wire                                mie_mtie_rld;
wire                                mie_mtie_d;

reg                                 mie_msie_q;
wire                                mie_msie_rld;
wire                                mie_msie_d;

reg                                 mie_meie_q;
wire                                mie_meie_rld;
wire                                mie_meie_d;

wire[31 : 0]                        mie_full;

reg[31 : 0]                         mtvec_q;
wire                                mtvec_rld;
wire[31 : 0]                        mtvec_d;

wire[31 : 0]                        mtvec_full;

reg[31 : 0]                         mtvt_q;
wire                                mtvt_rld;
wire[31 : 0]                        mtvt_d;

wire[31 : 0]                        mtvt_full;


reg[31 : 0]                         mscratch_q;
wire                                mscratch_rld;
wire[31 : 0]                        mscratch_d;

wire[31 : 0]                        mscratch_full;


reg[31 : 0]                         mepc_q;
wire                                mepc_rld;
wire[31 : 0]                        mepc_d;
wire[31 : 0]                        mepc_full;


reg[31 : 0]                         mcause_q;
wire                                mcause_rld;
wire[31 : 0]                        mcause_d;

wire[31 : 0]                        mcause_full;


reg[31 : 0]                         mtval_q;
wire                                mtval_rld;
wire[31 : 0]                        mtval_d;

wire[31 : 0]                        mtval_full;


// Machine interrupt pending register
reg                                 mtip_q;
wire                                mtip_d;

reg                                 msip_q;
wire                                msip_d;

reg                                 meip_q;
wire                                meip_d;

wire[31 : 0]                        mip_full;


reg[63 : 0]                         mcycle_q;
wire                                mcycle_rld;
wire[63 : 0]                        mcycle_d;

wire[31 : 0]                        mcycle_full;
wire[31 : 0]                        mcycleh_full;


reg[63 : 0]                         minstret_q;
wire                                minstret_rld;
wire[63 : 0]                        minstret_d;

wire[31 : 0]                        minstret_full;
wire[31 : 0]                        minstreth_full;

wire[31 : 0]                        mvendorid_full;
wire[31 : 0]                        marchid_full;
wire[31 : 0]                        mhartid_full;


// debug csr
wire[3 : 0]                         xdebugver;

reg                                 dcsr_ebreakm_q;
wire                                dcsr_ebreakm_rld;
wire                                dcsr_ebreakm_d;

reg                                 dcsr_stepie_q;
wire                                dcsr_stepie_rld;
wire                                dcsr_stepie_d;

reg                                 dcsr_stopcount_q;
wire                                dcsr_stopcount_rld;
wire                                dcsr_stopcount_d;

reg                                 dcsr_stoptime_q;
wire                                dcsr_stoptime_rld;
wire                                dcsr_stoptime_d;

reg                                 dcsr_step_q;
wire                                dcsr_step_rld;
wire                                dcsr_step_d;

wire[31 : 0]                        dcsr_full;

reg[2 : 0]                          dcause_q;
wire                                dcause_rld;
wire[2 : 0]                         dcause_d;
wire[31 : 0]                        dcause_full;

reg[31 : 0]                         dpc_q;
wire                                dpc_rld;
wire[31 : 0]                        dpc_d;
wire[31 : 0]                        dpc_full;

reg[31 : 0]                         dscratch0_q;
wire                                dscratch0_rld;
wire[31 : 0]                        dscratch0_d;
wire[31 : 0]                        dscratch0_full;

reg[31 : 0]                         dscratch1_q;
wire                                dscratch1_rld;
wire[31 : 0]                        dscratch1_d;
wire[31 : 0]                        dscratch1_full;

wire                                excp_irq_taken;

// 对地址进行判断
assign      csr_idx_is_MVENDORID    = (csr_idx == LP_MVENDORID_REG_ADDR);
assign      csr_idx_is_MARCHID      = (csr_idx == LP_MARCHID_REG_ADDR);
assign      csr_idx_is_MIMPID       = (csr_idx == LP_MIMPID_REG_ADDR);
assign      csr_idx_is_MHARTID      = (csr_idx == LP_MHARTID_REG_ADDR);
assign      csr_idx_is_MSTATUS      = (csr_idx == LP_MSTATUS_REG_ADDR);
assign      csr_idx_is_MISA         = (csr_idx == LP_MISA_REG_ADDR);
assign      csr_idx_is_MEDELEG      = (csr_idx == LP_MEDELEG_REG_ADDR);
assign      csr_idx_is_MIDELEG      = (csr_idx == LP_MIDELEG_REG_ADDR);
assign      csr_idx_is_MIE          = (csr_idx == LP_MIE_REG_ADDR);
assign      csr_idx_is_MTVEC        = (csr_idx == LP_MTVEC_REG_ADDR);
assign      csr_idx_is_MTVT         = (csr_idx == LP_MTVT_REG_ADDR);
assign      csr_idx_is_MCOUNTEREN   = (csr_idx == LP_MCOUNTEREN_REG_ADDR);
assign      csr_idx_is_MSCRATCH     = (csr_idx == LP_MSCRATCH_REG_ADDR);
assign      csr_idx_is_MEPC         = (csr_idx == LP_MEPC_REG_ADDR);
assign      csr_idx_is_MCAUSE       = (csr_idx == LP_MCAUSE_REG_ADDR);
assign      csr_idx_is_MTVAL        = (csr_idx == LP_MTVAL_REG_ADDR);
assign      csr_idx_is_MIP          = (csr_idx == LP_MIP_REG_ADDR);
assign      csr_idx_is_MCYCLE       = (csr_idx == LP_MCYCLE_REG_ADDR);
assign      csr_idx_is_MINSTRET     = (csr_idx == LP_MINSTRET_REG_ADDR);
assign      csr_idx_is_MCYCLEH      = (csr_idx == LP_MCYCLEH_REG_ADDR);
assign      csr_idx_is_MINSTRETH    = (csr_idx == LP_MINSTRETH_REG_ADDR);
assign      csr_idx_is_TSELECT      = (csr_idx == LP_TSELECT_REG_ADDR);
assign      csr_idx_is_TDATA1       = (csr_idx == LP_TDATA1_REG_ADDR);
assign      csr_idx_is_TDATA2       = (csr_idx == LP_TDATA2_REG_ADDR);
assign      csr_idx_is_TDATA3       = (csr_idx == LP_TDATA3_REG_ADDR);
assign      csr_idx_is_DCSR         = (csr_idx == LP_MARCHID_REG_ADDR);
assign      csr_idx_is_DPC          = (csr_idx == LP_DPC_REG_ADDR);
assign      csr_idx_is_DSCRATCH0    = (csr_idx == LP_DSCRATCH0_REG_ADDR);
assign      csr_idx_is_DSCRATCH1    = (csr_idx == LP_DSCRATCH1_REG_ADDR);

// 判断写回寄存器
assign      wbck_MVENDORID  = csr_idx_is_MVENDORID & wbck_vld;
assign      wbck_MARCHID    = csr_idx_is_MARCHID   & wbck_vld;
assign      wbck_MIMPID     = csr_idx_is_MIMPID    & wbck_vld;
assign      wbck_MHARTID    = csr_idx_is_MHARTID   & wbck_vld;
assign      wbck_MSTATUS    = csr_idx_is_MSTATUS   & wbck_vld;
assign      wbck_MISA       = csr_idx_is_MISA      & wbck_vld;
assign      wbck_MEDELEG    = csr_idx_is_MEDELEG   & wbck_vld;
assign      wbck_MIDELEG    = csr_idx_is_MIDELEG   & wbck_vld;
assign      wbck_MIE        = csr_idx_is_MIE       & wbck_vld;
assign      wbck_MTVEC      = csr_idx_is_MTVEC     & wbck_vld;
assign      wbck_MTVT       = csr_idx_is_MTVT      & wbck_vld;
assign      wbck_MSCRATCH   = csr_idx_is_MSCRATCH  & wbck_vld;
assign      wbck_MEPC       = csr_idx_is_MEPC      & wbck_vld;
assign      wbck_MCAUSE     = csr_idx_is_MCAUSE    & wbck_vld;
assign      wbck_MTVAL      = csr_idx_is_MTVAL     & wbck_vld;
assign      wbck_MIP        = csr_idx_is_MIP       & wbck_vld;
assign      wbck_MCYCLE     = csr_idx_is_MCYCLE    & wbck_vld;
assign      wbck_MINSTRET   = csr_idx_is_MINSTRET  & wbck_vld;
assign      wbck_TSELECT    = csr_idx_is_TSELECT   & wbck_vld;
assign      wbck_TDATA1     = csr_idx_is_TDATA1    & wbck_vld;
assign      wbck_TDATA2     = csr_idx_is_TDATA2    & wbck_vld;
assign      wbck_TDATA3     = csr_idx_is_TDATA3    & wbck_vld;
assign      wbck_DCSR       = csr_idx_is_DCSR      & wbck_vld;
assign      wbck_DPC        = csr_idx_is_DPC       & wbck_vld;
assign      wbck_DSCRATCH0  = csr_idx_is_DSCRATCH0 & wbck_vld;
assign      wbck_DSCRATCH1  = csr_idx_is_DSCRATCH1 & wbck_vld;


// 对于mstatus寄存器，

assign      excp_irq_taken = excp_taken | irq_taken;

// 我们会在以下情况发生时重新mstatus寄存器
// 1、发生中断或者异常
// 2、执行mret
// 3、写回
assign      mstatus_rld =   excp_irq_taken |
                            cmted_mret |
                            wbck_MSTATUS;

assign      mstatus_mie_rld = mstatus_rld;
// 在异常或者中断发生时，全局中断会被关闭
assign      mstatus_mie_d = excp_irq_taken ? 1'b0 :
                            cmted_mret ? mstatus_mpie_q :
                            wbck_MSTATUS ? wbck_wdata[3] :
                            mstatus_mie_q;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        mstatus_mie_q <= 1'b0;
    end else if(mstatus_mie_rld) begin
        mstatus_mie_q <= mstatus_mie_d;
    end
end

assign      mstatus_mpie_rld = mstatus_rld;
assign      mstatus_mpie_d =    excp_irq_taken ? mstatus_mie_q :
                                cmted_mret ? 1'b1 :
                                wbck_MSTATUS ? wbck_wdata[7] :
                                mstatus_mpie_q;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        mstatus_mpie_q <= 1'b0;
    end else if(mstatus_mpie_rld) begin
        mstatus_mpie_q <= mstatus_mpie_d;
    end
end

assign      mstatus_full[31] = 1'b0;
assign      mstatus_full[30 : 23] = 8'd0;
assign      mstatus_full[22 : 17] = 6'd0;
assign      mstatus_full[16 : 15] = 2'd0;       // 我们不支持自定义扩展单元，所以xs字段固定为0
assign      mstatus_full[14 : 13] = 2'd0;       // 我们不支持FPU单元，所以fs字段固定为0
assign      mstatus_full[12 : 11] = 2'b11;      // 我们只支持Machine模式，所以MPP固定为2'b11
assign      mstatus_full[10 : 9] = 2'd0;
assign      mstatus_full[8] = 1'b0;              // SPP
assign      mstatus_full[7] = mstatus_mpie_q;    // MPIE
assign      mstatus_full[6] = 1'b0;              // RSV
assign      mstatus_full[5] = 1'b0;              // SPIE
assign      mstatus_full[4] = 1'b0;              // UPIE
assign      mstatus_full[3] = mstatus_mie_q;     // MIE
assign      mstatus_full[2] = 1'b0;              // RSV
assign      mstatus_full[1] = 1'b0;              // SIE
assign      mstatus_full[0] = 1'b0;              // UIE


// Machine Trap-Vector Base-Address Register
assign      mtvec_rld = wbck_MTVEC;
assign      mtvec_d = wbck_wdata;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        mtvec_q <= 32'd0;
    end else if(mtvec_rld) begin
        mtvec_q <= mtvec_d;
    end
end

assign      mtvec_full = mtvec_q;

assign      mtvt_rld = wbck_MTVT;
assign      mtvt_d = wbck_wdata;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        mtvt_q <= 32'd0;
    end else if(mtvt_rld) begin
        mtvt_q <= mtvt_d;
    end
end

assign      mtvt_full = mtvt_q;

// Machine Exception Program Counter
assign      mepc_rld = wbck_MEPC | mepc_wen;
assign      mepc_d = mepc_wen ? mepc_wdata : wbck_wdata;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        mepc_q <= {32{1'b0}};
    end else if(mepc_rld) begin
        mepc_q <= mepc_d;
    end
end

assign      mepc_full = mepc_q;


// 写回、发生异常、发生中断，都会修改mcause寄存器
assign      mcause_rld = wbck_MCAUSE | mcause_wen;
// 来自异常的优先级更高
assign      mcause_d = mcause_wen ? mcause_wdata : wbck_wdata;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        mcause_q <= {32{1'b0}};
    end else if(mcause_rld) begin
        mcause_q <= mcause_d;
    end
end

assign      mcause_full = mcause_q;


// Machine Trap Value
assign      mtval_rld = wbck_MTVAL | mtval_wen;
assign      mtval_d = mtval_wen ? mtval_wdata : wbck_wdata;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        mtval_q <= {32{1'b0}};
    end else if(mtval_rld) begin
        mtval_q <= mtval_d;
    end
end

assign      mtval_full = mtval_q;


// Machine external interrupt enable
assign      mie_meie_rld = wbck_MIE;
assign      mie_meie_d = wbck_wdata[11];
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        mie_meie_q <= 1'b0;
    end else if(mie_meie_rld) begin
        mie_meie_q <= mie_meie_d;
    end
end

// machine software interrupt enable
assign      mie_msie_rld = wbck_MIE;
assign      mie_msie_d = wbck_wdata[3];
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        mie_msie_q <= 1'b0;
    end else if(mie_msie_rld) begin
        mie_msie_q <= mie_msie_d;
    end
end

// machine timer interrupt enable
assign      mie_mtie_rld = wbck_MIE;
assign      mie_mtie_d = wbck_wdata[7];
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        mie_mtie_q <= 1'b0;
    end else if(mie_mtie_rld) begin
        mie_mtie_q <= mie_mtie_d;
    end
end

assign      mie_full[31 : 12]    = 20'd0;
assign      mie_full[11]         = mie_meie_q;
assign      mie_full[10 : 8]     = 3'd0;
assign      mie_full[7]          = mie_mtie_q;
assign      mie_full[6 : 4]      = 3'd0;
assign      mie_full[3]          = mie_msie_q;
assign      mie_full[2 : 0]      = 3'd0;


// timer interrupt pending
assign      mtip_d = irq_tmr;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        mtip_q <= 1'b0;
    end else begin
        mtip_q <= mtip_d;
    end
end

// software interrupt pending
assign      msip_d = irq_sft;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        msip_q <= 1'b0;
    end else begin
        msip_q <= msip_d;
    end
end

// external interrupt pending
assign      meip_d = irq_tmr;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        meip_q <= 1'b0;
    end else begin
        meip_q <= meip_d;
    end
end

assign      mip_full[31 : 12]    = 20'd0;
assign      mip_full[11]         = meip_q;
assign      mip_full[10]         = 1'b0;
assign      mip_full[9]          = 1'b0;
assign      mip_full[8]          = 1'b0;
assign      mip_full[7]          = mtip_q;
assign      mip_full[6]          = 1'b0;
assign      mip_full[5]          = 1'b0;
assign      mip_full[4]          = 1'b0;
assign      mip_full[3]          = msip_q;
assign      mip_full[2]          = 1'b0;
assign      mip_full[1]          = 1'b0;
assign      mip_full[0]          = 1'b0;


assign      mscratch_rld = wbck_MSCRATCH;
assign      mscratch_d = wbck_wdata;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        mscratch_q <= 32'd0;
    end else if(mscratch_rld) begin
        mscratch_q <= mscratch_d;
    end
end

assign      mscratch_full = mscratch_q;

assign      mcycle_rld = (~dcsr_stopcount_q);
assign      mcycle_d = mcycle_q + 1'b1;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        mcycle_q <= {64{1'b0}};
    end else if(mcycle_rld) begin
        mcycle_q <= mcycle_d;
    end
end

assign      {mcycleh_full, mcycle_full} = mcycle_q;
assign      {minstreth_full, minstret_full} = 64'd0;
assign      mvendorid_full = 32'd0;
assign      marchid_full = 32'd0;
assign      mimpid_full = 32'd0;
assign      mhartid_full = 32'd0;
assign      misa_full = 32'd0;

// 只支持Machine Mode
assign      m_mode = 1'b1;

assign      dpc_rld = dpc_wen | wbck_DPC;
assign      dpc_d = dpc_wen ? dpc_wdata : wbck_wdata;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0 ) begin
        dpc_q <= 32'd0;
    end else if(dpc_rld) begin
        dpc_q <= dpc_d;
    end
end

assign      dpc_full = dpc_q;

assign      dcause_rld = dcause_wen;
assign      dcause_d = dcause_wdata;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0 ) begin
        dcause_q <= 3'd0;
    end else if(dcause_rld) begin
        dcause_q <= dcause_d;
    end
end

assign      dcause_full[31 : 3] = 29'd0;
assign      dcause_full[2 : 0] = dcause_q;

// debug csr
// 该比特用于配置core处于Machine Mode时，执行ebreak指令时的行为
// 0 - 执行ebreak时仅产生异常
// 1 - 执行ebreak时进入debug mode
assign      dcsr_ebreakm_rld = wbck_DCSR;
assign      dcsr_ebreakm_d = wbck_wdata[15];
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0 ) begin
        dcsr_ebreakm_q <= 1'b0;
    end else if(dcsr_ebreakm_rld) begin
        dcsr_ebreakm_q <= dcsr_ebreakm_d;
    end
end

// 该比特用于配置在单步调试模式下，是否允许响应中断
// 0 - 在单步调试模式下禁止响应中断
// 1 - 在单步调试模式下仍正常响应中断
assign      dcsr_stepie_rld = wbck_DCSR;
assign      dcsr_stepie_d = wbck_wdata[11];
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0 ) begin
        dcsr_stepie_q <= 1'b0;
    end else if(dcsr_stepie_rld) begin
        dcsr_stepie_q <= dcsr_stepie_d;
    end
end


// 设置在debug mode下，停止cycle以及instret计数
assign      dcsr_stopcount_rld = wbck_DCSR;
assign      dcsr_stopcount_d = wbck_wdata[10];
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0 ) begin
        dcsr_stopcount_q <= 1'b0;
    end else if(dcsr_stopcount_rld) begin
        dcsr_stopcount_q <= dcsr_stopcount_d;
    end
end

// 设置在debug mode下，停止timer
assign      dcsr_stoptime_rld = wbck_DCSR;
assign      dcsr_stoptime_d = wbck_wdata[9];
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0 ) begin
        dcsr_stoptime_q <= 1'b0;
    end else if(dcsr_stoptime_rld) begin
        dcsr_stoptime_q <= dcsr_stoptime_d;
    end
end

// 单步运行模式
assign      dcsr_step_rld = wbck_DCSR;
assign      dcsr_step_d = wbck_wdata[2];
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0 ) begin
        dcsr_step_q <= 1'b0;
    end else if(dcsr_step_rld) begin
        dcsr_step_q <= dcsr_step_d;
    end
end

assign      dcsr_full[31 : 28]   = 4'd4;
assign      dcsr_full[27 : 16]   = 12'd0;
assign      dcsr_full[15]        = dcsr_ebreakm_q;
assign      dcsr_full[14]        = 1'b0;
assign      dcsr_full[13]        = 1'b0;
assign      dcsr_full[12]        = 1'b0;
assign      dcsr_full[11]        = dcsr_stepie_q;
assign      dcsr_full[10]        = dcsr_stopcount_q;
assign      dcsr_full[9]         = dcsr_stoptime_q;
assign      dcsr_full[8 : 6]     = dcause_q;
assign      dcsr_full[5]         = 1'b0;
assign      dcsr_full[4]         = 1'b1;
assign      dcsr_full[3]         = 1'b0;
assign      dcsr_full[2]         = dcsr_step_q;
assign      dcsr_full[1 : 0]     = 2'd3;                // 只支持Machine mode

// debug mode下用的临时寄存器0
assign      dscratch0_rld = wbck_DSCRATCH0;
assign      dscratch0_d = wbck_wdata;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0 ) begin
        dscratch0_q <= 32'd0;
    end else if(dscratch0_rld) begin
        dscratch0_q <= dscratch0_d;
    end
end

assign      dscratch0_full = dscratch0_q;

// debug mode下用的临时寄存器1
assign      dscratch1_rld = wbck_DSCRATCH1;
assign      dscratch1_d = wbck_wdata;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0 ) begin
        dscratch1_q <= 32'd0;
    end else if(dscratch1_rld) begin
        dscratch1_q <= dscratch1_d;
    end
end

assign      dscratch1_full = dscratch1_q;


// 只要cause不为零，就认为处于debug mode
assign      d_mode        = |dcause_q;

assign      mtvec           = mtvec_q;
assign      mepc            = mepc_q;
assign      mie_msie        = mie_msie_q;
assign      mie_mtie        = mie_mtie_q;
assign      mie_meie        = mie_meie_q;
assign      mstatus_mie     = mstatus_mie_q;

assign      dpc             = dpc_q;
assign      dcsr_step       = dcsr_step_q;
assign      dcsr_stepie     = dcsr_stepie_q;
assign      dcsr_ebreakm    = dcsr_ebreakm_q;
assign      dcsr_stoptime   = dcsr_stoptime_q;


// 写回是立即就绪的
assign      wbck_rdy = 1'b1;

assign      csr_idx_err = 1'b0;

// 读接口
assign      csr_rdata =
                        ({32{csr_idx_is_MSTATUS}}   & mstatus_full) |
                        ({32{csr_idx_is_MISA}}      & misa_full) |
                        ({32{csr_idx_is_MIE}}       & mie_full) |
                        ({32{csr_idx_is_MTVEC}}     & mtvec_full) |
                        ({32{csr_idx_is_MTVT}}      & mtvt_full) |
                        ({32{csr_idx_is_MSCRATCH}}  & mscratch_full) |
                        ({32{csr_idx_is_MEPC}}      & mepc_full) |
                        ({32{csr_idx_is_MCAUSE}}    & mcause_full) |
                        ({32{csr_idx_is_MTVAL}}     & mtval_full) |
                        ({32{csr_idx_is_MIP}}       & mip_full) |
                        ({32{csr_idx_is_MCYCLE}}    & mcycle_full) |
                        ({32{csr_idx_is_MCYCLEH}}   & mcycleh_full) |
                        ({32{csr_idx_is_MINSTRET}}  & minstret_full) |
                        ({32{csr_idx_is_MINSTRETH}} & minstreth_full) |
                        ({32{csr_idx_is_MVENDORID}} & mvendorid_full) |
                        ({32{csr_idx_is_MARCHID}}   & marchid_full) |
                        ({32{csr_idx_is_MIMPID}}    & mimpid_full) |
                        ({32{csr_idx_is_MHARTID}}   & mhartid_full) |
                        ({32{csr_idx_is_DCSR}}      & dcsr_full) |
                        ({32{csr_idx_is_DSCRATCH0}} & dscratch0_full) |
                        ({32{csr_idx_is_DSCRATCH1}} & dscratch1_full) |
                        32'd0;

endmodule