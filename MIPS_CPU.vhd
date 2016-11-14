-------------------------------------------------------------------------------
-- Title      : MIPS Processor
-- Project    : 
-------------------------------------------------------------------------------
-- File       : MIPS_CPU.vhd
-- Author     : Robert Jarzmik  <robert.jarzmik@free.fr>
-- Company    : 
-- Created    : 2016-11-11
-- Last update: 2016-11-14
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

-------------------------------------------------------------------------------

entity MIPS_CPU is

  generic (
    ADDR_WIDTH : integer := 32;
    DATA_WIDTH : integer := 32
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

  component Decode
    port (
      clk         : in  std_logic;
      rst         : in  std_logic;
      stall_req   : in  std_logic;
      instruction : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
      pc          : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
      ra          : out std_logic_vector(DATA_WIDTH - 1 downto 0);
      rb          : out std_logic_vector(DATA_WIDTH - 1 downto 0)
      );
  end component Decode;

  -----------------------------------------------------------------------------
  -- Internal signal declarations
  -----------------------------------------------------------------------------
  signal current_pc          : std_logic_vector(ADDR_WIDTH - 1 downto 0);
  signal jump_target         : std_logic_vector(ADDR_WIDTH - 1 downto 0);
  signal fetched_instruction : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal ra                  : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal rb                  : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal stall_pc            : std_logic;
  signal jump_pc             : std_logic;

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
    port map (
      clk         => clk,
      rst         => rst,
      stall_req   => '0',
      instruction => fetched_instruction,
      pc          => current_pc,
      ra          => ra,
      rb          => rb
      );

  stall_pc <= '0';
  jump_pc  <= '0';

end architecture rtl;

-------------------------------------------------------------------------------
