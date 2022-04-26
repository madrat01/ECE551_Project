module A2D_intf(clk, rst_n, batt, curr, brake, torque, SS_n, SCLK, MOSI, MISO);
////////////////////////////////////////////////////////////////////////////////////////////////
// Interface to the A2D converter to read battery voltage, torque, current and brake position//
// Channel 0: Battery Voltage				Channel 1: Current drawn by motor   //
// Channel 3: Brake lever position			Channel 4: Torque sensor output	   //
////////////////////////////////////////////////////////////////////////////////////////////

input clk, rst_n, MISO;

output logic [11:0] batt, curr, brake, torque;
output logic SS_n, SCLK, MOSI;

//Count variable for delay counter
logic [13:0] delay_cnt;

//Intermediate signals to and from SPI_mnrch
logic snd, done; 
logic [15:0] cmd, resp;

//Inputs and outputs of state machine
logic cnv_cmplt, start_cnv;

//Count variable for a counter used to select A2D channels in round robin fashion
logic [1:0] cmd_cnt;

//Enable signals for holding registers to sample 1. Torque sensor input 2. Battery voltage 
//3. Current the motor is drawing and 4. Brake lever position
logic capture_torque, capture_batt, capture_curr, capture_brake;

//Variable to select the A2D channel
logic [2:0] chnnl;

//States for the state machine to send 2 consecutive SPI transaction
typedef enum logic [1:0] {IDLE, FIRST_TRANSFER, WAIT, SECOND_TRANSFER} state_t;
state_t state, nxt_state;

//Instantiate SPI DUT
SPI_mnrch SPI_DUT( .clk(clk), .rst_n(rst_n), .MISO(MISO), .snd(snd), .cmd(cmd), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .done(done), .resp(resp));

//14 bit delay counter to count for 328us before staring conversion on one of the 4 A2D channels 
always_ff @(posedge clk, negedge rst_n)
	if(!rst_n)
		delay_cnt <= 0;
	else
		delay_cnt <= delay_cnt+1;

//Start A2D conversion by intitiating the SPI transaction to the A2D converter on the selected channel when delay_cnt = 0x3fff i.e. after 328us
assign start_cnv = &delay_cnt;

//State FLOP for the state machine which controls the SPI transactions into the A2D 	
always_ff @(posedge clk, negedge rst_n)
	if(!rst_n)
		state <= IDLE;
	else
		state <= nxt_state;

//State transition and output logic for the given state machine
always_comb
begin
	nxt_state = state;
	cnv_cmplt = 0;
	snd = 0;
	case(state)
	default: 	 if(start_cnv) begin		//Setting IDLE as default state; Stay in idle up until the 328us i.e until counter value is 3fff
			 snd = 1;			//Initiate the SPI transaction to the given channel selected in cmd 
			 nxt_state = FIRST_TRANSFER;	
		 	 end
	
	FIRST_TRANSFER:  if(done)			//Wait one cycle before the next SPI transaction 
			 nxt_state = WAIT;		

	WAIT:		 begin
			 snd = 1;			//Initiate the second SPI transaction to read the results from A2D conversion on the selected channel
			 nxt_state = SECOND_TRANSFER;
			 end

	SECOND_TRANSFER: if(done) begin			//Wait until the SPI transfer is complete and move the state machine to IDLE
			 cnv_cmplt = 1;			//Assert cnv_cmplt to increment the A2D channel select counter to select the next channel
			 nxt_state = IDLE;
			 end	 
	endcase			
end

//Counter to select the A2D channel out of the four used in a round robin fashion
always_ff @(posedge clk, negedge rst_n)
	if(!rst_n)
		cmd_cnt <= 0;
	else if(cnv_cmplt)
		cmd_cnt <= cmd_cnt + 1;

//Setting channel to 0,1,3 or 4 based on the counter value in a round robin fashion
assign chnnl =  (cmd_cnt == 2'h0) ? 3'b000 :
		(cmd_cnt == 2'h1) ? 3'b001 :
		(cmd_cnt == 2'h2) ? 3'b011 :
		(cmd_cnt == 2'h3) ? 3'b100 : 3'b000;

//Assign cmd based on the channel value to feed to SPI_mnrch
assign cmd = {2'b00,chnnl,11'h000};

//Asserting enable signals to holding registers for batter, current, torque and brake position 
//based on the channel selected and when the conversion is complete
assign capture_batt   = (cmd_cnt == 2'h0 && cnv_cmplt) ? 1'b1 : 1'b0;
assign capture_curr   = (cmd_cnt == 2'h1 && cnv_cmplt) ? 1'b1 : 1'b0;
assign capture_brake  = (cmd_cnt == 2'h2 && cnv_cmplt) ? 1'b1 : 1'b0;
assign capture_torque = (cmd_cnt == 2'h3 && cnv_cmplt) ? 1'b1 : 1'b0;

//Holding register for battery voltage 
always_ff @(posedge clk, negedge rst_n)
	if(!rst_n)
		batt <= 0;
	else if(capture_batt) 
		batt <= resp;

//Holding register for current the motor is drawing
always_ff @(posedge clk, negedge rst_n)
	if(!rst_n)
		curr <= 0;
	else if(capture_curr)
		curr <= resp;

//Holding register for brake lever position
always_ff @(posedge clk, negedge rst_n)
	if(!rst_n)
		brake <= 0;
	else if(capture_brake)
		brake <= resp;

//Holding register for torque sensor output
always_ff @(posedge clk, negedge rst_n)
	if(!rst_n)
		torque <= 0;
	else if(capture_torque)
		torque <= resp;


endmodule