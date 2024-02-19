//-------------------------------
// Simple multiplier that follows
// the valid-ready responses per port
//-------------------------------
module simple_alu_wrapper #(
  parameter int unsigned SpatPar       = 4,
  parameter int unsigned DataWidth     = 64,
  parameter int unsigned CsrAddrOffset = 8,
  parameter int unsigned RegCount 		 = 8,
  parameter int unsigned RegDataWidth  = 32,
	parameter int unsigned RegAddrWidth  = $clog2(RegCount)
)(
  //-------------------------------
  // Clocks and reset
  //-------------------------------
  input  logic                           clk_i,
  input  logic                           rst_ni,
  //-------------------------------
  // Accelerator ports
  //-------------------------------
  input  logic [(SpatPar*DataWidth)-1:0] a_i,
  input  logic                           a_valid_i,
  output logic                           a_ready_o,
  input  logic [(SpatPar*DataWidth)-1:0] b_i,
  input  logic                           b_valid_i,
  output logic                           b_ready_o,
  output logic [(SpatPar*DataWidth)-1:0] result_o,
  output logic                           result_valid_o,
  input  logic                           result_ready_i,
  //-------------------------------
  // CSR manager ports
  //-------------------------------
	input  logic [       RegAddrWidth-1:0] csr_addr_i,
  input  logic [       RegDataWidth-1:0] csr_wr_data_i,
	input  logic 										       csr_wr_en_i,
	input  logic 										       csr_req_valid_i,
	output logic										       csr_req_ready_o,
	output logic [       RegDataWidth-1:0] csr_rd_data_o,
	output logic										       csr_rsp_valid_o,
	input  logic										       csr_rsp_ready_i
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
    simple_alu #(
      .DataWidth      ( DataWidth       )
    ) i_simple_alu (
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
      .result_ready_i ( result_ready_i  ),
      .alu_config_i   ( csr_alu_config  )
    );
  end

  // Wiring for CSR configuration
  logic [1:0] csr_alu_config;

  //-------------------------------
  // CSR Manager
  //-------------------------------
  simple_alu_csr #(
    .RegCount         ( RegCount        ),
    .RegDataWidth     ( RegDataWidth    ),
    .RegAddrWidth     ( RegAddrWidth    )
  ) i_simple_alu_csr (
    .clk_i            ( clk_i           ),
    .rst_ni           ( rst_ni          ),
    .csr_addr_i       ( csr_addr_i      ),
    .csr_wr_data_i    ( csr_wr_data_i   ),
    .csr_wr_en_i      ( csr_wr_en_i     ),
    .csr_req_valid_i  ( csr_req_valid_i ),
    .csr_req_ready_o  ( csr_req_ready_o ),
    .csr_rd_data_o    ( csr_rd_data_o   ),
    .csr_rsp_valid_o  ( csr_rsp_valid_o ),
    .csr_rsp_ready_i  ( csr_rsp_ready_i ),
    .csr_alu_config_o ( csr_alu_config  )
  );

endmodule
