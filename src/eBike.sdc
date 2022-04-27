# Read all files
read_file -format sverilog {A2D_intf.sv brushless.sv cadence_filt.sv cadence_LU.sv cadence_meas.sv sensorCondition.sv desiredDrive.sv eBike.sv inertial_integrator.sv inert_intf.sv mtr_drv.sv nonoverlap.sv PB_intf.sv PID.sv PWM.sv reset_synch.sv eBike.sv SPI_mnrch.sv telemetry.sv UART_tx.sv}

# Set current design to eBike (top module)
current_design eBike

# create clock of 400 MHz
create_clock -name "clk" -period 2.5 -waveform {0 1} clk

# Don't touch clk, else synopsys will buffer it
set_dont_touch_network [find port clk]

# all inputs other than clk
set prim_inputs [remove_from_collection [all_inputs] [find port clk]]

# Set input delay and drive strength
set_input_delay -clock clk 0.3 [copy_collection $prim_inputs]

# set driving cell to NAND2 to all inputs other than clk and rst_n
set_driving_cell -lib_cell NAND2X2_LVT -library saed32lvt_tt0p85v25c [remove_from_collection [copy_collection $prim_inputs] [find port rst_n]]

# Set output delay and output load
set_output_delay -clock clk 0.5 [all_outputs]
set_load 0.05 [all_outputs]

# Max transition time
set_max_transition 0.20 [current_design]

# Wire load model
set_wire_load_model -name 16000 -library saed32lvt_tt0p85v25c

# Set clock uncertainty
set_clock_uncertainty  0.15 clk

set_fix_hold clk

ungroup -all -flatten

compile

check_design

report_area > eBike_area.txt

# min and max timing reports
report_timing -path full -delay max -nworst 3 > eBike_max_timing.txt
report_timing -path full -delay min -nworst 3 > eBike_min_timing.txt

# net list
write -format verilog eBike -output eBike.vg