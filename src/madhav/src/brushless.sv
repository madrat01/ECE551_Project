module brushless (
    input logic         clk,
    input logic         rst_n,
    input logic [11:0]  drv_mag,
    input logic         hallGrn,
    input logic         hallYlw,
    input logic         hallBlu,
    input logic         brake_n,
    input logic         PWM_synch,
    output logic [10:0] duty,
    output logic [1:0]  selGrn,
    output logic [1:0]  selYlw,
    output logic [1:0]  selBlu
);

logic       hallGrn_d2, hallGrn_d3, synchGrn;
logic       hallBlu_d2, hallBlu_d3, synchBlu;
logic       hallYlw_d2, hallYlw_d3, synchYlw;

logic [2:0] rotationState;

// Blocks to synchronize green wire
always_ff @(posedge clk) begin
    hallGrn_d2 <= hallGrn;
    hallGrn_d3 <= hallGrn_d2;
end

always_ff @(posedge clk or negedge rst_n) begin : synchGrn_blk
    if (~rst_n)
        synchGrn <= 1'b0;
    else
        synchGrn <= PWM_synch ? hallGrn_d3 : synchGrn;
end

// Blocks to synchronize blue wire
always_ff @(posedge clk) begin
    hallBlu_d2 <= hallBlu;
    hallBlu_d3 <= hallBlu_d2;
end

always_ff @(posedge clk or negedge rst_n) begin : synchBlu_blk
    if (~rst_n)
        synchBlu <= 1'b0;
    else
        synchBlu <= PWM_synch ? hallBlu_d3 : synchBlu;
end

// Blocks to synchronize yellow wire
always_ff @(posedge clk) begin
    hallYlw_d2 <= hallYlw;
    hallYlw_d3 <= hallYlw_d2;
end

always_ff @(posedge clk or negedge rst_n) begin : synchYlw_blk
    if (~rst_n)
        synchYlw <= 1'b0;
    else
        synchYlw <= PWM_synch ? hallYlw_d3 : synchYlw;
end

// Rotation state depends on current drive of green, yellow and blue wires
assign rotationState = {synchGrn, synchYlw, synchBlu};

// 2'b11 : Regenerative braking, 2'b10: forward current, 2'b01: reverse current, 2'b00: high_z
assign selGrn = ~brake_n                                           ?  2'b11 : 
                rotationState == 3'b101 | rotationState == 3'b100  ?  2'b10 :
                rotationState == 3'b010 | rotationState == 3'b011  ?  2'b01 : 2'b00;  
assign selYlw = ~brake_n                                           ?  2'b11 : 
                rotationState == 3'b110 | rotationState == 3'b010  ?  2'b10 :
                rotationState == 3'b101 | rotationState == 3'b001  ?  2'b01 : 2'b00;

assign selBlu = ~brake_n                                           ?  2'b11 : 
                rotationState == 3'b011 | rotationState == 3'b001  ?  2'b10 :
                rotationState == 3'b100 | rotationState == 3'b110  ?  2'b01 : 2'b00;

// If normal operation, drive PWM at drv_mag[11:2] + 11'h400 else dirve at 11'h600 (75%)
assign duty = brake_n ? drv_mag[11:2] + 11'h400 : 11'h600;

endmodule
