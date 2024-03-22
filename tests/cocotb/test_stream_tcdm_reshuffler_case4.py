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
import math

# Transformation parameters configuration
TRANSFORMATION_PARAMS = {
    "nb_elements": 16,
    "nb_for_loops": 3,
    "strides": [
        {
            "src": 8,
            "dst": 8,
            "bound": 2
        },
        {
            "src": 1,
            "dst": 4,
            "bound": 2
        },
        {
            "src": 2,
            "dst": 1,
            "bound": 4
        },
    ]
}

# Configurable design time parameters
TCDM_REQ_PORTS = 2
NARROW_DATA_WIDTH = 64
WIDE_DATA_WIDTH = 512
TCDM_DEPTH = 64
NR_BANKS = 32
NUM_INPUT = 1
ALIGN_ELEMS = 8

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
CSR_LOOP_COUNT_1 = 1
CSR_LOOP_COUNT_2 = 2
CSR_TEMPORAL_STRIDE_M0_L0 = 3
CSR_TEMPORAL_STRIDE_M0_L1 = 4
CSR_TEMPORAL_STRIDE_M0_L2 = 5
CSR_TEMPORAL_STRIDE_M1_L0 = 6
CSR_TEMPORAL_STRIDE_M1_L1 = 7
CSR_TEMPORAL_STRIDE_M1_L2 = 8
CSR_SPATIAL_STRIDE_M0 = 9
CSR_SPATIAL_STRIDE_M1 = 10
CSR_BASE_PTR_M0 = 11
CSR_BASE_PTR_M1 = 12
CSR_START_STREAMER = 13


@cocotb.test()
async def stream_tcdm_dut(dut):
    # Value configurations you can set
    # For exploration and testing
    # These values go into the respective
    # CSR register addresses above
    LOOP_COUNT_0 = TRANSFORMATION_PARAMS['strides'][-1]['bound']
    LOOP_COUNT_1 = TRANSFORMATION_PARAMS['strides'][-2]['bound']    # Outer-Most Loop
    LOOP_COUNT_2 = TRANSFORMATION_PARAMS['strides'][-3]['bound']    # Outer-Most Loop
    
    # Reader - Mover 0
    # TEMPORAL_STRIDE_M0_L0 = 1
    TEMPORAL_STRIDE_M0_L0 = TRANSFORMATION_PARAMS['strides'][-1]['src'] * ALIGN_ELEMS
    TEMPORAL_STRIDE_M0_L1 = TRANSFORMATION_PARAMS['strides'][-2]['src'] * ALIGN_ELEMS
    TEMPORAL_STRIDE_M0_L2 = TRANSFORMATION_PARAMS['strides'][-3]['src'] * ALIGN_ELEMS
    SPATIAL_STRIDE_M0 = 0       # Not used
    BASE_PTR_M0 = 0

    # Writer - Mover 1
    # TEMPORAL_STRIDE_M1_L0 = 1
    TEMPORAL_STRIDE_M1_L0 = TRANSFORMATION_PARAMS['strides'][-1]['dst'] * ALIGN_ELEMS
    TEMPORAL_STRIDE_M1_L1 = TRANSFORMATION_PARAMS['strides'][-2]['dst'] * ALIGN_ELEMS
    TEMPORAL_STRIDE_M1_L2 = TRANSFORMATION_PARAMS['strides'][-3]['dst'] * ALIGN_ELEMS
    SPATIAL_STRIDE_M1 = 0       # Not used
    OFFSET = 8                  # Relieve bank confilct via a pre-computed offset
    BASE_PTR_M1 = NR_BANKS * math.ceil(LOOP_COUNT_0 * LOOP_COUNT_1 * LOOP_COUNT_2 * ALIGN_ELEMS / NR_BANKS) + OFFSET
    # BASE_PTR_M1 = 128


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
        int(LOOP_COUNT_0 * LOOP_COUNT_1 * LOOP_COUNT_2), MIN_VAL, 255
    )
    cocotb.log.info("Narrow_Golden_List: %s", narrow_golden_list)
    wide_golden_list = snax_util.gen_wide_list(
        narrow_golden_list, NARROW_DATA_WIDTH, WIDE_DATA_WIDTH
    )
    cocotb.log.info("Wide_Golden_List: %s", wide_golden_list)

    narrow_writer_golden_list = snax_util.gen_rand_int_list(
        int(LOOP_COUNT_0 * LOOP_COUNT_1 * LOOP_COUNT_2), MIN_VAL, 255
    )
    cocotb.log.info("Narrow_Writer_Golden_List: %s", narrow_writer_golden_list)
    wide_writer_golden_list = snax_util.gen_wide_list(
        narrow_writer_golden_list, NARROW_DATA_WIDTH, 256
    )
    cocotb.log.info("Wide_Writer_Golden_List: %s", wide_writer_golden_list)

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
    await snax_util.reg_write(dut, CSR_LOOP_COUNT_1, LOOP_COUNT_1)
    await snax_util.reg_write(dut, CSR_LOOP_COUNT_2, LOOP_COUNT_2)

    # Set temporal strides
    await snax_util.reg_write(dut, CSR_TEMPORAL_STRIDE_M0_L0, TEMPORAL_STRIDE_M0_L0)
    await snax_util.reg_write(dut, CSR_TEMPORAL_STRIDE_M0_L1, TEMPORAL_STRIDE_M0_L1)
    await snax_util.reg_write(dut, CSR_TEMPORAL_STRIDE_M0_L2, TEMPORAL_STRIDE_M0_L2)
    await snax_util.reg_write(dut, CSR_TEMPORAL_STRIDE_M1_L0, TEMPORAL_STRIDE_M1_L0)
    await snax_util.reg_write(dut, CSR_TEMPORAL_STRIDE_M1_L1, TEMPORAL_STRIDE_M1_L1)
    await snax_util.reg_write(dut, CSR_TEMPORAL_STRIDE_M1_L2, TEMPORAL_STRIDE_M1_L2)

    # Set base pointers
    await snax_util.reg_write(dut, CSR_BASE_PTR_M0, BASE_PTR_M0)
    await snax_util.reg_write(dut, CSR_BASE_PTR_M1, BASE_PTR_M1)

    # Clear driver signals
    # So that we don't have stuck valid
    await snax_util.reg_clr(dut)

    # Read and verify the contents
    # of the previously set registers
    reg_val = await snax_util.reg_read(dut, CSR_LOOP_COUNT_0)
    snax_util.comp_and_assert(LOOP_COUNT_0, reg_val)
    reg_val = await snax_util.reg_read(dut, CSR_LOOP_COUNT_1)
    snax_util.comp_and_assert(LOOP_COUNT_1, reg_val)
    reg_val = await snax_util.reg_read(dut, CSR_LOOP_COUNT_2)
    snax_util.comp_and_assert(LOOP_COUNT_2, reg_val)
    
    reg_val = await snax_util.reg_read(dut, CSR_TEMPORAL_STRIDE_M0_L0)
    snax_util.comp_and_assert(TEMPORAL_STRIDE_M0_L0, reg_val)
    reg_val = await snax_util.reg_read(dut, CSR_TEMPORAL_STRIDE_M0_L1)
    snax_util.comp_and_assert(TEMPORAL_STRIDE_M0_L1, reg_val)
    reg_val = await snax_util.reg_read(dut, CSR_TEMPORAL_STRIDE_M0_L2)
    snax_util.comp_and_assert(TEMPORAL_STRIDE_M0_L2, reg_val)
    reg_val = await snax_util.reg_read(dut, CSR_TEMPORAL_STRIDE_M1_L0)
    snax_util.comp_and_assert(TEMPORAL_STRIDE_M1_L0, reg_val)
    reg_val = await snax_util.reg_read(dut, CSR_TEMPORAL_STRIDE_M1_L1)
    snax_util.comp_and_assert(TEMPORAL_STRIDE_M1_L1, reg_val)
    reg_val = await snax_util.reg_read(dut, CSR_TEMPORAL_STRIDE_M1_L2)
    snax_util.comp_and_assert(TEMPORAL_STRIDE_M1_L2, reg_val)
    
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
    await snax_util.reg_write(dut, CSR_START_STREAMER, 1)
    await snax_util.reg_clr(dut)

    # Wait for the rising edge of the valid
    # From there we can continuously stream for ever clock cycle
    await RisingEdge(dut.stream2acc_data_0_valid_o)

    # Necessary for cocotb evaluation step
    await Timer(Decimal(1), units="ps")

    # for i in range(LOOP_COUNT_0 * LOOP_COUNT_1):
    #     # Extract the data
    #     read_stream_0 = int(dut.stream2acc_data_0_bits_o.value)

    #     cocotb.log.info("Run the streamer and check if data are correct")
    #     cocotb.log.info(">> Gold_list:     %s", narrow_golden_list[i])
    #     cocotb.log.info(">> Read_Stream_0: %s", read_stream_0)
    #     snax_util.comp_and_assert(narrow_golden_list[i], read_stream_0)
    #     await snax_util.clock_and_wait(dut)

    for i in range(LOOP_COUNT_2):
        for j in range(LOOP_COUNT_1):
            for k in range(LOOP_COUNT_0):
                read_stream_0 = int(dut.stream2acc_data_0_bits_o.value)
                cocotb.log.info("[Read Test] Run the streamer and check if data are correct")
                cocotb.log.info(">> Gold_list:     %s", narrow_golden_list[(i * TEMPORAL_STRIDE_M0_L2 + j * TEMPORAL_STRIDE_M0_L1 + k * TEMPORAL_STRIDE_M0_L0) // ALIGN_ELEMS])
                cocotb.log.info(">> Read_Stream_0: %s", read_stream_0)
                snax_util.comp_and_assert(narrow_golden_list[(i * TEMPORAL_STRIDE_M0_L2 + j * TEMPORAL_STRIDE_M0_L1 + k * TEMPORAL_STRIDE_M0_L0) // ALIGN_ELEMS], read_stream_0)
                await snax_util.clock_and_wait(dut)            

    # In this test the writer is streamed continuosly
    # then we read through one of the reader ports
    cocotb.log.info("Writer-reader test")

    # Allow the writer to write data unto the streamer
    # writer_len = len(wide_writer_golden_list)
    for i in range(LOOP_COUNT_0 * LOOP_COUNT_1 * LOOP_COUNT_2):
        dut.acc2stream_data_0_bits_i.value = narrow_writer_golden_list[i]
        dut.acc2stream_data_0_valid_i.value = 1
        await snax_util.clock_and_wait(dut)

    # Clear step to avoid overwriting
    dut.acc2stream_data_0_bits_i.value = 0
    dut.acc2stream_data_0_valid_i.value = 0
    await snax_util.clock_and_wait(dut)

    # Switch off 2nd reader since the
    # 1st reader will be the only one used
    # dut.stream2acc_data_1_ready_i.value = 0
    # await snax_util.clock_and_wait(dut)

    # Start streamer again
    # And we read the ptr_m1 since we just write data here
    await snax_util.reg_write(dut, CSR_LOOP_COUNT_0, 1)
    await snax_util.reg_write(dut, CSR_LOOP_COUNT_1, 1)
    await snax_util.reg_write(dut, CSR_LOOP_COUNT_2, LOOP_COUNT_0 * LOOP_COUNT_1 * LOOP_COUNT_2)
    await snax_util.reg_write(dut, CSR_TEMPORAL_STRIDE_M0_L0, 1 * ALIGN_ELEMS)
    await snax_util.reg_write(dut, CSR_TEMPORAL_STRIDE_M0_L1, 1 * ALIGN_ELEMS)
    await snax_util.reg_write(dut, CSR_TEMPORAL_STRIDE_M0_L2, 1 * ALIGN_ELEMS)
    await snax_util.reg_write(dut, CSR_BASE_PTR_M0, BASE_PTR_M1)
    await snax_util.reg_clr(dut)
    
    # await snax_util.reg_clr(dut)
    
    await snax_util.reg_write(dut, CSR_START_STREAMER, 1)
    await snax_util.reg_clr(dut)
    
    cocotb.log.info("Read written data test")

    # Wait for the rising edge of the valid
    # From here we can continuously stream for ever clock cycle
    await RisingEdge(dut.stream2acc_data_0_valid_o)
    # Necessary for cocotb evaluation step
    await Timer(Decimal(1), units="ps")

    for i in range(LOOP_COUNT_2):
        for j in range(LOOP_COUNT_1):
            for k in range(LOOP_COUNT_0):
                # Extract the data
                read_stream_0 = int(dut.stream2acc_data_0_bits_o.value)
                cocotb.log.info("[Write Test] Run the streamer and check if data are correct")
                cocotb.log.info(">> Gold_list:     %s", narrow_writer_golden_list[(i * TEMPORAL_STRIDE_M1_L2 + j * TEMPORAL_STRIDE_M1_L1 + k * TEMPORAL_STRIDE_M1_L0) // ALIGN_ELEMS])
                cocotb.log.info(">> Read_Stream_0: %s", read_stream_0)
                # Streamed data should be consistent
                snax_util.comp_and_assert(narrow_writer_golden_list[(i * TEMPORAL_STRIDE_M1_L2 + j * TEMPORAL_STRIDE_M1_L1 + k * TEMPORAL_STRIDE_M1_L0) // ALIGN_ELEMS], read_stream_0)
                await snax_util.clock_and_wait(dut)


# Main test run
def test_stream_tcdm(simulator, waves):
    repo_path = os.getcwd()
    tests_path = repo_path + "/tests/cocotb/"

    # Make sure to generate the StreamerTop.sv
    # If it does not exist
    streamer_cfg_file = "streamer_cfg_reshuffler_case4.hjson"
    stream_tcdm_tb_file = repo_path + "/tests/tb/tb_stream_tcdm_top.sv"
    if not os.path.exists(stream_tcdm_tb_file):
        print(f"Generating Chisel RTLs: {stream_tcdm_tb_file}.sv")
        subprocess.run(["make", stream_tcdm_tb_file, f"STREAM_CFG_FILENAME={streamer_cfg_file}"])

    streamer_verilog_sources = [
        repo_path + "/rtl/StreamerTop.sv",
        repo_path + "/rtl/streamer_wrapper.sv",
    ]

    # Extract TCDM components
    tcdm_includes, tcdm_verilog_sources = snax_util.extract_tcdm_list()

    tb_verilog_source = [
        stream_tcdm_tb_file,
    ]

    verilog_sources = (
        tcdm_verilog_sources + streamer_verilog_sources + tb_verilog_source
    )

    defines = []
    includes = [] + tcdm_includes

    toplevel = "tb_stream_tcdm_top"

    module = "test_stream_tcdm_reshuffler_case4"

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
