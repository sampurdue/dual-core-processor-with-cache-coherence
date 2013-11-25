--cacheReg.vhd
--contains implementation for a 
--16 set, 2-way associative, 2 words/block cache
--block offset = 1
--index bits = 3
--tag bit = 32 - (1+3+2)=26
--frame size = 26+64+1(valid)+1(dirty) = 92

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity icacheReg is
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
end icacheReg;

architecture behavioural of icacheReg is
	
	type REG64 is array(0 to 15) of std_logic_vector(63 downto 0);
	type TAG26 is array(0 to 15) of std_logic_vector(24 downto 0);
	type VALID is array(0 to 15) of std_logic;
	
	signal block64 : REG64;
	signal tagData	: TAG26;
	--signal validBit	:	VALID := ('0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0');
		signal k : integer :=0 ;
	signal validBit : std_logic_vector(15 downto 0) := X"0000";
	begin
	indexSelect : process(index)
	begin
		k <= 0;
		case index is
			when "0000" => k <= 0;
			when "0001" => k <= 1;
			when "0010" => k <= 2;
			when "0011" => k <= 3;
			when "0100" => k <= 4;
			when "0101" => k <= 5;
			when "0110" => k <= 6;
			when "0111" => k <= 7;
			when "1000" => k <= 8;
			when "1001" => k <= 9;
			when "1010" => k <= 10;
			when "1011" => k <= 11;
			when "1100" => k <= 12;
			when "1101" => k <= 13;
			when "1110" => k <= 14;
			when "1111" => k <= 15;
			when others => k <= 0;
		end case;	
	end process;
			
	cacheRead : process(k,block64,tagData,validBit)
	begin
		dataOut <= block64(k);
		tagOut <= tagData(k);
		validRead <= validBit(k);
	end process;

	cacheWrite : process(k,dataIn,tagIn,clk,blockWrEn,tagWrEn,nReset)
	begin
		if(rising_edge(clk) and (blockWrEn = '1')) then
			block64(k) <= dataIn;
			
		end if;
		if(nReset = '0') then
			validBit <= (others=>'0');
		elsif(blockWrEn = '1' and rising_edge(clk)) then
			validBit(k) <= '1';
		end if;
		if(rising_edge(clk) and (tagWrEn = '1')) then
			tagData(k) <= tagIn;
		end if;	
	end process;

		
	
end behavioural;	
