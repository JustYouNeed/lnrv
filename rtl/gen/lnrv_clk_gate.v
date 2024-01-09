module  lnrv_clk_gate
(
    input           clk_in,
    input           clk_en,
    input           bypass,

    output          clk_out
);


assign      clk_out = clk_in;

endmodule