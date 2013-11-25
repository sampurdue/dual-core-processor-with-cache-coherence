library ieee;
use ieee.std_logic_1164.all;

entity processorArbiter is
        port (
                CLK             :       in      std_logic;
                nReset          :       in      std_logic;

                procRead0         :       in      std_logic;      --core
                procWrite0        :       in      std_logic;
                procAddr0         :       in      std_logic_vector(15 downto 0);
                procToMem0      :       in     std_logic_vector(63 downto 0);
                memToProc0      :       out      std_logic_vector(63 downto 0);
                procWait0       :       out     std_logic;

                procRead1         :       in      std_logic;      --core
                procWrite1        :       in      std_logic;
                procAddr1         :       in      std_logic_vector(15 downto 0);
                procToMem1      :       in     std_logic_vector(63 downto 0);
                memToProc1      :       out      std_logic_vector(63 downto 0);
                procWait1         :       out     std_logic;


                ramState        :       in      std_logic_vector(1 downto 0);   --Memory
                ramRen          :       out     std_logic;                      --Memory
                ramWen          :       out     std_logic;                      --Memory
                ramAddr         :       out     std_logic_vector(15 downto 0);  --Memory
                ramQ            :       in      std_logic_vector(63 downto 0);  --Memory
                ramData         :       out     std_logic_vector(63 downto 0)   --Memory
        );
end processorArbiter;
architecture behav of processorArbiter is

        constant MEMFREE        : std_logic_vector              := "00";
    constant MEMBUSY        : std_logic_vector              := "01";
    constant MEMACCESS      : std_logic_vector              := "10";
    constant MEMERROR       : std_logic_vector              := "11";

        type state_type is      (proc0, proc1,idle);
        signal currState,nextState : state_type;

        signal proc1Grant,proc0Grant,proc0Req,proc1Req,aiMemRead   :       std_logic;

begin
		proc0Req <= procRead0 or procWrite0;
		proc1Req <= procRead1 or procWrite1;
		
        stateChange : process(clk,nReset)
        begin
                if(nReset = '0') then
                        currState <= idle;
                elsif(rising_edge(clk)) then
                        currState <= nextState;
                end if;
        end process stateChange;

        arbitration : process(currState,proc0Req,proc1Req,ramState)
        begin
                case currState is

                        when idle =>
                                        if(proc0Req = '1') then
                                                nextState <= proc0;
                                        elsif(proc1Req = '1') then
                                                nextState<= proc1;
                                        else
                                                nextState <= idle;
                                        end if;

                        when proc1 =>
                                        if(ramState = MEMACCESS) then
                                                if(proc0Req = '1') then
                                                        nextState <= proc0;
                                                else
                                                        nextState <= idle;
                                                end if;
                                        else
                                                nextState <= proc1;
                                        end if;

                        when proc0 =>
                                        if(ramState = MEMACCESS) then
                                                if(proc1Req = '1') then
                                                        nextState <= proc1;
                                                else
                                                        nextState <= idle;
                                                end if;
                                        else
                                                nextState <= proc0;
                                        end if;
                        when others =>
                                        nextState <= idle;
                        end case;
        end process arbitration;
-----------------------------arbitration logic--------------------------------------------
        proc1Grant <= '1' when (currState = proc1) else '0';
        proc0Grant <= '1' when (currState = proc0) else '0';
        procWait0 <= '0' when (proc0Grant = '1' and ramState = MEMACCESS)  else '1';
	procWait1 <= '0' when (proc1Grant = '1' and ramState = MEMACCESS)  else '1';
        ramRen <= '1' when ((procRead0 = '1' and proc0Grant = '1') or (procRead1 = '1' and proc1Grant = '1')) else '0';
        ramWen <= '1' when ((procWrite0 = '1' and proc0Grant = '1') or (procWrite1 = '1' and proc1Grant = '1')) else '0';
 	ramAddr <= procAddr0 when (proc0Grant = '1') else
		procAddr1 when (proc1Grant = '1') else
		X"00AB";
	ramData <= procToMem0 when (proc0Grant = '1') else
			procToMem1 when (proc1Grant = '1') else
			X"ABCDABCDABCDABCD";
	memToProc0 <= ramQ when ((proc0Grant = '1') or (ramState = MEMACCESS)) else X"ABCDABCDABCDABCD";
	memToProc1 <= ramQ when ((proc1Grant = '1') or (ramState = MEMACCESS)) else X"ABCDABCDABCDABCD";
        proc0Req <= procRead0 or procWrite0;
	proc1Req <= procRead1 or procWrite1;
end behav;
