library ieee;
use ieee.std_logic_1164.all;

entity EX_MEM_Register is
	port (
		clk	:	in	std_logic;
		nReset	:	in	std_logic;
		wren	:	in	std_logic;
		data	:	in	std_logic_vector (174 downto 0);
		q	:	out	std_logic_vector (174 downto 0)
	);
end EX_MEM_Register;

architecture behavioral of EX_MEM_Register is

begin

	CLK_signal: process (clk,nReset,wren)
	begin
		if (nReset = '0') then
			q <= (others => '0');
		elsif  (wren = '1' and rising_edge(CLK)) then
			q <= data;
		end if;
	end process CLK_signal;

end behavioral;
