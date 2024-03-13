# Case 1
# Base Streamer Test Cases
make clean
pytest tests/cocotb/test_basic_streamer_reshuffler_case1.py -s --simulator=verilator
pytest tests/cocotb/test_stream_tcdm_reshuffler_case1.py -s --simulator=verilator
pytest tests/cocotb/test_stream_reshuffler_case1.py --simulator=verilator

# Case 2
# Base Streamer Test Cases
make clean
pytest tests/cocotb/test_basic_streamer_reshuffler_case2.py -s --simulator=verilator
pytest tests/cocotb/test_stream_tcdm_reshuffler_case2.py -s --simulator=verilator
pytest tests/cocotb/test_stream_reshuffler_case2.py --simulator=verilator

# Case 3
# Base Streamer Test Cases
make clean
pytest tests/cocotb/test_basic_streamer_reshuffler_case3.py -s --simulator=verilator
pytest tests/cocotb/test_stream_tcdm_reshuffler_case3.py -s --simulator=verilator
pytest tests/cocotb/test_stream_reshuffler_case3.py --simulator=verilator

# Case 4
# Base Streamer Test Cases
make clean
pytest tests/cocotb/test_basic_streamer_reshuffler_case4.py -s --simulator=verilator
pytest tests/cocotb/test_stream_tcdm_reshuffler_case4.py -s --simulator=verilator
pytest tests/cocotb/test_stream_reshuffler_case4.py --simulator=verilator

# Case 5
# Base Streamer Test Cases
make clean
pytest tests/cocotb/test_basic_streamer_reshuffler_case5.py -s --simulator=verilator
pytest tests/cocotb/test_stream_tcdm_reshuffler_case5.py -s --simulator=verilator
pytest tests/cocotb/test_stream_reshuffler_case5.py --simulator=verilator