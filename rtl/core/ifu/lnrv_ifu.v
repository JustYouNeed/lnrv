// `include    "lnrv_config.v"
`include    "lnrv_def.v"
module	lnrv_ifu
(
    input                               clk,
    input                               reset_n,

    output                              ifu_active,

    // 复位向量
    input[31 : 0]                       reset_vector,

    // 流水线冲刷请求
    input                               pipe_flush_req,
    output                              pipe_flush_ack,
    input[31 : 0]                       pipe_flush_pc_op1,
    input[31 : 0]                       pipe_flush_pc_op2,

    // 流水线暂停请求
    input                               pipe_halt_req,
    output                              pipe_halt_ack,
        
    // 输出至EXU模块
    output                              ifu_ir_vld,
    input                               ifu_ir_rdy,
    output[31 : 0]                      ifu_pc,         // pc寄存器
    output[31 : 0]                      ifu_ir,         // instruction寄存器
    output                              ifu_misalgn,
    output                              ifu_buserr,

    output                              ifu_cmd_vld,
    input                               ifu_cmd_rdy,
    output                              ifu_cmd_write,
    output[31 : 0]                      ifu_cmd_addr,
    output[31 : 0]                      ifu_cmd_wdata,
    output[3 : 0]                       ifu_cmd_wstrb,
    input                               ifu_rsp_vld,
    output                              ifu_rsp_rdy,
    input[31 : 0]                       ifu_rsp_rdata,
    input                               ifu_rsp_err
);


wire                        bpu_prdt_taken;
wire[31 : 0]                bpu_prdt_pc_op1;
wire[31 : 0]                bpu_prdt_pc_op2;
wire[31 : 0]                bpu_prdt_ir;


// 暂时没有分支预测功能
assign      bpu_prdt_taken = 1'b0;
assign      bpu_prdt_pc_op1 = 32'd0;
assign      bpu_prdt_pc_op2 = 32'd0;

// 取指模块 
lnrv_ifu_ifetch u_lnrv_ifu_ifetch
(
    .reset_vector           ( reset_vector              ),
            
    .pipe_flush_req         ( pipe_flush_req            ),
    .pipe_flush_ack         ( pipe_flush_ack            ),
    .pipe_flush_pc_op1      ( pipe_flush_pc_op1         ),
    .pipe_flush_pc_op2      ( pipe_flush_pc_op2         ),
    .pipe_halt_req          ( pipe_halt_req             ),
    .pipe_halt_ack          ( pipe_halt_ack             ),
    
    .ifu_ir_vld             ( ifu_ir_vld                ),
    .ifu_ir_rdy             ( ifu_ir_rdy                ),
    .ifu_pc                 ( ifu_pc                    ),
    .ifu_ir                 ( ifu_ir                    ),
    .ifu_misalgn            ( ifu_misalgn               ),
    .ifu_buserr             ( ifu_buserr                ),

    .bpu_prdt_taken         ( bpu_prdt_taken            ),
    .bpu_prdt_pc_op1        ( bpu_prdt_pc_op1           ),
    .bpu_prdt_pc_op2        ( bpu_prdt_pc_op2           ),
    .bpu_prdt_ir            ( bpu_prdt_ir               ),
    
    .ifu_cmd_vld            ( ifu_cmd_vld               ),
    .ifu_cmd_rdy            ( ifu_cmd_rdy               ),
    .ifu_cmd_write          ( ifu_cmd_write             ),
    .ifu_cmd_addr           ( ifu_cmd_addr              ),
    .ifu_cmd_wdata          ( ifu_cmd_wdata             ),
    .ifu_cmd_wstrb          ( ifu_cmd_wstrb             ),
    .ifu_rsp_vld            ( ifu_rsp_vld               ),
    .ifu_rsp_rdy            ( ifu_rsp_rdy               ),
    .ifu_rsp_rdata          ( ifu_rsp_rdata             ),
    .ifu_rsp_err            ( ifu_rsp_err               ),

    .clk                    ( clk                       ),
    .reset_n                ( reset_n                   )
);


assign      ifu_active = 1'b1;

endmodule