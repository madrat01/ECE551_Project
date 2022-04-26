module inert_intf(clk, rst_n, INT, MISO, SS_n, SCLK, MOSI, incline, vld);
input clk, rst_n, INT, MISO;
output logic SS_n, SCLK, MOSI, vld;
output logic [12:0] incline;

logic INT_ff1, INT_ff2;
logic [15:0] timer;

logic snd, done;
logic [15:0] cmd, resp;

logic [15:0] roll_rt, yaw_rt, AY, AZ;
logic [7:0] roll_L, roll_H, yaw_L, yaw_H, ay_L, ay_H, az_L, az_H;
logic C_R_H_en, C_R_L_en, C_Y_H_en, C_Y_L_en, C_AY_H_en, C_AY_L_en, C_AZ_H_en, C_AZ_L_en;

typedef enum logic [3:0] {IDLE, INT_EN, SETUP_ACCEL, SETUP_GYRO, EN_ROUNDING, WAIT, ROLL_L, ROLL_H, YAW_L, YAW_H, AY_L, AY_H, AZ_L, AZ_H, VALID} state_t;
state_t state, nxt_state;

SPI_mnrch SPI_DUT( .clk(clk), .rst_n(rst_n), .MISO(MISO), .snd(snd), .cmd(cmd), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .done(done), .resp(resp));

inertial_integrator inertial_integrator_DUT( .clk(clk), .rst_n(rst_n), .vld(vld), .roll_rt(roll_rt), .yaw_rt(yaw_rt), .AY(AY), .AZ(AZ), .incline(incline), .LED());

always @(posedge clk, negedge rst_n)
	if(!rst_n) begin
		INT_ff1 <= 0;
		INT_ff2 <= 0;
	end else begin
		INT_ff1 <= INT;
		INT_ff2 <= INT_ff1;
	end

always @(posedge clk, negedge rst_n)
	if(!rst_n)
		timer <= 0;
	else if(timer < 16'hffff)
		timer <= timer + 1;

always @(posedge clk, negedge rst_n)	
	if(!rst_n)
		state <= IDLE;
	else 
		state <= nxt_state;

always_comb 
begin
snd = 0;
cmd = 0;
vld = 0;
C_R_H_en = 0;
C_R_L_en = 0; 
C_Y_H_en = 0; 
C_Y_L_en = 0;
C_AY_H_en = 0; 
C_AY_L_en = 0;
C_AZ_H_en = 0;
C_AZ_L_en = 0;
nxt_state = state;

case(state)
default: begin
	if(&timer) begin
		cmd = 16'h0D02;
		snd = 1;
		nxt_state = INT_EN;
	end
end

INT_EN: begin
	if(done) begin
		cmd = 16'h1053;
		snd = 1;
		nxt_state = SETUP_ACCEL;
	end
end

SETUP_ACCEL: begin
	if(done) begin
		cmd = 16'h1150;
		snd = 1;
		nxt_state = SETUP_GYRO;
	end
end

SETUP_GYRO: begin
	if(done) begin
		cmd = 16'h1460;
		snd = 1;
		nxt_state = EN_ROUNDING;
	end
end

EN_ROUNDING: begin
	if(done) begin
		nxt_state = WAIT;
	end
end

WAIT: begin
	if(INT_ff2) begin
		cmd = 16'hA400;
		snd = 1;
		nxt_state = ROLL_L;
	end
end

ROLL_L: begin
	if(done) begin
		C_R_L_en = 1;
		cmd = 16'hA500;
		snd = 1;
		nxt_state = ROLL_H;
	end
end 

ROLL_H: begin
	if(done) begin
		C_R_H_en = 1;
		cmd = 16'hA600;
		snd = 1;
		nxt_state = YAW_L;
	end
end 

YAW_L: begin
	if(done) begin
		C_Y_L_en = 1;
		cmd = 16'hA700;
		snd = 1;
		nxt_state = YAW_H;
	end
end 

YAW_H: begin
	if(done) begin
		C_Y_H_en = 1;
		cmd = 16'hAA00;
		snd = 1;
		nxt_state = AY_L;
	end
end 

AY_L: begin
	if(done) begin
		C_AY_L_en = 1;
		cmd = 16'hAB00;
		snd = 1;
		nxt_state = AY_H;
	end
end 
 
AY_H: begin
	if(done) begin
		C_AY_H_en = 1;
		cmd = 16'hAC00;
		snd = 1;
		nxt_state = AZ_L;
	end
end 
  
AZ_L: begin
	if(done) begin
		C_AZ_L_en = 1;
		cmd = 16'hAD00;
		snd = 1;
		nxt_state = AZ_H;
	end
end 
 
AZ_H: begin
	if(done) begin
		C_AZ_H_en = 1;
		nxt_state = VALID;
	end
end

VALID: begin
		vld = 1;
		nxt_state = WAIT;
end

endcase 
end //always comb

//logic [7:0] roll_L, roll_H, yaw_L, yaw_H, AY_L, AY_H, AZ_L, AZ_H;
always @(posedge clk, negedge rst_n)
	if(!rst_n)
		roll_L <= 0;
	else if(C_R_L_en)
		roll_L <= resp[7:0];

always @(posedge clk, negedge rst_n)
	if(!rst_n)
		roll_H <= 0;
	else if(C_R_H_en)
		roll_H <= resp[7:0];

always @(posedge clk, negedge rst_n)
	if(!rst_n)
		yaw_L <= 0;
	else if(C_Y_L_en)
		yaw_L <= resp[7:0];

always @(posedge clk, negedge rst_n)
	if(!rst_n)
		yaw_H <= 0;
	else if(C_Y_H_en)
		yaw_H <= resp[7:0];

always @(posedge clk, negedge rst_n)
	if(!rst_n)
		ay_L <= 0;
	else if(C_AY_L_en)
		ay_L <= resp[7:0];

always @(posedge clk, negedge rst_n)
	if(!rst_n)
		ay_H <= 0;
	else if(C_AY_H_en)
		ay_H <= resp[7:0];

always @(posedge clk, negedge rst_n)
	if(!rst_n)
		az_L <= 0;
	else if(C_AZ_L_en)
		az_L <= resp[7:0];

always @(posedge clk, negedge rst_n)
	if(!rst_n)
		az_H <= 0;
	else if(C_AZ_H_en)
		az_H <= resp[7:0];	

//logic [7:0] roll_L, roll_H, yaw_L, yaw_H, AY_L, AY_H, AZ_L, AZ_H;
//logic [15:0] roll_rt, yaw_rt, AY, AZ;
assign roll_rt = {roll_H,roll_L};
assign yaw_rt = {yaw_H,yaw_L};
assign AY = {AY_H,AY_L};
assign AZ = {AZ_H,AZ_L};

endmodule
		