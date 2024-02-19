//-------------------------------
// Simple set of CSRs for the
// simple ALU accelerator
//-------------------------------
module simple_alu_csr #(
	parameter int unsigned RegCount 		= 8,
  parameter int unsigned RegDataWidth = 32,
	parameter int unsigned RegAddrWidth = $clog2(RegCount)
)(
  input  logic                 		clk_i,
  input  logic                 		rst_ni,
	input  logic [RegAddrWidth-1:0] csr_addr_i,
  input  logic [RegDataWidth-1:0] csr_wr_data_i,
	input  logic 										csr_wr_en_i,
	input  logic 										csr_req_valid_i,
	output logic										csr_req_ready_o,
	output logic [RegDataWidth-1:0] csr_rd_data_o,
	output logic										csr_rsp_valid_o,
	input  logic										csr_rsp_ready_i,
  // Fix this to 2 bits only
  // Let's do 4 ALU operations for simplicity
  output logic 						  [1:0] csr_alu_config_o
);

	//-------------------------------
	// In this set we use 8 registers
	// but only the first one is for the configuration
	//-------------------------------
	logic [RegWidth-1:0] csr_reg_set [RegCount];

	//-------------------------------
	// The CSR manager is always ready to take
	// in new configurations
	//-------------------------------
	logic req_success;

	assign csr_req_ready_o = 1'b1;
	assign req_success = csr_req_valid_i && csr_req_ready_o;

	//-------------------------------
	// Updating CSR registers
	//-------------------------------
	always_ff @ (posedge clk_i or negedge rst_ni) begin
		if(!rst_ni) begin
			for( int i = 0; i < RegCount; i++) begin
				csr_reg_set <= {RegCount{1'b0}};
			end
		end else begin
			if(req_success && csr_wr_en_i) begin
				csr_reg_set[csr_addr_i] <= csr_wr_data_i;
			end else begin
				csr_reg_set[csr_addr_i] <= csr_reg_set[csr_addr_i];
			end
		end
	end

	//-------------------------------
	// Since RISCV CSR instructions
	// an automatic read and write
	// every cycle of a request,
	// the next cycle gives a valid data out
	// Note that register 0 is only the useful
	// one, but registers above 0 are general purpose
	//-------------------------------
	logic rsp_success = csr_rsp_valid_o && csr_rsp_ready_i;

	always_ff @ (posedge clk_i or negedge rst_ni) begin
		if(!rst_ni) begin
			csr_rd_data_o 	<= {RegDataWidth{1'b0}};
			csr_rsp_valid_o <= 1'b0;
		end else begin
			if(req_success) begin
				csr_rd_data_o	  <= csr_reg_set[csr_addr_i];
				csr_rsp_valid_o <= 1'b1;
			end else if (rsp_success) begin
				csr_rd_data_o 	<= {RegDataWidth{1'b0}};
				csr_rsp_valid_o <= 1'b0;
			end else begin
				csr_rd_data_o 	<= csr_rd_data_o;
				csr_rsp_valid_o <= csr_rsp_valid_o;
			end
		end
	
	//-------------------------------
	// Register 0 has its own usefulness
	//-------------------------------
	assign csr_alu_config_o = csr_reg_set[0][1:0];

endmodule