FROM ubuntu:22.04

# Install verilator dependencies and python for cocotb and pytest
RUN apt-get update && apt-get -y install git autoconf help2man perl python3 python3-pip make flex bison g++ libfl2 libfl-dev curl

# Cocotb explicitly requires verilator v5.006, so compile from source
RUN git clone https://github.com/verilator/verilator
WORKDIR /verilator
RUN git checkout v5.006
ENV VERILATOR_ROOT=/verilator
RUN autoconf && ./configure && make -j `nproc`
RUN make test
ENV PATH="$VERILATOR_ROOT/bin:$PATH"

# Build Rust tools for bender
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH "/root/.cargo/bin:${PATH}"
RUN rustup install 1.63.0
RUN rustup override set 1.63.0

# Install Bender
RUN cargo install bender --version 0.23.2

# Install python dependencies
WORKDIR /repo
COPY requirements.txt .
RUN pip install -r requirements.txt