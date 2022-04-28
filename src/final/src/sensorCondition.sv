module sensorCondition #(parameter FAST_SIM = 1) (
    input logic                 clk,
    input logic                 rst_n,
    input logic [11:0]          torque,
    input logic                 cadence_raw,
    input logic [11:0]          curr,
    input logic signed [12:0]   incline,
    input logic [2:0]           scale,
    input logic [11:0]          batt,
    output logic signed [12:0]  error,
    output logic                not_pedaling,
    output logic                TX
);

localparam  W_AVG_CURR = 4;
localparam  W_AVG_TORQUE = 32;
localparam  LOW_BATT_THRES = 12'hA98;

logic           cadence_filt;
logic [4:0]		cadence;
logic [11:0]	target_curr;
logic [7:0]     cadence_per;
logic           pedaling_resumes;
logic           not_pedaling_dly;
logic [11:0]    avg_curr;
logic [11:0]    avg_torque;
logic           smpl_avg_curr;
logic [21:0]    avg_curr_counter;
logic [13:0]    avg_curr_accum_next;
logic [13:0]    avg_curr_accum;
logic           smpl_avg_torque;
logic [16:0]    avg_torque_accum_next;
logic [16:0]    avg_torque_accum;
logic           cadence_rise;
logic           cadence_filt_dly;

//desiredDrive desiredDrive(.avg_torque(avg_torque), .cadence(cadence), .not_pedaling(not_pedaling), .incline(incline), .scale(scale), .target_curr(target_curr));
desiredDrive desiredDrive (.clk (clk), .avg_torque(avg_torque), .cadence(cadence), .not_pedaling(not_pedaling), .incline(incline), .scale(scale), .target_curr(target_curr));

cadence_filt #(.FAST_SIM(FAST_SIM)) cadence_f (.clk (clk), .rst_n(rst_n), .cadence(cadence_raw), .cadence_filt(cadence_filt), .cadence_rise(cadence_rise));

cadence_meas #(.FAST_SIM(FAST_SIM)) cadence_meas (.clk(clk), .rst_n(rst_n), .cadence_filt(cadence_filt), .cadence_rise(cadence_rise), .not_pedaling(not_pedaling), .cadence_per(cadence_per));

cadence_LU cadence_LU(.cadence_per(cadence_per), .cadence(cadence));

telemetry telemetry(.clk(clk), .rst_n(rst_n), .batt_v(batt), .avg_curr(avg_curr), .avg_torque(avg_torque), .TX(TX));

// Detect pedelaing when pendaling resumed
// Flop to capture previous pedaling state
always_ff @ (posedge clk)
    not_pedaling_dly <= not_pedaling;

assign pedaling_resumes = ~not_pedaling & not_pedaling_dly;

// ----------------------------
// --- Avg curr calculation --- 
// ----------------------------

// avg_curr counter to decide when to sample
always_ff @ (posedge clk, negedge rst_n)
    if (~rst_n)
        avg_curr_counter <= 'h0;
    else
        avg_curr_counter <= avg_curr_counter + 1;

// Sample avg curr every X cycles depending on FAST_SIM
generate if (FAST_SIM)
    assign smpl_avg_curr = &avg_curr_counter[15:0];
else
    assign smpl_avg_curr = &avg_curr_counter;
endgenerate

// Exponential average
// accum = ((accum*(W-1))/W) + smpl
assign avg_curr_accum_next = (avg_curr_accum*(W_AVG_CURR-1))/W_AVG_CURR + curr;

// Avg curr is assigned when sample signal is high
always_ff @ (posedge clk, negedge rst_n) begin
    if (~rst_n)
        avg_curr_accum <= 'h0;
    else 
        avg_curr_accum <= smpl_avg_curr ? avg_curr_accum_next : avg_curr_accum;
end

assign avg_curr = avg_curr_accum[13:2];

// ------------------------------
// --- Avg torque calculation --- 
// ------------------------------

// Torque is sampled at cadence rise
assign smpl_avg_torque = cadence_rise;

// Exponential average
// accum = ((accum*(W-1))/W) + smpl
assign avg_torque_accum_next = (avg_torque_accum*(W_AVG_TORQUE-1))/W_AVG_TORQUE + torque;

// Avg torque is assigned when sample signal is high
always_ff @ (posedge clk, negedge rst_n) begin
    if (~rst_n)
        avg_torque_accum <= 'h0;
    else
        // seed avg torque when pedaling resumes 
        avg_torque_accum <= pedaling_resumes ? {1'b0, torque, 4'b0000} : (smpl_avg_torque ? avg_torque_accum_next : avg_torque_accum);
end

assign avg_torque = avg_torque_accum[16:5];

// -----------------
// Error calculation
// -----------------

assign error =  not_pedaling            ? 'b0 : 
                batt < LOW_BATT_THRES   ? 'b0 : target_curr - avg_curr; 

endmodule