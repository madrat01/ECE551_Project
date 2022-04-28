module PID
#(parameter FAST_SIM = 0)
(
    input logic                 clk,
    input logic                 rst_n,
    input logic signed [12:0]   error,
    input logic                 not_pedaling,
    output logic [11:0]         drv_mag
);

logic signed [13:0]     P_term;
logic signed [11:0]     I_term;
logic signed [9:0]      D_term;
logic signed [13:0]     P_term_dly;
logic signed [11:0]     I_term_dly;
logic signed [9:0]      D_term_dly;
logic signed [13:0]     PID;
logic signed [12:0]     error_d2, error_d3, prev_err; 
logic signed [12:0]     D_diff;
logic signed [8:0]      D_diff_sat;
logic signed [19:0]     decimator;
logic signed [17:0]     integrator;
logic signed [17:0]     nxt_integrator;
logic                   pos_overflow;
logic signed [17:0]     integrator_accum;
logic signed [17:0]     integrator_plus_error;
logic signed [17:0]     allowed_integrator;
logic 	     [17:0]	integrator_saturated;
logic                   decimator_full;
logic 	     [11:0]	drv_mag_pre;

generate 
if (FAST_SIM)
    assign decimator_full = &decimator[14:0];
else
    assign decimator_full = &decimator;
endgenerate

// possibly next integrator
assign integrator_plus_error = {{5{error[12]}}, error[12:0]} + integrator;

// intergrator accum is not allowed to go negative, clip of to 18'h0 if goes negative
assign integrator_accum = integrator_plus_error[17] ? 18'h0 : integrator_plus_error;

// Check for positive overflow - integrator + error flips the sign bit of the integrator (i.e. goes from 0->1)
assign pos_overflow = integrator_plus_error[17] & integrator[16];
assign integrator_saturated = pos_overflow ? 18'h1FFFF : integrator_accum;
// integrator is allowed to integrate only 1/48 times a second
//assign allowed_integrator = decimator == 20'hfe502 ? (pos_overflow ? 18'h1FFFF : integrator_accum) : integrator;
assign allowed_integrator = decimator_full ? integrator_saturated : integrator;

// clear wound up integrator when rider stops pedaling
assign nxt_integrator = not_pedaling ? 18'h0 : allowed_integrator;

// Integrator flop
always_ff @ (posedge clk or negedge rst_n) begin
    if (!rst_n)
        integrator <= 18'b0;
    else
        integrator <= nxt_integrator;
end

assign I_term = integrator[16:5];

// P term is error*1
assign P_term = {error[12], error};

// Decimator to count till 20'hfe502
// Since we need to send a payload every 48 times a second and our frequency is 50MHz
always_ff @ (posedge clk or negedge rst_n) begin
    if (~rst_n)
        decimator <= 20'b0;
    else
        decimator <= decimator + 1;
end

// Errors get new value every 1/48 times a second
always_ff @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        error_d2 <= 'b0;
        error_d3 <= 'b0;
        prev_err <= 'b0;
    end
    else if (decimator_full) begin
        error_d2 <= error;
        error_d3 <= error_d2;
        prev_err <= error_d3;
    end
end

// D diff (dervative) is current error - previous error (3 times previous)
assign D_diff = error - prev_err;

// Saturate D_ff to 9 bits
assign D_diff_sat = (~D_diff[12] & |D_diff[11:8]) ? 9'h0FF :
                    (D_diff[12] & ~&D_diff[11:8]) ? 9'h100 :
                    D_diff[8:0];

// D term is Signed multiply of the derivative by 2
assign D_term = {D_diff_sat, 1'b0};

always_ff @ (posedge clk) begin
    P_term_dly <= P_term;
    I_term_dly <= I_term;
    D_term_dly <= D_term;
end

//Computer PID
assign PID = P_term_dly + {2'b00, I_term_dly} + {{4{D_term_dly[9]}}, D_term_dly};

//Saturating PID to 0xFFF if it exceeds 0xFFF
assign drv_mag_pre = PID[12] ? 12'hFFF : PID[11:0];

//If PID is negative clip it to zero
assign drv_mag = PID[13] ? 12'h0 : drv_mag_pre;

endmodule
