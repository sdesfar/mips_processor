-------------------------------------------------------------------------------
-- Title      : MIPS Processor
-- Project    : 
-------------------------------------------------------------------------------
-- File       : MIPS_CPU.vhd
-- Author     : Robert Jarzmik  <robert.jarzmik@free.fr>
-- Company    : 
-- Created    : 2016-11-11
-- Last update: 2016-11-16
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: A MIPS v1 processor, not pipelined
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-11-11  1.0      rj      Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cpu_defs.all;

-------------------------------------------------------------------------------

entity MIPS_CPU is

  generic (
    ADDR_WIDTH           : integer  := 32;
    DATA_WIDTH           : integer  := 32;
    NB_REGISTERS         : positive := 32;  -- r0 to r31
    NB_REGISTERS_SPECIAL : positive := 2    -- mflo and mfhi
    );

  port (
    clk : in std_logic;
    rst : in std_logic
    );

end entity MIPS_CPU;

-------------------------------------------------------------------------------

architecture rtl of MIPS_CPU is

  component PC_Register is
    generic (
      ADDR_WIDTH : integer;
      STEP       : integer);
    port (
      clk         : in  std_logic;
      rst         : in  std_logic;
      stall_pc    : in  std_logic;
      jump_pc     : in  std_logic;
      jump_target : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
      current_pc  : out std_logic_vector(ADDR_WIDTH - 1 downto 0));
  end component PC_Register;

  component Fetch
    port (
      clk         : in  std_logic;
      rst         : in  std_logic;
      stall_req   : in  std_logic;
      pc          : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
      instruction : out std_logic_vector(DATA_WIDTH - 1 downto 0)
      );
  end component Fetch;

  component Decode is
    generic (
      ADDR_WIDTH           : integer;
      DATA_WIDTH           : integer;
      NB_REGISTERS         : positive;
      NB_REGISTERS_SPECIAL : positive);
    port (
      clk         : in  std_logic;
      rst         : in  std_logic;
      stall_req   : in  std_logic;
      instruction : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
      pc          : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
      rwb_en      : in  std_logic;
      rwbi        : in  natural range 0 to NB_REGISTERS + NB_REGISTERS_SPECIAL - 1;
      rwb_data    : in  std_logic_vector(DATA_WIDTH * 2 -1 downto 0);
      alu_op      : out alu_op_type;
      ra          : out std_logic_vector(DATA_WIDTH - 1 downto 0);
      rb          : out std_logic_vector(DATA_WIDTH - 1 downto 0);
      rwrite_en   : out std_logic;
      rwritei     : out natural range 0 to NB_REGISTERS + NB_REGISTERS_SPECIAL - 1;
      jump_target : out std_logic_vector(ADDR_WIDTH - 1 downto 0);
      jump_op     : out jump_type;
      mem_data    : out std_logic_vector(DATA_WIDTH - 1 downto 0);
      mem_op      : out memory_op_type);
  end component Decode;

  component ALU is
    generic (
      DATA_WIDTH : integer);
    port (
      clk           : in  std_logic;
      rst           : in  std_logic;
      stall_req     : in  std_logic;
      alu_op        : in  alu_op_type;
      ra            : in  unsigned(DATA_WIDTH - 1 downto 0);
      rb            : in  unsigned(DATA_WIDTH - 1 downto 0);
      result        : out unsigned(DATA_WIDTH * 2 - 1 downto 0);
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
      o_mem_op      : out memory_op_type);
  end component ALU;

  component Writeback is
    generic (
      ADDR_WIDTH           : integer;
      DATA_WIDTH           : integer;
      NB_REGISTERS         : positive;
      NB_REGISTERS_SPECIAL : positive);
    port (
      clk           : in  std_logic;
      rst           : in  std_logic;
      stall_req     : in  std_logic;
      i_rwrite_en   : in  std_logic;
      i_rwritei     : in  natural range 0 to NB_REGISTERS + NB_REGISTERS_SPECIAL - 1;
      i_rwrite_data : in  std_logic_vector(DATA_WIDTH * 2 - 1 downto 0);
      i_jump_target : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
      i_is_jump     : in  std_logic;
      o_rwrite_en   : out std_logic;
      o_rwritei     : out natural range 0 to NB_REGISTERS + NB_REGISTERS_SPECIAL - 1;
      o_rwrite_data : out std_logic_vector(DATA_WIDTH * 2 - 1 downto 0);
      o_is_jump     : out std_logic;
      o_jump_target : out std_logic_vector(ADDR_WIDTH - 1 downto 0));
  end component Writeback;

  -----------------------------------------------------------------------------
  -- Internal signal declarations
  -----------------------------------------------------------------------------
  signal current_pc          : std_logic_vector(ADDR_WIDTH - 1 downto 0);
  signal jump_target         : std_logic_vector(ADDR_WIDTH - 1 downto 0);
  signal fetched_instruction : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal alu_op              : alu_op_type;
  signal ra                  : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal rb                  : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal ra_unsigned         : unsigned(DATA_WIDTH - 1 downto 0);
  signal rb_unsigned         : unsigned(DATA_WIDTH - 1 downto 0);
  signal result              : unsigned(DATA_WIDTH * 2 - 1 downto 0);
  signal stall_pc            : std_logic;
  signal jump_pc             : std_logic;
  signal decode_rwrite_en    : std_logic;
  signal decode_rwritei      : natural range 0 to NB_REGISTERS - 1;
  signal decode_jump_target  : std_logic_vector(ADDR_WIDTH - 1 downto 0);
  signal decode_jump_op      : jump_type;
  signal decode_mem_data     : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal decode_mem_op       : memory_op_type;

  signal execute_rwrite_en   : std_logic;
  signal execute_rwritei     : natural range 0 to NB_REGISTERS - 1;
  signal execute_jump_target : std_logic_vector(ADDR_WIDTH - 1 downto 0);
  signal execute_is_jump     : std_logic;
  signal execute_mem_data    : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal execute_mem_op      : memory_op_type;

  signal wb_result      : std_logic_vector(DATA_WIDTH * 2 - 1 downto 0);
  signal rwb_en         : std_logic;
  signal rwbi           : natural range 0 to NB_REGISTERS + NB_REGISTERS_SPECIAL - 1;
  signal rwb_data       : std_logic_vector(DATA_WIDTH * 2 -1 downto 0);
  signal wb_is_jump     : std_logic;
  signal wb_jump_target : std_logic_vector(ADDR_WIDTH - 1 downto 0);

begin  -- architecture rtl

  -----------------------------------------------------------------------------
  -- Component instantiations
  -----------------------------------------------------------------------------
  pc_reg : PC_Register
    generic map (
      ADDR_WIDTH => ADDR_WIDTH,
      STEP       => 4)
    port map (
      clk         => clk,
      rst         => rst,
      stall_pc    => stall_pc,
      jump_pc     => wb_is_jump,
      jump_target => wb_jump_target,
      current_pc  => current_pc);

  ife : Fetch
    port map (
      clk         => clk,
      rst         => rst,
      stall_req   => '0',
      pc          => current_pc,
      instruction => fetched_instruction
      );

  di : Decode
    generic map (
      ADDR_WIDTH           => ADDR_WIDTH,
      DATA_WIDTH           => DATA_WIDTH,
      NB_REGISTERS         => NB_REGISTERS,
      NB_REGISTERS_SPECIAL => NB_REGISTERS_SPECIAL)
    port map (
      clk         => clk,
      rst         => rst,
      stall_req   => '0',
      instruction => fetched_instruction,
      pc          => current_pc,
      rwb_en      => rwb_en,
      rwbi        => rwbi,
      rwb_data    => rwb_data,
      alu_op      => alu_op,
      ra          => ra,
      rb          => rb,
      rwrite_en   => decode_rwrite_en,
      rwritei     => decode_rwritei,
      jump_target => decode_jump_target,
      jump_op     => decode_jump_op,
      mem_data    => decode_mem_data,
      mem_op      => decode_mem_op);

  ex : ALU
    generic map (
      DATA_WIDTH => DATA_WIDTH)
    port map (
      clk           => clk,
      rst           => rst,
      stall_req     => '0',
      alu_op        => alu_op,
      ra            => ra_unsigned,
      rb            => rb_unsigned,
      result        => result,
      i_rwrite_en   => decode_rwrite_en,
      i_rwritei     => decode_rwritei,
      i_jump_target => decode_jump_target,
      i_jump_op     => decode_jump_op,
      i_mem_data    => decode_mem_data,
      i_mem_op      => decode_mem_op,
      o_rwrite_en   => execute_rwrite_en,
      o_rwritei     => execute_rwritei,
      o_jump_target => execute_jump_target,
      o_is_jump     => execute_is_jump,
      o_mem_data    => execute_mem_data,
      o_mem_op      => execute_mem_op);

  wb : Writeback
    generic map (
      ADDR_WIDTH           => ADDR_WIDTH,
      DATA_WIDTH           => DATA_WIDTH,
      NB_REGISTERS         => NB_REGISTERS,
      NB_REGISTERS_SPECIAL => NB_REGISTERS_SPECIAL)
    port map (
      clk           => clk,
      rst           => rst,
      stall_req     => '0',
      i_rwrite_en   => execute_rwrite_en,
      i_rwritei     => execute_rwritei,
      i_rwrite_data => wb_result,
      i_jump_target => execute_jump_target,
      i_is_jump     => execute_is_jump,
      o_rwrite_en   => rwb_en,
      o_rwritei     => rwbi,
      o_rwrite_data => rwb_data,
      o_is_jump     => wb_is_jump,
      o_jump_target => wb_jump_target);

  stall_pc    <= '0';
  ra_unsigned <= unsigned(ra);
  rb_unsigned <= unsigned(rb);
  wb_result   <= std_logic_vector(result);

end architecture rtl;

-------------------------------------------------------------------------------
