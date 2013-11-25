-- $Id: $
-- File name:   tb_fulladder4bit.vhd
-- Created:     8/29/2012
-- Author:      Siddhesh Rajan Dhupe
-- Lab Section: Wednesday 77:30-10:20
-- Version:     1.0  Initial Test Bench

library ieee;
--library gold_lib;   --UNCOMMENT if you're using a GOLD model
use ieee.std_logic_1164.all;
--use gold_lib.all;   --UNCOMMENT if you're using a GOLD model

entity tb_fulladder4bit is
end tb_fulladder4bit;

architecture TEST of tb_fulladder4bit is

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

  component fulladder4bit
    PORT(
         A4 : in std_logic_vector(3 downto 0);
         B4 : in std_logic_vector(3 downto 0);
         Cin4 : in std_logic;
         S4 : out std_logic_vector(3 downto 0);
         Cout4 : out std_logic
    );
  end component;

-- Insert signals Declarations here
  signal A4 : std_logic_vector(3 downto 0);
  signal B4 : std_logic_vector(3 downto 0);
  signal Cin4 : std_logic;
  signal S4 : std_logic_vector(3 downto 0);
  signal Cout4 : std_logic;

-- signal <name> : <type>;

begin
  DUT: fulladder4bit port map(
                A4 => A4,
                B4 => B4,
                Cin4 => Cin4,
                S4 => S4,
                Cout4 => Cout4
                );

--   GOLD: <GOLD_NAME> port map(<put mappings here>);

process

  begin

-- Insert TEST BENCH Code Here

    A4 <= "0001";

    B4 <= "0010";

    Cin4 <= '1';

    wait for 50 ns;

    A4 <= "1001";

    B4 <= "0010";

    Cin4 <= '1';

    wait for 50 ns;

    A4 <= "1101";

    B4 <= "1010";

    Cin4 <= '0';

    wait for 50 ns;

    A4 <= "1001";

    B4 <= "0011";

    Cin4 <= '0';

    wait;

  end process;
end TEST;
