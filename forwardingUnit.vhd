--forwardingUnit.vhd
--		MUX	Source
--ForwardA	00	ID/EX reg
--		01	Writeback
--		10	Memory
--ForwardB	00	ID/EX reg
--		01	Writeback
--		10	Memory

library ieee;
use ieee.std_logic_1164.all;

entity forwardingUnit is
	port(	IDEXRegisterRs 	: 	in std_logic_vector(4 downto 0);
		IDEXRegisterRt		:	in std_logic_vector(4 downto 0);
		--IDEXRegDst		:	in std_logic;
		IDEXMemRd		:	in std_logic;
		EXMEMRegWrite		:	in std_logic;
		EXMEMRegisterRd		:	in std_logic_vector(4 downto 0);
		MEMWBRegWrite			:	in std_logic;
		MEMWBRegisterRd		: 	in std_logic_vector(4 downto 0);
		ForwardA			:	out std_logic_vector(1 downto 0);
		ForwardB			:	out std_logic_vector(1 downto 0)	
		);
end forwardingUnit;

architecture behav of forwardingUnit is
begin
	process(IDEXRegisterRs,IDEXRegisterRt,EXMEMRegWrite,EXMEMRegisterRd,MEMWBRegWrite,MEMWBRegisterRd,IDEXMemRd)
	begin
		if(EXMEMRegWrite = '1' and (EXMEMRegisterRd /= "00000") and (EXMEMRegisterRd = IDEXRegisterRs)) then
			ForwardA <= "10";
		elsif((MEMWBRegWrite = '1') and (MEMWBRegisterRd /= "00000") and (MEMWBRegisterRd = IDEXRegisterRs)) then
			ForwardA <= "01";
		else
			ForwardA <= "00";
		end if;

		if((EXMEMRegWrite = '1') and (EXMEMRegisterRd /= "00000") and (EXMEMRegisterRd = IDEXRegisterRt) ) then	
			ForwardB <= "10";
		elsif((MEMWBRegWrite = '1') and (MEMWBRegisterRd /= "00000") and (MEMWBRegisterRd = IDEXRegisterRt)) then
			ForwardB <= "01";
		else
			ForwardB <= "00";
		end if;
	end process;
end behav;	
