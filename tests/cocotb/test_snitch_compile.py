# ---------------------------------
# Copyright 2023 KULeuven
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
# Author: Ryan Antonio (ryan.antonio@esat.kuleuven.be)
# ---------------------------------

# -----------------------------------
# Imports
# -----------------------------------
import os
import cocotb
from cocotb.triggers import RisingEdge
from cocotb.clock import Clock
from cocotb_test.simulator import run
import random
import pytest


# Reconfigurable parameters
TEST_COUNT = 10

@cocotb.test()
async def shift_reg_dut(dut):

    # Initialize clock
    clock = Clock(dut.clk_i, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Reset or intial values
    dut.rst_ni.value = 0

    # Wait 1 cycle to reset
    await RisingEdge(dut.clk_i)

    # Deassert reset
    dut.rst_ni.value = 1

    for i in range(TEST_COUNT):

        await RisingEdge(dut.clk_i)


# Main test run
@pytest.mark.parametrize(
    "parameters", [
        {
            "AddrWidth": str(48),
            "DataWidth": str(64)
        }
    ]
)

def test_shift_reg(parameters):

    # Working paths
    repo_path = os.getcwd()
    tests_path = repo_path + "/tests/cocotb/"

    # Extract RTL files and include folders from Bender filelist
    with open("snitch_cluster.f","r") as file:
        file_list = file.readlines()

    include_folders = []
    rtl_sources = []

    for item in file_list:
        if(item[0] == "#" or item[0]=='' or item[0]=='\n'):
            pass
        elif(item[0:8]=="+incdir+"):
            include_folders.append(item[8:].strip())
        else:
            rtl_sources.append(item.strip())

    print(include_folders)

    # Specify top-level module
    toplevel = "tb_snitch_cc"
    
    # Specify python test name that contains the @cocotb.test.
    # Usually the name of this test.
    module = "test_snitch_compile"

    # Specify what simulator to use (e.g., verilator, modelsim, icarus)
    simulator = "verilator"

    # Specify build directory
    sim_build = tests_path + "/test/sim_build/{}/".format(toplevel)

    compile_args = ["-Wno-LITENDIAN",
                    "-Wno-WIDTH",
                    "-Wno-CASEINCOMPLETE",
                    "-Wno-BLKANDNBLK",
                    "-Wno-CMPCONST",
                    "-Wno-WIDTHCONCAT",
                    "-Wno-UNSIGNED",
                    "-Wno-UNOPTFLAT",
                    "-Wno-TIMESCALEMOD",
                    "-Wno-fatal",
                    "--no-timing"
                    ]

    run(
        verilog_sources=rtl_sources,
        includes=include_folders,
        toplevel=toplevel,
        module=module,
        simulator=simulator,
        sim_build=sim_build,
        compile_args=compile_args,
    )
