//---------------------------------
// Copyright 2023 KULeuven
// Author: Ryan Antonio (ryan.antonio@esat.kuleuven.be)
//
// Description:
//
// This wrapper is necessary, since cocotb can not resolve user-defined
// typedefs attached to the DUT directly. 
//
// The testbench contains parameters that can be controlled
// directly from cocotb.
//---------------------------------

module tb_shift_reg #(
    parameter int unsigned DataWidth = 8,
    parameter int unsigned Depth     = 1
);

    //---------------------------------
    // Workaround for cocotb to access the user defined dtype
    //---------------------------------
    localparam type dtype = logic [DataWidth-1:0];

    logic clk_i;
    logic rst_ni;
    dtype d_i;
    dtype d_o;

    shift_reg #(
        .dtype  ( dtype  ),
        .Depth  ( Depth  )
    ) i_shift_reg (
        .clk_i  ( clk_i  ),
        .rst_ni ( rst_ni ),
        .d_i    ( d_i    ),
        .d_o    ( d_o    )
    );

endmodule
