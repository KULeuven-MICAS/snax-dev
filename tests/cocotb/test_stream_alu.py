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

from tests.cocotb.test_tcdm_subsys import MAX_VAL


# Configurable testing parameters
# In the default value below, the number
# of tests fills the entire memory
NARROW_DATA_WIDTH = 64
WIDE_DATA_WIDTH = 512
TCDM_DEPTH = 64
NR_BANKS = 32
SPATPAR = 4
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

CSR_ALU_CONFIG = 0
CSR_ALU_GPP_1 = 1
CSR_ALU_GPP_2 = 2
CSR_ALU_GPP_3 = 3
CSR_ALU_GPP_4 = 4
CSR_ALU_GPP_5 = 5
CSR_ALU_GPP_6 = 6
CSR_ALU_GPP_7 = 7

# This STREAMER_OFFSET is the offset
# For the address registers
STREAMER_OFFSET = 8

CSR_LOOP_COUNT_0 = 0 + STREAMER_OFFSET
CSR_TEMPORAL_STRIDE_0 = 1  + STREAMER_OFFSET
CSR_TEMPORAL_STRIDE_1 = 2  + STREAMER_OFFSET
CSR_TEMPORAL_STRIDE_2 = 3 + STREAMER_OFFSET
CSR_SPATIAL_STRIDE_0 = 4 + STREAMER_OFFSET
CSR_SPATIAL_STRIDE_1 = 5 + STREAMER_OFFSET
CSR_SPATIAL_STRIDE_2 = 6 + STREAMER_OFFSET
CSR_BASE_PTR_0 = 7 + STREAMER_OFFSET
CSR_BASE_PTR_1 = 8 + STREAMER_OFFSET
CSR_BASE_PTR_2 = 9 + STREAMER_OFFSET
CSR_START_STREAMER = 10 + STREAMER_OFFSET


@cocotb.test()
async def stream_alu_dut(dut):
    # Value configurations you can set
    # For exploration and testing
    # These values go into the respective
    # CSR register addresses above

    # ACLU_CONFIG has the following:
    # 0 - addition
    # 1 - subtraction
    # 2 - multiplication
    # 3 - XOR
    ALU_CONFIG = 1
    ALU_GPP_1 = 123
    ALU_GPP_2 = 456
    ALU_GPP_3 = 789
    ALU_GPP_4 = 910
    ALU_GPP_5 = 101
    ALU_GPP_6 = 121
    ALU_GPP_7 = 368
    
    # These ones go into the 
    # streamer registers
    LOOP_COUNT_0 = 100
    TEMPORAL_STRIDE_0 = 64
    TEMPORAL_STRIDE_1 = 64
    TEMPORAL_STRIDE_2 = 64
    SPATIAL_STRIDE_0 = 8
    SPATIAL_STRIDE_1 = 8
    SPATIAL_STRIDE_2 = 8
    BASE_PTR_0 = 0
    BASE_PTR_1 = 32
    BASE_PTR_2 = 64

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
        int(LOOP_COUNT_0 * (WIDE_DATA_WIDTH / NARROW_DATA_WIDTH)), MIN_VAL, MAX_VAL
    )
    wide_golden_list = snax_util.gen_wide_list(
        narrow_golden_list, NARROW_DATA_WIDTH, WIDE_DATA_WIDTH
    )

    # Precompute golden results
    narrow_golden_result = []

    for i in range(LOOP_COUNT_0):
        for j in range(SPATPAR):
            # Output changes per ALU_CONFIG
            if( ALU_CONFIG == 1 ):

                temp_res = (
                    narrow_golden_list[i * SPATPAR * 2 + j]
                    - narrow_golden_list[(2 * i + 1) * SPATPAR + j]
                )
            elif ( ALU_CONFIG == 2):

                temp_res = (
                    narrow_golden_list[i * SPATPAR * 2 + j]
                    * narrow_golden_list[(2 * i + 1) * SPATPAR + j]
                )
            elif ( ALU_CONFIG == 3):
                temp_res = (
                    narrow_golden_list[i * SPATPAR * 2 + j]
                    ^ narrow_golden_list[(2 * i + 1) * SPATPAR + j]
                )
            else:
                temp_res = (
                    narrow_golden_list[i * SPATPAR * 2 + j]
                    + narrow_golden_list[(2 * i + 1) * SPATPAR + j]
                )
            
            temp_res = temp_res & (MAX_NARROW_VAL - 1)
            narrow_golden_result.append(temp_res)

    wide_golden_result = snax_util.gen_wide_list(
        narrow_golden_result, NARROW_DATA_WIDTH, (NARROW_DATA_WIDTH * SPATPAR)
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

    # Setting of ALU accelerator registers
    # Only CSR_ALU_CONFIG affects the accelerator
    # The other registers are for read/write checks only
    await snax_util.reg_write(dut, CSR_ALU_CONFIG, ALU_CONFIG)
    await snax_util.reg_write(dut, CSR_ALU_GPP_1, ALU_GPP_1)
    await snax_util.reg_write(dut, CSR_ALU_GPP_2, ALU_GPP_2)
    await snax_util.reg_write(dut, CSR_ALU_GPP_3, ALU_GPP_3)
    await snax_util.reg_write(dut, CSR_ALU_GPP_4, ALU_GPP_4)
    await snax_util.reg_write(dut, CSR_ALU_GPP_5, ALU_GPP_5)
    await snax_util.reg_write(dut, CSR_ALU_GPP_6, ALU_GPP_6)
    await snax_util.reg_write(dut, CSR_ALU_GPP_7, ALU_GPP_7)

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

    # Check ALU registers first
    reg_val = await snax_util.reg_read(dut, CSR_ALU_CONFIG)
    snax_util.comp_and_assert(ALU_CONFIG, reg_val)
    reg_val = await snax_util.reg_read(dut, CSR_ALU_GPP_1)
    snax_util.comp_and_assert(ALU_GPP_1, reg_val)
    reg_val = await snax_util.reg_read(dut, CSR_ALU_GPP_2)
    snax_util.comp_and_assert(ALU_GPP_2, reg_val)
    reg_val = await snax_util.reg_read(dut, CSR_ALU_GPP_3)
    snax_util.comp_and_assert(ALU_GPP_3, reg_val)
    reg_val = await snax_util.reg_read(dut, CSR_ALU_GPP_4)
    snax_util.comp_and_assert(ALU_GPP_4, reg_val)
    reg_val = await snax_util.reg_read(dut, CSR_ALU_GPP_5)
    snax_util.comp_and_assert(ALU_GPP_5, reg_val)
    reg_val = await snax_util.reg_read(dut, CSR_ALU_GPP_6)
    snax_util.comp_and_assert(ALU_GPP_6, reg_val)
    reg_val = await snax_util.reg_read(dut, CSR_ALU_GPP_7)
    snax_util.comp_and_assert(ALU_GPP_7, reg_val)

    # Check Streamer registers
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
    # From here we can continuously stream for ever clock cycle
    await RisingEdge(dut.i_stream_alu_wrapper.acc2stream_data_0_valid)
    # Necessary for cocotb evaluation step
    await Timer(Decimal(1), units="ps")

    for i in range(LOOP_COUNT_0):
        # Extract the data
        write_stream_0 = int(dut.i_stream_alu_wrapper.acc2stream_data_0_bits.value)

        # Streamed data should be consistent
        snax_util.comp_and_assert(wide_golden_result[i], write_stream_0)
        await snax_util.clock_and_wait(dut)


# Main test run
def test_stream_alu(simulator, waves):
    repo_path = os.getcwd()
    tests_path = repo_path + "/tests/cocotb/"

    # Make sure to generate the StreamerTop.sv
    # If it does not exist
    stream_alu_tb_file = repo_path + "/tests/tb/tb_stream_alu.sv"
    if not os.path.exists(stream_alu_tb_file):
        subprocess.run(["make", stream_alu_tb_file])

    streamer_verilog_sources = [
        repo_path + "/rtl/StreamerTop.sv",
        repo_path + "/rtl/streamer_wrapper.sv",
    ]

    # Extract TCDM components
    tcdm_includes, tcdm_verilog_sources = snax_util.extract_tcdm_list()

    # Extract resources for simple mul
    simple_mul_sources = [
        repo_path + "/rtl/simple-alu/simple_alu.sv",
        repo_path + "/rtl/simple-alu/simple_alu_csr.sv",
        repo_path + "/rtl/simple-alu/simple_alu_wrapper.sv",
        repo_path + "/rtl/stream_alu_wrapper.sv",
    ]

    rtl_util_sources = [
        repo_path + "/rtl/rtl-util/csr_mux_demux.sv",
    ]

    tb_verilog_source = [
        stream_alu_tb_file,
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

    toplevel = "tb_stream_alu"

    module = "test_stream_alu"

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
