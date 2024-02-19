# Utility

This directory has the following:

* `/container` - Has the docker file used for this repo.
* `/scripts` - Contains useful scripts. Right now we have a template generation tool.
* `/cfg` - Has configuration files for templates used for the template generation.
* `/templates` - Contains several templates for different files.

# Docker Usage

You can build the docker with:

```bash
docker build -t snax-cocotb util/container/.
```

Alternatively, you can download the latest pre-built container with:

```bash
docker pull ghcr.io/kuleuven-micas/snax-cocotb:latest
```

You can run the container with (make sure you are at the root of the repo):

```bash
docker run -it -v `pwd`:/repo -w /repo ghcr.io/kuleuven-micas/snax-cocotb
```

# Template Generation Usage

The file generation uses [Mako Templates](https://www.makotemplates.org/) to produce source and parameter files. You only need:

* Configuration files that contain parametrizable variables. Check `/cfg` directory for examples.
* Template files which are the formats for the file to produce.

The `/scripts/template_gen.py` script grabs the both the configuration files and template files to produce the target file. For example, the command below generates a `streamer_wrapper.sv` file. Invoke this from the root of the repo:

```bash
python3 util/scripts/template_gen.py --cfg_path="./util/cfg/streamer_cfg.hjson" --tpl_path="./util/templates/streamer_wrapper.sv.tpl" --out_path="./rtl/streamer_wrapper.sv"
```

Where:

* `--cfg_path` - points to the configuration file
* `--tpl_path` - points to the template file
* `--out_path` - points to the output path

