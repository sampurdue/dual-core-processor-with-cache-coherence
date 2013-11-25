--mycpu.vhd
--dual core


library ieee;
use ieee.std_logic_1164.all;

entity mycpu is
	port ( 
		CLK				:	in	std_logic;
		nReset				:	in	std_logic;
		halt				:	out	std_logic;
		ramAddr				:	out	std_logic_vector(15 downto 0);
		ramData				:	out	std_logic_vector(63 downto 0);
		ramWen				:	out	std_logic;
		ramRen				:	out	std_logic;
		ramQ				:	in	std_logic_vector(63 downto 0);
		ramState			:	in	std_logic_vector(1 downto 0)
	);
end mycpu;

architecture arch of mycpu is


component arbiter
	port (
		CLK		:	in	std_logic;
		nReset		:	in	std_logic;
		ramState	:		in std_logic_vector(1 downto 0);
		icacheReq	:	in std_logic;
		dcacheReq		:		in std_logic;
		instr_out	:		out std_logic;
		data_out	:		out std_logic
	);
end component;

component core
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
end component;

---------------------------------Signal declarations ----------------------------
---------------------------------constants---------------------------------------
constant MEMFREE        : std_logic_vector              := "00";
constant MEMBUSY        : std_logic_vector              := "01";
constant MEMACCESS      : std_logic_vector              := "10";
constant MEMERROR       : std_logic_vector              := "11";

---------------------------------core 0 -----------------------------------------
signal 	PCSelect,iMemRead0,iMemWait0,cpuRead0,cpuWrite0,dcacheReady0	:	std_logic;
signal 	loadLinked0,lockSuccess0,halt0					:	std_logic;
signal	iMemAddr0,cpuAddr0, cpuMemAddr0					:	std_logic_vector(31 downto 0);
signal	iMemData0, cpuToCacheData0,cacheToCpuData0			:	std_logic_vector(31 downto 0);	

--------------------------------dcache & icache----------------------------------
signal cpuReadReq0, cpuWriteReq0, memWait0						:	std_logic;
signal memToCache0							:	std_logic_vector(63 downto 0);
signal icacheReq0, dCacheReq0						:	std_logic;

-----------------------------------arbiter---------------------------------------
signal icacheReq, dcacheReq, instr_out, data_out			:	std_logic;
signal aiMemData0, cacheToMem0						:	std_logic_vector(63 downto 0);
signal memAddr0, aiMemAddr0						:	std_logic_vector(31 downto 0);
signal aiMemRead0,aiMemWait0, memRead0, memWrite0			:	std_logic; 

---------------------------------------------------------------------------------

begin

--------------------------------arbiter-------------------------------------------------
	memArbiter : arbiter
	port map(
			CLK		=>	CLK,
			nReset		=>	nReset,
			ramState	=>	ramState,
			icacheReq	=>	aiMemRead0,
			dcacheReq	=>	dcacheReq0,
			instr_out	=>	instr_out,
			data_out	=>	data_out
		);

-----------------------------arbitration logic--------------------------------------------

	aiMemWait0 <= '0' when (instr_out = '1' and ramState = MEMACCESS)  else '1';
	ramRen <= '1' when ((aiMemRead0 = '1' and instr_out = '1') or (memRead0 = '1' and instr_out = '0')) else '0';
	ramWen <= '1' when (memWrite0 = '1' and data_out = '1') else '0';
	process(data_out,instr_out,memAddr0,aiMemAddr0)
	begin
		if(data_out = '1') then
			ramAddr <= memAddr0(15 downto 0);
		elsif(instr_out = '1')then
			ramAddr <= aiMemAddr0(15 downto 0);
		else
			ramAddr <= X"00AB";
		end if;
	end process;
	process(nReset,data_out,ramState,ramQ,instr_out,cacheToMem0)
	begin
		if(nReset = '0')then
			memToCache0 <= X"ABCDABCDABCDABCD";
		elsif((data_out = '1') or (ramState = MEMACCESS))then
			memToCache0 <= ramQ;
		else
			memToCache0 <= X"ABCDABCDABCDABCD";
		end if;
		if(nReset = '0')then
			aiMemData0 <= X"ABCDABCDABCDABCD";
		else
			aiMemData0 <= ramQ;
		end if;
		if(nReset = '0')then
			ramData <= X"ABCDABCDABCDABCD";
		else
			ramData <= cacheToMem0;
		end if;
	end process;
	memWait0 <= '0' when (data_out = '1' and ramState = MEMACCESS)else '1';
	dcacheReq0 <= memRead0 or memWrite0;

-------------------------------------------core0-------------------------------
	core0 : core
	port map(
			CLK		=>	CLK,
			nReset		=>	nReset,
			PCSelect	=>	'0',
			halt		=>	halt,
	
			aiMemWait 	=>	aiMemWait0,
	    		aiMemRead 	=>	aiMemRead0,
	    		aiMemAddr 	=>	aiMemAddr0,
	    		aiMemData 	=>	aiMemData0,

			cdMemRead	=>	memRead0,
			cdMemWrite	=>	memWrite0,
			cdMemAddr	=>	memAddr0,
			cacheToMem	=>	cacheToMem0,
			memToCache	=>	memToCache0,
			cdMemWait	=>	memWait0	
	);
	
end arch;






















