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
	cacheReady	:	in std_logic;
	cacheDumpOn	:	out std_logic;
	dumpPCOut	:	out std_logic_vector(31 downto 0);
	finalHalt	:	out std_logic
	);
end cacheDump;

architecture arch of cacheDump is

type dumpState is (idle,dump,dumped);
signal currState, nextState : dumpState;
signal pc : integer := 12032;
signal pcplus4	: integer := 12032;	

begin
	dumpPCOut <= std_logic_vector(to_unsigned(pc,32));
	stateChange : process(nReset,nextState,clk)
	begin
	if(nReset = '0') then
		currState <= idle;
	elsif(rising_edge(clk)) then
		currState <= nextState;
	end if;
	end process;

	stateTransactions : process(currState,halt,pc,cacheReady,clk)
	begin
		cacheDumpOn <= '0';
		finalHalt <= '0';
		case currState is
		
			when idle =>
				cacheDumpOn <= '0';
				finalHalt <= '0';
				if(halt = '1') then
					nextState <= dump;
				else
					nextState <= idle;
				end if;
				
			when dump =>
				cacheDumpOn <= '1';
				if(pc = 12160) then
					finalHalt <= '1';
					nextState <= dumped;
				else
					nextState <= dump;
				end if;
				if(cacheReady = '1' and falling_edge(clk))then
					pcplus4 <= pc +4;
				end if;

			when dumped =>
				cacheDumpOn <= '0';
				finalHalt <= '1';
				nextState <= dumped;

		end case;		
	end process;	
	
	pcupdate : process(pcplus4,clk,nReset,currState)
	begin
		if(nReset = '0') then
			pc <= 16128;
		elsif(rising_edge(clk) and (currState = dump))then
			pc <= pcplus4;
		end if;
	end process;
end arch;

