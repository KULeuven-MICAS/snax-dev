//---------------------------------
// Copyright 2023 KULeuven
// Author: Ryan Antonio (ryan.antonio@esat.kuleuven.be)
//---------------------------------

module tb_shift_reg #(

    //---------------------------------
    // Soft parameters that can change from cocotb pytest
    //---------------------------------
    parameter int unsigned DataWidth = 8,
    parameter int unsigned Depth     = 1

);

    //---------------------------------
    // Hard parameters that cannot be changed from cocotb pytest
    //---------------------------------
    localparam type dtype = logic [DataWidth-1:0];

    //---------------------------------
    // Wires
    //---------------------------------
    logic clk_i;
    logic rst_ni;
    dtype d_i;
    dtype d_o;

    //---------------------------------
    // Main DUT
    //---------------------------------
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
