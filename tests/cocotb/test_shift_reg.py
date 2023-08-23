# ---------------------------------
# Copyright 2023 KULeuven
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
# Author: Ryan Antonio (ryan.antonio@esat.kuleuven.be)
# ---------------------------------

# -----------------------------------
# Imports
# -----------------------------------
import subprocess
import cocotb
from cocotb.triggers import RisingEdge
from cocotb.clock import Clock
from cocotb_test.simulator import run
import random
import pytest

# -----------------------------------
# Variables
# -----------------------------------
FIFO_DEPTH = 1
TEST_COUNT = 10
DATA_WIDTH = 8


# -----------------------------------
# Stimulus
# -----------------------------------
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

    # Getting check list
    checker = [0] * (FIFO_DEPTH + 1)
    answer = []

    # Iterate test cases
    for i in range(TEST_COUNT):
        input_val = random.randint(0, (2**DATA_WIDTH - 1))
        dut.d_i.value = input_val

        output_val = dut.d_o.value

        # Workaround so that both Verilator and Modelsim pass
        if str(output_val).isnumeric():
            output_val = int(output_val)
        else:
            output_val = 0

        # Log debug
        cocotb.log.info(f"Shift reg input: {input_val}")
        cocotb.log.info(f"Shift reg output: {output_val}")

        # Collect answers and expected outputs
        checker.append(input_val)
        answer.append(output_val)

        await RisingEdge(dut.clk_i)

    assert checker[0:TEST_COUNT] == answer


# -----------------------------------
# Parameter inputs to DUT
# -----------------------------------
@pytest.mark.parametrize(
    "parameters", [{"DataWidth": str(DATA_WIDTH), "Depth": str(FIFO_DEPTH)}]
)

# -----------------------------------
# Run setup
# -----------------------------------
def test_shift_reg(parameters, simulator):
    # Working paths
    repo_dir = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"], stdout=subprocess.PIPE
    )
    repo_dir = repo_dir.stdout.decode("utf-8").strip()
    tests_path = repo_dir + "/tests/cocotb/"

    # RTL paths
    # TODO: Change this later. For now this is just a simple test.
    rtl_sources = [
        repo_dir
        + "/.bender/git/checkouts/common_cells-9e51f4fce2109f7f/src/shift_reg.sv",
        repo_dir
        + "/.bender/git/checkouts/common_cells-9e51f4fce2109f7f/src/shift_reg_gated.sv",
        repo_dir + "/tests/tb/tb_shift_reg.sv",
    ]

    # Include directories
    include_folders = [
        repo_dir + "/.bender/git/checkouts/common_cells-9e51f4fce2109f7f/include"
    ]

    # Specify top-level module
    toplevel = "tb_shift_reg"

    # Specify python test name that contains the @cocotb.test.
    # Usually the name of this test.
    module = "test_shift_reg"

    # Specify build directory
    sim_build = tests_path + "/sim_build/{}/".format(toplevel)

    run(
        verilog_sources=rtl_sources,
        includes=include_folders,
        toplevel=toplevel,
        module=module,
        simulator=simulator,
        sim_build=sim_build,
        parameters=parameters,
    )
