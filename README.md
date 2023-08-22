#  SNAX - Snitch Accelerator Extension

This is the development repo for the SNAX project. It is a variant of the [Snitch Cluster Platform](https://github.com/pulp-platform/snitch_cluster) where it focuses on heterogenous architectures. 

# Testing and Verification
* **Please make sure to install Verilator version v5.006**. Refer to [Verilator](https://verilator.org/guide/latest/install.html) for installation details.
* Please make sure to have Python3.10 and the required packages in `requirements.txt`. You can invoke:

```bash
pip install -r requirements.txt
```
Run tests:
```bash
pytest --simulator=verilator
```
You can set `--simulator` to any of the [cocotb supported simulators](https://docs.cocotb.org/en/stable/simulator_support.html).
This option is set to `verilator` by default.

# Development
We provide pre-commit hooks to help formatting python and yaml code.
To hook the pre-commit hooks into git, use:
```bash
pre-commit install
```
