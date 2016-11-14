-------------------------------------------------------------------------------
-- Title      : Instruction Fetch stage
-- Project    : 
-------------------------------------------------------------------------------
-- File       : Fetch.vhd
-- Author     : Robert Jarzmik  <robert.jarzmik@free.fr>
-- Company    : 
-- Created    : 2016-11-10
-- Last update: 2016-11-14
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
    clk         : in  std_logic;
    rst         : in  std_logic;
    stall_req   : in  std_logic;
    pc          : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
    instruction : out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );

end entity Fetch;

-------------------------------------------------------------------------------

architecture rtl of Fetch is

  -----------------------------------------------------------------------------
  -- Internal signal declarations
  -----------------------------------------------------------------------------
  signal l1c_data : std_logic_vector(DATA_WIDTH - 1 downto 0);
begin  -- architecture rtl
  l1c : entity work.Instruction_Cache(rtl) port map (
    clk  => clk,
    pc   => pc,
    data => l1c_data
    );
  process(rst, clk)
  begin
    if rst = '0' and stall_req = '0' and rising_edge(clk) then
      instruction <= l1c_data;
    end if;
  end process;
  -----------------------------------------------------------------------------
  -- Component instantiations
  -----------------------------------------------------------------------------

end architecture rtl;

-------------------------------------------------------------------------------
