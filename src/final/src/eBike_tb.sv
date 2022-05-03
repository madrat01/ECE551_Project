`timescale 1ns/1ps

module eBike_tb();
 
// include or import tasks?

localparam FAST_SIM = 1;		// accelerate simulation by default

///////////////////////////
// Stimulus of type reg //
/////////////////////////
reg clk,RST_n;
reg [11:0] BATT;				// analog values
reg [11:0] BRAKE,TORQUE;		// analog values
reg tgglMd;					// push button for assist mode
reg [15:0] YAW_RT;			// models angular rate of incline (+ => uphill)


//////////////////////////////////////////////////
// Declare any internal signal to interconnect //
////////////////////////////////////////////////
wire A2D_SS_n,A2D_MOSI,A2D_SCLK,A2D_MISO;
wire highGrn,lowGrn,highYlw,lowYlw,highBlu,lowBlu;
wire hallGrn,hallBlu,hallYlw;
wire inertSS_n,inertSCLK,inertMISO,inertMOSI,inertINT;
logic cadence;
wire [1:0] LED;			// hook to setting from PB_intf

wire signed [11:0] coilGY,coilYB,coilBG;
logic [11:0] curr;		// comes from hub_wheel_model
logic [11:0] BATT_TX, TORQUE_TX, CURR_TX;
logic vld_TX;

logic cadence_disable, cadence_increase;
logic [11:0] avg_curr_prev;
logic [19:0] omega_prev;
logic TX_RX, rdy;
logic [7:0] rx_data;
//////////////////////////////////////////////////
// Instantiate model of analog input circuitry //
////////////////////////////////////////////////
AnalogModel iANLG(.clk(clk),.rst_n(RST_n),.SS_n(A2D_SS_n),.SCLK(A2D_SCLK),
                  .MISO(A2D_MISO),.MOSI(A2D_MOSI),.BATT(BATT),
    .CURR(curr),.BRAKE(BRAKE),.TORQUE(TORQUE));

////////////////////////////////////////////////////////////////
// Instantiate model inertial sensor used to measure incline //
//////////////////////////////////////////////////////////////
eBikePhysics iPHYS(.clk(clk),.RST_n(RST_n),.SS_n(inertSS_n),.SCLK(inertSCLK),
            .MISO(inertMISO),.MOSI(inertMOSI),.INT(inertINT),
     .yaw_rt(YAW_RT),.highGrn(highGrn),.lowGrn(lowGrn),
     .highYlw(highYlw),.lowYlw(lowYlw),.highBlu(highBlu),
     .lowBlu(lowBlu),.hallGrn(hallGrn),.hallYlw(hallYlw),
     .hallBlu(hallBlu),.avg_curr(curr));

//////////////////////
// Instantiate DUT //
////////////////////
//eBike #(FAST_SIM) iDUT(.clk(clk),.RST_n(RST_n),.A2D_SS_n(A2D_SS_n),.A2D_MOSI(A2D_MOSI),
//                       .A2D_SCLK(A2D_SCLK),.A2D_MISO(A2D_MISO),.hallGrn(hallGrn),
//	 .hallYlw(hallYlw),.hallBlu(hallBlu),.highGrn(highGrn),
//	 .lowGrn(lowGrn),.highYlw(highYlw),.lowYlw(lowYlw),
//	 .highBlu(highBlu),.lowBlu(lowBlu),.inertSS_n(inertSS_n),
//	 .inertSCLK(inertSCLK),.inertMOSI(inertMOSI),
//	 .inertMISO(inertMISO),.inertINT(inertINT),
//	 .cadence(cadence),.tgglMd(tgglMd),.TX(TX_RX),
//	 .LED(LED));

eBike iDUT(.clk(clk),.RST_n(RST_n),.A2D_SS_n(A2D_SS_n),.A2D_MOSI(A2D_MOSI),
                       .A2D_SCLK(A2D_SCLK),.A2D_MISO(A2D_MISO),.hallGrn(hallGrn),
	 .hallYlw(hallYlw),.hallBlu(hallBlu),.highGrn(highGrn),
	 .lowGrn(lowGrn),.highYlw(highYlw),.lowYlw(lowYlw),
	 .highBlu(highBlu),.lowBlu(lowBlu),.inertSS_n(inertSS_n),
	 .inertSCLK(inertSCLK),.inertMOSI(inertMOSI),
	 .inertMISO(inertMISO),.inertINT(inertINT),
	 .cadence(cadence),.tgglMd(tgglMd),.TX(TX_RX),
	 .LED(LED));	 
	 
////////////////////////////////////////////////////////////
// Instantiate UART_rcv or some other telemetry monitor? //
//////////////////////////////////////////////////////////
UART_rcv UART_rcv_tb(.clk(clk), .rst_n(RST_n), .RX(TX_RX), .rdy(rdy), .rx_data(rx_data), .clr_rdy(rdy));
	 
initial begin
//<your magic here>
cadence_increase = 0;
cadence_disable = 0;
clk = 0;
RST_n = 0;
TORQUE = 12'h0;
BATT = 12'hFFF;
BRAKE = 12'hFFF;
YAW_RT = 16'h0;
tgglMd = 1'b0;
cadence = 1;
@(posedge clk);
@(negedge clk);
RST_n = 1; 	
TORQUE = 12'h700;
repeat(2000000) @(posedge clk);
//TEST 1: When battery drops below threshold the error should be zero
BATT = 12'h0;
repeat(2000000) @(posedge clk);
if(iDUT.sensorCondition.error !== 0) begin
	$display("ERROR: Error signal doesnt drop down to 0 when Battery falls below threshold A98, Error %h", iDUT.sensorCondition.error);
	$stop();
end
//Increasing the battery beyond threshold so that the error is no longer zero
BATT = 12'hFFF;
repeat(2000000) @(posedge clk);
if(iDUT.sensorCondition.error === 0) begin
	$display("ERROR: Error signal is 0 when Battery goes above the threshold A98, Error %h", iDUT.sensorCondition.error);
	$stop();
end

//TEST 2: When Torque reduces the Avg current and omega should decrease
avg_curr_prev = iDUT.sensorCondition.avg_curr;
omega_prev = iPHYS.omega;
TORQUE = 12'h500;
repeat(2000000) @(posedge clk);
if(avg_curr_prev < iDUT.sensorCondition.avg_curr || omega_prev < iPHYS.omega) begin
	$display("ERROR: With the decrease in torque the average current and omega doesn't go down, Omega %h Prev_omega %h Avg Curr %h Prev_Avg_Curr %h  %t", iPHYS.omega, omega_prev, iDUT.sensorCondition.avg_curr, avg_curr_prev, $time);
	$stop();	
end
//When Torque increases the Avg current and omega should increase
avg_curr_prev = iDUT.sensorCondition.avg_curr;
omega_prev = iPHYS.omega;
TORQUE = 12'h700;
repeat(2000000) @(posedge clk);
if(avg_curr_prev > iDUT.sensorCondition.avg_curr || omega_prev > iPHYS.omega) begin
	$display("ERROR: With the increase in torque the average current and omega doesn't go up, Omega %h Prev_omega %h Avg Curr %h Prev_Avg_Curr %h  %t", iPHYS.omega, omega_prev, iDUT.sensorCondition.avg_curr, avg_curr_prev, $time);
	$stop();	
end

//TEST 3: Increasing the cadence to check the increase in omega and average current
avg_curr_prev = iDUT.sensorCondition.avg_curr;
omega_prev = iPHYS.omega;
cadence_increase = 1;
repeat(2000000) @(posedge clk);
if(avg_curr_prev > iDUT.sensorCondition.avg_curr || omega_prev > iPHYS.omega) begin
	$display("ERROR: With the increase in cadence the average current and omega doesn't go up, Omega %h Prev_omega %h Avg Curr %h Prev_Avg_Curr %h  %t", iPHYS.omega, omega_prev, iDUT.sensorCondition.avg_curr, avg_curr_prev, $time);
	$stop();	
end
//Decreasing the cadence to check the decrease in omega and average current
avg_curr_prev = iDUT.sensorCondition.avg_curr;
omega_prev = iPHYS.omega;
cadence_increase = 0;
repeat(2000000) @(posedge clk);
if(avg_curr_prev < iDUT.sensorCondition.avg_curr || omega_prev < iPHYS.omega) begin
	$display("ERROR: With the decrease in cadence the average current and omega doesn't go down, Omega %h Prev_omega %h Avg Curr %h Prev_Avg_Curr %h  %t", iPHYS.omega, omega_prev, iDUT.sensorCondition.avg_curr, avg_curr_prev, $time);
	$stop();	
end

//TEST 4: BRAKE testing
//Appplying brake should reduce the average current and omega
avg_curr_prev = iDUT.sensorCondition.avg_curr;
omega_prev = 16'h40; //Low value of Omega
BRAKE = 12'h000;
repeat(2000000) @(posedge clk);
if(iDUT.sensorCondition.avg_curr !== 0 || omega_prev < iPHYS.omega) begin
	$display("ERROR: With the application of brake the average current and omega doesn't go down, Omega %h Prev_omega %h Avg Curr %h Prev_Avg_Curr %h  %t", iPHYS.omega, omega_prev, iDUT.sensorCondition.avg_curr, avg_curr_prev, $time);
	$stop();	
end
//Release of brake should increase the average current and omega
avg_curr_prev = iDUT.sensorCondition.avg_curr;
omega_prev = iPHYS.omega;
BRAKE = 12'hFFF;
repeat(2000000) @(posedge clk);
if(avg_curr_prev > iDUT.sensorCondition.avg_curr || omega_prev > iPHYS.omega) begin
	$display("ERROR: With the release of brake the average current and omega doesn't go up, Omega %h Prev_omega %h Avg Curr %h Prev_Avg_Curr %h  %t", iPHYS.omega, omega_prev, iDUT.sensorCondition.avg_curr, avg_curr_prev, $time);
	$stop();	
end

//TEST 5: Incline Testing
//Reducing YAW should reduce the Average current and omega i.e. we are going downhill so less assist
avg_curr_prev = iDUT.sensorCondition.avg_curr;
omega_prev = iPHYS.omega;
YAW_RT = 16'hDEAD;
repeat(2000000) @(posedge clk);
if(avg_curr_prev < iDUT.sensorCondition.avg_curr || omega_prev < iPHYS.omega) begin
	$display("ERROR: With the decrease in YAW(Downhill) the average current and omega doesn't go down, Omega %h Prev_omega %h Avg Curr %h Prev_Avg_Curr %h  %t", iPHYS.omega, omega_prev, iDUT.sensorCondition.avg_curr, avg_curr_prev, $time);
	$stop();	
end
//Increasing YAW should increase the average current and omega i.e. we are going uphill and rider requires assist
avg_curr_prev = iDUT.sensorCondition.avg_curr;
omega_prev = iPHYS.omega;
YAW_RT = 16'h7FFF;
repeat(2000000) @(posedge clk);
if(avg_curr_prev > iDUT.sensorCondition.avg_curr || omega_prev > iPHYS.omega) begin
	$display("ERROR: With the increase in YAW(Uphill) the average current and omega doesn't go up, Omega %h Prev_omega %h Avg Curr %h Prev_Avg_Curr %h  %t", iPHYS.omega, omega_prev, iDUT.sensorCondition.avg_curr, avg_curr_prev, $time);
	$stop();	
end
YAW_RT = 16'h0;
repeat(2000000) @(posedge clk);

//TEST 6: Chaging the assist setting based on rider preference - Default: Medium Assist 
//Toggle tgglMd to move to high assist which should increase the omega
omega_prev = iPHYS.omega;
@(posedge clk)
tgglMd = 1'b1;
@(posedge clk)
tgglMd = 1'b0;
repeat(2000000) @(posedge clk);
if(omega_prev > iPHYS.omega) begin
	$display("ERROR: With the Rider's selction of high assist the omega doesn't go up, Omega %h Prev_omega %h %t", iPHYS.omega, omega_prev, $time);
	$stop();	
end

//Toggle tgglMd to move to low assist which should decrease the omega
omega_prev = iPHYS.omega;
@(posedge clk)
tgglMd = 1'b1;
@(posedge clk)
tgglMd = 1'b0;
repeat(2000000) @(posedge clk);
if(omega_prev < iPHYS.omega) begin
	$display("ERROR: With the Rider's selction of no assist omega doesn't go down, Omega %h Prev_omega %h %t", iPHYS.omega, omega_prev, $time);
	$stop();	
end

//Toggle tgglMd to move to low assist from no assist which should increase omega
omega_prev = iPHYS.omega;
@(posedge clk)
tgglMd = 1'b1;
@(posedge clk)
tgglMd = 1'b0;
repeat(2000000) @(posedge clk);
if(omega_prev > iPHYS.omega) begin
	$display("ERROR: With the Rider's selction of low assist from no assist omega doesn't go up, Omega %h Prev_omega %h %t", iPHYS.omega, omega_prev, $time);
	$stop();	
end

//Toggle tgglMd to move to Medium assist (default) from low assist which should increase omega
omega_prev = iPHYS.omega;
@(posedge clk)
tgglMd = 1'b1;
@(posedge clk)
tgglMd = 1'b0;
repeat(2000000) @(posedge clk);
if(omega_prev > iPHYS.omega) begin
	$display("ERROR: With the Rider's selction of medium assist from low assist omega doesn't go up, Omega %h Prev_omega %h %t", iPHYS.omega, omega_prev, $time);
	$stop();	
end

//TEST 7: Telemetry test - Check if this can be run all the time in parallel
@(posedge iDUT.sensorCondition.telemetry.trmt);
@(posedge rdy);
if(rx_data !== 8'haa)		// Check for delim1 data at UART reciever
begin
	$display("ERROR: Deliml data does not match. Expected data 0xaa Simulated data %h", rx_data);
	$stop();
end

@(posedge rdy);			// Wait for rdy at UART reciever after transfering delim2 data
if(rx_data !== 8'h55)		// Check for delim2 data at UART reciever
begin
	$display("ERROR: Delim2 data does not match. Expected data 0x55 Simulated data %h", rx_data);
	$stop();
end

@(posedge iDUT.sensorCondition.telemetry.trmt);
BATT_TX = iDUT.sensorCondition.batt;
@(posedge rdy);			// Wait for rdy at UART reciever after transfering payload1 data
if(rx_data !== {4'b0000,BATT_TX[11:8]})		// Check for payload1 data at UART reciever
begin
	$display("ERROR: Payload1 data does not match. Expected data %h Simulated data %h", BATT_TX[11:8], rx_data);
	$stop();
end
@(posedge rdy);			// Wait for rdy at UART reciever after transfering payload2 data
if(rx_data !== BATT_TX[7:0])		// Check for payload2 data at UART reciever
begin
	$display("ERROR: Payload2 data does not match. Expected data %h Simulated data %h", BATT_TX[7:0], rx_data);
	$stop();
end

@(posedge iDUT.sensorCondition.telemetry.trmt);
CURR_TX = iDUT.sensorCondition.avg_curr;
@(posedge rdy);			// Wait for rdy at UART reciever after transfering payload3 data
if(rx_data !== {4'b0000,CURR_TX[11:8]})		// Check for payload3 data at UART reciever
begin
	$display("ERROR: Payload3 data does not match. Expected data %h Simulated data %h", CURR_TX[11:8], rx_data);
	$stop();
end
@(posedge iDUT.sensorCondition.telemetry.trmt);
CURR_TX = iDUT.sensorCondition.avg_curr;
@(posedge rdy);			// Wait for rdy at UART reciever after transfering payload4 data
if(rx_data !== CURR_TX[7:0])		// Check for payload4 data at UART reciever
begin
	$display("ERROR: Payload4 data does not match. Expected data %h Simulated data %h %t", CURR_TX[7:0], rx_data, $time);
	$stop();
end

@(posedge iDUT.sensorCondition.telemetry.trmt);
TORQUE_TX = iDUT.sensorCondition.avg_torque;
@(posedge rdy);			// Wait for rdy at UART reciever after transfering payload3 data
if(rx_data !== {4'b0000,TORQUE_TX[11:8]})		// Check for payload3 data at UART reciever
begin
	$display("ERROR: Payload5 data does not match. Expected data %h Simulated data %h", TORQUE_TX[11:8], rx_data);
	$stop();
end
@(posedge rdy);			// Wait for rdy at UART reciever after transfering payload4 data
if(rx_data !== TORQUE_TX[7:0])		// Check for payload4 data at UART reciever
begin
	$display("ERROR: Payload6 data does not match. Expected data %h Simulated data %h", TORQUE_TX[7:0], rx_data);
	$stop();
end

repeat(2000000) @(posedge clk);
$stop();
end

always begin
	if(cadence_increase)
		repeat (1024) @ (posedge clk);
	else
		repeat (2048) @ (posedge clk);
	//@ (negedge clk);
	if(cadence_disable) begin
		cadence = 0;
	end else begin
		cadence = ~cadence;
	end
end  

///////////////////
// Generate clk //
/////////////////
always
  #2 clk = ~clk;

///////////////////////////////////////////
// Block for cadence signal generation? //
/////////////////////////////////////////
	
endmodule
