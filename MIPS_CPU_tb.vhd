-------------------------------------------------------------------------------
-- Title      : Testbench for design "MIPS_CPU"
-- Project    : 
-------------------------------------------------------------------------------
-- File       : MIPS_CPU_tb.vhd
-- Author     : Robert Jarzmik  <robert.jarzmik@free.fr>
-- Company    : 
-- Created    : 2016-11-12
-- Last update: 2016-12-06
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
use ieee.numeric_std.all;

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
  signal stop : std_logic := '0';

  -- L2 connections
  signal o_L2c_req       : std_logic;
  signal o_L2c_addr      : std_logic_vector(ADDR_WIDTH - 1 downto 0);
  signal i_L2c_read_data : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal i_L2c_valid     : std_logic;
  -- Debug signals
  signal dbg_if_pc       : std_logic_vector(ADDR_WIDTH - 1 downto 0);
  signal dbg_di_pc       : std_logic_vector(ADDR_WIDTH - 1 downto 0);
  signal dbg_ex_pc       : std_logic_vector(ADDR_WIDTH - 1 downto 0);
  signal dbg_wb_pc       : std_logic_vector(ADDR_WIDTH - 1 downto 0);
  signal dbg_commited_pc : std_logic_vector(ADDR_WIDTH - 1 downto 0);

begin  -- architecture rtl

  -- component instantiation
  DUT : entity work.MIPS_CPU
    generic map (
      ADDR_WIDTH           => ADDR_WIDTH,
      DATA_WIDTH           => DATA_WIDTH,
      NB_REGISTERS_GP      => NB_REGISTERS_GP,
      NB_REGISTERS_SPECIAL => NB_REGISTERS_SPECIAL)
    port map (
      clk               => clk,
      rst               => rst,
      o_L2c_req         => o_L2c_req,
      o_L2c_addr        => o_L2c_addr,
      i_L2c_read_data   => i_L2c_read_data,
      i_L2c_valid       => i_L2c_valid,
      o_dbg_if_pc       => dbg_if_pc,
      o_dbg_di_pc       => dbg_di_pc,
      o_dbg_ex_pc       => dbg_ex_pc,
      o_dbg_wb_pc       => dbg_wb_pc,
      o_dbg_commited_pc => dbg_commited_pc);

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
  Rst <= '0' or stop after 12 ps;
  -- clock generation
  Clk <= not Clk                     after 5 ps;

  -- waveform generation
  WaveGen_Proc : process
  begin
    -- insert signal assignments here

    wait until Clk = '1';
  end process WaveGen_Proc;

  debug_proc : process(clk, rst)
    variable cycle           : integer                                   := 1;
    variable unusable_op     : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => 'X');
    variable passed_by_addr0 : natural                                   := 0;
  begin
    if rst = '1' then
    elsif rising_edge(clk) then
      cycle := cycle + 1;
      report "[" & integer'image(cycle) & "] " &
        "if=0x" & to_hstring(dbg_if_pc) & " " &
        "di=0x" & to_hstring(dbg_di_pc) & " " &
        "ex=0x" & to_hstring(dbg_ex_pc) & " " &
        "wb=0x" & to_hstring(dbg_wb_pc) & " " &
        "done=0x" & to_hstring(dbg_commited_pc);
      if dbg_commited_pc /= unusable_op then
        if to_integer(unsigned(dbg_commited_pc)) = 0 then
          passed_by_addr0 := passed_by_addr0 + 1;
        end if;
      end if;

      if passed_by_addr0 > 1 then
        report "PC rolled over to 0, ending simulation." severity error;
        stop <= '1';
      end if;
    end if;
  end process debug_proc;

end architecture rtl;

-------------------------------------------------------------------------------

configuration MIPS_CPU_tb_rtl_cfg of MIPS_CPU_tb is
  for rtl
  end for;
end MIPS_CPU_tb_rtl_cfg;

-------------------------------------------------------------------------------
