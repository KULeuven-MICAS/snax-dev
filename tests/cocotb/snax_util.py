# Import packages
import subprocess
import os
import random
from typing import List, Tuple, Optional
import cocotb
from cocotb.triggers import RisingEdge, Timer
from decimal import Decimal


# This extracts all benderized files
def extract_bender_filelist() -> Tuple[List[str], List[str], List[str]]:
    # Use verilator script because it has the complete and ordered filelist
    # bender script flist has incomplete include directories
    filelist = subprocess.run(["bender", "script", "verilator"], stdout=subprocess.PIPE)

    filelist = filelist.stdout.decode("utf-8").strip().split("\n")

    includes = []
    defines = []
    verilog_sources = []

    # For every item in the filelist,
    # assign them to include directories, defines list, and rtl sources
    # Skip comments and empty spaces
    for item in filelist:
        if item == "":
            pass
        elif item[0] == "#" or item[0] == "" or item[0] == "\n":
            pass
        elif item[0:8] == "+define+":
            defines.append(item[8:].strip())
        elif item[0:8] == "+incdir+":
            includes.append(item[8:].strip())
        else:
            verilog_sources.append(item.strip())

    return includes, defines, verilog_sources


# This extracts only a specific subset of modules from
# The benderized filelist
def extract_bender_filepath(target_module: str, given_list: List[str]) -> Optional[str]:
    # Iterate through list and find the target path
    # for a specific target_module
    # if there is more than 1 instance, raise an error
    num_instance = 0
    valid_path = None

    for path in given_list:
        if target_module in path:
            valid_path = path
            num_instance += 1

    if num_instance > 1:
        raise Exception("Multiple instances in bender filelist.")
    else:
        return valid_path


# This extracts the bender file path to
# a specified package
def extract_src_path(target_src: str) -> str:
    src_path = subprocess.run(["bender", "path", target_src], stdout=subprocess.PIPE)
    src_path = src_path.stdout.decode("utf-8").strip().split("\n")[0]

    return src_path


# This lists all necessary files for the
# TCDM subsystem
def extract_tcdm_list() -> Tuple[List[str], List[str]]:
    # Get repo path (from snax-dev directory)
    repo_path = os.getcwd()
    pulp_submodule_path = repo_path + "/rtl/pulp-submodules"

    # Extract bender path names
    common_cells_path = pulp_submodule_path + "/common_cells"
    axi_path = pulp_submodule_path + "/axi"
    register_interface_path = pulp_submodule_path + "/register_interface"
    snitch_cluster_path = pulp_submodule_path + "/snitch_cluster"
    dm_pkg_path = pulp_submodule_path + "/riscv-dbg"
    tech_cells_path = pulp_submodule_path + "/tech_cells_generic"

    # Extract include list for typedefs
    include_list = [
        common_cells_path + "/include",
        axi_path + "/include",
        register_interface_path + "/include",
        snitch_cluster_path + "/hw/snitch/include",
        snitch_cluster_path + "/hw/mem_interface/include",
        snitch_cluster_path + "/hw/tcdm_interface/include",
    ]

    # Extract common cells
    common_cells_list = [
        common_cells_path + "/src/cf_math_pkg.sv",
        common_cells_path + "/src/stream_demux.sv",
        common_cells_path + "/src/rr_arb_tree.sv",
        common_cells_path + "/src/stream_xbar.sv",
        common_cells_path + "/src/shift_reg.sv",
        common_cells_path + "/src/shift_reg_gated.sv",
        common_cells_path + "/src/spill_register_flushable.sv",
        common_cells_path + "/src/spill_register.sv",
        common_cells_path + "/src/lzc.sv",
    ]

    # Extract debug package
    dm_pkg_list = [dm_pkg_path + "/src/dm_pkg.sv"]

    # Extract technological cells
    tech_cells_list = [
        tech_cells_path + "/src/rtl/tc_sram.sv",
        tech_cells_path + "/src/rtl/tc_sram_impl.sv",
    ]

    # Extract AXI cells
    axi_cells_list = [axi_path + "/src/axi_pkg.sv"]

    # Snitch cluster cells
    snitch_cluster_cells = [
        snitch_cluster_path + "/hw/reqrsp_interface/src/reqrsp_pkg.sv",
        snitch_cluster_path + "/hw/snitch/src/snitch_pkg.sv",
        snitch_cluster_path + "/hw/snitch_cluster/src/snitch_tcdm_interconnect.sv",
        snitch_cluster_path + "/hw/snitch_cluster/src/snitch_amo_shim.sv",
        snitch_cluster_path + "/hw/mem_interface/src/mem_wide_narrow_mux.sv",
    ]

    # Add top-level tcdm components
    tcdm_subsys = [
        repo_path + "/rtl/memory-subsys/tcdm_subsys.sv",
        repo_path + "/tests/tb/tb_tcdm_subsys.sv",
    ]

    # Combine all RTl lists
    verilog_list = (
        common_cells_list
        + dm_pkg_list
        + tech_cells_list
        + axi_cells_list
        + snitch_cluster_cells
        + tcdm_subsys
    )

    return include_list, verilog_list


# This generates a random list of integers
# Input is list length, the minimum value and max value
def gen_rand_int_list(list_len: int, min_val: int, max_val: int) -> List[int]:
    uint_list = []

    random.seed(0)

    for i in range(list_len):
        uint_list.append(random.randint(min_val, max_val))

    return uint_list


# This is for repacking data from a contigious list
# into a list of packed data for DMA read and write chunks
def gen_wide_list(
    narrow_list: List[int], narrow_width: int, wide_width: int
) -> List[int]:
    # This one checks if the number of narrow elements
    # Is divisible by the ratio of wide and narrow widths
    # Otherwise you will not utilize the entire DMA
    wide_list = []
    wide_narrow_ratio = int(wide_width / narrow_width)
    if len(narrow_list) % wide_narrow_ratio:
        print("WARNING! Number of elements and wide-narrow ratio are not divisible")

    wide_len = int(len(narrow_list) / wide_narrow_ratio)

    for i in range(wide_len):
        wide_num = 0
        for j in range(wide_narrow_ratio - 1, -1, -1):
            wide_num += narrow_list[i * wide_narrow_ratio + j] << (narrow_width * j)
        wide_list.append(wide_num)

    return wide_list


# Compare and assert
def comp_and_assert(golden_data: int, actual_data: int) -> None:
    cocotb.log.info(f"Golden data: {hex(golden_data)}; Actual data: {hex(actual_data)}")
    assert golden_data == actual_data
    return


# Functions for register reading or writing
# to controls status registers. This one
# uses the direct connection for the
# SNAX streamer and SNAX accelerators
# made by chisel.
async def clock_and_wait(dut) -> None:
    await RisingEdge(dut.clk_i)
    await Timer(Decimal(1), units="ps")
    return


# Functions for reading and writing to registers
# For writing to registers
async def reg_write(dut, addr: int, data: int) -> None:
    dut.io_csr_req_bits_data_i.value = data
    dut.io_csr_req_bits_addr_i.value = addr
    dut.io_csr_req_bits_write_i.value = 1
    dut.io_csr_req_valid_i.value = 1
    # Check if ready is high, wait if not
    await Timer(Decimal(1), units="ps")
    while dut.io_csr_req_ready_o.value != 1:
        await clock_and_wait(dut)
    await clock_and_wait(dut)

    return


# For reading from registers
async def reg_read(dut, addr: int) -> int:
    dut.io_csr_req_bits_data_i.value = 0
    dut.io_csr_req_bits_addr_i.value = addr
    dut.io_csr_req_bits_write_i.value = 0
    dut.io_csr_req_valid_i.value = 1
    await clock_and_wait(dut)

    reg_read = int(dut.io_csr_rsp_bits_data_o.value)

    return reg_read


# For clearing the ports
async def reg_clr(dut) -> None:
    dut.io_csr_req_bits_data_i.value = 0
    dut.io_csr_req_bits_addr_i.value = 0
    dut.io_csr_req_bits_write_i.value = 0
    dut.io_csr_req_valid_i.value = 0

    return


# Functions for TCDM control
# Writing to TCDM
async def tcdm_write(dut, idx: int, addr: int, data: int) -> None:
    dut.tcdm_req_addr_i[idx].value = addr
    dut.tcdm_req_data_i[idx].value = data
    dut.tcdm_req_strb_i[idx].value = 0xFF
    dut.tcdm_req_write_i[idx].value = 1
    dut.tcdm_req_q_valid_i[idx].value = 1
    await clock_and_wait(dut)

    return


# Reading from TCDM
async def tcdm_read(dut, idx: int, addr: int) -> int:
    dut.tcdm_req_addr_i[idx].value = addr
    dut.tcdm_req_data_i[idx].value = 0
    dut.tcdm_req_strb_i[idx].value = 0x00
    dut.tcdm_req_write_i[idx].value = 0
    dut.tcdm_req_q_valid_i[idx].value = 1
    await clock_and_wait(dut)

    reg_read = int(dut.tcdm_rsp_data_o[idx].value)

    return reg_read


# Clear TCDM
async def tcdm_clr(dut, idx: int) -> None:
    dut.tcdm_req_addr_i[idx].value = 0
    dut.tcdm_req_data_i[idx].value = 0
    dut.tcdm_req_strb_i[idx].value = 0
    dut.tcdm_req_write_i[idx].value = 0
    dut.tcdm_req_q_valid_i[idx].value = 0
    await clock_and_wait(dut)

    return


# Functions for Wide TCDM control
# Writing to Wide TCDM
async def wide_tcdm_write(dut, addr: int, data: int) -> None:
    dut.tcdm_dma_req_addr_i.value = addr
    dut.tcdm_dma_req_data_i.value = data
    dut.tcdm_dma_req_strb_i.value = 0xFFFFFFFFFFFFFFFF
    dut.tcdm_dma_req_write_i.value = 1
    dut.tcdm_dma_req_q_valid_i.value = 1
    await clock_and_wait(dut)

    return


# Reading from Wide TCDM
async def wide_tcdm_read(dut, addr: int) -> int:
    dut.tcdm_dma_req_addr_i.value = addr
    dut.tcdm_dma_req_data_i.value = 0
    dut.tcdm_dma_req_strb_i.value = 0x00
    dut.tcdm_dma_req_write_i.value = 0
    dut.tcdm_dma_req_q_valid_i.value = 1
    await clock_and_wait(dut)

    reg_read = int(dut.tcdm_dma_rsp_data_o.value)

    return reg_read


# Clear Wide TCDM
async def wide_tcdm_clr(dut) -> None:
    dut.tcdm_dma_req_addr_i.value = 0
    dut.tcdm_dma_req_data_i.value = 0
    dut.tcdm_dma_req_strb_i.value = 0
    dut.tcdm_dma_req_write_i.value = 0
    dut.tcdm_dma_req_q_valid_i.value = 0
    await clock_and_wait(dut)

    return


async def reset_dut(dut) -> None:
    dut.rst_ni.value = 0
    await clock_and_wait(dut)
    dut.rst_ni.value = 1
    await clock_and_wait(dut)
    return
