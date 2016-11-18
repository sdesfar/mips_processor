-------------------------------------------------------------------------------
-- Title      : Testbench for design "MIPS_CPU"
-- Project    : 
-------------------------------------------------------------------------------
-- File       : MIPS_CPU_tb.vhd
-- Author     : Robert Jarzmik  <robert.jarzmik@free.fr>
-- Company    : 
-- Created    : 2016-11-12
-- Last update: 2016-11-16
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-11-12  1.0      rj	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity MIPS_CPU_tb is

end entity MIPS_CPU_tb;

-------------------------------------------------------------------------------

architecture rtl of MIPS_CPU_tb is

  -- component generics
  constant ADDR_WIDTH : integer := 32;
  constant DATA_WIDTH : integer := 32;

  -- clock
  signal Clk : std_logic := '1';
  signal Rst : std_logic := '1';

begin  -- architecture rtl

  -- component instantiation
  DUT: entity work.MIPS_CPU
    generic map (
      ADDR_WIDTH => ADDR_WIDTH,
      DATA_WIDTH => DATA_WIDTH)
    port map (
      clk => clk,
      rst => rst);

  -- reset
  Rst <= '0' after 24 ps;
  -- clock generation
  Clk <= not Clk after 10 ps;

  -- waveform generation
  WaveGen_Proc: process
  begin
    -- insert signal assignments here

    wait until Clk = '1';
  end process WaveGen_Proc;

  

end architecture rtl;

-------------------------------------------------------------------------------

configuration MIPS_CPU_tb_rtl_cfg of MIPS_CPU_tb is
  for rtl
  end for;
end MIPS_CPU_tb_rtl_cfg;

-------------------------------------------------------------------------------
