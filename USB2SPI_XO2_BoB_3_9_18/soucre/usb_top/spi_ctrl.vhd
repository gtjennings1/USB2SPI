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
	constant READ_SR1      : std_logic_vector(7 downto 0) := X"05";
	constant READ_SR2      : std_logic_vector(7 downto 0) := X"35";
	constant DEVICE_ID     : std_logic_vector(7 downto 0) := X"90";
	constant UNIQUE_ID     : std_logic_vector(7 downto 0) := X"4B";
	constant JEDEC_ID      : std_logic_vector(7 downto 0) := X"9F";
	constant READ_DATA     : std_logic_vector(7 downto 0) := X"03";
	constant READ_FAST     : std_logic_vector(7 downto 0) := X"0B";

	constant NO_PAYLOAD    : std_logic_vector(8 downto 0) := (others => '0');
	type states is (Idle, Active);
	type cmd_states is (WaitCommand, Size_LSB, Size_MSB, Prepare, Transfer, WaitEnd);
	signal command_state : cmd_states;
	signal transfer_len  : std_logic_vector(8 downto 0);
	signal state              : states;
	signal fsm_rx_ready      : std_logic;
	signal spi_tx_ready       : std_logic;
	signal command_valid      : std_logic;
	signal command            : std_logic_vector(7 downto 0);
	signal active_mode_en     : std_logic;
	signal read_mode_en       : std_logic;
	signal spi_rx_valid       : std_logic;
	signal rx_hold            : std_logic;
	signal active_mode_en_d : std_logic;
	signal active_mode_en_dd : std_logic;
	signal fsm_tx_valid 	: std_logic;
	signal cont : std_logic;
	

begin
	spi_resetn     <= '0' when state = Idle else '1';
	creset         <= '1' when state = Idle else '0';
	
	spi_tx_data    <= usb_rx_data;
	usb_tx_data    <= spi_rx_data;
	
	-- Main command FSM
	process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				command_state <= WaitCommand;
				command_valid <= '0';
				fsm_rx_ready <= '0';
				rx_hold 	<= '0';
				cont <= '0';
			else
				case command_state is 
					when WaitCommand =>
						fsm_rx_ready <= '1';
						if usb_rx_valid = '1' then
							command <= usb_rx_data;
							command_valid <= '1';
							command_state <= Size_LSB;
							cont <= '1';
						end if;
					when Size_LSB =>
						command_valid <= '0';
						if usb_rx_valid = '1' then
							transfer_len(7 downto 0) <= usb_rx_data;
							command_state <= Size_MSB;
						end if;
					when Size_MSB =>
						if usb_rx_valid = '1' then
							transfer_len(8) <= usb_rx_data(0);
							command_state <= Prepare;
							fsm_rx_ready <= '0';
						end if;
					when Prepare =>
						if transfer_len = NO_PAYLOAD then
							command_state <= WaitEnd;
						elsif transfer_len <= (usb_rx_len + 1) then
							command_state <= Transfer;
							rx_hold <= '0';
						else
							rx_hold <= '1';
						end if;
					when Transfer =>
						if transfer_len = NO_PAYLOAD then
							command_state <= WaitEnd;
						elsif usb_rx_valid = '1' and spi_busy = '0' then
							transfer_len <= transfer_len - 1;
						end if;
					when WaitEnd =>
						cont <= '0';
						if spi_busy = '0' then
							command_state <= WaitCommand;
						end if;
				end case;
			end if;
		end if;
	end process;
	
	spi_cont <= cont;
	spi_hold <= rx_hold;
	spi_tx_ready <= not spi_busy when command_state = Transfer else '0';
	usb_rx_ready   <= fsm_rx_ready or spi_tx_ready;
	spi_enable     <= '0' when state = Idle else fsm_tx_valid;
	fsm_tx_valid <= usb_rx_valid when command_state = Transfer or command_state = WaitCommand else '0';
	-- command parser
	process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				active_mode_en <= '0';
				read_mode_en   <= '0';
			else
				if command_valid = '1' then
					case command is
						when WRITE_ENABLE =>
							active_mode_en <= '1';
							read_mode_en   <= '0';
						when WRITE_DISABLE =>
							active_mode_en <= '0';
							read_mode_en   <= '0';
						when READ_SR1 | READ_SR2 | READ_DATA | READ_FAST | DEVICE_ID | UNIQUE_ID | JEDEC_ID =>
							read_mode_en <= '1';
						when others =>
							read_mode_en <= '0';
					end case;
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
				active_mode_en_d <= '0';
				active_mode_en_dd <= '0';
			else
				active_mode_en_d <= active_mode_en;
				active_mode_en_dd <= active_mode_en_d;
				if active_mode_en_dd = '1' then
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
	
	usb_tx_valid   <= spi_rx_valid;
	

end architecture RTL;
