#-- Lattice Semiconductor Corporation Ltd.
#-- Synplify OEM project file C:/projects/projects/USB to SPI Master Design/USB_Project/USB_2_14_18/USB_DEMO_XO2_BoB/implementation/usb_1p1_demo/launch_synplify.tcl
#-- Written on Tue Mar  6 15:42:24 2018

project -close
set filename "C:/projects/projects/USB to SPI Master Design/USB_Project/USB_2_14_18/USB_DEMO_XO2_BoB/implementation/usb_1p1_demo/usb_1p1_demo_syn.prj"
if ([file exists "$filename"]) {
	project -load "$filename"
	project_file -remove *
} else {
	project -new "$filename"
}
set create_new 0

#device options
set_option -technology MACHXO2
set_option -part LCMXO2_7000HE
set_option -package TG144C
set_option -speed_grade -4

if {$create_new == 1} {
#-- add synthesis options
	set_option -symbolic_fsm_compiler true
	set_option -resource_sharing true
	set_option -vlog_std v2001
	set_option -frequency auto
	set_option -maxfan 1000
	set_option -auto_constrain_io 0
	set_option -disable_io_insertion false
	set_option -retiming false; set_option -pipe true
	set_option -force_gsr false
	set_option -compiler_compatible 0
	set_option -dup false
	set_option -frequency 1
	set_option -default_enum_encoding default
	
	
	
	set_option -write_apr_constraint 1
	set_option -fix_gated_and_generated_clocks 1
	set_option -update_models_cp 0
	set_option -resolve_multiple_driver 0
	
	
}
#-- add_file options
add_file -vhdl "C:/lscc/diamond/3.9_x64/cae_library/synthesis/vhdl/machxo2.vhd"
add_file -vhdl -lib "work" "C:/projects/projects/USB to SPI Master Design/USB_Project/USB_2_14_18/USB_DEMO_XO2_BoB/soucre/usb_phy/usb_phy.vhd"
add_file -vhdl -lib "work" "C:/projects/projects/USB to SPI Master Design/USB_Project/USB_2_14_18/USB_DEMO_XO2_BoB/soucre/usb_phy/usb_rx_phy_60MHz.vhd"
add_file -vhdl -lib "work" "C:/projects/projects/USB to SPI Master Design/USB_Project/USB_2_14_18/USB_DEMO_XO2_BoB/soucre/usb_phy/usb_tx_phy.vhd"
add_file -vhdl -lib "work" "C:/projects/projects/USB to SPI Master Design/USB_Project/USB_2_14_18/USB_DEMO_XO2_BoB/soucre/usb_serial/usb_control.vhd"
add_file -vhdl -lib "work" "C:/projects/projects/USB to SPI Master Design/USB_Project/USB_2_14_18/USB_DEMO_XO2_BoB/soucre/usb_serial/usb_init.vhd"
add_file -vhdl -lib "work" "C:/projects/projects/USB to SPI Master Design/USB_Project/USB_2_14_18/USB_DEMO_XO2_BoB/soucre/usb_serial/usb_packet.vhd"
add_file -vhdl -lib "work" "C:/projects/projects/USB to SPI Master Design/USB_Project/USB_2_14_18/USB_DEMO_XO2_BoB/soucre/usb_serial/usb_pkg.vhd"
add_file -vhdl -lib "work" "C:/projects/projects/USB to SPI Master Design/USB_Project/USB_2_14_18/USB_DEMO_XO2_BoB/soucre/usb_serial/usb_serial.vhd"
add_file -vhdl -lib "work" "C:/projects/projects/USB to SPI Master Design/USB_Project/USB_2_14_18/USB_DEMO_XO2_BoB/soucre/usb_serial/usb_transact.vhd"
add_file -vhdl -lib "work" "C:/projects/projects/USB to SPI Master Design/USB_Project/USB_2_14_18/USB_DEMO_XO2_BoB/soucre/usb_top/usb_2upper.vhd"
add_file -vhdl -lib "work" "C:/projects/projects/USB to SPI Master Design/USB_Project/USB_2_14_18/USB_DEMO_XO2_BoB/soucre/usb_top/usb_fs_port.vhd"
add_file -vhdl -lib "work" "C:/projects/projects/USB to SPI Master Design/USB_Project/USB_2_14_18/USB_DEMO_XO2_BoB/soucre/cores/pll_60MHz.vhd"
#-- top module name
set_option -top_module {}
project -result_file {C:/projects/projects/USB to SPI Master Design/USB_Project/USB_2_14_18/USB_DEMO_XO2_BoB/implementation/usb_1p1_demo/usb_1p1_demo.edi}
project -save "$filename"
