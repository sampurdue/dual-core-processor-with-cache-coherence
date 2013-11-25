--cache.vhd
--16 set, 2 way set associative, 2 words per block
--write back, uses a write back buffer
--LRU replacement policy
--block offset = 1
--index bits = 3
--tag bit = 32 - (1+3+2)=26
--frame size = 26+64+1(valid)+1(dirty) = 92

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dcache is
  port(
	clk		:	in std_logic;
	nReset		:	in std_logic;
	linked		:	in std_logic;
	scSuccess	:	out std_logic;

	cpuRead		:	in std_logic;
	cpuWrite	:	in std_logic;
	cpuAddr		:	in std_logic_vector(31 downto 0);
	cpuToCacheData	:	in std_logic_vector(31 downto 0);
	cacheToCpuData	:	out std_logic_vector(31 downto 0);
	dcacheReady	:	out std_logic;	
		
	memRead		:	out std_logic;
	memWrite	:	out std_logic;
	memAddr		:	out std_logic_vector(31 downto 0);
	cacheToMem	:	out std_logic_vector(63 downto 0);
	memToCache	:	in std_logic_vector(63 downto 0);		
	memWait		:	in std_logic	
    );

end dcache;

architecture arch of dcache is

component cacheReg
	port(
			dataIn 		:	in std_logic_vector(63 downto 0);
			tagIn		:	in std_logic_vector(25 downto 0);
			blockWrEn	:	in std_logic;
			tagWrEn		:	in std_logic;
			dirtyIn		: 	in std_logic;
			index		:	in std_logic_vector(2 downto 0);
			clk		:	in std_logic;
			nReset		:	in std_logic;
			tagOut		:	out std_logic_vector(25 downto 0);
			dataOut		:	out std_logic_vector(63 downto 0);
			validRead	:	out std_logic;
			dirtyRead	:	out std_logic	
		);
end component;

component dCacheCtrl
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
end component;

	constant CACHEIDLE	: std_logic_vector(1 downto 0) :=	"00";
	constant COMPARE	: std_logic_vector(1 downto 0) :=	"01";
	constant CWRITEBACK	:std_logic_vector(1 downto 0) :=	"10";
	constant ALLOCATE	:std_logic_vector(1 downto 0) :=	"11";
	signal cacheTagIn,tagOut1,tagOut2,tagOut		:	std_logic_vector(25 downto 0);
	signal index					:	std_logic_vector(2 downto 0);
	signal blockOffset				:	std_logic;
	signal hit1,hit2,hit,dirty1,valid1,dirty2,valid2,dirty,writeBack 				: 	std_logic;
	signal dataOut1,dataOut2,cacheOut,data2bWritten64,data2bWritten			:	std_logic_vector(63 downto 0);
	signal cacheDataWriteEn1,cacheTagWriteEn1,cacheDataWriteEn2,cacheTagWriteEn2 : std_logic;
	type LRUTable is array(0 to 7) of std_logic_vector(1 downto 0);
	signal LRUT : LRUTable ;
	--signal data2bWritten32	:	std_logic_vector(31 downto 0);
	signal cacheDataWriteEn,cacheTagWriteEn,cacheReady,setDirty,setValid 		:		std_logic;
	signal cacheState	:	std_logic_vector(1 downto 0);
	signal linkedReg	:	std_logic_vector(32 downto 0);
	--signal writeBackBuffer	:	std_logic_vector(96 downto 0);

begin
	cacheTagIn 	<= cpuAddr(31 downto 6);
	index		<= cpuAddr(5 downto 3);
	blockOffset	<= cpuAddr(2); 

----------------------------------cache controller block --------------------------------------------------------------------------------------------------------------
	dcacheController : dCacheCtrl
	port map(	clk		=> clk,
			nReset		=> nReset,
			readReq		=> cpuRead,
			writeReq	=> cpuWrite,
			hit		=> hit,
			cacheWriteBack	=> writeBack,
			memWait		=> memWait,
			cacheDataWrite	=> cacheDataWriteEn,
			cacheTagWrite	=> cacheTagWriteEn,
			cacheReady	=> cacheReady,
			setDirty	=> setDirty,
			setValid	=> setValid,
			memWrite	=> memWrite,
			memRead		=> memRead,
			cacheState	=> cacheState	);--dcacheReady <= cacheReady

	
	dcacheReady <= cacheReady;
---------------------------------2 way associative cache blocks--------------------------------------------------------------------------------------------------------
	cacheBlock1 : cacheReg
	port map(	dataIn		=> data2bWritten64,
			tagIn		=> cacheTagIn,
			blockWrEn	=> cacheDataWriteEn1,
			tagWrEn		=> cacheTagWriteEn1,
			dirtyIn		=> setDirty,
			index		=> index,
			clk		=> clk,
			nReset		=> nReset,
			tagOut		=> tagOut1,
			dataOut		=> dataOut1,
			validRead	=> valid1,
			dirtyRead	=> dirty1);
	
	hit1 <= '1' when(cacheTagIn = tagOut1 and valid1 = '1') else '0';
	
	cacheBlock2 : cacheReg
	port map(	dataIn		=> data2bWritten64,
			tagIn		=> cacheTagIn,
			blockWrEn	=> cacheDataWriteEn2,
			tagWrEn		=> cacheTagWriteEn2,
			dirtyIn		=> setDirty,
			index		=> index,
			clk		=> clk,
			nReset		=> nReset,
			tagOut		=> tagOut2,
			dataOut		=> dataOut2,
			validRead	=> valid2,
			dirtyRead	=> dirty2);

	hit2 <= '1' when(cacheTagIn = tagOut2 and valid2 = '1') else '0';

	hit <= hit1 or hit2;
	dirty <= dirty1 or dirty2;

---------------------------------read cache---------------------------------------------------------------------------------------------------------------------
	cacheOut <= dataOut1 when(hit1 = '1') else
			dataOut2 when(hit2 = '1') else
			X"BAABBAABBAABBAAB";
	tagOut	<= tagOut1 when(hit1 = '1') else
			tagOut2 when(hit2 = '1') else
			(others=>'0');

	cacheToCpuData <= cacheOut(31 downto 0) when(blockOffset = '0') else
				cacheOut(63 downto 32);

-------------------------------read/write memory---------------------------------------------
	memAddr <= tagOut1 & index & "000" when((dirty1 = '1') and (LRUT(to_integer(unsigned(index))) = "01") and (cacheState = CWRITEBACK)) else
			tagOut2 & index & "000" when(dirty2 = '1' and LRUT(to_integer(unsigned(index))) = "10" and cacheState = CWRITEBACK) else
			cpuAddr;
	--memAddr <= writeBackBuffer(95 downto 64) when (cacheState = CWRITEBACK)else
			--cpuAddr;
	cacheToMem <= dataOut1 when(dirty1 = '1' and LRUT(to_integer(unsigned(index))) = "01" and cacheState = CWRITEBACK) else
			dataOut2 when(dirty2 = '1' and LRUT(to_integer(unsigned(index))) = "10" and cacheState = CWRITEBACK) else
			X"ABCDABCDABCDABCD";
	--cacheToMem <= writeBackBuffer(63 downto 0);
	writeBack <= '1' when ((dirty1 = '1' and LRUT(to_integer(unsigned(index))) = "01") or (dirty2 = '1' and LRUT(to_integer(unsigned(index))) = "10")) else '0';
------------------modified code for writeback buffer-------------------------------
	--process(clk,dataOut1,dataOut2,dirty1,dirty2,LRUT)
	--begin
--		if(rising_edge(clk) and cacheState = COMPARE) then
--			if(dirty1 = '1' and LRUT(to_integer(unsigned(index))) = "01")then
--				writeBackBuffer <= '1' & tagout1 & index & "000" & dataOut1;
--			elsif(dirty2 = '1' and LRUT(to_integer(unsigned(index))) = "10")then
--				writeBackBuffer <= '1' & tagout2 & index & "000" & dataOut2;
--			else
--				writeBackBuffer <= (others=>'0');
--			end if;
--		end if;
--	end process;
-----------------------------------------------------------------------------------
--------------------------------replacement bits-------------------------------------
	replacement : process(nReset,index,hit1,hit2,clk)
	begin
		if(nReset = '0') then
			for i in 0 to 7 loop
			LRUT(i) <= "01";
			end loop;
		elsif(hit1 = '1' and rising_edge(clk))	then
			LRUT(to_integer(unsigned(index))) <= "10";
		elsif(hit2 = '1' and rising_edge(clk)) then	
			LRUT(to_integer(unsigned(index))) <= "01";
		end if;
	end process;
------------------------------------write cache-------------------------------------
	--data2bWritten32 <= cpuToCacheData when (rising_edge(clk)) ;
	data2bWritten64 <= cpuToCacheData & cacheOut(31 downto 0) when (blockOffset = '1' and hit = '1') else
			cacheOut(63 downto 32) & cpuToCacheData when(blockOffset = '0' and hit = '1') else
			memToCache;
	--process(nReset,clk,data2bWritten64)
	--begin
--		if(nReset = '0')then
--			data2bWritten <= X"0000000000000000";
--		elsif(rising_edge(clk))then
--			data2bWritten <= data2bWritten64;
--		end if;
--	end process;
	cacheDataWriteEn1 <= cacheDataWriteEn when((LRUT(to_integer(unsigned(index))) = "01" and cacheState = ALLOCATE) or (hit1 = '1' and cacheState = COMPARE)) else '0';
	cacheDataWriteEn2 <= cacheDataWriteEn when((LRUT(to_integer(unsigned(index))) = "10" and cacheState = ALLOCATE) or (hit2 = '1' and cacheState = COMPARE)) else '0';
	cacheTagWriteEn1 <= cacheTagWriteEn when((LRUT(to_integer(unsigned(index))) = "01" and cacheState = ALLOCATE)or (hit1 = '1' and cacheState = COMPARE)) else '0';
	cacheTagWriteEn2 <= cacheTagWriteEn when((LRUT(to_integer(unsigned(index))) = "10" and cacheState = ALLOCATE)or (hit2 = '1' and cacheState = COMPARE)) else '0';

----------------------------------LL/SC----------------------------------------------
	process(clk,linked,cpuAddr,cpuRead,cpuWrite,nReset)	
	begin
		if(nReset = '0')then
			linkedReg(32) <= '0';
		elsif(rising_edge(clk) and (cpuRead = '1') and (linked = '1'))then
			linkedReg <= '1' & cpuAddr;
		else
			--do nothing--
		end if;
	end process;
	
	scSuccess <= '0' when((linked = '1') and (cpuWrite = '1') and (linkedReg(31 downto 0) = cpuAddr ) and (linkedReg(32) = '0') ) else '1';

end arch;

