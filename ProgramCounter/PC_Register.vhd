-------------------------------------------------------------------------------
-- Title      : Program Counter
-- Project    : 
-------------------------------------------------------------------------------
-- File       : PC_Register.vhd
-- Author     : Robert Jarzmik  <robert.jarzmik@free.fr>
-- Company    : 
-- Created    : 2016-11-13
-- Last update: 2016-11-26
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: The MIPS processor program counter
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-11-13  1.0      rj      Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-------------------------------------------------------------------------------

entity PC_Register is

  generic (
    ADDR_WIDTH : integer := 32;
    STEP       : integer := 4
    );

  port (
    clk         : in  std_logic;
    rst         : in  std_logic;
    stall_pc    : in  std_logic;
    jump_pc     : in  std_logic;
    jump_target : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
    current_pc  : out std_logic_vector(ADDR_WIDTH - 1 downto 0);
    next_pc     : out std_logic_vector(ADDR_WIDTH - 1 downto 0)
    );

end entity PC_Register;

-------------------------------------------------------------------------------

architecture rtl of PC_Register is
  component PC_Adder is
    generic (
      ADDR_WIDTH : integer;
      STEP       : integer);
    port (
      current_pc : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
      next_pc    : out std_logic_vector(ADDR_WIDTH - 1 downto 0));
  end component PC_Adder;

  -----------------------------------------------------------------------------
  -- Internal signal declarations
  -----------------------------------------------------------------------------
  signal pc         : std_logic_vector(ADDR_WIDTH - 1 downto 0);
  signal pc_stepped : std_logic_vector(ADDR_WIDTH - 1 downto 0);

begin  -- architecture rtl

  -----------------------------------------------------------------------------
  -- Component instantiations
  -----------------------------------------------------------------------------
  pc_add4 : PC_Adder
    generic map (
      ADDR_WIDTH => ADDR_WIDTH,
      STEP       => STEP)
    port map (
      current_pc => pc,
      next_pc    => pc_stepped);

  process(clk, rst) is
  begin
    if rst = '1' then
      pc <= std_logic_vector(to_unsigned(0, ADDR_WIDTH));
    elsif rising_edge(clk) then
      if stall_pc = '1' then
        pc <= pc;
      elsif jump_pc = '1' then
        pc <= jump_target;
      else
        pc <= pc_stepped;
      end if;
    end if;
  end process;

  current_pc <= pc;
  next_pc    <= pc_stepped;

end architecture rtl;

-------------------------------------------------------------------------------
