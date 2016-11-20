-------------------------------------------------------------------------------
-- Title      : Testbench for design "Simulated_Memory"
-- Project    : Source files in two directories, custom library name, VHDL'87
-------------------------------------------------------------------------------
-- File       : Simulated_Memory_tb.vhd
-- Author     : Robert Jarzmik  <robert.jarzmik@free.fr>
-- Company    : 
-- Created    : 2016-11-21
-- Last update: 2016-11-21
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-11-21  1.0      rj      Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-------------------------------------------------------------------------------

entity Simulated_Memory_tb is

end entity Simulated_Memory_tb;

-------------------------------------------------------------------------------

architecture rtl of Simulated_Memory_tb is

  -- component generics
  constant ADDR_WIDTH     : integer                                  := 32;
  constant DATA_WIDTH     : integer                                  := 32;
  constant MEMORY_LATENCY : natural                                  := 1;
  constant addr_zero      : std_logic_vector(ADDR_WIDTH -1 downto 0) := std_logic_vector(to_unsigned(0, ADDR_WIDTH));

  -- component ports
  signal clk                 : std_logic                                 := '1';
  signal rst                 : std_logic                                 := '1';
  signal i_memory_req        : std_logic                                 := '1';
  signal i_memory_we         : std_logic;
  signal i_memory_addr       : std_logic_vector(ADDR_WIDTH - 1 downto 0) := addr_zero;
  signal i_memory_write_data : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal o_memory_read_data  : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal o_memory_valid      : std_logic;
  signal addr                : std_logic_vector(ADDR_WIDTH - 1 downto 0) := addr_zero;
  signal wait_clk_requested  : boolean                                   := false;

  -- clock

begin  -- architecture rtl

  -- component instantiation
  DUT : entity work.Simulated_Memory
    generic map (
      ADDR_WIDTH     => ADDR_WIDTH,
      DATA_WIDTH     => DATA_WIDTH,
      MEMORY_LATENCY => MEMORY_LATENCY)
    port map (
      clk                 => clk,
      rst                 => rst,
      i_memory_req        => i_memory_req,
      i_memory_we         => i_memory_we,
      i_memory_addr       => i_memory_addr,
      i_memory_write_data => i_memory_write_data,
      o_memory_read_data  => o_memory_read_data,
      o_memory_valid      => o_memory_valid);

  -- reset
  Rst <= '0' after 24 ps;

  -- clock generation
  Clk <= not Clk after 10 ps;

  -- waveform generation
  read_normal : process(clk, o_memory_valid)
    variable wait_clk_before_incrementing_addr : integer := 0;
  begin
    if rst = '0' and rising_edge(clk) then
      if MEMORY_LATENCY > 0 then
        if o_memory_valid = '1' and not wait_clk_requested then
          wait_clk_requested                <= true;
          addr                              <= std_logic_vector(unsigned(addr) + 4);
          wait_clk_before_incrementing_addr := 0;
        elsif wait_clk_requested and wait_clk_before_incrementing_addr > 0 then
          wait_clk_before_incrementing_addr := wait_clk_before_incrementing_addr - 1;
        end if;

        if wait_clk_requested and wait_clk_before_incrementing_addr = 0 then
          wait_clk_requested <= false;
        end if;
      else
        addr <= std_logic_vector(unsigned(addr) + 4);
      end if;

    end if;
  end process read_normal;

  i_memory_addr <= addr;
  i_memory_req  <= '0' when (MEMORY_LATENCY > 0 and o_memory_valid = '1') else '1';

end architecture rtl;

-------------------------------------------------------------------------------

configuration Simulated_Memory_tb_rtl_cfg of Simulated_Memory_tb is
  for rtl
  end for;
end Simulated_Memory_tb_rtl_cfg;

-------------------------------------------------------------------------------
