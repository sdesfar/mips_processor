-------------------------------------------------------------------------------
-- Title      : Memory that is simulated with predefined values
-- Project    : Source files in two directories, custom library name, VHDL'87
-------------------------------------------------------------------------------
-- File       : Simulated_Memory.vhd
-- Author     : Robert Jarzmik  <robert.jarzmik@free.fr>
-- Company    : 
-- Created    : 2016-11-20
-- Last update: 2016-11-20
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
  type memory is array(0 to 15) of std_logic_vector(DATA_WIDTH - 1 downto 0);
  constant rom : memory := (
    X"2C820002",  --  0:        2c820002        sltiu   v0,a0,2
    X"1440000B",  --  4:        1440000b        bnez    v0,34 <fibo_flat+0x34>
    x"24030001",  --  8:        24030001        li      v1,1
    x"00003021",  --  c:        00003021        move    a2,zero
    x"08000007",  -- 10:        08000007        j       1c <fibo_flat+0x1c>
    x"24050001",  -- 14:        24050001        li      a1,1
    x"00402821",  -- 18:        00402821        move    a1,v0
    x"24630001",  -- 1c:        24630001        addiu   v1,v1,1
    X"00C51021",  -- 20:        00c51021        addu    v0,a2,a1
    X"1464FFFC",  -- 24:        1464fffc        bne     v1,a0,18 <fibo_flat+0x18>
    X"00A03021",  -- 28:        00a03021        move    a2,a1
    X"03E00008",  -- 2c:        03e00008        jr      ra
    x"00200825",  -- 30:        00200825        move    at,at
    X"03E00008",  -- 34:        03e00008        jr      ra
    x"00801021",  -- 38:        00801021        move    v0,a0
    x"00000000"
    );

begin  -- architecture rtl
  -----------------------------------------------------------------------------
  -- Component instantiations
  -----------------------------------------------------------------------------

  process(rst, clk)
    variable clk_req : natural := 0;
  begin
    if rst = '0' and i_memory_req = '1' then
      if rising_edge(clk) then
        if i_memory_req = '1' then
          clk_req := clk_req + 1;
        end if;

        if clk_req >= MEMORY_LATENCY then
          clk_req            := 0;
          o_memory_read_data <= rom(to_integer(unsigned(i_memory_addr)) / 4);
          o_memory_valid     <= '1';
        end if;
      end if;
    end if;
  end process;

end architecture rtl;

-------------------------------------------------------------------------------
