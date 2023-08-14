#---------------------
# Ubuntu 22.04 base
#---------------------
FROM ubuntu:22.04

#---------------------
# Install necessary packages
#---------------------
RUN apt-get update && apt-get -y install git autoconf help2man perl python3 python3-pip make flex bison g++ libfl2 libfl-dev

#---------------------
# Compile verilator from source code
#---------------------
RUN git clone https://github.com/verilator/verilator
WORKDIR /verilator
RUN git checkout v5.006
ENV VERILATOR_ROOT=/verilator
RUN autoconf && ./configure && make -j `nproc`
RUN make test
ENV PATH="$VERILATOR_ROOT/bin:$PATH"

#---------------------
# Installing cocotb
#---------------------
WORKDIR /repo
COPY requirements.txt .
RUN pip install -r requirements.txt

#---------------------
# Necessary environment variables
#---------------------
ENV SNAX_REPO=/repo
