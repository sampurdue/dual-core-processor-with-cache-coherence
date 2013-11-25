--hazardDetection.vhd

library ieee;
use ieee.std_logic_1164.all;

entity hazardDetection is
	port(
			IDEXMemRead	:	in std_logic;
			IDEXRegWrite	:	in std_logic;
			IDEXRegisterRd	:	in std_logic_vector(4 downto 0);
			IFIDRegisterRs	:	in std_logic_vector(4 downto 0);
			IFIDRegisterRt	:	in std_logic_vector(4 downto 0);
			STALL			:	out std_logic
		);
end hazardDetection;

architecture behav of hazardDetection is
begin
	process(IDEXMemRead,IDEXRegWrite,IDEXRegisterRd,IFIDRegisterRs,IFIDRegisterRt)
	begin
		if(IDEXMemRead = '1' and IDEXRegisterRd /= "00000") then
			if(IDEXRegisterRd = IFIDRegisterRs) then
				STALL <= '1';
			elsif(IDEXRegisterRd = IFIDRegisterRt) then
				STALL <= '1';
			else
				STALL <= '0';
			end if;
		else
			STALL <= '0';
		end if;	
	end process;
end behav;	


