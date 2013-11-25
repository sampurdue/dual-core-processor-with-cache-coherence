-- ExtOp
--	00 Logical Extend
--	01 Signed Extend
--	10 SLL by 16 bits

library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Extender is
	port
	(
		ExtOp	:	in	std_logic_vector (1 downto 0);
		input	:	in	std_logic_vector (15 downto 0);
		ExtOut	:	out	std_logic_vector (31 downto 0)
	);
end Extender;

architecture behavioral of Extender is

begin

	ExtOut <=	(x"FFFF" & input) when (ExtOp = "01" and input(15) = '1') else	-- pad 1's when input MSB is 1 and ExtOp is 01
			(input & x"0000") when (ExtOp = "10") else			-- SLL by 16 bits if ExtOp is 10
			(x"0000" & input);						-- pad 0's in all other cases
		
end behavioral;
