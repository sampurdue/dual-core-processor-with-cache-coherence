-- opcode list
--
--	0000	SLL
--	0001	SRL
--	0010	ADD	
--	0011	SUB
--	0100	AND
--	0101	NOR
--	0110	OR
--	0111	XOR
--	1000	SLT
--	1001	SLTU
--	1010	LUI




library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity alu is
    port
    (
        -- opcode to determine operation
        opcode        :    in    std_logic_vector (3 downto 0);
        -- input 1 port
        A        :    in    std_logic_vector (31 downto 0);
        -- input 2 port
        B        :    in    std_logic_vector (31 downto 0);
        -- output port
        aluout        :    out    std_logic_vector (31 downto 0);
        -- negative port
        negative    :    out    std_logic;
        -- overflow port
        overflow    :    out    std_logic;
        -- zero port
        zero        :    out    std_logic;
	-- equal port
	equal		:	out	std_logic
    );
end alu;

architecture alu_arch of alu is

    constant BAD1    :    std_logic_vector    := x"BAD1BAD1";
    constant c_zero    :    std_logic_vector    := x"00000000";

    type OUT_ARRAY is array (0 to 10) of std_logic_vector (31 downto 0);
    signal out_i        :    OUT_ARRAY;
    signal not_B	:   std_logic_vector (31 downto 0);
    signal add_carry    :   std_logic;
    signal sub_carry    :   std_logic;
    signal add_overflow	:   std_logic;
    signal sub_overflow	:   std_logic;
    signal aluout_temp    :    std_logic_vector (31 downto 0);
    signal less_than	:   std_logic;

    constant c		:   std_logic := '0';
    constant one	:   std_logic := '1';

    component SLL32bit
	port(	A	: in	std_logic_vector (31 downto 0);
		B	: in	std_logic_vector (4 downto 0);
		Y	: out	std_logic_vector (31 downto 0) );
    end component;

    component SRL32bit
	port(	A	: in	std_logic_vector (31 downto 0);
		B	: in	std_logic_vector (4 downto 0);
		Y	: out	std_logic_vector (31 downto 0) );
    end component;

    component fulladder32bit
	port(	A32, B32	: in std_logic_vector(31 downto 0);
		Cin32		: in std_logic;
		S32		: out std_logic_vector(31 downto 0);
		Cout32		: out std_logic);
    end component;

begin

    -- SLL - Shift Left Logical
    --=========================

    sll32: SLL32bit port map (	A => A,
				B => B(4 downto 0),
				Y => out_i(0) );


    -- SRL - Shift Right Logical
    --==========================

    srl32: SRL32bit port map (	A => A,
				B => B(4 downto 0),
				Y => out_i(1) );

    -- add
    --====
    sum: fulladder32bit port map (	A32 => A,
					B32 => B,
					Cin32 => c,
					S32 => out_i(2),
					Cout32 => add_carry );

    -- subtract
    --=========
    not_B <= not(B);
    subtraction: fulladder32bit port map (	A32 => A,
						B32 => not_B,
						Cin32 => one,
						S32 => out_i(3),
						Cout32 => sub_carry );

    -- and
    out_i(4) <= A and B;

    -- nor
    out_i(5) <= A nor B;

    -- or
    out_i(6) <= A or B;

    -- xor
    out_i(7) <= A xor B;

    -- slt
    -- detect less-than (A < B) (when subtract output is negative and no overflow)
    less_than <= out_i(3)(31) and not sub_overflow;
    out_i(8) <= x"00000001" when (less_than = '1') else x"00000000";

    -- sltu
    -- detect less-than (A < B) unsigned (when subtract output is negative, don't care for overflow)
--    less_than <= '1' when (out_i(3)(31) = '1') else '0';
    out_i(9) <= x"00000001" when (sub_overflow = '1') else x"00000000";

	--LUI
	out_i(10) <= B(31 downto 0); --lui		
    -- output multiplexer
    with opcode select
        aluout_temp <=    out_i(0) when "0000",
                          out_i(1) when "0001",
                          out_i(2) when "0010",
                          out_i(3) when "0011",
                          out_i(4) when "0100",
                          out_i(5) when "0101",
                          out_i(6) when "0110",
                          out_i(7) when "0111",
			  out_i(8) when "1000",
			  out_i(9) when "1001",
			out_i(10) when "1010",	
			  BAD1 when others;


    -- detect overflow
    add_overflow <= (not A(31) and not B(31) and aluout_temp(31)) or (A(31) and B(31) and not aluout_temp(31));
    sub_overflow <= (not A(31) and B(31) and aluout_temp(31)) or (A(31) and not B(31) and not aluout_temp(31));
    with opcode select
	overflow <=	add_overflow when "0010",
			sub_overflow when "0011",
			'0' when others;

    -- detect negative
    negative <= aluout_temp(31);

    -- detect zero
	
    with aluout_temp select
        zero <=    '1' when x"00000000",
                   '0' when others;

    -- detect equal (check if A xor B is zero)
    equal <= '1' when (out_i(7) = x"00000000") else '0';

    aluout <= aluout_temp;

end alu_arch;
