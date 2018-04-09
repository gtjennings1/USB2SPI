--==========================================================================================================--
--                                                                                                          --
--  File name   : usb_2_spi_top_lat_bb.vhd                                                                            --
--  Author      : Yuriy Grigoryev  grigoryev.yu@gmail.com                                                   --
--  Description : USB to SPI converter for Lattice Breakout Board
--                                                                                                          --
--==========================================================================================================--
--                                                                                                          --
-- Change history                                                                                           --
--                                                                                                          --
-- Version / date        Description                                                                        --
--                                                                                                          --
-- 03 March 2018 YG   Initial version                                                                    --
--                                                                                                          --
-- End change history                                                                                       --
--==========================================================================================================--
--                                                                                                          --
--   USB-to-SPI Bridge 
--   Implementation for Lattice Breakout board
--
--==========================================================================================================--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.usb_desc_pkg.all;

entity usb_2_spi_top_lat_bb is
	port (
		-- Board system reset
		rst_neg_ext     : in    std_logic;

		-- USB lines
		usb_dp    : inout std_logic;
		usb_dn    : inout std_logic;

		-- Status and control
		-- PLL lock signal
		FPGA_ready    : out   std_logic;
		-- USB core status
		LED_green : out   std_logic;
		
		-- SPI 
		miso      : in    std_logic;    --master in, slave out
		sclk      : out   std_logic;    --spi clock
		ss_n      : out   std_logic;    --slave select
		mosi      : out   std_logic;     --master out, slave in	
		--ss_in     : in    std_logic;
		vcc       : out   std_logic;
		cresetn   : out   std_logic			
	);
end entity usb_2_spi_top_lat_bb;

architecture RTL of usb_2_spi_top_lat_bb is
	signal osc_clk : std_logic;
	signal pll_clk : std_logic;
	signal pll_lock : std_logic;
	signal pll_reset : std_logic;
	signal usb_online : std_logic;
	
	COMPONENT OSCH
	
	GENERIC (NOM_FREQ: string := "11.57");
		PORT ( STDBY :IN std_logic;
		OSC :OUT std_logic;
		SEDSTDBY :OUT std_logic);
	END COMPONENT; 
	attribute NOM_FREQ : string;
	attribute NOM_FREQ of onchip_osc : label is "12.09";
begin
	
	-- On-Chip Oscillator
	onchip_osc: OSCH
		generic map(
			NOM_FREQ => "12.09"
	)
		port map(
			stdby    => '0',
			osc      => osc_clk,
			sedstdby => open
		);
		
	pll_reset <= not rst_neg_ext;
	-- PLL
	pll_unit: entity work.pll_60MHz
		port map(
			RST => pll_reset,
			CLKI  => osc_clk,
			CLKOP => pll_clk,
			LOCK  => pll_lock
		);
	
	usb_2_spi_unit: entity work.usb_2_spi
		generic map(
			SELFTEST => 0,
			USB_DESCRIPTOR => GENERAL_VCP_DESC
		)
		port map(
			clk        => pll_clk,
			resetn     => rst_neg_ext,
			usb_dp     => usb_dp,
			usb_dn     => usb_dn,
			usb_ready  => open,
			usb_online => usb_online,
			sclk       => sclk,
			miso       => miso,
			mosi       => mosi,
			ss_n       => ss_n,
			creset     => cresetn
		);
		
	FPGA_ready <= not pll_lock;
	LED_green <= not usb_online;
	--ss_n <= ss_in;
	vcc  <= '1';
	
end architecture RTL;