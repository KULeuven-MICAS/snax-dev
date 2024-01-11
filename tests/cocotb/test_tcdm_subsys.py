# ---------------------------------
# Copyright 2023 KULeuven
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
# Author: Ryan Antonio (ryan.antonio@esat.kuleuven.be)
#
# Description:
# This tests the basic read and write funtcionality for each
# input port and checks if we can read/write data into the TCDM
# ---------------------------------

import cocotb
from cocotb.triggers import RisingEdge, Timer
from cocotb.clock import Clock
from cocotb_test.simulator import run
from decimal import Decimal
import pytest
import snax_util

# Configurable design time parameters
NARROW_DATA_WIDTH = 64
TCDM_DEPTH = 64
NR_BANKS = 8
NUM_INPUT = 2

# Optinally configurable parameters
NUM_OUTPUT = NR_BANKS
MIN_VAL = 0
MAX_VAL = 2**NARROW_DATA_WIDTH
BANK_INCREMENT = NARROW_DATA_WIDTH / 8

# Configurable testing parameters
# In the default value below, the number
# of tests fills the entire memory
NUM_TESTS = TCDM_DEPTH * NR_BANKS


@cocotb.test()
async def tcdm_subsys_dut(dut):
    clock = Clock(dut.clk_i, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Initial reset values
    # Need to clear for modelsim (or other simulator)
    # Verilator assumes 0, no don't care states
    dut.rst_ni.value = 0

    # These mappings are made easier due to the
    # modifications done in the /tb/tb_tcdm_subsys.sv
    # where the hard remappings were
    # included so that cocotb can see the signals
    # regardless of simulator
    for i in range(NUM_INPUT):
        dut.tcdm_req_write_i[i].value = 0
        dut.tcdm_req_addr_i[i].value = 0
        dut.tcdm_req_amo_i[i].value = 0
        dut.tcdm_req_data_i[i].value = 0
        dut.tcdm_req_user_core_id_i[i].value = 0
        dut.tcdm_req_user_is_core_i[i].value = 0
        dut.tcdm_req_strb_i[i].value = 0
        dut.tcdm_req_q_valid_i[i].value = 0

    await RisingEdge(dut.clk_i)
    await Timer(Decimal(1), units="ns")

    # Release reset
    dut.rst_ni.value = 1

    await RisingEdge(dut.clk_i)
    await Timer(Decimal(1), units="ns")

    # Begin test
    for i in range(NUM_INPUT):
        golden_list = snax_util.gen_rand_int_list(NUM_TESTS, MIN_VAL, MAX_VAL)

        # Cycle through values that change
        # Per item or element
        # Explicitly write the control signals
        for j in range(len(golden_list)):
            dut.tcdm_req_addr_i[i].value = int(j * BANK_INCREMENT)
            dut.tcdm_req_data_i[i].value = golden_list[j]
            dut.tcdm_req_strb_i[i].value = 0xFF
            dut.tcdm_req_write_i[i].value = 1
            dut.tcdm_req_q_valid_i[i].value = 1
            await RisingEdge(dut.clk_i)
            await Timer(Decimal(1), units="ns")

        # Clear default inputs for reading
        dut.tcdm_req_addr_i[i].value = 0
        dut.tcdm_req_data_i[i].value = 0
        dut.tcdm_req_strb_i[i].value = 0
        dut.tcdm_req_write_i[i].value = 0
        dut.tcdm_req_q_valid_i[i].value = 0
        await RisingEdge(dut.clk_i)
        await Timer(Decimal(1), units="ns")

        # Cycle through reads
        # And check immediately if result is correct
        for j in range(len(golden_list)):
            dut.tcdm_req_addr_i[i].value = int(j * BANK_INCREMENT)
            dut.tcdm_req_data_i[i].value = 0
            dut.tcdm_req_strb_i[i].value = 0
            dut.tcdm_req_write_i[i].value = 0
            dut.tcdm_req_q_valid_i[i].value = 1
            await RisingEdge(dut.clk_i)
            await Timer(Decimal(1), units="ns")

            # Check for results
            check_val = int(dut.tcdm_rsp_data_o[i].value)
            cocotb.log.info(f"Port {i} Actual output: {check_val}")
            cocotb.log.info(f"Golden output: {golden_list[j]}")
            assert check_val == golden_list[j]

        # Clear default inputs for reading
        dut.tcdm_req_addr_i[i].value = 0
        dut.tcdm_req_data_i[i].value = 0
        dut.tcdm_req_strb_i[i].value = 0
        dut.tcdm_req_write_i[i].value = 0
        dut.tcdm_req_q_valid_i[i].value = 0
        await RisingEdge(dut.clk_i)
        await Timer(Decimal(1), units="ns")


# Main test run
@pytest.mark.parametrize(
    "parameters",
    [
        {
            "NarrowDataWidth": str(NARROW_DATA_WIDTH),
            "TCDMDepth": str(TCDM_DEPTH),
            "NrBanks": str(NR_BANKS),
            "NumInp": str(NUM_INPUT),
            "NumOut": str(NUM_OUTPUT),
        }
    ],
)
def test_tcdm_subsys(parameters, simulator):
    tests_path = "./tests/cocotb/"

    defines = []

    includes, verilog_sources = snax_util.extract_tcdm_list()

    toplevel = "tb_tcdm_subsys"

    module = "test_tcdm_subsys"

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
            "--trace",
            "--trace-structs",
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
