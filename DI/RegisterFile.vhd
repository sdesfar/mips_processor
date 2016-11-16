-------------------------------------------------------------------------------
-- Title      : Register File
-- Project    : 
-------------------------------------------------------------------------------
-- File       : RegisterFile.vhd
-- Author     : Robert Jarzmik  <robert.jarzmik@free.fr>
-- Company    : 
-- Created    : 2016-11-12
-- Last update: 2016-11-16
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: MIPS Register File, 32 registers
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-11-12  1.0      rj      Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity RegisterFile is

  generic (
    DATA_WIDTH           : positive := 32;
    NB_REGISTERS         : positive := 32;  -- r0 to r31
    NB_REGISTERS_SPECIAL : positive := 2    -- mflo and mfhi
    );

  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    a_idx : in  natural range 0 to NB_REGISTERS + NB_REGISTERS_SPECIAL - 1;
    b_idx : in  natural range 0 to NB_REGISTERS + NB_REGISTERS_SPECIAL - 1;
    -- Writeback register
    w_en  : in  std_logic;
    w_idx : in  natural range 0 to NB_REGISTERS + NB_REGISTERS_SPECIAL - 1;
    w     : in  std_logic_vector(DATA_WIDTH * 2 - 1 downto 0);
    a     : out std_logic_vector(DATA_WIDTH - 1 downto 0);
    b     : out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );

end entity RegisterFile;

-------------------------------------------------------------------------------

architecture rtl of RegisterFile is

  -----------------------------------------------------------------------------
  -- Internal signal declarations
  -----------------------------------------------------------------------------
  type r_array is array (0 to NB_REGISTERS + NB_REGISTERS_SPECIAL - 1) of
    std_logic_vector(DATA_WIDTH -1 downto 0);
  signal registers : r_array := (
    x"00000000",                        -- r0
    x"00000001",                        -- r1
    x"00000002",
    x"00000003",
    x"00000004",
    x"00000005",
    x"00000006",
    x"00000007",
    x"00000008",
    x"00000009",
    x"0000000a",
    x"0000000b",
    x"0000000c",
    x"0000000d",
    x"0000000e",
    x"0000000f",
    x"00000010",
    x"00000011",
    x"00000012",
    x"00000013",
    x"00000014",
    x"00000015",
    x"00000016",
    x"00000017",
    x"00000018",
    x"00000019",
    x"0000001a",
    x"0000001b",
    x"0000001c",
    x"0000001d",
    x"0000001e",
    x"0000001f",                        -- r_NB_REGISTERS-1
    x"11000000",                        -- mflo
    x"22000000"                         -- mfhi
    );

begin  -- architecture rtl

  -----------------------------------------------------------------------------
  -- Component instantiations
  -----------------------------------------------------------------------------

  process(rst, clk, w_en)
  begin
    if rst = '1' then
    elsif rising_edge(clk) and w_en = '1' then
      if w_idx = NB_REGISTERS then
        registers(NB_REGISTERS)     <= w(DATA_WIDTH - 1 downto 0);
        registers(NB_REGISTERS + 1) <= w(DATA_WIDTH * 2 - 1 downto DATA_WIDTH);
      elsif w_idx < NB_REGISTERS then
        registers(w_idx) <= w(DATA_WIDTH - 1 downto 0);
      end if;
    end if;
  end process;

  a <= registers(a_idx);
  b <= registers(b_idx);

end architecture rtl;

-------------------------------------------------------------------------------
