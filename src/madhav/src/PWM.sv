module PWM (
	input bit		clk,
	input bit		rst_n,
	input logic [10:0]	duty,
	output logic		PWM_sig,
	output logic		PWM_synch
);

logic [10:0]	cnt;

always_ff @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		PWM_sig <= 1'b0;
		cnt <= 11'b0;
	end else begin
		// PWM duty cycle
		if (cnt <= duty)
			PWM_sig <= 1'b1;
		else
			PWM_sig <= 1'b0;
			
		// Increase counter, let it overflow from 11'h3FF to 0
		cnt <= cnt + 1'b1;
	end
end

// PWM synch signal
assign PWM_synch = cnt == 11'h001;

endmodule
