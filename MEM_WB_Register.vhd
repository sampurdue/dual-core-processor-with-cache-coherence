library ieee;
use ieee.std_logic_1164.all;

entity MEM_WB_Register is
	port (
		clk	:	in	std_logic;
		nReset	:	in	std_logic;
		wren	:	in	std_logic;
		data	:	in	std_logic_vector (170 downto 0);
		q	:	out	std_logic_vector (170 downto 0)
	);
end MEM_WB_Register;

architecture behavioral of MEM_WB_Register is

begin

	CLK_signal: process (clk)
	begin
		if (nReset = '0') then
			q <= (others => '0');
		elsif  (wren = '1' and rising_edge(CLK)) then
			q <= data;
		end if;
	end process CLK_signal;

end behavioral;
