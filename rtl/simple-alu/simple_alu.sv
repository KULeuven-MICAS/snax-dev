//-------------------------------
// Simple multiplier that follows
// the valid-ready responses per port
//-------------------------------
module simple_alu #(
  parameter int unsigned DataWidth = 64
)(
  input  logic                 clk_i,
  input  logic                 rst_ni,
  input  logic [DataWidth-1:0] a_i,
  input  logic                 a_valid_i,
  output logic                 a_ready_o,
  input  logic [DataWidth-1:0] b_i,
  input  logic                 b_valid_i,
  output logic                 b_ready_o,
  output logic [DataWidth-1:0] result_o,
  output logic                 result_valid_o,
  input  logic                 result_ready_i,
  // Fix this to 2 bits only
  // Let's do 4 ALU operations for simplicity
  input  logic [          1:0] alu_config_i
);

  //-------------------------------
  // Local parameter
  //-------------------------------
  localparam int unsigned CsrAddrAdd = 0;
  localparam int unsigned CsrAddrSub = 1;
  localparam int unsigned CsrAddrMul = 2;
  localparam int unsigned CsrAddrXor = 0;

  //-------------------------------
  // Wires and combinationa logic
  //-------------------------------
  logic [2*DataWidth-1:0] result_wide;

  logic input_success;
  logic output_success;

  logic result_success;
  logic result_valid;

  assign input_success  = a_valid_i && b_valid_i;
  assign output_success = result_valid_o && result_ready_i;

  //-------------------------------
  // Registered output
  //-------------------------------
  always_ff @ (posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      result_wide  <= {DataWidth{1'b0}};
      result_valid <= 1'b0;
    end else begin
      if(input_success) begin
        case(alu_config_i)
          CsrAddrSub: result_wide <= a_i - b_i;
          CsrAddrMul: result_wide <= a_i * b_i;
          CsrAddrXor: result_wide <= a_i ^ b_i;
          default:    result_wide <= a_i + b_i;
        endcase
        result_valid <= 1'b1;
      end else if (output_success) begin
        result_wide  <= {DataWidth{1'b0}};
        result_valid <= 1'b0;
      end else begin
        result_wide  <= result_wide;
        result_valid <= result_valid;
      end
    end
  end

  //-------------------------------
  // Assignments
  //-------------------------------
  // Input ports are ready when the output
  // Is actually ready to get data
  assign a_ready_o      = input_success;
  assign b_ready_o      = input_success;
  assign result_valid_o = result_valid;
  assign result_o       = result_wide[DataWidth-1:0];

endmodule
