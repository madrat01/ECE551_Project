module nonoverlap_test(clk,RST_n,PB,LED);

	input clk;		// our 50MHz clock from DE0-Nano
	input RST_n;	// from push button, goes to our reset_synch block
	input PB;		// from push button, goes to our PB_release detector
	
	output reg [7:0] LED;		// 
	
	////////////////////////////////////////
	// Declare any internal signals here //
	//////////////////////////////////////
	wire rst_n;				// global reset to all other blocks, produced by rst_synch
	wire start_seq;			// from PB_release unit, start stimulus to DUT
	wire highIn, lowIn;		// inputs to DUT generated by stim
    wire highOut,lowOut;	// outputs of DUT monitored by observer
	
	/////////////////////////////////////
	// Instantiate reset synchronizer //
	///////////////////////////////////
	reset_synch iRST(.RST_n(RST_n), .clk(clk), .rst_n(rst_n));

	///////////////////////////////////////////////
	// Instantiate push button release detector //
	/////////////////////////////////////////////
	PB_release iPB(.clk(clk), .rst_n(rst_n), .PB(PB), .released(start_seq));
	

	///////////////////////////////////
	// Instantiate DUT (nonoverlap) //
    /////////////////////////////////
	nonoverlap iDUT(.clk(clk),.rst_n(rst_n),.highIn(highIn),.lowIn(lowIn),
	                .highOut(highOut),.lowOut(lowOut));
						 
	/////////////////////////////
	// Instantiate stim block //
	///////////////////////////
	stim iSTM(.clk(clk),.rst_n(rst_n),.start_seq(start_seq),.highIn(highIn),.lowIn(lowIn),.LED());
	
	///////////////////////////
	// Instantiate observer //
    /////////////////////////
	observer iCHK(.clk(clk),.rst_n(rst_n),.highOut(highOut),.lowOut(lowOut),.LED(LED));
	
endmodule


module stim(clk,rst_n,start_seq,highIn,lowIn,LED);

  input clk,rst_n;
  input start_seq; 	// pulse on this starts stimulus generation
  output reg highIn;	// stimulus to DUT
  output reg lowIn;		// stimulus to DUT
  output [7:0] LED;
  
  typedef enum reg {IDLE,GEN} state_t;
  
  state_t state, nxt_state;
  
  ////////////////////////////////////////////
  // Declare any needed internal registers //
  //////////////////////////////////////////
  reg [7:0] cnt;		// MSB of this forms stimulus
  
  ///////////////////////////////////////
  // Declare SM outputs of type logic //
  /////////////////////////////////////
  logic clr_cnt;		// clear stimulus counter
  
  //////////////////////////////////////////
  // Infer counter used to form stimulus //
  ////////////////////////////////////////
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
	  cnt <= 8'h00;
	else if (clr_cnt)
	  cnt <= 8'h00;
	else
	  cnt <= cnt + 1;
	  
  assign highIn = cnt[7];
  assign lowIn = ~cnt[7];
  
  ////////////////////////
  // Infer state flops //
  //////////////////////
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
	  state <= IDLE;
	else
	  state <= nxt_state;

  /////////////////////////////////////////
  // Infer SM transition & output logic //
  ///////////////////////////////////////
  always_comb begin
    clr_cnt = 1'b0;
    nxt_state = state;
	
	case (state)
	  IDLE : begin
	    clr_cnt = 1'b1;
		if (start_seq)
		  nxt_state = GEN;
	  end
	  GEN : begin
	    // stay here forever
	  end
	endcase
  end
  
  assign LED = {5'b10000,highIn,lowIn,state};
  
  
endmodule

module observer(clk,rst_n,highOut,lowOut,LED);
  
  input clk, rst_n;
  input highOut,lowOut;		// FET controls from nonoverlap being monitored
  output reg [7:0] LED;			// will be 0xAA if all good, and 0xEE if overlap discovered
  
  
  typedef enum reg[1:0] {WAIT_CHANGE,RISE,DEADBANDfall,HIGH_AFTER_FALL} state_t;
  
  state_t state, nxt_state;
  
  ////////////////////////////////////////////
  // Declare any needed internal registers //
  //////////////////////////////////////////
  reg [4:0] tmr;				// deadband timer
  reg [1:0] last_state;		// last state of {highOut,lowOut} for change detection.
  reg skip_1st,skip_2nd;	// skip 1st 2 compares after rst deasserts
  
  ///////////////////////////////////////
  // Declare SM outputs of type logic //
  /////////////////////////////////////
  logic clr_tmr;		// clear deadband timer
  logic set_err;		// set LED to error state
  
  //////////////////////////////////////
  // Declare any needed interanl signals //
  ////////////////////////////////////////
  wire tmr_full;
  wire rise,fall;
  
  //////////////////////////////////////
  // Infer last_state flops looking  //
  // for change of {highOut,lowOut} //
  ///////////////////////////////////
  always_ff @(posedge clk)
      last_state <= {highOut,lowOut};

  assign fall = (({highOut,lowOut}==2'b00) && |last_state) ? 1'b1 :
                ((highOut^lowOut) && (last_state==2'b11)) ? 1'b1 : 1'b0;
				
  assign rise = (({highOut,lowOut}==2'b11) && (!(&last_state))) ? 1'b1 :
                ((highOut^lowOut) && (last_state==2'b00)) ? 1'b1 : 1'b0;
  
  ////////////////////////
  // Infer state flops //
  //////////////////////
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
	  state <= WAIT_CHANGE;
	else
	  state <= nxt_state;
	 	 
  /////////////////////////////////////
  // LED output resets to 0xAA and  //
  // is sticky if ever set to 0xEE //
  //////////////////////////////////
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
	  LED <= 8'h99;
	else if (set_err)
	  LED <= 8'hEE;
	else if (fall && (LED!=8'hEE))
	  LED <= 8'hAA;
	  
  ////////////////////////////////
  // implement dead band timer //
  //////////////////////////////
  always_ff @(posedge clk)
    if (clr_tmr)
	  tmr <= 5'h00;
	else
	  tmr <= tmr + 1;
	  
  assign tmr_full = &tmr[4:2];	// terminate at 31 counts
	  
  /////////////////////////////////////////
  // Infer SM transition & output logic //
  ///////////////////////////////////////
  always_comb begin
    set_err = 0;			// default to
	clr_tmr = 0;			// ensure no latches
	nxt_state = state;
	
	case (state)
	  WAIT_CHANGE : begin
	    clr_tmr = 1;
	    set_err = highOut & lowOut;		// can't ever have both high
	    if (rise)
		  nxt_state = RISE;
		else if (fall)
		  nxt_state = DEADBANDfall;
	  end
	  RISE : begin
	    set_err = highOut & lowOut;		// check that not both high
		 if (tmr_full)
		   nxt_state = WAIT_CHANGE;
	  end
	  DEADBANDfall : begin
	    set_err = highOut | lowOut;		// during deadband fall both better be low
		 if (tmr_full)
		   nxt_state = HIGH_AFTER_FALL;
	  end
	  HIGH_AFTER_FALL : begin
	    if (tmr==5'h03) begin						// a few clocks after timer rolls over
		   set_err = ~(highOut | lowOut); 		// one of them better be high
			nxt_state = WAIT_CHANGE;
		 end
	  end
	endcase
  end
	  
endmodule

