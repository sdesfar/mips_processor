-------------------------------------------------------------------------------
-- Title      : Arithmetic and Logic Unit
-- Project    : 
-------------------------------------------------------------------------------
-- File       : ALU.vhd.vhd
-- Author     : Robert Jarzmik (Intel)  <robert.jarzmik@free.fr>
-- Company    : 
-- Created    : 2016-11-16
-- Last update: 2016-11-17
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Integer Computing Unit
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-11-16  1.0      rjarzmik        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cpu_defs.all;

-------------------------------------------------------------------------------

entity ALU is

  generic (
    ADDR_WIDTH   : integer  := 32;
    DATA_WIDTH   : integer  := 32;
    NB_REGISTERS : positive := 32
    );

  port (
    clk           : in  std_logic;
    rst           : in  std_logic;
    stall_req     : in  std_logic;
    alu_op        : in  alu_op_type;
    ra            : in  unsigned(DATA_WIDTH - 1 downto 0);
    rb            : in  unsigned(DATA_WIDTH - 1 downto 0);
    result        : out unsigned(DATA_WIDTH * 2 - 1 downto 0);
    -- Carry-over signals
    i_rwrite_en   : in  std_logic;
    i_rwritei     : in  natural range 0 to NB_REGISTERS - 1;
    i_jump_target : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
    i_jump_op     : in  jump_type;
    i_mem_data    : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
    i_mem_op      : in  memory_op_type;
    o_rwrite_en   : out std_logic;
    o_rwritei     : out natural range 0 to NB_REGISTERS - 1;
    o_jump_target : out std_logic_vector(ADDR_WIDTH - 1 downto 0);
    o_is_jump     : out std_logic;
    o_mem_data    : out std_logic_vector(DATA_WIDTH - 1 downto 0);
    o_mem_op      : out memory_op_type
    );

end entity ALU;

-------------------------------------------------------------------------------

architecture rtl of ALU is

  -----------------------------------------------------------------------------
  -- Internal signal declarations
  -----------------------------------------------------------------------------
  signal q          : unsigned(DATA_WIDTH * 2 downto 0);
  signal cond_zero  : std_logic;
  signal cond_carry : std_logic;

  -----------------------------------------------------------------------------
  -- Internal decoder procedures
  -----------------------------------------------------------------------------
  procedure do_branch(
    signal i_jump_op  : in  jump_type;
    signal cond_zero  : in  std_logic;
    signal cond_carry : in  std_logic;
    signal o_is_jump  : out std_logic) is
  begin
    case i_jump_op is
      when none =>
        o_is_jump <= '0';
      when always =>
        o_is_jump <= '1';
      when zero =>
        if cond_zero = '1' then
          o_is_jump <= '1';
        else
          o_is_jump <= '0';
        end if;
      when non_zero =>
        if cond_zero = '0' then
          o_is_jump <= '1';
        else
          o_is_jump <= '0';
        end if;
      when lesser_or_zero =>
        if cond_carry = '1' or cond_zero = '1' then
          o_is_jump <= '1';
        else
          o_is_jump <= '0';
        end if;
      when greater =>
        if cond_carry = '0' then
          o_is_jump <= '1';
        else
          o_is_jump <= '0';
        end if;
      when lesser =>
        if cond_carry = '1' then
          o_is_jump <= '1';
        else
          o_is_jump <= '0';
        end if;
      when greater_or_zero =>
        if cond_carry = '0' or cond_zero = '1' then
          o_is_jump <= '1';
        else
          o_is_jump <= '0';
        end if;
    end case;
  end procedure do_branch;

begin  -- architecture rtl

  -----------------------------------------------------------------------------
  -- Component instantiations
  -----------------------------------------------------------------------------

  process(rst, clk, stall_req)
  begin
    if rst = '1' then
      q <= (others => '0');
    elsif stall_req = '0' and rising_edge(clk) then
      case alu_op is
        when all_zero =>
          q <= (others => '0');
        when add =>
          q(DATA_WIDTH downto 0) <= resize(ra, DATA_WIDTH + 1) + resize(rb, DATA_WIDTH + 1);
        when substract =>
          q(DATA_WIDTH downto 0) <= resize(ra, DATA_WIDTH + 1) - resize(rb, DATA_WIDTH + 1);
        when multiply =>
          q(DATA_WIDTH * 2 - 1 downto 0) <= ra * rb;
        when divide =>
          q(DATA_WIDTH - 1 downto 0)              <= ra / rb;
          q(DATA_WIDTH * 2 - 1 downto DATA_WIDTH) <= ra rem rb;
        when log_and =>
          q(DATA_WIDTH - 1 downto 0) <= ra and rb;
        when log_or =>
          q(DATA_WIDTH - 1 downto 0) <= ra or rb;
        when log_xor =>
          q(DATA_WIDTH - 1 downto 0) <= ra xor rb;
        when log_nor =>
          q(DATA_WIDTH - 1 downto 0) <= ra nor rb;
        when slt =>
          if unsigned(ra) < unsigned(rb) then
            q <= (0 => '1', others => '0');
          else
            q <= (others => '0');
          end if;
      end case;

      do_branch(i_jump_op, cond_zero, cond_carry, o_is_jump);

      o_rwrite_en   <= i_rwrite_en;
      o_rwritei     <= i_rwritei;
      o_jump_target <= i_jump_target;
      o_mem_data    <= i_mem_data;
      o_mem_op      <= i_mem_op;
    end if;
  end process;

  result     <= q(DATA_WIDTH * 2 - 1 downto 0);
  cond_zero  <= '1' when unsigned(q) = to_unsigned(0, DATA_WIDTH);
  cond_carry <= q(DATA_WIDTH);

end architecture rtl;

-------------------------------------------------------------------------------
