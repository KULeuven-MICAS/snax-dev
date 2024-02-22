# ---------------------------------
# Copyright 2023 KULeuven
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
# Author: Joren Dumoulin (joren.dumoulin@kuleuven.be)
#
# Description:
# This tests the functionality of the SNAX Reshuffler
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

TRANSFORMATION_PARAMS = {
    "nb_elements": 64,
    "nb_for_loops": 3,
    "strides": [
        {
            "src": 0,
            "dst": 1,
            "bound": 2
        },
        {
            "src": 1,
            "dst": 2,
            "bound": 2
        },
        {
            "src": 2,
            "dst": 3,
            "bound": 2
        }
    ]
}

@cocotb.test()
async def reshuffler_dut(dut):
    clock = Clock(dut.clk_i, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Initial reset values
    # Need to clear for modelsim (or other simulator)
    # Verilator assumes 0, no don't care states
    dut.rst_ni.value = 0

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

    # Begin test
    cocotb.log.info(" ------------------------------------------ ")
    cocotb.log.info(" Testing Reshuffler ")
    cocotb.log.info(" ------------------------------------------ ")

    # Get golden data
    input_list = snax_util.gen_rand_int_list(TRANSFORMATION_PARAMS["nb_elements"], NARROW_DATA_WIDTH)

    # Get golden data after transformation
    golden_list = snax_util.transform_data(input_list, TRANSFORMATION_PARAMS)

    # Write data to TCDM
    # TODO (using the snax_util.tcdm_write function ? )

    # Apply transformation
    # TODO

    # Read data from TCDM and check for results

    # Read data from TCDM
    #for i in ...
        # read value
        # check_val = ...
        # Check for results
        # cocotb.log.info(f"Actual output: {check_val}")
        # cocotb.log.info(f"Golden output: {wide_golden_list[i]}")
        # assert check_val == wide_golden_list[i]
     #   pass


# Main test run
def test_reshuffler(parameters, simulator):
    
    # TODO
    pass
