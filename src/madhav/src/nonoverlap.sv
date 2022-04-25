module nonoverlap (
    input bit               clk,
    input bit               rst_n,
    input logic             highIn,
    input logic             lowIn,
    output logic            highOut,
    output logic            lowOut
);

typedef enum logic {RESET, IN_DEAD_TIME} dead_time_t;

logic [4:0] deadTime;
logic       inputChanged;
logic       highIn_dly;
logic       lowIn_dly;
dead_time_t deadTimeFSM, deadTimeFSM_next;

// Capture input change at high or low
assign inputChanged = highIn ^ highIn_dly | lowIn ^ lowIn_dly;

always_ff @ (posedge clk) begin
    highIn_dly <= highIn;
    lowIn_dly <= lowIn;
end

always_ff @ (posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        highOut <= 1'b0;
        lowOut <= 1'b0;
    end
    // Outs are low till we are in dead time
    else if (deadTimeFSM_next == IN_DEAD_TIME) begin
        highOut <= 1'b0;
        lowOut <= 1'b0;
    end
    // else just output
    else begin
        highOut <= highIn;
        lowOut <= lowIn;
    end
end

always_ff @ (posedge clk or negedge rst_n) begin
    if (~rst_n)
        deadTimeFSM <= RESET;
    else
	deadTimeFSM <= deadTimeFSM_next;
end

always_comb begin
	case (deadTimeFSM)
	    RESET : begin
		    	// go to dead time when input changed, reset the
			// counter to count till 32
	                deadTimeFSM_next = inputChanged ? IN_DEAD_TIME : RESET;
	            end
	    IN_DEAD_TIME : begin
		    	   // exit dead time when counter reaches 31 (32 cycles)
	                   deadTimeFSM_next = &deadTime ? RESET : deadTimeFSM;
	                   end
	endcase
end

always_ff @ (posedge clk) begin
	if (deadTimeFSM_next == IN_DEAD_TIME)
		deadTime <= inputChanged ? 5'b0 : deadTime + 1;
	else
		deadTime <= 5'b0;
end

endmodule
