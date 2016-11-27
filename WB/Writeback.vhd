-------------------------------------------------------------------------------
-- Title      : Writeback instruction's result
-- Project    : Source files in two directories, custom library name, VHDL'87
-------------------------------------------------------------------------------
-- File       : Writeback.vhd
-- Author     : Robert Jarzmik  <robert.jarzmik@free.fr>
-- Company    : 
-- Created    : 2016-11-16
-- Last update: 2016-11-16
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Writes back a MIPS instruction result into the register file
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-11-16  1.0      rj      Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.cpu_defs.all;

-------------------------------------------------------------------------------

entity Writeback is

  generic (
    ADDR_WIDTH   : integer  := 32;
    DATA_WIDTH   : integer  := 32;
    NB_REGISTERS : positive := 34
    );

  port (
    clk           : in std_logic;
    rst           : in std_logic;
    stall_req     : in std_logic;       -- stall current instruction
    kill_req      : in std_logic;       -- kill current instruction
    i_reg1        : in register_port_type;
    i_reg2        : in register_port_type;
    i_jump_target : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
    i_is_jump     : in std_logic;

    o_reg1        : out register_port_type;
    o_reg2        : out register_port_type;
    o_is_jump     : out std_logic;
    o_jump_target : out std_logic_vector(ADDR_WIDTH - 1 downto 0)
    );

end entity Writeback;

-------------------------------------------------------------------------------

architecture rtl of Writeback is

  -----------------------------------------------------------------------------
  -- Internal signal declarations
  -----------------------------------------------------------------------------
  signal reg1        : register_port_type;
  signal reg2        : register_port_type;
  signal is_jump     : std_logic;
  signal jump_target : std_logic_vector(ADDR_WIDTH - 1 downto 0);

begin  -- architecture rtl

  -----------------------------------------------------------------------------
  -- Component instantiations
  -----------------------------------------------------------------------------

  process(rst, clk, stall_req)
  begin
    if rst = '1' then
      reg1.we <= '0';
      reg2.we <= '0';
      is_jump <= '0';
    elsif rising_edge(clk) then
      if kill_req = '1' then
        reg1.we <= '0';
        reg2.we <= '0';
        is_jump <= '0';
      elsif stall_req = '0' then
        is_jump     <= i_is_jump;
        jump_target <= i_jump_target;

        reg1 <= i_reg1;
        reg2 <= i_reg2;
      else
        is_jump   <= '0';
        reg1.we   <= '0';
        reg1.data <= (others => 'X');
        reg2.we   <= '0';
        reg2.data <= (others => 'X');
      end if;
    end if;
  end process;

  o_reg1        <= reg1;
  o_reg2        <= reg2;
  o_is_jump     <= is_jump;
  o_jump_target <= jump_target when is_jump = '1' else (others => 'X');

end architecture rtl;

-------------------------------------------------------------------------------
