module PWM_tb ();

bit		clk;
bit		rst_n;
logic [10:0]	duty;
logic		PWM_sig;
logic		PWM_synch;

PWM pwm (.clk (clk), .rst_n (rst_n), .duty (duty), .PWM_sig (PWM_sig), .PWM_synch (PWM_synch));

initial begin
	clk = 1'b0;
	rst_n = 1'b1;
end

always begin
	#10 clk = ~clk;
end

initial begin
	@ (posedge clk);
	@ (negedge clk);
	rst_n = 0;
	duty = 11'd1028;
	@ (posedge clk);
	rst_n = 1;
    repeat (5000) @ (posedge clk);
	@ (posedge clk);
	@ (negedge clk);
	rst_n = 0;
	duty = 11'd512;
	@ (posedge clk);
	rst_n = 1;
    repeat (5000) @ (posedge clk);
	@ (posedge clk);
	@ (negedge clk);
	rst_n = 0;
	duty = 11'd256;
	@ (posedge clk);
	rst_n = 1;
    repeat (5000) @ (posedge clk);
	@ (posedge clk);
	$stop();
end

endmodule
