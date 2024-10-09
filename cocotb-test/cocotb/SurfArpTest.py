import os
import random
import logging
import socket
import struct

from scapy.all import *
from scapy.contrib.roce import *

import cocotb
from cocotb.queue import Queue
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from cocotbext.axi import AxiStreamBus, AxiStreamSource, AxiStreamSink, AxiStreamFrame
from cocotbext.eth import XgmiiSource, XgmiiSink, XgmiiFrame

SERVERS_IP_C = ['192.168.2.11', '192.168.2.12']
PACKETS_PER_SERVER_C = 50   # >=50

def invert_ip(ip_address):
    # Split the IP address by the dots into a list of octets
    octets = ip_address.split(".")
    # Reverse the list of octets
    reversed_octets = octets[::-1]
    # Join the reversed octets back into a string with dots
    inverted_ip = ".".join(reversed_octets)
    return inverted_ip

def ip_to_decimal(ip_address):
    # Convert the IP address to a 32-bit packed binary format
    packed_ip = socket.inet_aton(invert_ip(ip_address))
    # Unpack the packed binary format as an unsigned long integer
    decimal_ip = struct.unpack("!L", packed_ip)[0]
    return decimal_ip

class UdpEngineTest:
    def __init__(
            self,
            dut,
    ):
        self.dut = dut
        self.log = logging.getLogger("UdpEngineTest")
        self.log.setLevel(logging.DEBUG)
        # User
        self.check_idx = 0
        self.ipChanged = False
        # Clock
        self.clock = self.dut.clk
        # Reset
        self.reset = self.dut.rst
        # tDest
        self.tDest = self.dut.tDest
        # remoteIpAddr
        self.remoteIpAddr = self.dut.remoteIpAddr
        # phyReady
        self.phyReady = self.dut.phyReady
        # DataToCheck
        self.dataRx      = self.dut.DataRx
        self.dataRxValid = self.dut.DataRxValid
        self.dataRxKeep  = self.dut.DataRxKeep
        self.dataTx      = self.dut.DataTx
        self.dataTxValid = self.dut.DataTxValid
        self.dataTxKeep  = self.dut.DataTxKeep
        self.dataRxQueue = Queue()
        self.dataTxQueue = Queue()
        # XGMII Tx
        self.xgmii_tx = XgmiiSink(
            dut.phyDTx,
            dut.phyCTx,
            self.clock,
            self.reset,
        )
        self.xgmii_tx.log.setLevel(logging.WARNING)
        #XGMII Rx
        self.xgmii_rx = XgmiiSource(
            dut.phyDRx,
            dut.phyCRx,
            self.clock,
            self.reset,
        )
        self.xgmii_rx.log.setLevel(logging.WARNING)

    async def gen_clock(self):
        await cocotb.start(Clock(self.clock, 6.4, "ns").start())
        self.log.info("Start generating clock")

    async def gen_reset(self):
        self.reset.value = 1
        self.remoteIpAddr.value = 0
        self.phyReady.value = 0
        self.tDest.value = 0
        for _ in range(20):
            await RisingEdge(self.clock)
        self.reset.value = 0
        self.phyReady.value = 1
        await RisingEdge(self.clock)

    async def xgmii_srp(self):
        pkt_idx = 0
        while True:
            # Get XGMII from testbench
            data = await self.xgmii_tx.recv()
            # Extract XGMII data
            packet = Ether(data.get_payload())
            self.log.debug(f'Sending packet {pkt_idx} from XGMII')
            if ARP in packet or UDP in packet:
                # Send packet and get response
                resp, _ = srp(packet, verbose=True, iface='eth0')
                #sendp(packet, verbose=True, iface='lo')
                for _, r in resp:
                    recv_pkt = r
                self.log.debug(f'Got response for packet {pkt_idx}')
                # Extract XGMII data
                ackRaw = raw(recv_pkt)
                # Put XGMII into testbench
                xgmiiFrame = XgmiiFrame.from_payload(ackRaw)
                await self.xgmii_rx.send(xgmiiFrame)
            else:
                self.log.debug('just sending a packet')
                sendp(packet, verbose=True, iface='eth0')
            pkt_idx += 1

    async def get_data(self):
        rx_data_idx = 0
        tx_data_idx = 0
        while True:
            if self.dataRxValid.value == 1:
                dataRx = self.dataRx.value.integer
                dataRxKeep = self.dataRxKeep.value.integer
                dataRxHex = dataRx.to_bytes(16, byteorder='big')
                mask_bits_rx = bin(dataRxKeep)[2:].zfill(16)
                dataRxByte = bytes([b for b, m in zip(dataRxHex, mask_bits_rx) if m == '1'])
                await self.dataRxQueue.put(int.from_bytes(dataRxByte, "big"))
                rx_data_idx += 1
            if self.dataTxValid.value == 1:
                dataTx = self.dataTx.value.integer
                dataTxKeep = self.dataTxKeep.value.integer
                dataTxHex = dataTx.to_bytes(16, byteorder='big')
                mask_bits_tx = bin(dataTxKeep)[2:].zfill(16)
                dataTxByte = bytes([b for b, m in zip(dataTxHex, mask_bits_tx) if m == '1'])
                await self.dataTxQueue.put(int.from_bytes(dataTxByte, "big"))
                tx_data_idx += 1
            await RisingEdge(self.clock)

    async def check_data(self):
        mismatch_idx = 0
        startLooking = True
        while True:
            if startLooking:
                dataRx = await self.dataRxQueue.get()
                dataTx = await self.dataTxQueue.get()
                while dataRx != dataTx:
                    dataTx = await self.dataTxQueue.get()
                    self.log.debug(f'Looking for a match.. {hex(dataRx)} --- {hex(dataTx)}')
                self.log.debug('Starting to check data!')
                startLooking = False
                self.ipChanged = False
                self.check_idx += 1
                self.next_check_idx = self.check_idx + PACKETS_PER_SERVER_C
                self.log.debug(f'Checking will stop at match {self.next_check_idx}')
            else:
                dataTx = await self.dataTxQueue.get()
                dataRx = await self.dataRxQueue.get()
                if (dataRx != dataTx and self.ipChanged):
                    startLooking = True
                    self.log.warning('Found mismatch, its possible its from the IP changing')
                elif (dataRx != dataTx and not self.ipChanged):
                    assert (False), f'Mismatch!! --> Rx: {hex(dataRx)} -- Tx: {hex(dataTx)}'
                else:
                    self.log.debug(f'Match #{self.check_idx}! {hex(dataRx)} --- {hex(dataTx)}')
                self.check_idx += 1

    async def server_arbiter(self):
        # Check first server
        while True:
            if self.remoteIpAddr.value == ip_to_decimal(SERVERS_IP_C[0]):
                self.next_check_idx = self.check_idx + PACKETS_PER_SERVER_C
                break
            await RisingEdge(self.clock)
        # Check list of servers
        for i in range(len(SERVERS_IP_C)-1):
            while True:
                if self.check_idx == self.next_check_idx:
                    self.log.debug(f'Changing IP address to {SERVERS_IP_C[i+1]}')
                    self.ipChanged = True
                    self.remoteIpAddr.value = ip_to_decimal(SERVERS_IP_C[i+1])
                    self.next_check_idx = self.check_idx + PACKETS_PER_SERVER_C
                    break
                await RisingEdge(self.clock)
        # Check last server
        while True:
            if self.check_idx == self.next_check_idx:
                break
            await RisingEdge(self.clock)


@cocotb.test(timeout_time=1000000000, timeout_unit="ns")
async def runUdpEngineTest(dut):
    tester = UdpEngineTest(
        dut,
    )
    await tester.gen_clock()
    await tester.gen_reset()
    xgmii_srp_thread = cocotb.start_soon(tester.xgmii_srp())
    get_data_thread = cocotb.start_soon(tester.get_data())
    check_data_thread = cocotb.start_soon(tester.check_data())
    server_arbiter_thread = cocotb.start_soon(tester.server_arbiter())
    tester.log.info("Starting Tesbench")
    for _ in range(200):
        await RisingEdge(tester.clock)
    dut.remoteIpAddr.value = ip_to_decimal(SERVERS_IP_C[0])
    await server_arbiter_thread
    #await Timer(7, units='us')
