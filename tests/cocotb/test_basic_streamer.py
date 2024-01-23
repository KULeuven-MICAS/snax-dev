# ---------------------------------
# Copyright 2024 KULeuven
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
# Author: Ryan Antonio (ryan.antonio@esat.kuleuven.be)
#
# Description:
# This tests the basic configuration of the streamer
# found in ./util/cfg/streamer_cfg.hjson
#
# Sequence of tests:
# 1. First test read and write to CSR registers
# 2. Check if the output addresses of TCDM
#    are correct and valid
# ---------------------------------

import cocotb
from cocotb.triggers import RisingEdge
from cocotb.clock import Clock
from cocotb_test.simulator import run
import pytest
import snax_util
import os
import subprocess

# Configurable design time parameters
NARROW_DATA_WIDTH = 64
TCDM_DEPTH = 256
TCDM_REQ_PORTS = 12

# DON'T TOUCH ME PLEASE
# CSR parameters from the default
# Configuration found under util/cfg/streamer_cfg.hjson
# Also some pre-computed that are fixed
CSR_LOOP_COUNT_0 = 0
CSR_TEMPORAL_STRIDE_0 = 1
CSR_TEMPORAL_STRIDE_1 = 2
CSR_TEMPORAL_STRIDE_2 = 3
CSR_SPATIAL_STRIDE_0 = 4
CSR_SPATIAL_STRIDE_1 = 5
CSR_SPATIAL_STRIDE_2 = 6
CSR_BASE_PTR_0 = 7
CSR_BASE_PTR_1 = 8
CSR_BASE_PTR_2 = 9
CSR_START_STREAMER = 10

# Value configurations you can set
# For exploration and testing
# These values go into the respective
# CSR register addresses above
LOOP_COUNT_0 = 20
TEMPORAL_STRIDE_0 = 2
TEMPORAL_STRIDE_1 = 2
TEMPORAL_STRIDE_2 = 2
SPATIAL_STRIDE_0 = 8
SPATIAL_STRIDE_1 = 8
SPATIAL_STRIDE_2 = 8
BASE_PTR_0 = 0
BASE_PTR_1 = 32
BASE_PTR_2 = 64


# Some functions for generating golden model
# This is only useful here in this test
# Basically it uses the default configuration
# For the gen_basic_stream_gold_list,
# Note that TCDM ports 0-3, and 4-7 are for readers
# (specifically port_a and port_b)
# While the TCDM ports 8-11 are for writing
# (specifically port_c)
def gen_basic_stream_gold_list():
    golden_list = []

    for i in range(LOOP_COUNT_0):
        port_a_list = []
        port_b_list = []
        port_c_list = []
        for j in range(int(TCDM_REQ_PORTS / 3)):
            port_a = BASE_PTR_0 + j * SPATIAL_STRIDE_0 + i * TEMPORAL_STRIDE_0
            port_a_list.append(port_a)
            port_b = BASE_PTR_1 + j * SPATIAL_STRIDE_1 + i * TEMPORAL_STRIDE_1
            port_b_list.append(port_b)
            port_c = BASE_PTR_2 + j * SPATIAL_STRIDE_2 + i * TEMPORAL_STRIDE_2
            port_c_list.append(port_c)

        golden_list.append(port_a_list + port_b_list + port_c_list)

    return golden_list


@cocotb.test()
async def basic_streamer_dut(dut):
    clock = Clock(dut.clk_i, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Initial reset values
    # Need to clear for modelsim (or other simulator)
    # Verilator assumes 0, no don't care states
    dut.rst_ni.value = 0

    # Always active for continuous streaming
    dut.io_csr_rsp_ready_i.value = 1

    # From the accelerator ports to streamer ports
    # Tie the valid and ready to 1
    # So that we can see address changes
    dut.acc2stream_data_0_bits_i.value = 0
    dut.acc2stream_data_0_valid_i.value = 1
    dut.stream2acc_data_0_ready_i.value = 1
    dut.stream2acc_data_1_ready_i.value = 1

    # TCDM ports that need to be forever active
    # Just so that the address generation is
    # Continuous
    for i in range(TCDM_REQ_PORTS):
        dut.tcdm_rsp_q_ready_i[i].value = 1
        dut.tcdm_rsp_p_valid_i[i].value = 1
        dut.tcdm_rsp_data_i[i].value = 0

    await RisingEdge(dut.clk_i)

    dut.rst_ni.value = 1

    await RisingEdge(dut.clk_i)

    cocotb.log.info("Setting up of CSR registers and verifying if setup is correct")

    # At this point we'll do explicit declartion
    # of the tests so that it's understandable
    # for other users

    # Set number of iterations
    await snax_util.reg_write(dut, CSR_LOOP_COUNT_0, LOOP_COUNT_0)

    # Set temporal strides
    await snax_util.reg_write(dut, CSR_TEMPORAL_STRIDE_0, TEMPORAL_STRIDE_0)
    await snax_util.reg_write(dut, CSR_TEMPORAL_STRIDE_1, TEMPORAL_STRIDE_1)
    await snax_util.reg_write(dut, CSR_TEMPORAL_STRIDE_2, TEMPORAL_STRIDE_2)

    # Set spatial strides
    await snax_util.reg_write(dut, CSR_SPATIAL_STRIDE_0, SPATIAL_STRIDE_0)
    await snax_util.reg_write(dut, CSR_SPATIAL_STRIDE_1, SPATIAL_STRIDE_1)
    await snax_util.reg_write(dut, CSR_SPATIAL_STRIDE_2, SPATIAL_STRIDE_2)

    # Set base pointers
    await snax_util.reg_write(dut, CSR_BASE_PTR_0, BASE_PTR_0)
    await snax_util.reg_write(dut, CSR_BASE_PTR_1, BASE_PTR_1)
    await snax_util.reg_write(dut, CSR_BASE_PTR_2, BASE_PTR_2)

    # Clear driver signals
    # So that we don't have stuck valid
    await snax_util.reg_clr(dut)

    # Read and verify the contents
    # of the previously set registers
    reg_val = await snax_util.reg_read(dut, CSR_LOOP_COUNT_0)
    snax_util.comp_and_assert(LOOP_COUNT_0, reg_val)
    reg_val = await snax_util.reg_read(dut, CSR_TEMPORAL_STRIDE_0)
    snax_util.comp_and_assert(TEMPORAL_STRIDE_0, reg_val)
    reg_val = await snax_util.reg_read(dut, CSR_TEMPORAL_STRIDE_1)
    snax_util.comp_and_assert(TEMPORAL_STRIDE_1, reg_val)
    reg_val = await snax_util.reg_read(dut, CSR_TEMPORAL_STRIDE_2)
    snax_util.comp_and_assert(TEMPORAL_STRIDE_2, reg_val)
    reg_val = await snax_util.reg_read(dut, CSR_SPATIAL_STRIDE_0)
    snax_util.comp_and_assert(SPATIAL_STRIDE_0, reg_val)
    reg_val = await snax_util.reg_read(dut, CSR_SPATIAL_STRIDE_1)
    snax_util.comp_and_assert(SPATIAL_STRIDE_1, reg_val)
    reg_val = await snax_util.reg_read(dut, CSR_SPATIAL_STRIDE_2)
    snax_util.comp_and_assert(SPATIAL_STRIDE_2, reg_val)
    reg_val = await snax_util.reg_read(dut, CSR_BASE_PTR_0)
    snax_util.comp_and_assert(BASE_PTR_0, reg_val)
    reg_val = await snax_util.reg_read(dut, CSR_BASE_PTR_1)
    snax_util.comp_and_assert(BASE_PTR_1, reg_val)
    reg_val = await snax_util.reg_read(dut, CSR_BASE_PTR_2)
    snax_util.comp_and_assert(BASE_PTR_2, reg_val)

    # Clear driver signals
    # So that we don't have stuck valid
    await snax_util.reg_clr(dut)

    cocotb.log.info("Run the streamer and check if addresses are correct")

    # Do a run of the streamer
    # We can write anything on this address
    # And it will automatically run the streamer
    await snax_util.reg_write(dut, CSR_START_STREAMER, 0)

    # First generate the golden answer list
    golden_list = gen_basic_stream_gold_list()

    # Cycle for each TCDM request ports
    # Check the temporal loop
    for i in range(LOOP_COUNT_0):
        for j in range(TCDM_REQ_PORTS):
            read_val = int(dut.tcdm_req_addr_o[j].value)
            snax_util.comp_and_assert(golden_list[i][j], read_val)
        await snax_util.clock_and_wait(dut)


# Main test run
@pytest.mark.parametrize(
    "parameters",
    [
        {
            "NarrowDataWidth": str(NARROW_DATA_WIDTH),
            "TCDMDepth": str(TCDM_DEPTH),
            "TCDMReqPorts": str(TCDM_REQ_PORTS),
        }
    ],
)
def test_basic_streamer(parameters, simulator, waves):
    repo_path = os.getcwd()
    tests_path = repo_path + "/tests/cocotb/"

    # Make sure to generate the StreamerTop.sv
    # If it does not exist
    streamer_top_file = repo_path + "/rtl/StreamerTop.sv"
    if not os.path.exists(streamer_top_file):
        subprocess.run(["make", "gen_stream_top"])

    verilog_sources = [
        repo_path + "/rtl/StreamerTop.sv",
        repo_path + "/rtl/streamer_wrapper.sv",
        repo_path + "/tests/tb/tb_streamer_top.sv",
    ]
    defines = []
    includes = []

    toplevel = "tb_streamer_top"

    module = "test_basic_streamer"

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
        waves=waves,
        timescale=timescale,
    )
