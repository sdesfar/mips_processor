-------------------------------------------------------------------------------
-- Title      : Single port cache
-- Project    : Source files in two directories, custom library name, VHDL'87
-------------------------------------------------------------------------------
-- File       : SinglePort_Cache.vhd
-- Author     : Robert Jarzmik  <robert.jarzmik@free.fr>
-- Company    : 
-- Created    : 2016-11-19
-- Last update: 2016-11-26
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Cache with one access port and one port to the memory/L+1 cache
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-11-19  1.0      rj      Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity SinglePort_Cache is

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

    o_memory_req        : out std_logic;
    o_memory_we         : out std_logic;
    o_memory_addr       : out std_logic_vector(ADDR_WIDTH - 1 downto 0);
    o_memory_write_data : out std_logic_vector(DATA_WIDTH - 1 downto 0);
    i_memory_read_data  : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
    i_memory_valid      : in  std_logic
    );

end entity SinglePort_Cache;

-------------------------------------------------------------------------------

architecture passthrough of SinglePort_Cache is

  -----------------------------------------------------------------------------
  -- Internal signal declarations
  -----------------------------------------------------------------------------

  -- access handling
  signal cache_initialized : boolean                                   := false;
  signal cache_loaded      : boolean;
  signal cache_hit         : boolean;
  signal cache_addr        : std_logic_vector(ADDR_WIDTH - 1 downto 0) := (others => '1');
  signal cache_data        : std_logic_vector(DATA_WIDTH - 1 downto 0);
  -- cache_valid means: for previously latched address, cache_data is valid.
  -- cache_valid also means: for last time i_porta_req was raised, for the
  -- i_porta_addr that was input, the data on cache_data is valid.
  signal cache_valid       : boolean;
  -- dearm_memory_req : ensure o_memory_req is held only 1 cycle for each request
  signal dearm_memory_req  : boolean                                   := false;
  signal memory_ongoing    : boolean                                   := false;

begin  -- architecture str

  -----------------------------------------------------------------------------
  -- Component instantiations
  -----------------------------------------------------------------------------
  process(rst, clk) is
  begin
    if rst = '0' then
      if rising_edge(clk) then
        if i_porta_req = '1' then
          if not cache_initialized or cache_addr /= i_porta_addr then
            cache_addr          <= i_porta_addr;
            cache_valid         <= false;
            cache_data          <= (others => 'X');
            o_memory_addr       <= i_porta_addr;
            o_memory_req        <= '1';
            dearm_memory_req    <= true;
            memory_ongoing      <= true;
            o_memory_we         <= i_porta_we;
            o_memory_write_data <= i_porta_write_data;
          end if;
        -- If cache_valid and cache_valid = i_porta_addr, output is still
        -- valid and nothing is to be done.
        elsif dearm_memory_req then
          o_memory_req     <= '0';
          dearm_memory_req <= false;
          if i_memory_valid = '0' then
            cache_valid <= false;       -- dearm cache_valid one cycle after
          -- cache_addr changed
          end if;
        end if;

        if i_memory_valid = '1' then
          memory_ongoing    <= false;
          cache_data        <= i_memory_read_data;
          cache_initialized <= true;
          if not (i_porta_req = '1' and (not cache_initialized or cache_addr /= i_porta_addr)) then
            cache_valid <= true;
          end if;
        -- In parallel, o_porta_valid will become '1'
        end if;
      end if;
    else
      o_memory_req <= '0';
      cache_valid  <= false;
    end if;
  end process;

  o_porta_valid     <= '1'        when cache_valid else '0';
  o_porta_read_data <= cache_data when cache_valid else (others => 'X');

end architecture passthrough;

---------------------------------------------------------------------------------
