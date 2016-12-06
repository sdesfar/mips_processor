-------------------------------------------------------------------------------
-- Title      : Arithmetic and Logic Unit
-- Project    : 
-------------------------------------------------------------------------------
-- File       : ALU.vhd.vhd
-- Author     : Robert Jarzmik (Intel)  <robert.jarzmik@free.fr>
-- Company    : 
-- Created    : 2016-11-16
-- Last update: 2016-12-02
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
    stall_req     : in  std_logic;      -- stall current instruction
    kill_req      : in  std_logic;      -- kill current instruction
    alu_op        : in  alu_op_type;
    i_reg1        : in  register_port_type;
    i_reg2        : in  register_port_type;
    -- Carry-over signals
    i_jump_target : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
    i_jump_op     : in  jump_type;
    i_mem_data    : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
    i_mem_op      : in  memory_op_type;
    o_reg1        : out register_port_type;
    o_reg2        : out register_port_type;
    o_jump_target : out std_logic_vector(ADDR_WIDTH - 1 downto 0);
    o_is_jump     : out std_logic;
    o_mem_data    : out std_logic_vector(DATA_WIDTH - 1 downto 0);
    o_mem_op      : out memory_op_type;
    -- Debug signal
    i_dbg_ex_pc    : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
    o_dbg_ex_pc    : out std_logic_vector(ADDR_WIDTH - 1 downto 0)
    );

end entity ALU;

-------------------------------------------------------------------------------

architecture rtl of ALU is
  signal ra : unsigned(DATA_WIDTH - 1 downto 0);
  signal rb : unsigned(DATA_WIDTH - 1 downto 0);

  -----------------------------------------------------------------------------
  -- Internal signal declarations
  -----------------------------------------------------------------------------
  signal q          : unsigned(DATA_WIDTH * 2 - 1 downto 0);
  signal cond_zero  : std_logic;
  signal cond_carry : std_logic;
  signal jump_op    : jump_type;

begin  -- architecture rtl

  -----------------------------------------------------------------------------
  -- Component instantiations
  -----------------------------------------------------------------------------

  process(rst, clk, kill_req, stall_req)
  begin
    if rst = '1' then
      q       <= (others => '0');
      jump_op <= none;
    elsif kill_req = '1' and rising_edge(clk) then
      o_reg1.we     <= '0';
      o_reg1.idx    <= 0;
      o_reg2.we     <= '0';
      o_reg2.idx    <= 0;
      jump_op       <= none;
      o_jump_target <= (others => '0');
      o_mem_data    <= (others => '0');
      o_mem_op      <= none;
    elsif stall_req = '0' and rising_edge(clk) then
      case alu_op is
        when all_zero =>
          q <= (others => '0');
        when add =>
          q(DATA_WIDTH downto 0) <= resize(ra, DATA_WIDTH + 1) + resize(rb, DATA_WIDTH + 1);
        when substract =>
          q(DATA_WIDTH downto 0) <= resize(ra, DATA_WIDTH + 1) - resize(rb, DATA_WIDTH + 1);
        when multiply =>
          q <= ra * rb;
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
            q(DATA_WIDTH - 1 downto 0) <= to_unsigned(1, DATA_WIDTH);
          else
            q(DATA_WIDTH - 1 downto 0) <= (others => '0');
          end if;
      end case;

      o_reg1.we     <= i_reg1.we;
      o_reg1.idx    <= i_reg1.idx;
      o_reg2.we     <= i_reg2.we;
      o_reg2.idx    <= i_reg2.idx;
      o_jump_target <= i_jump_target;
      o_mem_data    <= i_mem_data;
      o_mem_op      <= i_mem_op;
      jump_op       <= i_jump_op;
    end if;
  end process;

  debug : process(rst, clk, stall_req, kill_req)
  begin
    if rst = '1' then
      o_dbg_ex_pc <= (others => 'X');
    elsif rising_edge(clk) and kill_req = '1' then
      o_dbg_ex_pc <= (others => 'X');
    elsif rising_edge(clk) and stall_req = '1' then
    elsif rising_edge(clk) then
      o_dbg_ex_pc <= i_dbg_ex_pc;
    end if;
  end process debug;

  ra          <= unsigned(i_reg1.data);
  rb          <= unsigned(i_reg2.data);
  o_reg1.data <= std_logic_vector(q(DATA_WIDTH -1 downto 0));
  o_reg2.data <= std_logic_vector(q(DATA_WIDTH * 2 -1 downto DATA_WIDTH));
  cond_zero   <= '1' when unsigned(q) = to_unsigned(0, q'length) else '0';
  cond_carry  <= q(DATA_WIDTH);

  o_is_jump <= '1' when
               (jump_op = always) or
               (jump_op = zero and cond_zero = '1') or
               (jump_op = non_zero and cond_zero = '0') or
               (jump_op = lesser_or_zero and (cond_carry = '1' or cond_zero = '1')) or
               (jump_op = lesser and cond_carry = '1') or
               (jump_op = greater and cond_carry = '0') or
               (jump_op = greater_or_zero and (cond_carry = '0' or cond_zero = '1'))
               else '0';

end architecture rtl;

-------------------------------------------------------------------------------
