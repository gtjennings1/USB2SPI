
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
--  File name   : USB_tb.vhd                                                                                --
--  Author      : Martin Neumann  martin@neumanns-mail.de                                                   --
--  Description : USB test bench - an example how to use the usb_master files together an US application.   --
--                                                                                                          --
--     The test bench simulates a FPGA board with a 50 MHz oscillator, async reset and a USB PC connection  --
--     The last lines of code simulate a FS pullup resistor ...                                             --
--                                                                                                          --
--==========================================================================================================--
--                                                                                                          --
-- Change history                                                                                           --
--                                                                                                          --
-- Version / date        Description                                                                        --
--                                                                                                          --
-- 01  05 Mar 2011 MN    Initial version                                                                    --
-- 02  15 Apr 2013 MN    Simplified                                                                         --
--                                                                                                          --
-- End change history                                                                                       --
--==========================================================================================================--

LIBRARY work, IEEE;
  USE IEEE.std_logic_1164.ALL;
  USE work.usb_commands.ALL;

ENTITY usb_tb IS
END usb_tb;

ARCHITECTURE sim OF usb_tb IS

  SIGNAL clk_50MHz      : STD_LOGIC;
  SIGNAL rst_neg_ext    : STD_LOGIC;
  SIGNAL usb_dp         : STD_LOGIC;
  SIGNAL usb_dn         : STD_LOGIC;
  SIGNAL FPGA_ready     : STD_LOGIC;

BEGIN

  usb_dp <= 'L' WHEN rst_neg_ext ='0' OR FPGA_ready ='0' ELSE 'H' after 10 ns; -- simulate the pullup resistor

  p_clk_50MHz : PROCESS
  BEGIN
    clk_50MHz <= '0';
    WAIT FOR 10 ns;
    clk_50MHz <= '1';
    WAIT FOR 10 ns;
  END PROCESS;

  p_res_neg_ext : PROCESS
  BEGIN
    rst_neg_ext <= '0', '1' AFTER 133 ns;
    WAIT;
  END PROCESS;

  usb_1 : ENTITY work.usb_2upper
  PORT MAP(
   clk_50MHz      => clk_50MHz,
    rst_neg_ext    => rst_neg_ext,
    usb_dp         => usb_dp,
    usb_dn         => usb_dn,
    FPGA_ready     => FPGA_ready
  );

  usb_fs_master : ENTITY work.usb_fs_master
  PORT MAP (
    rst_neg_ext => rst_neg_ext,
    usb_Dp      => usb_dp,
    usb_Dn      => usb_dn
  );

  usb_dp <= 'L' WHEN  FPGA_ready ='0' ELSE 'H' after 10 ns;
  usb_dn <= 'L';

END sim;

