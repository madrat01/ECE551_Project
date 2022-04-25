module PID_tb();

logic clk,rst_n;
logic [11:0] drv_mag;
logic signed [12:0] error;
logic not_pedaling;
logic test_over;

//Instantiate the model of plant
plant_PID plant_PID_DUT( .clk(clk), .rst_n(rst_n), .drv_mag(drv_mag), .error(error), .not_pedaling(not_pedaling), .test_over(test_over));

//Instantiate the PID DUT
PID #(.FAST_SIM(1)) PID_DUT( .clk(clk), .rst_n(rst_n), .error(error), .not_pedaling(not_pedaling), .drv_mag(drv_mag));

initial begin
//Initialize clk and rst_n to 0
clk = 0;
rst_n = 0;
//Lift the reset in the negative edge of clock
@(negedge clk);
rst_n = 1;
//Wait for test_over signal coming from plant_PID to assert 
@(posedge test_over);
$stop();
end    

always #5 clk = ~clk;

endmodule

