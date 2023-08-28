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
import pytest
import snax_util


# Testing parameters
CLOCK_CYCLES = 20


@cocotb.test()
async def snitch_cc_dut(dut):
    clock = Clock(dut.clk_i, 10, units="ns")
    cocotb.start_soon(clock.start())

    dut.rst_ni.value = 0

    await RisingEdge(dut.clk_i)

    dut.rst_ni.value = 1

    for i in range(CLOCK_CYCLES):
        await RisingEdge(dut.clk_i)


# Main test run
@pytest.mark.parametrize("parameters", [{"AddrWidth": str(48), "DataWidth": str(64)}])
def test_snitch_cc(parameters, simulator):
    tests_path = "./tests/cocotb/"

    includes, defines, verilog_sources = snax_util.extract_bender_filelist()

    # Append test bench to rtl list
    verilog_sources.append("tests/tb/tb_snitch_cc.sv")

    toplevel = "tb_snitch_cc"

    module = "test_snitch_cc"

    sim_build = tests_path + "/sim_build/{}/".format(toplevel)

    if simulator == "verilator":
        compile_args = [
            "-Wno-LITENDIAN",
            "-Wno-WIDTH",
            "-Wno-CASEINCOMPLETE",
            "-Wno-BLKANDNBLK",
            "-Wno-CMPCONST",
            "-Wno-WIDTHCONCAT",
            "-Wno-UNSIGNED",
            "-Wno-UNOPTFLAT",
            "-Wno-TIMESCALEMOD",
            "-Wno-fatal",
            "--no-timing",
        ]
        timescale = None
    else:
        compile_args = None
        timescale = "1ns/1ps"

    run(
        verilog_sources=verilog_sources,
        includes=includes,
        toplevel=toplevel,
        defines=defines,
        module=module,
        simulator=simulator,
        sim_build=sim_build,
        compile_args=compile_args,
        timescale=timescale,
    )
