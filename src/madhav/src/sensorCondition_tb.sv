module sensorCondition_tb ();

logic                 clk;
logic                 rst_n;
logic [11:0]          torque;
logic                 cadence_raw;
logic [11:0]          curr;
logic signed [12:0]   incline;
logic [2:0]           scale;
logic [11:0]          batt;
logic signed [12:0]   error;
logic                 not_pedaling;
logic                 TX;

sensorCondition sc (.clk(clk), .rst_n(rst_n), .torque(torque), .cadence_raw(cadence_raw), .curr(curr), .incline(incline), .scale(scale), .batt(batt), .error(error), .not_pedaling(not_pedaling), .TX(TX));

initial begin
    clk = 1'b0;
end

always
    #2 clk = ~clk;

initial begin
    rst_n = 0;
    curr = 12'h3ff;
    torque = 12'h2ff;
    repeat (5) @ (posedge clk);
    @ (negedge clk);
    rst_n = 1;
end

initial begin
    for (int i = 0; i < 50; i++) begin
        cadence_raw = 1;
        repeat (2048) @ (posedge clk);
        cadence_raw = 0;
        repeat (2048) @ (posedge clk);
    end
    @ (posedge clk);
    $stop();
end

endmodule