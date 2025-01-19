module lnrv_cmt_irq
(
    // 指令执行模块空闲，没有正在执行的指令，或者当前指令已经执行完成
    input                       exu_idle,

    input                       ifu_vld,
    input[31 : 0]               ifu_pc,

    input                       irq_sft,            // 软件中断
    input                       irq_ext,            // 外部中断
    input                       irq_tmr,            // 定时器中断

    // clic接口
    input                       clic_irq_req,
    output                      clic_irq_ack,
    input[7 : 0]                clic_irq_id,
    input                       clic_irq_mode,

    input                       mie_meie,
    input                       mie_mtie,
    input                       mie_msie,
    input                       mstatus_mie,

    input                       d_mode,

    // 有中断发生
    output                      irq_taken,

    // 原始中断有效信号，没有被mstatus_mie mask
    output                      irq_req_raw,

    // 中断发生时需要修改mcsr寄存器
    output[31 : 0]              mepc_wdata,
    output[31 : 0]              mcause_wdata,

    input                       dcsr_stepie,        // 在单步调试模式下是否使能中断
    input                       dcsr_step,          // 单步调试模式

    // 中断跳转地址
    input[31 : 0]               mtvec,

    // clic模块管理的中断向量表
    input[31 : 0]               mtvt,

    // 流水线冲刷请求
    output                      pipe_flush_req,
    input                       pipe_flush_ack,
    output[31 : 0]              pipe_flush_pc_op1,
    output[31 : 0]              pipe_flush_pc_op2,

    output                      vec_irq_taken,

    input                       clk,
    input                       reset_n
);

wire                            clic_mode;
wire                            clint_mode;

wire                            clic_vec_irq;

wire                            irq_sft_vld;
wire                            irq_ext_vld;
wire                            irq_tmr_vld;
wire                            irq_clic_vld;
wire                            any_irq_vld;


wire                            dbg_msk_irq;
wire                            pipe_flush_hsked;

assign      clic_mode   = (mtvec[5 : 0] == 6'b00_0011);
assign      clint_mode  = ~clic_mode;

assign      pipe_flush_hsked = pipe_flush_req & pipe_flush_ack;

assign      irq_sft_vld = irq_sft & mie_msie & clint_mode;
assign      irq_ext_vld = irq_ext & mie_meie;
assign      irq_tmr_vld = irq_tmr & mie_mtie & clint_mode;
assign      irq_clic_vld = clic_irq_req & clic_mode;

assign      irq_req_raw =   irq_sft_vld |
                            irq_ext_vld |
                            irq_tmr_vld |
                            irq_clic_vld;

assign      any_irq_vld = mstatus_mie & irq_req_raw;

// 如果当前处于debug mode，或者单步调试模式且没有使能单步调试中断，则不会响应任何中断请求
assign      dbg_msk_irq = d_mode | (dcsr_step & (~dcsr_stepie));

// 生成流水线冲刷请求，前提条件如下:
//      1、当前中断有效
//      2、当前exu处于空闲状态
//      3、ifu中的pc是有效的
// 因为对于中断请求，我们需要将下一条未执行指令的pc保存到mepc寄存器，我们取指不会停止，因此肯定可以等到下一条指令有效
assign      pipe_flush_req = any_irq_vld & (~dbg_msk_irq) & exu_idle & ifu_vld;

assign      clic_vec_irq = irq_clic_vld & clic_irq_mode;
// 我们默认只支持非向量中断模式，因此这里直接使用mtvec寄存器的值作为跳转地址，如果是向量模式，
// 则首先需要进行访存，以获取对应中断id的中断服务程序地址
assign      pipe_flush_pc_op1 = clic_vec_irq ? mtvt : mtvec;
assign      pipe_flush_pc_op2 = clic_vec_irq ? {22'd0, clic_irq_id, 2'b00} : 32'd0;


// 对于中断，我们需要将下一条未执行指令的地址保存到mepc中，exu处于流水线的第三级，pc由idu输出，已经
// 执行完成，ifu的输出即为下一条未执行指令的地址
assign      mepc_wdata = ifu_pc;

assign      mcause_wdata[31]        = 1'b1;
assign      mcause_wdata[30 : 4]    = 27'd0;
assign      mcause_wdata[3 : 0]     = irq_sft_vld ? 4'd3 :
                                      irq_tmr_vld ? 4'd7 :
                                      irq_ext_vld ? 4'd11 :
                                      clic_irq_req ? 4'd15 :
                                      4'd0;

//
assign      irq_taken       = pipe_flush_hsked;
assign      clic_irq_ack    = pipe_flush_hsked;

assign      vec_irq_taken   = clic_vec_irq & mstatus_mie;

endmodule