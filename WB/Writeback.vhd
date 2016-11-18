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
    stall_req     : in std_logic;
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

begin  -- architecture rtl

  -----------------------------------------------------------------------------
  -- Component instantiations
  -----------------------------------------------------------------------------

  process(rst, clk, stall_req)
  begin
    if rst = '1' then
      o_reg1.we <= '0';
      o_reg2.we <= '0';
      o_is_jump <= '0';
    elsif stall_req = '0' and rising_edge(clk) then
      o_is_jump     <= i_is_jump;
      o_jump_target <= i_jump_target;

      o_reg1 <= i_reg1;
      o_reg2 <= i_reg2;
    end if;
  end process;
end architecture rtl;

-------------------------------------------------------------------------------
