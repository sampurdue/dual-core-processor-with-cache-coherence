library ieee;
use ieee.std_logic_1164.all;

entity arbiter is
	port (
		CLK		:	in	std_logic;
		nReset		:	in	std_logic;
		ramState	:	in std_logic_vector(1 downto 0);
		icacheReq	:	in std_logic;
		dcacheReq	:	in std_logic;
		instr_out	:	out std_logic_vector(1 downto 0);
		data_out	:	out std_logic_vector(1 downto 0)
	);
end arbiter;
architecture behav of arbiter is

	constant MEMFREE        : std_logic_vector              := "00";
    constant MEMBUSY        : std_logic_vector              := "01";
    constant MEMACCESS      : std_logic_vector              := "10";
    constant MEMERROR       : std_logic_vector              := "11";
	
	type state_type is 	(instructionFetch, dataAccess,idle);
	signal currState,nextState : state_type;

begin
	stateChange : process(clk,nReset)
	begin
		if(nReset = '0') then
			currState <= idle;
		elsif(rising_edge(clk)) then
			currState <= nextState;
		end if;
	end process stateChange;
	
	arbitration : process(currState,dcacheReq,icacheReq,ramState)
	begin
		case currState is
			
			when idle =>
					instr_out <= '0';
					data_out <= '0';
					if(dcacheReq = '1') then
						nextState <= dataAccess;
					elsif(icacheReq = '1') then
						nextState<= instructionFetch;
					else
						nextState <= idle;
					end if;
 
			when instructionFetch =>
					instr_out <= '1';
					data_out <= '0';
					if(ramState = MEMACCESS) then
						if(dcacheReq = '1') then
							nextState <= dataAccess;
						else
							nextState <= idle;
						end if;
					else
						nextState <= instructionFetch;
					end if;
			
			when dataAccess =>
					data_out <= '1';
					instr_out <= '0';
					if(ramState = MEMACCESS) then
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
end behav;	
