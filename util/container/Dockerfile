FROM ubuntu:22.04

# Install verilator dependencies and python for cocotb and pytest
RUN apt-get update && \
    apt-get -y install git autoconf help2man perl python3 python3-pip make flex bison g++ libfl2 libfl-dev curl openjdk-11-jre-headless openjdk-11-jdk-headless wget tar gnupg2 software-properties-common lsb-release

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

# Install chisel dependencies
WORKDIR /tools

RUN echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" | tee /etc/apt/sources.list.d/sbt.list && \
    echo "deb https://repo.scala-sbt.org/scalasbt/debian /" | tee /etc/apt/sources.list.d/sbt_old.list && \
    curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | apt-key add && \
    apt-get update

RUN apt-get install -y sbt

RUN wget https://github.com/llvm/circt/releases/download/firtool-1.42.0/firrtl-bin-ubuntu-20.04.tar.gz && \
    tar -xvzf firrtl-bin-ubuntu-20.04.tar.gz && \
    rm firrtl-bin-ubuntu-20.04.tar.gz

# Install generic LLVM toolchain in /usr/bin - latest stable release is 17
RUN  wget https://apt.llvm.org/llvm.sh && chmod +x llvm.sh && ./llvm.sh 17 && rm llvm.sh

ENV PATH "/tools/firtool-1.42.0/bin/:${PATH}"
