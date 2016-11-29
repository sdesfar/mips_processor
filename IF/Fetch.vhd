-------------------------------------------------------------------------------
-- Title      : Instruction Fetch stage
-- Project    : 
-------------------------------------------------------------------------------
-- File       : Fetch.vhd
-- Author     : Robert Jarzmik  <robert.jarzmik@free.fr>
-- Company    : 
-- Created    : 2016-11-10
-- Last update: 2016-11-29
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Fetch instruction from I-Cache and forward to Decode-Issue
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-11-10  1.0      rj      Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-------------------------------------------------------------------------------

entity Fetch is

  generic (
    ADDR_WIDTH : integer := 32;
    DATA_WIDTH : integer := 32
    );

  port (
    clk       : in std_logic;
    rst       : in std_logic;
    stall_req : in std_logic;           -- stall current instruction
    kill_req  : in std_logic;           -- kill current instruction

    i_pc            : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
    i_next_pc       : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
    i_next_next_pc  : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
    o_instruction   : out std_logic_vector(DATA_WIDTH - 1 downto 0);
    o_do_stall_pc   : out std_logic;
    -- L2 connections
    o_L2c_req       : out std_logic;
    o_L2c_addr      : out std_logic_vector(ADDR_WIDTH - 1 downto 0);
    i_L2c_read_data : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
    i_L2c_valid     : in  std_logic
    );

end entity Fetch;

-------------------------------------------------------------------------------

architecture rtl of Fetch is

  -----------------------------------------------------------------------------
  -- Internal signal declarations
  -----------------------------------------------------------------------------
  constant nop_instruction : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
  signal l1c_addr          : std_logic_vector(ADDR_WIDTH - 1 downto 0);
  signal l1c_data          : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal l1c_data_valid    : std_logic;

  signal current_pc          : std_logic_vector(ADDR_WIDTH -1 downto 0);
  signal current_instruction : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal current_valid       : boolean;
  signal next_pc             : std_logic_vector(ADDR_WIDTH -1 downto 0);
  signal next_next_pc        : std_logic_vector(ADDR_WIDTH -1 downto 0);
  signal next_instruction    : std_logic_vector(DATA_WIDTH - 1 downto 0);
begin  -- architecture rtl
  l1c : entity work.Instruction_Cache(rtl) port map (
    clk             => clk,
    rst             => rst,
    -- cache query and response
    addr            => l1c_addr,
    data            => l1c_data,
    data_valid      => l1c_data_valid,
    -- signal carry over L2 connections
    o_L2c_req       => o_L2c_req,
    o_L2c_addr      => o_L2c_addr,
    i_L2c_read_data => i_L2c_read_data,
    i_L2c_valid     => i_L2c_valid
    );

  process(clk, rst)
  begin
    if rst = '1' then
      current_valid       <= false;
      current_instruction <= (others => 'X');
    elsif rising_edge(clk) then
      if kill_req = '1' then
        current_instruction <= nop_instruction;
      elsif stall_req = '1' then
      else
        if current_valid and l1c_data_valid = '0' then
          current_valid       <= false;
          -- current_instruction <= nop_instruction;
        end if;

        if current_valid and l1c_data_valid = '1' then
          current_valid       <= true;
          current_instruction <= l1c_data;
        end if;

        if not current_valid and l1c_data_valid = '0' then
          current_valid       <= false;
          -- current_instruction <= nop_instruction;
        end if;

        if not current_valid and l1c_data_valid = '1' then
          current_valid       <= true;
          current_instruction <= l1c_data;
        end if;

      end if;
    end if;

  end process;

  o_instruction <= current_instruction;
  current_pc    <= i_pc;
  next_pc       <= i_next_pc;
  next_next_pc  <= i_next_next_pc;
  l1c_addr      <= next_pc when l1c_data_valid = '0' else next_next_pc;

  o_do_stall_pc <= '0' when l1c_data_valid = '1' else '1';

  -----------------------------------------------------------------------------
  -- Component instantiations
  -----------------------------------------------------------------------------

end architecture rtl;

-------------------------------------------------------------------------------
