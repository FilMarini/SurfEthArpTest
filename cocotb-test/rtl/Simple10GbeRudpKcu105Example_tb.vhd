-------------------------------------------------------------------------------
-- Title      : Testbench for design "Simple10GbeRudpKcu105Example"
-- Project    : 
-------------------------------------------------------------------------------
-- File       : Simple10GbeRudpKcu105Example_tb.vhd
-- Author     : Filippo Marini  <filippo.marini@pd.infn.it>
-- Company    : INFN Padova
-- Created    : 2025-01-14
-- Last update: 2025-01-14
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2025 INFN Padova
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2025-01-14  1.0      fmarini Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;
use surf.AxiLitePkg.all;
-------------------------------------------------------------------------------

entity Simple10GbeRudpKcu105Example_tb is

end entity Simple10GbeRudpKcu105Example_tb;

-------------------------------------------------------------------------------

architecture behav of Simple10GbeRudpKcu105Example_tb is

  -- component generics
  constant TPD_G        : time             := 1 ns;
  constant BUILD_INFO_G : BuildInfoType;
  constant SIMULATION_G : boolean          := false;
  constant IP_ADDR_G    : slv(31 downto 0) := x"0A02A8C0";
  constant DHCP_G       : boolean          := false;

  -- component ports
  signal sfpTxDisL  : sl;
  signal i2cRstL    : sl;
  signal i2cScl     : sl;
  signal i2cSda     : sl;
  signal vPIn       : sl;
  signal vNIn       : sl;
  signal emcClk     : sl := '1';
  signal extRst     : sl;
  signal led        : slv(7 downto 0);
  signal flashCsL   : sl;
  signal flashMosi  : sl;
  signal flashMiso  : sl;
  signal flashHoldL : sl;
  signal flashWp    : sl;
  signal ethClkP    : sl := '1';
  signal ethClkN    : sl;
  signal ethRxP     : sl;
  signal ethRxN     : sl;
  signal ethTxP     : sl;
  signal ethTxN     : sl;

begin  -- architecture behav

  -- component instantiation
  DUT : entity work.Simple10GbeRudpKcu105Example
    generic map (
      TPD_G        => TPD_G,
      BUILD_INFO_G => BUILD_INFO_G,
      SIMULATION_G => SIMULATION_G,
      IP_ADDR_G    => IP_ADDR_G,
      DHCP_G       => DHCP_G)
    port map (
      sfpTxDisL  => sfpTxDisL,
      i2cRstL    => i2cRstL,
      i2cScl     => i2cScl,
      i2cSda     => i2cSda,
      vPIn       => vPIn,
      vNIn       => vNIn,
      emcClk     => emcClk,
      extRst     => extRst,
      led        => led,
      flashCsL   => flashCsL,
      flashMosi  => flashMosi,
      flashMiso  => flashMiso,
      flashHoldL => flashHoldL,
      flashWp    => flashWp,
      ethClkP    => ethClkP,
      ethClkN    => ethClkN,
      ethRxP     => ethRxP,
      ethRxN     => ethRxN,
      ethTxP     => ethTxP,
      ethTxN     => ethTxN);

  -- clock generation
  ethClkP <= not ethClkP after 3.2 ns;
  ethClkN <= not ethClkP;
  emcClk  <= not emcClk  after 5.556 ns;


end architecture behav;

-------------------------------------------------------------------------------

-- configuration Simple10GbeRudpKcu105Example_tb_behav_cfg of Simple10GbeRudpKcu105Example_tb is
--   for behav
--   end for;
-- end Simple10GbeRudpKcu105Example_tb_behav_cfg;

-------------------------------------------------------------------------------
