library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity fulladder1bit is
	port
	(
		A	: in	std_logic;
		B	: in	std_logic;
		Cin	: in	std_logic;
		S	: out	std_logic;
		Cout	: out	std_logic
	);
end fulladder1bit;

architecture fulladder1bit_arch of fulladder1bit is 

begin

	S <= A xor B xor Cin;
	Cout <= (A and B) or ((A xor B) and Cin);

end fulladder1bit_arch;

