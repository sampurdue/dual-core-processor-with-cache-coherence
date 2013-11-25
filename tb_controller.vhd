-- $Id: $
-- File name:   tb_controller.vhd
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

entity tb_controller is
end tb_controller;

architecture TEST of tb_controller is

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

  component controller
	port
	(
		instr		:	in	std_logic_vector (31 downto 0);
		Equal		:	in	std_logic;
		PCSrc		:	out	std_logic;
		RegWr		:	out	std_logic;
		RegDst		:	out	std_logic;
		ExtOp		:	out	std_logic;
		ALUSrc		:	out	std_logic;
		ALUOp		:	out	std_logic_vector (2 downto 0);
		MemWr		:	out	std_logic;
		MemtoReg	:	out	std_logic;
		Jump		:	out	std_logic
	);
  end component;

-- Insert signals Declarations here
	signal	instr		:	std_logic_vector (31 downto 0);
	signal	Equal		:	std_logic;
	signal	PCSrc		:	std_logic;
	signal	RegWr		:	std_logic;
	signal	RegDst		:	std_logic;
	signal	ExtOp		:	std_logic;
	signal	ALUSrc		:	std_logic;
	signal	ALUOp		:	std_logic_vector (2 downto 0);
	signal	MemWr		:	std_logic;
	signal	MemtoReg	:	std_logic;
	signal	Jump		:	std_logic;

-- signal <name> : <type>;
  constant z    : std_logic_vector := "00000000000000000000000000000000";
  constant v1   : std_logic_vector := x"341D4000";
  constant v2   : std_logic_vector := x"3403000F";
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
  	myController: controller port map (	instr		=> instr,
						Equal		=> Equal,
						PCSrc		=> PCSrc,
						RegWr		=> RegWr,
						RegDst		=> RegDst,
						ExtOp		=> ExtOp,
						AluSrc		=> AluSrc,
						AluOp		=> AluOp,
						MemWr		=> MemWr,
						MemtoReg	=> MemtoReg,
						Jump		=> Jump);

--   GOLD: <GOLD_NAME> port map(<put mappings here>);

process

  begin

    wait for 50 ns;

    instr <= v1;
    Equal <= '0';

    wait for 50 ns;

    instr <= v2;
    Equal <= '1';

    -- end simulation
    wait;
  end process;
end TEST;
