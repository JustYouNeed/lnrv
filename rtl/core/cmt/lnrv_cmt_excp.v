module lnrv_cmt_excp
(
    input[31 : 0]               exu_pc,
    input[31 : 0]               exu_ir,

    output                      excp_taken,

    // 来自前级模块的异常
    input                       idu_excp_ilgl_ir,       // 非法指令
    input                       ifu_excp_buserr,             // 取指总线错误
    input                       ifu_excp_misalgn,            // 取指地址非对齐

    // 来自lsu模块的异常，包括:
    // 1、非对齐访问
    // 2、总线错误
    input                       lsu_excp_ld_misalgn,
    input                       lsu_excp_ld_buserr,
    input                       lsu_excp_st_misalgn,
    input                       lsu_excp_st_buserr,
    input[31 : 0]               lsu_excp_addr,

    // 来自sys指令处理模块的异常，主要为ecall以及ebreak
    input                       sys_excp_ecall,
    input                       sys_excp_ebreak,

    // CSR指令操作不存在的CSR寄存器时发生异常
    input                       csr_excp_idxerr,

    output[31 : 0]              mepc_wdata,
    output[31 : 0]              mcause_wdata,
    output[31 : 0]              mtval_wdata,

    input                       m_mode,
    input                       d_mode,

    // 该寄存器用于设置ebreak指令用途
    // 0:产生异常
    // 1:进入debug mode
    input                       dcsr_ebreakm,

    // 
    input[31 : 0]               mtvec,

    // 请求冲刷流水线
    output                      pipe_flush_req,
    input                       pipe_flush_ack,
    output[31 : 0]              pipe_flush_pc_op1,
    output[31 : 0]              pipe_flush_pc_op2,


    input                       clk,
    input                       reset_n
);

wire                    lsu_excp_taken;
wire                    idu_excp_taken;
wire                    ifu_excp_taken;
wire                    sys_excp_taken;
wire                    csr_excp_taken;

wire                    any_excp_taken;

wire                    m_mode_ecall;
wire                    u_mode_ecall;
wire                    s_mode_ecall;

wire                    ebreak4excp;

// wire                    pipe_flush_hsked;

// assign      pipe_flush_hsked = pipe_flush_req & pipe_flush_ack;

// 来自lsu模块的异常
assign      lsu_excp_taken =    lsu_excp_ld_misalgn | 
                                lsu_excp_ld_buserr | 
                                lsu_excp_st_misalgn | 
                                lsu_excp_st_buserr;

// 来自idu模块的异常
assign      idu_excp_taken =    idu_excp_ilgl_ir;

assign      ifu_excp_taken =    ifu_excp_buserr | 
                                ifu_excp_misalgn;

// 来自sys模块的异常
// 如果在debug mode下，或者dcsr寄存器中的ebreakm位没有置1，则认为ebreak指令仅产生异常，
// 否则将请求进入debug mode
assign      ebreak4excp = (dbg_mode | (~dcsr_ebreakm)) & sys_excp_ebreak;
assign      sys_excp_taken = sys_excp_ecall | ebreak4excp;

assign      csr_excp_taken = csr_excp_idxerr;

assign      any_excp_taken =    lsu_excp_taken | 
                                idu_excp_taken | 
                                ifu_excp_taken | 
                                sys_excp_taken | 
                                csr_excp_taken | 
                                1'b0;

// 只要有异常发生，就请求冲刷流水线，异常只会在指令交付时有效，所以不需要等待exu idle
assign      pipe_flush_req = 1'b1 & any_excp_taken;

// 如果是ebreak请求debug，则跳转到调试模块基地址，如果是在debug mode中产生异常，
// 则跳转到debug mode中的异常处理程序中
assign      pipe_flush_pc_op1 = d_mode ? 32'h808 : mtvec;
assign      pipe_flush_pc_op2 = 32'd0;


assign      m_mode_ecall = m_mode & sys_excp_ecall;
assign      u_mode_ecall = 1'b0;//u_mode & sys_excp_ecall;
assign      s_mode_ecall = 1'b0;//s_mode & sys_excp_ecall;
// assign      d_mode_ecall = d_mode & sys_excp_ecall;

// 如果是调试请求，则不需要更新csr寄存器
assign      mepc_wdata = exu_pc;

assign      mcause_wdata[31] = 1'b0;
assign      mcause_wdata[30 : 4] = 27'd0;
assign      mcause_wdata[3 : 0] =   ifu_excp_misalgn ? 4'd0 : 
                                    ifu_excp_buserr ? 4'd1 : 
                                    (idu_excp_ilgl_ir | csr_excp_idxerr) ? 4'd2 : 
                                    ebreak4excp ? 4'd3 : 
                                    lsu_excp_ld_misalgn ? 4'd4 :
                                    lsu_excp_ld_buserr ? 4'd5 : 
                                    lsu_excp_st_misalgn ? 4'd6 : 
                                    lsu_excp_st_buserr ? 4'd7 : 
                                    u_mode_ecall ? 4'd8 : 
                                    s_mode_ecall ? 4'd9 :
                                    m_mode_ecall ? 4'd11 : 
                                    4'd14;
// 对于异常，还需要更新mtval寄存器，
// 如果是取指时发生错误，则将错误更新到mtval寄存器
// 如果是译码时发现是非法指令，则将指令本身更新到mtval寄存器
assign      mtval_wdata =   (dec_ifu_buserr | dec_ifu_misalgn) ? exu_pc : 
                            dec_idu_ilegal_instr ? exu_ir : 
                            lsu_excp_taken ? lsu_bad_addr : 
                            32'd0;

endmodule //lnrv_exu_excp
