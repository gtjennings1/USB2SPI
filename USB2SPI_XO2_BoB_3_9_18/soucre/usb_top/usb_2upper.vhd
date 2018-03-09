
--==========================================================================================================--
--                                                                                                          --
--  Copyright (C) 2011  by  Martin Neumann martin@neumanns-mail.de                                          --
--                                                                                                          --
--  This source file may be used and distributed without restriction provided that this copyright statement --
--  is not removed from the file and that any derivative work contains the original copyright notice and    --
--  the associated disclaimer.                                                                              --
--                                                                                                          --
--  This software is provided ''as is'' and without any expressed or implied warranties, including, but not --
--  limited to, the implied warranties of merchantability and fitness for a particular purpose. In no event --
--  shall the author or contributors be liable for any direct, indirect, incidental, special, exemplary, or --
--  consequential damages (including, but not limited to, procurement of substitute goods or services; loss --
--  of use, data, or profits; or business interruption) however caused and on any theory of liability,      --
--  whether in  contract, strict liability, or tort (including negligence or otherwise) arising in any way  --
--  out of the use of this software, even if advised of the possibility of such damage.                     --
--                                                                                                          --
--==========================================================================================================--
--                                                                                                          --
--  File name   : usb_2upper.vhd                                                                            --
--  Author      : Martin Neumann  martin@neumanns-mail.de                                                   --
--  Description : USB test bench - an example how to use the usb_master files together an US application.   --
--                                                                                                          --
--==========================================================================================================--
--                                                                                                          --
-- Change history                                                                                           --
--                                                                                                          --
-- Version / date        Description                                                                        --
--                                                                                                          --
-- 01  275 Jul 2013 MN    Initial version                                                                    --
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

LIBRARY work, IEEE;
  USE IEEE.std_logic_1164.ALL;

ENTITY usb_2upper IS
  PORT (
    --clk_50MHz      : IN    STD_LOGIC;
    rst_neg_ext    : IN    STD_LOGIC;
    usb_dp         : INOUT STD_LOGIC;
    usb_dn         : INOUT STD_LOGIC;
    LED_green      : OUT   STD_LOGIC;
    FPGA_ready     : OUT   STD_LOGIC;
	o_CLK_12MHz     : OUT   STD_LOGIC;
	o_CLK_60MHz     : OUT   STD_LOGIC


  );
END usb_2upper;

ARCHITECTURE rtl OF usb_2upper IS

  TYPE   outp_mode  IS(RECV, SEND);
  CONSTANT BUFSIZE_BITS : Integer := 8;
  SIGNAL areset         : STD_LOGIC;
  SIGNAL clk_60mhz      : STD_LOGIC;
  SIGNAL clk_70mhz      : STD_LOGIC;
  SIGNAL online         : STD_LOGIC;
  SIGNAL outp_cntl      : outp_mode;
  SIGNAL outp_reg       : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL pll_locked     : STD_LOGIC;
  SIGNAL reset_sync_60  : STD_LOGIC;
  SIGNAL rxdat          : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL rxrdy          : STD_LOGIC;
  SIGNAL rxval          : STD_LOGIC;
  SIGNAL txcork         : STD_LOGIC;
  SIGNAL txdat          : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL txrdy          : STD_LOGIC;
  SIGNAL txval          : STD_LOGIC;
  SIGNAL usb_rst        : STD_LOGIC;
  SIGNAL clk_50MHz      : STD_LOGIC;
  
COMPONENT OSCH
-- synthesis translate_off
GENERIC (NOM_FREQ: string := "11.57");
-- synthesis translate_on
PORT ( STDBY :IN std_logic;
OSC :OUT std_logic;
SEDSTDBY :OUT std_logic);
END COMPONENT; 
attribute NOM_FREQ : string;
attribute NOM_FREQ of OSCinst0 : label is "11.57";
 
BEGIN

  areset <= NOT rst_neg_ext;

  FPGA_ready <= not (pll_locked);

  LED_green  <= not (online);
  o_CLK_12MHz  <= clk_50MHz;
  o_CLK_60MHz  <= clk_60MHz;


  -- PLL_1 : ENTITY work.pll_60MHz
  -- PORT MAP (
    -- areset     => areset,
    -- inclk0     => clk_50MHz,
    -- c0         => clk_60MHz,
    -- locked     => pll_locked
  -- );
  
OSCInst0: OSCH
-- synthesis translate_off
GENERIC MAP ( NOM_FREQ => "11.57" )
-- synthesis translate_on
PORT MAP ( 
STDBY=> '0',
OSC=> clk_50MHz,
SEDSTDBY=> open
 );

  
  PLL_1 : ENTITY work.pll_60MHz
  PORT MAP (
    RST      => areset,
    CLKI     => clk_50MHz,
    CLKOP    => clk_60MHz,
    LOCK     => pll_locked
  );
  
  usb_spi_1: entity work.usb_2_spi
  generic map(
	SELFTEST => 1
	)
	port map(
		clk  => clk_60MHz,
		resetn => rst_neg_ext,
		usb_dp      => usb_dp, 
		usb_dn      => usb_dn,
		usb_ready   => open,
		usb_online  => online,
		loopback    => (others => '0'),
		
		sclk        => open,
		-- SPI master in, slave out
		miso                => '0',
		mosi                => open,
		-- SPI slave select
		ss_n                => open
		);
  
  
END rtl;

