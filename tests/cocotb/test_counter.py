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
import pytest

# -----------------------------------
# Global parameters for testing
# TODO: These are modifiable so change whenever needed
# -----------------------------------
# Checker parameter
CHECK_COUNT = 5

# DUT parameters
COUNTER_WIDTH = 16

# -----------------------------------
# Main test bench
# -----------------------------------
# For the main test bench, we need to make sure the ports
# are consistent with the DUT. Double check the main module.
# -----------------------------------


@cocotb.test()
async def counter_dut(dut):
    # Initialize clock
    clock = Clock(dut.clk_i, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Reset or intial values
    dut.rst_ni.value = 0
    dut.clr_i.value = 0

    # Wait 1 cycle to reset
    await RisingEdge(dut.clk_i)

    # Deassert reset
    dut.rst_ni.value = 1

    for i in range(CHECK_COUNT):
        await RisingEdge(dut.clk_i)
        counter_val = int(dut.out.value)
        cocotb.log.info(f"Counter value: {counter_val}")
        assert (
            i == counter_val
        ), f"ERROR! Output mismatch - \
            Expected output: {i}; Actual output: {counter_val}"


# Main test run
@pytest.mark.parametrize("parameters", [{"COUNTER_WIDTH": str(COUNTER_WIDTH)}])
def test_counter(parameters, simulator):
    # Working paths
    repo_path = os.getcwd()
    tests_path = repo_path + "/tests/cocotb/"

    # RTL paths
    counter_source = repo_path + "/rtl/counter.sv"
    rtl_sources = [counter_source]

    # Specify top-level module
    toplevel = "counter"

    # Specify python test name that contains the @cocotb.test.
    # Usually the name of this test.
    module = "test_counter"

    # Specify build directory
    sim_build = tests_path + "/test/sim_build/{}/".format(toplevel)

    run(
        verilog_sources=rtl_sources,
        toplevel=toplevel,
        module=module,
        simulator=simulator,
        sim_build=sim_build,
        parameters=parameters,
    )
