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

use work.cpu_defs.all;

-------------------------------------------------------------------------------

entity MIPS_CPU is

  generic (
    ADDR_WIDTH   : integer := 32;
    DATA_WIDTH   : integer := 32;
    NB_REGISTERS : integer := 32
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
      ADDR_WIDTH   : integer;
      DATA_WIDTH   : integer;
      NB_REGISTERS : positive);
    port (
      clk         : in  std_logic;
      rst         : in  std_logic;
      stall_req   : in  std_logic;
      instruction : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
      pc          : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
      alu_op      : out alu_op_type;
      ra          : out std_logic_vector(DATA_WIDTH - 1 downto 0);
      rb          : out std_logic_vector(DATA_WIDTH - 1 downto 0);
      rwritei     : out natural range 0 to NB_REGISTERS;
      jump_target : out std_logic_vector(ADDR_WIDTH - 1 downto 0);
      jump_op     : out jump_type;
      mem_data    : out std_logic_vector(DATA_WIDTH - 1 downto 0);
      mem_op      : out memory_op_type);
  end component Decode;

  -----------------------------------------------------------------------------
  -- Internal signal declarations
  -----------------------------------------------------------------------------
  signal current_pc          : std_logic_vector(ADDR_WIDTH - 1 downto 0);
  signal jump_target         : std_logic_vector(ADDR_WIDTH - 1 downto 0);
  signal fetched_instruction : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal alu_op              : alu_op_type;
  signal ra                  : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal rb                  : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal rwritei             : natural range 0 to NB_REGISTERS;
  signal stall_pc            : std_logic;
  signal jump_pc             : std_logic;
  signal decode_jump_target  : std_logic_vector(ADDR_WIDTH - 1 downto 0);
  signal decode_jump_op      : jump_type;
  signal decode_mem_data     : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal decode_mem_op       : memory_op_type;

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
      jump_pc     => jump_pc,
      jump_target => jump_target,
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
      ADDR_WIDTH   => ADDR_WIDTH,
      DATA_WIDTH   => DATA_WIDTH,
      NB_REGISTERS => NB_REGISTERS)
    port map (
      clk         => clk,
      rst         => rst,
      stall_req   => '0',
      instruction => fetched_instruction,
      pc          => current_pc,
      alu_op      => alu_op,
      ra          => ra,
      rb          => rb,
      rwritei     => rwritei,
      jump_target => decode_jump_target,
      jump_op     => decode_jump_op,
      mem_data    => decode_mem_data,
      mem_op      => decode_mem_op);

  stall_pc <= '0';
  jump_pc  <= '0';

end architecture rtl;

-------------------------------------------------------------------------------
