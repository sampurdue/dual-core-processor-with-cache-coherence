--dump.vhd
--it shall dump dcache to memory once halt signal is raised

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cacheDump is
port(
	nReset		:	in std_logic;
	clk		:	in std_logic;
	halt		:	in std_logic;
	memState	:	in std_logic_vector(1 downto 0);
	memRead		:	out std_logic;
	cacheDumpOn	:	out std_logic;
	dumpPCOut	:	out std_logic_vector(31 downto 0);
	final_halt	:	out std_logic
	);
end cacheDump;

architecture arch of cacheDump is

type dumpState is (idle,dump)
signal currState, nextState : dumpState;
signal pc : integer := 16368;
signal pcplus4	: integer := 0;	

begin
	stateChange : process(nReset,nexState)
	begin
	if(nReset = '0') then
		currState <= idle;
	elsif(rising_ege(clk)) then
		currState <= nextState;
	end if;
	end process;

	stateTransactions : process(currState)
	begin
		memRead <= '0';
		cacheDumpOn <= '0';
		finalHalt <= '0';
		pc <= 16368
		case curState is
		
			when idle =>
				memRead <= '0';
				cacheDumpOn <= '0';
				finalHalt <= '0';
				if(halt = '1') then
					nexState <= dump;
				else
					nextState <= idle;
				end if;
				
			when dump =>
				memRead <= '1';
				cacheDumpOn <= '1';
				if(pc = 16399) then
					finalHalt <= '1';
				else
					dumpPCOut <= std_logic_vector(to_unsigned(pc,dumpPCOut'length));
					pcplus4 <= pc + 1;
				end if;
				if(rising_edge(clk)) then
					pc <= pcplus4;
				end if;
					
		end case;			
				
				

	end process;	
end arch;

