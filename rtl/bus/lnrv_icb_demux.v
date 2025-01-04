module lnrv_icb_demux#
(
    parameter                                           P_ADDR_WIDTH = 32,
    parameter                                           P_DATA_WIDTH = 32,
    parameter                                           P_ICB_COUNT = 4,

    // 是否在master通路上插入一个buffer，可以优化时序
    parameter                                           P_CMD_BUFF_ENABLE = "true",
    parameter                                           P_CMD_BUFF_CUT_READY = "true",
    parameter                                           P_CMD_BUFF_BYPASS = "false",

    parameter                                           P_RSP_BUFF_ENABLE = "true",
    parameter                                           P_RSP_BUFF_CUT_READY = "true",
    parameter                                           P_RSP_BUFF_BYPASS = "false",

    parameter                                           P_OTS_COUNT = 1
)
(
    input                                               clk,
    input                                               reset_n,

    // master
    input                                               icb_cmd_vld_m,
    output                                              icb_cmd_rdy_m,
    input                                               icb_cmd_write_m,
    input[P_ADDR_WIDTH - 1 : 0]                         icb_cmd_addr_m,
    input[P_DATA_WIDTH - 1 : 0]                         icb_cmd_wdata_m,
    input[(P_DATA_WIDTH/8) - 1 : 0]                     icb_cmd_wstrb_m,
    input[2 : 0]                                        icb_cmd_size_m,
    input                                               icb_rsp_rdy_m,
    output                                              icb_rsp_vld_m,
    output[P_DATA_WIDTH - 1 : 0]                        icb_rsp_rdata_m,
    output                                              icb_rsp_err_m,

    // slave
    output[P_ICB_COUNT - 1 : 0]                         icb_cmd_vld_sn,
    input[P_ICB_COUNT - 1 : 0]                          icb_cmd_rdy_sn,
    output[P_ICB_COUNT - 1 : 0]                         icb_cmd_write_sn,
    output[(P_ADDR_WIDTH * P_ICB_COUNT) - 1 : 0]        icb_cmd_addr_sn,
    output[(P_DATA_WIDTH * P_ICB_COUNT) - 1 : 0]        icb_cmd_wdata_sn,
    output[((P_DATA_WIDTH/8) * P_ICB_COUNT) - 1 : 0]    icb_cmd_wstrb_sn,
    output[(P_ICB_COUNT * 3) - 1 : 0]                   icb_cmd_size_sn,
    input[P_ICB_COUNT - 1 : 0]                          icb_rsp_vld_sn,
    output[P_ICB_COUNT - 1 : 0]                         icb_rsp_rdy_sn,
    input[(P_DATA_WIDTH * P_ICB_COUNT) - 1 : 0]         icb_rsp_rdata_sn,
    input[P_ICB_COUNT - 1 : 0]                          icb_rsp_err_sn,

    // 地址指示
    input[(P_ADDR_WIDTH * P_ICB_COUNT) - 1 : 0]         sn_region_base,
    input[(P_ADDR_WIDTH * P_ICB_COUNT) - 1 : 0]         sn_region_end
);

localparam                                  LP_DISP_BUF_DATA_WIDTH = P_ICB_COUNT;

wire[LP_DISP_BUF_DATA_WIDTH - 1 : 0]        disp_buf_push_data;
wire                                        disp_buf_push_vld;
wire                                        disp_buf_push_rdy;

wire[LP_DISP_BUF_DATA_WIDTH - 1 : 0]        disp_buf_pop_data;
wire                                        disp_buf_pop_vld;
wire                                        disp_buf_pop_rdy;

wire                                        icb_cmd_vld_bufed_m;
wire                                        icb_cmd_rdy_bufed_m;
wire                                        icb_cmd_write_bufed_m;
wire[P_ADDR_WIDTH - 1 : 0]                  icb_cmd_addr_bufed_m;
wire[P_DATA_WIDTH - 1 : 0]                  icb_cmd_wdata_bufed_m;
wire[(P_DATA_WIDTH/8) - 1 : 0]              icb_cmd_wstrb_bufed_m;
wire[2 : 0]                                 icb_cmd_size_bufed_m;

wire                                        icb_rsp_vld_bufed_m;
wire                                        icb_rsp_rdy_bufed_m;
wire[P_DATA_WIDTH - 1 : 0]                  icb_rsp_rdata_bufed_m;
wire                                        icb_rsp_err_bufed_m;


wire[P_ICB_COUNT - 1 : 0]                   icb_cmd_vld_slv;
wire[P_ICB_COUNT - 1 : 0]                   icb_cmd_rdy_slv;
wire[P_ICB_COUNT - 1 : 0]                   icb_cmd_write_slv;
wire[P_ADDR_WIDTH - 1 : 0]                  icb_cmd_addr_slv[P_ICB_COUNT - 1 : 0];
wire[P_DATA_WIDTH - 1 : 0]                  icb_cmd_wdata_slv[P_ICB_COUNT - 1 : 0];
wire[(P_DATA_WIDTH/8) - 1 : 0]              icb_cmd_wstrb_slv[P_ICB_COUNT - 1 : 0];
wire[2 : 0]                                 icb_cmd_size_slv[P_ICB_COUNT - 1 : 0];
wire[P_ICB_COUNT - 1 : 0]                   icb_rsp_vld_slv;
wire[P_ICB_COUNT - 1 : 0]                   icb_rsp_rdy_slv;
wire[P_DATA_WIDTH - 1 : 0]                  icb_rsp_rdata_slv[P_ICB_COUNT - 1 : 0];
wire[P_ICB_COUNT - 1 : 0]                   icb_rsp_err_slv;

wire[P_ADDR_WIDTH - 1 : 0]                  slv_region_start_addr[P_ICB_COUNT - 1 : 0];
wire[P_ADDR_WIDTH - 1 : 0]                  slv_region_end_addr[P_ICB_COUNT - 1 : 0];
wire[P_ICB_COUNT - 1 : 0]                   slv_region_match;
wire[P_ICB_COUNT - 1 : 0]                   slv_region_match_bufed;

wire[P_ICB_COUNT - 1 : 0]                   addr_gte_start_addr;
wire[P_ICB_COUNT - 1 : 0]                   addr_ls_end_addr;
wire[P_ICB_COUNT - 1 : 0]                   end_addr_is_zero;

wire                                        no_region_match;
wire                                        no_region_match_bufed;


wire                                        icb_cmd_rdy_mux_m;
wire                                        icb_rsp_vld_mux_m;
reg[P_DATA_WIDTH - 1 : 0]                   icb_rsp_rdata_mux_m;
reg                                         icb_rsp_err_mux_m;

wire                                        icb_cmd_hsked_m;
wire                                        icb_rsp_hsked_m;

genvar                                      i;
integer                                     j;


assign      icb_cmd_hsked_m = icb_cmd_vld_m & icb_cmd_rdy_m;
assign      icb_rsp_hsked_m = icb_rsp_vld_m & icb_rsp_rdy_m;

// 根据参数决定是否需要在输入端口插入一个buff
lnrv_icb_buf#
(
    .P_ADDR_WIDTH           ( P_ADDR_WIDTH              ),
    .P_DATA_WIDTH           ( P_DATA_WIDTH              ),

    .P_CMD_BUFF_ENABLE      ( P_CMD_BUFF_ENABLE         ),
    .P_CMD_BUFF_CUT_READY   ( P_CMD_BUFF_CUT_READY      ),
    .P_CMD_BUFF_BYPASS      ( P_CMD_BUFF_BYPASS         ),

    .P_RSP_BUFF_ENABLE      ( P_RSP_BUFF_ENABLE         ),
    .P_RSP_BUFF_CUT_READY   ( P_RSP_BUFF_CUT_READY      ),
    .P_RSP_BUFF_BYPASS      ( P_RSP_BUFF_BYPASS         ),

    .P_OTS_COUNT            ( P_OTS_COUNT               )
)
u_lnrv_icb_buf
(
    .icb_cmd_vld_m          ( icb_cmd_vld_m             ),
    .icb_cmd_rdy_m          ( icb_cmd_rdy_m             ),
    .icb_cmd_write_m        ( icb_cmd_write_m           ),
    .icb_cmd_addr_m         ( icb_cmd_addr_m            ),
    .icb_cmd_wdata_m        ( icb_cmd_wdata_m           ),
    .icb_cmd_wstrb_m        ( icb_cmd_wstrb_m           ),
    .icb_cmd_size_m         ( icb_cmd_size_m            ),
    .icb_rsp_vld_m          ( icb_rsp_vld_m             ),
    .icb_rsp_rdy_m          ( icb_rsp_rdy_m             ),
    .icb_rsp_rdata_m        ( icb_rsp_rdata_m           ),
    .icb_rsp_err_m          ( icb_rsp_err_m             ),

    .icb_cmd_vld_s          ( icb_cmd_vld_bufed_m       ),
    .icb_cmd_rdy_s          ( icb_cmd_rdy_bufed_m       ),
    .icb_cmd_write_s        ( icb_cmd_write_bufed_m     ),
    .icb_cmd_addr_s         ( icb_cmd_addr_bufed_m      ),
    .icb_cmd_wdata_s        ( icb_cmd_wdata_bufed_m     ),
    .icb_cmd_wstrb_s        ( icb_cmd_wstrb_bufed_m     ),
    .icb_cmd_size_s         ( icb_cmd_size_bufed_m      ),
    .icb_rsp_vld_s          ( icb_rsp_vld_bufed_m       ),
    .icb_rsp_rdy_s          ( icb_rsp_rdy_bufed_m       ),
    .icb_rsp_rdata_s        ( icb_rsp_rdata_bufed_m     ),
    .icb_rsp_err_s          ( icb_rsp_err_bufed_m       ),

    .clk                    ( clk                       ),
    .reset_n                ( reset_n                   )
);

// 指令通道握手成功后，将当前选择的通道信息推入disp_fifo中
assign      disp_buf_push_vld   = icb_cmd_hsked_m;
assign      disp_buf_push_data  = slv_region_match;

assign      no_region_match = ~(|slv_region_match);

// 应答通道握手成功，表示已经完成一次通信，将保存的通道信息弹出
assign      disp_buf_pop_rdy        = icb_rsp_hsked_m;
assign      slv_region_match_bufed  = disp_buf_pop_data;
assign      no_region_match_bufed = ~(|slv_region_match_bufed);

// 将分发信息保存下来，用于rsp通道
lnrv_gnrl_buffer#
(
    .P_DATA_WIDTH       ( LP_DISP_BUF_DATA_WIDTH    ),
    .P_DEEPTH           ( P_OTS_COUNT               ),
    .P_CUT_READY        ( "false"                   ),
    .P_BYPASS           ( "true"                    )
)
u_icb_disp_buf
(
    .clk                ( clk                       ),
    .reset_n            ( reset_n                   ),

    .flush_req          ( 1'b0                      ),
    .flush_ack          (                           ),

    .push_vld           ( disp_buf_push_vld         ),
    .push_rdy           ( disp_buf_push_rdy         ),
    .push_data          ( disp_buf_push_data        ),

    .pop_vld            ( disp_buf_pop_vld          ),
    .pop_rdy            ( disp_buf_pop_rdy          ),
    .pop_data           ( disp_buf_pop_data         )
);

 // 分离出各个地址区间的base和mask信息，进行匹配
generate
    for(i = 0; i < P_ICB_COUNT; i = i + 1) begin
        assign      slv_region_start_addr[i]    = sn_region_base[i * P_ADDR_WIDTH +: P_ADDR_WIDTH];
        assign      slv_region_end_addr[i]      = sn_region_end[i * P_ADDR_WIDTH +: P_ADDR_WIDTH];

        assign      addr_gte_start_addr[i]      = (icb_cmd_addr_bufed_m >= slv_region_start_addr[i]);
        assign      addr_ls_end_addr[i]         = (icb_cmd_addr_bufed_m < slv_region_end_addr[i]);
        assign      end_addr_is_zero[i]         = ~(|slv_region_end_addr[i]);
    end


    for(i = 0; i < P_ICB_COUNT - 1; i = i + 1) begin
        assign      slv_region_match[i] = addr_gte_start_addr[i] & addr_ls_end_addr[i];
    end

    // 最后一个通道的匹配规则不一样，如果结束地址为0，则不需要进行匹配，没有选中其他通道时，默认选中最后一个通道
    // 如果最后一个通道的结束地址不为0，则正常进行匹配
    assign      slv_region_match[P_ICB_COUNT - 1] = (~|(slv_region_match[P_ICB_COUNT - 2 : 0]));
endgenerate

// 根据地址匹配，进行分发
generate
    // 分离slave port
    for(i = 0; i < P_ICB_COUNT; i = i + 1) begin
        assign      icb_cmd_vld_slv[i]      = slv_region_match[i] & icb_cmd_vld_bufed_m;
        assign      icb_cmd_write_slv[i]    = slv_region_match[i] & icb_cmd_write_bufed_m;
        assign      icb_cmd_addr_slv[i]     = {P_ADDR_WIDTH{slv_region_match[i]}} & icb_cmd_addr_bufed_m;
        assign      icb_cmd_wdata_slv[i]    = {P_DATA_WIDTH{slv_region_match[i]}} & icb_cmd_wdata_bufed_m;
        assign      icb_cmd_wstrb_slv[i]    = {(P_DATA_WIDTH/8){slv_region_match[i]}} & icb_cmd_wstrb_bufed_m;
        assign      icb_cmd_size_slv[i]     = {3{slv_region_match[i]}} & icb_cmd_size_bufed_m;
        assign      icb_cmd_rdy_slv[i]      = slv_region_match[i] & icb_cmd_rdy_sn[i];

        assign      icb_rsp_rdy_slv[i]      = slv_region_match_bufed[i] & icb_rsp_rdy_bufed_m;
        assign      icb_rsp_vld_slv[i]      = slv_region_match_bufed[i] & icb_rsp_vld_sn[i];
        assign      icb_rsp_rdata_slv[i]    = {P_DATA_WIDTH{slv_region_match_bufed[i]}} & icb_rsp_rdata_sn[i * P_DATA_WIDTH +: P_DATA_WIDTH];
        assign      icb_rsp_err_slv[i]      = slv_region_match_bufed[i] & icb_rsp_err_sn[i];
    end

    for(i = 0; i < P_ICB_COUNT; i = i + 1) begin
        assign      icb_cmd_vld_sn[i]                                           = icb_cmd_vld_slv[i];
        assign      icb_cmd_addr_sn[i * P_ADDR_WIDTH +: P_ADDR_WIDTH]           = icb_cmd_addr_slv[i];
        assign      icb_cmd_write_sn[i]                                         = icb_cmd_write_slv[i];
        assign      icb_cmd_wdata_sn[i * P_DATA_WIDTH +: P_DATA_WIDTH]          = icb_cmd_wdata_slv[i];
        assign      icb_cmd_wstrb_sn[i * (P_DATA_WIDTH/8) +: (P_DATA_WIDTH/8)]  = icb_cmd_wstrb_slv[i];
        assign      icb_cmd_size_sn[i * 3 +: 3]                                 = icb_cmd_size_slv[i];

        assign      icb_rsp_rdy_sn[i] = icb_rsp_rdy_slv[i];
    end
endgenerate



// 从slave中选中一个数据
assign      icb_cmd_rdy_mux_m = |{icb_cmd_rdy_slv};
assign      icb_rsp_vld_mux_m = |{icb_rsp_vld_slv};
generate
    always@(*) begin
        icb_rsp_rdata_mux_m = {P_DATA_WIDTH{1'b0}};
        icb_rsp_err_mux_m = 1'b0;

        // 从slave中选出rsp
        for(j = 0; j < P_ICB_COUNT; j = j + 1) begin
            icb_rsp_rdata_mux_m     = icb_rsp_rdata_mux_m | icb_rsp_rdata_slv[j];
            icb_rsp_err_mux_m       = icb_rsp_err_mux_m | icb_rsp_err_slv[j];
        end
    end
endgenerate


// 如果没有匹配到任一地址区间，则立即回rdy
assign      icb_cmd_rdy_bufed_m = no_region_match ? icb_cmd_vld_m : icb_cmd_rdy_mux_m;

assign      icb_rsp_vld_bufed_m = no_region_match_bufed ? disp_buf_pop_vld : icb_rsp_vld_mux_m;
assign      icb_rsp_err_bufed_m = icb_rsp_err_mux_m | no_region_match_bufed;
assign      icb_rsp_rdata_bufed_m = icb_rsp_rdata_mux_m;


endmodule //lnrv_icb_demux
