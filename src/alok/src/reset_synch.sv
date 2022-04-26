module reset_synch(RST_n, clk, rst_n);
/////////////////////////////////////////////////////////////////
// Reset synchronizer that takes raw push button signal and   //
// creates a stable reset deasserted at negative edge of clk //
//////////////////////////////////////////////////////////////

input RST_n, clk;
output logic rst_n;

//Intermediate signals between two flops
logic rst_n_q1;

//Producing a global reset (rst_n) which comes from double flopped design to account for metastability
always @(negedge clk, negedge RST_n)
begin
	if(!RST_n) 
	begin
		rst_n_q1 <= 0;
		rst_n <= 0;
	end else begin
		rst_n_q1 <= 1;
		rst_n <= rst_n_q1;
	end
end

endmodule