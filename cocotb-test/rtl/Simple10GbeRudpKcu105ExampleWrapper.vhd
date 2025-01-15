-------------------------------------------------------------------------------
-- Title      : Testbench for design "Simple10GbeRudpKcu105Example"
-- Project    : 
-------------------------------------------------------------------------------
-- File       : Simple10GbeRudpKcu105Example_tb.vhd
-- Author     : Filippo Marini  <filippo.marini@pd.infn.it>
-- Company    : INFN Padova
-- Created    : 2025-01-14
-- Last update: 2025-01-15
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

entity Simple10GbeRudpKcu105ExampleWrapper is
   generic (
      TPD_G        : time             := 1 ns;
      BUILD_INFO_G : BuildInfoType;
      SIMULATION_G : boolean          := false;
      IP_ADDR_G    : slv(31 downto 0) := x"0A02A8C0";  -- 192.168.2.10
      PHY_BYPASS_G : false;
      MAC_BYPASS_G : false;
      DHCP_G       : boolean          := false);
   port (
      -- I2C Ports
      sfpTxDisL   : out   sl;
      i2cRstL     : out   sl;
      i2cScl      : inout sl;
      i2cSda      : inout sl;
      -- XADC Ports
      vPIn        : in    sl;
      vNIn        : in    sl;
      -- System Ports
      emcClk      : in    sl;
      extRst      : in    sl;
      led         : out   slv(7 downto 0);
      -- Boot Memory Ports
      flashCsL    : out   sl;
      flashMosi   : out   sl;
      flashMiso   : in    sl;
      flashHoldL  : out   sl;
      flashWp     : out   sl;
      -- ETH GT Pins
      ethClkP     : in    sl;
      ethClkN     : in    sl;
      ethRxP      : in    sl;
      ethRxN      : in    sl;
      ethTxP      : out   sl;
      ethTxN      : out   sl;
      -- XGMII PHY Interface (in case PHY is bypassed)
      xgmiiRxd    : in    slv(63 downto 0)    := (others => '0');
      xgmiiRxc    : in    slv(7 downto 0)     := (others => '0');
      xgmiiTxd    : out   slv(63 downto 0);
      xgmiiTxc    : out   slv(7 downto 0);
      -- UDP Interface (in case PHY is bypassed)
      udpRxMaster : in    AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
      udpRxSlave  : out   AxiStreamSlaveType;
      udpTxMaster : out   AxiStreamMasterType;
      udpTxSlave  : in    AxiStreamSlaveType  := AXI_STREAM_SLAVE_INIT_C
      );
end Simple10GbeRudpKcu105ExampleWrapper;

architecture rtl of Simple10GbeRudpKcu105ExampleWrapper is

begin  -- architecture rtl

   Simple10GbeRudpKcu105Example_1: entity work.Simple10GbeRudpKcu105Example
      generic map (
         TPD_G        => TPD_G,
         BUILD_INFO_G => BUILD_INFO_G,
         SIMULATION_G => SIMULATION_G,
         IP_ADDR_G    => IP_ADDR_G,
         PHY_BYPASS_G => PHY_BYPASS_G,
         MAC_BYPASS_G => MAC_BYPASS_G,
         DHCP_G       => DHCP_G)
      port map (
         sfpTxDisL   => sfpTxDisL,
         i2cRstL     => i2cRstL,
         i2cScl      => i2cScl,
         i2cSda      => i2cSda,
         vPIn        => vPIn,
         vNIn        => vNIn,
         emcClk      => emcClk,
         extRst      => extRst,
         led         => led,
         flashCsL    => flashCsL,
         flashMosi   => flashMosi,
         flashMiso   => flashMiso,
         flashHoldL  => flashHoldL,
         flashWp     => flashWp,
         ethClkP     => ethClkP,
         ethClkN     => ethClkN,
         ethRxP      => ethRxP,
         ethRxN      => ethRxN,
         ethTxP      => ethTxP,
         ethTxN      => ethTxN,
         xgmiiRxd    => xgmiiRxd,
         xgmiiRxc    => xgmiiRxc,
         xgmiiTxd    => xgmiiTxd,
         xgmiiTxc    => xgmiiTxc,
         udpRxMaster => udpRxMaster,
         udpRxSlave  => udpRxSlave,
         udpTxMaster => udpTxMaster,
         udpTxSlave  => udpTxSlave);

   MasterAxiStreamIpIntegrator_1: entity surf.MasterAxiStreamIpIntegrator
      generic map (
         TDATA_NUM_BYTES => 16)
      port map (
         M_AXIS_ACLK    => ethClkP,
         M_AXIS_ARESETN => '1',
         M_AXIS_TVALID  => udpTxMaster_tValid,
         M_AXIS_TDATA   => udpTxMaster_tData,
         M_AXIS_TKEEP   => udpTxMaster_tKeep,
         M_AXIS_TLAST   => udpTxMaster_tLast,
         M_AXIS_TUSER   => udpTxMaster_tUser,
         M_AXIS_TREADY  => udpTxMaster_tReady,
         axisClk        => open,
         axisRst        => open,
         axisMaster     => udpTxMaster,
         axisSlave      => udpTxSlave);

   SlaveAxiStreamIpIntegrator_1: entity surf.SlaveAxiStreamIpIntegrator
      generic map (
         TDATA_NUM_BYTES => 16)
      port map (
         S_AXIS_ACLK    => ethClkP,
         S_AXIS_ARESETN => '1',
         S_AXIS_TVALID  => udpRxMaster_tValid,
         S_AXIS_TDATA   => udpRxMaster_tData,
         S_AXIS_TKEEP   => udpRxMaster_tKeep,
         S_AXIS_TLAST   => udpRxMaster_tLast,
         S_AXIS_TUSER   => udpRxMaster_tUser,
         S_AXIS_TREADY  => udpRxMaster_tReady,
         axisClk        => open,
         axisRst        => open,
         axisMaster     => udpRxMaster,
         axisSlave      => udpRxSlave
         );

end architecture rtl;
