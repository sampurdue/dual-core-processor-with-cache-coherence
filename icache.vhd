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

entity icache is
  port(
    clk       : in  std_logic;
    nReset    : in  std_logic;

    iMemRead  : in  std_logic;                       -- CPU side
    iMemWait  : out std_logic;                       -- CPU side
    iMemAddr  : in  std_logic_vector (31 downto 0);  -- CPU side
    iMemData  : out std_logic_vector (31 downto 0);  -- CPU side

    aiMemWait : in  std_logic;                       -- arbitrator side
    aiMemRead : out std_logic;                       -- arbitrator side
    aiMemAddr : out std_logic_vector (31 downto 0);  -- arbitrator side
    aiMemData : in  std_logic_vector (63 downto 0)   -- arbitrator side
    );

end icache;


architecture arch of icache is

component icacheReg
	port(
			dataIn 		:	in std_logic_vector(63 downto 0);
			tagIn		:	in std_logic_vector(24 downto 0);
			blockWrEn	:	in std_logic;
			tagWrEn		:	in std_logic;
			setValid	:	in std_logic;
			index		:	in std_logic_vector(3 downto 0);
			clk		:	in std_logic;
			nReset		:	in std_logic;
			tagOut		:	out std_logic_vector(24 downto 0);
			dataOut		:	out std_logic_vector(63 downto 0);
			validRead	:	out std_logic
		);
end component;

component iCacheCtrl
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
end component;

	constant CACHEIDLE	: std_logic_vector(1 downto 0) :=	"00";
	constant COMPARE	: std_logic_vector(1 downto 0) :=	"01";
	constant CWRITEBACK	:std_logic_vector(1 downto 0) :=	"10";
	constant ALLOCATE	:std_logic_vector(1 downto 0) :=	"11";

	signal cacheTagIn,tagOut1		:	std_logic_vector(24 downto 0);
	signal index					:	std_logic_vector(3 downto 0);
	signal blockOffset				:	std_logic;
	signal hit,valid1				: 	std_logic;
	signal dataOut1,cacheOut			:	std_logic_vector(63 downto 0);
	signal cacheDataWriteEn1,cacheTagWriteEn1 : std_logic;
	signal data2bWritten64	:	std_logic_vector(63 downto 0);
	signal cacheDataWriteEn,cacheTagWriteEn,cacheReady,setValid		:		std_logic;
	signal cacheDataIn :	std_logic_vector(31 downto 0);

begin
	cacheTagIn 	<= iMemAddr(31 downto 7);
	index		<= iMemAddr(6 downto 3);
	blockOffset	<= iMemAddr(2); 

----------------------------------cache controller block --------------------------------------------------------------------------------------------------------------
	icacheController : iCacheCtrl
	port map(	clk		=> clk,
			nReset		=> nReset,
			readReq		=> iMemRead,
			--writeReq	=> cpuWrite,
			hit		=> hit,
			--cacheWriteBack	=> writeBack,
			memWait		=> aiMemWait,
			cacheDataWrite	=> cacheDataWriteEn,
			cacheTagWrite	=> cacheTagWriteEn,
			cacheReady	=> cacheReady,
			--setDirty	=> setDirty,
			setValid	=> setValid,
			--memWrite	=> memWrite,
			memRead		=> aiMemRead);--dcacheReady <= cacheReady

	
	iMemWait <= not cacheReady;
---------------------------------2 way associative cache blocks--------------------------------------------------------------------------------------------------------
	cacheBlock1 : icacheReg
	port map(	dataIn		=> data2bWritten64,
			tagIn		=> cacheTagIn,
			blockWrEn	=> cacheDataWriteEn1,
			tagWrEn		=> cacheTagWriteEn1,
			setValid	=> setValid,
			--dirtyIn		=> setDirty,
			index		=> index,
			clk		=> clk,
			nReset		=> nReset,
			tagOut		=> tagOut1,
			dataOut		=> dataOut1,
			validRead	=> valid1);
			--dirtyRead	=> dirty1);
	
	hit <= '1' when(cacheTagIn = tagOut1 and valid1 = '1') else '0';
	

---------------------------------read cache---------------------------------------------------------------------------------------------------------------------
	cacheOut <= dataOut1 when(hit = '1') else
			--dataOut2 when(hit2 = '1') else
			X"BAABBAABBAABBAAB";
	--tagOut	<= tagOut1 when(hit = '1') else
			--tagOut2 when(hit2 = '1') else
	--		(others=>'0');

	iMemData <= cacheOut(31 downto 0) when(blockOffset = '0') else
				cacheOut(63 downto 32);

-------------------------------readmemory---------------------------------------------
	aiMemAddr <= iMemAddr;
	--cacheToMem <= dataOut1 when(dirty1 = '1' and LRUT(to_integer(unsigned(index))) = "01" and cacheState = CWRITEBACK) else
			--dataOut2 when(dirty2 = '1' and LRUT(to_integer(unsigned(index))) = "10" and cacheState = CWRITEBACK) else
			--X"ABCDABCDABCDABCD";
	--writeBack <= '1' when ((dirty1 = '1' and LRUT(to_integer(unsigned(index))) = "01") or (dirty2 = '1' and LRUT(to_integer(unsigned(index))) = "10")) else '0';

------------------------------------write cache-------------------------------------
	--data2bWritten32 <= cpuToCacheData when (rising_edge(clk)) ;
	data2bWritten64 <= aiMemData;
	cacheDataWriteEn1 <= cacheDataWriteEn;-- when(LRUT(to_integer(unsigned(index))) = "10") else '0';
--	cacheDataWriteEn2 <= cacheDataWriteEn when(LRUT(to_integer(unsigned(index))) = "01") else '0';
	cacheTagWriteEn1 <= cacheTagWriteEn;-- when(LRUT(to_integer(unsigned(index))) = "10") else '0';
--	cacheTagWriteEn2 <= cacheTagWriteEn when(LRUT(to_integer(unsigned(index))) = "01") else '0';
	
end arch;

