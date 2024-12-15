module lnrv_cmt_excp
(
    input[31 : 0]               idu_pc,
    input[31 : 0]               idu_ir,

    // 发生异常，且被接收
    output                      excp_taken,

    input                       cmt_vld,
    input                       cmt_idu_excp_ilglir,
    input                       cmt_ifu_excp_buserr,
    input                       cmt_ifu_excp_misalgn,
    input                       cmt_lsu_ld,
    input                       cmt_lsu_st,
    input                       cmt_lsu_buserr,
    input                       cmt_lsu_misalgn,
    input[31 : 0]               cmt_lsu_addr,
    input                       cmt_sys_ebreak,
    input                       cmt_sys_ecall,
    input                       cmt_csr_idxerr,

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

wire                    lsu_excp_pending;
wire                    idu_excp_pending;
wire                    ifu_excp_pending;
wire                    sys_excp_pending;
wire                    csr_excp_pending;

wire                    any_excp_pending;

wire                    m_mode_ecall;
wire                    u_mode_ecall;
wire                    s_mode_ecall;

wire                    ebreak4excp;

wire                    pipe_flush_hsked;

assign      pipe_flush_hsked = pipe_flush_req & pipe_flush_ack;

// 来自lsu模块的异常
assign      lsu_excp_pending = cmt_lsu_buserr | cmt_lsu_misalgn;

// 来自idu模块的异常
assign      idu_excp_pending = cmt_idu_excp_ilglir;

// 来自取指模块的异常
assign      ifu_excp_pending = cmt_ifu_excp_buserr | cmt_ifu_excp_misalgn;

// 来自sys模块的异常
// 如果在debug mode下，或者dcsr寄存器中的ebreakm位没有置1，则认为ebreak指令仅产生异常，
// 否则将请求进入debug mode
assign      ebreak4excp = (d_mode | (~dcsr_ebreakm)) & cmt_sys_ebreak;
assign      sys_excp_pending = cmt_sys_ecall | ebreak4excp;

assign      csr_excp_pending = cmt_csr_idxerr;

assign      any_excp_pending =  lsu_excp_pending | 
                                idu_excp_pending | 
                                ifu_excp_pending | 
                                sys_excp_pending | 
                                csr_excp_pending | 
                                1'b0;

// 只要有异常发生，就请求冲刷流水线，异常只会在指令交付时有效，所以不需要等待exu idle
assign      pipe_flush_req = cmt_vld & any_excp_pending;

// 如果是ebreak请求debug，则跳转到调试模块基地址，如果是在debug mode中产生异常，
// 则跳转到debug mode中的异常处理程序中
assign      pipe_flush_pc_op1 = d_mode ? 32'h808 : mtvec;
assign      pipe_flush_pc_op2 = 32'd0;


assign      m_mode_ecall = m_mode & cmt_sys_ecall;
assign      u_mode_ecall = 1'b0;//u_mode & sys_excp_ecall;
assign      s_mode_ecall = 1'b0;//s_mode & sys_excp_ecall;
// assign      d_mode_ecall = d_mode & sys_excp_ecall;

// 如果是调试请求，则不需要更新csr寄存器
assign      mepc_wdata = idu_pc;

assign      mcause_wdata[31] = 1'b0;
assign      mcause_wdata[30 : 4] = 27'd0;
assign      mcause_wdata[3 : 0] =   cmt_ifu_excp_misalgn ? 4'd0 : 
                                    cmt_ifu_excp_buserr ? 4'd1 : 
                                    (cmt_idu_excp_ilglir | cmt_csr_idxerr) ? 4'd2 : 
                                    ebreak4excp ? 4'd3 : 
                                    (cmt_lsu_ld & cmt_lsu_misalgn) ? 4'd4 :
                                    (cmt_lsu_ld & cmt_lsu_buserr) ? 4'd5 : 
                                    (cmt_lsu_st & cmt_lsu_misalgn) ? 4'd6 : 
                                    (cmt_lsu_st & cmt_lsu_buserr) ? 4'd7 : 
                                    u_mode_ecall ? 4'd8 : 
                                    s_mode_ecall ? 4'd9 :
                                    m_mode_ecall ? 4'd11 : 
                                    4'd14;
// 对于异常，还需要更新mtval寄存器，
// 如果是取指时发生错误，则将错误更新到mtval寄存器
// 如果是译码时发现是非法指令，则将指令本身更新到mtval寄存器
assign      mtval_wdata =   (cmt_ifu_excp_buserr | cmt_ifu_excp_misalgn) ? idu_pc : 
                            (cmt_idu_excp_ilglir | cmt_csr_idxerr) ? idu_ir : 
                            lsu_excp_pending ? cmt_lsu_addr : 
                            32'd0;

assign      excp_taken = pipe_flush_hsked;

endmodule //lnrv_exu_excp
