-------------------------------------------------------------------------------
-- Title      : Testbench for design "DualPort_Cache"
-- Project    : Source files in two directories, custom library name, VHDL'87
-------------------------------------------------------------------------------
-- File       : DualPort_Cache_tb.vhd
-- Author     : Robert Jarzmik  <robert.jarzmik@free.fr>
-- Company    : 
-- Created    : 2016-11-19
-- Last update: 2016-11-19
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-11-19  1.0      rj      Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-------------------------------------------------------------------------------

entity DualPort_Cache_tb is

end entity DualPort_Cache_tb;

-------------------------------------------------------------------------------

architecture passthrough of DualPort_Cache_tb is

  -- component generics
  constant ADDR_WIDTH : integer := 32;
  constant DATA_WIDTH : integer := 32;

  -- component ports
  signal clk                 : std_logic := '1';
  signal rst                 : std_logic := '1';
  signal i_porta_req         : std_logic;
  signal i_porta_we          : std_logic;
  signal i_porta_addr        : std_logic_vector(ADDR_WIDTH - 1 downto 0);
  signal i_porta_write_data  : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal o_porta_read_data   : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal o_porta_valid       : std_logic;
  signal i_portb_req         : std_logic;
  signal i_portb_we          : std_logic;
  signal i_portb_addr        : std_logic_vector(ADDR_WIDTH - 1 downto 0);
  signal i_portb_write_data  : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal o_portb_read_data   : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal o_portb_valid       : std_logic;
  signal o_memory_req        : std_logic;
  signal o_memory_we         : std_logic;
  signal o_memory_addr       : std_logic_vector(ADDR_WIDTH - 1 downto 0);
  signal o_memory_write_data : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal i_memory_read_data  : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal i_memory_valid      : std_logic;

  -- memory simulator
  type memory is array(0 to 7) of std_logic_vector(DATA_WIDTH - 1 downto 0);
  constant rom : memory := (
    x"00000000",
    x"20050004",
    x"00000008",
    x"0000000c",

    x"00000010",
    x"00000014",
    x"00000018",
    x"0000001c"
    );

begin  -- architecture passthrough

  -- component instantiation
  DUT : entity work.DualPort_Cache
    generic map (
      ADDR_WIDTH => ADDR_WIDTH,
      DATA_WIDTH => DATA_WIDTH)
    port map (
      clk                 => clk,
      rst                 => rst,
      i_porta_req         => i_porta_req,
      i_porta_we          => i_porta_we,
      i_porta_addr        => i_porta_addr,
      i_porta_write_data  => i_porta_write_data,
      o_porta_read_data   => o_porta_read_data,
      o_porta_valid       => o_porta_valid,
      i_portb_req         => i_portb_req,
      i_portb_we          => i_portb_we,
      i_portb_addr        => i_portb_addr,
      i_portb_write_data  => i_portb_write_data,
      o_portb_read_data   => o_portb_read_data,
      o_portb_valid       => o_portb_valid,
      o_memory_req        => o_memory_req,
      o_memory_we         => o_memory_we,
      o_memory_addr       => o_memory_addr,
      o_memory_write_data => o_memory_write_data,
      i_memory_read_data  => i_memory_read_data,
      i_memory_valid      => i_memory_valid);

  -- reset
  rst <= '0'     after 24 ps;
  -- clock generation
  clk <= not clk after 10 ps;

  -- waveform generation
  WaveGen_Proc : process
    variable nb_clk : natural := 0;
  begin
    -- insert signal assignments here

    wait until Clk = '1';
    nb_clk := nb_clk + 1;
    case nb_clk is
      when 2 | 4 | 6 | 8 | 10 | 12 | 14 | 16 | 22 =>
        i_porta_we   <= '0';
        i_porta_addr <= std_logic_vector(to_unsigned(2 * nb_clk, ADDR_WIDTH));
        i_porta_req  <= '1';
      when others =>
        i_porta_req <= '0';
        i_porta_addr <= (others => 'X');
    end case;

  end process WaveGen_Proc;

  -- memory simulator
  --InstantaneousMemorySim : process(clk, rst, o_memory_req)
  --begin
  --  if rst = '0' and o_memory_req = '1' then
  --    if rising_edge(clk) then
  --      i_memory_read_data <= rom((to_integer(unsigned(o_memory_addr)) / 4) mod 8);
  --      i_memory_valid     <= '1';
  --    end if;
  --  end if;
  --end process InstantaneousMemorySim;

  -- memory simulator
  OneCycleMemorySim : process(clk, rst, o_memory_req)
    variable clk_req : natural := 0;
  begin
    if rst = '0' then
      if rising_edge(clk) then
        if o_memory_req = '0' then
          i_memory_valid <= '0';
          i_memory_read_data <= (others => 'X');
        end if;

        if o_memory_req = '1' then
          clk_req := clk_req + 1;
        end if;

        if clk_req > 0 then
          clk_req            := 0;
          i_memory_read_data <= rom((to_integer(unsigned(o_memory_addr)) / 4) mod 8);
          i_memory_valid     <= '1';
        end if;
      end if;
    end if;
  end process OneCycleMemorySim;

end architecture passthrough;

-------------------------------------------------------------------------------

configuration DualPort_Cache_tb_passthrough_cfg of DualPort_Cache_tb is
  for passthrough
  end for;
end DualPort_Cache_tb_passthrough_cfg;

-------------------------------------------------------------------------------
