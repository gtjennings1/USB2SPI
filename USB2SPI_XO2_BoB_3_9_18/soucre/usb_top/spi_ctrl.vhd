library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity spi_ctrl is
	generic(
		DCOUNTER_W : integer := 8
	);
	port(
		clk          : in  std_logic;
		reset        : in  std_logic;

		-- USB interface
		usb_rx_ready : out std_logic;
		usb_rx_valid : in  std_logic;
		usb_rx_data  : in  std_logic_vector(7 downto 0);
		usb_rx_len   : in  std_logic_vector(DCOUNTER_W - 1 downto 0);
		usb_tx_valid : out std_logic;
		usb_tx_data  : out std_logic_vector(7 downto 0);

		-- SPI interface
		spi_resetn   : out std_logic;
		spi_busy     : in  std_logic;
		spi_enable   : out std_logic;
		spi_hold     : out std_logic;
		spi_cont     : out std_logic;
		spi_tx_data  : out std_logic_vector(7 downto 0);
		spi_rx_data  : in  std_logic_vector(7 downto 0);

		-- External control
		creset       : out std_logic
	);
end entity spi_ctrl;

architecture RTL of spi_ctrl is
	constant WRITE_ENABLE  : std_logic_vector(7 downto 0) := X"06";
	constant WRITE_DISABLE : std_logic_vector(7 downto 0) := X"04";
	constant PAGE_PROGRAM  : std_logic_vector(7 downto 0) := X"02";
	constant READ_SR1      : std_logic_vector(7 downto 0) := X"05";
	constant READ_SR2      : std_logic_vector(7 downto 0) := X"35";
	constant DEVICE_ID     : std_logic_vector(7 downto 0) := X"90";
	constant UNIQUE_ID     : std_logic_vector(7 downto 0) := X"4B";
	constant JEDEC_ID      : std_logic_vector(7 downto 0) := X"9F";
	constant READ_DATA     : std_logic_vector(7 downto 0) := X"03";
	constant READ_FAST     : std_logic_vector(7 downto 0) := X"0B";

	type states is (Idle, Active);
	signal state              : states;
	signal usb_rx_ready_i     : std_logic;
	signal usb_rx_valid_d     : std_logic;
	signal usb_rx_command_rdy : std_logic;
	signal command_valid      : std_logic;
	signal command            : std_logic_vector(7 downto 0);
	signal active_mode_en     : std_logic;
	signal read_mode_en       : std_logic;
	signal spi_rx_valid       : std_logic;
	signal wait_data_en       : std_logic;
	signal rx_hold            : std_logic;
	signal rx_data_extended   : std_logic_vector(DCOUNTER_W - 1 downto 0);
	signal rx_expected 		  : std_logic_vector(DCOUNTER_W - 1 downto 0);

begin
	spi_resetn     <= '0' when state = Idle else '1';
	creset         <= '1' when state = Idle else '0';
	usb_rx_ready_i <= '1' when state = Idle else (not spi_busy);
	spi_enable     <= '0' when state = Idle else usb_rx_valid;
	spi_cont       <= '0' when state = Idle else usb_rx_valid;
	spi_hold       <= rx_hold;
	spi_tx_data    <= usb_rx_data;
	usb_tx_data    <= spi_rx_data;
	usb_rx_ready   <= (usb_rx_ready_i and not rx_hold) or wait_data_en;
	usb_tx_valid   <= spi_rx_valid;

	-- capturing a command
	process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				usb_rx_valid_d     <= '0';
				usb_rx_command_rdy <= '0';
			else
				usb_rx_valid_d <= usb_rx_valid;
				if usb_rx_valid = '1' and usb_rx_valid_d = '0' then
					usb_rx_command_rdy <= not usb_rx_ready_i;
				elsif usb_rx_ready_i = '1' then
					usb_rx_command_rdy <= '0';
				end if;
			end if;
		end if;
	end process;

	command       <= usb_rx_data when rising_edge(clk);
	command_valid <= usb_rx_valid and usb_rx_ready_i and (usb_rx_command_rdy or not usb_rx_valid_d) when rising_edge(clk);

	-- command parser
	process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				active_mode_en <= '0';
				read_mode_en   <= '0';
				wait_data_en   <= '0';
			else
				if command_valid = '1' then
					case command is
						when WRITE_ENABLE =>
							active_mode_en <= '1';
							read_mode_en   <= '0';
							wait_data_en <= '0';
						when WRITE_DISABLE =>
							active_mode_en <= '0';
							read_mode_en   <= '0';
							wait_data_en <= '0';
						when PAGE_PROGRAM  =>
							wait_data_en <= '1';
						when READ_SR1 | READ_SR2 | READ_DATA | READ_FAST | DEVICE_ID | UNIQUE_ID | JEDEC_ID =>
							read_mode_en <= '1';
						when others =>
							read_mode_en <= '0';
							wait_data_en <= '0';
					end case;
				else
					wait_data_en <= '0';
				end if;
			end if;
		end if;
	end process;

	-- State switcher
	process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				state <= Idle;
			else
				if active_mode_en = '1' then
					state <= Active;
				else
					if spi_busy = '0' then
						state <= Idle;
					end if;
				end if;
			end if;
		end if;
	end process;

	spi_rx_valid_capturing : block
		signal spi_busy_d : std_logic;
	begin
		spi_busy_d   <= spi_busy when rising_edge(clk);
		spi_rx_valid <= '1' when spi_busy = '0' and spi_busy_d = '1' and read_mode_en = '1' else '0';
	end block spi_rx_valid_capturing;
	
	
	-- extend rx data
	rx_data_extended(7 downto 0) <= usb_rx_data;
	rx_data_extend : if DCOUNTER_W > 8 generate
		rx_data_extended(DCOUNTER_W - 1 downto 8) <= (others => '0');
	end generate rx_data_extend;
	
	
	-- waiting data
	process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				rx_hold <= '0';
				rx_expected <= (others => '0');
			else
				if rx_hold = '0' then
					if wait_data_en = '1' then
						rx_hold <= '1';
						rx_expected <= rx_data_extended + X"4";
					end if;
				else
					if rx_expected = usb_rx_len then
						rx_hold <= '0';
					end if;
				end if;
			end if;
		end if;
	end process;

end architecture RTL;
