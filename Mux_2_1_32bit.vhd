library ieee;
use ieee.std_logic_1164.all;

entity Mux_2_1_32bit is
	port
	(
		sel	:	in	std_logic;
		A	:	in	std_logic_vector (31 downto 0);
		B	:	in	std_logic_vector (31 downto 0);
		muxout	:	out	std_logic_vector (31 downto 0)
	);
end Mux_2_1_32bit;

architecture behavioral of Mux_2_1_32bit is

	constant zero	:	std_logic_vector	:= x"00000000";

begin

	with sel select
		muxout <=	A when '0',
				B when '1',
				zero when others;

end behavioral;
