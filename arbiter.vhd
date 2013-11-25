library ieee;
use ieee.std_logic_1164.all;

entity arbiter is
        port (
                CLK             :       in      std_logic;
                nReset          :       in      std_logic;

                icacheReq       :       in      std_logic;      --core
                aiMemWait       :       out     std_logic;
                aimemAddr       :       in      std_logic_vector(31 downto 0);
                aiMemData       :       out     std_logic_vector(63 downto 0);

                memRead         :       in      std_logic;      --core
                memWrite        :       in      std_logic;
                memAddr         :       in      std_logic_vector(31 downto 0);
                memToCache      :       out     std_logic_vector(63 downto 0);
                cacheToMem      :       in      std_logic_vector(63 downto 0);
                memWait         :       out     std_logic;


                ramState        :       in      std_logic_vector(1 downto 0);   --Memory
                ramRen          :       out     std_logic;                      --Memory
                ramWen          :       out     std_logic;                      --Memory
                ramAddr         :       out     std_logic_vector(15 downto 0);  --Memory
                ramQ            :       in      std_logic_vector(63 downto 0);  --Memory
                ramData         :       out     std_logic_vector(63 downto 0);   --Memory
		procArbitWait	:	in	std_logic
        );
end arbiter;
architecture behav of arbiter is

        constant MEMFREE        : std_logic_vector              := "00";
    constant MEMBUSY        : std_logic_vector              := "01";
    constant MEMACCESS      : std_logic_vector              := "10";
    constant MEMERROR       : std_logic_vector              := "11";

        type state_type is      (instructionFetch, dataAccess,idle);
        signal currState,nextState : state_type;

        signal instr_out,data_out,dcacheReq,aiMemRead   :       std_logic;

begin
        stateChange : process(clk,nReset)
        begin
                if(nReset = '0') then
                        currState <= idle;
                elsif(rising_edge(clk)) then
                        currState <= nextState;
                end if;
        end process stateChange;

        arbitration : process(currState,dcacheReq,icacheReq,ramState,procArbitWait)
        begin
                case currState is

                        when idle =>
                                        if(dcacheReq = '1') then
                                                nextState <= dataAccess;
                                        elsif(icacheReq = '1') then
                                                nextState<= instructionFetch;
                                        else
                                                nextState <= idle;
                                        end if;

                        when instructionFetch =>
                                        if(ramState = MEMACCESS and procArbitWait = '0') then
                                                if(dcacheReq = '1') then
                                                        nextState <= dataAccess;
                                                else
                                                        nextState <= idle;
                                                end if;
                                        else
                                                nextState <= instructionFetch;
                                        end if;

                        when dataAccess =>
                                        if(ramState = MEMACCESS and procArbitWait = '0') then
                                                if(icacheReq = '1') then
                                                        nextState <= instructionFetch;
                                                else
                                                        nextState <= idle;
                                                end if;
                                        else
                                                nextState <= dataAccess;
                                        end if;
                        when others =>
                                        nextState <= idle;
                        end case;
        end process arbitration;
-----------------------------arbitration logic--------------------------------------------
        instr_out <= '1' when (currState = instructionFetch) else '0';
        data_out <= '1' when (currState = dataAccess) else '0';
        aiMemRead <= icacheReq;
        aiMemWait <= '0' when (instr_out = '1' and ramState = MEMACCESS and procArbitWait = '0')  else '1';
        ramRen <= '1' when ((aiMemRead = '1' and instr_out = '1') or (memRead = '1' and instr_out = '0')) else '0';
        ramWen <= '1' when (memWrite = '1' and data_out = '1') else '0';
        process(data_out,instr_out,memAddr,aiMemAddr)
        begin
                if(data_out = '1') then
                        ramAddr <= memAddr(15 downto 0);
                elsif(instr_out = '1')then
                        ramAddr <= aiMemAddr(15 downto 0);
                else
                        ramAddr <= X"00AB";
                end if;
        end process;
        process(nReset,data_out,ramState,ramQ,instr_out,cacheToMem)
        begin
                if(nReset = '0')then
                        memToCache <= X"ABCDABCDABCDABCD";
                elsif((data_out = '1') or (ramState = MEMACCESS))then
                        memToCache <= ramQ;
                else
                        memToCache <= X"ABCDABCDABCDABCD";
                end if;
                if(nReset = '0')then
                        aiMemData <= X"ABCDABCDABCDABCD";
                else
                        aiMemData <= ramQ;
                end if;
                if(nReset = '0')then
                        ramData <= X"ABCDABCDABCDABCD";
                else
                        ramData <= cacheToMem;
                end if;
        end process;
        memWait <= '0' when (data_out = '1' and ramState = MEMACCESS and procArbitWait = '0')else '1';
        dcacheReq <= memRead or memWrite;
end behav;
