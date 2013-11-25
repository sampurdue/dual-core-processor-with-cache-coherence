library ieee;
use ieee.std_logic_1164.all;

entity Mux_2_1_5bit is
	port
	(
		sel	:	in	std_logic;
		A	:	in	std_logic_vector (4 downto 0);
		B	:	in	std_logic_vector (4 downto 0);
		muxout	:	out	std_logic_vector (4 downto 0)
	);
end Mux_2_1_5bit;

architecture behavioral of Mux_2_1_5bit is

	constant zero	:	std_logic_vector	:= "00000";

begin

	with sel select
		muxout <=	A when '0',
				B when '1',
				zero when others;

end behavioral;
