module mul_tb;

reg                             clk;
reg                             reset_n;

integer                         in1;
reg                             in1_is_unsigned;
integer                         in2;
reg                             in2_is_unsigned;
reg                             op_vld;
wire                            op_rdy;
wire[63 : 0]                    out;

reg signed [63 : 0]             golden_res;
reg signed [63 : 0]                    golden_res_unsigned;
wire                            calc_error;
wire [63 : 0]                    golden_res_mul_SxS;
wire [63 : 0]                    golden_res_mul_SxU;
wire [63 : 0]                    golden_res_mul_UxS;
wire unsigned[63 : 0]                    golden_res_mul_UxU;


integer                         in1_temp;
integer                         in2_temp;

mul32x32_booth4 u_mul32x32_booth4
(
    .clk                ( clk               ),
    .reset_n            ( reset_n           ),

    .in1                ( in1               ),
    .in1_is_unsigned    ( in1_is_unsigned   ),
    .in2                ( in2               ),
    .in2_is_unsigned    ( in2_is_unsigned   ),
    .out                ( out               ),
    .op_vld             ( op_vld            ),
    .op_rdy             ( op_rdy            )
);

initial begin
    clk = 1'b0;
    reset_n = 1'b0;
    op_vld = 1'b0;
    #100;
    @(posedge clk) begin
        reset_n <= 1'b1;
    end

    #10;
    @(posedge clk) {in1_is_unsigned, in2_is_unsigned} <= 2'b01;
    #100;
    @(posedge clk) op_vld <= 1'b1;
    wait(&{(in1 == 32'd0), (in2==32'd0), op_rdy}) op_vld = 1'b0;

    // wait(&{in1, in2, op_rdy, in1_is_unsigned, in2_is_unsigned});
    $display("Test Finish");
    $finish;
end


always #10 clk = ~clk;


initial begin
    $fsdbDumpfile("mul_tb.fsdb");
    $fsdbDumpvars(0, mul_tb, "+mda");
end


always@(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
        in1 <= 0;
        in2 <= 32'h0000_0000;
    end else begin
        if(~op_vld) begin
            in1 <= 32'h8000_0000;
            in2 <= 32'hffff_8000;
        end else if(op_rdy) begin
            if(in1_is_unsigned) begin
                if((in2_is_unsigned & (in2 == 32'hffff_ffff)) | (~in2_is_unsigned & in2 == 32'd0)) begin
                    in1 <= in1 + 1'b1;
                end
            end else begin
                if((in2_is_unsigned & (in2 == 32'hffff_ffff)) | (~in2_is_unsigned & in2 == 32'd0)) begin
                    in1 <= in1 - 1'b1;
                end
            end

            if(in2_is_unsigned) begin
                in2 <= in2 + 1'b1;
            end else begin
                in2 <= in2 - 1'b1;
            end
        end
    end
end

initial begin
    forever begin
        @(posedge clk) begin
            if(op_rdy) begin
                case({in1_is_unsigned, in2_is_unsigned})
                    2'b00: begin
                        $display("SxS Mode,in1:%d, in2:%d, golden:%d, res:%d", $signed(in1), $signed(in2), $signed(golden_res_mul_SxS), $signed(out));
                        if(out != golden_res_mul_SxS)begin
                            #1000;
                            $finish;
                        end
                    end
                    2'b01: begin
                        $display("SxU Mode,in1:%d, in2:%d, golden:%d, res:%d", $signed(in1), $unsigned(in2), $signed(golden_res_mul_SxU), $signed(out));
                        if(out != golden_res_mul_SxU)begin
                            #1000;
                            $finish;
                        end
                    end
                    2'b10: begin
                        $display("UxS Mode,in1:%d, in2:%d, golden:%d, res:%d", $unsigned(in1), $signed(in2), $signed(golden_res_mul_UxS), $signed(out));
                        if(out != golden_res_mul_UxS)begin
                            #1000;
                            $finish;
                        end
                    end
                    2'b11: begin
                        $display("UXU Mode,in1:%d, in2:%d, golden:%x, res:%x", $unsigned(in1), $unsigned(in2), golden_res_mul_UxU, out);
                        if(out != golden_res_mul_UxU)begin
                            #1000;
                            $finish;
                        end
                    end
                endcase
            end
        end

    end
end

assign      golden_res_mul_SxS = $signed(in1)   * $signed(in2);
assign      golden_res_mul_SxU = $signed(in1)   * $unsigned(in2);
assign      golden_res_mul_UxS = $unsigned(in1) * $signed(in2);
assign      golden_res_mul_UxU = $unsigned(in1) * $unsigned(in2);


assign      golden_res = $signed(in1) * $signed(in2);
assign      golden_res_unsigned = $unsigned(in1) * $signed(in2);
assign      calc_error = golden_res_unsigned != out;
endmodule