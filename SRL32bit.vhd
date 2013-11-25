library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity SRL32bit is
	port
	(
		A	: in	std_logic_vector (31 downto 0);
		B	: in	std_logic_vector (4 downto 0);
		Y	: out	std_logic_vector (31 downto 0)
	);
end SRL32bit;

architecture SRL32bit_arch of SRL32bit is 

	signal ri4, ri3, ri2, ri1	:	std_logic_vector(31 downto 0);
        constant shift16		:	std_logic_vector(15 downto 0)	:=	x"0000";
        constant shift8			:	std_logic_vector(7 downto 0)	:=	x"00";
        constant shift4			:	std_logic_vector(3 downto 0)	:=	x"0";
        constant shift2			:	std_logic_vector(1 downto 0)	:=	"00";
        constant shift1			:	std_logic			:=	'0';

begin

	-- SLL - Shift Left Logical
	--=========================
	-- 16 bit logical right shift if B(4) is '1'
	with B(4) select
		ri4 <=	shift16 & A(31 downto 16)		when '1',
			A					when others;

	-- 8 bit logical right shift if B(3) is '1'
	with B(3) select
		ri3 <=	shift8 & ri4(31 downto 8)		when '1',
			ri4					when others;

	-- 4 bit logical right shift if B(2) is '1'
	with B(2) select
		ri2 <=	shift4 & ri3(31 downto 4)		when '1',
			ri3					when others;

	-- 2 bit logical right shift if B(1) is '1'
	with B(1) select
		ri1 <=	shift2 & ri2(31 downto 2)		when '1',
			ri2					when others;

	-- 1 bit logical right shift if B(0) is '1'
	with B(0) select
		Y <=	shift1 & ri1(31 downto 1)		when '1',
			ri1					when others;

end SRL32bit_arch;

