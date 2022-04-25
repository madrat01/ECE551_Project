module cadence_filt_tb();

  reg clk,rst_n;		//clock
  reg cadence_raw;		// raw stimulus (will have "noisy" transitions
  reg cadence_gold;		// "noise free" version of cadence_raw
  
  reg [23:0] transition_cnt;		// used to count transitions of filtered signal
  reg flt_smpld;					// used for edge detection of filtered signal
  
  wire cadence_flt;					// hooked to the filtered output of the DUT

  integer rand_cnt,transitions;		// number of random transitions
  integer iterations;				// outer loop counter
  integer rand_bit;					// random bit assigned to cadence
  
  //////////////////////
  // Instantiate DUT //
  ////////////////////
  cadence_filt iDUT(.clk(clk),.rst_n(rst_n),.cadence(cadence_raw),.cadence_filt(cadence_flt));
  
  initial begin
    /// initialize signals ///
    clk = 0;
	rst_n = 0;
	cadence_raw = 1'b0;
	cadence_gold = 1'b0;
	/// wait till deassert reset ////
	@(posedge clk);
	@(negedge clk);
	rst_n = 1;			// deassert reset
	@(negedge clk);
	
	///// loop for 20 "actual" transitions of cadence //////
	for (iterations=0; iterations<20; iterations = iterations + 1) begin
	    //// hold signal at constant value for > 1ms /////
		cadence_gold = ~cadence_gold;
		cadence_raw = cadence_gold;
		repeat(80000) @(negedge clk);
        
		//// Now inject some noise for <1ms, random transitions/data ////
		rand_cnt = $urandom % 40000;
		for (transitions=0; transitions<rand_cnt; transitions=transitions+1) begin
		  @(negedge clk);
		  rand_bit = $urandom %2;
		  cadence_raw = (rand_bit==0) ? 1'b0 : 1'b1;
		end
	end
	//// If we saw too many transitions of filtered signal something is wrong ////
	if (transition_cnt>24'h000016)
	  $display("ERR: too many transitions found on filtered signal");
	else
	  $display("YAHOO!! test passed");
	$stop();
  end
  
  //////////////////////////////////////////////////////////
  // capture filtered signal for edge detection purposes //
  ////////////////////////////////////////////////////////
  always @(posedge clk, negedge rst_n)
    if (!rst_n)
	  flt_smpld <= 1'b0;
	else
	  flt_smpld <= cadence_flt;
	  
  ///////////////////////////////////////////
  // Count transitions of filtered signsl //
  /////////////////////////////////////////
  always @(posedge clk, negedge rst_n)
    if (!rst_n)
	  transition_cnt <= 5'h00;
	else if (flt_smpld!==cadence_flt)
	  transition_cnt <= transition_cnt + 5'h01;
  
  always
    #5 clk = ~clk;
	
endmodule
	
  