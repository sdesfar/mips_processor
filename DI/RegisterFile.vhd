-------------------------------------------------------------------------------
-- Title      : Register File
-- Project    : 
-------------------------------------------------------------------------------
-- File       : RegisterFile.vhd
-- Author     : Robert Jarzmik  <robert.jarzmik@free.fr>
-- Company    : 
-- Created    : 2016-11-12
-- Last update: 2016-11-18
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
    clk           : in  std_logic;
    rst           : in  std_logic;
    a_idx         : in  natural range 0 to NB_REGISTERS + NB_REGISTERS_SPECIAL - 1;
    b_idx         : in  natural range 0 to NB_REGISTERS + NB_REGISTERS_SPECIAL - 1;
    -- Writeback register
    rwb_reg1_we   : in  std_logic;
    rwb_reg1_idx  : in  natural range 0 to NB_REGISTERS + NB_REGISTERS_SPECIAL - 1;
    rwb_reg1_data : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
    rwb_reg2_we   : in  std_logic;
    rwb_reg2_idx  : in  natural range 0 to NB_REGISTERS + NB_REGISTERS_SPECIAL - 1;
    rwb_reg2_data : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
    -- Output read registers
    a             : out std_logic_vector(DATA_WIDTH - 1 downto 0);
    b             : out std_logic_vector(DATA_WIDTH - 1 downto 0)
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

  process(rst, clk, rwb_reg1_we, rwb_reg2_we)
  begin
    if rst = '1' then
    elsif rising_edge(clk) then
      if rwb_reg1_we = '1' then
        registers(rwb_reg1_idx) <= rwb_reg1_data;
      end if;
      if rwb_reg2_we = '1' then
        registers(rwb_reg2_idx) <= rwb_reg2_data;
      end if;
    end if;
  end process;

  a <= registers(a_idx);
  b <= registers(b_idx);

end architecture rtl;

-------------------------------------------------------------------------------
