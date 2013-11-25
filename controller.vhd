library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity controller is
	port
	(
		instr		:	in	std_logic_vector (31 downto 0);
		RegWr		:	out	std_logic;
		RegDst		:	out	std_logic;
		ExtOp		:	out	std_logic_vector (1 downto 0);
		ALUSrc		:	out	std_logic;
		ALUOp		:	out	std_logic_vector (3 downto 0);
		MemWr		:	out	std_logic;
		MemRd		:	out	std_logic;
		MemtoReg	:	out	std_logic;
		Jump		:	out	std_logic;
		BusWSel		:	out	std_logic;
		ShamtSel	:	out	std_logic;
		JumpSel		:	out	std_logic;
		JalSel		:	out	std_logic;
		linked		:	out 	std_logic;
		stCondnal	:	out	std_logic;
		halt		:	out	std_logic
	);
end controller;

architecture controller_arch of controller is

	constant BAD1		:	std_logic_vector	:= x"BAD1BAD1";
	signal control_s	:	std_logic_vector (8 downto 0);
	-- control_s = RegWr : RegDst : ExtOp ExtOp : AluSrc : AluOp AluOp AluOp AluOp

begin

	control_s <=	"000000000" when (instr = X"00000000") else --NOP
			"110000010" when (instr(31 downto 26) = "000000" and instr(5 downto 0) = "100001") else	-- ADDU 0010
			"110000100" when (instr(31 downto 26) = "000000" and instr(5 downto 0) = "100100") else	-- AND 0100
			"110000110" when (instr(31 downto 26) = "000000" and instr(5 downto 0) = "100101") else	-- OR 0110
			"110000111" when (instr(31 downto 26) = "000000" and instr(5 downto 0) = "100110") else	-- XOR 0111
			"110000101" when (instr(31 downto 26) = "000000" and instr(5 downto 0) = "100111") else	-- NOR 0101
			"110001000" when (instr(31 downto 26) = "000000" and instr(5 downto 0) = "101010") else	-- SLT 1000
			"110001001" when (instr(31 downto 26) = "000000" and instr(5 downto 0) = "101011") else	-- SLTU 1001
			"110000011" when (instr(31 downto 26) = "000000" and instr(5 downto 0) = "100011") else	-- SUBU 0011
			"110000000" when (instr(31 downto 26) = "000000" and instr(5 downto 0) = "000000") else	-- SLL 0000
			"110000001" when (instr(31 downto 26) = "000000" and instr(5 downto 0) = "000010") else	-- SRL 0001
			"100110010" when (instr(31 downto 26) = "001001") else	-- ADDIU 0010
			"100010110" when (instr(31 downto 26) = "001101") else	-- ORI 0110
			"100110010" when (instr(31 downto 26) = "100011" or instr(31 downto 26) = "110000" ) else	-- LW/LL (ADD 0010)
			"000110010" when (instr(31 downto 26) = "101011" ) else	-- SW (ADD 0010)
			"100110010" when (instr(31 downto 26) = "111000") else --SC (ADD 0010)
			"100010100" when (instr(31 downto 26) = "001100") else	-- ANDI 0100
			"101011010" when (instr(31 downto 26) = "001111") else	-- LUI
			"100010111" when (instr(31 downto 26) = "001110") else	-- XORI 0111

			"000000000" when (instr(31 downto 26) = "000000" and instr(5 downto 0) = "001000") else	-- JR
			"100111000" when (instr(31 downto 26) = "001010") else	-- SLTI 1000
			"100111001" when (instr(31 downto 26) = "001011") else	-- SLTIU
			"100000000" when (instr(31 downto 26) = "000011") else	-- JAL
			"000100011" when (instr(31 downto 26) = "000100") else	-- BEQ
			"000100011" when (instr(31 downto 26) = "000101") else	-- BNE (ALUOp = SUB 011)
			"000000000" when (instr(31 downto 26) = "000010") else	-- J
			"000000000";
	

	RegWr 		<=	control_s(8);
	RegDst		<=	control_s(7);
	ExtOp		<=	control_s(6 downto 5);
	ALUSrc		<=	control_s(4);
	ALUOp		<=	control_s(3 downto 0);

	MemWr		<=	'1' when (instr(31 downto 26) = "101011" or instr(31 downto 26) = "111000") else '0';	-- SW/SC
	MemRd		<=	'1' when (instr(31 downto 26) = "100011" or instr(31 downto 26) = "110000") else '0';	-- LW/LL
	MemtoReg	<=	'1' when (instr(31 downto 26) = "100011" or instr(31 downto 26) = "110000") else '0';	-- LW/LL
	Jump		<=	'1' when (instr(31 downto 26) = "000010" or (instr(31 downto 26) = "000000" and instr(5 downto 0) = "001000") or instr(31 downto 26) = "000011") else '0';	-- J/JR/JAL
	BusWSel		<=	'0';--'1' when (instr(31 downto 26) = "001111") else '0';	-- LUI
	ShamtSel	<=	'1' when (instr(31 downto 26) = "000000" and (instr(5 downto 0) = "000000" or instr(5 downto 0) = "000010") and (not(instr = X"00000000"))) else '0';	-- SLL/SRL
	JumpSel		<=	'1' when (instr(31 downto 26) = "000010" or instr(31 downto 26) = "000011") else '0';	-- '1' when J/JAL (imm used) and '0' when JR or all other cases
	JalSel		<=	'1' when (instr(31 downto 26) = "000011") else '0';	-- JAL
	linked		<= 	'1' when (instr(31 downto 26) = "110000") else '0';
	stCondnal	<= 	'1' when (instr(31 downto 26) = "111000") else '0';

	halt		<=	'1' when (instr = x"FFFFFFFF") else '0';

end controller_arch;
