module telemetry (
    input logic         clk,
    input logic         rst_n,
    input logic [11:0] 	batt_v,
    input logic [11:0] 	avg_curr,
    input logic [11:0] 	avg_torque,
	output logic	   	TX
);

typedef enum logic [3:0] {IDLE, DELIM1, DELIM2, PAYLOAD1, PAYLOAD2, PAYLOAD3, PAYLOAD4, PAYLOAD5, PAYLOAD6} tran_state_t;

logic [19:0]        counter;
tran_state_t        transmiterFSM, transmiterFSM_next, transmiterFSM_dly;
logic               trmt;
logic               tx_done, tx_done_dly, tx_done_rise;
logic [7:0]         tx_data;

// Counter to count till 20'hfe502
// Since we need to send a payload every 47.68 times a second and our frequency is 50MHz
always_ff @ (posedge clk or negedge rst_n) begin
    if (~rst_n)
        counter <= 20'b0;
    else
        counter <= (counter != 20'hfe502) ? counter + 1 : 20'h0;
end

// Move to next state next cycle
always_ff @(posedge clk or negedge rst_n) begin : TRANS_FSM_NEXT
    if (~rst_n)
        transmiterFSM <= IDLE;
    else
        transmiterFSM <= transmiterFSM_next;
end

always_ff @(posedge clk)
	transmiterFSM_dly <= transmiterFSM;

// trmt high for a single cycle when state changed (and not changed to idle state)
assign trmt = ((transmiterFSM != transmiterFSM_dly) && (transmiterFSM != IDLE));

always_ff @ (posedge clk)
	tx_done_dly <= tx_done;

// tx_done is used to move to next state (but tx done is high for more than 1 cycle, so implement a rising edge detector)
assign tx_done_rise = ~tx_done_dly & tx_done;

// Move to transmit when counter reaches 20'hfe502 and next states when tx_done_rise detected
always_comb begin : TRANS_FSM
    tx_data = 8'h0;
    transmiterFSM_next = transmiterFSM;
    case (transmiterFSM)
    IDLE : transmiterFSM_next = counter == 20'hfe502 ? DELIM1 : transmiterFSM_next;
    DELIM1 : begin
                 tx_data = 8'hAA; 
                 if (tx_done_rise) transmiterFSM_next = DELIM2;
                 end
	DELIM2 : begin
		  	  tx_data = 8'h55;
		  	  if (tx_done_rise) transmiterFSM_next = PAYLOAD1;
	          end
    PAYLOAD1 : begin
		   tx_data = {4'h0, batt_v[11:8]};
		   if (tx_done_rise) transmiterFSM_next = PAYLOAD2;
	   	   end
	PAYLOAD2 : begin
		   tx_data = batt_v[7:0];
		   if (tx_done_rise) transmiterFSM_next = PAYLOAD3;
	   	  end
	PAYLOAD3 : begin
		   tx_data = {4'h0, avg_curr[11:8]};
		   if (tx_done_rise) transmiterFSM_next = PAYLOAD4;
	   	   end
	PAYLOAD4 : begin
		   tx_data = avg_curr[7:0];
		   if (tx_done_rise) transmiterFSM_next = PAYLOAD5;
	  	   end
	PAYLOAD5 : begin
		   tx_data = {4'h0, avg_torque[11:8]};
		   if (tx_done_rise) transmiterFSM_next = PAYLOAD6;
	           end
	PAYLOAD6 : begin
		   tx_data = avg_torque[7:0];
		   transmiterFSM_next = IDLE;
	   	   end
    endcase
end

UART_tx uart_tx (.clk (clk), .rst_n (rst_n), .TX (TX), .trmt(trmt), .tx_data(tx_data), .tx_done(tx_done));

endmodule
