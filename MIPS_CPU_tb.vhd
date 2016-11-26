-------------------------------------------------------------------------------
-- Title      : Testbench for design "MIPS_CPU"
-- Project    : 
-------------------------------------------------------------------------------
-- File       : MIPS_CPU_tb.vhd
-- Author     : Robert Jarzmik  <robert.jarzmik@free.fr>
-- Company    : 
-- Created    : 2016-11-12
-- Last update: 2016-11-26
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-11-12  1.0      rj      Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity MIPS_CPU_tb is

end entity MIPS_CPU_tb;

-------------------------------------------------------------------------------

architecture rtl of MIPS_CPU_tb is

  -- component generics
  constant ADDR_WIDTH           : integer := 32;
  constant DATA_WIDTH           : integer := 32;
  constant NB_REGISTERS_GP      : integer := 32;
  constant NB_REGISTERS_SPECIAL : integer := 2;

  -- clock
  signal Clk : std_logic := '1';
  signal Rst : std_logic := '1';

  -- L2 connections
  signal o_L2c_req       : std_logic;
  signal o_L2c_addr      : std_logic_vector(ADDR_WIDTH - 1 downto 0);
  signal i_L2c_read_data : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal i_L2c_valid     : std_logic;

begin  -- architecture rtl

  -- component instantiation
  DUT : entity work.MIPS_CPU
    generic map (
      ADDR_WIDTH           => ADDR_WIDTH,
      DATA_WIDTH           => DATA_WIDTH,
      NB_REGISTERS_GP      => NB_REGISTERS_GP,
      NB_REGISTERS_SPECIAL => NB_REGISTERS_SPECIAL)
    port map (
      clk             => clk,
      rst             => rst,
      o_L2c_req       => o_L2c_req,
      o_L2c_addr      => o_L2c_addr,
      i_L2c_read_data => i_L2c_read_data,
      i_L2c_valid     => i_L2c_valid);

  Simulated_Memory_1 : entity work.Simulated_Memory
    generic map (
      ADDR_WIDTH     => ADDR_WIDTH,
      DATA_WIDTH     => DATA_WIDTH,
      MEMORY_LATENCY => 1)
    port map (
      clk                 => clk,
      rst                 => rst,
      i_memory_req        => o_L2c_req,
      i_memory_we         => '0',
      i_memory_addr       => o_L2c_addr,
      i_memory_write_data => (others => 'X'),
      o_memory_read_data  => i_L2c_read_data,
      o_memory_valid      => i_L2c_valid);

  -- reset
  Rst <= '0'     after 12 ps;
  -- clock generation
  Clk <= not Clk after 5 ps;

  -- waveform generation
  WaveGen_Proc : process
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
