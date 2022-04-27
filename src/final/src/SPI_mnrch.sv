module SPI_mnrch(clk, rst_n, MISO, snd, cmd, SS_n, SCLK, MOSI, done, resp);
/////////////////////////////////////////////////////////////////////////////////////////////
// SPI monarch for the Inertial sensor and A2D converter which are the SPI peripherals    //
///////////////////////////////////////////////////////////////////////////////////////////

input clk, rst_n, MISO, snd;
input [15:0] cmd;

output logic SS_n, SCLK, MOSI, done;
output logic [15:0] resp;

typedef enum logic [1:0] {IDLE, SHIFT, BACK_PORCH}state_t;	//States for the state machine

state_t state,nxt_state;

logic [4:0] SCLK_div, bit_cntr;
logic full, shft, init, done16, set_done, ld_SCLK;
logic [15:0] shft_reg;

//SCLK generator
always @(posedge clk, negedge rst_n)
begin
	if(!rst_n)
		SCLK_div <= 5'b10111;
	else if(ld_SCLK)
		SCLK_div <= 5'b10111;	//Loading SCLK_div with 5'b10111 for the frontporch behavior of SCLK
	else
		SCLK_div <= SCLK_div + 1;
end

assign SCLK = SCLK_div[4];	//Assigning MSB of SCLK_div to SCLK to divide clk by 32
assign full = &SCLK_div;	//Indicates completion of 1 complete SCLK cycle
assign shft = (SCLK_div == 5'b10001) ? 1'b1 : 1'b0;	//shft idicates 2 system clk cycles after SCLK rise to put MISO into LSB

//16 bit shift register with parallel load to recieve and send serial data
always @(posedge clk, negedge rst_n)
begin
	if(!rst_n)
		shft_reg <= 0;
	else if(init)				//Load data from cmd when init comes from state machine
		shft_reg <= cmd;
	else if((!init) && shft)		//Shift out MSB as MOSI and shift in MISO as LSB 2 system clk cycles after rise of SCLK
		shft_reg <= {shft_reg[14:0],MISO};
end

assign MOSI = shft_reg[15];	//MSB of the shift register is shifted out as MOSI output from monarch

//Counter to keep track of number of times the shift register has shifted 
always @(posedge clk, negedge rst_n)
begin
	if(!rst_n)
		bit_cntr <= 0;
	else if(init)
		bit_cntr <= 0;
	else if(shft)
		bit_cntr <= bit_cntr + 1;
end

assign done16 = bit_cntr[4];	//Indication of completion of 16 clock cycles

//SPI monarch state machine
//State flop for the SPI monarch state machine
always @(posedge clk, negedge rst_n)
begin
	if(!rst_n)
		state <= IDLE;
	else
		state <= nxt_state;
end

//Output and state transition logic for SPI monarch state machine
always_comb
begin
nxt_state = state;
ld_SCLK = 0;
init = 0;
set_done = 0;

case(state)
//SHIFT state wherein we wait for 16 shifts to complete
SHIFT: begin
if(done16)
	nxt_state = BACK_PORCH;
end

//After the 16 shifts assert done and move the state machine to IDLE while maintaining SCLK at 1
BACK_PORCH: begin
if(full)
begin
	set_done = 1;
	nxt_state = IDLE;
	ld_SCLK = 1;
end
end

//Assign IDLE as the default state and wherein the state machine waits till the next snd request
default: begin
ld_SCLK = 1;
if(snd)
begin
	init = 1;
	nxt_state = SHIFT;
end
end

endcase
end 

//Using Preset Flops to output SS_n
always @(posedge clk, negedge rst_n)
begin
	if(!rst_n)
		SS_n <= 1;
	else if(set_done)
		SS_n <= 1;
	else if(init)
		SS_n <= 0;
end

//Using Reset Flops to output done 
always @(posedge clk, negedge rst_n)
begin
	if(!rst_n)
		done <= 0;
	else if(set_done)
		done <= 1;
	else if(init)
		done <= 0;
end

//Assigning the output to resp
always @(posedge clk, negedge rst_n)
begin
	if(!rst_n)
		resp <= 0;
	else if(set_done)
		resp <= shft_reg;
end

endmodule
