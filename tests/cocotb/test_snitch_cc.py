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
import pytest


# Reconfigurable parameters
CLOCK_CYCLES = 20


@cocotb.test()
async def snitch_cc_dut(dut):
    # Initialize clock
    clock = Clock(dut.clk_i, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Reset or intial values
    dut.rst_ni.value = 0

    # Wait 1 cycle to reset
    await RisingEdge(dut.clk_i)

    # Deassert reset
    dut.rst_ni.value = 1

    for i in range(CLOCK_CYCLES):
        # Simple check if instructions are running normally
        # instruction_value = hex(dut.i_snitch_cc.i_snitch.inst_data_i.value)
        # instruction_address = int(dut.instruction_addr_offset.value)

        # cocotb.log.info('---------- Instruction Info ----------')
        # cocotb.log.info(f'Instruction Value: {instruction_value}')
        # cocotb.log.info(f'Instruction Addr: {instruction_address}')

        await RisingEdge(dut.clk_i)


# Main test run
@pytest.mark.parametrize("parameters", [{"AddrWidth": str(48), "DataWidth": str(64)}])
def test_snitch_cc(parameters, simulator):
    # Working paths
    repo_path = "something"
    tests_path = repo_path + "/tests/cocotb/"

    filelist = subprocess.run(["bender", "script", "verilator"], stdout=subprocess.PIPE)

    filelist = filelist.stdout.decode("utf-8").strip().split("\n")

    include_folders = []
    rtl_sources = []

    for item in filelist:
        if item == "":
            pass
        elif (
            item[0] == "#"
            or item[0] == ""
            or item[0] == "\n"
            or item[0:8] == "+define+"
        ):
            pass
        elif item[0:8] == "+incdir+":
            include_folders.append(item[8:].strip())
        else:
            rtl_sources.append(item.strip())

    # Append test bench to rtl list
    rtl_sources.append("tests/tb/tb_snitch_cc.sv")

    # Specify top-level module
    toplevel = "tb_snitch_cc"

    # Specify python test name that contains the @cocotb.test.
    # Usually the name of this test.
    module = "test_snitch_cc"

    # Specify build directory
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

        run(
            verilog_sources=rtl_sources,
            includes=include_folders,
            toplevel=toplevel,
            module=module,
            simulator=simulator,
            sim_build=sim_build,
            compile_args=compile_args,
        )
    else:
        run(
            verilog_sources=rtl_sources,
            includes=include_folders,
            toplevel=toplevel,
            module=module,
            simulator=simulator,
            timescale="1ps",
        )
