--==========================================================================================================--
--                                                                                                          --
--  File name   : usb_2_spi.vhd                                                                            --
--  Author      : Yuriy Grigoryev  grigoryev.yu@gmail.com                                                   --
--  Description : USB to SPI converter
--                                                                                                          --
--==========================================================================================================--
--                                                                                                          --
-- Change history                                                                                           --
--                                                                                                          --
-- Version / date        Description                                                                        --
--                                                                                                          --
-- 02 Feb 2018 YG   Initial version                                                                    --
--                                                                                                          --
-- End change history                                                                                       --
--==========================================================================================================--
--                                                                                                          --
-- Interface for a up to 16 channel logic analyzer, output data is stored in SDRAM memory                   --
--                                                                                                          --
--  Block Diagram :
--
--                +--------+     +-------+
--                |  USB   |TX   |  To   |
-- usb_Dn---------|  PORT  |<====| Upper |<===#
-- usb_Dp---------|        |     | Case  |    |
--                |        |     |       |    |
-- usb_term-------|        |     |       |    |
--                |        |     +-------+    |
--                |        |RX                |
--                |        |==================#
--                +--------+
--                 +-----+
--                 | PLL |
-- clk_50MHz-------|     |60MHz--->
--                 |     |
--                 +-----+
--
--==========================================================================================================--

library IEEE;
use IEEE.std_logic_1164.all;

library work;
use work.usb_desc_pkg.all;

entity usb_2_spi is
	generic(
		-- Selftest mode
		-- 0 - Normal operation
		-- 1 - USB loopback
		-- 2 - SPI loopback
		-- 3 - Runtime 
		SELFTEST : integer range 0 to 3 := 0;
		-- USB descriptor
		USB_DESCRIPTOR : usb_desc
	);
	port(
		-- Reference clock, 60 MHz
		clk         : in    std_logic;
		-- External reset (active low)
		resetn : in    std_logic;
		
		-- USB lines
		usb_dp      : inout std_logic;
		usb_dn      : inout std_logic;
		-- USB core initialzation status
		usb_ready   : out   std_logic;
		usb_online  : out   std_logic;

		-- Runtime loopback mode
		-- 0b01 - USB loopback
		-- 0b10 - SPI loopback
		-- others - normal operation
		loopback    : in    std_logic_vector(1 downto 0);

		-- SPI clock
		sclk        : out   std_logic;
		-- SPI master in, slave out
		miso        : in    std_logic;
		-- SPI master out, slave in
		mosi        : out   std_logic;
		-- SPI slave select
		ss_n        : out   std_logic
	);
	
	
end usb_2_spi;

architecture rtl of usb_2_spi is
	constant BUFSIZE_BITS : integer := 8;
	signal usb_rx_data    : std_logic_vector(7 downto 0);
	signal usb_rx_ready   : std_logic;
	signal usb_rx_valid   : std_logic;
	signal usb_tx_cork    : std_logic;
	signal usb_tx_data    : std_logic_vector(7 downto 0);
	signal usb_tx_room    : std_logic_vector(7 downto 0);
	signal spi_tx_data    : std_logic_vector(7 downto 0);
	signal spi_rx_data    : std_logic_vector(7 downto 0);
	signal usb_tx_ready   : std_logic;
	signal usb_tx_valid   : std_logic;
	signal spi_tx_valid   : std_logic;
	signal spi_busy       : std_logic;
	signal spi_mosi       : std_logic;
	signal spi_miso       : std_logic;
	signal spi_rx_valid   : std_logic;
	signal spi_reset_n    : std_logic;
	signal spi_ss_n       : std_logic_vector(0 downto 0);
	attribute keep : string;
	attribute keep of usb_rx_valid : signal is "TRUE";
begin

	usb_fs_slave_1 : entity work.usb_fs_port
		generic map(
			VENDORID     => USB_DESCRIPTOR.VENDORID,
			PRODUCTID    => USB_DESCRIPTOR.PRODUCTID,
			VERSIONBCD   => USB_DESCRIPTOR.VERSIONBCD,
			VENDORSTR 	 => USB_DESCRIPTOR.VENDORSTR,
			PRODUCTSTR   => USB_DESCRIPTOR.PRODUCTSTR,
			SERIALSTR    => USB_DESCRIPTOR.SERIALSTR,
			SELFPOWERED  => TRUE,
			BUFSIZE_BITS => BUFSIZE_BITS)
		port map(
			clk         => clk,         -- i
			rst_neg_ext => resetn, -- i
			reset_syc   => open,        -- o  positive active, streched to the next clock
			d_pos       => usb_dp,      -- io Pos USB data line
			d_neg       => usb_dn,      -- io Neg USB data line
			d_oe        => open,
			USB_rst     => open,        -- o  USB reset detected (SE0 > 2.5 us)
			online      => usb_online,  -- o  High when the device is in Config state.
			RXval       => usb_rx_valid, -- o  High if a received byte available on RXDAT.
			RXdat       => usb_rx_data, -- o  Received data byte, valid if RXVAL is high.
			RXrdy       => usb_rx_ready, -- i  High if application is ready to receive.
			RXlen       => open,        -- o  No of bytes available in receive buffer.
			TXval       => usb_tx_valid, -- i  High if the application has data to send.
			TXdat       => usb_tx_data, -- i  Data byte to send, must be valid if TXVAL is high.
			TXrdy       => usb_tx_ready, -- o  High if the entity is ready to accept the next byte.
			TXroom      => usb_tx_room,        -- o  No of free bytes in transmit buffer.
			TXcork      => usb_tx_cork, -- i  Temp. suppress transmissions at the outgoing endpoint.
			FPGA_ready  => usb_ready         -- o  Connect FPGA_ready to the pullup resistor logic
		);

	usb_tx_cork <= '0';                 -- Don't hold TX transmission

	spi_master_1 : entity work.spi_master
		generic map(
			slaves  => 1,               --number of spi slaves
			d_width => 8)               --data bus width
		port map(
			clock   => clk,             --system clock
			reset_n => spi_reset_n,     --asynchronous reset
			enable  => spi_tx_valid,    --initiate transaction
			cpol    => '0',             --spi clock polarity
			cpha    => '0',             --spi clock phase
			cont    => '0',             --continuous mode command
			clk_div => 0,               --30,              --system clock cycles per 1/2 period of sclk
			addr    => 0,               --address of slave
			tx_data => spi_tx_data,     --data to transmit
			miso    => spi_miso,        --master in, slave out
			sclk    => sclk,            --spi clock
			ss_n    => spi_ss_n,        --slave select
			mosi    => spi_mosi,        --master out, slave in
			busy    => spi_busy,        --busy / data ready signal
			rx_data => spi_rx_data      --data received
		);

	spi_tx_data  <= usb_rx_data;
	spi_tx_valid <= usb_rx_valid;
	mosi         <= spi_mosi;
	ss_n         <= spi_ss_n(0);

	spi_rx_valid_capturing : block
		signal spi_busy_d : std_logic;
	begin
		spi_busy_d   <= spi_busy when rising_edge(clk);
		spi_rx_valid <= '1' when spi_busy = '0' and spi_busy_d = '1' else '0';
	end block spi_rx_valid_capturing;

	normal_mode : if SELFTEST = 0 generate
		usb_rx_ready <= not spi_busy;
		usb_tx_data  <= spi_rx_data;
		usb_tx_valid <= spi_rx_valid;
		spi_reset_n  <= resetn;
		spi_miso     <= miso;
	end generate normal_mode;

	usb_loopback : if SELFTEST = 1 generate
		usb_rx_ready <= usb_tx_ready;
		usb_tx_data  <= usb_rx_data;
		usb_tx_valid <= usb_rx_valid;
		spi_reset_n  <= '0';
		spi_miso     <= miso;
	end generate usb_loopback;

	spi_loopback : if SELFTEST = 2 generate
		usb_rx_ready <= not spi_busy;
		usb_tx_data  <= spi_rx_data;
		usb_tx_valid <= spi_rx_valid;
		spi_reset_n  <= resetn;
		spi_miso     <= spi_mosi;
	end generate spi_loopback;

	runtime_loopback : if SELFTEST = 3 generate
		usb_rx_ready <= usb_tx_ready when loopback = "01" else not spi_busy;
		usb_tx_data  <= usb_rx_data when loopback = "01" else spi_rx_data;
		usb_tx_valid <= usb_rx_valid when loopback = "01" else spi_rx_valid;
		spi_reset_n  <= '0' when loopback = "01" else resetn;
		spi_miso     <= spi_mosi when loopback = "10" else miso;
	end generate runtime_loopback;

end rtl;