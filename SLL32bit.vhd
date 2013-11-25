library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity SLL32bit is
	port
	(
		A	: in	std_logic_vector (31 downto 0);
		B	: in	std_logic_vector (4 downto 0);
		Y	: out	std_logic_vector (31 downto 0)
	);
end SLL32bit;

architecture SLL32bit_arch of SLL32bit is 

	signal li4, li3, li2, li1	:	std_logic_vector(31 downto 0);
        constant shift16		:	std_logic_vector(15 downto 0)	:=	x"0000";
        constant shift8			:	std_logic_vector(7 downto 0)	:=	x"00";
        constant shift4			:	std_logic_vector(3 downto 0)	:=	x"0";
        constant shift2			:	std_logic_vector(1 downto 0)	:=	"00";
        constant shift1			:	std_logic			:=	'0';

begin

	-- SLL - Shift Left Logical
	--=========================
	-- 16 bit logical left shift if B(4) is '1'
	with B(4) select
		li4 <=	A(15 downto 0) & shift16		when '1',
			A					when others;

	-- 8 bit logical left shift if B(3) is '1'
	with B(3) select
		li3 <=	li4(23 downto 0) & shift8		when '1',
			li4					when others;

	-- 4 bit logical left shift if B(2) is '1'
	with B(2) select
		li2 <=	li3(27 downto 0) & shift4		when '1',
			li3					when others;

	-- 2 bit logical left shift if B(1) is '1'
	with B(1) select
		li1 <=	li2(29 downto 0) & shift2		when '1',
			li2					when others;

	-- 1 bit logical left shift if B(0) is '1'
	with B(0) select
		Y <=	li1(30 downto 0) & shift1		when '1',
			li1					when others;

end SLL32bit_arch;

