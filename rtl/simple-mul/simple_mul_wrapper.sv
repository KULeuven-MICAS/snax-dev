//-------------------------------
// Simple multiplier that follows
// the valid-ready responses per port
//-------------------------------
module simple_mul_wrapper #(
  parameter int unsigned SpatPar = 4,
  parameter int unsigned DataWidth = 64
)(
  input  logic                           clk_i,
  input  logic                           rst_ni,
  input  logic [(SpatPar*DataWidth)-1:0] a_i,
  input  logic                           a_valid_i,
  output logic                           a_ready_o,
  input  logic [(SpatPar*DataWidth)-1:0] b_i,
  input  logic                           b_valid_i,
  output logic                           b_ready_o,
  output logic [(SpatPar*DataWidth)-1:0] result_o,
  output logic                           result_valid_o,
  input  logic                           result_ready_i
);

  //-------------------------------
  // Wires and combinationa logic
  //-------------------------------
  logic [SpatPar-1:0][DataWidth-1:0] a_split;
  logic [SpatPar-1:0][DataWidth-1:0] b_split;
  logic [SpatPar-1:0][DataWidth-1:0] result_split;

  logic [SpatPar-1:0] a_ready;
  logic [SpatPar-1:0] b_ready;
  logic [SpatPar-1:0] result_valid;

  //-------------------------------
  // Flexible mapping
  //-------------------------------
  always_comb begin
    for (int i = 0; i < SpatPar; i++) begin
      a_split[i] = a_i[i*DataWidth+:DataWidth];
      b_split[i] = b_i[i*DataWidth+:DataWidth];
      result_o[i*DataWidth+:DataWidth] = result_split[i];
    end

    a_ready_o = &a_ready;
    b_ready_o = &b_ready;
    result_valid_o = &result_valid;
  end

  //-------------------------------
  // Generate Simple Multipliers
  //-------------------------------
  for (genvar i = 0; i < SpatPar; i ++) begin: gen_spatpar_muls
    simple_mul #(
      .DataWidth      ( DataWidth       )
    ) i_simple_mul (
      .clk_i          ( clk_i           ),
      .rst_ni         ( rst_ni          ),
      .a_i            ( a_split[i]      ),
      .a_valid_i      ( a_valid_i       ),
      .a_ready_o      ( a_ready[i]      ),
      .b_i            ( b_split[i]      ),
      .b_valid_i      ( b_valid_i       ),
      .b_ready_o      ( b_ready[i]      ),
      .result_o       ( result_split[i] ),
      .result_valid_o ( result_valid[i] ),
      .result_ready_i ( result_ready_i  )
    );
  end

endmodule
