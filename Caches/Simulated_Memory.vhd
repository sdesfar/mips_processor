-------------------------------------------------------------------------------
-- Title      : Memory that is simulated with predefined values
-- Project    : Source files in two directories, custom library name, VHDL'87
-------------------------------------------------------------------------------
-- File       : Simulated_Memory.vhd
-- Author     : Robert Jarzmik  <robert.jarzmik@free.fr>
--            : Simon Desfarges <simon.desfarges@free.fr>
-- Company    : 
-- Created    : 2016-11-20
-- Last update: 2016-11-30
-- Platform   : 
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: Simulates a constant latency memory.
--              The memory content is loaded from a file, with init_ram(), and
--              that part requires VHDL 2008 compliance.
--              If the rom is hard encoded in this file, the file should be
--              VHDL'93 compliant.
--
--              It is assumed that a "memory_data.txt" file is available, and
--              that is contains lines of data as would have been generated by
--              hexdump -e '"%08x\n"' bin_opcodes.raw > memory_data.txt
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-11-20  1.0      rj      Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

-------------------------------------------------------------------------------

entity Simulated_Memory is

  generic (
    ADDR_WIDTH        : integer := 32;
    DATA_WIDTH        : integer := 32;
    MEMORY_LATENCY    : natural := 1;
    MEMORY_ADDR_WIDTH : natural := 5;
    MEMORY_FILE       : string  := "memory_data.txt"
    );

  port (
    clk : in std_logic;
    rst : in std_logic;

    i_memory_req        : in  std_logic;
    i_memory_we         : in  std_logic;
    i_memory_addr       : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
    i_memory_write_data : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
    o_memory_read_data  : out std_logic_vector(DATA_WIDTH - 1 downto 0);
    o_memory_valid      : out std_logic
    );

end entity Simulated_Memory;

-------------------------------------------------------------------------------

architecture rtl of Simulated_Memory is

  -----------------------------------------------------------------------------
  -- Internal signal declarations
  -----------------------------------------------------------------------------
  type memory is array(0 to 2**MEMORY_ADDR_WIDTH - 1) of
    std_logic_vector(DATA_WIDTH - 1 downto 0);
--constant rom : memory := (
--    x"24040011",  --   0:       24040011        li      a0,17
--    x"2c820002",  --   4:       2c820002        sltiu   v0,a0,2
--    x"1440000b",  --   8:       1440000b        bnez    v0,38 <fibo_flat+0x38>
--    x"24030001",  --   c:       24030001        li      v1,1
--    x"00003021",  --  10:       00003021        move    a2,zero
--    x"08000008",  --  14:       08000008        j       20 <fibo_flat+0x20>
--    x"24050001",  --  18:       24050001        li      a1,1
--    x"00402821",  --  1c:       00402821        move    a1,v0
--    x"24630001",  --  20:       24630001        addiu   v1,v1,1
--    x"00c51021",  --  24:       00c51021        addu    v0,a2,a1
--    x"1483fffc",  --  28:       1483fffc        bne     a0,v1,1c <fibo_flat+0x1c>
--    x"00a03021",  --  2c:       00a03021        move    a2,a1
--    x"03e00008",  --  30:       03e00008        jr      ra
--    x"00200825",  --  34:       00200825        move    at,at
--    x"03e00008",  --  38:       03e00008        jr      ra
--    x"00801021",  --  3c:       00801021        move    v0,a0
--    others => (others => '0')
--    );

  signal request_addr_valid : boolean := false;
  signal request_addr       : std_logic_vector(ADDR_WIDTH - 1 downto 0);
  signal requested          : boolean := false;

  signal memory_read_data : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal memory_valid     : std_logic;

  impure function init_ram(FileName : string)
    return memory is

    variable tmp         : memory := (others => (others => '0'));
    file FileHandle      : text open read_mode is FileName;
    variable CurrentLine : line;
    variable TempWord    : bit_vector(DATA_WIDTH - 1 downto 0);
    variable good        : boolean;

  begin
    for addr_pos in 0 to 2**MEMORY_ADDR_WIDTH - 1 loop
      exit when endfile(FileHandle);

      good := false;
      while not good and not endfile(FileHandle) loop
        readline(FileHandle, CurrentLine);
        hread(CurrentLine, TempWord, good);
      end loop;

      tmp(addr_pos) := To_StdLogicVector(TempWord);
    end loop;
    return tmp;
  end init_ram;
  signal rom : memory := init_ram(MEMORY_FILE);

begin  -- architecture rtl

  -----------------------------------------------------------------------------
  -- Component instantiations
  -----------------------------------------------------------------------------
  process(rst, clk)
    variable wait_clk : natural := 0;
  begin
    if rst = '1' then
      memory_read_data <= (others => 'X');
      memory_valid     <= '0';
    elsif rising_edge(clk) and MEMORY_LATENCY > 0 then
      if i_memory_req = '1' and (not request_addr_valid or i_memory_addr /= request_addr) then
        wait_clk           := MEMORY_LATENCY - 1;
        request_addr       <= i_memory_addr;
        request_addr_valid <= true;
        requested          <= true;
        if MEMORY_LATENCY > 1 then
          memory_valid <= '0';
        else
          memory_valid <= '1';
        end if;
        memory_read_data <= (others => 'X');
      elsif i_memory_req = '1' and (not request_addr_valid or i_memory_addr = request_addr) then
      end if;

      if requested and wait_clk > 0 then
        wait_clk := wait_clk - 1;
      end if;

      if requested and wait_clk = 0 then
        requested <= false;
        memory_read_data <=
          rom(to_integer(unsigned(request_addr)) / (DATA_WIDTH / 8));
        memory_valid <= '1';
      end if;
    end if;
  end process;

  o_memory_valid     <= memory_valid     when (MEMORY_LATENCY > 0) else '1';
  o_memory_read_data <= memory_read_data when (MEMORY_LATENCY > 1) else
                        rom(to_integer(unsigned(request_addr)) / (DATA_WIDTH / 8)) when (MEMORY_LATENCY = 1) else
                        rom(to_integer(unsigned(i_memory_addr)) / (DATA_WIDTH / 8));
end architecture rtl;

-------------------------------------------------------------------------------
