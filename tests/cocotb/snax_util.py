import subprocess


def extract_bender_filelist():
    # Use verilator script because it has the complete and ordered filelist
    # bender script flist has incomplete include directories
    filelist = subprocess.run(["bender", "script", "verilator"], stdout=subprocess.PIPE)

    filelist = filelist.stdout.decode("utf-8").strip().split("\n")

    includes = []
    defines = []
    verilog_sources = []

    # For every item in the filelist,
    # assign them to include direcotires, defines list, and rtl sources
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
