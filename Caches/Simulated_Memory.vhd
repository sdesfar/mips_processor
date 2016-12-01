-------------------------------------------------------------------------------
-- Title      : Memory that is simulated with predefined values
-- Project    : Source files in two directories, custom library name, VHDL'87
-------------------------------------------------------------------------------
-- File       : Simulated_Memory.vhd
-- Author     : Robert Jarzmik  <robert.jarzmik@free.fr>
-- Company    : 
-- Created    : 2016-11-20
-- Last update: 2016-11-30
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
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

-------------------------------------------------------------------------------

entity Simulated_Memory is

  generic (
    ADDR_WIDTH     : integer := 32;
    DATA_WIDTH     : integer := 32;
    MEMORY_LATENCY : natural := 1
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
  type memory is array(0 to 31) of std_logic_vector(DATA_WIDTH - 1 downto 0);
  constant rom : memory := (
    x"24040011",  --   0:       24040011        li      a0,17
    x"2c820002",  --   4:       2c820002        sltiu   v0,a0,2
    x"1440000b",  --   8:       1440000b        bnez    v0,38 <fibo_flat+0x38>
    x"24030001",  --   c:       24030001        li      v1,1
    x"00003021",  --  10:       00003021        move    a2,zero
    x"08000008",  --  14:       08000008        j       20 <fibo_flat+0x20>
    x"24050001",  --  18:       24050001        li      a1,1
    x"00402821",  --  1c:       00402821        move    a1,v0
    x"24630001",  --  20:       24630001        addiu   v1,v1,1
-- RAW dependency on instruction @0x1c on register a1
    x"00c51021",  --  24:       00c51021        addu    v0,a2,a1
-- RAW dependency on instruction @0x20 on register v1
    x"1483fffc",  --  28:       1483fffc        bne     a0,v1,1c <fibo_flat+0x1c>
    x"00a03021",  --  2c:       00a03021        move    a2,a1
    x"03e00008",  --  30:       03e00008        jr      ra
    x"00200825",  --  34:       00200825        move    at,at
    x"03e00008",  --  38:       03e00008        jr      ra
    x"00801021",  --  3c:       00801021        move    v0,a0
    --std_logic_vector(to_unsigned(0, DATA_WIDTH - 8)) & std_logic_vector(to_unsigned(0 * DATA_WIDTH / 8, 8)),
    --std_logic_vector(to_unsigned(0, DATA_WIDTH - 8)) & std_logic_vector(to_unsigned(1 * DATA_WIDTH / 8, 8)),
    --std_logic_vector(to_unsigned(0, DATA_WIDTH - 8)) & std_logic_vector(to_unsigned(2 * DATA_WIDTH / 8, 8)),
    --std_logic_vector(to_unsigned(0, DATA_WIDTH - 8)) & std_logic_vector(to_unsigned(3 * DATA_WIDTH / 8, 8)),
    --std_logic_vector(to_unsigned(0, DATA_WIDTH - 8)) & std_logic_vector(to_unsigned(4 * DATA_WIDTH / 8, 8)),
    --std_logic_vector(to_unsigned(0, DATA_WIDTH - 8)) & std_logic_vector(to_unsigned(5 * DATA_WIDTH / 8, 8)),
    --std_logic_vector(to_unsigned(0, DATA_WIDTH - 8)) & std_logic_vector(to_unsigned(6 * DATA_WIDTH / 8, 8)),
    --std_logic_vector(to_unsigned(0, DATA_WIDTH - 8)) & std_logic_vector(to_unsigned(7 * DATA_WIDTH / 8, 8)),
    --std_logic_vector(to_unsigned(0, DATA_WIDTH - 8)) & std_logic_vector(to_unsigned(8 * DATA_WIDTH / 8, 8)),
    --std_logic_vector(to_unsigned(0, DATA_WIDTH - 8)) & std_logic_vector(to_unsigned(9 * DATA_WIDTH / 8, 8)),
    others => (others => '0')
    );

  signal request_addr_valid : boolean := false;
  signal request_addr       : std_logic_vector(ADDR_WIDTH - 1 downto 0);
  signal requested          : boolean := false;

  signal memory_read_data : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal memory_valid     : std_logic;

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
