-------------------------------------------------------------------------------
-- Title      : Testbench for design "Fetch"
-- Project    : 
-------------------------------------------------------------------------------
-- File       : Fetch_tb.vhd
-- Author     : Robert Jarzmik  <robert.jarzmik@free.fr>
-- Company    : 
-- Created    : 2016-11-11
-- Last update: 2016-11-12
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-11-11  1.0      rj      Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity Fetch_tb is

end entity Fetch_tb;

-------------------------------------------------------------------------------

architecture rtl of Fetch_tb is

  -- component ports
  component Fetch
    port (
      clk         : in  std_logic;
      rst         : in  std_logic;
      instruction : out std_logic_vector(31 downto 0)
      );
  end component;

  -- clock
  signal Clk : std_logic := '1';
  -- reset
  signal Rst : std_logic := '1';

  signal instruction : std_logic_vector(31 downto 0);

begin  -- architecture test

  -- component instantiation
  dut : Fetch
    port map (clk         => Clk,
              rst         => Rst,
              instruction => instruction);

  -- reset
  Rst <= '0' after 24 ns;
  -- clock generation
  Clk <= not Clk after 10 ns;

  -- waveform generation
  WaveGen_Proc : process
  begin
    -- insert signal assignments here

    wait until Clk = '1';
  end process WaveGen_Proc;

end architecture rtl;

-------------------------------------------------------------------------------

configuration Fetch_tb_test_cfg of Fetch_tb is
  for rtl
  end for;
end Fetch_tb_test_cfg;

-------------------------------------------------------------------------------
