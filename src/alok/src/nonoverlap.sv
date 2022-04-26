module nonoverlap(clk, rst_n, highIn, lowIn, highOut, lowOut);
/////////////////////////////////////////////////////////////////////////////////////////////
// Non Overlap block to ensure that high gate drive and low gate drive will never overlap //
///////////////////////////////////////////////////////////////////////////////////////////

input clk, rst_n, lowIn, highIn;
output logic lowOut, highOut;

logic lowIn_nxt, highIn_nxt, lowIn_change, highIn_change, overall_change;	//Intermediate signals
logic [4:0] cnt;	// Counter variable

//Flopping lowIn and highIn for detecting change in the signal
always @(posedge clk, negedge rst_n)
	if(!rst_n) 
	begin
		lowIn_nxt <= 0;
		highIn_nxt <= 0;
	end
	else
	begin
		lowIn_nxt <= lowIn;
		highIn_nxt <= highIn;
	end

assign lowIn_change = ~(lowIn ^ lowIn_nxt);	//lowIn change detection

assign highIn_change = ~(highIn ^ highIn_nxt);	//highIn change detection

//Creating an intermediate signal to indicate change in either lowIn or highIn
assign overall_change = ~(lowIn_change & highIn_change);

//5 bit counter which is assigned to 0 when there is a change either lowIn or highIn and keeps counting until 1f
always @(posedge clk, negedge rst_n, posedge overall_change)
	if(!rst_n)
		cnt <= 0;
	else if(overall_change)
		cnt <= 0;
	else if(cnt <= 5'h1e)
		cnt <= cnt+1;

//Adding flops to avoid glitch in highOut/lowOut wherein highOut and lowOut is assigned to 0 when there is a change in either highIn or lowIn 
//highOut and lowOut is assigned to highIn and lowIn respectively when the counter is full which is after 32 clock cycles 
always @(posedge clk, negedge rst_n)
	if(!rst_n)
	begin
		highOut <= 0;
		lowOut <= 0;
	end
	else if(overall_change)
	begin
		highOut <= 0;
		lowOut <= 0;
	end
	else if(&cnt)
	begin
		highOut <= highIn;
		lowOut <= lowIn;
	end

endmodule
