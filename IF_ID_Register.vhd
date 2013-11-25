library ieee;
use ieee.std_logic_1164.all;

entity IF_ID_Register is
	port (
		clk	:	in	std_logic;
		nReset	:	in	std_logic;
		flush	:	in	std_logic;
		wren	:	in	std_logic;
		data	:	in	std_logic_vector (63 downto 0);
		q	:	out	std_logic_vector (63 downto 0)
	);
end IF_ID_Register;

architecture behavioral of IF_ID_Register is

begin

	CLK_signal: process (clk,flush,nReset,wren)
	begin
		if (nReset = '0' or flush = '1') then
			q <= (others => '0');
		elsif  (wren = '1' and rising_edge(CLK)) then
			q <= data;
		end if;
	end process CLK_signal;

end behavioral;
