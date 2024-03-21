//-------------------------------
// Data reshuffler that follows
// the valid-ready responses per port
//-------------------------------
module dev_reshuffler #(
  parameter int unsigned SpatPar   = 8,
  parameter int unsigned DataWidth = 64,
  parameter int unsigned Elems     = DataWidth / SpatPar
)(
  input  logic                           clk_i,
  input  logic                           rst_ni,
  input  logic [(SpatPar*DataWidth)-1:0] a_i,
  input  logic                           a_valid_i,
  output logic                           a_ready_o,
  output logic [(SpatPar*DataWidth)-1:0] z_o,
  output logic                           z_valid_o,
  input  logic                           z_ready_i
);

  //-------------------------------
  // Wires and combinationa logic
  //-------------------------------
  logic [SpatPar-1:0][SpatPar-1:0][Elems-1:0] a_split;
  logic [SpatPar-1:0][SpatPar-1:0][Elems-1:0] z_split;
  logic [(SpatPar*DataWidth)-1:0] z_wide;
  logic [(SpatPar*DataWidth)-1:0] z_wide_tmp;

  logic z_valid;

  for (genvar i = 0; i < SpatPar; i++) begin
    for (genvar j = 0; j < SpatPar; j++) begin
      assign a_split[i][j] = a_i[(i * SpatPar + j) +: Elems];
      // Transpose the data
      assign z_split[i][j] = a_split[j][i];
      assign z_wide_tmp[(i * SpatPar + j) * Elems +: Elems] = z_split[i][j];
    end
  end

  logic a_success;
  logic z_success;

  assign a_success  = a_valid_i;
  assign z_success = z_valid_o && z_ready_i;

  //-------------------------------
  // Registered output
  //-------------------------------
  always_ff @ (posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      z_wide  <= {(SpatPar*DataWidth){1'b0}};
      z_valid <= 1'b0;
    end else begin
      if(a_success) begin
        z_wide <= z_wide_tmp;
        z_valid <= 1'b1;
      end else if (z_success) begin
        z_wide  <= {(SpatPar*DataWidth){1'b0}};
        z_valid <= 1'b0;
      end else begin
        z_wide  <= z_wide;
        z_valid <= z_valid;
      end
    end
  end

  //-------------------------------
  // Assignments
  //-------------------------------
  // Input ports are ready when the output
  // Is actually ready to get data
  assign a_ready_o = a_success;
  assign z_valid_o = z_valid;
  assign z_o       = z_wide;

endmodule
