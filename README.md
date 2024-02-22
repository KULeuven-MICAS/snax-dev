
# Snax Reshuffler

*Note: Not meant to merge into main*

This branch contains testcases for the implementation of the SNAX Reshuffler.
The reshuffler should be able to copy data from A to B while applying an affine transformation to the data layout.
The pseudocode for the transformation looks like this:

```
for i = 0 .. I
    for j = 0 .. J
        for k = 0 .. K
            B [i * stride_i_b + j * stride_j_b + k * stride_k_b] =
            A [i * stride_i_a + j * stride_j_a + k * stride_k_a] 
```

Every element is 64-bit ( = width of a narrow TCDM port)

The reshuffler may be configured to execute some for loops in parallel = unrolling the loop spatially.
The number of for loops must also be parametrizable.

## Test cases

Golden model for the reshuffling can be created with the `transform_data` function in `tests/cocotb/snax_util.py`
The python file `test.py` shows how to use the function with some sample configurations of reshuffling.
The file `test_reshuffler.py` in `tests/cocotb` provides a skeleton for the tests for the reshuffler, to what I think it should approximately look like. Feel free to use this / create your own, whatever is most useful!
