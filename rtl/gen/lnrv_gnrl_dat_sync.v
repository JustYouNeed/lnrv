module lnrv_gnrl_dat_sync#
(
    parameter                           P_SYNC_STAGE = 2,
    parameter                           P_DATA_WIDTH = 1,
    parameter                           P_RESET_VALUE = 1'b0
)
(
    input[P_DATA_WIDTH - 1 : 0]         async_data,

    input                               sync_clk,
    input                               sync_rst_n,
    output[P_DATA_WIDTH - 1 : 0]        sync_data
);


reg[P_DATA_WIDTH - 1 : 0]               data_buf_q[P_SYNC_STAGE - 1 : 0];
wire[P_DATA_WIDTH - 1 : 0]              data_buf_d[P_SYNC_STAGE - 1 : 0];

genvar                                  i;

generate
    for(i = 0; i < P_SYNC_STAGE; i = i + 1) begin: GEN_SYNC_DATA_BUF
        if(i == 0) begin: FIRST_SYNC_STAGE
            assign      data_buf_d[i] = async_data;
        end else begin: OTHER_SYNC_STAGE
            assign      data_buf_d[i] = data_buf_q[i - 1];
        end

        always@(posedge sync_clk or negedge sync_rst_n) begin
            if(sync_rst_n == 1'b0) begin
                data_buf_q[i] <= P_RESET_VALUE[0 +: P_DATA_WIDTH];
            end else begin
                data_buf_q[i] <= data_buf_d[i];
            end
        end
    end
endgenerate


assign      sync_data = data_buf_q[P_SYNC_STAGE - 1];

endmodule