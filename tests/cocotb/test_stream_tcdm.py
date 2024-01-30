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
from cocotb.triggers import RisingEdge, Timer
from cocotb.clock import Clock
from cocotb_test.simulator import run
import snax_util
import os
import subprocess
from decimal import Decimal

# Configurable design time parameters
TCDM_REQ_PORTS = 12
NARROW_DATA_WIDTH = 64
WIDE_DATA_WIDTH = 512
TCDM_DEPTH = 64
NR_BANKS = 32
NUM_INPUT = 2

# Configurable testing parameters
# In the default value below, the number
# of tests fills the entire memory
BANK_INCREMENT = int(NARROW_DATA_WIDTH / 8)
WIDE_BANK_INCREMENT = int(WIDE_DATA_WIDTH / 8)
WIDE_NARROW_RATIO = int(WIDE_DATA_WIDTH / NARROW_DATA_WIDTH)
NUM_NARROW_TESTS = TCDM_DEPTH * NR_BANKS
NUM_WIDE_TESTS = int(NUM_NARROW_TESTS / 8)
MIN_VAL = 0
MAX_NARROW_VAL = 2**NARROW_DATA_WIDTH
MAX_WIDE_VAL = 2**WIDE_DATA_WIDTH

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


@cocotb.test()
async def stream_tcdm_dut(dut):
    # Value configurations you can set
    # For exploration and testing
    # These values go into the respective
    # CSR register addresses above
    LOOP_COUNT_0 = 20
    TEMPORAL_STRIDE_0 = 64
    TEMPORAL_STRIDE_1 = 64
    TEMPORAL_STRIDE_2 = 64
    SPATIAL_STRIDE_0 = 8
    SPATIAL_STRIDE_1 = 8
    SPATIAL_STRIDE_2 = 8
    BASE_PTR_0 = 0
    BASE_PTR_1 = 32
    BASE_PTR_2 = 0

    # Start clock
    clock = Clock(dut.clk_i, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Initial reset values
    # Need to clear for modelsim (or other simulator)
    # Verilator assumes 0, no don't care states
    dut.rst_ni.value = 0

    # Always active assuming core can
    # contiuously read data from streamer CSR
    dut.io_csr_rsp_ready_i.value = 1

    # From the accelerator ports to streamer ports
    # Tie the valid and ready to 1
    # So that we can see address changes
    dut.acc2stream_data_0_bits_i.value = 0
    dut.acc2stream_data_0_valid_i.value = 0
    dut.stream2acc_data_0_ready_i.value = 1
    dut.stream2acc_data_1_ready_i.value = 1

    # Set DMA ports to 0 first before driving
    dut.tcdm_dma_req_write_i.value = 0
    dut.tcdm_dma_req_addr_i.value = 0
    dut.tcdm_dma_req_data_i.value = 0
    dut.tcdm_dma_req_strb_i.value = 0
    dut.tcdm_dma_req_q_valid_i.value = 0

    await snax_util.clock_and_wait(dut)

    # Release reset
    dut.rst_ni.value = 1

    await snax_util.clock_and_wait(dut)

    # Preload data into the TCDM subsys
    # using the DMA ports
    cocotb.log.info("Preload data with DMA control")

    # Generate data to be processed
    # Number of elements is dependent on:
    # LOOP_COUNT_0 x (WIDE_DATA_WIDTH / NARROW_DATA_WIDTH)
    narrow_golden_list = snax_util.gen_rand_int_list(
        int(LOOP_COUNT_0 * (WIDE_DATA_WIDTH / NARROW_DATA_WIDTH)), MIN_VAL, 255
    )
    wide_golden_list = snax_util.gen_wide_list(
        narrow_golden_list, NARROW_DATA_WIDTH, WIDE_DATA_WIDTH
    )

    narrow_writer_golden_list = snax_util.gen_rand_int_list(
        int(LOOP_COUNT_0 * (WIDE_DATA_WIDTH / NARROW_DATA_WIDTH / 2)), MIN_VAL, 255
    )
    wide_writer_golden_list = snax_util.gen_wide_list(
        narrow_writer_golden_list, NARROW_DATA_WIDTH, 256
    )

    # Preload TCDM DMA subsys using DMA ports
    wide_len = len(wide_golden_list)
    for i in range(wide_len):
        await snax_util.wide_tcdm_write(
            dut, i * WIDE_BANK_INCREMENT, wide_golden_list[i]
        )

    await snax_util.wide_tcdm_clr(dut)

    # Sanity check contents loaded into DMA
    for i in range(wide_len):
        tcdm_wide_val = await snax_util.wide_tcdm_read(dut, i * WIDE_BANK_INCREMENT)
        snax_util.comp_and_assert(wide_golden_list[i], tcdm_wide_val)

    await snax_util.wide_tcdm_clr(dut)

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
    await snax_util.reg_clr(dut)

    # In this test we simply continuously
    # stream the data in the stream to accelerator ports
    # and check if the data is consistent with the preloaded data
    cocotb.log.info("Run the streamer and check if data are correct")

    # Write anything to CSR_STAR_STREAMER CSR
    # adderss to activate the streamer
    await snax_util.reg_write(dut, CSR_START_STREAMER, 0)
    await snax_util.reg_clr(dut)

    # Wait for the rising edge of the valid
    # From there we can continuously stream for ever clock cycle
    await RisingEdge(dut.stream2acc_data_0_valid_o)

    # Necessary for cocotb evaluation step
    await Timer(Decimal(1), units="ps")

    for i in range(LOOP_COUNT_0):
        # Extract the data
        read_stream_0 = int(dut.stream2acc_data_0_bits_o.value)
        read_stream_1 = int(dut.stream2acc_data_1_bits_o.value)

        # Combine data into 512 bits wide
        # Note that each reader port is 256 bits only
        # Compare combined data to the wide golden list
        combined_val = read_stream_0 + (read_stream_1 << 256)
        snax_util.comp_and_assert(wide_golden_list[i], combined_val)
        await snax_util.clock_and_wait(dut)

    # In this test the writer is streamed continuosly
    # then we read through one of the reader ports
    cocotb.log.info("Writer-reader test")

    # Allow the writer to write data unto the streamer
    writer_len = len(wide_writer_golden_list)
    for i in range(writer_len):
        dut.acc2stream_data_0_bits_i.value = wide_writer_golden_list[i]
        dut.acc2stream_data_0_valid_i.value = 1
        await snax_util.clock_and_wait(dut)

    # Clear step to avoid overwriting
    dut.acc2stream_data_0_bits_i.value = 0
    dut.acc2stream_data_0_valid_i.value = 0
    await snax_util.clock_and_wait(dut)

    # Switch off 2nd reader since the
    # 1st reader will be the only one used
    dut.stream2acc_data_1_ready_i.value = 0
    await snax_util.clock_and_wait(dut)

    # Start streamer again
    await snax_util.reg_write(dut, CSR_START_STREAMER, 0)
    await snax_util.reg_clr(dut)

    # Wait for the rising edge of the valid
    # From here we can continuously stream for ever clock cycle
    await RisingEdge(dut.stream2acc_data_0_valid_o)
    # Necessary for cocotb evaluation step
    await Timer(Decimal(1), units="ps")

    for i in range(LOOP_COUNT_0):
        # Extract the data
        read_stream_0 = int(dut.stream2acc_data_0_bits_o.value)

        # Streamed data should be consistent
        snax_util.comp_and_assert(wide_writer_golden_list[i], read_stream_0)
        await snax_util.clock_and_wait(dut)


# Main test run
def test_stream_tcdm(simulator, waves):
    repo_path = os.getcwd()
    tests_path = repo_path + "/tests/cocotb/"

    # Make sure to generate the StreamerTop.sv
    # If it does not exist
    streamer_top_file = repo_path + "/rtl/StreamerTop.sv"
    if not os.path.exists(streamer_top_file):
        subprocess.run(["make", "gen_stream_tcdm_tb"])

    streamer_verilog_sources = [
        repo_path + "/rtl/StreamerTop.sv",
        repo_path + "/rtl/streamer_wrapper.sv",
    ]

    # Extract TCDM components
    tcdm_includes, tcdm_verilog_sources = snax_util.extract_tcdm_list()

    tb_verilog_source = [
        repo_path + "/tests/tb/tb_stream_tcdm_top.sv",
    ]

    verilog_sources = (
        tcdm_verilog_sources + streamer_verilog_sources + tb_verilog_source
    )

    defines = []
    includes = [] + tcdm_includes

    toplevel = "tb_stream_tcdm_top"

    module = "test_stream_tcdm"

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
        waves=waves,
        timescale=timescale,
    )
