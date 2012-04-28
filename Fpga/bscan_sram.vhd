library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity bscan_sram is
	port (
		A:		out   STD_LOGIC_VECTOR(18 downto 0);
		D:		inout STD_LOGIC_VECTOR(15 downto 0);
		nCS:	out   STD_LOGIC;
		nOE:	out   STD_LOGIC;
		nWE:	out   STD_LOGIC;
		nBLE:	out   STD_LOGIC;
		nBHE:	out   STD_LOGIC;
		
		led1:	out   STD_LOGIC);
end bscan_sram;

architecture Behavioral of bscan_sram is

	signal user_CAPTURE:		std_ulogic;
	signal user_DRCK:			std_ulogic;
	signal user_RESET:		std_ulogic;
	signal user_SEL:			std_ulogic;
	signal user_SHIFT:		std_ulogic;
	signal user_TDI:			std_ulogic;
	signal user_UPDATE:		std_ulogic;
	signal user_TDO:			std_ulogic;

	signal tdi_mem:			std_logic_vector(31 downto 0);
	signal tdo_mem:			std_logic_vector(15 downto 0);
	
	constant STATE_WAIT:		integer := 0;
	constant STATE_WRITE0:	integer := 1;
	constant STATE_WRITE:	integer := 2;
	constant STATE_READ0:	integer := 3;
	constant STATE_READ:		integer := 4;
	
	signal reset:				std_logic;
	signal state:				integer := STATE_WAIT;
	signal repeat_count:		unsigned(24 downto 0);
	signal bit_count:			unsigned(3 downto 0);
	
	signal A_in:				unsigned(18 downto 0);
	
	signal led1_in:			std_logic := '0';
begin

	reset <= user_CAPTURE or user_RESET or user_UPDATE or not user_SEL;

	BS : BSCAN_SPARTAN6
	port map (
		CAPTURE	=> user_CAPTURE,
		DRCK		=> user_DRCK,
		RESET		=> user_RESET,
		SEL		=> user_SEL,
		SHIFT		=> user_SHIFT,
		TDI		=> user_TDI,
		UPDATE	=> user_UPDATE,
		TDO		=> user_TDO
	);
	
	A		<= std_logic_vector(A_in);
	nCS	<= '0';
	nBLE	<= '0';
	nBHE	<= '0';
	
	nOE	<= '0' when state=STATE_READ else '1';
	nWE	<= '0' when state=STATE_WRITE and bit_count=2 else '1';
	
	led1 <= led1_in;--'0' when state=STATE_WAIT else '1';

	process (reset,user_DRCK)
	begin
		if (reset='1') then
			state <= STATE_WAIT;
			led1_in <= '0';
			
		elsif (falling_edge(user_DRCK)) then
			case state is
			when STATE_WAIT =>
				-- start write : 59a6 xxxx (xxxx = # of 512B pages)
				if (tdi_mem(31 downto 16)="0101100110100110") then
					A_in(18 downto 0)				<= (others=>'0');
					repeat_count(24 downto 9)	<= unsigned(tdi_mem(15 downto 0));
					repeat_count(8 downto 0)	<= (others=>'0');
					bit_count						<= (others=>'1');
					state								<= STATE_WRITE0;
					led1_in <= '1';
				end if;
				
			when STATE_WRITE0 =>
				if bit_count>0 then
					bit_count		<= bit_count-1;
				else
					D					<= tdi_mem(15 downto 0);
					bit_count		<= (others=>'1');
					state				<= STATE_WRITE;
				end if;
				
			when STATE_WRITE =>
				if bit_count>0 then
					bit_count		<= bit_count-1;
				else
					A_in				<= A_in+1;
					D					<= tdi_mem(15 downto 0);
					bit_count		<= (others=>'1');
					if repeat_count>0 then
						repeat_count<= repeat_count-1;
					else
						state			<= STATE_WAIT;
					end if;
				end if;
				
--			when STATE_READ =>
--				if bit_count>0 then
--					bit_count		<= bit_count-1;
--					next_tdo			<= D;
--				else
--					A_in				<= A_in+1;
--					bit_count		<= (others=>'1');
--					if repeat_count>0 then
--						repeat_count<= repeat_count-1;
--					else
--						state			<= STATE_WAIT;
--					end if;
--				end if;
				
			when others =>
				state <= STATE_WAIT;
			end case;
		end if;
	end process;

	process (reset,user_DRCK)
	begin
		if reset='1' then
			tdo_mem <= (others => '0');
			tdi_mem <= (others => '0');
			
		elsif rising_edge(user_DRCK) then
			tdi_mem(0) <= user_TDI;
			tdi_mem(31 downto 1) <= tdi_mem(30 downto 0);

			tdo_mem(0) <= '0';
			tdo_mem(tdo_mem'high downto 1) <= tdo_mem((tdo_mem'high-1) downto 0);
		end if;
	end process;

end Behavioral;