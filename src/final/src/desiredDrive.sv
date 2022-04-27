module desiredDrive (
	input logic					clk,
	input logic [11:0]			avg_torque,
	input logic [4:0]			cadence,
	input logic					not_pedaling,
	input logic signed [12:0] 	incline,
	input logic [2:0]			scale,
	output logic [11:0]			target_curr
);

logic signed [9:0] 	incline_sat;
logic signed [10:0] incline_factor;
logic [8:0] 		incline_lim;
logic signed [12:0] torque_off; 
logic [11:0]		torque_pos;
logic [29:0]		assist_prod;
logic [5:0]			cadence_factor;

localparam TORQUE_MIN = 12'h380;

assign incline_sat = (~incline[12] & |incline[11:9]) ? 10'h1ff   : 
                     (incline[12] & ~&incline[11:9]) ? 10'h200   :
                     incline[9:0];

assign incline_factor = {incline_sat[9], incline_sat[9:0]} + 256;

assign incline_lim = incline_factor[10] ? 9'b0 :		// Negative then 0 off
		     incline_factor[9] ? 9'd511 :		// Greater than 511 
		     incline_factor[8:0];

assign cadence_factor = cadence > 1 ? cadence + 32 : 0;				

assign torque_off = {1'b0, avg_torque} - {1'b0, TORQUE_MIN};

assign torque_pos = torque_off[12] ? 12'b0 : torque_off[11:0];

assign assist_prod = ~not_pedaling ? torque_pos * scale * cadence_factor * incline_lim : 30'b0;

assign target_curr = |assist_prod[29:27] ? 12'hFFF : assist_prod[26:15];

endmodule
