--core.vhd
--comprises dcache icache 
--and a pipeline


library ieee;
use ieee.std_logic_1164.all;


entity core is
	port(
		CLK		:	in	std_logic;
		nReset		:	in	std_logic;
		PCSelect	:	in 	std_logic;
		halt		:	out	std_logic;
	
		aiMemWait 	: 	in  std_logic;                       -- arbitrator side
    		aiMemRead 	: 	out std_logic;                       -- arbitrator side
    		aiMemAddr 	: 	out std_logic_vector (31 downto 0);  -- arbitrator side
    		aiMemData 	: 	in  std_logic_vector (63 downto 0) ;  -- arbitrator side

		cdMemRead	:	out std_logic;
		cdMemWrite	:	out std_logic;
		cdMemAddr	:	out std_logic_vector(31 downto 0);
		cacheToMem	:	out std_logic_vector(63 downto 0);
		memToCache	:	in std_logic_vector(63 downto 0);		
		cdMemWait	:	in std_logic	
	);
end core;

architecture arch of core is 

component pipeline
	port ( 
		CLK				:	in	std_logic;
		nReset				:	in	std_logic;
		halt				:	out	std_logic;
		PCSelect			:	in	std_logic;
		
		iMemRead  			: 	out  	std_logic;                       -- CPU side
		iMemWait  			: 	in 	std_logic;                       -- CPU side
		iMemAddr  			: 	out  	std_logic_vector (31 downto 0);  -- CPU side
		iMemData  			: 	in 	std_logic_vector (31 downto 0);  -- CPU side

		cpuRead				:	out 	std_logic;				--dcache CPU side 
		cpuWrite			:	out 	std_logic;				--dcache CPU side 
		cpuAddr				:	out 	std_logic_vector(31 downto 0);		--dcache CPU side 
		cpuToCacheData			:	out 	std_logic_vector(31 downto 0);		--dcache CPU side 
		cacheToCpuData			:	in 	std_logic_vector(31 downto 0);		--dcache CPU side 
		dcacheReady			:	in 	std_logic;				--dcache CPU side 
		loadLinked			:	out 	std_logic;				--dcache CPU side
		lockSuccess			:	in	std_logic				--dcache CPU side
	);
end component;

component icache
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

end component;

component dcache
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
end component;

component cacheDump
	port(
		nReset		:	in std_logic;
		clk		:	in std_logic;
		halt		:	in std_logic;
		cacheReady	:	in std_logic;
		cacheDumpOn	:	out std_logic;
		dumpPCOut	:	out std_logic_vector(31 downto 0);
		finalHalt	:	out std_logic
		);
end component;
------------------------------signal declarations -----------------------
------------------------------pipeline----------------------------------
signal	iMemRead,iMemWait,cpuRead,cpuWrite,dCacheReady,loadLinked,lockSuccess		:	std_logic;
signal 	haltPipeline									:	std_logic;
signal	iMemAddr,iMemData,cpuMemAddr,cacheToCpuData,cpuToCacheData			:	std_logic_vector(31 downto 0);

-----------------------------icache, dcache and cacheDump---------------
signal	cpuReadReq,cpuWriteReq,memWait,cacheDumpOn					:	std_logic;
signal	cpuAddr,dumpPC									:	std_logic_vector(31 downto 0);


begin

----------------------------pipeline----------------------------------------
	myPipeline : pipeline
	port map(
			CLK			=>	CLK,
			nReset			=>	nReset,
			halt			=>	haltPipeline,
			PCSelect		=>	PCSelect,
		
			iMemRead  		=>	iMemRead,
			iMemWait  		=>	iMemWait,
			iMemAddr  		=>	iMemAddr,
			iMemData  		=>	iMemData,

			cpuRead			=>	cpuRead,
			cpuWrite		=>	cpuWrite,
			cpuAddr			=>	cpuMemAddr,
			cpuToCacheData		=>	cpuToCacheData,
			cacheToCpuData		=>	cacheToCpuData,
			dcacheReady		=>	dCacheReady,
			loadLinked		=>	loadLinked,
			lockSuccess		=>	lockSuccess
		);

-------------------------icache-----------------------------------------
	instrCache : icache 
	port map(
			clk       =>	CLK,
			nReset    =>	nReset,

			iMemRead  =>	iMemRead,
			iMemWait  =>	iMemWait,
			iMemAddr  =>	iMemAddr,
			iMemData  =>	iMemData,

			aiMemWait =>	aiMemWait,
			aiMemRead =>	aiMemRead,
			aiMemAddr =>	aiMemAddr,
			aiMemData =>	aiMemData
		);

------------------------dCache------------------------------------------
	dataCache : dcache
	port map(
			clk		=>	CLK,
			nReset		=>	nReset,
			linked		=>	loadLinked,
			scSuccess	=>	lockSuccess,

			cpuRead		=>	cpuReadReq,
			cpuWrite	=>	cpuWriteReq,
			cpuAddr		=>	cpuAddr,
			cpuToCacheData	=>	cpuToCacheData,
			cacheToCpuData	=>	cacheToCpuData,
			dcacheReady	=>	dCacheReady,

			memRead		=>	cdMemRead,
			memWrite	=>	cdMemWrite,
			memAddr		=>	cdMemAddr,
			cacheToMem	=>	cacheToMem,
			memToCache	=>	memToCache,
			memWait		=>	cdMemWait
		);

--------------------------cache dump----------------------------------------------------
	cacheDumper : cacheDump
	port map (nReset,CLK,haltPipeline,dCacheReady,cacheDumpOn,dumpPC,halt);
	
	cpuAddr 	<= cpuMemAddr when(cacheDumpOn = '0') else dumpPC;
	cpuReadReq	<= cpuRead when (cacheDumpOn = '0') else '1';
	cpuWriteReq	<= cpuWrite when (cacheDumpOn = '0') else '0';

end arch;
