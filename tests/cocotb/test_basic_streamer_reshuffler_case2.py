# ---------------------------------
# Copyright 2024 KULeuven
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
# Author: Chao Fang (chao.fang@esat.kuleuven.be)
#
# Description:
# This tests the basic configuration of the streamer
# found in ./util/cfg/streamer_cfg_reshuffler_case2.hjson
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
import snax_util
import os
import subprocess
import math

# Transformation parameters configuration
TRANSFORMATION_PARAMS = {
    "nb_elements": 16,
    "nb_for_loops": 2,
    "strides": [
        {
            "src": 1,
            "dst": 8,
            "bound": 2
        },
        {
            "src": 2,
            "dst": 1,
            "bound": 8
        },
    ]
}

# Configurable design time parameters
ALIGN_ELEMS = 8
TCDM_REQ_PORTS = 2
NUM_BANKS = 32

# DON'T TOUCH ME PLEASE
# CSR parameters from the default
# Configuration found under util/cfg/streamer_cfg.hjson
# Also some pre-computed that are fixed
CSR_LOOP_COUNT_0 = 0
CSR_LOOP_COUNT_1 = 1
CSR_TEMPORAL_STRIDE_M0_L0 = 2
CSR_TEMPORAL_STRIDE_M0_L1 = 3
CSR_TEMPORAL_STRIDE_M1_L0 = 4
CSR_TEMPORAL_STRIDE_M1_L1 = 5
CSR_SPATIAL_STRIDE_M0 = 6
CSR_SPATIAL_STRIDE_M1 = 7
CSR_BASE_PTR_M0 = 8
CSR_BASE_PTR_M1 = 9
CSR_START_STREAMER = 10

# Value configurations you can set
# For exploration and testing
# These values go into the respective
# CSR register addresses above

# LOOP_COUNT_0 = 8    # Inner-Most Loop
# LOOP_COUNT_1 = 2    # Outer-Most Loop
LOOP_COUNT_0 = TRANSFORMATION_PARAMS['strides'][-1]['bound']    # Inner-Most Loop
LOOP_COUNT_1 = TRANSFORMATION_PARAMS['strides'][-2]['bound']    # Outer-Most Loop

# Reader - Mover 0
# TEMPORAL_STRIDE_M0_L0 = 2
# TEMPORAL_STRIDE_M0_L1 = 1
TEMPORAL_STRIDE_M0_L0 = TRANSFORMATION_PARAMS['strides'][-1]['src'] * ALIGN_ELEMS
TEMPORAL_STRIDE_M0_L1 = TRANSFORMATION_PARAMS['strides'][-2]['src'] * ALIGN_ELEMS
SPATIAL_STRIDE_M0 = 0
BASE_PTR_M0 = 0

# Writer - Mover 1
# TEMPORAL_STRIDE_M1_L0 = 1
# TEMPORAL_STRIDE_M1_L1 = 8
TEMPORAL_STRIDE_M1_L0 = TRANSFORMATION_PARAMS['strides'][-1]['dst'] * ALIGN_ELEMS
TEMPORAL_STRIDE_M1_L1 = TRANSFORMATION_PARAMS['strides'][-2]['dst'] * ALIGN_ELEMS
SPATIAL_STRIDE_M1 = 0       # Not used
OFFSET = 8                  # Relieve bank confilct via a pre-computed offset
BASE_PTR_M1 = NUM_BANKS * math.ceil(LOOP_COUNT_0 * LOOP_COUNT_1 * ALIGN_ELEMS/ NUM_BANKS) + OFFSET


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

    # Clear driver signals
    # So that we don't have stuck valid
    await snax_util.reg_clr(dut)

    cocotb.log.info("Run the streamer and check if addresses are correct")

    # Do a run of the streamer
    # We can write anything on this address
    # And it will automatically run the streamer
    await snax_util.reg_write(dut, CSR_START_STREAMER, 1)

    # First generate the golden answer list
    # golden_list = gen_basic_stream_gold_list()
    gold_input_data = list(range(TRANSFORMATION_PARAMS["nb_elements"]))
    gold_output_data = snax_util.transform_data(gold_input_data, TRANSFORMATION_PARAMS)

    # Cycle for each TCDM request ports
    # Check the temporal loop
    for i in range(LOOP_COUNT_1):
        for j in range(LOOP_COUNT_0):
            iter_count = i * LOOP_COUNT_0 + j
            rd_addr_read_val = int(dut.tcdm_req_addr_o[0].value) 
            cocotb.log.info(f"Iter-{iter_count}, Reading address from TCDM is {rd_addr_read_val}")
            # snax_util.comp_and_assert(golden_list[i][j], rd_addr_read_val)
            wr_addr_read_val = int(dut.tcdm_req_addr_o[1].value) 
            cocotb.log.info(f"Iter-{iter_count}, Writing address to TCDM is {wr_addr_read_val}")
            # snax_util.comp_and_assert(golden_list[i][j + LOOP_COUNT_1], wr_addr_read_val)
            snax_util.comp_and_assert(gold_input_data[(rd_addr_read_val - BASE_PTR_M0) // ALIGN_ELEMS], 
                                      gold_output_data[(wr_addr_read_val - BASE_PTR_M1) // ALIGN_ELEMS])
            await snax_util.clock_and_wait(dut)


# Main test run
def test_basic_streamer_reshuffler(simulator, waves):
    repo_path = os.getcwd()
    tests_path = repo_path + "/tests/cocotb/"

    # Make sure to generate the StreamerTop.sv
    # If it does not exist
    streamer_cfg_file = "streamer_cfg_reshuffler_case2.hjson"
    streamer_top_file = repo_path + "/tests/tb/tb_streamer_top.sv"
    if not os.path.exists(streamer_top_file):
        print(f"Generating Chisel RTLs: {streamer_top_file}.sv")
        subprocess.run(["make", streamer_top_file, f"STREAM_CFG_FILENAME={streamer_cfg_file}"])

    verilog_sources = [
        repo_path + "/rtl/StreamerTop.sv",
        repo_path + "/rtl/streamer_wrapper.sv",
        repo_path + "/tests/tb/tb_streamer_top.sv",
    ]
    defines = []
    includes = []

    toplevel = "tb_streamer_top"

    module = "test_basic_streamer_reshuffler_case2"

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
