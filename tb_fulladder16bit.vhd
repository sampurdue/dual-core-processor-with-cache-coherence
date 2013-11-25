-- $Id: $
-- File name:   tb_fulladder16bit.vhd
-- Created:     8/30/2012
-- Author:      Siddhesh Rajan Dhupe
-- Lab Section: Wednesday 77:30-10:20
-- Version:     1.0  Initial Test Bench

library ieee;
--library gold_lib;   --UNCOMMENT if you're using a GOLD model
use ieee.std_logic_1164.all;
--use gold_lib.all;   --UNCOMMENT if you're using a GOLD model

entity tb_fulladder16bit is
end tb_fulladder16bit;

architecture TEST of tb_fulladder16bit is

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

  component fulladder16bit
    PORT(
         A16 : in std_logic_vector(15 downto 0);
         B16 : in std_logic_vector(15 downto 0);
         Cin16 : in std_logic;
         S16 : out std_logic_vector(15 downto 0);
         Cout16 : out std_logic
    );
  end component;

-- Insert signals Declarations here
  signal A16 : std_logic_vector(15 downto 0);
  signal B16 : std_logic_vector(15 downto 0);
  signal Cin16 : std_logic;
  signal S16 : std_logic_vector(15 downto 0);
  signal Cout16 : std_logic;

-- signal <name> : <type>;
  constant v1	: std_logic_vector	:= x"0060";
  constant v2	: std_logic_vector	:= x"0F90";
  constant v3	: std_logic_vector	:= x"C0B3";
  constant v4	: std_logic_vector	:= x"AA00";

begin
  DUT: fulladder16bit port map(
                A16 => A16,
                B16 => B16,
                Cin16 => Cin16,
                S16 => S16,
                Cout16 => Cout16
                );

--   GOLD: <GOLD_NAME> port map(<put mappings here>);

process

  begin

-- Insert TEST BENCH Code Here

    A16 <= v1;

    B16 <= v2;

    Cin16 <= '1';

    wait for 50 ns;

    A16 <= v3;

    B16 <= v4;

    Cin16 <= '0';

    wait for 50 ns;

    A16 <= v1;

    B16 <= v3;

    Cin16 <= '1';

    wait for 50 ns;

    A16 <= v2;

    B16 <= v4;

    Cin16 <= '0';

    wait;

  end process;
end TEST;
