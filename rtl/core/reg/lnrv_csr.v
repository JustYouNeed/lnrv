module lnrv_csr
(
    // 复位后的mtvec值
    input[31 : 0]                   reset_mtvec,

    output[31 : 0]                  mepc,
    output[31 : 0]                  mtvec,
    output                          mstatus_mie,
    output[31 : 0]                  dpc,
    output                          d_mode,
    
    // 中断输入
    input                           sft_irq,
    input                           tmr_irq,
    input                           ext_irq,

    // 不可屏蔽中断
    input                           non_msk_irq,
    output                          sft_irq_en,
    output                          tmr_irq_en,
    output                          ext_irq_en,

    // 来自异常与中断的交付
    input                           cmt_irq,
    input                           cmt_excp,
    input                           cmt_debug,
    input                           cmt_mret,
    input                           cmt_dret,
    input[31 : 0]                   cmt_mepc,
    input[31 : 0]                   cmt_mcause,
    input[31 : 0]                   cmt_mtval,
    input[31 : 0]                   cmt_dpc,
    input[2 : 0]                    cmt_dcause,

    // debug csr
    output                          dcsr_step,
    output                          dcsr_stepie,
    output                          dcsr_ebreakm,
    output                          dcsr_stoptime,
    output                          dcsr_stopcount,   

    // 非法访问
    // 当访问不存在的csr时
    // 在非debug mode下访问dcsr时
    output                          ilegl_access,

    // 读写共用一个索引
    input[11 : 0]                   csr_idx,

    // 读接口
    output[31 : 0]                  csr_rdata,

    // 写回接口
    input                           wbck_vld,
    output                          wbck_rdy,
    input[31 : 0]                   wbck_wdata,

    input                           clk,
    input                           reset_n
);



// Machine Information Registers Map
localparam[11 : 0]                  LP_MVENDORID_REG_ADDR = 12'hf11;
localparam[11 : 0]                  LP_MARCHID_REG_ADDR = 12'hf12;
localparam[11 : 0]                  LP_MIMPID_REG_ADDR = 12'hf13;
localparam[11 : 0]                  LP_MHARTID_REG_ADDR = 12'hf14;


// Machine Trap Setup Registers Map
localparam[11 : 0]                  LP_MSTATUS_REG_ADDR = 12'h300;
localparam[11 : 0]                  LP_MISA_REG_ADDR = 12'h301;
localparam[11 : 0]                  LP_MEDELEG_REG_ADDR = 12'h302;
localparam[11 : 0]                  LP_MIDELEG_REG_ADDR = 12'h303;
localparam[11 : 0]                  LP_MIE_REG_ADDR = 12'h304;
localparam[11 : 0]                  LP_MTVEC_REG_ADDR = 12'h305;
localparam[11 : 0]                  LP_MCOUNTEREN_REG_ADDR = 12'h306;


// Machine Trap Handing Registers Map
localparam[11 : 0]                  LP_MSCRATCH_REG_ADDR = 12'h340;
localparam[11 : 0]                  LP_MEPC_REG_ADDR = 12'h341;
localparam[11 : 0]                  LP_MCAUSE_REG_ADDR = 12'h342;
localparam[11 : 0]                  LP_MTVAL_REG_ADDR = 12'h343;
localparam[11 : 0]                  LP_MIP_REG_ADDR = 12'h344;


// Machine Counter/Timers
localparam[11 : 0]                  LP_MCYCLE_REG_ADDR = 12'hb00;
localparam[11 : 0]                  LP_MINSTRET_REG_ADDR = 12'hb02;
localparam[11 : 0]                  LP_MCYCLEH_REG_ADDR = 12'hb80;
localparam[11 : 0]                  LP_MINSTRETH_REG_ADDR = 12'hb82;


// Debug/Trace Registers Map
localparam[11 : 0]                  LP_TSELECT_REG_ADDR = 12'h7a0;
localparam[11 : 0]                  LP_TDATA1_REG_ADDR = 12'h7a1;
localparam[11 : 0]                  LP_TDATA2_REG_ADDR = 12'h7a2;
localparam[11 : 0]                  LP_TDATA3_REG_ADDR = 12'h7a3;


// Debug Mode Registers
localparam[11 : 0]                  LP_DCSR_REG_ADDR = 12'h7b0;
localparam[11 : 0]                  LP_DPC_REG_ADDR = 12'h7b1;
localparam[11 : 0]                  LP_DSCRATCH0_REG_ADDR = 12'h7b2;
localparam[11 : 0]                  LP_DSCRATCH1_REG_ADDR = 12'h7b3;

assign      ilegl_access = 1'b0;

assign      dcsr_step = 1'b0;
assign      dcsr_stepie = 1'b0;
assign      dcsr_ebreakm = 1'b0;

assign      dpc = 32'd0;
assign      d_mode = 1'b0;
assign      mstatus_mie = 1'b1;



// wire[31 : 0]            misa_full;


// reg[31 : 0]             mstatus_q;
// wire                    mstatus_rld;
// wire[31 : 0]            mstatus_d;

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


reg[31 : 0]             mcause_q;
wire                    mcause_rld;
wire[31 : 0]            mcause_d;

reg[31 : 0]             mepc_q;
wire                    mepc_rld;
wire[31 : 0]            mepc_d;

reg[31 : 0]             mtval_q;
wire                    mtval_rld;
wire[31 : 0]            mtval_d;

reg[31 : 0]             mtvec_q;
wire                    mtvec_rld;
wire[31 : 0]            mtvec_d;

wire[31 : 0]            mstatus;

reg                     mstatus_mie_q;
wire                    mstatus_mie_rld;
wire                    mstatus_mie_d;

reg                     mstatus_mpie_q;
wire                    mstatus_mpie_rld;
wire                    mstatus_mpie_d;

// Machine interrupt enable register
wire[31 : 0]            mie;

reg                     mtie_q;
wire                    mtie_rld;
wire                    mtie_d;

reg                     msie_q;
wire                    msie_rld;
wire                    msie_d;

reg                     meie_q;
wire                    meie_rld;
wire                    meie_d;

reg[31 : 0]             mie_q;
wire                    mie_rld;
wire[31 : 0]            mie_d;

// Machine interrupt pending register
wire[31 : 0]            mip;
reg                     mtip_q;
wire                    mtip_d;

reg                     msip_q;
wire                    msip_d;

reg                     meip_q;
wire                    meip_d;

reg[31 : 0]                 mscratch_q;
wire                        mscratch_rld;
wire[31 : 0]                mscratch_d;


reg[63 : 0]                 cycle_q;
wire                        cycle_rld;
wire[63 : 0]                cycle_d;

// debug csr
wire[3 : 0]                 xdebugver;

reg                         ebreakm_q;
wire                        ebreakm_rld;
wire                        ebreakm_d;

reg                         ebreaks_q;
wire                        ebreaks_rld;
wire                        ebreaks_d;

reg                         ebreaku_q;
wire                        ebreaku_rld;
wire                        ebreaku_d;

reg                         stepie_q;
wire                        stepie_rld;
wire                        stepie_d;

reg                         stopcount_q;
wire                        stopcount_rld;
wire                        stopcount_d;

reg                         stoptime_q;
wire                        stoptime_rld;
wire                        stoptime_d;

reg[2 : 0]                  dcause_q;
wire                        dcause_rld;
wire[2 : 0]                 dcause_d;

wire                        mprven;

reg                         nmip_q;
wire                        nmip_d;

reg                         step_q;
wire                        step_rld;
wire                        step_d;

wire[1 : 0]                 prv;


wire[31 : 0]                dcsr;


reg[31 : 0]                 dpc_q;
wire                        dpc_rld;
wire[31 : 0]                dpc_d;

reg[31 : 0]                 dscratch0_q;
wire                        dscratch0_rld;
wire[31 : 0]                dscratch0_d;

reg[31 : 0]                 dscratch1_q;
wire                        dscratch1_rld;
wire[31 : 0]                dscratch1_d;


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

assign      cmt_mstatus_vld = cmt_excp | cmt_irq;

// 我们会在以下情况发生时重新mstatus寄存器
// 1、发生中断或者异常
// 2、执行mret
// 3、写回
assign      mstatus_rld =   cmt_mstatus_vld | 
                            cmt_mret | 
                            wbck_MSTATUS;

assign      mstatus_mpie_rld = mstatus_rld;
assign      mstatus_mpie_d =    cmt_mstatus_vld ? mstatus_mie_q : 
                                cmt_mret ? 1'b1 : 
                                wbck_MSTATUS ? wbck_wdata[7] : 
                                mstatus_mpie_q;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        mstatus_mpie_q <= 1'b0;
    end else if(mstatus_mpie_rld) begin
        mstatus_mpie_q <= mstatus_mpie_d;
    end
end

assign      mstatus_mie_rld = mstatus_rld;
// 在异常或者中断发生时，全局中断会被关闭
assign      mstatus_mie_d = cmt_mstatus_vld ? 1'b0 : 
                            cmt_mret ? mstatus_mpie_q : 
                            wbck_MSTATUS ? wbck_wdata[3] : 
                            mstatus_mie_q;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        mstatus_mie_q <= 1'b0;
    end else if(mstatus_mie_rld) begin
        mstatus_mie_q <= mstatus_mie_d;
    end
end


assign      mstatus[31] = 1'b0;
assign      mstatus[30 : 23] = 8'd0;
assign      mstatus[22 : 17] = 6'd0;
// 我们不支持自定义扩展单元，所以xs字段固定为0
assign      mstatus[16 : 15] = 2'd0; // 
// 我们不支持FPU单元，所以fs字段固定为0
assign      mstatus[14 : 13] = 2'd0;  
// 我们只支持Machine模式，所以MPP固定为2'b11
assign      mstatus[12 : 11] = 2'b11;  // MPP
assign      mstatus[10 : 9] = 2'd0;
assign      mstatus[8] = 1'b0;              // SPP
assign      mstatus[7] = mstatus_mpie_q;    // MPIE
assign      mstatus[6] = 1'b0;              // RSV
assign      mstatus[5] = 1'b0;              // SPIE
assign      mstatus[4] = 1'b0;              // UPIE
assign      mstatus[3] = mstatus_mie_q;     // MIE
assign      mstatus[2] = 1'b0;              // RSV
assign      mstatus[1] = 1'b0;              // SIE
assign      mstatus[0] = 1'b0;              // UIE

assign      cmt_mcause_vld = cmt_excp | cmt_irq;

// 写回、发生异常、发生中断，都会修改mcause寄存器
assign      mcause_rld = wbck_MCAUSE | cmt_mcause_vld;
// 来自异常的优先级更高
assign      mcause_d = cmt_mcause_vld ? cmt_mcause : wbck_wdata;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        mcause_q <= {32{1'b0}};
    end else if(mcause_rld) begin
        mcause_q <= mcause_d;
    end
end

assign      cmt_mepc_vld = cmt_excp | cmt_irq;

// Machine Exception Program Counter
assign      mepc_rld = wbck_MEPC | cmt_mepc_vld;
assign      mepc_d = cmt_mepc_vld ? cmt_mepc : wbck_wdata;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        mepc_q <= {32{1'b0}};
    end else if(mepc_rld) begin
        mepc_q <= mepc_d;
    end
end

// 只有异常才需要更新mtval寄存器
assign      cmt_mtval_vld = cmt_excp;

// Machine Trap Value
assign      mtval_rld = wbck_MTVAL | cmt_mtval_vld;
assign      mtval_d = cmt_mtval_vld ? cmt_mtval : wbck_wdata;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        mtval_q <= {32{1'b0}};
    end else if(mtval_rld) begin
        mtval_q <= mtval_d;
    end
end

// Machine Trap-Vector Base-Address Register
assign      mtvec_rld = wbck_MTVEC;
assign      mtvec_d = wbck_wdata;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        mtvec_q <= reset_mtvec;
    end else if(mtvec_rld) begin
        mtvec_q <= mtvec_d;
    end
end


// timer interrupt pending
assign      mtip_d = tmr_irq;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        mtip_q <= 1'b0;
    end else begin
        mtip_q <= mtip_d;
    end
end

// software interrupt pending
assign      msip_d = sft_irq;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        msip_q <= 1'b0;
    end else begin
        msip_q <= msip_d;
    end
end

// external interrupt pending
assign      meip_d = tmr_irq;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        meip_q <= 1'b0;
    end else begin
        meip_q <= meip_d;
    end
end

assign      mip[31 : 12]    = 20'd0;
assign      mip[11]         = meip_q;
assign      mip[10]         = 1'b0;
assign      mip[9]          = 1'b0;
assign      mip[8]          = 1'b0;
assign      mip[7]          = mtip_q;
assign      mip[6]          = 1'b0;
assign      mip[5]          = 1'b0;
assign      mip[4]          = 1'b0;
assign      mip[3]          = msip_q;
assign      mip[2]          = 1'b0;
assign      mip[1]          = 1'b0;
assign      mip[0]          = 1'b0;


// Machine external interrupt enable
assign      meie_rld = wbck_MIE;
assign      meie_d = wbck_wdata[11];
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        meie_q <= 1'b0;
    end else if(meie_rld) begin
        meie_q <= meie_d;
    end
end

// machine software interrupt enable
assign      msie_rld = wbck_MIE;
assign      msie_d = wbck_wdata[3];
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        msie_q <= 1'b0;
    end else if(msie_rld) begin
        msie_q <= msie_d;
    end
end

// machine timer interrupt enable
assign      mtie_rld = wbck_MIE;
assign      mtie_d = wbck_wdata[7];
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        mtie_q <= 1'b0;
    end else if(mtie_rld) begin
        mtie_q <= mtie_d;
    end
end

assign      mie[31 : 12]    = 20'd0;
assign      mie[11]         = meie_q;
assign      mie[10 : 8]     = 3'd0;
assign      mie[7]          = mtie_q;
assign      mie[6 : 4]      = 3'd0;
assign      mie[3]          = msie_q;
assign      mie[2 : 0]      = 3'd0;


assign      mscratch_rld = wbck_MSCRATCH;
assign      mscratch_d = wbck_wdata;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        mscratch_q <= 32'd0;
    end else if(mscratch_rld) begin
        mscratch_q <= mscratch_d;
    end
end


assign      cycle_rld = (~dcsr_stopcount);
assign      cycle_d = cycle_q + 1'b1;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        cycle_q <= {64{1'b0}};
    end else if(cycle_rld) begin
        cycle_q <= cycle_d;
    end
end



// debug csr

assign      dpc_rld = cmt_debug | wbck_DPC;
assign      dpc_d = cmt_debug ? cmt_dpc : wbck_wdata;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0 ) begin
        dpc_q <= 32'd0;
    end else if(dpc_rld) begin
        dpc_q <= dpc_d;
    end
end

assign      dcause_rld = cmt_debug;
assign      dcause_d = cmt_dcause;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0 ) begin
        dcause_q <= 3'd0;
    end else if(dcause_rld) begin
        dcause_q <= dcause_d;
    end
end


// 该比特用于配置core处于Machine Mode时，执行ebreak指令时的行为
// 0 - 执行ebreak时仅产生异常
// 1 - 执行ebreak时进入debug mode
assign      ebreakm_rld = wbck_DCSR;
assign      ebreakm_d = wbck_wdata[15];
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0 ) begin
        ebreakm_q <= 1'b0;
    end else if(ebreakm_rld) begin
        ebreakm_q <= ebreakm_d;
    end
end

// 该比特用于配置在单步调试模式下，是否允许响应中断
// 0 - 在单步调试模式下禁止响应中断
// 1 - 在单步调试模式下仍正常响应中断
assign      stepie_rld = wbck_DCSR;
assign      stepie_d = wbck_wdata[11];
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0 ) begin
        stepie_q <= 1'b0;
    end else if(stepie_rld) begin
        stepie_q <= stepie_d;
    end
end


// 设置在debug mode下，停止cycle以及instret计数
assign      stopcount_rld = wbck_DCSR;
assign      stopcount_d = wbck_wdata[10];
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0 ) begin
        stopcount_q <= 1'b0;
    end else if(stopcount_rld) begin
        stopcount_q <= stopcount_d;
    end
end

// 设置在debug mode下，停止timer
assign      stoptime_rld = wbck_DCSR;
assign      stoptime_d = wbck_wdata[9];
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0 ) begin
        stoptime_q <= 1'b0;
    end else if(stoptime_rld) begin
        stoptime_q <= stoptime_d;
    end
end

// 单步运行模式
assign      step_rld = wbck_DCSR;
assign      step_d = wbck_wdata[2];
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0 ) begin
        step_q <= 1'b0;
    end else if(step_rld) begin
        step_q <= step_d;
    end
end

// 不可屏蔽中断挂起
assign      nmip_d = non_msk_irq;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0 ) begin
        nmip_q <= 1'b0;
    end else begin
        nmip_q <= nmip_d;
    end
end

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

assign      dcsr[31 : 28]   = 4'd4;
assign      dcsr[27 : 16]   = 12'd0;
assign      dcsr[15]        = ebreakm_q;
assign      dcsr[14]        = 1'b0;
assign      dcsr[13]        = 1'b0;
assign      dcsr[12]        = 1'b0;
assign      dcsr[11]        = stepie_q;
assign      dcsr[10]        = stopcount_q;
assign      dcsr[9]         = stoptime_q;
assign      dcsr[8 : 6]     = dcause_q;
assign      dcsr[5]         = 1'b0;
assign      dcsr[4]         = 1'b1;
assign      dcsr[3]         = nmip_q;
assign      dcsr[2]         = step_q;
// 只支持Machine mode
assign      dcsr[1 : 0]     = 2'd3;     // prv


// 只要cause不为零，就认为处于debug mode
assign      dbg_mode        = |dcause_q;

assign      mtvec           = mtvec_q;
assign      mepc            = mepc_q;
assign      sft_irq_en      = msie_q;
assign      tmr_irq_en      = mtie_q;
assign      ext_irq_en      = meie_q;
assign      mstatus_mie     = mstatus_mie_q;

assign      dpc             = dpc_q;
assign      dcsr_step       = step_q;
assign      dcsr_stepie     = stepie_q;
assign      dcsr_ebreakm    = ebreakm_q;
assign      dcsr_stopcount  = stopcount_q;
assign      dcsr_stoptime   = stoptime_q;


// 写回是立即就绪的
assign      wbck_rdy = 1'b1;

// 读接口
assign      csr_rdata = ({32{csr_idx_is_MTVEC}} & mtvec_q) | 
                        ({32{csr_idx_is_MEPC}} & mepc_q) |
                        ({32{csr_idx_is_MSCRATCH}} & mscratch_q) | 
                        ({32{csr_idx_is_MCYCLE}} & cycle_q[31 : 0]) | 
                        ({32{csr_idx_is_MCYCLEH}} & cycle_q[63 : 32]) | 
                        ({32{csr_idx_is_DCSR}} & dcsr) | 
                        ({32{csr_idx_is_DSCRATCH0}} & dscratch0_q) | 
                        ({32{csr_idx_is_DSCRATCH1}} & dscratch0_q) | 
                        32'd0;

endmodule