onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group ADC0 -color Gold /ibfb_packet_router_tb/BPM0_EMU/adc_bunch_trig
add wave -noupdate -group ADC0 /ibfb_packet_router_tb/BPM0_EMU/adc_x
add wave -noupdate -group ADC0 -color magenta /ibfb_packet_router_tb/BPM0_EMU/adc_x_new
add wave -noupdate -group ADC0 /ibfb_packet_router_tb/BPM0_EMU/adc_x_valid
add wave -noupdate -group ADC0 /ibfb_packet_router_tb/BPM0_EMU/adc_y
add wave -noupdate -group ADC0 -color magenta /ibfb_packet_router_tb/BPM0_EMU/adc_y_new
add wave -noupdate -group ADC0 /ibfb_packet_router_tb/BPM0_EMU/adc_y_valid
add wave -noupdate -group ADC1 -color Gold /ibfb_packet_router_tb/BPM1_EMU/adc_bunch_trig
add wave -noupdate -group ADC1 -color magenta /ibfb_packet_router_tb/BPM1_EMU/adc_x
add wave -noupdate -group ADC1 /ibfb_packet_router_tb/BPM1_EMU/adc_x_new
add wave -noupdate -group ADC1 /ibfb_packet_router_tb/BPM1_EMU/adc_x_valid
add wave -noupdate -group ADC1 /ibfb_packet_router_tb/BPM1_EMU/adc_y
add wave -noupdate -group ADC1 -color magenta /ibfb_packet_router_tb/BPM1_EMU/adc_y_new
add wave -noupdate -group ADC1 /ibfb_packet_router_tb/BPM1_EMU/adc_y_valid
add wave -noupdate -group ADC2 -color Gold /ibfb_packet_router_tb/BPM2_EMU/adc_bunch_trig
add wave -noupdate -group ADC2 /ibfb_packet_router_tb/BPM2_EMU/adc_x
add wave -noupdate -group ADC2 -color magenta /ibfb_packet_router_tb/BPM2_EMU/adc_x_new
add wave -noupdate -group ADC2 /ibfb_packet_router_tb/BPM2_EMU/adc_x_valid
add wave -noupdate -group ADC2 /ibfb_packet_router_tb/BPM2_EMU/adc_y
add wave -noupdate -group ADC2 -color magenta /ibfb_packet_router_tb/BPM2_EMU/adc_y_new
add wave -noupdate -group ADC2 /ibfb_packet_router_tb/BPM2_EMU/adc_y_valid
add wave -noupdate -group ADC3 -color Gold /ibfb_packet_router_tb/BPM3_EMU/adc_bunch_trig
add wave -noupdate -group ADC3 /ibfb_packet_router_tb/BPM3_EMU/adc_x
add wave -noupdate -group ADC3 -color magenta /ibfb_packet_router_tb/BPM3_EMU/adc_x_new
add wave -noupdate -group ADC3 /ibfb_packet_router_tb/BPM3_EMU/adc_x_valid
add wave -noupdate -group ADC3 /ibfb_packet_router_tb/BPM3_EMU/adc_y
add wave -noupdate -group ADC3 -color magenta /ibfb_packet_router_tb/BPM3_EMU/adc_y_new
add wave -noupdate -group ADC3 /ibfb_packet_router_tb/BPM3_EMU/adc_y_valid
add wave -noupdate -group Router0 /ibfb_packet_router_tb/BPM0_EMU/rout_in_charisk
add wave -noupdate -group Router0 /ibfb_packet_router_tb/BPM0_EMU/rout_in_data
add wave -noupdate -group Router0 /ibfb_packet_router_tb/BPM0_EMU/rout_in_next
add wave -noupdate -group Router0 /ibfb_packet_router_tb/BPM0_EMU/rout_in_valid
add wave -noupdate -group Router0 -color blue /ibfb_packet_router_tb/BPM0_EMU/ROUTER/s
add wave -noupdate -group Router0 -color gold /ibfb_packet_router_tb/BPM0_EMU/ROUTER/in_port
add wave -noupdate -group Router0 /ibfb_packet_router_tb/BPM0_EMU/ROUTER/in_valid
add wave -noupdate -group Router0 /ibfb_packet_router_tb/BPM0_EMU/ROUTER/in_next
add wave -noupdate -group Router0 /ibfb_packet_router_tb/BPM0_EMU/rout_out_charisk
add wave -noupdate -group Router0 /ibfb_packet_router_tb/BPM0_EMU/rout_out_data
add wave -noupdate -group Router0 /ibfb_packet_router_tb/BPM0_EMU/rout_out_err
add wave -noupdate -group Router0 -expand /ibfb_packet_router_tb/BPM0_EMU/rout_out_next
add wave -noupdate -group Router0 -expand /ibfb_packet_router_tb/BPM0_EMU/rout_out_valid
add wave -noupdate -group Router1 /ibfb_packet_router_tb/BPM1_EMU/rout_in_charisk
add wave -noupdate -group Router1 /ibfb_packet_router_tb/BPM1_EMU/rout_in_data
add wave -noupdate -group Router1 /ibfb_packet_router_tb/BPM1_EMU/rout_in_next
add wave -noupdate -group Router1 /ibfb_packet_router_tb/BPM1_EMU/rout_in_valid
add wave -noupdate -group Router1 /ibfb_packet_router_tb/BPM1_EMU/rout_out_charisk
add wave -noupdate -group Router1 /ibfb_packet_router_tb/BPM1_EMU/rout_out_data
add wave -noupdate -group Router1 /ibfb_packet_router_tb/BPM1_EMU/rout_out_err
add wave -noupdate -group Router1 /ibfb_packet_router_tb/BPM1_EMU/rout_out_next
add wave -noupdate -group Router1 -expand /ibfb_packet_router_tb/BPM1_EMU/rout_out_valid
add wave -noupdate -group Router3 /ibfb_packet_router_tb/BPM3_EMU/rout_in_charisk
add wave -noupdate -group Router3 /ibfb_packet_router_tb/BPM3_EMU/rout_in_data
add wave -noupdate -group Router3 /ibfb_packet_router_tb/BPM3_EMU/rout_in_next
add wave -noupdate -group Router3 /ibfb_packet_router_tb/BPM3_EMU/rout_in_valid
add wave -noupdate -group Router3 /ibfb_packet_router_tb/BPM3_EMU/rout_out_charisk
add wave -noupdate -group Router3 /ibfb_packet_router_tb/BPM3_EMU/rout_out_data
add wave -noupdate -group Router3 /ibfb_packet_router_tb/BPM3_EMU/rout_out_err
add wave -noupdate -group Router3 /ibfb_packet_router_tb/BPM3_EMU/rout_out_next
add wave -noupdate -group Router3 /ibfb_packet_router_tb/BPM3_EMU/rout_out_valid
add wave -noupdate -group {XF TX} -color cyan /ibfb_packet_router_tb/xf_txf_empty
add wave -noupdate -group {XF TX} -color magenta -expand -subitemconfig {/ibfb_packet_router_tb/xf_txf_next(0) {-color magenta -height 15} /ibfb_packet_router_tb/xf_txf_next(1) {-color magenta -height 15} /ibfb_packet_router_tb/xf_txf_next(2) {-color magenta -height 15} /ibfb_packet_router_tb/xf_txf_next(3) {-color magenta -height 15}} /ibfb_packet_router_tb/xf_txf_next
add wave -noupdate -group {XF TX} /ibfb_packet_router_tb/xf_txf_isk
add wave -noupdate -group {XF TX} /ibfb_packet_router_tb/xf_txf_data
add wave -noupdate -group {BP RX} -color cyan /ibfb_packet_router_tb/bp_rxf_full
add wave -noupdate -group {BP RX} -color magenta -expand -subitemconfig {/ibfb_packet_router_tb/bp_rxf_wr(0) {-color magenta -height 15} /ibfb_packet_router_tb/bp_rxf_wr(1) {-color magenta -height 15} /ibfb_packet_router_tb/bp_rxf_wr(2) {-color magenta -height 15} /ibfb_packet_router_tb/bp_rxf_wr(3) {-color magenta -height 15}} /ibfb_packet_router_tb/bp_rxf_wr
add wave -noupdate -group {BP RX} /ibfb_packet_router_tb/bp_rxf_isk
add wave -noupdate -group {BP RX} /ibfb_packet_router_tb/bp_rxf_data
add wave -noupdate -group {BP TX} -color cyan /ibfb_packet_router_tb/bp_txf_empty
add wave -noupdate -group {BP TX} -color magenta -expand -subitemconfig {/ibfb_packet_router_tb/bp_txf_next(0) {-color magenta -height 15} /ibfb_packet_router_tb/bp_txf_next(1) {-color magenta -height 15} /ibfb_packet_router_tb/bp_txf_next(2) {-color magenta -height 15} /ibfb_packet_router_tb/bp_txf_next(3) {-color magenta -height 15}} /ibfb_packet_router_tb/bp_txf_next
add wave -noupdate -group {BP TX} /ibfb_packet_router_tb/bp_txf_isk
add wave -noupdate -group {BP TX} /ibfb_packet_router_tb/bp_txf_data
add wave -noupdate -group {XF RX} -color cyan /ibfb_packet_router_tb/xf_rxf_full
add wave -noupdate -group {XF RX} -color magenta -expand -subitemconfig {/ibfb_packet_router_tb/xf_rxf_wr(0) {-color magenta -height 15} /ibfb_packet_router_tb/xf_rxf_wr(1) {-color magenta -height 15} /ibfb_packet_router_tb/xf_rxf_wr(2) {-color magenta -height 15} /ibfb_packet_router_tb/xf_rxf_wr(3) {-color magenta -height 15}} /ibfb_packet_router_tb/xf_rxf_wr
add wave -noupdate -group {XF RX} /ibfb_packet_router_tb/xf_rxf_isk
add wave -noupdate -group {XF RX} /ibfb_packet_router_tb/xf_rxf_data
add wave -noupdate -group {DS RX FIFO} /ibfb_packet_router_tb/ds_rxf_empty
add wave -noupdate -group {DS RX FIFO} /ibfb_packet_router_tb/ds_rxf_full
add wave -noupdate -group {DS RX FIFO} /ibfb_packet_router_tb/ds_rxf_next
add wave -noupdate -group {DS RX FIFO} /ibfb_packet_router_tb/ds_rxf_rdata
add wave -noupdate -group {DS RX FIFO} /ibfb_packet_router_tb/ds_rxf_risk
add wave -noupdate -group {DS RX FIFO} /ibfb_packet_router_tb/ds_rxf_wdata
add wave -noupdate -group {DS RX FIFO} /ibfb_packet_router_tb/ds_rxf_wisk
add wave -noupdate -group {DS RX FIFO} /ibfb_packet_router_tb/ds_rxf_wr
add wave -noupdate -group {US RX FIFO} /ibfb_packet_router_tb/us_rxf_empty
add wave -noupdate -group {US RX FIFO} /ibfb_packet_router_tb/us_rxf_full
add wave -noupdate -group {US RX FIFO} /ibfb_packet_router_tb/us_rxf_next
add wave -noupdate -group {US RX FIFO} /ibfb_packet_router_tb/us_rxf_rdata
add wave -noupdate -group {US RX FIFO} /ibfb_packet_router_tb/us_rxf_risk
add wave -noupdate -group {US RX FIFO} /ibfb_packet_router_tb/us_rxf_valid
add wave -noupdate -group {US RX FIFO} /ibfb_packet_router_tb/us_rxf_wdata
add wave -noupdate -group {US RX FIFO} /ibfb_packet_router_tb/us_rxf_wisk
add wave -noupdate -group {US RX FIFO} /ibfb_packet_router_tb/us_rxf_wr
add wave -noupdate -expand -group UPSTREAM_RX -color magenta /ibfb_packet_router_tb/UPSTREAM_RX/i_valid
add wave -noupdate -expand -group UPSTREAM_RX -color cyan /ibfb_packet_router_tb/UPSTREAM_RX/o_next
add wave -noupdate -expand -group UPSTREAM_RX /ibfb_packet_router_tb/UPSTREAM_RX/i_charisk
add wave -noupdate -expand -group UPSTREAM_RX /ibfb_packet_router_tb/UPSTREAM_RX/i_data
add wave -noupdate -expand -group UPSTREAM_RX -color orange /ibfb_packet_router_tb/UPSTREAM_RX/o_bad_data
add wave -noupdate -expand -group UPSTREAM_RX -color yellow /ibfb_packet_router_tb/UPSTREAM_RX/o_crc_good
add wave -noupdate -expand -group UPSTREAM_RX -color magenta /ibfb_packet_router_tb/UPSTREAM_RX/o_eop
add wave -noupdate -expand -group UPSTREAM_RX -childformat {{/ibfb_packet_router_tb/UPSTREAM_RX/o_rx_data.bucket -radix unsigned}} -expand -subitemconfig {/ibfb_packet_router_tb/UPSTREAM_RX/o_rx_data.bpm {-height 15 -itemcolor Gold} /ibfb_packet_router_tb/UPSTREAM_RX/o_rx_data.bucket {-height 15 -itemcolor Gold -radix unsigned}} /ibfb_packet_router_tb/UPSTREAM_RX/o_rx_data
add wave -noupdate -expand -group {US RX COUNTERS} -radix unsigned /ibfb_packet_router_tb/us_cnt_0
add wave -noupdate -expand -group {US RX COUNTERS} -radix unsigned /ibfb_packet_router_tb/us_cnt_1
add wave -noupdate -expand -group {US RX COUNTERS} -radix unsigned /ibfb_packet_router_tb/us_cnt_2
add wave -noupdate -expand -group {US RX COUNTERS} -radix unsigned /ibfb_packet_router_tb/us_cnt_3
add wave -noupdate -expand -group {US RX COUNTERS} -radix unsigned /ibfb_packet_router_tb/us_cnt_err
add wave -noupdate -expand -group {US RX COUNTERS} -radix unsigned /ibfb_packet_router_tb/us_rxf_rerr
add wave -noupdate -expand -group {US RX COUNTERS} /ibfb_packet_router_tb/us_rxf_werr
add wave -noupdate -expand -group DOWNSTREAM_RX -color magenta /ibfb_packet_router_tb/DOWNSTREAM_RX/i_valid
add wave -noupdate -expand -group DOWNSTREAM_RX -color cyan /ibfb_packet_router_tb/DOWNSTREAM_RX/o_next
add wave -noupdate -expand -group DOWNSTREAM_RX /ibfb_packet_router_tb/DOWNSTREAM_RX/i_charisk
add wave -noupdate -expand -group DOWNSTREAM_RX /ibfb_packet_router_tb/DOWNSTREAM_RX/i_data
add wave -noupdate -expand -group DOWNSTREAM_RX -color orange /ibfb_packet_router_tb/DOWNSTREAM_RX/o_bad_data
add wave -noupdate -expand -group DOWNSTREAM_RX -color yellow /ibfb_packet_router_tb/DOWNSTREAM_RX/o_crc_good
add wave -noupdate -expand -group DOWNSTREAM_RX -color magenta /ibfb_packet_router_tb/DOWNSTREAM_RX/o_eop
add wave -noupdate -expand -group DOWNSTREAM_RX -expand -subitemconfig {/ibfb_packet_router_tb/DOWNSTREAM_RX/o_rx_data.bpm {-height 15 -itemcolor gold} /ibfb_packet_router_tb/DOWNSTREAM_RX/o_rx_data.bucket {-height 15 -itemcolor gold}} /ibfb_packet_router_tb/DOWNSTREAM_RX/o_rx_data
add wave -noupdate -expand -group {DS RX COUNTERS} -radix unsigned /ibfb_packet_router_tb/ds_cnt_0
add wave -noupdate -expand -group {DS RX COUNTERS} -radix unsigned /ibfb_packet_router_tb/ds_cnt_1
add wave -noupdate -expand -group {DS RX COUNTERS} -radix unsigned /ibfb_packet_router_tb/ds_cnt_2
add wave -noupdate -expand -group {DS RX COUNTERS} -radix unsigned /ibfb_packet_router_tb/ds_cnt_3
add wave -noupdate -expand -group {DS RX COUNTERS} -radix unsigned /ibfb_packet_router_tb/ds_cnt_err
add wave -noupdate -expand -group {DS RX COUNTERS} -radix unsigned /ibfb_packet_router_tb/ds_rxf_rerr
add wave -noupdate -expand -group {DS RX COUNTERS} -radix unsigned /ibfb_packet_router_tb/ds_rxf_werr
add wave -noupdate -group {LATENCY DOWN 0} /ibfb_packet_router_tb/BPM0_EMU/adc_x_valid
add wave -noupdate -group {LATENCY DOWN 0} /ibfb_packet_router_tb/BPM0_EMU/rout_in_valid(0)
add wave -noupdate -group {LATENCY DOWN 0} /ibfb_packet_router_tb/BPM0_EMU/rout_out_valid(0)
add wave -noupdate -group {LATENCY DOWN 0} -color magenta /ibfb_packet_router_tb/xf_txf_next(0)
add wave -noupdate -group {LATENCY DOWN 0} -color magenta /ibfb_packet_router_tb/xf_rxf_wr(1)
add wave -noupdate -group {LATENCY DOWN 0} /ibfb_packet_router_tb/BPM1_EMU/rout_in_next(1)
add wave -noupdate -group {LATENCY DOWN 0} /ibfb_packet_router_tb/BPM1_EMU/rout_out_valid(1)
add wave -noupdate -group {LATENCY DOWN 0} -color magenta /ibfb_packet_router_tb/bp_txf_next(1)
add wave -noupdate -group {LATENCY DOWN 0} -color magenta /ibfb_packet_router_tb/bp_rxf_wr(3)
add wave -noupdate -group {LATENCY DOWN 0} /ibfb_packet_router_tb/BPM3_EMU/rout_in_valid(2)
add wave -noupdate -group {LATENCY DOWN 0} /ibfb_packet_router_tb/BPM3_EMU/rout_out_valid(1)
add wave -noupdate -group {LATENCY DOWN 0} -color magenta /ibfb_packet_router_tb/bp_txf_next(3)
add wave -noupdate -group {LATENCY DOWN 0} /ibfb_packet_router_tb/ds_rxf_wr
add wave -noupdate -group {LATENCY DOWN 0} /ibfb_packet_router_tb/ds_rxf_valid
add wave -noupdate -group {LATENCY UP 0} /ibfb_packet_router_tb/BPM0_EMU/adc_x_valid
add wave -noupdate -group {LATENCY UP 0} /ibfb_packet_router_tb/BPM0_EMU/rout_in_valid(0)
add wave -noupdate -group {LATENCY UP 0} /ibfb_packet_router_tb/BPM0_EMU/rout_out_valid(1)
add wave -noupdate -group {LATENCY UP 0} -color magenta /ibfb_packet_router_tb/bp_txf_next(0)
add wave -noupdate -group {LATENCY UP 0} /ibfb_packet_router_tb/us_rxf_wr
add wave -noupdate -group {LATENCY UP 0} /ibfb_packet_router_tb/us_rxf_next
add wave -noupdate -group {LATENCY DOWN 1} /ibfb_packet_router_tb/BPM1_EMU/adc_x_new
add wave -noupdate -group {LATENCY DOWN 1} /ibfb_packet_router_tb/BPM1_EMU/rout_in_valid(0)
add wave -noupdate -group {LATENCY DOWN 1} /ibfb_packet_router_tb/BPM1_EMU/rout_out_valid(1)
add wave -noupdate -group {LATENCY DOWN 1} -color magenta /ibfb_packet_router_tb/bp_txf_next(1)
add wave -noupdate -group {LATENCY DOWN 1} -color magenta /ibfb_packet_router_tb/bp_rxf_wr(3)
add wave -noupdate -group {LATENCY DOWN 1} /ibfb_packet_router_tb/BPM3_EMU/rout_in_valid(2)
add wave -noupdate -group {LATENCY DOWN 1} /ibfb_packet_router_tb/BPM3_EMU/rout_out_valid(1)
add wave -noupdate -group {LATENCY DOWN 1} -color magenta /ibfb_packet_router_tb/bp_txf_next(3)
add wave -noupdate -group {LATENCY DOWN 1} /ibfb_packet_router_tb/ds_rxf_wr
add wave -noupdate -group {LATENCY DOWN 1} /ibfb_packet_router_tb/ds_rxf_next
add wave -noupdate -group {LATENCY UP 1} /ibfb_packet_router_tb/BPM1_EMU/adc_x_new
add wave -noupdate -group {LATENCY UP 1} /ibfb_packet_router_tb/BPM1_EMU/rout_in_valid(0)
add wave -noupdate -group {LATENCY UP 1} /ibfb_packet_router_tb/BPM1_EMU/rout_out_valid(0)
add wave -noupdate -group {LATENCY UP 1} -color magenta /ibfb_packet_router_tb/xf_txf_next(1)
add wave -noupdate -group {LATENCY UP 1} -color magenta /ibfb_packet_router_tb/xf_rxf_wr(0)
add wave -noupdate -group {LATENCY UP 1} /ibfb_packet_router_tb/BPM0_EMU/rout_in_valid(1)
add wave -noupdate -group {LATENCY UP 1} /ibfb_packet_router_tb/BPM0_EMU/rout_out_valid(1)
add wave -noupdate -group {LATENCY UP 1} -color magenta /ibfb_packet_router_tb/bp_txf_next(0)
add wave -noupdate -group {LATENCY UP 1} /ibfb_packet_router_tb/us_rxf_wr
add wave -noupdate -group {LATENCY UP 1} /ibfb_packet_router_tb/us_rxf_next
add wave -noupdate -group {FIFO ERR COUNTERS} /ibfb_packet_router_tb/pkt_rxf_rerr
add wave -noupdate -group {FIFO ERR COUNTERS} /ibfb_packet_router_tb/pkt_rxf_werr
add wave -noupdate -group {FIFO ERR COUNTERS} /ibfb_packet_router_tb/bp_rxf_rerr
add wave -noupdate -group {FIFO ERR COUNTERS} /ibfb_packet_router_tb/bp_rxf_werr
add wave -noupdate -group {FIFO ERR COUNTERS} /ibfb_packet_router_tb/bp_txf_rerr
add wave -noupdate -group {FIFO ERR COUNTERS} /ibfb_packet_router_tb/bp_txf_werr
add wave -noupdate -group {FIFO ERR COUNTERS} /ibfb_packet_router_tb/xf_rxf_rerr
add wave -noupdate -group {FIFO ERR COUNTERS} /ibfb_packet_router_tb/xf_rxf_werr
add wave -noupdate -group {FIFO ERR COUNTERS} /ibfb_packet_router_tb/xf_txf_rerr
add wave -noupdate -group {FIFO ERR COUNTERS} /ibfb_packet_router_tb/xf_txf_werr
add wave -noupdate -group {DATA METERS} /ibfb_packet_router_tb/xf_txf_speed
add wave -noupdate -group {DATA METERS} /ibfb_packet_router_tb/xf_rxf_speed
add wave -noupdate -group {DATA METERS} -expand /ibfb_packet_router_tb/bp_rxf_speed
add wave -noupdate -group {DATA METERS} -expand /ibfb_packet_router_tb/bp_txf_speed
add wave -noupdate -group {DATA METERS} /ibfb_packet_router_tb/ds_rxf_speed_r
add wave -noupdate -group {DATA METERS} /ibfb_packet_router_tb/ds_rxf_speed_w
add wave -noupdate -group {DATA METERS} /ibfb_packet_router_tb/us_rxf_speed_r
add wave -noupdate -group {DATA METERS} /ibfb_packet_router_tb/us_rxf_speed_w
add wave -noupdate -group {ROUTER0 SPEED} /ibfb_packet_router_tb/BPM0_EMU/adc_speed
add wave -noupdate -group {ROUTER0 SPEED} /ibfb_packet_router_tb/BPM0_EMU/pkt_fifo_read_speed
add wave -noupdate -group {ROUTER0 SPEED} -expand -subitemconfig {/ibfb_packet_router_tb/BPM0_EMU/rout_in_speed(2) {-format Analog-Step -height 50 -max 1200.0}} /ibfb_packet_router_tb/BPM0_EMU/rout_in_speed
add wave -noupdate -group {ROUTER0 SPEED} -expand -subitemconfig {/ibfb_packet_router_tb/BPM0_EMU/rout_out_speed(1) {-format Analog-Step -height 50 -max 2200.0}} /ibfb_packet_router_tb/BPM0_EMU/rout_out_speed
add wave -noupdate -group {ROUTER1 SPEED} /ibfb_packet_router_tb/BPM1_EMU/adc_speed
add wave -noupdate -group {ROUTER1 SPEED} /ibfb_packet_router_tb/BPM1_EMU/pkt_fifo_read_speed
add wave -noupdate -group {ROUTER1 SPEED} /ibfb_packet_router_tb/BPM1_EMU/rout_in_speed
add wave -noupdate -group {ROUTER1 SPEED} -expand -subitemconfig {/ibfb_packet_router_tb/BPM1_EMU/rout_out_speed(1) {-format Analog-Step -height 50 -max 1200.0}} /ibfb_packet_router_tb/BPM1_EMU/rout_out_speed
add wave -noupdate -group {ROUTER2 SPEED} /ibfb_packet_router_tb/BPM2_EMU/adc_speed
add wave -noupdate -group {ROUTER2 SPEED} /ibfb_packet_router_tb/BPM2_EMU/pkt_fifo_read_speed
add wave -noupdate -group {ROUTER2 SPEED} /ibfb_packet_router_tb/BPM2_EMU/rout_in_speed
add wave -noupdate -group {ROUTER2 SPEED} -expand -subitemconfig {/ibfb_packet_router_tb/BPM2_EMU/rout_out_speed(1) {-format Analog-Step -height 50 -max 1200.0}} /ibfb_packet_router_tb/BPM2_EMU/rout_out_speed
add wave -noupdate -group {ROUTER3 SPEED} /ibfb_packet_router_tb/BPM3_EMU/adc_speed
add wave -noupdate -group {ROUTER3 SPEED} /ibfb_packet_router_tb/BPM3_EMU/pkt_fifo_read_speed
add wave -noupdate -group {ROUTER3 SPEED} -expand -subitemconfig {/ibfb_packet_router_tb/BPM3_EMU/rout_in_speed(2) {-format Analog-Step -height 50 -max 1200.0}} /ibfb_packet_router_tb/BPM3_EMU/rout_in_speed
add wave -noupdate -group {ROUTER3 SPEED} -expand -subitemconfig {/ibfb_packet_router_tb/BPM3_EMU/rout_out_speed(1) {-format Analog-Step -height 50 -max 2300.0}} /ibfb_packet_router_tb/BPM3_EMU/rout_out_speed
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 11} {719204686 ps} 0}
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
WaveRestoreZoom {136050992 ps} {1466523632 ps}
