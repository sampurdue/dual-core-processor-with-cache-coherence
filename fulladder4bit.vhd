library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity fulladder4bit is
	port
	(
		A4	: in	std_logic_vector(3 downto 0);
		B4	: in	std_logic_vector(3 downto 0);
		Cin4	: in	std_logic;
		S4	: out	std_logic_vector(3 downto 0);
		Cout4	: out	std_logic
	);
end fulladder4bit;

architecture fulladder4bit_arch of fulladder4bit is
signal c	: std_logic_vector(2 downto 0)	:= "000";
component fulladder1bit
	port(	A, B, Cin	:in std_logic;
		S, Cout		:out std_logic);
end component;

begin

	bit0: fulladder1bit port map (A=>A4(0), B=>B4(0), S=>S4(0), Cin=>Cin4, Cout=>c(0));
	bit1: fulladder1bit port map (A=>A4(1), B=>B4(1), S=>S4(1), Cin=>c(0), Cout=>c(1));
	bit2: fulladder1bit port map (A=>A4(2), B=>B4(2), S=>S4(2), Cin=>c(1), Cout=>c(2));
	bit3: fulladder1bit port map (A=>A4(3), B=>B4(3), S=>S4(3), Cin=>c(2), Cout=>Cout4);

end fulladder4bit_arch;
