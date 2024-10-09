library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;
use surf.EthMacPkg.all;
use surf.AxiLitePkg.all;

entity UdpEngineTb is
   generic (
      TPD_G      : time                          := 1 ns;
      IP_ADDR_G  : std_logic_vector(31 downto 0) := x"0A02A8C0";  -- 192.168.2.10
      MAC_ADDR_G : std_logic_vector(47 downto 0) := x"0a02a8c04202"  -- 02:42:c0:a8:02:0a
      );
   port (
      -- Clock and Reset
      clk          : in  sl;
      rst          : in  sl;
      -- User signals
      tDest        : in  slv(7 downto 0);
      remoteIpAddr : in  slv(31 downto 0);
      phyReady     : in  sl;
      -- Data to check
      DataTx       : out slv(127 downto 0);
      DataTxValid  : out sl;
      DataTxKeep   : out slv(15 downto 0);
      DataRx       : out slv(127 downto 0);
      DataRxKeep   : out slv(15 downto 0);
      DataRxValid  : out sl;
      DataRxIp     : out slv(31 downto 0);
      -- XGMII
      phyDTx       : out slv(63 downto 0);
      phyCTx       : out slv(7 downto 0);
      phyDRx       : in  slv(63 downto 0);
      phyCRx       : in  slv(7 downto 0)
      );
end UdpEngineTb;

architecture behav of UdpEngineTb is

   type RegType is record
      packetLength : slv(31 downto 0);
      trig         : sl;
      txBusy       : sl;
      errorDet     : sl;
   end record RegType;

   constant REG_INIT_C : RegType := (
      packetLength => toSlv(0, 32),
      trig         => '0',
      txBusy       => '0',
      errorDet     => '0');

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal ethConfig   : EthMacConfigArray(0 downto 0) := (others => ETH_MAC_CONFIG_INIT_C);
   signal txMaster    : AxiStreamMasterType           := AXI_STREAM_MASTER_INIT_C;
   signal rxMaster    : AxiStreamMasterType           := AXI_STREAM_MASTER_INIT_C;
   signal txSlave     : AxiStreamSlaveType            := AXI_STREAM_SLAVE_INIT_C;
   signal txBusy      : sl;
   signal obMacMaster : AxiStreamMasterType           := AXI_STREAM_MASTER_INIT_C;
   signal obMacSlave  : AxiStreamSlaveType            := AXI_STREAM_SLAVE_INIT_C;
   signal ibMacMaster : AxiStreamMasterType           := AXI_STREAM_MASTER_INIT_C;
   signal ibMacSlave  : AxiStreamSlaveType            := AXI_STREAM_SLAVE_INIT_C;

begin  -- architecture behav

   ----------
   -- PRBS TX
   ----------
   U_TX : entity surf.SsiPrbsTx
      generic map (
         TPD_G                      => TPD_G,
         AXI_EN_G                   => '0',
         MASTER_AXI_STREAM_CONFIG_G => EMAC_AXIS_CONFIG_C)
      port map (
         -- Master Port (mAxisClk)
         mAxisClk     => clk,
         mAxisRst     => rst,
         mAxisMaster  => txMaster,
         mAxisSlave   => txSlave,
         -- Trigger Signal (locClk domain)
         locClk       => clk,
         locRst       => rst,
         packetLength => r.packetLength,
         tDest        => tDest,
         trig         => r.trig,
         busy         => txBusy);

   ----------------------
   -- Data ports
   ----------------------
   DataTx      <= txMaster.tData(127 downto 0);
   DataTxValid <= txMaster.tValid and txSlave.tReady;
   DataTxKeep  <= txMaster.tKeep(15 downto 0);
   DataRx      <= rxMaster.tData(127 downto 0);
   DataRxValid <= rxMaster.tValid;
   DataRxKeep  <= rxMaster.tKeep(15 downto 0);
   DataRxIp    <= rxMaster.tUser(39 downto 8);

   ----------------------
   -- IPv4/ARP/UDP Engine
   ----------------------
   U_UDP_Client : entity surf.UdpEngineWrapper
      generic map (
         -- Simulation Generics
         TPD_G                  => TPD_G,
         -- UDP Server Generics
         SERVER_EN_G            => false,
         -- UDP Client Generics
         CLIENT_EN_G            => true,
         CLIENT_TAG_IP_IN_TUSER => true,
         CLIENT_SIZE_G          => 1,
         CLIENT_PORTS_G         => (0 => 8193),
         CLIENT_EXT_CONFIG_G    => true,
         ARP_TAB_ENTRIES_G      => 4)
      port map (
         -- Local Configurations
         localMac            => MAC_ADDR_G,
         localIp             => IP_ADDR_G,
         -- Remote Configurations
         clientRemotePort(0) => x"0020",  -- PORT = 8192 = 0x2000 (0x0020 in big endianness)
         clientRemoteIp(0)   => remoteIpAddr,
         -- Interface to Ethernet Media Access Controller (MAC)
         obMacMaster         => obMacMaster,
         obMacSlave          => obMacSlave,
         ibMacMaster         => ibMacMaster,
         ibMacSlave          => ibMacSlave,
         -- Interface to UDP Server engine(s)
         obClientMasters(0)  => rxMaster,
         obClientSlaves(0)   => AXI_STREAM_SLAVE_FORCE_C,
         ibClientMasters(0)  => txMaster,
         ibClientSlaves(0)   => txSlave,
         -- Clock and Reset
         clk                 => clk,
         rst                 => rst);

   --------------------
   -- Ethernet MAC core
   --------------------
   U_MAC0 : entity surf.EthMacTop
      generic map (
         TPD_G          => TPD_G,
         PHY_TYPE_G     => "XGMII",
         DROP_ERR_PKT_G => false,
         PRIM_CONFIG_G  => EMAC_AXIS_CONFIG_C)
      port map (
         -- DMA Interface
         primClk         => clk,
         primRst         => rst,
         ibMacPrimMaster => ibMacMaster,
         ibMacPrimSlave  => ibMacSlave,
         obMacPrimMaster => obMacMaster,
         obMacPrimSlave  => obMacSlave,
         -- Ethernet Interface
         ethClk          => clk,
         ethRst          => rst,
         ethConfig       => ethConfig(0),
         phyReady        => phyReady,
         -- XGMII PHY Interface
         xgmiiTxd        => phyDTx,
         xgmiiTxc        => phyCTx,
         xgmiiRxd        => phyDRx,
         xgmiiRxc        => phyCRx);
   ethConfig(0).macAddress <= MAC_ADDR_G;

   comb : process (r, rst, txBusy) is
      variable v : RegType;
   begin
      -- Latch the current value
      v := r;

      -- Keep delay copies
      v.txBusy := txBusy;
      v.trig   := not(r.txBusy);

      -- Check for the packet completion
      if (txBusy = '1') and (r.txBusy = '0') then
         -- Sweeping the packet size size
         v.packetLength := r.packetLength + 1;
         -- Check for Jumbo frame roll over
         if (r.packetLength = (8192/4)-1) then
            -- Reset the counter
            v.packetLength := (others => '0');
         end if;
      end if;

      -- Reset
      if (rst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

   end process comb;

   seq : process (clk) is
   begin
      if (rising_edge(clk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end architecture behav;
