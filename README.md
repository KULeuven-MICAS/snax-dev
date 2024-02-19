[![CI](https://github.com/KULeuven-MICAS/snax-dev/actions/workflows/ci.yml/badge.svg)](https://github.com/KULeuven-MICAS/snax-dev/actions/workflows/ci.yml)
[![CI](https://github.com/KULeuven-MICAS/snax-dev/actions/workflows/code-formatting.yml/badge.svg)](https://github.com/KULeuven-MICAS/snax-dev/actions/workflows/code-formatting.yml)
[![CI](https://github.com/KULeuven-MICAS/snax-dev/actions/workflows/pyright.yml/badge.svg)](https://github.com/KULeuven-MICAS/snax-dev/actions/workflows/pyright.yml)

#  SNAX (Snitch Accelerator Extension) Accelerator Development

This repo is for accelerator development purposes. Users can use this as an intermediate step for testing their own accelerators before connecting to the [SNAX platform](https://github.com/KULeuven-MICAS/snitch_cluster). This repo contains the following:

* [Snitch](https://github.com/pulp-platform/snitch_cluster) tightly-coupled data memory (TCDM) sub-system for simulating the TCDM and memory contention handling.
* [Streamers](https://github.com/KULeuven-MICAS/snax-streamer.git) for packing and unpacking data from TCDM memory to accelerator and vice-versa.
* Tests for guiding users on how to use TCDM, streamers, and simple accelerators.

The goal is for users to make their own accelerator wrapper which can easily attach to the SNAX platform.

# Testing and Verification
* **Please make sure to install Verilator version v5.006**. Refer to [Verilator](https://verilator.org/guide/latest/install.html) for installation details.
* Please make sure to have Python3.10 and the required packages in `requirements.txt`. You can invoke:

```bash
pip install -r requirements.txt
```

This repo uses git submodules to setup some PULP IP for the TCDM subsystem. Clone the repo with:
```bash
git clone https://github.com/KULeuven-MICAS/snax-dev.git --recurse-submodules
```
Or if you cloned the repo already you can invoke:

```bash
git submodule init --recursive
```

Run tests:
```bash
pytest --simulator=verilator
```
You can set `--simulator` to any of the [cocotb supported simulators](https://docs.cocotb.org/en/stable/simulator_support.html).
This option is set to `verilator` by default.

# Development
We provide pre-commit hooks to help formatting python and yaml code.
To hook the pre-commit hooks into git, use:
```bash
pre-commit install
```

# Directory Structure

* `/rtl` - contains custom and generated RTL source files.
    * We use Chisel to generate the streamers and the RTL source files are placed here.
    * The TCDM sub-system uses PULP's Snitch platform and we sub-module these IPs into this directory.
    * There are also examples on how to make the top-level wrappers which we connect to the SNAX platform.
* `/tests` - contains the Cocotb test and test bench wrappers.
    * The Cocotb tests function as the main test bench and stimuli for the design under test (DUT).
    * The test bench wrappers function as top-level wrappers to connect to cocotb.
    * The `snax_util.py` contains utility components for tests and read-write register or direct memory access (DMA) operations.
 * `/util` - contains configuration files, scripts, templates, and the container for quick setups.

# Testbench Guide

Below shows a figure for the test and test bench setup:

<img src="https://drive.google.com/thumbnail?id=1fI5fB6a7tJELptoN1RR7dBMUnbwpcmYO&sz=w1960" alt="SNAX Development Setup">

There are three major key sections:

* `TCDM Subsystem` - is at the top-most area. This is a replica of the Snitch's TCDM subsystem where it contains narrow and wide TCDM ports. The narrow are for the accelerator's ports while the wide are for the DMA's ports.
* `Accelerator Wrapper` - is the main accelerator DUT. The figure shows that it has streamers connected to the main accelerator data path. There also exists a CSR Control which is also a manager for setting configurations. **Note** It is possible to design or have your own streamer, if you have an accelerator built this way, then we connect it directly to the TCDM interconnect following the given ports.
* `Cocotb Driver` - acts as the main stimuli. It controls the CSR of the accelerator and a port that handles DMA transactions unto the wide TCDM. The latter was developed so users can simulate the DMA transfers into the memory.

When a designer makes an accelerator wrapper, they only need to connect the accelerator CSR ports and the TCDM ports. The succeeding subsections discuss these ports in detail.

## Accelerator Ports

Referring to the figure above, the Cocotb drives the accelerator ports through simple register read and write operations. The ports for the request port are:

| Signal      | Description                                         | 
| ----------- | --------------------------------------------------  |
| addr        | Register address port.                              |
| data        | Register data port.                                 |
| write       | Write enable signal. 1 means write enable.          |
| valid       | Valid signal. High when data is valid.              |
| ready       | Ready signal. High when receiving end is valid.     |

The signal definitions for the response port are:

| Signal      | Description                                         | 
| ----------- | --------------------------------------------------  |
| data        | Response side valid signal.                         |
| valid       | Valid signal. High when data is valid.              |
| ready       | Ready signal. High when receiving end is valid.     |

**Note** Valid-ready response have very specific rules which you can find from the [AXI ARM Documentation](https://developer.arm.com/documentation/102202/0300/Channel-transfers-and-transactions). In summary:

* A successful transaction only happens when both `VALID` and `READY` signals are high.
* A source cannot wait for READY to be asserted before asserting `VALID`.
* A destination can wait for VALID to be asserted before asserting `READY`.

The accelerator ports for getting data from streamers uses the same mechanism. They only have one channel which is the `data` port. The interaction between streamers and the accelerator involves only data transfers. If you are to use streamers, refer to the [SNAX Streamer](https://github.com/KULeuven-MICAS/snax-streamer) repository.

##  TCDM Ports:

It also uses the same valid-ready handshake similar to the accelerator ports. Referring to the figure above, you can find these TCDM ports at the top-most section in between the streamers and the TCDM subsystem. The signal definitions for the request port are:

| Signal            | Description                                                                                                   | 
| ----------------- | ------------------------------------------------------------------------------------------------------------  |
| q_valid           | Request side valid signal.                                                                                    |
| write             | Write signal. 1 means to write.                                                                               |
| addr              | Memory address to write to.                                                                                   |
| amo               | Atomic memory operation. Details are in [Request and Response](reqrsp_interface.md) section                   |
| data              | The data to be written.                                                                                       |
| user              | User field pertains to which core is accessing the port.                                                      |
| strb              | Byte masking for data writes                                                                                  |

The signal definitions for the response port are:

| Signal            | Description                                                                                                   | 
| ----------------- | ------------------------------------------------------------------------------------------------------------  |
| p_valid           | Response side valid signal.                                                                                   |
| q_ready           | Request side ready signal.                                                                                    |
| data              | The read data to be returned to the core.                                                                     |

Notice that the `q_ready` signal of the TCDM was placed in the response ports. This is just to indicate that the direction is from the TCDM interconnect towards the Snitch core. Also, there is no `p_ready` signal indicating that the `p_ready` is invisibly always ready. The accelerator needs to buffer this data as soon as they can. Note that the `p_valid` signal asserts immediately along with the appropriate data at that cycle.