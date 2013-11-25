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

entity cacheReg is
	port(
			dataIn 		:	in std_logic_vector(63 downto 0);
			tagIn		:	in std_logic_vector(25 downto 0);
			blockWrEn	:	in std_logic;
			tagWrEn		:	in std_logic;
			dirtyIn		: 	in std_logic;
			index		:	in std_logic_vector(2 downto 0);
			clk		:	in std_logic;
			nReset		:	in std_logic;
			tagOut		:	out std_logic_vector(25 downto 0);
			dataOut		:	out std_logic_vector(63 downto 0);
			validRead	:	out std_logic;
			dirtyRead	:	out std_logic	
		);
end cacheReg;

architecture behavioural of cacheReg is
	
	type REG64 is array(0 to 7) of std_logic_vector(63 downto 0);
	type TAG26 is array(0 to 7) of std_logic_vector(25 downto 0);
	type DIRTY is array(0 to 7) of std_logic;
	type VALID is array(0 to 7) of std_logic;
	
	signal block64 : REG64;
	signal tagData	: TAG26;
	signal dirtyBit	: std_logic_vector(7 downto 0);
	signal validBit	:std_logic_vector(7 downto 0);
		signal k : integer :=0 ;
	begin
	indexSelect : process(index)
	begin
		k <= 0;
		case index is
			when "000" => k <= 0;
			when "001" => k <= 1;
			when "010" => k <= 2;
			when "011" => k <= 3;
			when "100" => k <= 4;
			when "101" => k <= 5;
			when "110" => k <= 6;
			when "111" => k <= 7;
			when others => k <= 0;
		end case;	
	end process;
			
	cacheRead : process(k,block64,tagData,dirtyBit,validBit)
	begin
		dataOut <= block64(k);
		tagOut <= tagData(k);
		dirtyRead <= dirtyBit(k);
		validRead <= validBit(k);
	end process;

	cacheWrite : process(k,dataIn,tagIn,dirtyIn,clk,blockWrEn,tagWrEn,nReset)
	begin
		if(rising_edge(clk) and (blockWrEn = '1')) then
			block64(k) <= dataIn;
			dirtyBit(k) <= dirtyIn;
		end if;
		if(nReset = '0')then
			validBit <= (others=>'0');
			dirtyBit <= (others=>'0');
		elsif(rising_edge(clk) and blockWrEn = '1') then
			validBit(k) <= '1';
		end if;
		if(rising_edge(clk) and (tagWrEn = '1')) then
			tagData(k) <= tagIn;
		end if;	
	end process;		
	
end behavioural;	
