//-------------------------------
// Simple multiplier that follows
// the valid-ready responses per port
//-------------------------------
module simple_reshuffler #(
  parameter int unsigned DataWidth = 64
)(
  input  logic                 clk_i,
  input  logic                 rst_ni,
  input  logic [DataWidth-1:0] data_i,
  input  logic                 data_valid_i,
  output logic                 data_ready_o,
  output logic [DataWidth-1:0] data_o,
  output logic                 data_valid_o,
  input  logic                 data_ready_i
);

  //-------------------------------
  // Wires and combinationa logic
  //-------------------------------
  logic [DataWidth-1:0] data_tmp;

  logic input_success;
  logic output_success;

  logic result_success;
  logic result_valid;

  assign input_success  = data_valid_i;
  assign output_success = data_valid_o && data_ready_i;

  //-------------------------------
  // Registered output
  //-------------------------------
  always_ff @ (posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      data_tmp  <= {DataWidth{1'b0}};
      result_valid <= 1'b0;
    end else begin
      if(input_success) begin
        data_tmp <= data_i;
        result_valid <= 1'b1;
      end else if (output_success) begin
        data_tmp  <= {DataWidth{1'b0}};
        result_valid <= 1'b0;
      end else begin
        data_tmp  <= data_tmp;
        result_valid <= result_valid;
      end
    end
  end

  //-------------------------------
  // Assignments
  //-------------------------------
  // Input ports are ready when the output
  // Is actually ready to get data
  assign data_ready_o = input_success;
  assign data_valid_o = result_valid;
  assign data_o       = data_tmp[DataWidth-1:0];

endmodule
