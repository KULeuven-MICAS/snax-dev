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

'''
    Let's do this manually first
'''

# Reconfigurable parameters
DataWidth = 8
Depth = 0
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

    # Getting check list
    checker = [0]*(Depth + 1)
    answer = []

    for i in range(TEST_COUNT):

        input_val = random.randint(0,(2**DataWidth-1))
        dut.d_i.value = input_val

        output_val = dut.d_o.value

        # Workaround so that both Verilator and Modelsim pass
        if(str(output_val).isnumeric()):
            output_val = int(output_val)
        else:
            output_val = 0
            

        cocotb.log.info(f'Shift reg input: {input_val}')
        cocotb.log.info(f'Shift reg output: {output_val}')

        checker.append(input_val)
        answer.append(output_val)

        await RisingEdge(dut.clk_i)

    assert (checker[0:TEST_COUNT] == answer)

# Main test run
@pytest.mark.parametrize(
    "parameters", [
        {
            "DataWidth": str(DataWidth),
            "Depth": str(Depth)
        }
    ]
)

def test_shift_reg(parameters):

    # Working paths
    repo_path = os.getcwd()
    tests_path = repo_path + "/tests/cocotb/"

    # RTL paths
    rtl_sources = ["/users/micas/rantonio/no_backup/snax-dev/.bender/git/checkouts/common_cells-9e51f4fce2109f7f/src/shift_reg.sv", \
                   "/users/micas/rantonio/no_backup/snax-dev/.bender/git/checkouts/common_cells-9e51f4fce2109f7f/src/shift_reg_gated.sv", \
                   "/users/micas/rantonio/no_backup/snax-dev/tests/tb/tb_shift_reg.sv"]
    
    # Include directories
    include_folders = ['/users/micas/rantonio/no_backup/snax-dev/.bender/git/checkouts/common_cells-9e51f4fce2109f7f/include']

    # Specify top-level module
    toplevel = "tb_shift_reg"
    
    # Specify python test name that contains the @cocotb.test.
    # Usually the name of this test.
    module = "test_shift_reg"

    # Specify what simulator to use (e.g., verilator, modelsim, icarus)
    simulator = "verilator"

    # Specify build directory
    sim_build = tests_path + "/test/sim_build/{}/".format(toplevel)

    run(
        verilog_sources=rtl_sources,
        includes=include_folders,
        toplevel=toplevel,
        module=module,
        simulator=simulator,
        sim_build=sim_build,
        parameters=parameters
    )
