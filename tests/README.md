# Test Directory

This directory contains a set of tests for the designs a user makes. Here we provide tests for the TCDM subsystem, streamers, and a simple streaming multiplier accelerator. You should find:

* `/cocotb` - contains cocotb tests. These tests are the main test benches and cocotb acts like a driver.
    * `snax_util.py` - contains utility functions for testing. These include reading filelists, register read and write tasks, and DMA read or write tasks.
* `/tb` - contains test bench wrappers provide hooks for cocotb to drive and monitor.
    * **Note** these wrappers are necessary because not all signals are seen in cocotb. For example, user defined `typedef` signals are not recognizable by the cocotb drivers. You need to convert them into packed signals.

# How to Test

At the root of this repo, you can run all tests with:

```bash
pytest
```

If you want to specify a specific test you can invoke the command below. It runs the TCDM subsystem test.

```bash
pytest ./tests/cocotb/test_tcdm_subsys.py
```

There are `pytest` options available:

* `--simulator=<simulator>` specifies the simulator. By default our tests use Verilator (`verilator`). The tests also support Questasim (`questa`).
* `--waves=<1 or 0>` specifies if the tests need to dump waveform databases. By default it is set to 0.

For example you can invoke:


```bash
pytest ./tests/cocotb/test_tcdm_subsys.py --simulator=questa --waves=1
```

You can also add verbose logging in cocotb by invoking:


```bash
pytest ./tests/cocotb/test_tcdm_subsys.py -v -o log_cli=True --simulator=questa --waves=1
```