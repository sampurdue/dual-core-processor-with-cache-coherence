library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity fulladder16bit is
	port
	(
		A16	: in	std_logic_vector(15 downto 0);
		B16	: in	std_logic_vector(15 downto 0);
		Cin16	: in	std_logic;
		S16	: out	std_logic_vector(15 downto 0);
		Cout16	: out	std_logic
	);
end fulladder16bit;

architecture fulladder16bit_arch of fulladder16bit is
signal c	: std_logic_vector(2 downto 0)	:= "000";
component fulladder4bit
	port(	A4, B4		: in std_logic_vector(3 downto 0);
		Cin4		: in std_logic;
		S4		: out std_logic_vector(3 downto 0);
		Cout4		: out std_logic);
end component;

begin

	x0: fulladder4bit port map (A4=>A16(3 downto 0), B4=>B16(3 downto 0), S4=>S16(3 downto 0), Cin4=>Cin16, Cout4=>c(0));
	x1: fulladder4bit port map (A4=>A16(7 downto 4), B4=>B16(7 downto 4), S4=>S16(7 downto 4), Cin4=>c(0), Cout4=>c(1));
	x2: fulladder4bit port map (A4=>A16(11 downto 8), B4=>B16(11 downto 8), S4=>S16(11 downto 8), Cin4=>c(1), Cout4=>c(2));
	x3: fulladder4bit port map (A4=>A16(15 downto 12), B4=>B16(15 downto 12), S4=>S16(15 downto 12), Cin4=>c(2), Cout4=>Cout16);

end fulladder16bit_arch;
