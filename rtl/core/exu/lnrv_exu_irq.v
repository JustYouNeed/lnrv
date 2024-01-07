module lnrv_exu_irq
(
    input                       sft_irq,
    input                       ext_irq,
    input                       tmr_irq,

    input                       sft_irq_en,
    input                       ext_irq_en,
    input                       tmr_irq_en,

    input                       mstatus_mie,

    input                       ifu_pc_vld,
    input[31 : 0]               ifu_pc,

    input                       disp_idle,

    input                       d_mode,

    // 有中断发生
    output                      irq_taken,

    output                      cmt_csr,
    output[31 : 0]              cmt_mepc,
    output[31 : 0]              cmt_mcause,

    // 单步调试模式
    // 在单步调试模式下是否使能中断
    input                       dcsr_step,
    input                       dcsr_stepie,

    // 中断跳转地址
    input[31 : 0]               mtvec,

    output                      pipe_flush_req,
    input                       pipe_flush_ack,
    output[31 : 0]              pipe_flush_pc_op1,
    output[31 : 0]              pipe_flush_pc_op2,


    input                       clk,
    input                       reset_n
);


wire                            sft_irq_masked;
wire                            ext_irq_masked;
wire                            tmr_irq_masked;
wire                            any_irq_vld;

wire                            dbg_msk_irq;
wire                            pipe_flush_hsked;


assign      pipe_flush_hsked = pipe_flush_req & pipe_flush_ack;

assign      sft_irq_masked = sft_irq & sft_irq_en;
assign      ext_irq_masked = ext_irq & ext_irq_en;
assign      tmr_irq_masked = tmr_irq & tmr_irq_en;

assign      any_irq_vld =   mstatus_mie & 
                            (
                                sft_irq_masked | 
                                ext_irq_masked | 
                                tmr_irq_masked
                            );

// 如果当前处于debug mode，或者单步调试模式且没有使能单步调试中断，则不会响应任何中断请求
assign      dbg_msk_irq =   d_mode | 
                            (dcsr_step & (~dcsr_stepie));

// 
assign      irq_taken = any_irq_vld & (~dbg_msk_irq);


// 生成流水线冲刷请求，前提条件如下:
//      1、当前中断有效
//      2、当前exu处于空闲状态
//      3、ifu中的pc是有效的
// 因为对于中断请求，我们需要将下一条未执行指令的pc保存到mepc寄存器
assign      pipe_flush_req = irq_taken & disp_idle & ifu_pc_vld;

// 我们默认只支持非向量中断模式，因此这里直接使用mtvec寄存器的值作为跳转地址，如果是向量模式，
// 则首先需要进行访存，以获取对应中断id的中断服务程序地址
assign      pipe_flush_pc_op1 = mtvec;
assign      pipe_flush_pc_op2 = 32'd0;


// 我们需要等流水线冲刷请求被接收后才请求修改相应的csr寄存器
assign      cmt_csr = pipe_flush_hsked;
// 对于中断，我们需要将下一条未执行指令的地址保存到mepc中，exu处于流水线的第三级，pc由idu输出，已经
// 执行完成，ifu的输出即为下一条未执行指令的地址
assign      cmt_mepc = ifu_pc;

assign      cmt_mcause[31] = 1'b1;
assign      cmt_mcause[30 : 4] = 27'd0;
assign      cmt_mcause[3 : 0] = sft_irq_masked ? 4'd3 : 
                                tmr_irq_masked ? 4'd7 : 
                                ext_irq_masked ? 4'd11 : 
                                4'd0;


endmodule