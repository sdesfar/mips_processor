-------------------------------------------------------------------------------
-- Title      : Instruction Cache L1
-- Project    : 
-------------------------------------------------------------------------------
-- File       : Instruction_Cache.vhd
-- Author     : Robert Jarzmik  <robert.jarzmik@free.fr>
-- Company    : 
-- Created    : 2016-11-10
-- Last update: 2016-11-26
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
    clk             : in  std_logic;
    rst             : in  std_logic;
    stall_req       : in  std_logic;
    pc              : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
    next_pc         : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
    data            : out std_logic_vector(DATA_WIDTH - 1 downto 0);
    data_valid      : out std_logic;
    -- L2 connections
    o_L2c_req       : out std_logic;
    o_L2c_addr      : out std_logic_vector(ADDR_WIDTH - 1 downto 0);
    i_L2c_read_data : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
    i_L2c_valid     : in  std_logic
    );

end entity Instruction_Cache;

-------------------------------------------------------------------------------

architecture rtl of Instruction_Cache is

  -----------------------------------------------------------------------------
  -- Internal signal declarations
  -----------------------------------------------------------------------------
  signal i_porta_req : std_logic;
  signal fetch_pc : std_logic_vector(ADDR_WIDTH - 1 downto 0);
  signal fetched_instr_valid : std_logic;

begin  -- architecture rtl

  -----------------------------------------------------------------------------
  -- Component instantiations
  -----------------------------------------------------------------------------
  L1_Instr : entity work.SinglePort_Cache
    generic map (
      ADDR_WIDTH => ADDR_WIDTH,
      DATA_WIDTH => DATA_WIDTH)
    port map (
      clk                => clk,
      rst                => rst,
      i_porta_req        => i_porta_req,
      i_porta_we         => '0',
      i_porta_addr       => fetch_pc,
      i_porta_write_data => (others => 'X'),
      o_porta_read_data  => data,
      o_porta_valid      => fetched_instr_valid,
      o_memory_req       => o_L2c_req,
      o_memory_addr      => o_L2c_addr,
      i_memory_read_data => i_L2c_read_data,
      i_memory_valid     => i_L2c_valid
      );

  i_porta_req <= '1' when rst = '0' and stall_req = '0' else '0';
  data_valid <= fetched_instr_valid;
  fetch_pc <= next_pc when fetched_instr_valid = '1' else pc;

end architecture rtl;

-------------------------------------------------------------------------------
