module PB_intf (
    input               clk,
    input               rst_n,
    input               tgglMd,
    output logic [1:0]  setting,
    output logic [2:0]  scale
);

logic tgglMd_d2, tgglMd_d3, tgglMd_rising;

// Sync tgglMd to current clk domain to remove metastability
always_ff @ (posedge clk) begin
    tgglMd_d2 <= tgglMd;
    tgglMd_d3 <= tgglMd_d2;
end

// Rising edge dectector of rgglMd
assign tgglMd_rising = ~tgglMd_d3 & tgglMd_d2;

// toggle setting at push of tgglMD
always_ff @ (posedge clk, negedge rst_n) begin
    if (~rst_n)
        setting <= 2'b10;
    else if (tgglMd_rising)
        setting <= setting + 1;
end

// Setting assigns scale
assign scale =  setting == 2'b11 ? 3'b111 :
                setting == 2'b10 ? 3'b101 :
                setting == 2'b01 ? 3'b011 : 3'b000;

endmodule