# ---------------------------------
# Copyright 2024 KULeuven
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
# Author: Ryan Antonio (ryan.antonio@esat.kuleuven.be)
#
# Description:
# This test is a complete set where the TCDM subsystem,
# SNAX streamer, and a dummy accelerator are connected together.
# The dummy accelerator is a simple multiply streamer.
#
# Sequence of tests:
# 1. Load data through DMA
# 2. Set the streamer CSRs
# 3. Check the output of the streamer
# ---------------------------------

import cocotb
from cocotb.triggers import RisingEdge, Timer
from cocotb.clock import Clock
from cocotb_test.simulator import run
import snax_util
import os
import subprocess
from decimal import Decimal
import math

from tests.cocotb.test_tcdm_subsys import MAX_VAL

# Transformation parameters configuration
TRANSFORMATION_PARAMS = {
    "nb_elements": 64,
    "nb_for_loops": 2,
    "strides": [
        {
            "src": 1,
            "dst": 8,
            "bound": 8
        },
        {
            "src": 8,
            "dst": 1,
            "bound": 8
        },
    ]
}

# Configurable testing parameters
# In the default value below, the number
# of tests fills the entire memory
NARROW_DATA_WIDTH = 64
WIDE_DATA_WIDTH = 512
TCDM_DEPTH = 64
NR_BANKS = 32
SPATPAR = 1
ALIGN_ELEMS = 8
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

CSR_RESHUFFLER_GPP_0 = 0
CSR_RESHUFFLER_GPP_1 = 1
CSR_RESHUFFLER_GPP_2 = 2
CSR_RESHUFFLER_GPP_3 = 3
CSR_RESHUFFLER_GPP_4 = 4
CSR_RESHUFFLER_GPP_5 = 5
CSR_RESHUFFLER_GPP_6 = 6
CSR_RESHUFFLER_GPP_7 = 7

# This STREAMER_OFFSET is the offset
# For the address registers
STREAMER_OFFSET = 8

CSR_LOOP_COUNT_0 = 0 + STREAMER_OFFSET
CSR_LOOP_COUNT_1 = 1 + STREAMER_OFFSET
CSR_TEMPORAL_STRIDE_M0_L0 = 2 + STREAMER_OFFSET
CSR_TEMPORAL_STRIDE_M0_L1 = 3 + STREAMER_OFFSET
CSR_TEMPORAL_STRIDE_M1_L0 = 4 + STREAMER_OFFSET
CSR_TEMPORAL_STRIDE_M1_L1 = 5 + STREAMER_OFFSET
CSR_SPATIAL_STRIDE_M0 = 6 + STREAMER_OFFSET
CSR_SPATIAL_STRIDE_M1 = 7 + STREAMER_OFFSET
CSR_BASE_PTR_M0 = 8 + STREAMER_OFFSET
CSR_BASE_PTR_M1 = 9 + STREAMER_OFFSET
CSR_START_STREAMER = 10 + STREAMER_OFFSET


@cocotb.test()
async def stream_reshuffler_dut(dut):
    # Value configurations you can set
    # For exploration and testing
    # These values go into the respective
    # CSR register addresses above

    # Reshuffler_CSR_CONFIG has the following:
    RESHUFFLER_GPP_0 = 0 # Unused temporarily
    RESHUFFLER_GPP_1 = 0 # Unused temporarily
    RESHUFFLER_GPP_2 = 0 # Unused temporarily
    RESHUFFLER_GPP_3 = 0 # Unused temporarily
    RESHUFFLER_GPP_4 = 0 # Unused temporarily
    RESHUFFLER_GPP_5 = 0 # Unused temporarily
    RESHUFFLER_GPP_6 = 0 # Unused temporarily
    RESHUFFLER_GPP_7 = 0 # Unused temporarily

    # These ones go into the
    # streamer registers
    LOOP_COUNT_0 = TRANSFORMATION_PARAMS['strides'][-1]['bound']
    LOOP_COUNT_1 = TRANSFORMATION_PARAMS['strides'][-2]['bound']    # Outer-Most Loop
    
    # Reader - Mover 0
    # TEMPORAL_STRIDE_M0_L0 = 1
    TEMPORAL_STRIDE_M0_L0 = TRANSFORMATION_PARAMS['strides'][-1]['src'] * ALIGN_ELEMS
    TEMPORAL_STRIDE_M0_L1 = TRANSFORMATION_PARAMS['strides'][-2]['src'] * ALIGN_ELEMS
    SPATIAL_STRIDE_M0 = 0       # Not used
    BASE_PTR_M0 = 0

    # Writer - Mover 1
    # TEMPORAL_STRIDE_M1_L0 = 1
    TEMPORAL_STRIDE_M1_L0 = TRANSFORMATION_PARAMS['strides'][-1]['dst'] * ALIGN_ELEMS
    TEMPORAL_STRIDE_M1_L1 = TRANSFORMATION_PARAMS['strides'][-2]['dst'] * ALIGN_ELEMS
    SPATIAL_STRIDE_M1 = 0       # Not used
    OFFSET = 8                  # Relieve bank confilct via a pre-computed offset
    BASE_PTR_M1 = NR_BANKS * math.ceil(LOOP_COUNT_0 * LOOP_COUNT_1 * ALIGN_ELEMS / NR_BANKS) + OFFSET


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
        int(LOOP_COUNT_0 * LOOP_COUNT_1), MIN_VAL, MAX_VAL
    )
    cocotb.log.info("Narrow_Golden_List: %s", narrow_golden_list)
    wide_golden_list = snax_util.gen_wide_list(
        narrow_golden_list, NARROW_DATA_WIDTH, WIDE_DATA_WIDTH
    )
    cocotb.log.info("Wide_Golden_List: %s", wide_golden_list)
    # Precompute golden results
    narrow_golden_result = snax_util.transform_data(narrow_golden_list, TRANSFORMATION_PARAMS)
    cocotb.log.info("Narrow_Golden_Result: %s", narrow_golden_result)

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

    # Setting of ALU accelerator registers
    # Only CSR_ALU_CONFIG affects the accelerator
    # The other registers are for read/write checks only
    await snax_util.reg_write(dut, CSR_RESHUFFLER_GPP_0, RESHUFFLER_GPP_0)
    await snax_util.reg_write(dut, CSR_RESHUFFLER_GPP_1, RESHUFFLER_GPP_1)
    await snax_util.reg_write(dut, CSR_RESHUFFLER_GPP_2, RESHUFFLER_GPP_2)
    await snax_util.reg_write(dut, CSR_RESHUFFLER_GPP_3, RESHUFFLER_GPP_3)
    await snax_util.reg_write(dut, CSR_RESHUFFLER_GPP_4, RESHUFFLER_GPP_4)
    await snax_util.reg_write(dut, CSR_RESHUFFLER_GPP_5, RESHUFFLER_GPP_5)
    await snax_util.reg_write(dut, CSR_RESHUFFLER_GPP_6, RESHUFFLER_GPP_6)
    await snax_util.reg_write(dut, CSR_RESHUFFLER_GPP_7, RESHUFFLER_GPP_7)

    # At this point we'll do explicit declartion
    # of the tests so that it's understandable
    # for other users

    # Set number of iterations
    await snax_util.reg_write(dut, CSR_LOOP_COUNT_0, LOOP_COUNT_0)
    await snax_util.reg_write(dut, CSR_LOOP_COUNT_1, LOOP_COUNT_1)

    # Set temporal strides
    await snax_util.reg_write(dut, CSR_TEMPORAL_STRIDE_M0_L0, TEMPORAL_STRIDE_M0_L0)
    await snax_util.reg_write(dut, CSR_TEMPORAL_STRIDE_M0_L1, TEMPORAL_STRIDE_M0_L1)
    await snax_util.reg_write(dut, CSR_TEMPORAL_STRIDE_M1_L0, TEMPORAL_STRIDE_M1_L0)
    await snax_util.reg_write(dut, CSR_TEMPORAL_STRIDE_M1_L1, TEMPORAL_STRIDE_M1_L1)

    # Set base pointers
    await snax_util.reg_write(dut, CSR_BASE_PTR_M0, BASE_PTR_M0)
    await snax_util.reg_write(dut, CSR_BASE_PTR_M1, BASE_PTR_M1)

    # Clear driver signals
    # So that we don't have stuck valid
    await snax_util.reg_clr(dut)

    # Read and verify the contents
    # of the previously set registers

    # Check ALU registers first
    reg_val = await snax_util.reg_read(dut, CSR_RESHUFFLER_GPP_0)
    snax_util.comp_and_assert(RESHUFFLER_GPP_0, reg_val)
    reg_val = await snax_util.reg_read(dut, CSR_RESHUFFLER_GPP_1)
    snax_util.comp_and_assert(RESHUFFLER_GPP_1, reg_val)
    reg_val = await snax_util.reg_read(dut, CSR_RESHUFFLER_GPP_2)
    snax_util.comp_and_assert(RESHUFFLER_GPP_2, reg_val)
    reg_val = await snax_util.reg_read(dut, CSR_RESHUFFLER_GPP_3)
    snax_util.comp_and_assert(RESHUFFLER_GPP_3, reg_val)
    reg_val = await snax_util.reg_read(dut, CSR_RESHUFFLER_GPP_4)
    snax_util.comp_and_assert(RESHUFFLER_GPP_4, reg_val)
    reg_val = await snax_util.reg_read(dut, CSR_RESHUFFLER_GPP_5)
    snax_util.comp_and_assert(RESHUFFLER_GPP_5, reg_val)
    reg_val = await snax_util.reg_read(dut, CSR_RESHUFFLER_GPP_6)
    snax_util.comp_and_assert(RESHUFFLER_GPP_6, reg_val)
    reg_val = await snax_util.reg_read(dut, CSR_RESHUFFLER_GPP_7)
    snax_util.comp_and_assert(RESHUFFLER_GPP_7, reg_val)

    # Check Streamer registers
    reg_val = await snax_util.reg_read(dut, CSR_LOOP_COUNT_0)
    snax_util.comp_and_assert(LOOP_COUNT_0, reg_val)
    reg_val = await snax_util.reg_read(dut, CSR_LOOP_COUNT_1)
    snax_util.comp_and_assert(LOOP_COUNT_1, reg_val)
        
    reg_val = await snax_util.reg_read(dut, CSR_TEMPORAL_STRIDE_M0_L0)
    snax_util.comp_and_assert(TEMPORAL_STRIDE_M0_L0, reg_val)
    reg_val = await snax_util.reg_read(dut, CSR_TEMPORAL_STRIDE_M0_L1)
    snax_util.comp_and_assert(TEMPORAL_STRIDE_M0_L1, reg_val)
    reg_val = await snax_util.reg_read(dut, CSR_TEMPORAL_STRIDE_M1_L0)
    snax_util.comp_and_assert(TEMPORAL_STRIDE_M1_L0, reg_val)
    reg_val = await snax_util.reg_read(dut, CSR_TEMPORAL_STRIDE_M1_L1)
    snax_util.comp_and_assert(TEMPORAL_STRIDE_M1_L1, reg_val)
        
    reg_val = await snax_util.reg_read(dut, CSR_BASE_PTR_M0)
    snax_util.comp_and_assert(BASE_PTR_M0, reg_val)
    reg_val = await snax_util.reg_read(dut, CSR_BASE_PTR_M1)
    snax_util.comp_and_assert(BASE_PTR_M1, reg_val)
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
    # From here we can continuously stream for ever clock cycle
    # [Note] Chao Fang: We need to modified here
    # await RisingEdge(dut.i_stream_reshuffler_wrapper.acc2stream_data_0_valid)
    # # Necessary for cocotb evaluation step
    # await Timer(Decimal(1), units="ps")

    for i in range(LOOP_COUNT_0 * LOOP_COUNT_1):
        # Extract the data
        # [Note] Chao Fang: In case of traffic jam of the streamer, we need to wait for the valid signal
        if dut.i_stream_reshuffler_wrapper.acc2stream_data_0_valid.value == 0:
            await RisingEdge(dut.i_stream_reshuffler_wrapper.acc2stream_data_0_valid)
            # Necessary for cocotb evaluation step
            await Timer(Decimal(1), units="ps")
        write_stream_0 = int(dut.i_stream_reshuffler_wrapper.acc2stream_data_0_bits.value)
        # cocotb.log.info(f"Iter-{i}: Gold: {narrow_golden_result[i]} Actual: {write_stream_0}")
        # Streamed data should be consistent
        snax_util.comp_and_assert(narrow_golden_result[i], write_stream_0)
        await snax_util.clock_and_wait(dut)

# Main test run
def test_stream_reshuffler(simulator, waves):
    repo_path = os.getcwd()
    tests_path = repo_path + "/tests/cocotb/"

    # Make sure to generate the StreamerTop.sv
    # If it does not exist
    streamer_cfg_file = "streamer_cfg_reshuffler_case3.hjson"
    stream_reshuffler_tb_file = repo_path + "/tests/tb/tb_stream_reshuffler.sv"
    if not os.path.exists(stream_reshuffler_tb_file):
        subprocess.run(["make", stream_reshuffler_tb_file, f"STREAM_CFG_FILENAME={streamer_cfg_file}"])

    streamer_verilog_sources = [
        repo_path + "/rtl/StreamerTop.sv",
        repo_path + "/rtl/streamer_wrapper.sv",
    ]

    # Extract TCDM components
    tcdm_includes, tcdm_verilog_sources = snax_util.extract_tcdm_list()

    # Extract resources for simple mul
    simple_mul_sources = [
        repo_path + "/rtl/simple-reshuffler/simple_reshuffler.sv",
        repo_path + "/rtl/simple-reshuffler/simple_reshuffler_csr.sv",
        repo_path + "/rtl/simple-reshuffler/simple_reshuffler_wrapper.sv",
        repo_path + "/rtl/stream_reshuffler_wrapper.sv",
    ]

    rtl_util_sources = [
        repo_path + "/rtl/rtl-util/csr_mux_demux.sv",
    ]

    tb_verilog_source = [
        stream_reshuffler_tb_file,
    ]

    verilog_sources = (
        tcdm_verilog_sources
        + streamer_verilog_sources
        + rtl_util_sources
        + simple_mul_sources
        + tb_verilog_source
    )

    defines = []
    includes = [] + tcdm_includes

    toplevel = "tb_stream_reshuffler"

    module = "test_stream_reshuffler_case3"

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
