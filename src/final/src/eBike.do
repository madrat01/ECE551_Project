onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /eBike_tb/TORQUE
add wave -noupdate /eBike_tb/cadence
add wave -noupdate -radix decimal /eBike_tb/iDUT/sensorCondition/target_curr
add wave -noupdate -radix decimal /eBike_tb/iDUT/sensorCondition/avg_curr
add wave -noupdate -radix decimal /eBike_tb/iDUT/sensorCondition/error
add wave -noupdate /eBike_tb/iDUT/highGrn
add wave -noupdate /eBike_tb/iDUT/lowGrn
add wave -noupdate /eBike_tb/iPHYS/SS_n
add wave -noupdate /eBike_tb/iPHYS/SCLK
add wave -noupdate /eBike_tb/iPHYS/MOSI
add wave -noupdate /eBike_tb/iPHYS/NEMO_setup
add wave -noupdate -radix decimal /eBike_tb/iPHYS/omega
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {110 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 2
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {1 us}
