module mtr_drv (
    input logic         clk,
    input logic         rst_n,
    input logic [1:0]   selGrn, selYlw, selBlu,
    input logic [10:0]  duty,
    output logic        highBlu, lowBlu,
    output logic        highGrn, lowGrn,
    output logic        highYlw, lowYlw,
    output logic        PWM_synch
);

logic               PWM_sig;

logic               highBlu_in, lowBlu_in;
logic               highGrn_in, lowGrn_in;
logic               highYlw_in, lowYlw_in;

PWM pwm (
    .clk        (clk),
    .rst_n      (rst_n),
    .duty       (duty),
    .PWM_sig    (PWM_sig),
    .PWM_synch  (PWM_synch)
);

nonoverlap nonoverlap_grn (
    .clk        (clk),
    .rst_n      (rst_n),
    .highIn     (highGrn_in),
    .lowIn      (lowGrn_in),
    .highOut    (highGrn),
    .lowOut     (lowGrn)
);

nonoverlap nonoverlap_ylw (
    .clk        (clk),
    .rst_n      (rst_n),
    .highIn     (highYlw_in),
    .lowIn      (lowYlw_in),
    .highOut    (highYlw),
    .lowOut     (lowYlw)
);

nonoverlap nonoverlap_blu (
    .clk        (clk),
    .rst_n      (rst_n),
    .highIn     (highBlu_in),
    .lowIn      (lowBlu_in),
    .highOut    (highBlu),
    .lowOut     (lowBlu)
);

assign highGrn_in = selGrn == 2'b00     ?   1'b0        :
                    selGrn == 2'b01     ?   ~PWM_sig    :
                    selGrn == 2'b10     ?   PWM_sig     : 1'b0;

assign highBlu_in = selBlu == 2'b00     ?   1'b0        :
                    selBlu == 2'b01     ?   ~PWM_sig    :
                    selBlu == 2'b10     ?   PWM_sig     : 1'b0;

assign highYlw_in = selYlw == 2'b00     ?   1'b0        :
                    selYlw == 2'b01     ?   ~PWM_sig    :
                    selYlw == 2'b10     ?   PWM_sig     : 1'b0;

assign lowGrn_in =  selGrn == 2'b00     ?   1'b0        :
                    selGrn == 2'b01     ?   PWM_sig     :
                    selGrn == 2'b10     ?   ~PWM_sig    : PWM_sig;

assign lowBlu_in =  selBlu == 2'b00     ?   1'b0        :
                    selBlu == 2'b01     ?   PWM_sig     :
                    selBlu == 2'b10     ?   ~PWM_sig    : PWM_sig;

assign lowYlw_in =  selYlw == 2'b00     ?   1'b0        :
                    selYlw == 2'b01     ?   PWM_sig     :
                    selYlw == 2'b10     ?   ~PWM_sig    : PWM_sig;

endmodule
