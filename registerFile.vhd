-- 32 bit version register file
-- evillase

library ieee;
use ieee.std_logic_1164.all;

entity registerFile is
	port
	(
		-- Write data input port
		wdat		:	in	std_logic_vector (31 downto 0);
		-- Select which register to write
		wsel		:	in	std_logic_vector (4 downto 0);
		-- Write Enable for entire register file
		wen			:	in	std_logic;
		-- clock, positive edge triggered
		clk			:	in	std_logic;
		-- REMEMBER: nReset-> '0' = RESET, '1' = RUN
		nReset	:	in	std_logic;
		-- Select which register to read on rdat1 
		rsel1		:	in	std_logic_vector (4 downto 0);
		-- Select which register to read on rdat2
		rsel2		:	in	std_logic_vector (4 downto 0);
		-- read port 1
		rdat1		:	out	std_logic_vector (31 downto 0);
		-- read port 2
		rdat2		:	out	std_logic_vector (31 downto 0)
	);
end registerFile;

architecture regfile_arch of registerFile is

	constant BAD1	:	std_logic_vector		:= x"BAD1BAD1";

	type REGISTER32 is array (1 to 31) of std_logic_vector(31 downto 0);
	signal reg	:	REGISTER32;				-- registers as an array

	-- enable lines... use en(x) to select
	-- individual lines for each register
	signal en		:	std_logic_vector(31 downto 0);
	signal decoder_input	:	std_logic_vector(5 downto 0);

begin

	-- registers process
	registers : process (clk, nReset, en)
	begin
		-- one register if statement
		if (nReset = '0') then
			-- Reset here
			for i in 1 to 31 loop
				reg(i) <= x"00000000";
			end loop;
		elsif (falling_edge(clk)) then
			-- Set register here
			for i in 1 to 31 loop
				if (en(i) = '1') then
					reg(i) <= wdat;
				end if;
			end loop;
		end if;
	end process;

  	--decoder for assigning en:
	decoder: process (wen, wsel)
	begin
		en <= x"00000000";
		if (wen = '1') then
			case wsel is
				when "00000"	=> en <= X"00000001";
				when "00001"	=> en <= X"00000002";
				when "00010"	=> en <= X"00000004";
				when "00011"	=> en <= X"00000008";
				when "00100"	=> en <= X"00000010";
				when "00101"	=> en <= X"00000020";
				when "00110"	=> en <= X"00000040";
				when "00111"	=> en <= X"00000080";
				when "01000"	=> en <= X"00000100";
				when "01001"	=> en <= X"00000200";
				when "01010"	=> en <= X"00000400";
				when "01011"	=> en <= X"00000800";
				when "01100"	=> en <= X"00001000";
				when "01101"	=> en <= X"00002000";
				when "01110"	=> en <= X"00004000";
				when "01111"	=> en <= X"00008000";
				when "10000"	=> en <= X"00010000";
				when "10001"	=> en <= X"00020000";
				when "10010"	=> en <= X"00040000";
				when "10011"	=> en <= X"00080000";
				when "10100"	=> en <= X"00100000";
				when "10101"	=> en <= X"00200000";
				when "10110"	=> en <= X"00400000";
				when "10111"	=> en <= X"00800000";
				when "11000"	=> en <= X"01000000";
				when "11001"	=> en <= X"02000000";
				when "11010"	=> en <= X"04000000";
				when "11011"	=> en <= X"08000000";
				when "11100"	=> en <= X"10000000";
				when "11101"	=> en <= X"20000000";
				when "11110"	=> en <= X"40000000";
				when "11111"	=> en <= X"80000000";
				when others	=> en <= X"00000000";
			end case;
		end if;
	end process;

	--rsel muxes:
	with rsel1 select
		rdat1 <=	x"00000000" when "00000",
				reg(1) when "00001",
				reg(2) when "00010",
				reg(3) when "00011",
				reg(4) when "00100",
				reg(5) when "00101",
				reg(6) when "00110",
				reg(7) when "00111",
				reg(8) when "01000",
				reg(9) when "01001",
				reg(10) when "01010",
				reg(11) when "01011",
				reg(12) when "01100",
				reg(13) when "01101",
				reg(14) when "01110",
				reg(15) when "01111",
				reg(16) when "10000",
				reg(17) when "10001",
				reg(18) when "10010",
				reg(19) when "10011",
				reg(20) when "10100",
				reg(21) when "10101",
				reg(22) when "10110",
				reg(23) when "10111",
				reg(24) when "11000",
				reg(25) when "11001",
				reg(26) when "11010",
				reg(27) when "11011",
				reg(28) when "11100",
				reg(29) when "11101",
				reg(30) when "11110",
				reg(31) when "11111",
							BAD1 when others;

	with rsel2 select
		rdat2 <=	x"00000000" when "00000",
				reg(1) when "00001",
				reg(2) when "00010",
				reg(3) when "00011",
				reg(4) when "00100",
				reg(5) when "00101",
				reg(6) when "00110",
				reg(7) when "00111",
				reg(8) when "01000",
				reg(9) when "01001",
				reg(10) when "01010",
				reg(11) when "01011",
				reg(12) when "01100",
				reg(13) when "01101",
				reg(14) when "01110",
				reg(15) when "01111",
				reg(16) when "10000",
				reg(17) when "10001",
				reg(18) when "10010",
				reg(19) when "10011",
				reg(20) when "10100",
				reg(21) when "10101",
				reg(22) when "10110",
				reg(23) when "10111",
				reg(24) when "11000",
				reg(25) when "11001",
				reg(26) when "11010",
				reg(27) when "11011",
				reg(28) when "11100",
				reg(29) when "11101",
				reg(30) when "11110",
				reg(31) when "11111",
							BAD1 when others;

end regfile_arch;
