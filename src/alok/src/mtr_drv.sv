module mtr_drv(clk, rst_n, duty, selGrn, selYlw, selBlu, PWM_synch, highGrn, lowGrn, highYlw, lowYlw, highBlu, lowBlu);
//////////////////////////////////////////////////////////////////////////////////////////////////
// The module to determine the coil drive state for brushless motor drive along with duty cycle//
////////////////////////////////////////////////////////////////////////////////////////////////

input clk, rst_n;
input [10:0] duty;
input [1:0] selGrn, selYlw, selBlu;

output logic PWM_synch, highGrn, lowGrn, highYlw, lowYlw, highBlu, lowBlu;

logic PWM_sig, highIn_grn, lowIn_grn, highIn_ylw, lowIn_ylw, highIn_blu, lowIn_blu;

//Instantiate the PWM module to produce PWM signal of specified duty cycle
PWM PWM_inst(.clk(clk), .rst_n(rst_n), .duty(duty), .PWM_sig(PWM_sig), .PWM_synch(PWM_synch));

//Genrate the highIn and lowIn inputs for the nonoverlap for green coil
assign highIn_grn = selGrn[1] ? (selGrn[0] ? 1'b0 : PWM_sig) : (selGrn[0] ? ~PWM_sig : 1'b0);
assign lowIn_grn = selGrn[1] ? (selGrn[0] ? PWM_sig : ~PWM_sig) : (selGrn[0] ? PWM_sig : 1'b0);

//Genrate the highIn and lowIn inputs for the nonoverlap for yellow coil
assign highIn_ylw = selYlw[1] ? (selYlw[0] ? 1'b0 : PWM_sig) : (selYlw[0] ? ~PWM_sig : 1'b0);
assign lowIn_ylw = selYlw[1] ? (selYlw[0] ? PWM_sig : ~PWM_sig) : (selYlw[0] ? PWM_sig : 1'b0);

//Genrate the highIn and lowIn inputs for the nonoverlap for blue coil
assign highIn_blu = selBlu[1] ? (selBlu[0] ? 1'b0 : PWM_sig) : (selBlu[0] ? ~PWM_sig : 1'b0);
assign lowIn_blu = selBlu[1] ? (selBlu[0] ? PWM_sig : ~PWM_sig) : (selBlu[0] ? PWM_sig : 1'b0);

//Non Overlap block for the green coil
nonoverlap NOLP1(.clk(clk), .rst_n(rst_n), .highIn(highIn_grn), .lowIn(lowIn_grn), .highOut(highGrn), .lowOut(lowGrn));
//Non Overlap block for the yellow coil
nonoverlap NOLP2(.clk(clk), .rst_n(rst_n), .highIn(highIn_ylw), .lowIn(lowIn_ylw), .highOut(highYlw), .lowOut(lowYlw));
//Non Overlap block for the blue coil
nonoverlap NOLP3(.clk(clk), .rst_n(rst_n), .highIn(highIn_blu), .lowIn(lowIn_blu), .highOut(highBlu), .lowOut(lowBlu));

endmodule