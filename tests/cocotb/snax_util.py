import subprocess
from typing import List, Tuple


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


def extract_bender_filepath(target_module: str, given_list: List[str]) -> str:
    # Iterate through list and find the target path
    # for a specific target_module
    for path in given_list:
        if target_module in path:
            filepath = path
            return filepath
