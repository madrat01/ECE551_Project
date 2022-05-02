module telemetry(clk, rst_n, batt_v, avg_curr, avg_torque, TX);
/////////////////////////////////////////////////////////////////
// UART transmitter wrapper for periodic serial transfer of   //
// battery voltage, motor current and input torque	     //
//////////////////////////////////////////////////////////////

input clk, rst_n;
input [11:0] batt_v, avg_curr, avg_torque;

output logic TX;

logic trmt, tx_done;
logic [7:0] tx_data;
logic [19:0] cnt;

// States for the FSM - One of each byte to be transferred along with IDLE
typedef enum reg [3:0] {IDLE,DELIM1,DELIM2,PAYLOAD1,PAYLOAD2,PAYLOAD3,PAYLOAD4,PAYLOAD5,PAYLOAD6} state_t;
state_t state, nxt_state;

// Instantiate the UART Transmitter
UART_tx UARTTX(.clk(clk), .rst_n(rst_n), .TX(TX), .trmt(trmt), .tx_data(tx_data), .tx_done(tx_done));

// Counter which resets to zero after 1041666 cycles which is equal to 1/48th of a second with clock at 50MHz
always @(posedge clk, negedge rst_n)
begin
	if(!rst_n)
		cnt <= 0;
	else if(cnt == 20'hFE502)
		cnt <= 0;
	else
		cnt <= cnt + 1;
end

//Telemetry state machine
//State flop for the telemetry state machine
always @(posedge clk,negedge rst_n) 
begin 
	if(!rst_n) 
		state <= IDLE;
	else 
		state <= nxt_state;
end

//Output and state transisition logic for telemetry state machine
always_comb
begin
nxt_state = state;
trmt = 0;
tx_data = 0;

case(state)

DELIM1: begin				//State to wait for serial transfer of DELIM1 to complete
tx_data = 8'haa;
	if(tx_done) begin		// Wait for tx_done to arrive from DELIM1 trasfer and load DELIM2 (0x55) in next clock cycle and assert trmt for one clock cycle
		nxt_state = DELIM2;
		tx_data = 8'h55;
		trmt = 1;
	end
end

DELIM2: begin				//State to wait for serial transfer of DELIM2 to complete
tx_data = 8'h55;
	if(tx_done) begin		// Wait for tx_done to arrive from DELIM2 trasfer and load payload1 (MSB nibble of Battery voltage) in next clock cycle and assert trmt for one clock cycle
		nxt_state = PAYLOAD1;
		tx_data = {4'b0000,batt_v[11:8]};
		trmt = 1;
	end
end

PAYLOAD1: begin				//State to wait for serial transfer of payload1 to complete
tx_data = {4'b0000,batt_v[11:8]};
	if(tx_done) begin		// Wait for tx_done to arrive from payload1 trasfer and load payload2 (LSB byte of Battery voltage) in next clock cycle and assert trmt for one clock cycle
		nxt_state = PAYLOAD2;
		tx_data = batt_v[7:0];
		trmt = 1;
	end
end

PAYLOAD2: begin				//State to wait for serial transfer of payload2 to complete
tx_data = batt_v[7:0];
	if(tx_done) begin		// Wait for tx_done to arrive from payload2 trasfer and load payload3 (MSB nibble of motor current) in next clock cycle and assert trmt for one clock cycle
		nxt_state = PAYLOAD3;
		tx_data = {4'b0000,avg_curr[11:8]};
		trmt = 1;
	end
end

PAYLOAD3: begin				//State to wait for serial transfer of payload3 to complete
tx_data = {4'b0000,avg_curr[11:8]};
	if(tx_done) begin		// Wait for tx_done to arrive from payload3 trasfer and load payload2 (LSB byte of motor current) in next clock cycle and assert trmt for one clock cycle
		nxt_state = PAYLOAD4;
		tx_data = avg_curr[7:0];
		trmt = 1;
	end
end

PAYLOAD4: begin				//State to wait for serial transfer of paylaod4 to complete
tx_data = avg_curr[7:0];
	if(tx_done) begin		// Wait for tx_done to arrive from payload4 trasfer and load payload5 (MSB nibble of input torque) in next clock cycle and assert trmt for one clock cycle
		nxt_state = PAYLOAD5;
		tx_data = {4'b0000,avg_torque[11:8]};
		trmt = 1;
	end
end

PAYLOAD5: begin				//State to wait for serial transfer of paylaod5 to complete
tx_data = {4'b0000,avg_torque[11:8]};
	if(tx_done) begin		// Wait for tx_done to arrive from payload5 trasfer and load payload6 (LSB byte of input torque) in next clock cycle and assert trmt for one clock cycle
		nxt_state = PAYLOAD6;
		tx_data = avg_torque[7:0];
		trmt = 1;
	end
end

PAYLOAD6: begin				//State to wait for serial transfer of paylaod6 to complete
tx_data = avg_torque[7:0];
	if(tx_done)
		nxt_state = IDLE;
end

default: begin				// Setting up IDLE as the default state
	if(!rst_n) begin		// Assiging reset values to tx_data and trmt
		tx_data = 8'h00;
		trmt = 0;
	end
	else if(cnt == 20'h1) begin		// Moving to DELIM1 state and feeding 0xaa to UART_tx after every 1/48th of a second when counter resets to 0 and assert trmt for one clock cycle
		nxt_state = DELIM1;
		tx_data = 8'haa;
		trmt = 1;
	end
end

endcase
end

endmodule
