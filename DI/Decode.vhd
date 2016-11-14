-------------------------------------------------------------------------------
-- Title      : Decode and Issue instruction
-- Project    : 
-------------------------------------------------------------------------------
-- File       : Decode.vhd
-- Author     : Robert Jarzmik  <robert.jarzmik@free.fr>
-- Company    : 
-- Created    : 2016-11-12
-- Last update: 2016-11-14
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Decode and Issue a MIPS instruction
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-11-12  1.0      rj      Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-------------------------------------------------------------------------------

entity Decode is

  generic (
    ADDR_WIDTH   : integer  := 32;
    DATA_WIDTH   : integer  := 32;
    NB_REGISTERS : positive := 32
    );

  port (
    clk         : in  std_logic;
    rst         : in  std_logic;
    instruction : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
    pc          : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
    ra          : out std_logic_vector(DATA_WIDTH - 1 downto 0);
    rb          : out std_logic_vector(DATA_WIDTH - 1 downto 0);
    rdi         : out natural range 0 to NB_REGISTERS - 1
    );

  constant op_rtype : std_logic_vector(5 downto 0) := "000000";

  constant op_addi  : std_logic_vector(5 downto 0) := "001000";
  constant op_addiu : std_logic_vector(5 downto 0) := "001001";
  constant op_slti  : std_logic_vector(5 downto 0) := "001010";
  constant op_sltiu : std_logic_vector(5 downto 0) := "001011";
  constant op_andi  : std_logic_vector(5 downto 0) := "001100";
  constant op_ori   : std_logic_vector(5 downto 0) := "001101";
  constant op_xori  : std_logic_vector(5 downto 0) := "001110";

  constant op_lui : std_logic_vector(5 downto 0) := "001111";
  constant op_lb  : std_logic_vector(5 downto 0) := "100000";
  constant op_lw  : std_logic_vector(5 downto 0) := "100011";
  constant op_lbu : std_logic_vector(5 downto 0) := "100100";
  constant op_sb  : std_logic_vector(5 downto 0) := "101000";
  constant op_sw  : std_logic_vector(5 downto 0) := "101011";

  constant op_beq  : std_logic_vector(5 downto 0) := "000100";
  constant op_bne  : std_logic_vector(5 downto 0) := "000101";
  constant op_blez : std_logic_vector(5 downto 0) := "000110";
  constant op_bgtz : std_logic_vector(5 downto 0) := "000111";
  constant op_bltz : std_logic_vector(5 downto 0) := "000001";

  constant op_j   : std_logic_vector(5 downto 0) := "000001";
  constant op_jal : std_logic_vector(5 downto 0) := "000011";

  constant func_mul  : std_logic_vector(5 downto 0) := "011000";
  constant func_mulu : std_logic_vector(5 downto 0) := "011001";
  constant func_div  : std_logic_vector(5 downto 0) := "011010";
  constant func_divu : std_logic_vector(5 downto 0) := "011011";
  constant func_add  : std_logic_vector(5 downto 0) := "100000";
  constant func_addu : std_logic_vector(5 downto 0) := "100001";
  constant func_sub  : std_logic_vector(5 downto 0) := "100010";
  constant func_subu : std_logic_vector(5 downto 0) := "100011";
  constant func_slt  : std_logic_vector(5 downto 0) := "101010";
  constant func_sltu : std_logic_vector(5 downto 0) := "101011";
  constant func_and  : std_logic_vector(5 downto 0) := "100100";
  constant func_or   : std_logic_vector(5 downto 0) := "100101";
  constant func_nor  : std_logic_vector(5 downto 0) := "100111";
  constant func_xor  : std_logic_vector(5 downto 0) := "101000";
  constant func_jr   : std_logic_vector(5 downto 0) := "001000";
  constant func_jalr : std_logic_vector(5 downto 0) := "001001";
  constant func_mfhi : std_logic_vector(5 downto 0) := "010000";
  constant func_mflo : std_logic_vector(5 downto 0) := "010010";

end entity Decode;

-------------------------------------------------------------------------------

architecture rtl of Decode is

  component RegisterFile
    port (
      a_idx : in  natural range 0 to NB_REGISTERS - 1;
      b_idx : in  natural range 0 to NB_REGISTERS - 1;
      a     : out std_logic_vector(DATA_WIDTH - 1 downto 0);
      b     : out std_logic_vector(DATA_WIDTH - 1 downto 0)
      );
  end component RegisterFile;

  -----------------------------------------------------------------------------
  -- Internal signal declarations
  -----------------------------------------------------------------------------
  signal op_code       : std_logic_vector(5 downto 0);
  signal rsi           : natural range 0 to NB_REGISTERS - 1;
  signal rti           : natural range 0 to NB_REGISTERS - 1;
  signal func          : natural range 0 to 31;
  signal rs            : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal rt            : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal immediate     : std_logic_vector(DATA_WIDTH / 2 - 1 downto 0);
  signal rtype         : std_logic;
  signal decode_error  : std_logic;
  signal use_immediate : std_logic;

begin  -- architecture rtl

  -----------------------------------------------------------------------------
  -- Component instantiations
  -----------------------------------------------------------------------------
  rfile : RegisterFile port map (
    a_idx => rsi,
    b_idx => rti,
    a     => rs,
    b     => rt
    );

  process(rst, clk)
  begin
    if rst = '1' then
      ra           <= std_logic_vector(to_unsigned(0, DATA_WIDTH));
      rb           <= std_logic_vector(to_unsigned(0, DATA_WIDTH));
      decode_error <= '0';
    else
      if rising_edge(clk) then
        if (op_code = op_rtype) then
          ra           <= rs;
          rb           <= rt;
          rdi          <= to_integer(unsigned(instruction(15 downto 11)));
          decode_error <= '0';
        elsif use_immediate = '1' then
          ra                                       <= rs;
          rb(DATA_WIDTH - 1 downto DATA_WIDTH / 2) <= std_logic_vector(to_unsigned(0, DATA_WIDTH / 2));
          rb(DATA_WIDTH / 2 -1 downto 0)           <= immediate;
          rdi                                      <= to_integer(unsigned(instruction(15 downto 11)));
          decode_error                             <= '0';
        else
          decode_error <= '1';
        end if;
      end if;
    end if;
  end process;

  op_code   <= instruction(31 downto 26);
  rsi       <= to_integer(unsigned(instruction(25 downto 21)));
  rti       <= to_integer(unsigned(instruction(20 downto 16)));
  immediate <= instruction(15 downto 0);
  use_immediate <= '1' when ((op_code >= op_addi and op_code <= op_xori) or
                             (op_code = op_lui) or
                             (op_code = op_lb) or
                             (op_code = op_lw) or
                             (op_code = op_lbu) or
                             (op_code = op_sb) or
                             (op_code = op_sw) or
                             (op_code = op_beq) or
                             (op_code = op_bne) or
                             (op_code = op_blez) or
                             (op_code = op_bgtz) or
                             (op_code = op_bltz));

end architecture rtl;

-------------------------------------------------------------------------------
