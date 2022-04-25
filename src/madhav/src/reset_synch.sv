module reset_synch (
    input logic     RST_n,
    input logic     clk,
    output logic    rst_n
);

logic rst_n_t;

always_ff @ (negedge clk, negedge RST_n)
    if (!RST_n)
        rst_n_t <= 1'b0;
    else
        rst_n_t <= 1'b1;

always_ff @ (negedge clk, negedge RST_n)
    if (!RST_n)
        rst_n <= 1'b0;
    else
        rst_n <= rst_n_t;

endmodule
