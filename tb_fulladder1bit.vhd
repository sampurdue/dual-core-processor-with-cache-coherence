-- $Id: $
-- File name:   tb_fulladder1bit.vhd
-- Created:     8/29/2012
-- Author:      Siddhesh Rajan Dhupe
-- Lab Section: Wednesday 77:30-10:20
-- Version:     1.0  Initial Test Bench

library ieee;
--library gold_lib;   --UNCOMMENT if you're using a GOLD model
use ieee.std_logic_1164.all;
--use gold_lib.all;   --UNCOMMENT if you're using a GOLD model

entity tb_fulladder1bit is
end tb_fulladder1bit;

architecture TEST of tb_fulladder1bit is

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

  component fulladder1bit
    PORT(
         A : in std_logic;
         B : in std_logic;
         Cin : in std_logic;
         S : out std_logic;
         Cout : out std_logic
    );
  end component;

-- Insert signals Declarations here
  signal A : std_logic;
  signal B : std_logic;
  signal Cin : std_logic;
  signal S : std_logic;
  signal Cout : std_logic;

-- signal <name> : <type>;

begin
  DUT: fulladder1bit port map(
                A => A,
                B => B,
                Cin => Cin,
                S => S,
                Cout => Cout
                );

--   GOLD: <GOLD_NAME> port map(<put mappings here>);

process

  begin

-- Insert TEST BENCH Code Here

    A <= '1';

    B <= '1';

    Cin <= '0';

    wait for 50 ns;

    A <= '1';

    B <= '1';

    Cin <= '1';

    wait for 50 ns;

    A <= '1';

    B <= '0';

    Cin <= '1';

    wait for 50 ns;

    A <= '0';

    B <= '0';

    Cin <= '1';

    wait;

  end process;
end TEST;
