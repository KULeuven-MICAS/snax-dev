//-------------------------------
// Simple multiplier that follows
// the valid-ready responses per port
//-------------------------------
module simple_reshuffler_wrapper #(
  parameter int unsigned SpatPar       = 1,
  parameter int unsigned DataWidth     = 64,
  parameter int unsigned CsrAddrOffset = 8,
  parameter int unsigned RegCount      = 8,
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
  input  logic [(SpatPar*DataWidth)-1:0] data_i,
  input  logic                           data_valid_i,
  output logic                           data_ready_o,
  output logic [(SpatPar*DataWidth)-1:0] data_o,
  output logic                           data_valid_o,
  input  logic                           data_ready_i,
  //-------------------------------
  // CSR manager ports
  //-------------------------------
  input  logic [       RegAddrWidth-1:0] csr_addr_i,
  input  logic [       RegDataWidth-1:0] csr_wr_data_i,
  input  logic                           csr_wr_en_i,
  input  logic                           csr_req_valid_i,
  output logic                           csr_req_ready_o,
  output logic [       RegDataWidth-1:0] csr_rd_data_o,
  output logic                           csr_rsp_valid_o,
  input  logic                           csr_rsp_ready_i
);

  //-------------------------------
  // Generate Simple Reshuffler
  //-------------------------------
  // SpatPar == 1
  // for (genvar i = 0; i < SpatPar; i ++) begin: gen_spatpar  
  simple_reshuffler #(
    .DataWidth      ( DataWidth       )
  ) i_simple_reshuffler (
    .clk_i          ( clk_i           ),
    .rst_ni         ( rst_ni          ),
    .data_i         ( data_i          ),
    .data_valid_i   ( data_valid_i    ),
    .data_ready_o   ( data_ready_o    ),
    .data_o         ( data_o          ),
    .data_valid_o   ( data_valid_o    ),
    .data_ready_i   ( data_ready_i    )
  );
  // end

  //-------------------------------
  // CSR Manager
  //-------------------------------
  simple_reshuffler_csr #(
    .RegCount         ( RegCount        ),
    .RegDataWidth     ( RegDataWidth    ),
    .RegAddrWidth     ( RegAddrWidth    )
  ) i_simple_reshuffler_csr (
    .clk_i            ( clk_i           ),
    .rst_ni           ( rst_ni          ),
    .csr_addr_i       ( csr_addr_i      ),
    .csr_wr_data_i    ( csr_wr_data_i   ),
    .csr_wr_en_i      ( csr_wr_en_i     ),
    .csr_req_valid_i  ( csr_req_valid_i ),
    .csr_req_ready_o  ( csr_req_ready_o ),
    .csr_rd_data_o    ( csr_rd_data_o   ),
    .csr_rsp_valid_o  ( csr_rsp_valid_o ),
    .csr_rsp_ready_i  ( csr_rsp_ready_i )
  );

endmodule
