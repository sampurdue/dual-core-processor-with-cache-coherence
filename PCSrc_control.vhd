library ieee;
use ieee.std_logic_1164.all;

entity PCSrc_control is
	port (
		opcode	:	in	std_logic_vector (5 downto 0);
		equal	:	in	std_logic;
		PCSrc	:	out	std_logic
	);
end PCSrc_control;

architecture behavioral of PCSrc_control is

begin

	PCSrc <=	'1' when (opcode = "000100" and Equal = '1') else	-- BEQ
			'1' when (opcode = "000101" and Equal = '0') else	-- BNE
			'0';

end behavioral;
