-------------------------------------------------------------------------------
-- Title      : Testbench for design "SinglePort_Associative_Cache"
-- Project    : Source files in two directories, custom library name, VHDL'87
-------------------------------------------------------------------------------
-- File       : SinglePort_Associative_Cache_tb.vhd
-- Author     : Robert Jarzmik  <robert.jarzmik@free.fr>
-- Company    : 
-- Created    : 2016-11-30
-- Last update: 2016-12-01
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-11-30  1.0      rj      Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-------------------------------------------------------------------------------

entity SinglePort_Associative_Cache_tb is

end entity SinglePort_Associative_Cache_tb;

-------------------------------------------------------------------------------

architecture ways_N_associative of SinglePort_Associative_Cache_tb is

  -- component generics
  constant ADDR_WIDTH      : integer := 8;
  constant DATA_WIDTH      : integer := 8;
  constant MEMORY_LATENCY  : integer := 1;
  constant NB_DATA_PER_SET : integer := 2;
  constant NB_WAYS         : integer := 4;
  constant NB_SETS         : integer := 4;

  -- component ports
  signal clk                 : std_logic                                 := '1';
  signal rst                 : std_logic                                 := '1';
  signal i_porta_req         : std_logic;
  signal i_porta_we          : std_logic;
  signal i_porta_addr        : std_logic_vector(ADDR_WIDTH - 1 downto 0);
  signal i_porta_write_data  : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => 'X');
  signal o_porta_read_data   : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal o_porta_valid       : std_logic;
  signal o_memory_req        : std_logic;
  signal o_memory_we         : std_logic                                 := '0';
  signal o_memory_addr       : std_logic_vector(ADDR_WIDTH - 1 downto 0);
  signal o_memory_write_data : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal i_memory_read_data  : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal i_memory_valid      : std_logic;

begin  -- architecture ways_N_associative

  -- component instantiation
  DUT : entity work.SinglePort_Associative_Cache
    generic map (
      ADDR_WIDTH      => ADDR_WIDTH,
      DATA_WIDTH      => DATA_WIDTH,
      NB_DATA_PER_SET => NB_DATA_PER_SET,
      NB_WAYS         => NB_WAYS,
      NB_SETS         => NB_SETS)
    port map (
      clk                 => clk,
      rst                 => rst,
      i_porta_req         => i_porta_req,
      i_porta_we          => i_porta_we,
      i_porta_addr        => i_porta_addr,
      i_porta_write_data  => i_porta_write_data,
      o_porta_read_data   => o_porta_read_data,
      o_porta_valid       => o_porta_valid,
      o_memory_req        => o_memory_req,
      o_memory_we         => o_memory_we,
      o_memory_addr       => o_memory_addr,
      o_memory_write_data => o_memory_write_data,
      i_memory_read_data  => i_memory_read_data,
      i_memory_valid      => i_memory_valid);

  -- reset
  rst <= '0'     after 12 ps;
  -- clock generation
  clk <= not clk after 5 ps;

  i_porta_write_data <= (others => 'X');

  -- waveform generation
  WaveGen_Proc : process
    variable nb_clk   : natural := 0;
  begin
    -- insert signal assignments here

    wait until clk = '1';
    nb_clk    := nb_clk + 1;
    if nb_clk <= 24 then
      if nb_clk mod (MEMORY_LATENCY + 2) = 0 then
        i_porta_we   <= '0';
        i_porta_addr <= std_logic_vector(to_unsigned((nb_clk * DATA_WIDTH / 8) / (MEMORY_LATENCY + 2), ADDR_WIDTH));
        i_porta_req  <= '1';
      else
        i_porta_we   <= '0';
        i_porta_addr <= (others => 'X');
        i_porta_req  <= '0';
      end if;
    end if;

    if nb_clk > 24 and nb_clk <= 27 then
      i_porta_we   <= '0';
      i_porta_addr <= std_logic_vector(to_unsigned(8, ADDR_WIDTH));
      i_porta_req  <= '1';
    end if;

    if nb_clk = 28 then
      i_porta_we   <= '0';
      i_porta_addr <= std_logic_vector(to_unsigned(7, ADDR_WIDTH));
      i_porta_req  <= '1';
    end if;

    if nb_clk = 29 then
      i_porta_we   <= '0';
      i_porta_addr <= std_logic_vector(to_unsigned(8, ADDR_WIDTH));
      i_porta_req  <= '1';
    end if;

    if nb_clk = 30 then
      i_porta_req  <= '0';
      i_porta_addr <= (others => 'X');
    end if;

    if nb_clk > 32 and nb_clk <= 42 then
      i_porta_we <= '0';
      if nb_clk = 33 or nb_clk = (33 + MEMORY_LATENCY + 3) then
        i_porta_req  <= '1';
        i_porta_addr <= std_logic_vector(to_unsigned(8, ADDR_WIDTH));
      else
        i_porta_req  <= '0';
        i_porta_addr <= (others => 'X');
      end if;
    end if;

    if nb_clk > 42 then
      i_porta_req  <= '0';
      i_porta_addr <= (others => 'X');
    end if;

  end process WaveGen_Proc;

  reporter : process(clk, rst)
    variable nb_clk   : natural := 0;
  begin
    if rising_edge(clk) then
      nb_clk    := nb_clk + 1;
    end if;

    if rst = '0' and rising_edge(clk) then
      report "[" & integer'image(nb_clk) & "] " &
        "i_porta_req=" & std_logic'image(i_porta_req) & " " &
        "i_porta_addr=" & integer'image(to_integer(unsigned(i_porta_addr))) & " ";
      report "[" & integer'image(nb_clk) & "] " &
        "o_porta_valid=" & std_logic'image(o_porta_valid) & " " &
        "o_porta_read_data=" & integer'image(to_integer(unsigned(o_porta_read_data))) & " ";
    end if;
  end process reporter;

  -- memory simulator
  Simulated_Memory_1 : entity work.Simulated_Memory
    generic map (
      ADDR_WIDTH     => ADDR_WIDTH,
      DATA_WIDTH     => DATA_WIDTH,
      MEMORY_LATENCY => MEMORY_LATENCY)
    port map (
      clk                 => clk,
      rst                 => rst,
      i_memory_req        => o_memory_req,
      i_memory_we         => o_memory_we,
      i_memory_addr       => o_memory_addr,
      i_memory_write_data => o_memory_write_data,
      o_memory_read_data  => i_memory_read_data,
      o_memory_valid      => i_memory_valid);

end architecture ways_N_associative;

-------------------------------------------------------------------------------

configuration SinglePort_Associative_Cache_tb_ways_N_associative_cfg of SinglePort_Associative_Cache_tb is
  for ways_N_associative
  end for;
end SinglePort_Associative_Cache_tb_ways_N_associative_cfg;

-------------------------------------------------------------------------------
