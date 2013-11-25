library ieee;
--library gold_lib;   --UNCOMMENT if you're using a GOLD model
use ieee.std_logic_1164.all;
--use gold_lib.all;   --UNCOMMENT if you're using a GOLD model
use IEEE.STD_LOGIC_TEXTIO.all;
use STD.TEXTIO.all;
use IEEE.NUMERIC_STD.all;
library icache_gold;
use icache_gold.icache;

entity tb_cache is
	generic (Period : Time := 100 ns;
		Debug : Boolean := True);
end tb_cache;

architecture TEST of tb_cache is


	component icache port(
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
	
	component VarLatRAM port (
		nReset          : in std_logic ;
		clock           : in std_logic ;
		address         : in std_logic_vector (15 DOWNTO 0);
		data            : in std_logic_vector (63 DOWNTO 0);
		wren            : in std_logic ;
		rden            : in std_logic ;
		latency_override: in std_logic ; 
		q               : out std_logic_vector (63 DOWNTO 0);
		memstate        : out std_logic_vector (1 DOWNTO 0)
		);
	end component;


-- Insert signals Declarations here
	signal clk, nReset, memNReset, iMemRead, iMemWait, aiMemWait, aiMemRead, wren, rden, latency_override,myMemWen	:	std_logic;
	signal iMemAddr, iMemData, aiMemAddr,cacheRead,pc	: std_logic_vector(31 downto 0); 
	signal data, q,aiMemData					:	std_logic_vector (63 downto 0);
	signal address		:	std_logic_vector (15 downto 0);
	signal memstate		:	std_logic_vector (1 downto 0);
	signal cpuClk, initClkCtl, dumpClkCtl, cpuClkCtl, halt : std_logic;
	signal myMemCtl : std_logic;
    signal myMemAddr : std_logic_vector(15 downto 0);
    signal myMemData : std_logic_vector(63 downto 0);

-- signal <name> : <type>;
  constant z    : std_logic_vector := "00000000000000000000000000000000";
  constant v1   : std_logic_vector := "00000000000000000000000000000001";
  constant v2   : std_logic_vector := "00000000000000000000000000000010";
  constant v3   : std_logic_vector := "00000000000000000001001001110001";
  constant v4   : std_logic_vector := "00000000000000000110001000011111";
  constant v5   : std_logic_vector := "10001010100001010101010100000111";
  constant v6   : std_logic_vector := "11111111111111111111111111111000";
  constant v7   : std_logic_vector := "11111111111111111111111111111010";
  constant v8   : std_logic_vector := "00000000000000000000000000000011";
  constant v9	: std_logic_vector := "01000000000000000000000000000011";
  constant v10	: std_logic_vector := "01111111000000000000000000000011";
  constant v11   : std_logic_vector := "10000000000000000000000000000001";
  constant v12   : std_logic_vector := "10000000000000000000000000000001";

constant MEMFREE        : std_logic_vector              := "00";
        constant MEMBUSY        : std_logic_vector              := "01";
        constant MEMACCESS      : std_logic_vector              := "10";
        constant MEMERROR       : std_logic_vector              := "11";


	-- converts a hex string to a std_logic_vector
	function str_to_std_logic_vector (s : string) return std_logic_vector is
		variable vec : std_logic_vector(4 * (s'high - s'low) + 3 downto 0);
		variable tmp : std_logic_vector(3 downto 0);
		variable j : integer;
	begin
		for i in 0 to s'high - s'low loop
			case s(i + s'low) is
				when '0' =>
					tmp := X"0";
				when '1' =>
					tmp := X"1";
				when '2' =>
					tmp := X"2";
				when '3' =>
					tmp := X"3";
				when '4' =>
					tmp := X"4";
				when '5' =>
					tmp := X"5";
				when '6' =>
					tmp := X"6";
				when '7' =>
					tmp := X"7";
				when '8' =>
					tmp := X"8";
				when '9' =>
					tmp := X"9";
				when 'A' =>
					tmp := X"A";
				when 'B' =>
					tmp := X"B";
				when 'C' =>
					tmp := X"C";
				when 'D' =>
					tmp := X"D";
				when 'E' =>
					tmp := X"E";
				when 'F' =>
					tmp := X"F";
				when others =>
					tmp := X"0";
			end case;
			j := s'high - s'low - i;
			vec((j + 1) * 4 - 1 downto j * 4) := tmp;
		end loop;
		return vec;
	end str_to_std_logic_vector;

		
	-- initializes memory from meminit.hex, then monitors memory for writes
begin
        --iMemAddr <= x"0000" & address;
        DUT: icache port map(
                clk             =>      clk,
                nReset          =>      nReset,
                iMemRead        =>      iMemRead,
                iMemAddr        =>      iMemAddr,
                aiMemWait       =>      aiMemWait,
                aiMemData       =>      aiMemData,
                iMemWait        =>      iMemWait,
                iMemData        =>      iMemData,
                aiMemRead       =>      aiMemRead,
                aiMemAddr       =>      aiMemAddr
                );

        theRam: VarLatRAM port map(
                nReset          =>      memNReset,
                clock           =>      clk,
                address         =>      address,
                data            =>      myMemData,
                wren            =>      myMemWen,
                rden            =>      aiMemRead,
                latency_override        =>      '1',
                q               =>      aiMemData,
                memstate        =>      memstate
                );
	-- generate clock signal
  clkgen: process
    variable clk_tmp : std_logic := '0';
  begin
    clk_tmp := not clk_tmp;
    clk <= clk_tmp;
    wait for Period/2;
  end process;

	testing_process : process 
		file my_input : text;
		variable line_in : line;
		variable line_out : line;
		variable i : integer := 0;
		variable j : integer := 0;
		variable save_line : integer := 0;
		variable dummy1_s0 : string(1 to 3);
		variable address_s0 : string(1 to 4);
		variable dummy2_s0 : string(1 to 2);
		variable data_s0 : string(1 to 8);
		variable dummy1_s1 : string(1 to 3);
		variable address_s1 : string(1 to 4);
		variable dummy2_s1 : string(1 to 2);
		variable data_s1 : string(1 to 8);
		variable tmp : std_logic_vector(63 downto 0);
		
	begin
		nReset <= '0';
		memNReset <= '0';
		wait for 2 * Period;
		memNReset <= '1';
		write(line_out, string'("starting memory initialization"));
		writeline(OUTPUT, line_out);
		initClkCtl <= '1';
		myMemCtl <= '1';
		myMemWen <= '1';
		-- open meminit.hex for reading
		file_open(my_input, "meminit.hex", read_mode);
		while not endfile(my_input) loop
			if (save_line = 1) then
				dummy1_s0 := dummy1_s1;
				address_s0 := address_s1;
				dummy2_s0 := dummy2_s1;
				data_s0 := data_s1;
				save_line := 0;
			else
        		        readline(my_input, line_in);
        		        read(line_in, dummy1_s0);
        		        if (dummy1_s0 /= ":04") then
        				exit;
		                end if;
                		read(line_in, address_s0);
                		read(line_in, dummy2_s0);
		                read(line_in, data_s0);
			end if;

                	-- set address
                	myMemAddr <= str_to_std_logic_vector(address_s0)(13 downto 0) & "00";
			myMemData <= x"00000000" & str_to_std_logic_vector(data_s0);
			if (myMemAddr(2) = '1') then
                		myMemData <= str_to_std_logic_vector(data_s0) & x"00000000";
			else
				readline(my_input, line_in);
				read(line_in, dummy1_s1);
				if (dummy1_s1 /= ":04") then
					exit;
				end if;
				read(line_in, address_s1);
				read(line_in, dummy2_s1);
				read(line_in, data_s1);
				if (str_to_std_logic_vector(address_s1)(13 downto 1) = myMemAddr(15 downto 3)) then
        	        		myMemData <= str_to_std_logic_vector(data_s1) & str_to_std_logic_vector(data_s0);
				else
					save_line := 1;
				end if;
			end if;

	                -- give address time to output
	                wait for Period;
	                if (Debug) then
				write(line_out, string'("Writing value "));
				write(line_out, data_s0);
				write(line_out, string'(" ("));
				hwrite(line_out, myMemData);
				write(line_out, string'(") "));
				write(line_out, string'(" to address "));
				write(line_out, address_s0);
				write(line_out, string'(" ("));
				hwrite(line_out, myMemAddr);
				write(line_out, string'(") "));
				writeline(output, line_out);
			end if;
			wait for Period;
		end loop;

		-- close file
		file_close(my_input);
		-- so we don't keep looping
		write(line_out, string'("initialized memory"));
		writeline(OUTPUT, line_out);
		initClkCtl <= '0';
		myMemCtl <= '0';
		myMemWen <= '0';
		wait for 4 * Period;
		nReset <= '1';
		wait;
	end process;
	
	address <= myMemAddr when (nReset = '0') else aiMemAddr(15 downto 0);

	aiMemWait <= '1' when ((iMemRead = '1') and (memstate /= MEMACCESS) and (nReset = '1')) else '0';	

	iMemRead <= '1';

		

	tb_process: process
	begin
		wait for 6000 ns;
		iMemAddr <= x"00000000";
		wait for 1000 ns;
		iMemAddr <= x"00000004";
		wait for 1000 ns;
		iMemAddr <= x"00000008";
		wait for 1000 ns;
		iMemAddr <= x"0000000C";
		wait for 1000 ns;
		iMemAddr <= x"00000010";
		wait for 1000 ns;
		iMemAddr <= x"00000014";
		wait for 1000 ns;
		iMemAddr <= x"0000001C";
		wait;
	end process tb_process;
	

end TEST;
