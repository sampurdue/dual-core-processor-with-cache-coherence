library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity fulladder32bit is
	port
	(
		A32	: in	std_logic_vector(31 downto 0);
		B32	: in	std_logic_vector(31 downto 0);
		Cin32	: in	std_logic;
		S32	: out	std_logic_vector(31 downto 0);
		Cout32	: out	std_logic
	);
end fulladder32bit;

architecture fulladder32bit_arch of fulladder32bit is
signal c	: std_logic	:= '0';
component fulladder16bit
	port(	A16, B16	: in std_logic_vector(15 downto 0);
		Cin16		: in std_logic;
		S16		: out std_logic_vector(15 downto 0);
		Cout16		: out std_logic);
end component;

begin

	x3210: fulladder16bit port map (A16=>A32(15 downto 0), B16=>B32(15 downto 0), S16=>S32(15 downto 0), Cin16=>Cin32, Cout16=>c);
	x7654: fulladder16bit port map (A16=>A32(31 downto 16), B16=>B32(31 downto 16), S16=>S32(31 downto 16), Cin16=>c, Cout16=>Cout32);

end fulladder32bit_arch;
