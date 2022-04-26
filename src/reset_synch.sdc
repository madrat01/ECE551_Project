# Read all files
read_file -format sverilog {reset_synch.sv}

# Set current design to reset_synch (top module)
current_design reset_synch

# create clock of 400 MHz
create_clock -name "clk" -period 2.5 -waveform {0 1} clk

# Don't touch clk, else synopsys will buffer it
set_dont_touch_network [find port clk]

# all inputs other than clk
set prim_inputs [remove_from_collection [all_inputs] [find port clk]]

# Set input delay and drive strength
set_input_delay -clock clk 0.3 [copy_collection $prim_inputs]

# set driving cell to NAND2 to all inputs other than clk and RST_N
set_driving_cell -lib_cell NAND2X2_LVT -library saed32lvt_tt0p85v25c [remove_from_collection [copy_collection $prim_inputs] [find port RST_n]]

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

report_area > reset_synch_area.txt

# min and max timing reports
report_timing -path full -delay max -nworst 3 > reset_synch_max_timing.txt
report_timing -path full -delay min -nworst 3 > reset_synch_min_timing.txt

# net list
write -format verilog reset_synch -output reset_synch.vg
