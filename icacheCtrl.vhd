--dCacheCtrl.vhd
--implemented as a 4 state FSM
--16 set, 2 way set associative, 2 words per block
--write back, uses a write back buffer
--LRU replacement policy
--block offset = 1 addr(2)
--index bits = 3 addr(5:3)
--tag bit = 32 - (1+3+2)=26 addr(31:6)
--frame size = 26+64+1(valid)+1(dirty) = 92

library ieee;
use ieee.std_logic_1164.all;

entity iCacheCtrl is
	port(
			clk			:	in std_logic;
			nReset		:	in std_logic;
			readReq		:	in std_logic;
			hit 		: 	in std_logic;
			memWait		:	in std_logic;
			cacheDataWrite 	: 	out std_logic;
			cacheTagWrite	:	out std_logic;
			cacheReady	:	out std_logic;
			setValid	:	out std_logic;
			memRead  : out std_logic;
			cacheState	:	out std_logic_vector(1 downto 0)
		);
end iCacheCtrl;

architecture icacheCtrlArch of iCacheCtrl is
type state is (idle_s, compare_st, writeBack_st,preallocate_st, allocate_st);
signal currState,prevState, nextState : state;

constant CACHEIDLE	: std_logic_vector(1 downto 0) :=	"00";
	constant COMPARE	: std_logic_vector(1 downto 0) :=	"01";
	constant WRITEBACK	:std_logic_vector(1 downto 0) :=	"10";
	constant ALLOCATE	:std_logic_vector(1 downto 0) :=	"11";
begin
	stateChange : process(clk,nReset,nextState)
	begin
		if(nReset = '0') then
			currState 	<= compare_st;
		elsif(rising_edge(clk)) then
			currState	<= nextState;
		end if;	
	end process;
	
	stateTransactions : process(currState,memWait,readReq,hit)
	begin
		cacheDataWrite <= '0';
		cacheTagWrite <= '0';
		cacheReady <= '0';
		memRead <= '0';
		setValid <= '0';
		case currState is
		
			when idle_s	=>
				cacheReady <= '0';
				cacheDataWrite <= '0';
				cacheTagWrite <= '0';
				cacheState <= CACHEIDLE;
				if(readReq = '1') then
					nextState <= compare_st;
				else
					nextState <= idle_s;
				end if;
		
			when compare_st =>
				cacheState <= COMPARE;
				cacheDataWrite <= '0';
				cacheTagWrite <= '0';
				cacheReady <= '0';
				memRead <= '0';
				setValid <= '0';
				if(hit = '1' ) then
					cacheReady <= '1'; --read data is out
					--write request
					nextState <= compare_st;
				else
					cacheReady <= '0';
					nextState <= preallocate_st;
				end if;			
				
			when writeBack_st =>
				
				cacheState <= WRITEBACK;
				cacheDataWrite <= '0';
				cacheTagWrite <= '0';
				cacheReady <= '0';
				memRead <= '0';
				if(MemWait = '1') then
					nextState <= writeBack_st;
				else
					nextState <= preallocate_st;
				end if;	
					
			when preallocate_st =>
				cacheState <= ALLOCATE;
				nextState <= allocate_st;
				 cacheDataWrite <= '0';
				cacheTagWrite <= '0';
				cacheReady <= '0';
				memRead <= '1';
				cacheReady <= '0';
				setValid <= '0';

			when allocate_st =>
				cacheReady <= '0';
				memRead <= '1';
				cacheState <= ALLOCATE;
			  if(memWait = '1') then 
			   nextState <= allocate_st;
			  else 
				cacheDataWrite <= '1';
				cacheTagWrite <= '1';
				setValid <= '1';
				nextState <= compare_st;
				end if;
				
		end case;		
	end process;
end icacheCtrlArch;		
