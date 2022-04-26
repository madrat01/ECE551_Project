module brushless(clk, rst_n, drv_mag, hallGrn, hallYlw, hallBlu, brake_n, PWM_synch, duty, selGrn, selYlw, selBlu);
//////////////////////////////////////////////////////////////////////////////////////////////////
// The module to determine the coil drive state for brushless motor drive along with duty cycle//
////////////////////////////////////////////////////////////////////////////////////////////////
// States: 1. Not driven 2. Forward current 3. Reverse current 4. Regen braking//
////////////////////////////////////////////////////////////////////////////////

input clk, rst_n, hallGrn, hallYlw, hallBlu, brake_n, PWM_synch;
input [11:0] drv_mag;

output logic [10:0] duty;
output logic [1:0] selGrn, selYlw, selBlu;

logic hallGrn_q1, hallGrn_q2, hallYlw_q1, hallYlw_q2, hallBlu_q1, hallBlu_q2;
logic synchGrn, synchYlw, synchBlu;
logic [2:0] rotation_state;

//An enum for all the rotation state 
//typedef enum logic [2:0] {bluFW_ylwREV=1, ylwFW_grnREV, bluFW_grnREV, grnFW_bluREV, grnFW_ylwREV, ylwFW_bluREV}state_t;	
//state_t state;

//Synchronizing Hall sensors to system clock by double flopping
always @(posedge clk)
begin
	hallGrn_q1 <= hallGrn;
	hallGrn_q2 <= hallGrn_q1;
	hallYlw_q1 <= hallYlw;
	hallYlw_q2 <= hallYlw_q1;
	hallBlu_q1 <= hallBlu;
	hallBlu_q2 <= hallBlu_q1;
end

//Synchronizing commutation to the PWM cycle
always_ff @(posedge clk, negedge rst_n)
	if(!rst_n)
	begin
		synchGrn <= 0;
		synchYlw <= 0;
		synchBlu <= 0;
	end 
	else if (PWM_synch)
	begin
		synchGrn <= hallGrn_q2;
		synchYlw <= hallYlw_q2;
		synchBlu <= hallBlu_q2;
	end

//Forming 3 bit vector to determine the rotation state
assign rotation_state = {synchGrn,synchYlw,synchBlu};

//Casiting rotation_state to the enum "state"
//assign state = state_t'(rotation_state);

//Driving the coils relative to rotation state and braking
always_comb
if(brake_n == 1'b0)	// This indicates regenrative braking wherein all coils are driven with high side FET off and low side FET PWMing
begin
	selGrn = 2'b11;
	selYlw = 2'b11;
	selBlu = 2'b11;
end
else
case(rotation_state)	//When non breaking drive the coil based on rotation state
//Blue coil - Forward Current, Yellow coil - Reverse Current, Green coil - High Z
//bluFW_ylwREV: begin
3'b001: begin
	selGrn = 2'b00;
	selYlw = 2'b01;
	selBlu = 2'b10;
end

//Yellow coil - Forward Current, Green coil - Reverse Current, Blue coil - High Z
//ylwFW_grnREV: begin
3'b010: begin
	selGrn = 2'b01;
	selYlw = 2'b10;
	selBlu = 2'b00;
end

//Blue coil - Forward Current, Green coil - Reverse Current, Yellow coil - High Z
//bluFW_grnREV: begin
3'b011: begin
	selGrn = 2'b01;
	selYlw = 2'b00;
	selBlu = 2'b10;
end

//Green coil - Forward Current, Blue coil - Reverse Current, Yellow coil - High Z
//grnFW_bluREV: begin
3'b100: begin
	selGrn = 2'b10;
	selYlw = 2'b00;
	selBlu = 2'b01;
end

//Green coil - Forward Current, Yellow coil - Reverse Current, Blue coil - High Z
//grnFW_ylwREV: begin
3'b101: begin
	selGrn = 2'b10;
	selYlw = 2'b01;
	selBlu = 2'b00;
end

//Yellow coil - Forward Current, Blue coil - Reverse Current, Green coil - High Z
//ylwFW_bluREV: begin
3'b110: begin
	selGrn = 2'b00;
	selYlw = 2'b10;
	selBlu = 2'b01;
end

//When rotation state is 3'b111 or 3'b000 shut down both the gates i.e. put all the coils in High Z
default: begin
	selGrn = 2'b00;
	selYlw = 2'b00;
	selBlu = 2'b00;
end
endcase

//Duty cycle is assigned to 11'h600 (75%) while braking else add 0x400 to drv_mag[11:2] for duty cycle in normal operation
assign duty = brake_n ? (drv_mag[11:2] + 11'h400) : 11'h600;

endmodule
