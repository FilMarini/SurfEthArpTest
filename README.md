# SurfEthArpTest

This is a testbench to check the functionalities of the multiple entries ARP-Table in SURF

The test consists in setting up a Docker client machine, which sends PRBS data, and `N` Docker servers machines which send the data back to the client in a loop when targeted.

The client targets one machine at a time, first changine the `remoteIpAddr` of `UdpEngine`, and after changing the `tDest` field of the AXI-Stream transmission.

The test in cocotb manages the IP change FSM, as well as the checking of the loopback data in order to make sure it matches with the one thats being sent.

## Prerequisites

I think the PC just needs to have docker installed

## Run the test

In order to run the test:

* First build the docker image

```bash
# cd into the repo folder
cd <wherever you are>/SurfEthArpTest
# Build Docker image
docker build -f ./build_docker/Dockerfile -t ethernet-test ./build_docker
```
* Run the testbench

```bash
./run_udp_docker_test.sh
```
