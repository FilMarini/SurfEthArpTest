FROM ubuntu:22.04

# Environment variables to suppress interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies for building GHDL and LLVM
RUN apt update && \
    apt install -y \
    git \
    gnat \
    llvm \
    llvm-dev \
    make \
    g++ \
    curl \
    ca-certificates \
    automake \
    build-essential \
    python3 \
    clang \
    pip \
    net-tools \
    iputils-ping

# Install pip packages
RUN pip install scapy cocotb cocotbext-axi cocotbext-eth

# Clone the GHDL repository
RUN git clone https://github.com/ghdl/ghdl.git -b v4.1.0 /ghdl

# Set working directory to GHDL folder
WORKDIR /ghdl/build

# Configure and build GHDL with LLVM backend
RUN ../configure --with-llvm-config --prefix=/usr/local && \
    make && \
    make install
