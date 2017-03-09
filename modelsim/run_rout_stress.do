vcom -work work -2002 -explicit -novopt C:/temp/G/XFEL/14_Firmware/22_Library/EDKLib/hw/PSI/pcores/ibfb_common_v1_00_a/hdl/vhdl/pkg_crc.vhd
vcom -work work -2002 -explicit -novopt C:/temp/G/XFEL/14_Firmware/22_Library/EDKLib/hw/PSI/pcores/ibfb_common_v1_00_a/hdl/vhdl/rx_sync.vhd
vcom -work work -2002 -explicit -novopt C:/temp/G/XFEL/14_Firmware/22_Library/EDKLib/hw/PSI/pcores/ibfb_common_v1_00_a/hdl/vhdl/virtex5_gtx_package.vhd
vcom -work work -2002 -explicit -novopt C:/temp/G/XFEL/14_Firmware/22_Library/EDKLib/hw/PSI/pcores/ibfb_common_v1_00_a/hdl/vhdl/ibfb_comm_package.vhd
#vcom -work work -2002 -explicit -novopt C:/temp/G/XFEL/14_Firmware/22_Library/EDKLib/hw/PSI/pcores/ibfb_bpm_router_v1_00_a/hdl/vhdl/cav_bpm_interface.vhd
#vcom -work work -2002 -explicit -novopt C:/temp/G/XFEL/14_Firmware/22_Library/EDKLib/hw/PSI/pcores/ibfb_bpm_router_v1_00_a/hdl/vhdl/ibfb_bpm_pkt_gen.vhd
vcom -work work -2002 -explicit -novopt C:/temp/G/XFEL/14_Firmware/22_Library/EDKLib/hw/PSI/pcores/ibfb_bpm_router_v1_00_a/modelsim/ibfb_router_stress_tb.vhd

vsim -gui -t ps -novopt work.ibfb_router_stress_tb

log -r *
radix hex

do wave_router_stress.do

alias WW "write format wave -window .main_pane.wave.interior.cs.body.pw.wf C:/temp/G/XFEL/14_Firmware/22_Library/EDKLib/hw/PSI/pcores/ibfb_bpm_router_v1_00_a/modelsim/wave_router_stress.do"
