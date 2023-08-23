module counter #(
  parameter int unsigned COUNTER_WIDTH = 8
)(
  input  logic                      clk_i,
  input  logic                      rst_ni,
  input  logic                      clr_i,
  output logic [COUNTER_WIDTH-1:0]  out
);

  always_ff @ (posedge clk_i or negedge rst_ni) begin
    if(!rst_ni) begin
      out <= {COUNTER_WIDTH{1'b0}};
    end else begin
      if(clr_i) begin
        out <= {COUNTER_WIDTH{1'b0}};
      end else begin
        out <= out + 1;
      end
    end
  end

endmodule
