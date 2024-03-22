# ---------------------------------
# Copyright 2024 KULeuven
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
# Author: Xiaoling Yi <xiaoling.yi@esat.kuleuven.be>
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

CSR_LOOP_0 = 0
CSR_LOOP_1 = 1

CSR_TEMP_STRIDE_IN_0 = 2
CSR_TEMP_STRIDE_IN_1 = 3
CSR_TEMP_STRIDE_OUT_0 = 4
CSR_TEMP_STRIDE_OUT_1 = 5

CSR_SPAT_STRIDE_IN_0 = 6
CSR_SPAT_STRIDE_IN_1 = 7
CSR_SPAT_STRIDE_OUT_0 = 8
CSR_SPAT_STRIDE_OUT_1 = 9

CSR_BASE_IN = 10
CSR_BASE_OUT = 11

CSR_START_STREAMER = 12

CSR_SIMD_CSR0 = 13
CSR_SIMD_CSR1 = 14
CSR_SIMD_CSR2 = 15

CSR_SIMD_LOOP = 16

CSR_SIMD_START = 17


# Golden model for postprocessing
def postprocessing_simd_golden_model(
    data_in,
    input_zp_i,
    output_zp_i,
    shift_i,
    max_int_i,
    min_int_i,
    double_round_i,
    multiplier_i,
):
    out = np.zeros(data_in.shape, dtype=np.int8)
    for i in range(len(data_in)):
        var = data_in[i] - input_zp_i
        # avoid overflow
        var = np.int64(var) * np.int64(multiplier_i)
        var = np.int32(var >> (shift_i - 1))
        if double_round_i:
            if var >= 0:
                var = var + 1
            else:
                var = var - 1
        var = var >> 1
        var = var + output_zp_i
        if var > max_int_i:
            var = max_int_i
        if var < min_int_i:
            var = min_int_i
        out[i] = var & 0xFF
    return out


def gen_csr0_config(input_zp_i, output_zp_i, shift_i, max_int_i):
    # encode the configuration into a single 32-bit integer
    return int(
        ((max_int_i & 0xFF) << 24)
        | ((shift_i & 0xFF) << 16)
        | ((output_zp_i & 0xFF) << 8)
        | (input_zp_i & 0xFF)
    )


def gen_csr1_config(min_int_i, double_round_i):
    # encode the configuration into a single 32-bit integer
    return int(((double_round_i & 0xFF) << 8) | (min_int_i & 0xFF))


@cocotb.test()
async def stream_simd_dut(dut):
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

    MIN_int8 = -128
    MAX_int8 = 127

    MIN_int32 = -(2**31)
    MAX_int32 = 2**31 - 1

    # Generating random constant values
    input_zp_i = np.random.randint(MIN_int8, MAX_int8)
    output_zp_i = np.random.randint(MIN_int8, MAX_int8)
    shift_i = np.random.randint(0, 63)  # values between 0-63
    max_int_i = MAX_int8
    min_int_i = MIN_int8
    double_round_i = np.random.randint(0, 1)
    multiplier_i = np.random.randint(MIN_int32, MAX_int32, dtype=np.dtype("int32"))

    Tloop0 = 1
    Tloop1 = 1

    # hardware fiex parameter
    veclen = 64

    length_in = Tloop0 * Tloop1 * veclen

    np.random.seed(0)

    data_in = np.random.randint(MIN_int32, MAX_int32, length_in)

    # Make sure the product is possible!
    data_out_golden = postprocessing_simd_golden_model(
        data_in,
        input_zp_i,
        output_zp_i,
        shift_i,
        max_int_i,
        min_int_i,
        double_round_i,
        multiplier_i,
    )

    # Flatten the arrays
    data_in = data_in.flatten().tolist()
    data_out_golden = data_out_golden.flatten().tolist()

    # pack everything into a list of 64 bytes = wide tcdm
    data_in = snax_util.gen_wide_list(data_in, 32, 512)
    data_out_golden = snax_util.gen_wide_list(data_out_golden, 8, 512)

    inputs = [*data_in]

    cocotb.log.info("Preload data with DMA control")

    for i in range(len(inputs)):
        await snax_util.wide_tcdm_write(dut, i * WIDE_BANK_INCREMENT, inputs[i])

    await snax_util.wide_tcdm_clr(dut)

    cocotb.log.info("Setting up of CSR registers")

    await snax_util.reg_write(dut, CSR_LOOP_0, Tloop0)
    await snax_util.reg_write(dut, CSR_LOOP_1, Tloop1)

    await snax_util.reg_write(dut, CSR_TEMP_STRIDE_IN_0, 256)
    await snax_util.reg_write(dut, CSR_TEMP_STRIDE_IN_1, 256 * Tloop0)
    await snax_util.reg_write(dut, CSR_TEMP_STRIDE_OUT_0, 64)
    await snax_util.reg_write(dut, CSR_TEMP_STRIDE_OUT_1, 64 * Tloop0)

    await snax_util.reg_write(dut, CSR_SPAT_STRIDE_IN_0, 4)
    await snax_util.reg_write(dut, CSR_SPAT_STRIDE_IN_1, 32)
    await snax_util.reg_write(dut, CSR_SPAT_STRIDE_OUT_0, 1)
    await snax_util.reg_write(dut, CSR_SPAT_STRIDE_OUT_1, 8)

    IN_offset = 0
    await snax_util.reg_write(dut, CSR_BASE_IN, IN_offset)
    OUT_offset = IN_offset + veclen * Tloop0 * Tloop1 * 4
    await snax_util.reg_write(dut, CSR_BASE_OUT, OUT_offset)

    await snax_util.reg_write(dut, CSR_START_STREAMER, 1)

    CSR_0 = gen_csr0_config(input_zp_i, output_zp_i, shift_i, max_int_i)
    CSR_1 = gen_csr1_config(min_int_i, double_round_i)
    await snax_util.reg_write(dut, CSR_SIMD_CSR0, CSR_0)
    await snax_util.reg_write(dut, CSR_SIMD_CSR1, CSR_1)
    await snax_util.reg_write(dut, CSR_SIMD_CSR2, int(multiplier_i))

    await snax_util.reg_write(dut, CSR_SIMD_LOOP, Tloop0 * Tloop1)

    await snax_util.reg_write(dut, CSR_SIMD_START, 1)

    await snax_util.reg_clr(dut)

    # wait for finish
    await snax_util.reg_write(dut, CSR_SIMD_START, 0)
    await snax_util.reg_write(dut, CSR_START_STREAMER, 0)
    cocotb.log.info("SIMD Operation Finished")
    await snax_util.reg_clr(dut)

    # Read the result and check
    for i in range(len(data_out_golden)):
        tcdm_wide_val = await snax_util.wide_tcdm_read(
            dut, OUT_offset + i * WIDE_BANK_INCREMENT
        )
        temp_val = data_out_golden[i] & (2**512 - 1)
        snax_util.comp_and_assert(temp_val, tcdm_wide_val)


# Main test run
def test_streamer_simd(simulator, waves):
    repo_path = os.getcwd()
    tests_path = repo_path + "/tests/cocotb/"

    # Make sure to generate the testbench
    # And all necessary files to make it work
    stream_simd_tb_file = repo_path + "/tests/tb/tb_streamer_simd.sv"
    if not os.path.exists(stream_simd_tb_file):
        subprocess.run(["mkdir", "rtl/streamer-simd"])
        subprocess.run(["make", stream_simd_tb_file])

    # Extract TCDM components
    tcdm_includes, tcdm_verilog_sources = snax_util.extract_tcdm_list()

    # Extract resources for simple mul
    streamer_simd_sources = [
        repo_path + "/rtl/streamer-simd/SIMDTop.sv",
        repo_path + "/rtl/streamer-simd/StreamerTop.sv",
        repo_path + "/rtl/streamer-simd/streamer_for_simd_wrapper.sv",
        repo_path + "/rtl/streamer-simd/streamer_simd_wrapper.sv",
    ]

    rtl_util_sources = [
        repo_path + "/rtl/rtl-util/csr_mux_demux.sv",
    ]

    tb_verilog_source = [
        stream_simd_tb_file,
    ]

    verilog_sources = (
        tcdm_verilog_sources
        + rtl_util_sources
        + streamer_simd_sources
        + tb_verilog_source
    )

    defines = []
    includes = [] + tcdm_includes

    toplevel = "tb_streamer_simd"

    module = "test_streamer_simd"

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
