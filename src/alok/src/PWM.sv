module PWM(clk, rst_n, duty, PWM_sig, PWM_synch);

////////////////////////////////////////////////////////////////////////////////////
// Pulse width modulation block to vary the strength of the drive into the motor //
//////////////////////////////////////////////////////////////////////////////////

input clk, rst_n;
input [10:0] duty;
output logic PWM_sig, PWM_synch;

logic [10:0] cnt;	// Counter variable

//Simple 11-bit counter
always @(posedge clk, negedge rst_n)
	if(!rst_n)
		cnt <= 0;
	else 
		cnt <= cnt+1;

//PWM_synch signal which is triggred in the form of pulse when count of the counter is 1
assign PWM_synch = (cnt == 11'h001);

//Based on the duty cycle the signal is kept asserted until cnt is greater than duty cycle and is then flopped
always @(posedge clk, negedge rst_n)
	if(!rst_n)
		PWM_sig <= 0;
	else
		PWM_sig <= (cnt <= duty);

endmodule
