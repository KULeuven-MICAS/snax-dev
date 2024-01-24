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
from cocotb.clock import Clock
from cocotb_test.simulator import run
import pytest
import snax_util
import math

# Configurable design time parameters
NARROW_DATA_WIDTH = 64
WIDE_DATA_WIDTH = 512
TCDM_DEPTH = 64
NR_BANKS = 32
NUM_INPUT = 2

# Configuration checker for the DMA wide
# TCDM interconnection because
# We need to make sure that the memory
# and interconnect matches the addressing
TCDM_SIZE = int(NR_BANKS * TCDM_DEPTH * NARROW_DATA_WIDTH / 8)
TCDM_ADDR_WIDTH = math.ceil(math.log2(TCDM_SIZE))
TCDM_MEM_ADDR_WIDTH = math.ceil(math.log2(TCDM_DEPTH))
NR_BANKS_PER_SUPERBANK = WIDE_DATA_WIDTH / NARROW_DATA_WIDTH
NR_SUPER_BANKS = int(NR_BANKS / NR_BANKS_PER_SUPERBANK)
WIDE_TCDM_PORTS = math.ceil(math.log2(NR_SUPER_BANKS))
WIDE_BYTE_OFFSET = math.ceil(math.log2(int(WIDE_DATA_WIDTH / 8)))

assert TCDM_ADDR_WIDTH >= (
    TCDM_MEM_ADDR_WIDTH + WIDE_TCDM_PORTS + WIDE_BYTE_OFFSET
), "Error config! Make sure to satisfy the assertion equation"

# Optinally configurable parameters
NUM_OUTPUT = NR_BANKS
MIN_VAL = 0
MAX_VAL = 2**NARROW_DATA_WIDTH - 1
WIDE_MIN_VAL = 0
WIDE_MAX_VAL = 2**WIDE_DATA_WIDTH - 1
BANK_INCREMENT = int(NARROW_DATA_WIDTH / 8)
WIDE_BANK_INCREMENT = int(BANK_INCREMENT * (WIDE_DATA_WIDTH / NARROW_DATA_WIDTH))

# Configurable testing parameters
# In the default value below, the number
# of tests fills the entire memory
NUM_NARROW_TESTS = TCDM_DEPTH * NR_BANKS
NUM_WIDE_TESTS = int(NUM_NARROW_TESTS / 8)


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

    dut.tcdm_dma_req_write_i.value = 0
    dut.tcdm_dma_req_addr_i.value = 0
    dut.tcdm_dma_req_data_i.value = 0
    dut.tcdm_dma_req_strb_i.value = 0
    dut.tcdm_dma_req_q_valid_i.value = 0

    await snax_util.clock_and_wait(dut)

    # Release reset
    dut.rst_ni.value = 1

    await snax_util.clock_and_wait(dut)

    # Begin test
    cocotb.log.info(" ------------------------------------------ ")
    cocotb.log.info(" Testing for TCDM request and response ports")
    cocotb.log.info(" ------------------------------------------ ")
    for i in range(NUM_INPUT):
        golden_list = snax_util.gen_rand_int_list(NUM_NARROW_TESTS, MIN_VAL, MAX_VAL)

        # Cycle through values that change
        # Per item or element
        # Explicitly write the control signals
        for j in range(NUM_NARROW_TESTS):
            await snax_util.tcdm_write(dut, i, int(j * BANK_INCREMENT), golden_list[j])

        # Clear default inputs for reading
        await snax_util.tcdm_clr(dut, i)

        # Cycle through reads
        # And check immediately if result is correct
        for j in range(NUM_NARROW_TESTS):
            check_val = await snax_util.tcdm_read(dut, i, int(j * BANK_INCREMENT))
            # Check for results
            cocotb.log.info(f"Port {i} Actual output: {check_val}")
            cocotb.log.info(f"Golden output: {golden_list[j]}")
            assert check_val == golden_list[j]

        # Clear default inputs for reading
        await snax_util.tcdm_clr(dut, i)

    cocotb.log.info(" ------------------------------------------ ")
    cocotb.log.info(" Wide TCDM tests for the DMA transfers")
    cocotb.log.info(" ------------------------------------------ ")

    # Get golden data
    wide_golden_list = snax_util.gen_rand_int_list(
        NUM_WIDE_TESTS, WIDE_MIN_VAL, WIDE_MAX_VAL
    )

    # Write data to TCDM
    for i in range(NUM_WIDE_TESTS):
        await snax_util.wide_tcdm_write(
            dut, i * WIDE_BANK_INCREMENT, wide_golden_list[i]
        )
        print(i * WIDE_BANK_INCREMENT)

    # Write to clear
    await snax_util.wide_tcdm_clr(dut)

    # Read data from TCDM
    for i in range(NUM_WIDE_TESTS):
        check_val = await snax_util.wide_tcdm_read(dut, int(i * WIDE_BANK_INCREMENT))
        # Check for results
        cocotb.log.info(f"Actual output: {check_val}")
        cocotb.log.info(f"Golden output: {wide_golden_list[i]}")
        assert check_val == wide_golden_list[i]


# Main test run
@pytest.mark.parametrize(
    "parameters",
    [
        {
            "NarrowDataWidth": str(NARROW_DATA_WIDTH),
            "WideDataWidth": str(WIDE_DATA_WIDTH),
            "TCDMDepth": str(TCDM_DEPTH),
            "NrBanks": str(NR_BANKS),
            "NumInp": str(NUM_INPUT),
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
        parameters=parameters,
    )
