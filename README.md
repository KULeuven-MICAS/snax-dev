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