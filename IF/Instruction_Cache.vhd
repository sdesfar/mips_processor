-------------------------------------------------------------------------------
-- Title      : Instruction Cache L1
-- Project    : 
-------------------------------------------------------------------------------
-- File       : Instruction_Cache.vhd
-- Author     : Robert Jarzmik  <robert.jarzmik@free.fr>
-- Company    : 
-- Created    : 2016-11-10
-- Last update: 2016-11-12
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Level 1 cache for instruction fetch
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-11-10  1.0      rj      Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-------------------------------------------------------------------------------

entity Instruction_Cache is

  generic (
    ADDR_WIDTH : integer := 32;
    DATA_WIDTH : integer := 32
    );

  port (
    clk  : in  std_logic;
    pc   : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
    data : out std_logic_vector(DATA_WIDTH -1 downto 0)
    );

end entity Instruction_Cache;

-------------------------------------------------------------------------------

architecture rtl of Instruction_Cache is

  -----------------------------------------------------------------------------
  -- Internal signal declarations
  -----------------------------------------------------------------------------

  type memory is array(0 to 4) of std_logic_vector(DATA_WIDTH - 1 downto 0);
  constant rom : memory := (
    x"00000000",
    x"20050004",
    x"00000008",
    x"0000000c",
    x"00000010"
    );

begin  -- architecture rtl

  -----------------------------------------------------------------------------
  -- Component instantiations
  -----------------------------------------------------------------------------

  process(pc)
  begin
      data <= rom(to_integer(unsigned(pc)) / 4);
  end process;

end architecture rtl;

-------------------------------------------------------------------------------
