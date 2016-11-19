-------------------------------------------------------------------------------
-- Title      : Dual port cache
-- Project    : 
-------------------------------------------------------------------------------
-- File       : DualPort_Cache.vhd
-- Author     : Robert Jarzmik (Intel)  <robert.jarzmik@free.fr>
-- Company    : 
-- Created    : 2016-11-15
-- Last update: 2016-11-18
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Cache with 2 input ports and one port towards memory/next cache
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-11-15  1.0      rjarzmik        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-------------------------------------------------------------------------------

entity DualPort_Cache is

  generic (
    ADDR_WIDTH : integer := 32;
    DATA_WIDTH : integer := 32
    );

  port (
    clk : in std_logic;
    rst : in std_logic;

    i_porta_req        : in  std_logic;
    i_porta_we         : in  std_logic;
    i_porta_addr       : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
    i_porta_write_data : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
    o_porta_read_data  : out std_logic_vector(DATA_WIDTH - 1 downto 0);
    o_porta_valid      : out std_logic;

    i_portb_req        : in  std_logic;
    i_portb_we         : in  std_logic;
    i_portb_addr       : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
    i_portb_write_data : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
    o_portb_read_data  : out std_logic_vector(DATA_WIDTH - 1 downto 0);
    o_portb_valid      : out std_logic;

    o_memory_req        : out std_logic;
    o_memory_we         : out std_logic;
    o_memory_addr       : out std_logic_vector(ADDR_WIDTH - 1 downto 0);
    o_memory_write_data : out std_logic_vector(DATA_WIDTH - 1 downto 0);
    i_memory_read_data  : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
    i_memory_valid      : in  std_logic
    );

end entity DualPort_Cache;

-------------------------------------------------------------------------------

architecture passthrough of DualPort_Cache is

  -----------------------------------------------------------------------------
  -- Internal signal declarations
  -----------------------------------------------------------------------------

  -- access handling
  signal cache_valid           : boolean;
  signal cache_acquiring_porta : boolean;
  signal cache_acquiring_portb : boolean;
  signal cache_addr            : std_logic_vector(ADDR_WIDTH - 1 downto 0);
  signal cache_data            : std_logic_vector(DATA_WIDTH - 1 downto 0);

begin  -- architecture rtl
  -----------------------------------------------------------------------------
  -- Component instantiations
  -----------------------------------------------------------------------------
  process(rst, clk) is
  begin
    if rst = '1' then
      o_porta_valid         <= '0';
      o_portb_valid         <= '0';
      o_memory_we           <= '0';
      cache_valid           <= false;
      cache_acquiring_porta <= false;
      cache_acquiring_portb <= false;
    elsif rising_edge(clk) then
      if cache_valid and cache_acquiring_porta then
        o_porta_read_data     <= cache_data;
        o_porta_valid         <= '1';
        cache_addr            <= (others => 'X');
        cache_acquiring_porta <= false;
      else
        o_porta_valid     <= '0';
        o_porta_read_data <= (others => 'X');
      end if;
      if cache_valid and cache_acquiring_portb then
        o_portb_read_data     <= cache_data;
        o_portb_valid         <= '1';
        cache_addr            <= (others => 'X');
        cache_acquiring_portb <= false;
      else
        o_portb_valid     <= '0';
        o_portb_read_data <= (others => 'X');
      end if;

      if not (cache_acquiring_porta or cache_acquiring_portb) and
        (not cache_valid or (cache_addr /= i_porta_addr and cache_addr /= i_portb_addr)) then
        if i_porta_req = '1' then
          cache_valid           <= false;
          cache_data            <= (others => 'X');
          o_memory_addr         <= i_porta_addr;
          o_memory_write_data   <= i_porta_write_data;
          cache_addr            <= i_porta_addr;
          o_memory_we           <= i_porta_we;
          cache_acquiring_porta <= true;
        elsif i_portb_req = '1' then
          cache_valid           <= false;
          cache_data            <= (others => 'X');
          o_memory_addr         <= i_portb_addr;
          o_memory_write_data   <= i_portb_write_data;
          cache_addr            <= i_portb_addr;
          o_memory_we           <= i_portb_we;
          cache_acquiring_portb <= true;
        end if;
      end if;

      if i_memory_valid = '1' then
        cache_data  <= i_memory_read_data;
        cache_valid <= true;
      end if;
    end if;
  end process;

  o_memory_req <= '1' when cache_acquiring_porta or cache_acquiring_portb else '0';

end architecture passthrough;
