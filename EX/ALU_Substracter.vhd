-------------------------------------------------------------------------------
-- Title      : ALU substracter
-- Project    : Source files in two directories, custom library name, VHDL'87
-------------------------------------------------------------------------------
-- File       : ALU_Substracter.vhd
-- Author     : Robert Jarzmik  <robert.jarzmik@free.fr>
-- Company    : 
-- Created    : 2016-12-06
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
-- 2016-12-06  1.0      rj      Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-------------------------------------------------------------------------------

entity ALU_Substracter is
  generic (
    DATA_WIDTH : integer
    );

  port (
    i_ra : in  unsigned(DATA_WIDTH - 1 downto 0);
    i_rb : in  unsigned(DATA_WIDTH - 1 downto 0);
    o_q  : out unsigned(DATA_WIDTH * 2 - 1 downto 0)
    );
end entity ALU_Substracter;

-------------------------------------------------------------------------------

architecture rtl of ALU_Substracter is
  -----------------------------------------------------------------------------
  -- Internal signal declarations
  -----------------------------------------------------------------------------
  signal result      : unsigned(DATA_WIDTH downto 0);
  signal sign_extend : unsigned(DATA_WIDTH - 2 downto 0);

begin  -- architecture rtl

  o_q <= sign_extend & result;

  result      <= resize(i_ra, DATA_WIDTH + 1) - resize(i_rb, DATA_WIDTH + 1);
  sign_extend <= (others => result(DATA_WIDTH));

end architecture rtl;

-------------------------------------------------------------------------------
