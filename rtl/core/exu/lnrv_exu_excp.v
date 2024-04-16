module lnrv_exu_excp
(
    // 来自前级模块的异常
    input               dec_excp_vld,
    output              dec_excp_rdy,
    // 非法指令
    input               dec_idu_ilegal_instr,
    // 取指总线错误
    input               dec_ifu_bus_err,
    // 取指地址非对齐
    input               dec_ifu_addr_misalgn,

    // 来自lsu模块的异常，包括:
    // 1、非对齐访问
    // 2、总线错误
    input               lsu_excp_vld,
    output              lsu_excp_rdy,
    input               lsu_ld_addr_misalgn,
    input               lsu_ld_access_fault,
    input               lsu_st_addr_misalgn,
    input               lsu_st_access_fault,
    input[31 : 0]       lsu_bad_addr,

    // 来自sys指令处理模块的异常，主要为ecall以及ebreak
    input               sys_excp_vld,
    output              sys_excp_rdy,
    input               sys_excp_ecall,
    input               sys_excp_ebreak,

    // 在发生异常的情况下，需要修改几个csr寄存器
    output              cmt_mcsr_vld,
    output[31 : 0]      cmt_mepc,
    output[31 : 0]      cmt_mcause,
    output[31 : 0]      cmt_mtval,

    // 如果ebreak指令是用于进入debug mode，还需要修改dcsr寄存器
    output              cmt_dcsr_vld,
    output[31 : 0]      cmt_dpc,
    output[2 : 0]       cmt_dcause,

    input[31 : 0]       pc,
    input[31 : 0]       ir,

    input               m_mode,
    input               d_mode,

    // 该寄存器用于设置ebreak指令用途
    // 0:产生异常
    // 1:进入debug mode
    input               dcsr_ebreakm,

    // 
    input[31 : 0]       mtvec,

    // 请求冲刷流水线
    output              excp_pipe_flush_req,
    input               excp_pipe_flush_ack,
    output[31 : 0]      excp_pipe_flush_pc_op1,
    output[31 : 0]      excp_pipe_flush_pc_op2,


    input               clk,
    input               reset_n
);


wire                    lsu_excp_taken;
wire                    idu_excp_taken;
wire                    sys_excp_taken;
wire                    excp_taken;

wire                    m_mode_ecall;
wire                    u_mode_ecall;
wire                    s_mode_ecall;

wire                    not_in_debug_mode;
wire                    ebreak4excp;
wire                    ebreak4debug;

wire                    pipe_flush_hsked;

assign      not_in_debug_mode = ~d_mode;
assign      pipe_flush_hsked = excp_pipe_flush_req & excp_pipe_flush_ack;

// 来自lsu模块的异常
assign      lsu_excp_taken =    lsu_excp_vld & 
                                (
                                    lsu_ld_access_fault | 
                                    lsu_ld_addr_misalgn | 
                                    lsu_st_access_fault | 
                                    lsu_st_addr_misalgn
                                );

// 来自idu模块的异常
assign      dec_excp_taken =    dec_excp_vld & 
                                (
                                    dec_idu_ilegal_instr | 
                                    dec_ifu_bus_err | 
                                    dec_ifu_addr_misalgn
                                );

// 来自sys模块的异常
assign      sys_excp_taken =    sys_excp_vld & 
                                (
                                    sys_excp_ecall | 
                                    sys_excp_ebreak
                                );

// 如果在debug mode下，或者dcsr寄存器中的ebreakm位没有置1，则认为ebreak指令仅产生异常，
// 否则将请求进入debug mode
assign      ebreak4excp =   sys_excp_ebreak & 
                            (
                                (~dcsr_ebreakm) | 
                                d_mode
                            );

// ebreak指令用于进入debug mode
assign      ebreak4debug =  sys_excp_ebreak & 
                            not_in_debug_mode & 
                            dcsr_ebreakm;

assign      excp_taken =    lsu_excp_taken | 
                            idu_excp_taken | 
                            sys_excp_taken;

// 各个异常的优先级如下:
//      1、idu
//      2、lsu
//      3、sys
// 实际上由于lnrv是顺序单发射处理器，这些异常不可能同时发生，所以也可以不区分优先级
assign      idu_excp_rdy = idu_excp_taken & excp_pipe_flush_ack;

assign      lsu_excp_rdy =  (idu_excp_taken) ? 1'b0 : 
                            lsu_excp_taken & excp_pipe_flush_ack;

assign      sys_excp_rdy =  (idu_excp_taken | lsu_excp_taken) ? 1'b0 : 
                            sys_excp_taken & excp_pipe_flush_ack;


assign      m_mode_ecall = m_mode & sys_excp_ecall;
assign      u_mode_ecall = 1'b0;//u_mode & sys_excp_ecall;
assign      s_mode_ecall = 1'b0;//s_mode & sys_excp_ecall;
// assign      d_mode_ecall = d_mode & sys_excp_ecall;

// 如果是调试请求，则不需要更新csr寄存器
assign      cmt_mcsr_vld = pipe_flush_hsked & (~ebreak4debug);
assign      cmt_mepc = pc;
assign      cmt_mcause[31] = 1'b0;
assign      cmt_mcause[30 : 4] = 27'd0;
assign      cmt_mcause[3 : 0] = dec_ifu_addr_misalgn ? 4'd0 : 
                                dec_ifu_addr_misalgn ? 4'd1 : 
                                dec_idu_ilegal_instr ? 4'd2 : 
                                lsu_ld_addr_misalgn ? 4'd4 :
                                lsu_ld_access_fault ? 4'd5 : 
                                lsu_st_addr_misalgn ? 4'd6 : 
                                lsu_st_access_fault ? 4'd7 : 
                                u_mode_ecall ? 4'd8 : 
                                s_mode_ecall ? 4'd9 :
                                m_mode_ecall ? 4'd11 : 
                                4'd14;
// 对于异常，还需要更新mtval寄存器，
// 如果是取指时发生错误，则将错误更新到mtval寄存器
// 如果是译码时发现是非法指令，则将指令本身更新到mtval寄存器
assign      cmt_mtval = (dec_ifu_bus_err | dec_ifu_addr_misalgn) ? pc : 
                        dec_idu_ilegal_instr ? ir : 
                        lsu_excp_taken ? lsu_bad_addr : 
                        32'd0;

// 只要有异常发生，就请求冲刷流水线
assign      excp_pipe_flush_req = excp_taken;

// 如果是ebreak请求debug，则跳转到调试模块基地址，如果是在debug mode中产生异常，
// 则跳转到debug mode中的异常处理程序中
assign      excp_pipe_flush_pc_op1 = ebreak4debug ? 32'h800 : 
                                d_mode ? 32'h808 : 
                                mtvec;
assign      excp_pipe_flush_pc_op2 = 32'd0;


// 对于异常，只有ebreak指令会请求处理器进入debug mode，在调试结束后，
// debugger会修改ebreak指令回正常指令，因此需要保存ebreak指令本身的pc值
assign      cmt_dcsr_vld = ebreak4debug & pipe_flush_hsked;
assign      cmt_dpc = pc;
assign      cmt_dcause = 3'd2;

endmodule //lnrv_exu_excp
