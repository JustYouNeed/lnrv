module  lnrv_gnrl_arbiter#
(
    parameter   integer         P_ARBT_NUM = 4,
    parameter                   P_ARBT_TYPE = "round-robin"
)
(
    input[P_ARBT_NUM - 1 : 0]   request,
    output[P_ARBT_NUM - 1 : 0]  grant,

    input                       clk,
    input                       reset_n
);


reg[P_ARBT_NUM - 1 : 0]         pointer_q;
wire                            pointer_rld;
wire[P_ARBT_NUM - 1 : 0]        pointer_d;

wire[P_ARBT_NUM - 1 : 0]        request_vld;

wire[P_ARBT_NUM - 1 : 0]        masked_request;
wire[P_ARBT_NUM - 1 : 0]        mask_hp_request;
wire[P_ARBT_NUM - 1 : 0]        masked_grant;

wire[P_ARBT_NUM - 1 : 0]        unmasked_request;
wire[P_ARBT_NUM - 1 : 0]        unmask_hp_request;
wire[P_ARBT_NUM - 1 : 0]        unmask_grant;

// 如果已经有一个通道赢得了仲裁，则下一个请求需要等当前请求撤销后才可以处理
assign      request_vld = request;

assign      masked_request = pointer_q & request_vld;
assign      mask_hp_request = {mask_hp_request[P_ARBT_NUM - 2 : 0] | masked_request[P_ARBT_NUM - 2 : 0], 1'b0};
assign      masked_grant = masked_request & (~mask_hp_request);


assign      unmasked_request = request_vld;
assign      unmask_hp_request = {unmask_hp_request[P_ARBT_NUM - 2 : 0] | unmasked_request[P_ARBT_NUM - 2 : 0], 1'b0};
assign      unmask_grant = unmasked_request & (~unmask_hp_request);


assign      grant = ({P_ARBT_NUM{~|masked_request}} & unmask_grant) | masked_grant;

assign      pointer_rld = (|masked_request) | (|request);
assign      pointer_d = (|masked_request) ? mask_hp_request : unmask_hp_request;
always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        pointer_q <= {P_ARBT_NUM{1'b1}};
    end else if(pointer_rld) begin
        pointer_q <= pointer_d;
    end
end

endmodule