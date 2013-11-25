library ieee;
--library icache_gold;
--use icache_gold.icache;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.NUMERIC_STD.all;

entity pipeline is
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
end pipeline;

architecture behavioral of pipeline is

	constant zero_32	:	std_logic_vector	:= x"00000000";
	constant one_32	:	std_logic_vector	:= X"00000001";
	constant zero_1		:	std_logic		:= '0';
	constant four		:	std_logic_vector	:= x"00000004";
	constant two		:	std_logic_vector	:= "00010";
	constant one		:	std_logic		:= '1';
	constant Ra		:	std_logic_vector	:= "11111";	-- R[31]

        constant MEMFREE        : std_logic_vector              := "00";
        constant MEMBUSY        : std_logic_vector              := "01";
        constant MEMACCESS      : std_logic_vector              := "10";
        constant MEMERROR       : std_logic_vector              := "11";

	
	signal PCplus4		:	std_logic_vector (31 downto 0);
	signal busW		:	std_logic_vector (31 downto 0);
	signal busA		:	std_logic_vector (31 downto 0);
	signal jumpImmExSll	:	std_logic_vector (31 downto 0);
	
	signal PCwe		:	std_logic;
	signal halt_s		:	std_logic;
	signal instr_out	:	std_logic;
	signal data_out		:	std_logic;
	signal stall		:	std_logic;
	signal stall_pc		:	std_logic;
	signal if_id_wren	:	std_logic;
	signal id_ex_wren	:	std_logic;
	signal ex_mem_wren	:	std_logic;
	signal mem_wb_wren	:	std_logic;

-- IF Stage
	signal if_PCOut		:	std_logic_vector (31 downto 0)	:= x"00000000";
	signal if_PCSrcMuxOut	:	std_logic_vector (31 downto 0);
	signal if_jumpImmAddr	:	std_logic_vector (31 downto 0);
	signal if_jumpAddr	:	std_logic_vector (31 downto 0);
	signal if_PCIn		:	std_logic_vector (31 downto 0);
	signal flush		:	std_logic;
	signal latchCheck	:	std_logic_vector(31 downto 0);	
	signal instrfetch	:	std_logic;

	signal aiMemWait	:	std_logic;
	signal aiMemRead	:	std_logic;
	signal	aiMemAddr	:	std_logic_vector(31 downto 0);
	signal aiMemData	:	std_logic_vector(63 downto 0) := X"ABCDABCDABCDABCD";

	signal if_instr		:	std_logic_vector (31 downto 0);
	signal ifid_in		:	std_logic_vector (63 downto 0);
-----------

-- ID Stage

	signal ifid_out		:	std_logic_vector (63 downto 0);
	signal id_instr		:	std_logic_vector (31 downto 0);
	-- control signals
	signal RegWr		:	std_logic;
	signal RegDst		:	std_logic;
	signal ExtOp		:	std_logic_vector (1 downto 0);
	signal AluSrc		:	std_logic;
	signal AluOp		:	std_logic_vector (3 downto 0);
	signal MemWr		:	std_logic;
	signal MemRd		:	std_logic;
	signal MemtoReg		:	std_logic;
	signal Jump		:	std_logic;
	signal BusWSel		:	std_logic;
	signal ShamtSel		:	std_logic;
	signal JumpSel		:	std_logic;
	signal JalSel		:	std_logic;
	signal linked		:	std_logic;
	signal stCondnal	:	std_logic;
	------------------

	signal id_Rs		:	std_logic_vector (4 downto 0);
	signal id_Rt		:	std_logic_vector (4 downto 0);
	signal id_busB		:	std_logic_vector (31 downto 0);
	signal id_imm16		:	std_logic_vector (15 downto 0);
	signal id_extOut	:	std_logic_vector (31 downto 0);
	signal id_pcplus4	:	std_logic_vector (31 downto 0);
	signal idex_nop		:	std_logic;

	signal idex_in		:	std_logic_vector (177 downto 0);
-----------

-- EX Stage
	signal idex_out		:	std_logic_vector (177 downto 0);

	signal aluOperand1	:	std_logic_vector(31 downto 0);
	signal aluOperand2	: 	std_logic_vector(31 downto 0);
	signal ex_halt_s	:	std_logic;
	signal ex_Jump		:	std_logic;
	signal ex_JumpSel	:	std_logic;
	signal ex_RegWr		:	std_logic;
	signal ex_RegDst	:	std_logic;
	signal ex_BusWSel	:	std_logic;
	signal ex_MemtoReg	:	std_logic;
	signal ex_JalSel	:	std_logic;
	signal ex_MemWr		:	std_logic;
	signal ex_MemRd		:	std_logic;
	signal ex_ALUOp		:	std_logic_vector (3 downto 0);
	signal ex_ALUSrc	:	std_logic;
	signal ex_ShamtSel	:	std_logic;
	signal ex_instr		:	std_logic_vector (31 downto 0);
	signal ex_busA		:	std_logic_vector (31 downto 0);
	signal ex_busB		:	std_logic_vector (31 downto 0);
	signal ex_extOut	:	std_logic_vector (31 downto 0);
	signal ex_aluSrcMuxOut	:	std_logic_vector (31 downto 0);
	signal ex_shamt		:	std_logic_vector (31 downto 0);
	signal ex_aluIn2	:	std_logic_vector (31 downto 0);
	signal ex_aluout	:	std_logic_vector (31 downto 0);
	signal ex_negative	:	std_logic;
	signal ex_overflow	:	std_logic;
	signal ex_zero		:	std_logic;
	signal ex_Equal		:	std_logic;
	signal ex_sll2branch_out:	std_logic_vector (31 downto 0);
	signal ex_jumpImmEx	:	std_logic_vector (31 downto 0);
	signal ex_Rd		:	std_logic_vector (4 downto 0);
	signal ex_Rs		:	std_logic_vector (4 downto 0);
	signal ex_Rt		:	std_logic_vector (4 downto 0);
	signal ex_destRegMuxOut	:	std_logic_vector (4 downto 0);
	signal ex_wsel		:	std_logic_vector (4 downto 0);
	signal ex_pcplus4	:	std_logic_vector (31 downto 0);
	signal ForwardA		:	std_logic_vector(1 downto 0);
	signal ForwardB		: 	std_logic_vector(1 downto 0);
	signal hazardStall	: 	std_logic;
	signal memReq		:	std_logic;
	signal ex_PC4Imm16		:	std_logic_vector (31 downto 0);
	signal ex_PCSrc		:	std_logic;
	signal ex_linked	:	std_logic;
	signal ex_stCondnal	:	std_logic;


	signal exmem_in		:	std_logic_vector (174 downto 0);
-----------

-- MEM Stage
	signal exmem_out	:	std_logic_vector (174 downto 0);

	signal mem_halt_s	:	std_logic;
	signal mem_RegWr	:	std_logic;
	signal mem_BusWSel	:	std_logic;
	signal mem_MemtoReg	:	std_logic;
	signal mem_JalSel	:	std_logic;
	signal mem_MemWr	:	std_logic;
	signal mem_MemRd	:	std_logic;
	signal mem_linked	:	std_logic;
	signal mem_stCondnal	:	std_logic;
	signal mem_wsel		:	std_logic_vector (4 downto 0);
	signal mem_aluout	:	std_logic_vector (31 downto 0);
	signal mem_extOut	:	std_logic_vector (31 downto 0);
	signal mem_busB		:	std_logic_vector (31 downto 0);
	signal mem_memOut	:	std_logic_vector (31 downto 0);
	signal mem_pcplus4	:	std_logic_vector (31 downto 0);
	signal mem_PC4Imm16		:	std_logic_vector (31 downto 0);
	signal mem_PCSrc		:	std_logic;
	signal dCacheMemRead		:	std_logic;
	signal dCacheMemWrite		:	std_logic;
	signal dCacheMemAddr		:	std_logic_vector(31 downto 0);
	signal cpuReadReq		:	std_logic;
	signal cpuWriteReq		:	std_logic;
	signal dcacheReq		:	std_logic;
	signal dCacheToMemData		:	std_logic_vector(63 downto 0);
	signal memToCacheData		:	std_logic_vector(63 downto 0) := X"ABCDABCDABCDABCD";
	signal mem_scRes	:	std_logic_vector(31 downto 0);

	signal memwb_in		:	std_logic_vector (170 downto 0);
-----------

-- WB Stage
	signal memwb_out	:	std_logic_vector (170 downto 0);

	signal wb_regWrMuxIntmdt	:	std_logic_vector(31 downto 0);
	signal wb_scRes		:	std_logic_vector(31 downto 0);
	signal wb_stCondnal	:	std_logic;
	signal wb_halt_s	:	std_logic;
	signal wb_RegWr		:	std_logic;
	signal wb_BusWSel	:	std_logic;
	signal wb_MemtoReg	:	std_logic;
	signal wb_JalSel	:	std_logic;
	signal wb_aluout	:	std_logic_vector (31 downto 0);
	signal wb_extOut	:	std_logic_vector (31 downto 0);
	signal wb_memOut	:	std_logic_vector (31 downto 0);
	signal wb_regWrMuxOut	:	std_logic_vector (31 downto 0);
	signal wb_busWSelMuxOut	:	std_logic_vector (31 downto 0);
	signal wb_wsel		:	std_logic_vector (4 downto 0);
	signal wb_pcplus4	:	std_logic_vector (31 downto 0);
	signal cacheDumpOn	:	std_logic;
-----------
--Dumper
	signal cacheDumpMemRead		:	std_logic;	
	signal dumpPC			:	std_logic_vector(31 downto 0);
	signal cpuMemAddr			:	std_logic_vector(31 downto 0);

	signal ignore_1		:	std_logic;
	signal ignore_2		:	std_logic;

	type state_type is (state_0, state_1);
	signal state, next_state	:	state_type;
	signal memwait		:	std_logic	:= '0';
	signal intrpt		:	std_logic	:= '0';

	component controller
		port (	instr		:	in	std_logic_vector (31 downto 0);
			RegWr		:	out	std_logic;
			RegDst		:	out	std_logic;
			ExtOp		:	out	std_logic_vector (1 downto 0);
			ALUSrc		:	out	std_logic;
			ALUOp		:	out	std_logic_vector (3 downto 0);
			MemWr		:	out	std_logic;
			MemRd		:	out	std_logic;
			MemtoReg	:	out	std_logic;
			Jump		:	out	std_logic;
			BusWSel		:	out	std_logic;
			ShamtSel	:	out	std_logic;
			JumpSel		:	out	std_logic;
			JalSel		:	out	std_logic;
			linked		:	out	std_logic;
			stCondnal	:	out 	std_logic;
			halt		:	out	std_logic
		);
	end component;

	component PCSrc_control
		port (	opcode		:	in	std_logic_vector (5 downto 0);
			equal		:	in	std_logic;
			PCSrc		:	out	std_logic
		);
	end component;

	component registerFile
		port (	wdat		:	in	std_logic_vector (31 downto 0);
			wsel		:	in	std_logic_vector (4 downto 0);
			wen		:	in	std_logic;
			clk		:	in	std_logic;
			nReset		:	in	std_logic;
			rsel1		:	in	std_logic_vector (4 downto 0);
			rsel2		:	in	std_logic_vector (4 downto 0);
			rdat1		:	out	std_logic_vector (31 downto 0);
			rdat2		:	out	std_logic_vector (31 downto 0)
		);
	end component;

	component alu
		port (	opcode		:	in	std_logic_vector (3 downto 0);
			A		:	in	std_logic_vector (31 downto 0);
			B		:	in	std_logic_vector (31 downto 0);
			aluout		:	out	std_logic_vector (31 downto 0);
			negative	:	out	std_logic;
			overflow	:	out	std_logic;
			zero		:	out	std_logic;
			equal		:	out	std_logic
		);
	end component;

	component Mux_2_1_32bit
		port (	sel		:	in	std_logic;
			A		:	in	std_logic_vector (31 downto 0);
			B		:	in	std_logic_vector (31 downto 0);
			muxout		:	out	std_logic_vector (31 downto 0)
		);
	end component;

	component Mux_2_1_5bit
		port (	sel		:	in	std_logic;
			A		:	in	std_logic_vector (4 downto 0);
			B		:	in	std_logic_vector (4 downto 0);
			muxout		:	out	std_logic_vector (4 downto 0)
		);
	end component;

	component Extender
		port (	ExtOp		:	in	std_logic_vector (1 downto 0);
			input		:	in	std_logic_vector (15 downto 0);
			ExtOut		:	out	std_logic_vector (31 downto 0)
		);
	end component;

	component fulladder32bit
		port (	A32		:	in	std_logic_vector(31 downto 0);
			B32		:	in	std_logic_vector(31 downto 0);
			Cin32		:	in	std_logic;
			S32		:	out	std_logic_vector(31 downto 0);
			Cout32		:	out	std_logic
		);
	end component;

	component SLL32Bit
		port (	A		:	in	std_logic_vector (31 downto 0);
			B		:	in	std_logic_vector (4 downto 0);
			Y		:	out	std_logic_vector (31 downto 0)
		);
	end component;

	component IF_ID_Register
		port (	clk	:	in	std_logic;
			nReset	:	in	std_logic;
			flush	:	in	std_logic;
			wren	:	in	std_logic;
			data	:	in	std_logic_vector (63 downto 0);
			q	:	out	std_logic_vector (63 downto 0)
		);
	end component;

	component ID_EX_Register
		port (	clk	:	in	std_logic;
			nReset	:	in	std_logic;
			wren	:	in	std_logic;
			data	:	in	std_logic_vector (177 downto 0);
			q	:	out	std_logic_vector (177 downto 0)
		);
	end component;

	component EX_MEM_Register
		port (	clk	:	in	std_logic;
			nReset	:	in	std_logic;
			wren	:	in	std_logic;
			data	:	in	std_logic_vector (174 downto 0);
			q	:	out	std_logic_vector (174 downto 0)
		);
	end component;

	component MEM_WB_Register
		port (	clk	:	in	std_logic;
			nReset	:	in	std_logic;
			wren	:	in	std_logic;
			data	:	in	std_logic_vector (170 downto 0);
			q	:	out	std_logic_vector (170 downto 0)
		);
	end component;
	
	component forwardingUnit 
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
	end component;

	component hazardDetection
	port(
			IDEXMemRead	:	in std_logic;
			IDEXRegWrite	:	in std_logic;
			IDEXRegisterRd	:	in std_logic_vector(4 downto 0);
			IFIDRegisterRs	:	in std_logic_vector(4 downto 0);
			IFIDRegisterRt	:	in std_logic_vector(4 downto 0);
			STALL		:	out std_logic
		);
	end component;


begin


--------------------------------------------------------------------------------------------------------------------------
--			Instruction and data fetch from cache
--------------------------------------------------------------------------------------------------------------------------

	iMemRead <= '0' when(nReset = '0' or halt_s = '1') else '1';
	
	if_instr <= iMemData when (iMemWait = '0') else zero_32;
	stall_pc <= '1' when (iMemWait = '1' or nReset = '0' or halt_s = '1') or (dCacheReady = '0' and data_out = '1') else '0';
	iMemAddr <= if_PCOut;


-- IF: Instruction Fetch Stage
------------------------------

	PCplusFour: fulladder32bit port map (A32	=> if_PCOut,
					     B32	=> four,
					     Cin32	=> zero_1,
					     S32	=> PCplus4,
					     Cout32	=> ignore_1);

	JumpMux: Mux_2_1_32bit port map (sel		=> ex_Jump,--mem_PCSrc,
					  A		=> PCplus4,
					  B		=> if_jumpAddr,--mem_PC4Imm16,
					  muxout	=> if_PCSrcMuxOut);

	if_jumpImmAddr <= ex_pcplus4(31 downto 28) & jumpImmExSll(27 downto 0);
	JumpSelMux: Mux_2_1_32bit port map (sel		=> ex_JumpSel,
					    A		=> ex_busA,
					    B		=> if_jumpImmAddr,
					    muxout	=> if_jumpAddr);
	
	PCSrcMux: Mux_2_1_32bit port map (sel	=> mem_PCSrc,--ex_Jump,
					 A	=> if_PCSrcMuxOut,
					 B	=> mem_PC4Imm16,--if_jumpAddr,
					 muxout	=> if_PCIn);

	ifid_in <= PCplus4 & if_instr;
	
	flush <= mem_PCSrc or ex_Jump or ex_JumpSel;
	if_id_wren <= not (stall or hazardStall or halt_s);
	IF_ID_Latch: IF_ID_Register port map (clk	=> CLK,
					      nReset	=> nReset,
						flush	=> flush,
					      wren	=> if_id_wren,
					      data	=> ifid_in,
					      q		=> ifid_out);
	

-- ID: Instruction Decode Stage
-------------------------------

	id_pcplus4 <= ifid_out(63 downto 32);
	id_instr <= ifid_out(31 downto 0);

	myController: controller port map (	instr		=> id_instr,
						RegWr		=> RegWr,
						RegDst		=> RegDst,
						ExtOp		=> ExtOp,
						AluSrc		=> AluSrc,
						AluOp		=> AluOp,
						MemWr		=> MemWr,
						MemRd		=> MemRd,
						MemtoReg	=> MemtoReg,
						Jump		=> Jump,
						BusWSel		=> BusWSel,
						ShamtSel	=> ShamtSel,
						JumpSel		=> JumpSel,
						JalSel		=> JalSel,
						linked		=> linked,
						stCondnal	=> stCondnal,
						halt		=> halt_s);

	id_Rs <= id_instr(25 downto 21);
	id_Rt <= id_instr(20 downto 16);

	RegFile: registerFile port map (wdat	=> busW,
					wsel	=> wb_wsel,
					wen	=> wb_RegWr,
					clk	=> CLK,
					nReset	=> nReset,
					rsel1	=> id_Rs,
					rsel2	=> id_Rt,
					rdat1	=> busA,
					rdat2	=> id_busB);

	id_imm16 <= id_instr(15 downto 0);
	myExtender: Extender port map (ExtOp	=> ExtOp,
				       input	=> id_imm16,
				       ExtOut	=> id_extOut);
	idex_nop <= hazardStall or mem_PCSrc or ex_Jump or ex_JumpSel;
	with idex_nop select
	idex_in	<= 	stCondnal & linked & halt_s & id_pcplus4 & "000000000000000" & id_instr & busA & id_busB & id_extOut when '1', 
			stCondnal & linked & halt_s & id_pcplus4 & Jump & JumpSel & RegWr & RegDst & BusWSel & MemtoReg & JalSel & MemWr & MemRd & ALUOp & ALUSrc & ShamtSel & id_instr & busA & id_busB & id_extOut when others;
		

	id_ex_wren <= not stall;
	ID_EX_Latch: ID_EX_Register port map (clk	=> CLK,
					      nReset	=> nReset,
					      wren	=> id_ex_wren,
					      data	=> idex_in,
					      q		=> idex_out);

	hazardDetector : hazardDetection port map (IDEXMemRead => ex_MemRd,
						   IDEXRegWrite => ex_RegWr,
						   IDEXRegisterRd => ex_wsel,
						   IFIDRegisterRs => id_Rs,
						   IFIDRegisterRt => id_Rt,
						   STALL => hazardStall);


-- EX: Execute State
--------------------

	ex_stCondnal	<= idex_out(177);
	ex_linked	<= idex_out(176);
	ex_halt_s	<= idex_out(175);
	ex_pcplus4	<= idex_out(174 downto 143);
	ex_Jump		<= idex_out(142);
	ex_JumpSel	<= idex_out(141);
	ex_RegWr	<= idex_out(140);
	ex_RegDst	<= idex_out(139);
	ex_BusWSel	<= idex_out(138);
	ex_MemtoReg	<= idex_out(137);
	ex_JalSel	<= idex_out(136);
	ex_MemWr	<= idex_out(135);
	ex_MemRd	<= idex_out(134);
	ex_ALUSrc	<= idex_out(129);
	ex_ShamtSel	<= idex_out(128);
	
	ex_ALUOp	<= idex_out(133 downto 130);
	
	ex_instr	<= idex_out(127 downto 96);
	ex_busA		<= idex_out(95 downto 64);
	ex_busB		<= idex_out(63 downto 32);
	ex_extOut	<= idex_out(31 downto 0);

	AluSrcMux: Mux_2_1_32bit port map (sel		=> ex_AluSrc,
					   A		=> ex_aluIn2,
					   B		=> ex_extOut,
					   muxout	=> ex_aluSrcMuxOut);

	ex_shamt <= x"000000" & "000" & ex_instr(10 downto 6);
	ShamtMux: Mux_2_1_32bit port map (sel		=> ex_ShamtSel,
					  A		=> ex_aluSrcMuxOut,
					  B		=> ex_shamt,
					  muxout	=> aluOperand2);

	myALU: alu port map (opcode	=> ex_AluOp,
			     A		=> aluOperand1,
			     B		=> aluOperand2,
			     aluout	=> ex_aluout,
			     negative	=> ex_negative,
			     overflow	=> ex_overflow,
			     zero	=> ex_zero,
			     equal	=> ex_Equal);

	SLL2Branch: SLL32bit port map (A	=> ex_extOut,
				       B	=> two,
				       Y	=> ex_sll2branch_out);

	PCFourImm16: fulladder32bit port map (A32	=> ex_pcplus4,
					      B32	=> ex_sll2branch_out,
					      Cin32	=> zero_1,
					      S32	=> ex_PC4Imm16,
					      Cout32	=> ignore_2);

	ex_jumpImmEx <= "000000" & ex_instr(25 downto 0);
	SLL2Jump: SLL32bit port map (A	=> ex_jumpImmEx,
				     B	=> two,
				     Y	=> jumpImmExSll);

	myPCSrc_control: PCSrc_control port map (opcode	=> ex_instr(31 downto 26),
					       equal	=> ex_zero,--ex_Equal,
					       PCSrc	=> ex_PCSrc);

	ex_Rd <= ex_instr(15 downto 11);
	ex_Rs <= ex_instr(25 downto 21);
	ex_Rt <= ex_instr(20 downto 16);

	DestRegMux: Mux_2_1_5bit port map (sel		=> ex_RegDst,
					   A		=> ex_Rt,
					   B		=> ex_Rd,
					   muxout	=> ex_destRegMuxOut);

	JalDestRegMux: Mux_2_1_5bit port map (sel	=> ex_JalSel,
					      A		=> ex_destRegMuxOut,
					      B		=> Ra,
					      muxout	=> ex_wsel);

	with mem_PCSrc select
		exmem_in <= ex_stCondnal & ex_linked & ex_PC4Imm16 & "00" & ex_pcplus4 & '0' &  "00000" & ex_wsel & ex_aluout & ex_extOut & ex_aluIn2 when '1',
				ex_stCondnal & ex_linked & ex_PC4Imm16 & ex_PCSrc & ex_halt_s & ex_pcplus4 & ex_RegWr & ex_BusWSel & ex_MemtoReg & ex_JalSel & ex_MemWr & ex_MemRd & ex_wsel & ex_aluout & ex_extOut & ex_aluIn2 when others;

	ex_mem_wren <= not stall;
	EX_MEM_Latch: EX_MEM_Register port map (clk	=> CLK,
						nReset	=> nReset,
						wren	=> ex_mem_wren,
						data	=> exmem_in,
						q	=> exmem_out);

	forwarder:forwardingUnit port map (IDEXRegisterRs => ex_Rs,
					   IDEXRegisterRt => ex_Rt,
						--IDEXRegDst => ex_RegDst,
						IDEXMemRd => ex_MemRd,
					   EXMEMRegWrite => mem_RegWr,
					   EXMEMRegisterRd => mem_wsel,
					   MEMWBRegWrite => wb_RegWr,
					   MEMWBRegisterRd => wb_wsel,
					   ForwardA	=> ForwardA,
					   ForwardB	=> ForwardB);
	
	
	--mux logic to select between alu inputs
	process(ForwardA,ForwardB,ex_busA,mem_aluout,wb_regWrMuxOut,ex_busB)
	begin
		case ForwardA is
			when "01" => aluOperand1 <= wb_regWrMuxOut;
			when "10" => aluOperand1 <= mem_aluout;
			when others => aluOperand1 <= ex_busA;
		end case;
		
		case ForwardB is
			when "01" => ex_aluIn2 <= wb_regWrMuxOut;
                        when "10" => ex_aluIn2 <= mem_aluout;
                        when others => ex_aluIn2 <= ex_busB; 
		end case;	
	end process;

-- MEM: Memory Stage
--------------------
	
	cpuRead <= (mem_MemRd and (not mem_PCSrc));-- when (cacheDumpOn = '0') else '1';
	cpuWrite <= (mem_MemWr and (not mem_PCSrc));-- when (cacheDumpOn = '0') else '0';
	--memWait <= '0' when (data_out = '1' and ramState = MEMACCESS)else '1';
	--memWait <= '1' when(((dCacheMemRead = '1' or dCacheMemWrite = '1') and instr_out = '1') or (data_out = '1' and ramState /= MEMACCESS)) else '0';
	cpuAddr <= mem_aluout;-- when (cacheDumpOn = '0') else dumpPC;
	mem_memOut <= cacheToCpuData;
	cpuToCacheData <= mem_busB;
	stall <= '1' when (dCacheReady = '0') else '0';
	--dataCache : dcache
	--port map(clk,nReset,cpuReadReq,cpuWriteReq,cpuMemAddr,mem_busB,mem_memOut,dCacheReady,dCacheMemRead,dCacheMemWrite,dCacheMemAddr,dCacheToMemData,memToCacheData,memWait);
	
	mem_stCondnal	<= exmem_out(174);
	mem_linked	<= exmem_out(173);
	mem_PC4Imm16 	<= exmem_out(172 downto 141);
	mem_PCSrc	<= exmem_out(140);
	mem_halt_s	<= exmem_out(139);
	mem_pcplus4	<= exmem_out(138 downto 107);
	mem_RegWr	<= exmem_out(106);
	mem_BusWSel	<= exmem_out(105);
	mem_MemtoReg	<= exmem_out(104);
	mem_JalSel	<= exmem_out(103);
	mem_MemWr	<= exmem_out(102);
	mem_MemRd	<= exmem_out(101);
	mem_wsel	<= exmem_out(100 downto 96);
	mem_aluout	<= exmem_out(95 downto 64);
	mem_extOut	<= exmem_out(63 downto 32);
	mem_busB	<= exmem_out(31 downto 0);
	
	loadLinked <= mem_linked;
	llscMemMux : Mux_2_1_32bit port map (	
						sel		=> lockSuccess,
						A		=> zero_32,
						B		=> one_32,
						muxout		=> mem_scRes
						);
	
	memwb_in <= mem_scRes & mem_stCondnal & mem_halt_s & mem_pcplus4 & mem_RegWr & mem_BusWSel & mem_MemtoReg & mem_JalSel & mem_wsel & mem_aluout & mem_memOut & mem_extOut;

	mem_wb_wren <= not stall;
	MEM_WB_Latch: MEM_WB_Register port map (clk	=> CLK,
						nReset	=> nReset,
						wren	=> mem_wb_wren,
						data	=> memwb_in,
						q	=> memwb_out);

-- WB: Write-back Stage
-----------------------

	wb_scRes	<= memwb_out(170 downto 139);
	wb_stCondnal	<= memwb_out(138);
	wb_halt_s	<= memwb_out(137);
	wb_pcplus4	<= memwb_out(136 downto 105);
	wb_RegWr	<= memwb_out(104);
	wb_BusWSel	<= memwb_out(103);
	wb_MemtoReg	<= memwb_out(102);
	wb_JalSel	<= memwb_out(101);
	wb_wsel		<= memwb_out(100 downto 96);
	wb_aluout	<= memwb_out(95 downto 64);
	wb_memOut	<= memwb_out(63 downto 32);
	wb_extOut	<= memwb_out(31 downto 0);

	RegWrMux: Mux_2_1_32bit port map (sel		=> wb_MemtoReg,
					  A		=> wb_aluout,
					  B		=> wb_memOut,
					  muxout	=> wb_regWrMuxIntmdt);

	BusWselMux: Mux_2_1_32bit port map (sel		=> wb_BusWSel,
					    A		=> wb_regWrMuxOut,
					    B		=> wb_extOut,
					    muxout	=> wb_busWSelMuxOut);

	JalSelMux: Mux_2_1_32bit port map (sel		=> wb_JalSel,
					   A		=> wb_busWSelMuxOut,
					   B		=> wb_pcplus4,
					   muxout	=> busW);

	llscWbMux : Mux_2_1_32bit port map (sel		=> wb_stCondnal,
					  A		=> wb_regWrMuxIntmdt,
					  B		=> wb_scRes,
					  muxout	=> wb_regWrMuxOut);

	halt <= wb_halt_s;

	--cacheDumper : cacheDump
	--port map (nReset,CLK,wb_halt_s,dCacheReady,cacheDumpMemRead,cacheDumpOn,dumpPC,halt);

-- Program Counter

	PC: process (CLK, PCwe, nReset)
	begin
		if (nReset = '0' and PCSelect = '0') then
			if_PCOut	<= zero_32;
		elsif (nReset = '0' and PCSelect = '1')then
			if_PCOut	<= X"00000200";
		elsif (rising_edge(CLK) and PCwe = '1') then
			if_PCOut	<= if_PCIn;
		end if;
	end process PC;
	

-- PCwe control


	PCwe <= not( stall or halt_s or stall_pc or hazardStall) or mem_PCSrc or ex_Jump or ex_JumpSel;



end behavioral;
