library ieee;
use std.textio.all;
use ieee.std_logic_textio.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_cpu is
  generic (Period : Time := 100 ns;
             Debug : Boolean := False);
end tb_cpu;

architecture tb_arch of tb_cpu is

  -- cpu
  component cpu
    port(
      -- begin ports needed for synthesis testing
      -- altera_reserved_tms  :   in  std_logic;
      -- altera_reserved_tck  :   in  std_logic;
      -- altera_reserved_tdi  :   in  std_logic;
      -- end ports needed for synthesis testing
      -- clock signal
      cpuClk :    in  std_logic;
      -- clock signal
      ramClk :    in  std_logic;
      -- reset for processor
      nReset :    in  std_logic;
      -- halt for processor
      halt :    out std_logic;
      -- start mmio addins
      -- dip switch in
      dipIn :   in  std_logic_vector(15 downto 0);
      -- hexout
      hexOut :    out std_logic_vector(31 downto 0);
      -- end mmio addins
      -- memory address to dump
      dumpAddr : in std_logic_vector(15 downto 0);
      memNReset : in std_logic;
      -- mux signal to arbitrate control of mem between cpu and tb.  '1' means tb
      memCtl : in std_logic;
      -- mem write enable
      memWen : in std_logic;
      -- mem address
      memAddr : in std_logic_vector(15 downto 0);
      -- mem data
      memData :in std_logic_vector(63 downto 0);
      -- Mem read for dumping
      memQ : out std_logic_vector(63 downto 0);
      -- View of address and write_en for write snooping
      viewMemAddr : out std_logic_vector(15 downto 0);
      viewMemWen : out std_logic
    );
  end component; 

-- converts a hex string to a std_logic_vector
function str_to_std_logic_vector (s : string) return std_logic_vector is
    variable vec : std_logic_vector(4 * (s'high - s'low) + 3 downto 0);
    variable tmp : std_logic_vector(3 downto 0);
    variable j : integer;
begin
    for i in 0 to s'high - s'low loop
        case s(i + s'low) is
            when '0' =>
                tmp := X"0";
            when '1' =>
                tmp := X"1";
            when '2' =>
                tmp := X"2";
            when '3' =>
                tmp := X"3";
            when '4' =>
                tmp := X"4";
            when '5' =>
                tmp := X"5";
            when '6' =>
                tmp := X"6";
            when '7' =>
                tmp := X"7";
            when '8' =>
                tmp := X"8";
            when '9' =>
                tmp := X"9";
            when 'A' =>
                tmp := X"A";
            when 'B' =>
                tmp := X"B";
            when 'C' =>
                tmp := X"C";
            when 'D' =>
                tmp := X"D";
            when 'E' =>
                tmp := X"E";
            when 'F' =>
                tmp := X"F";
            when others =>
                tmp := X"0";
        end case;
        j := s'high - s'low - i;
        vec((j + 1) * 4 - 1 downto j * 4) := tmp;
    end loop;
    return vec;
end str_to_std_logic_vector;

type boolArray is array(0 to 8191) of boolean;


  -- signals here
  signal clk, cpuClk, initClkCtl, dumpClkCtl, cpuClkCtl, nReset, memNReset, halt : std_logic;
  signal memQ : std_logic_vector(63 downto 0);
  signal hexOut : std_logic_vector(31 downto 0);
  -- supply address that we want to dump
  signal address, viewMemAddr : std_logic_vector(15 downto 0);
  signal dipIn :  std_logic_vector(15 downto 0);
  signal viewMemWen : std_logic;
  signal myMemCtl : std_logic;
  signal myMemWen : std_logic;
  signal myMemAddr : std_logic_vector(15 downto 0);
  signal myMemData : std_logic_vector(63 downto 0);
  signal writeTrack : boolArray;

begin

  DUT: cpu port map(
      -- begin ports needed for synthesis testing
      -- altera_reserved_tms  =>  '0',
      -- altera_reserved_tck  =>  '0',
      -- altera_reserved_tdi  =>  '0',
      -- end ports needed for synthesis testing
      cpuClk => cpuClk,
      ramClk => clk,
      nReset => nReset,
      halt => halt,
      dipIn => dipin,
      hexOut => hexout,
      dumpAddr => address,
      memNReset => memNReset,
      memCtl => myMemCtl,
      memWen => myMemWen,
      memAddr => myMemAddr,
      memData => myMemData,
      memQ => memQ,
      viewMemAddr => viewMemAddr,
      viewMemWen => viewMemWen);


  -- generate clock signal
  clkgen: process
    variable clk_tmp : std_logic := '0';
  begin
    clk_tmp := not clk_tmp;
    clk <= clk_tmp;
    wait for Period/2;
  end process;

  -- print cycles for execution
  printprocess : process
    variable cycles : integer := 0;
    variable lout : line;
  begin
    if (nreset = '1') then
        cycles := cycles + 1;
        if (cycles mod 32 = 0) then
            write(lout, string'("Cycle #"));
            write(lout, integer'(cycles));
            writeline(output, lout);
        end if;
    end if;
    if (halt = '1') then
      write(lout, string'("Halted, cycles="));
      write(lout, integer'(cycles));
      writeline(output, lout);
      wait on halt;
    end if;
    wait for Period;
  end process;

  -- initializes memory from meminit.hex, then monitors memory for writes
  testing_process : process 
    file my_input : text;
    variable line_in : line;
    variable line_in1 : line;
    variable line_out : line;
    variable i : integer := 0;
    variable j : integer := 0;
    variable save_line : integer := 0;
    variable dummy1_s0 : string(1 to 3);
    variable address_s0 : string(1 to 4);
    variable dummy2_s0 : string(1 to 2);
    variable data_s0 : string(1 to 8);
    variable dummy1_s1 : string(1 to 3);
    variable address_s1 : string(1 to 4);
    variable dummy2_s1 : string(1 to 2);
    variable data_s1 : string(1 to 8);
    variable tmp : std_logic_vector(63 downto 0);
    
    begin
      nReset <= '0';
      memNReset <= '0';
      wait for 2 * Period;
      memNReset <= '1';
      write(line_out, string'("starting memory initialization"));
      writeline(OUTPUT, line_out);
      initClkCtl <= '1';
      myMemCtl <= '1';
      myMemWen <= '1';
      -- open meminit.hex for reading
      file_open(my_input, "meminit.hex", read_mode);
      while not endfile(my_input) loop
        if (save_line = 1) then
            dummy1_s0 := dummy1_s1;
            address_s0 := address_s1;
            dummy2_s0 := dummy2_s1;
            data_s0 := data_s1;
            save_line := 0;
          else
            readline(my_input, line_in);
            read(line_in, dummy1_s0);
            read(line_in, address_s0);
            read(line_in, dummy2_s0);
            read(line_in, data_s0);
          end if;

          if (dummy1_s0 /= ":04") then
              exit;
          end if;

          -- set address
          myMemAddr <= str_to_std_logic_vector(address_s0)(13 downto 0) & "00";
          myMemData <= x"00000000" & str_to_std_logic_vector(data_s0);
          if (str_to_std_logic_vector(address_s0)(0) = '1') then
            myMemData <= str_to_std_logic_vector(data_s0) & x"00000000";
          elsif (not endfile(my_input)) then
            readline(my_input, line_in1);
            read(line_in1, dummy1_s1);
            read(line_in1, address_s1);
            read(line_in1, dummy2_s1);
            read(line_in1, data_s1);
            if (dummy1_s1 = ":04" and (str_to_std_logic_vector(address_s1)(13 downto 1) = str_to_std_logic_vector(address_s0)(13 downto 1))) then
              myMemData <= str_to_std_logic_vector(data_s1) & str_to_std_logic_vector(data_s0);
            else
              save_line := 1;
            end if;
          end if;

          -- give address time to output
          wait for Period;
          if (Debug) then
              write(line_out, string'("Writing value "));
              write(line_out, data_s0);
              write(line_out, string'(" ("));
              hwrite(line_out, myMemData);
              write(line_out, string'(") "));
              write(line_out, string'(" to address "));
              write(line_out, address_s0);
              write(line_out, string'(" ("));
              hwrite(line_out, myMemAddr);
              write(line_out, string'(") "));
              writeline(output, line_out);
            end if;
            wait for Period;
            end loop;

            -- close file
            file_close(my_input);
            -- so we don't keep looping
            write(line_out, string'("initialized memory"));
            writeline(OUTPUT, line_out);
            initClkCtl <= '0';
            myMemCtl <= '0';
            myMemWen <= '0';
            wait for 4 * Period;
            nReset <= '1';
            wait;
    end process;

    track_writes: process
    begin
        for i in 0 to 8191 loop
            writeTrack(i) <= false;
        end loop;
        while (halt /= '1') loop
            wait for Period;
            if (viewMemWen = '1') then
                writeTrack(to_integer(unsigned(viewMemAddr(15 downto 2)))) <= true;
            end if;
        end loop;
        wait;
    end process;
  
  -- dumps memory to file
  -- change memout and address to reflect component and portmap
  -- also change filename for output if necessary
  dump_mem: process 
    file my_output : text;
    variable lout : line;
    variable my_line : line;
    variable my_output_line : line;
    variable i : integer := 0;
    variable j : integer := 0;
    variable field1 : integer := 0;
    variable field2 : integer := 0;
    variable field3 : integer := 0;
    variable field4 : integer := 0;
    variable field5 : integer := 0;
    variable field6 : integer := 0;
    variable field7 : integer := 0;
    variable field8 : integer := 0;
    variable checksum : integer := 0;
    variable tmp : std_logic_vector(63 downto 0);
    
    begin
      address <= x"0000";
      dumpClkCtl <= '0';
      wait on halt;
      if (halt = '1') then
        -- open file for writing you may change filename
        file_open(my_output, "memout.hex", write_mode);
        -- set address
        address <= std_logic_vector(to_unsigned(0, 16));
        -- give address time to output
        wait for Period;
        -- pipeline change this value to 8191
        -- single cycle change this value to 4095
        -- for each spot in memory loop
        for i in 0 to 8191 loop
          -- fix address translation
          j := i*4;
          if (j mod 512 = 0) then
            write(lout, string'("writing address "));
            write(lout, integer'(j));
            writeline(output, lout);
          end if;
          if (not writeTrack(i)) then
            next;
          end if;
          -- assign address
          address <= std_logic_vector(to_unsigned(j, 16));
          -- wait for output
          wait for Period*2;
          -- check if output has value
          if (Debug) then
              write(lout, string'("Found data "));
              hwrite(lout, memQ);
              write(lout, string'(" at addr "));
              hwrite(lout, address);
              writeline(output, lout);
            end if;
          if (memQ(31 downto 0) /= x"00000000" and address(2) = '0') then
            -- temp string so we can add 2 digit hex values for checksum
            tmp := x"04" & std_logic_vector(to_unsigned(i, 16)) & x"00" & memQ(31 downto 0);
            -- fields of 2 digit hex values
            field1 := to_integer(unsigned(tmp(63 downto 56)));
            field2 := to_integer(unsigned(tmp(55 downto 48)));
            field3 := to_integer(unsigned(tmp(47 downto 40)));
            field4 := to_integer(unsigned(tmp(39 downto 32)));
            field5 := to_integer(unsigned(tmp(31 downto 24)));
            field6 := to_integer(unsigned(tmp(23 downto 16)));
            field7 := to_integer(unsigned(tmp(15 downto 8)));
            field8 := to_integer(unsigned(tmp(7 downto 0)));
            -- compute checksum add fields
            checksum := field1 + field2 + field3 + field4 + field5 + field6 + field7 + field8;
            -- subtract from 0x100
            checksum := 16#100# - checksum;
            -- start outputing intel hex fields
            -- start character
            write(my_line, ':');
            -- size of data
            hwrite(my_line, std_logic_vector(to_unsigned(4, 8)));
            -- address
            hwrite(my_line, std_logic_vector(to_unsigned(i, 16)));
            -- type of data
            hwrite(my_line, std_logic_vector(to_unsigned(0, 8)));
            -- data at address
            hwrite(my_line, memQ(31 downto 0));
            -- checksum
            hwrite(my_line, std_logic_vector(to_unsigned(checksum mod 256,8)));
            -- write to file
            writeline(my_output, my_line);
          end if;
          if (memQ(63 downto 32) /= x"00000000" and address(2) = '0') then
            -- temp string so we can add 2 digit hex values for checksum
            tmp := x"04" & std_logic_vector(to_unsigned(i+1, 16)) & x"00" & memQ(63 downto 32);
            -- fields of 2 digit hex values
            field1 := to_integer(unsigned(tmp(63 downto 56)));
            field2 := to_integer(unsigned(tmp(55 downto 48)));
            field3 := to_integer(unsigned(tmp(47 downto 40)));
            field4 := to_integer(unsigned(tmp(39 downto 32)));
            field5 := to_integer(unsigned(tmp(31 downto 24)));
            field6 := to_integer(unsigned(tmp(23 downto 16)));
            field7 := to_integer(unsigned(tmp(15 downto 8)));
            field8 := to_integer(unsigned(tmp(7 downto 0)));
            -- compute checksum add fields
            checksum := field1 + field2 + field3 + field4 + field5 + field6 + field7 + field8;
            -- subtract from 0x100
            checksum := 16#100# - checksum;
            -- start outputing intel hex fields
            -- start character
            write(my_line, ':');
            -- size of data
            hwrite(my_line, std_logic_vector(to_unsigned(4, 8)));
            -- address
            hwrite(my_line, std_logic_vector(to_unsigned(i+1, 16)));
            -- type of data
            hwrite(my_line, std_logic_vector(to_unsigned(0, 8)));
            -- data at address
            hwrite(my_line, memQ(63 downto 32));
            -- checksum
            hwrite(my_line, std_logic_vector(to_unsigned(checksum mod 256,8)));
            -- write to file
            writeline(my_output, my_line);
          end if;
          -- wait rest of clock cycle
          wait for Period;
        end loop;
        -- write last line of hex file
        write(my_line, ':');
        hwrite(my_line, std_logic_vector(to_unsigned(0,8)));
        hwrite(my_line, std_logic_vector(to_unsigned(0,16)));
        hwrite(my_line, std_logic_vector(to_unsigned(1,8)));
        hwrite(my_line, std_logic_vector(to_unsigned(255,8)));
        writeline(my_output, my_line);
        -- close file
        file_close(my_output);
        -- so we don't keep looping
        write(my_line, string'("dumped memory"));
        writeline(OUTPUT, my_line);
            dumpClkCtl <= '1';
        wait;
      end if; -- end if halt
    end process;

    cpuClkCtl <= dumpClkCtl or initClkCtl;
    with cpuClkCtl select
      cpuClk <= '0' when '1',
      clk when others;
end tb_arch;
