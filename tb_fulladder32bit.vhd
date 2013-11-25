-- $Id: $
-- File name:   tb_fulladder32bit.vhd
-- Created:     8/30/2012
-- Author:      Siddhesh Rajan Dhupe
-- Lab Section: Wednesday 77:30-10:20
-- Version:     1.0  Initial Test Bench

library ieee;
--library gold_lib;   --UNCOMMENT if you're using a GOLD model
use ieee.std_logic_1164.all;
--use gold_lib.all;   --UNCOMMENT if you're using a GOLD model

entity tb_fulladder32bit is
end tb_fulladder32bit;

architecture TEST of tb_fulladder32bit is

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

  component fulladder32bit
    PORT(
         A32 : in std_logic_vector(31 downto 0);
         B32 : in std_logic_vector(31 downto 0);
         Cin32 : in std_logic;
         S32 : out std_logic_vector(31 downto 0);
         Cout32 : out std_logic
    );
  end component;

-- Insert signals Declarations here
  signal A32 : std_logic_vector(31 downto 0);
  signal B32 : std_logic_vector(31 downto 0);
  signal Cin32 : std_logic;
  signal S32 : std_logic_vector(31 downto 0);
  signal Cout32 : std_logic;

-- signal <name> : <type>;
  constant v1	: std_logic_vector	:= x"00000060";
  constant v2	: std_logic_vector	:= x"ABCD0F90";
  constant v3	: std_logic_vector	:= x"AABBC0B3";
  constant v4	: std_logic_vector	:= x"0007AA00";

begin
  DUT: fulladder32bit port map(
                A32 => A32,
                B32 => B32,
                Cin32 => Cin32,
                S32 => S32,
                Cout32 => Cout32
                );

--   GOLD: <GOLD_NAME> port map(<put mappings here>);

process

  begin

-- Insert TEST BENCH Code Here

    A32 <= v1;

    B32 <= v4;

    Cin32 <= '1';

    wait for 50 ns;

    A32 <= v2;

    B32 <= v3;

    Cin32 <= '0';

    wait for 50 ns;

    A32 <= v1;

    B32 <= v3;

    Cin32 <= '1';

    wait for 50 ns;

    A32 <= v2;

    B32 <= v4;

    Cin32 <= '0';

    wait;

  end process;
end TEST;
