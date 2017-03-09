onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /ibfb_router_stress_tb/rst
add wave -noupdate /ibfb_router_stress_tb/rst_n
add wave -noupdate /ibfb_router_stress_tb/s
add wave -noupdate /ibfb_router_stress_tb/core_clk
add wave -noupdate /ibfb_router_stress_tb/dcnt
add wave -noupdate /ibfb_router_stress_tb/rout_in_valid
add wave -noupdate /ibfb_router_stress_tb/rout_in_data
add wave -noupdate /ibfb_router_stress_tb/rout_in_charisk
add wave -noupdate /ibfb_router_stress_tb/rout_in_next
add wave -noupdate -expand -subitemconfig {/ibfb_router_stress_tb/rout_in_speed(0) {-format Analog-Step -height 50 -max 1000.0} /ibfb_router_stress_tb/rout_in_speed(1) {-format Analog-Step -height 50 -max 1000.0} /ibfb_router_stress_tb/rout_in_speed(2) {-format Analog-Step -height 50 -max 1000.0}} /ibfb_router_stress_tb/rout_in_speed
add wave -noupdate /ibfb_router_stress_tb/rout_out_valid
add wave -noupdate /ibfb_router_stress_tb/rout_out_charisk
add wave -noupdate /ibfb_router_stress_tb/rout_out_data
add wave -noupdate /ibfb_router_stress_tb/rout_out_err
add wave -noupdate /ibfb_router_stress_tb/rout_out_next
add wave -noupdate -expand -subitemconfig {/ibfb_router_stress_tb/rout_out_speed(0) {-format Analog-Step -height 50 -max 2600.0} /ibfb_router_stress_tb/rout_out_speed(1) {-format Analog-Step -height 50 -max 2600.0}} /ibfb_router_stress_tb/rout_out_speed
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {70043157 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 16
configure wave -griddelta 40
configure wave -timeline 1
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {105 us}
