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

# Get bender binary
WORKDIR /tools/bender/bin
RUN curl --proto '=https' --tlsv1.2 https://pulp-platform.github.io/bender/init -sSf | sh
ENV PATH "/tools/bender/bin:${PATH}"

# Install python dependencies
WORKDIR /repo
COPY requirements.txt .
RUN pip install -r requirements.txt