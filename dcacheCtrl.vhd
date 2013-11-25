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

entity dCacheCtrl is
	port(
			clk			:	in std_logic;
			nReset		:	in std_logic;
			readReq		:	in std_logic;
			writeReq	:	in std_logic;
			hit 		: 	in std_logic;
			cacheWriteBack	:	in std_logic;
			memWait		:	in std_logic;
			cacheDataWrite : out std_logic;
			cacheTagWrite	:	out std_logic;
			cacheReady	:	out std_logic;
			setDirty	:	out std_logic;
			setValid	:	out std_logic;
			memWrite : out std_logic;
			memRead  : out std_logic;
			cacheState	:	out std_logic_vector(1 downto 0)
		);
end dCacheCtrl;

architecture dcacheCtrlArch of dCacheCtrl is
type state is (compare_st,writeBack_st,allocate_st);
signal currState,nextState : state;
constant CACHEIDLE	: std_logic_vector(1 downto 0) :=	"00";
	constant COMPARE	: std_logic_vector(1 downto 0) :=	"01";
	constant WRITEBACK	:std_logic_vector(1 downto 0) :=	"10";
	constant ALLOCATE	:std_logic_vector(1 downto 0) :=	"11";
begin
	stateChange : process(clk,nReset,nextState)
	begin
		if(nReset = '0') then
			currState 	<= compare_st;
			--prevState	<= idle_s;
		elsif(rising_edge(clk)) then
			--prevState	<= currState;
			currState	<= nextState;
		end if;	
	end process;
	
	stateTransactions : process(currState,memWait,cacheWriteBack,readReq,writeReq,hit)
	begin
		cacheReady <= '1';
		cacheDataWrite <= '0';
		cacheTagWrite <= '0';
		memWrite <= '0';
		memRead <= '0';
		setDirty <= '0';
		setValid <= '0';
		case currState is
		
			--when idle_s	=>
			--	cacheReady <= '1';
			--	cacheDataWrite <= '0';
			--	cacheTagWrite <= '0';
			--	memWrite <= '0';
			--	memRead <= '0';
			---	setDirty <= '0';
			--	setValid <= '0';
			--	cacheState <= CACHEIDLE;
			--	if(readReq = '1' or writeReq = '1') then
			--		nextState <= compare_st;
			--		cacheReady <= '0';
			--	else
			--		nextState <= idle_s;
			--	end if;
		
			when compare_st =>
				cacheState <= COMPARE;
				cacheReady <= '1';
				memWrite <= '0';
				memRead <= '0';
				cacheDataWrite <= '0';
				cacheTagWrite <= '0';
				setDirty <= '0';
				setValid <= '0';
				if(readReq = '1' or writeReq = '1') then
					if(hit = '1' ) then
						cacheReady <= '1'; --read data is out
						--write request
						if(writeReq = '1') then
							cacheDataWrite <= '1';
							cacheTagWrite <= '0';
							setDirty <= '1';
							setValid <= '1';
							nextState <= compare_st;
						end if;
						nextState <= compare_st;
						
					elsif(cacheWriteBack = '1') then
						cacheReady <= '0'; 
						nextState <= writeBack_st;
					else
						cacheReady <= '0'; 
						nextState <= allocate_st;
					end if;	
				else
					nextState <= compare_st;
				end if;		
			
			when writeBack_st =>
				cacheReady <= '0';
				memRead <= '0';
				cacheDataWrite <= '0';
				cacheTagWrite <= '0';
				setDirty <= '0';
				setValid <= '0';
				memWrite <= '1';
				 cacheState <= WRITEBACK;
				if(MemWait = '1')then
					nextState <= writeBack_st;
				else
					nextState <= allocate_st;
				end if;
	
	
		--writeback is not required, delete it
		--	when writeBack_st =>
		--		cacheState <= COMPARE;
		--		cacheReady <= '1';
		--		memWrite <= '0';
		--		memRead <= '0';
		--		cacheDataWrite <= '1';
		--		cacheTagWrite <= '0';
		--		setDirty <= '1';
		--		setValid <= '1';
		--		nextState <= compare_st;						
			
			when allocate_st =>
				cacheReady <= '0';
				memRead <= '1';
				cacheDataWrite <= '0';
				cacheTagWrite <= '0';
				setDirty <= '0';
				setValid <= '0';
				memWrite <= '0';
				if(memWait = '1') then
					nextState <= allocate_st;
				else
					cacheDataWrite <= '1';
					cacheTagWrite <= '1';
					setValid <= '1';
					setDirty <= '0';
					nextState <= compare_st;
				end if;
				
				 cacheState <= ALLOCATE;

			--allocate is no required, delete it	
			--when allocate_st =>
			--	cacheReady <= '0';
			--	memWrite <= '0';
			--	memRead <= '0';
			--	cacheState <= ALLOCATE;
			  ----if(memWait = '1') then 
			   --nextState <= allocate_st;
			  --else 
				--cacheDataWrite <= '1';
				--cacheTagWrite <= '1';
			--	setValid <= '1';
			--	setDirty <= '0';
			--	nextState <= compare_st;
				--end if;
			
					
		end case;		
	end process;
end dCacheCtrlArch;		
