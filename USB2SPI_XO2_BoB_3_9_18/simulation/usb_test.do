
  echo  "===>"
  echo  "===> Recompiling Sources"
  echo  "===>"

  if {![file exists work]} {
  vlib work 
  }
  endif
  design create work .
  design open work
  adel -all
  
  set PATH		 D:\DEMO_DESIGN

  # Open Cores USB Phy, designed by Rudolf Usselmanns and translated to VHDL by Martin Neumann

  vcom -2008 -work work       $PATH/USB_1P1_DEMO/soucre/usb_phy/usb_rx_phy_60MHz.vhd
  vcom -2008 -work work       $PATH/USB_1P1_DEMO/soucre/usb_phy/usb_tx_phy.vhd
  vcom -2008 -work work       $PATH/USB_1P1_DEMO/soucre/usb_phy//usb_phy.vhd

  #  USB Serial, designed by Joris van Rantwijk
  vcom -2008 -work work       $PATH/USB_1P1_DEMO/soucre/usb_serial/usb_pkg.vhd
  vcom -2008 -work work       $PATH/USB_1P1_DEMO/soucre/usb_serial/usb_init.vhd
  vcom -2008 -work work       $PATH/USB_1P1_DEMO/soucre/usb_serial/usb_control.vhd
  vcom -2008 -work work       $PATH/USB_1P1_DEMO/soucre/usb_serial/usb_transact.vhd
  vcom -2008 -work work       $PATH/USB_1P1_DEMO/soucre/usb_serial/usb_packet.vhd
  vcom -2008 -work work       $PATH/USB_1P1_DEMO/soucre/usb_serial/usb_serial.vhd
  
  #  USB Top, designed by Joris van Rantwijk
  
  vcom -2008 -work work       $PATH/USB_1P1_DEMO/soucre/usb_top/pll_60MHz.vhd
  vcom -2008 -work work       $PATH/USB_1P1_DEMO/soucre/usb_top/usb_fs_port.vhd
  vcom -2008 -work work       $PATH/USB_1P1_DEMO/soucre/usb_top/usb_2upper.vhd


  # The USB FS test bench files
  vcom -2008 -work work       $PATH/USB_1P1_DEMO/testbench/usb_commands.vhd
  #vcom -2008 -work work       $PATH/USB_1P1_DEMO/testbench/usb_tc03.vhd
  vcom -2008 -work work       $PATH/USB_1P1_DEMO/testbench/USB_Stimuli.vhd
  vcom -2008 -work work       $PATH/USB_1P1_DEMO/testbench/usb_commands.vhd
  vcom -2008 -work work       $PATH/USB_1P1_DEMO/testbench/usb_fs_monitor.vhd
  vcom -2008 -work work       $PATH/USB_1P1_DEMO/testbench/usb_fs_master.vhd
  vcom -2008 -work work       $PATH/USB_1P1_DEMO/testbench/usb_tb.vhd

  echo  "===>"
  echo  "===> Start Simulation"
  echo  "===>"
  vsim  -quiet usb_tb

  #view source
  #view wave
  #configure wave -signalnamewidth 1

  add wave -noupdate -divider {USB_2upper}
  add wave -noupdate -format Literal -radix decimal     /usb_tb/usb_fs_master/test_case/t_no
  add wave -noupdate -format Logic   -radix hexadecimal /usb_tb/usb_1/*

  add wave -noupdate -divider {USB FS port}
  add wave -noupdate -format Literal -radix decimal     /usb_tb/usb_fs_master/test_case/t_no
  add wave -noupdate -format Logic   -radix hexadecimal /usb_tb/usb_1/usb_fs_slave_1/*

  add wave -noupdate -divider {USB_Monitor}
  add wave -noupdate -format Literal -radix decimal     /usb_tb/usb_fs_master/test_case/t_no
  add wave -noupdate -format Logic   -radix hexadecimal /usb_tb/usb_fs_master/usb_fs_monitor/*
  add wave -noupdate -format Logic   -radix hexadecimal /usb_tb/usb_fs_master/stimuli_bit

  add wave -noupdate -divider {USB_MASTER}
  add wave -noupdate -format Logic   -radix hexadecimal /usb_tb/usb_fs_master/*

  add wave -noupdate -divider {USB_STIMULI}
  add wave -noupdate -format Literal -radix decimal     /usb_tb/usb_fs_master/test_case/t_no
  add wave -noupdate -format Logic   -radix hexadecimal /usb_tb/usb_fs_master/test_case/*

# add wave -noupdate -divider {USB_PHY}
# add wave -noupdate -format Literal -radix decimal     /usb_tb/usb_fs_master/test_case/t_no
# add wave -noupdate -format Logic   -radix hexadecimal /usb_tb/usb_fs_slave_1/usb_phy_1/*
#
# add wave -noupdate -divider {USB_RX_PHY}
# add wave -noupdate -format Logic   -radix hexadecimal /usb_tb/usb_fs_slave_1/usb_phy_1/i_rx_phy/*
#
# add wave -noupdate -divider
# add wave -noupdate -divider {USB_TX_PHY}
# add wave -noupdate -format Literal -radix decimal /usb_tb/usb_fs_master/test_case/t_no
# add wave -noupdate -format Logic   -radix hexadecimal /usb_tb/usb_fs_slave_1/usb_phy_1/i_tx_phy/*
# add wave -noupdate -divider {USB_SERIAL}
# add wave -noupdate -format Literal -radix decimal     /usb_tb/usb_fs_master/test_case/t_no
# add wave -noupdate -format Logic   -radix hexadecimal /usb_tb/usb_fs_slave_1/usb_serial_1/*
# add wave -noupdate -divider {USB_S-INIT}
# add wave -noupdate -format Logic   -radix hexadecimal /usb_tb/usb_fs_slave_1/usb_serial_1/usb_init_inst/*
# add wave -noupdate -divider {USB_S-PACKET}
# add wave -noupdate -format Logic   -radix hexadecimal /usb_tb/usb_fs_slave_1/usb_serial_1/usb_packet_inst/*
# add wave -noupdate -divider {USB_S-TRANSACT}
# add wave -noupdate -format Literal -radix decimal     /usb_tb/usb_fs_master/test_case/t_no
# add wave -noupdate -format Logic   -radix hexadecimal /usb_tb/usb_fs_slave_1/usb_serial_1/usb_transact_inst/*
# add wave -noupdate -divider {USB_S-CONTROL}
# add wave -noupdate -format Logic   -radix hexadecimal /usb_tb/usb_fs_slave_1/usb_serial_1/usb_control_inst/*

  onbreak {resume}
  run -all
