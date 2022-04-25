module PB_release (
    input logic     PB,
    input logic     clk,
    input logic     rst_n,
    output logic    released
);

logic PB_d2, PB_d3, PB_d4;

always_ff @ (posedge clk, negedge rst_n)
    if (!rst_n)
        PB_d2 <= 1'b1;
    else
        PB_d2 <= PB;

always_ff @ (posedge clk, negedge rst_n)
    if (!rst_n)
        PB_d3 <= 1'b1;
    else
        PB_d3 <= PB_d2;

always_ff @ (posedge clk, negedge rst_n)
    if (!rst_n)
        PB_d4 <= 1'b1;
    else
        PB_d4 <= PB_d3;

assign released = ~PB_d4 & PB_d3;

endmodule
