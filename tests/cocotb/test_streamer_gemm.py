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
import numpy as np
from cocotb.clock import Clock
from cocotb_test.simulator import run
import snax_util
import os
import subprocess


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

CSR_LOOP_K = 0
CSR_LOOP_N = 1
CSR_LOOP_M = 2

CSR_TEMP_STRIDE_A_0 = 3
CSR_TEMP_STRIDE_A_1 = 4
CSR_TEMP_STRIDE_A_2 = 5
CSR_TEMP_STRIDE_B_0 = 6
CSR_TEMP_STRIDE_B_1 = 7
CSR_TEMP_STRIDE_B_2 = 8
CSR_TEMP_STRIDE_C_0 = 9
CSR_TEMP_STRIDE_C_1 = 10
CSR_TEMP_STRIDE_C_2 = 11

CSR_SPAT_STRIDE_A_0 = 12
CSR_SPAT_STRIDE_A_1 = 13
CSR_SPAT_STRIDE_B_0 = 14
CSR_SPAT_STRIDE_B_1 = 15
CSR_SPAT_STRIDE_C_0 = 16
CSR_SPAT_STRIDE_C_1 = 17

CSR_BASE_A = 18
CSR_BASE_B = 19
CSR_BASE_C = 20

CSR_START_STREAMER = 21

CSR_GEMM_K = 22
CSR_GEMM_M = 23
CSR_GEMM_N = 24

CSR_GEMM_SUBS = 25
CSR_GEMM_START = 26


@cocotb.test()
async def stream_alu_dut(dut):
    # Start clock
    clock = Clock(dut.clk_i, 10, units="ns")
    cocotb.start_soon(clock.start())
    await snax_util.clock_and_wait(dut)

    # Reset dut
    await snax_util.reset_dut(dut)

    # Let simulation time run
    for i in range(10):
        await snax_util.clock_and_wait(dut)

    # generate data
    M = 16
    N = 16
    K = 16

    low_bound = 0
    high_bound = 127

    np.random.seed(0)

    A = np.random.randint(low_bound, high_bound, size=[M, K], dtype=np.dtype("int8"))
    B = np.random.randint(low_bound, high_bound, size=[K, N], dtype=np.dtype("int8"))
    # Make sure the product is possible!
    assert A.shape[1] == B.shape[0]
    C_golden = np.matmul(A.astype(np.dtype("int32")), B.astype(np.dtype("int32")))

    # transpose B
    B = np.transpose(B)

    # Flatten the arrays
    A = A.flatten().tolist()
    B = B.flatten().tolist()
    C_golden = C_golden.flatten().tolist()

    # pack everything into a list of 64 bytes = wide tcdm
    A = snax_util.gen_wide_list(A, 8, 512)
    B = snax_util.gen_wide_list(B, 8, 512)
    C_golden = snax_util.gen_wide_list(C_golden, 32, 512)

    inputs = [*A, *B]

    cocotb.log.info("Preload data with DMA control")

    for i in range(len(inputs)):
        await snax_util.wide_tcdm_write(dut, i * WIDE_BANK_INCREMENT, inputs[i])

    await snax_util.wide_tcdm_clr(dut)

    cocotb.log.info("Setting up of CSR registers")

    K_param = round(K // 8)
    N_param = round(N // 8)
    M_param = round(M // 8)

    await snax_util.reg_write(dut, CSR_LOOP_K, K_param)
    await snax_util.reg_write(dut, CSR_LOOP_N, N_param)
    await snax_util.reg_write(dut, CSR_LOOP_M, M_param)

    await snax_util.reg_write(dut, CSR_TEMP_STRIDE_A_0, 8)
    await snax_util.reg_write(dut, CSR_TEMP_STRIDE_A_1, 0)
    await snax_util.reg_write(dut, CSR_TEMP_STRIDE_A_2, 64 * K_param)
    await snax_util.reg_write(dut, CSR_TEMP_STRIDE_B_0, 8)
    await snax_util.reg_write(dut, CSR_TEMP_STRIDE_B_1, 64 * K_param)
    await snax_util.reg_write(dut, CSR_TEMP_STRIDE_B_2, 0)
    await snax_util.reg_write(dut, CSR_TEMP_STRIDE_C_0, 0)
    await snax_util.reg_write(dut, CSR_TEMP_STRIDE_C_1, 32)
    await snax_util.reg_write(dut, CSR_TEMP_STRIDE_C_2, 256 * N_param)

    await snax_util.reg_write(dut, CSR_SPAT_STRIDE_A_0, 1)
    await snax_util.reg_write(dut, CSR_SPAT_STRIDE_A_1, 16)
    await snax_util.reg_write(dut, CSR_SPAT_STRIDE_B_0, 1)
    await snax_util.reg_write(dut, CSR_SPAT_STRIDE_B_1, 16)
    await snax_util.reg_write(dut, CSR_SPAT_STRIDE_C_0, 4)
    await snax_util.reg_write(dut, CSR_SPAT_STRIDE_C_1, 64)

    A_offset = 0
    await snax_util.reg_write(dut, CSR_BASE_A, A_offset)
    B_offset = A_offset + 64 * K_param * M_param
    await snax_util.reg_write(dut, CSR_BASE_B, B_offset)
    C_offset = B_offset + 64 * N_param * K_param
    await snax_util.reg_write(dut, CSR_BASE_C, C_offset)

    await snax_util.reg_write(dut, CSR_START_STREAMER, 1)

    await snax_util.reg_write(dut, CSR_GEMM_K, K_param)
    await snax_util.reg_write(dut, CSR_GEMM_M, M_param)
    await snax_util.reg_write(dut, CSR_GEMM_N, N_param)

    await snax_util.reg_write(dut, CSR_GEMM_SUBS, 0)
    await snax_util.reg_write(dut, CSR_GEMM_START, 1)

    await snax_util.reg_clr(dut)

    # wait for finish
    await snax_util.reg_write(dut, CSR_GEMM_START, 0)
    await snax_util.reg_write(dut, CSR_START_STREAMER, 0)
    cocotb.log.info("GEMM Operation Finished")
    await snax_util.reg_clr(dut)

    # Read the result and check
    for i in range(len(C_golden)):
        tcdm_wide_val = await snax_util.wide_tcdm_read(
            dut, C_offset + i * WIDE_BANK_INCREMENT
        )
        snax_util.comp_and_assert(C_golden[i], tcdm_wide_val)


# Main test run
def test_streamer_gemm(simulator, waves):
    repo_path = os.getcwd()
    tests_path = repo_path + "/tests/cocotb/"

    # Make sure to generate the testbench
    # And all necessary files to make it work
    stream_gemm_tb_file = repo_path + "/tests/tb/tb_streamer_gemm.sv"
    if not os.path.exists(stream_gemm_tb_file):
        subprocess.run(["mkdir", "rtl/streamer-gemm"])
        subprocess.run(["make", stream_gemm_tb_file])

    # Extract TCDM components
    tcdm_includes, tcdm_verilog_sources = snax_util.extract_tcdm_list()

    # Extract resources for simple mul
    streamer_gemm_sources = [
        repo_path + "/rtl/streamer-gemm/BareBlockGemmTop.sv",
        repo_path + "/rtl/streamer-gemm/streamer_for_gemm_wrapper.sv",
        repo_path + "/rtl/streamer-gemm/streamer_gemm_wrapper.sv",
        repo_path + "/rtl/streamer-gemm/StreamerTop.sv",
    ]

    rtl_util_sources = [
        repo_path + "/rtl/rtl-util/csr_mux_demux.sv",
    ]

    tb_verilog_source = [
        stream_gemm_tb_file,
    ]

    verilog_sources = (
        tcdm_verilog_sources
        + rtl_util_sources
        + streamer_gemm_sources
        + tb_verilog_source
    )

    defines = []
    includes = [] + tcdm_includes

    toplevel = "tb_streamer_gemm"

    module = "test_streamer_gemm"

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
