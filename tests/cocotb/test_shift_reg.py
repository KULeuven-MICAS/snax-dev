# ---------------------------------
# Copyright 2023 KULeuven
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
# Author: Ryan Antonio (ryan.antonio@esat.kuleuven.be)
# ---------------------------------

import cocotb
from cocotb.triggers import RisingEdge
from cocotb.clock import Clock
from cocotb_test.simulator import run
import random
import pytest
import snax_util

# -----------------------------------
# Variables
# -----------------------------------
FIFO_DEPTH = 0
TEST_COUNT = 20
DATA_WIDTH = 16


# -----------------------------------
# Test stimulus
# -----------------------------------
@cocotb.test()
async def shift_reg_dut(dut):
    clock = Clock(dut.clk_i, 10, units="ns")
    cocotb.start_soon(clock.start())

    dut.rst_ni.value = 0

    await RisingEdge(dut.clk_i)

    dut.rst_ni.value = 1

    checker = [0] * (FIFO_DEPTH + 1)
    answer = []

    for i in range(TEST_COUNT):
        input_val = random.randint(0, (2**DATA_WIDTH - 1))
        dut.d_i.value = input_val

        output_val = dut.d_o.value

        # Workaround since Verilator only outputs 1s and 0s
        # While modelsim outputs don't care X's
        if str(output_val).isnumeric():
            output_val = int(output_val)
        else:
            output_val = 0

        cocotb.log.info(f"Shift reg input: {input_val}; Shift reg output: {output_val}")

        checker.append(input_val)
        answer.append(output_val)

        await RisingEdge(dut.clk_i)

    assert checker[0:TEST_COUNT] == answer


# -----------------------------------
# Test build
# -----------------------------------
@pytest.mark.parametrize(
    "parameters", [{"DataWidth": str(DATA_WIDTH), "Depth": str(FIFO_DEPTH)}]
)
def test_shift_reg(parameters, simulator):
    # RTL paths
    # Extract paths for benderized files
    includes, defines, verilog_sources = snax_util.extract_bender_filelist()

    # Just get necessary files for shift_reg only
    shift_reg_rtl_src = []
    shift_reg_rtl_src.append(
        snax_util.extract_bender_filepath("shift_reg.sv", verilog_sources)
    )
    shift_reg_rtl_src.append(
        snax_util.extract_bender_filepath("shift_reg_gated.sv", verilog_sources)
    )

    # Append testbench
    shift_reg_rtl_src.append("tests/tb/tb_shift_reg.sv")

    toplevel = "tb_shift_reg"

    # Module is the python test name that contains the @cocotb.test.
    # In this example, it's the name of this test
    module = "test_shift_reg"

    sim_build = "tests/sim_build/{}/".format(toplevel)

    run(
        verilog_sources=shift_reg_rtl_src,  # Use shift reg only
        includes=includes,
        defines=defines,
        toplevel=toplevel,
        module=module,
        simulator=simulator,
        sim_build=sim_build,
        parameters=parameters,
    )
