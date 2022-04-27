module cadence_meas #(parameter FAST_SIM = 1) (
    input logic                 clk,
    input logic                 rst_n,
    input logic                 cadence_filt,
    input logic                 cadence_rise,
    output logic                not_pedaling,
    output logic [7:0]          cadence_per
);

localparam THIRD_SEC_REAL = 24'hE4E1C0;
localparam THIRD_SEC_FAST = 24'h007271;
localparam THIRD_SEC_UPPER = 8'hE4;

logic           is_third_of_sec;
logic           capture_per;
logic [24:0]    THIRD_SEC;
logic [23:0]    cadence_count;
logic [7:0]     cadence_per_d;

generate
    if (FAST_SIM)
        assign THIRD_SEC = THIRD_SEC_FAST;
    else
        assign THIRD_SEC = THIRD_SEC_REAL;
endgenerate

// Capture per
assign is_third_of_sec = cadence_count == THIRD_SEC;
assign capture_per = cadence_rise | is_third_of_sec;

// Count cycles between cadence rise
always_ff @ (posedge clk, negedge rst_n) begin
    if (~rst_n)
        cadence_count <= 24'h0;
    else
        cadence_count <= cadence_rise ? 24'h0 : (is_third_of_sec ? cadence_count : cadence_count + 1);
end

// Capture cadence period
assign cadence_per_d = rst_n ? (capture_per ? (FAST_SIM ? cadence_count[14:7] : cadence_count[23:16]) : cadence_per) : THIRD_SEC_UPPER;

always_ff @ (posedge clk) begin
    cadence_per <= cadence_per_d;
end

// Not pedaling when cadence period is equal to 1/3rd of a second
assign not_pedaling = cadence_per == THIRD_SEC_UPPER;

endmodule