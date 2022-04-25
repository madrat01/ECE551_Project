module cadence_filt #(parameter FAST_SIM = 1) (
	input bit		clk,
	input bit		rst_n,
	input logic		cadence,
	output logic 	cadence_filt,
	output logic	cadence_rise
);

logic		cadence_sync;
logic		cadence_sync_intermediate;
logic		cadence_sync_delayed;
logic		chngd_n;
logic [15:0] stbl_cnt;
logic       stbl_cnt_f;

generate
    if (FAST_SIM)
        assign stbl_cnt_f = &stbl_cnt[8:0];
    else
        assign stbl_cnt_f = &stbl_cnt;
endgenerate

always_ff @ (posedge clk) begin
	cadence_sync_intermediate <= cadence;
	cadence_sync <= cadence_sync_intermediate;
	cadence_sync_delayed <= cadence_sync;
end

assign chngd_n = ~(cadence_sync ^ cadence_sync_delayed);

always_ff @ (posedge clk) begin
	if (~rst_n)
		stbl_cnt <= 0;
	else
		stbl_cnt <= (stbl_cnt + 1) & {16{chngd_n}};
end

always_ff @ (posedge clk) begin
	cadence_filt <= stbl_cnt_f ? cadence_sync_delayed : cadence_filt;
end

assign cadence_rise = ~cadence_sync_delayed & cadence_sync;

endmodule
