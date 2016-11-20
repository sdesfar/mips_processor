-------------------------------------------------------------------------------
-- Title      : Testbench for design "Fetch"
-- Project    : 
-------------------------------------------------------------------------------
-- File       : Fetch_tb.vhd
-- Author     : Robert Jarzmik  <robert.jarzmik@free.fr>
-- Company    : 
-- Created    : 2016-11-11
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
-- 2016-11-11  1.0      rj      Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-------------------------------------------------------------------------------

entity Fetch_tb is

end entity Fetch_tb;

-------------------------------------------------------------------------------

architecture rtl of Fetch_tb is

  -- component generics
  constant ADDR_WIDTH : integer := 32;
  constant DATA_WIDTH : integer := 32;

  -- component ports

  -- clock
  signal Clk : std_logic := '1';
  -- reset
  signal Rst : std_logic := '1';

  signal instruction : std_logic_vector(31 downto 0);
  signal pc          : std_logic_vector(ADDR_WIDTH - 1 downto 0) := std_logic_vector(to_unsigned(0, ADDR_WIDTH));

  -- L2 connections
  signal o_L2c_req       : std_logic;
  signal o_L2c_addr      : std_logic_vector(ADDR_WIDTH - 1 downto 0);
  signal i_L2c_read_data : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal i_L2c_valid     : std_logic;

begin  -- architecture rtl

  -- component instantiation
  dut : entity work.Fetch
    generic map (
      ADDR_WIDTH => ADDR_WIDTH,
      DATA_WIDTH => DATA_WIDTH)
    port map (
      clk             => Clk,
      rst             => Rst,
      stall_req       => '0',
      pc              => pc,
      instruction     => instruction,
      o_L2c_req       => o_L2c_req,
      o_L2c_addr      => o_L2c_addr,
      i_L2c_read_data => i_L2c_read_data,
      i_L2c_valid     => i_L2c_valid);

  Simulated_Memory_1 : entity work.Simulated_Memory
    generic map (
      ADDR_WIDTH => ADDR_WIDTH,
      DATA_WIDTH => DATA_WIDTH,
      MEMORY_LATENCY => 1)
    port map (
      clk                 => Clk,
      rst                 => Rst,
      i_memory_req        => o_L2c_req,
      i_memory_we         => '0',
      i_memory_addr       => o_L2c_addr,
      i_memory_write_data => (others => 'X'),
      o_memory_read_data  => i_L2c_read_data,
      o_memory_valid      => i_L2c_valid);

  -- reset
  Rst <= '0'     after 24 ps;
  -- clock generation
  Clk <= not Clk after 10 ps;

  -- waveform generation
  WaveGen_Proc : process
    variable nb_clks : integer := 0;
  begin
    -- insert signal assignments here

    wait until Clk = '1';
    if Rst = '0' and nb_clks mod 2 = 0 then
      pc <= std_logic_vector(unsigned(pc) + 4);
    end if;
    nb_clks := nb_clks + 1;

  end process WaveGen_Proc;

end architecture rtl;

-------------------------------------------------------------------------------

configuration Fetch_tb_test_cfg of Fetch_tb is
  for rtl
end for;
end Fetch_tb_test_cfg;

-------------------------------------------------------------------------------
