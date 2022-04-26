module cadence_filt(clk, rst_n, cadence, cadence_filt, cadence_rise);

input clk, rst_n, cadence;
output logic cadence_filt, cadence_rise;
logic cadence_ff1, cadence_ff2, cadence_stable, chngd_n;		// Intermediate signals for FFs to mitigate metastability and for edge detection
logic [15:0] stbl_cnt_sync, stbl_cnt, stbl_cnt_inc;	// Intermediate signals for the stability counter. Making it 16 bits so because (1ms/(1/50MHz)) = 50000 which requires atleast 16 bits to represent

always @(posedge clk, negedge rst_n)		// 2 Flip Flops to mitigate metastability and one more for detecting change in edge 
begin
if(!rst_n)
begin
cadence_ff1 <= 0;
cadence_ff2 <= 0;
cadence_stable <= 0;
end
else
begin
cadence_ff1 <= cadence;
cadence_ff2 <= cadence_ff1;
cadence_stable <= cadence_ff2;
end
end

assign chngd_n = ~(cadence_ff2 ^ cadence_stable);	// XNOR gate to detect change in candence signal to knock down stability counter to zero

assign cadence_rise = (cadence_ff2 & ~(cadence_stable)); // Using AND and NOT gate ot detect rising edge on cadence signal

always @(posedge clk, negedge rst_n)	// Flip Flop with asyc reset before feeding into the counter which is combinational and whose value is used to determine whether to knock down counter value to 0 or not
begin
if(!rst_n)
stbl_cnt <= 16'h0;
else
stbl_cnt <= {16{chngd_n}} & (stbl_cnt+1);	// Knocking down the stability counter to zero when there is a change in the candence signal else passing the incremented stability counter value
end

always @(posedge clk, negedge rst_n)
begin
if(!rst_n)
cadence_filt <= 0;
else if(&stbl_cnt)			// Makes sure the data is stable for atleast 1ms i.e. stability counter is full 
cadence_filt <= cadence_stable; // Pass on the stable candence value else maintain the previous value
end

endmodule
