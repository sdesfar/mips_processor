-------------------------------------------------------------------------------
-- Title      : Instruction Fetch stage
-- Project    : 
-------------------------------------------------------------------------------
-- File       : Fetch.vhd
-- Author     : Robert Jarzmik  <robert.jarzmik@free.fr>
-- Company    : 
-- Created    : 2016-11-10
-- Last update: 2016-11-20
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Fetch instruction from I-Cache and forward to Decode-Issue
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

entity Fetch is

  generic (
    ADDR_WIDTH : integer := 32;
    DATA_WIDTH : integer := 32
    );

  port (
    clk             : in  std_logic;
    rst             : in  std_logic;
    stall_req       : in  std_logic;
    pc              : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
    instruction     : out std_logic_vector(DATA_WIDTH - 1 downto 0);
    -- L2 connections
    o_L2c_req       : out std_logic;
    o_L2c_addr      : out std_logic_vector(ADDR_WIDTH - 1 downto 0);
    i_L2c_read_data : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
    i_L2c_valid     : in  std_logic
    );

end entity Fetch;

-------------------------------------------------------------------------------

architecture rtl of Fetch is

  -----------------------------------------------------------------------------
  -- Internal signal declarations
  -----------------------------------------------------------------------------
  constant nop_instruction : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
  signal l1c_data          : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal l1c_data_valid    : std_logic;

begin  -- architecture rtl
  l1c : entity work.Instruction_Cache(rtl) port map (
    clk             => clk,
    pc              => pc,
    stall_req       => stall_req,
    data            => l1c_data,
    data_valid      => l1c_data_valid,
    o_L2c_req       => o_L2c_req,
    o_L2c_addr      => o_L2c_addr,
    i_L2c_read_data => i_L2c_read_data,
    i_L2c_valid     => i_L2c_valid
    );

  instruction <= l1c_data when stall_req = '0' and l1c_data_valid = '1' else nop_instruction;

  -----------------------------------------------------------------------------
  -- Component instantiations
  -----------------------------------------------------------------------------

end architecture rtl;

-------------------------------------------------------------------------------
