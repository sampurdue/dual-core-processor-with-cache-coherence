-- $Id: $
-- File name:   tb_alu.vhd
-- Created:     8/29/2012
-- Author:      Siddhesh Rajan Dhupe
-- Lab Section: Wednesday 77:30-10:20
-- Version:     1.0  Initial Test Bench

library ieee;
--library gold_lib;   --UNCOMMENT if you're using a GOLD model
use ieee.std_logic_1164.all;
--use gold_lib.all;   --UNCOMMENT if you're using a GOLD model
use IEEE.STD_LOGIC_TEXTIO.all;
use STD.TEXTIO.all;

entity tb_alu is
end tb_alu;

architecture TEST of tb_alu is

  function INT_TO_STD_LOGIC( X: INTEGER; NumBits: INTEGER )
     return STD_LOGIC_VECTOR is
    variable RES : STD_LOGIC_VECTOR(NumBits-1 downto 0);
    variable tmp : INTEGER;
  begin
    tmp := X;
    for i in 0 to NumBits-1 loop
      if (tmp mod 2)=1 then
        res(i) := '1';
      else
        res(i) := '0';
      end if;
      tmp := tmp/2;
    end loop;
    return res;
  end;

  component alu
    PORT(
         opcode : in std_logic_vector (3 downto 0);
         A : in std_logic_vector (31 downto 0);
         B : in std_logic_vector (31 downto 0);
         aluout : out std_logic_vector (31 downto 0);
         negative : out std_logic;
         overflow : out std_logic;
         zero : out std_logic
    );
  end component;

-- Insert signals Declarations here
  signal opcode : std_logic_vector (3 downto 0);
  signal A : std_logic_vector (31 downto 0);
  signal B : std_logic_vector (31 downto 0);
  signal aluout : std_logic_vector (31 downto 0);
  signal negative : std_logic;
  signal overflow : std_logic;
  signal zero : std_logic;

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

begin
  DUT: alu port map(
                opcode => opcode,
                A => A,
                B => B,
                aluout => aluout,
                negative => negative,
                overflow => overflow,
                zero => zero
                );

--   GOLD: <GOLD_NAME> port map(<put mappings here>);

process

  begin

    wait for 50 ns;

    -- test SLL
    opcode <= "0000";
    A <= v6;
    B <= V8;

    wait for 50 ns;

    -- test SRL
    opcode <= "0001";
    A <= v6;
    B <= V8;

    wait for 50 ns;

    -- test add 1
    opcode <= "0010";
    A <= v2;
    B <= v3;

    wait for 50 ns;

    -- test add 2
    opcode <= "0010";
    A <= v5;
    B <= v6;

    wait for 50 ns;

    -- test add 3
    opcode <= "0010";
    A <= v11;
    B <= v12;

    wait for 50 ns;

    -- test add 4
    opcode <= "0010";
    A <= v9;
    B <= v10;

    wait for 50 ns;

    -- test subtract 1
    opcode <= "0011";
    A <= v2;
    B <= v3;

    wait for 50 ns;

    -- test subtract 2
    opcode <= "0011";
    A <= v5;
    B <= v6;

    wait for 50 ns;

    -- test subtract 3
    opcode <= "0011";
    A <= v6;
    B <= v7;

    wait for 50 ns;

    -- test subtract 4
    opcode <= "0011";
    A <= v11;
    B <= v12;

    wait for 50 ns;

    -- test and
    opcode <= "0100";
    A <= v6;
    B <= z;

    wait for 50 ns;

    -- test nor
    opcode <= "0101";
    A <= v6;
    B <= v7;

    wait for 50 ns;

    -- test or
    opcode <= "0110";
    A <= v4;
    B <= v5;

    wait for 50 ns;

    -- test xor
    opcode <= "0111";
    A <= v6;
    B <= v7;

    wait for 50 ns;

    -- test slt
    opcode <= "1000";
    A <= v4;
    B <= v6;

    wait for 50 ns;

    -- test sltu
    opcode <= "1001";
    A <= v4;
    B <= v6;

    -- end simulation
    wait;
  end process;
end TEST;
