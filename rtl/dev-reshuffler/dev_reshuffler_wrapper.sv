//-------------------------------
// Data reshuffler that follows
// the valid-ready responses per port
//-------------------------------
module dev_reshuffler_wrapper #(
  parameter int unsigned SpatPar       = 8,
  parameter int unsigned DataWidth     = 64,
  parameter int unsigned Elems         = DataWidth / SpatPar,
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
  input  logic [(SpatPar*DataWidth)-1:0] a_i,
  input  logic                           a_valid_i,
  output logic                           a_ready_o,

  output logic [(SpatPar*DataWidth)-1:0] z_o,
  output logic                           z_valid_o,
  input  logic                           z_ready_i,
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
  // Wires and combinationa logic
  //-------------------------------
  logic [SpatPar-1:0] a_ready;
  logic [SpatPar-1:0] z_valid;


  //-------------------------------
  // Generate Simple Multipliers
  //-------------------------------
  dev_reshuffler #(
    .SpatPar        ( SpatPar         ),
    .DataWidth      ( DataWidth       )
  ) i_dev_reshuffler (
    .clk_i          ( clk_i           ),
    .rst_ni         ( rst_ni          ),
    .a_i            ( a_i             ),
    .a_valid_i      ( a_valid_i       ),
    .a_ready_o      ( a_ready_o       ),
    .z_o            ( z_o             ),
    .z_valid_o      ( z_valid_o       ),
    .z_ready_i      ( z_ready_i       )
  );

  //-------------------------------
  // CSR Manager
  //-------------------------------
  dev_reshuffler_csr #(
    .RegCount         ( RegCount        ),
    .RegDataWidth     ( RegDataWidth    ),
    .RegAddrWidth     ( RegAddrWidth    )
  ) i_dev_reshuffler_csr (
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
