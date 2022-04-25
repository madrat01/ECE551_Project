module desiredDrive_rnd_tb ();

reg [33:0] mem_stim[1500];
reg [11:0] mem_resp[1500];

logic               clk;

logic [11:0]		avg_torque;
logic [4:0]		    cadence;
logic			    not_pedaling;
logic signed [12:0] incline;
logic [2:0]		    scale;
logic [11:0]		target_curr;

logic               pass;

desiredDrive dd (
	.avg_torque	    (avg_torque),
	.cadence	    (cadence),
	.not_pedaling	(not_pedaling),
	.incline	    (incline),
	.scale		    (scale),
	.target_curr	(target_curr)
);

initial begin
    clk = 1'b0;
    $readmemh("desiredDrive_stim.hex", mem_stim);
    $readmemh("desiredDrive_resp.hex", mem_resp);
end

always begin
    #10 clk = ~clk;
end

initial begin
    pass = 1;
    @ (posedge clk);
    for (int i = 0; i < 1500; i++) begin
        avg_torque = mem_stim[i][33:22];
        cadence = mem_stim[i][21:17];
        not_pedaling = mem_stim[i][16];
        incline = mem_stim[i][15:3];
        scale = mem_stim[i][2:0];
        #1
        if (target_curr != mem_resp[i]) begin
            $display("Response mismatch, index %d", i);
            pass = 0;
        end
    end
    if (pass)
        $display("Test passed!! :)");
    repeat (2) @ (posedge clk);
    $stop();
end

endmodule