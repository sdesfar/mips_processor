-------------------------------------------------------------------------------
-- Title      : Single port cache
-- Project    : Source files in two directories, custom library name, VHDL'87
-------------------------------------------------------------------------------
-- File       : SinglePort_Cache.vhd
-- Author     : Robert Jarzmik  <robert.jarzmik@free.fr>
-- Company    : 
-- Created    : 2016-11-19
-- Last update: 2016-11-20
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
  signal cache_initialized      : boolean                                   := false;
  signal cache_loaded           : boolean;
  signal cache_hit              : boolean;
  signal data_ready_from_memory : boolean;
  signal cache_addr             : std_logic_vector(ADDR_WIDTH - 1 downto 0) := (others => '1');
  signal cache_data             : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal memory_requested_addr  : std_logic_vector(ADDR_WIDTH - 1 downto 0) := (others => '0');

begin  -- architecture str

  -----------------------------------------------------------------------------
  -- Component instantiations
  -----------------------------------------------------------------------------
  process(rst, clk) is
  begin
    if rst = '0' then
      if rising_edge(clk) then
        if i_porta_req = '1' then
          if cache_hit then
            memory_requested_addr <= cache_addr;
          -- In parallel, o_porta_valid and o_porta_read_data will be set
          else
            cache_data            <= (others => 'X');
            memory_requested_addr <= i_porta_addr;
          -- In parallel, cache_loaded will become false
          -- In parallel, o_porta_valid will probably become false
          end if;
        end if;

        if not cache_loaded and i_memory_valid = '1' then
          cache_addr        <= memory_requested_addr;
          cache_data        <= i_memory_read_data;
          cache_initialized <= true;
        -- In parallel, cache_loaded will become true
        end if;
      end if;
    end if;
  end process;

  cache_loaded           <= cache_initialized and cache_addr = memory_requested_addr;
  cache_hit              <= cache_initialized and cache_addr = i_porta_addr;
  data_ready_from_memory <= i_memory_valid = '1' and i_porta_addr = memory_requested_addr;
  o_porta_valid          <= '1'        when cache_hit or data_ready_from_memory else '0';
  o_porta_read_data      <= cache_data when cache_hit else
                       i_memory_read_data when data_ready_from_memory else (others => 'X');

  o_memory_addr       <= i_porta_addr when i_porta_req = '1'                                 else (others => 'X');
  o_memory_req        <= '0'          when cache_hit or (cache_loaded and i_porta_req = '0') else '1';
  o_memory_we         <= i_porta_we;
  o_memory_write_data <= i_porta_write_data;
end architecture passthrough;

---------------------------------------------------------------------------------
