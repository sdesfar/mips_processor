-------------------------------------------------------------------------------
-- Title      : MIPS CPU definitions
-- Project    : Source files in two directories, custom library name, VHDL'87
-------------------------------------------------------------------------------
-- File       : cpu_defs.vhd
-- Author     : Robert Jarzmik  <robert.jarzmik@free.fr>
-- Company    : 
-- Created    : 2016-11-15
-- Last update: 2016-11-15
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: MIPS CPU general definitions
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-11-15  1.0      rj      Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

package cpu_defs is
  constant REGISTER_WIDTH : integer := 32;

  type jump_type is (none, always, zero, non_zero, lesser_or_zero, greater, lesser, greater_or_zero);
  type alu_op_type is (all_zero, add, substract, multiply, divide, log_and, log_or, log_xor, log_nor, slt);
  type memory_op_type is (none, loadw, storew, load8, load8_signextend32, store8);

  type register_port_type is record
    we   : std_logic;
    idx  : natural;
    data : std_logic_vector(REGISTER_WIDTH - 1 downto 0);
  end record register_port_type;

end package cpu_defs;
