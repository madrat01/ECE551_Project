module desiredDrive(avg_torque, cadence, not_pedaling, incline, scale, target_curr);
///////////////////////////////////////////////////////////////////////////
// Processing sensor inputs to get desired drive using Dataflow verilog //
/////////////////////////////////////////////////////////////////////////
localparam TORQUE_MIN = 12'h380;
input [11:0] avg_torque;	
input [4:0] cadence;
input not_pedaling;
input signed [12:0] incline;
input [2:0] scale;
output logic [11:0] target_curr;

logic signed [9:0] incline_sat;
logic signed [10:0] incline_factor;
logic [8:0] incline_lim;
logic signed [12:0] torque_off;
logic [11:0] torque_pos;
logic [29:0] assist_prod;
logic [5:0] cadence_factor;

assign incline_sat = (!incline[12] && |incline[11:9]) ? 10'h1ff : 
		     (incline[12] && !(&incline[11:9])) ? 10'h200 :
		     incline[9:0];					// The 13 bit signed incline signal is saturated to a 10 bit signed value

assign incline_factor = {{incline_sat[9]}, incline_sat} + 11'h100;	// 10 bit saturated signal is sign extended to 11 bits and adding 256

assign incline_lim = incline_factor[10] ? 9'h0 : (incline_factor[9:0] > 10'h1ff) ? 9'h1ff : incline_factor[8:0];	// If incline_factor was negative clip to zero and if incline_factor was greater than 511 it will be saturated to 511

assign cadence_factor = (cadence > 5'h1) ? ({1'b0,{cadence}} + 6'h20) : 6'h0;	// Adding 32 to cadence if cadence is greater than 1 else set it to zero

assign torque_off =  avg_torque - TORQUE_MIN;	// Subtracting the offset from the force of pedalling coming from the torque sensor

assign torque_pos = torque_off[12] ? 12'h0 : torque_off[11:0];	// Zero clipping torque_off so that negative values are saturated to zero

assign assist_prod = not_pedaling ? 30'h0 : (torque_pos*incline_lim*cadence_factor*scale);	// Calculating the assist needed by the rider from the motor

assign target_curr = (|assist_prod[29:27]) ? 12'hfff : assist_prod[26:15];	// Implementing the target current to ultimately go to PID Controlled

endmodule