//-----------------------------------
// Tightly Coupled Data Memory Sub-System 
// Local testbench
//-----------------------------------
module tb_streamer_top;

  localparam int unsigned NarrowDataWidth = 64;
  localparam int unsigned TCDMDepth = 256;
  localparam int unsigned TCDMReqPorts = 13;
  localparam int unsigned TCDMMemAddrWidth = $clog2(TCDMDepth);
  localparam int unsigned TCDMSize = TCDMReqPorts * TCDMDepth * (NarrowDataWidth/8);
  //localparam int unsigned TCDMAddrWidth = $clog2(TCDMSize);
  localparam int unsigned TCDMAddrWidth = 32;

  // clock and resets
  logic clk_i;
  logic rst_ni;

  // ports from streamer to accelerator
  logic [255:0] acc2stream_data_0_bits_i;
  logic acc2stream_data_0_valid_i;
  logic acc2stream_data_0_ready_o;

  // ports from acclerator to streamer
  logic [255:0] stream2acc_data_0_bits_o;
  logic stream2acc_data_0_valid_o;
  logic stream2acc_data_0_ready_i;

  logic [255:0] stream2acc_data_1_bits_o;
  logic stream2acc_data_1_valid_o;
  logic stream2acc_data_1_ready_i;

  logic [63:0] stream2acc_data_2_bits_o;
  logic stream2acc_data_2_valid_o;
  logic stream2acc_data_2_ready_i;

  //-----------------------------
  // TCDM ports
  //-----------------------------
  // Request
  logic [TCDMReqPorts-1:0] tcdm_req_write_o;
  logic [TCDMReqPorts-1:0][TCDMAddrWidth-1:0] tcdm_req_addr_o;
  logic [TCDMReqPorts-1:0][3:0] tcdm_req_amo_o; //Note that tcdm_req_amo_i is 4 bits based on reqrsp definition
  logic [TCDMReqPorts-1:0][NarrowDataWidth-1:0] tcdm_req_data_o;
  logic [TCDMReqPorts-1:0][4:0] tcdm_req_user_core_id_o; //Note that tcdm_req_user_core_id_i is 5 bits based on Snitch definition
  logic [TCDMReqPorts-1:0] tcdm_req_user_is_core_o;
  logic [TCDMReqPorts-1:0][NarrowDataWidth/8-1:0] tcdm_req_strb_o;
  logic [TCDMReqPorts-1:0] tcdm_req_q_valid_o;

  // Response
  logic [TCDMReqPorts-1:0] tcdm_rsp_q_ready_i;
  logic [TCDMReqPorts-1:0] tcdm_rsp_p_valid_i;
  logic [TCDMReqPorts-1:0][NarrowDataWidth-1:0] tcdm_rsp_data_i;

  //-----------------------------
  // CSR control ports
  //-----------------------------
  // Request
  logic [31:0] io_csr_req_bits_data_i;
  logic [31:0] io_csr_req_bits_addr_i;
  logic io_csr_req_bits_write_i;
  logic io_csr_req_valid_i;
  logic io_csr_req_ready_o;

  // Response
  logic io_csr_rsp_ready_i;
  logic io_csr_rsp_valid_o;
  logic [31:0] io_csr_rsp_bits_data_o;

  // Combinational control
  always_comb begin

    // Instant loop backs for easier control
    acc2stream_data_0_valid_i = acc2stream_data_0_ready_o;
    stream2acc_data_0_ready_i = stream2acc_data_0_valid_o;
    stream2acc_data_1_ready_i = stream2acc_data_1_valid_o;
    stream2acc_data_2_ready_i = stream2acc_data_2_valid_o;

    // Always on signals
    for(int i = 0; i < TCDMReqPorts; i++) begin
      tcdm_rsp_q_ready_i[i] = tcdm_req_q_valid_o[i];
      tcdm_rsp_p_valid_i[i] = '1;
      tcdm_rsp_data_i[i] = '0;
    end
  
  end

  streamer_wrapper #(
    .NarrowDataWidth (NarrowDataWidth),
    .TCDMDepth (TCDMDepth),
    .TCDMReqPorts (TCDMReqPorts),
    .TCDMSize (TCDMSize),
    .TCDMAddrWidth (TCDMAddrWidth)
  ) i_streamer_wrapper (
    //-----------------------------
    // Clocks and reset
    //-----------------------------
    .clk_i (clk_i),
    .rst_ni (rst_ni),

    //-----------------------------
    // Accelerator ports
    //-----------------------------
    // ports from streamer to accelerator
    .acc2stream_data_0_bits_i (acc2stream_data_0_bits_i),
    .acc2stream_data_0_valid_i (acc2stream_data_0_valid_i),
    .acc2stream_data_0_ready_o (acc2stream_data_0_ready_o),

    // ports from acclerator to streamer
    .stream2acc_data_0_bits_o (stream2acc_data_0_bits_o),
    .stream2acc_data_0_valid_o (stream2acc_data_0_valid_o),
    .stream2acc_data_0_ready_i (stream2acc_data_0_ready_i),

    .stream2acc_data_1_bits_o (stream2acc_data_1_bits_o),
    .stream2acc_data_1_valid_o (stream2acc_data_1_valid_o),
    .stream2acc_data_1_ready_i (stream2acc_data_1_ready_i),

    .stream2acc_data_2_bits_o (stream2acc_data_2_bits_o),
    .stream2acc_data_2_valid_o (stream2acc_data_2_valid_o),
    .stream2acc_data_2_ready_i (stream2acc_data_2_ready_i),

    //-----------------------------
    // TCDM ports
    //-----------------------------
    // Request
    .tcdm_req_write_o (tcdm_req_write_o),
    .tcdm_req_addr_o (tcdm_req_addr_o),
    .tcdm_req_amo_o (tcdm_req_amo_o), //Note that tcdm_req_amo_i is 4 bits based on reqrsp definition
    .tcdm_req_data_o (tcdm_req_data_o),
    .tcdm_req_user_core_id_o (tcdm_req_user_core_id_o), //Note that tcdm_req_user_core_id_i is 5 bits based on Snitch definition
    .tcdm_req_user_is_core_o (tcdm_req_user_is_core_o),
    .tcdm_req_strb_o (tcdm_req_strb_o),
    .tcdm_req_q_valid_o (tcdm_req_q_valid_o),

    // Response
    .tcdm_rsp_q_ready_i (tcdm_rsp_q_ready_i),
    .tcdm_rsp_p_valid_i (tcdm_rsp_p_valid_i),
    .tcdm_rsp_data_i (tcdm_rsp_data_i),

    //-----------------------------
    // CSR control ports
    //-----------------------------
    // Request
    .io_csr_req_bits_data_i (io_csr_req_bits_data_i),
    .io_csr_req_bits_addr_i (io_csr_req_bits_addr_i),
    .io_csr_req_bits_write_i (io_csr_req_bits_write_i),
    .io_csr_req_valid_i (io_csr_req_valid_i),
    .io_csr_req_ready_o (io_csr_req_ready_o),

    // Response
    .io_csr_rsp_ready_i (io_csr_rsp_ready_i),
    .io_csr_rsp_valid_o (io_csr_rsp_valid_o),
    .io_csr_rsp_bits_data_o (io_csr_rsp_bits_data_o)
  );

  always begin #10; clk_i <= !clk_i; end

  task cfg_write(
    input logic [31:0] addr,
    input logic [31:0] data
  );
    io_csr_req_bits_addr_i = addr;
    io_csr_req_bits_data_i = data;
    io_csr_req_bits_write_i = 1'b1;
    io_csr_req_valid_i = 1'b1;
    @(posedge clk_i);
  endtask

  task cfg_read(
    input logic [31:0] addr
  );
    io_csr_req_bits_addr_i = addr;
    io_csr_req_bits_data_i = 32'd0;
    io_csr_req_bits_write_i = 1'b0;
    io_csr_req_valid_i = 1'b1;
    @(posedge clk_i);
  endtask

  task cfg_clear;
    io_csr_req_bits_addr_i = 32'd0;
    io_csr_req_bits_data_i = 32'd0;
    io_csr_req_bits_write_i = 1'b0;
    io_csr_req_valid_i = 1'b0;
  endtask
  
  initial begin

    clk_i                 = 0;
    rst_ni                = 0;

    acc2stream_data_0_bits_i = 256'd0;

    // Initial values for control
    io_csr_req_bits_data_i = 32'd0; //32-bits
    io_csr_req_bits_addr_i = 32'd0; // 32-bits
    io_csr_req_bits_write_i = 1'b0;
    io_csr_req_valid_i = 1'b0;
    io_csr_rsp_ready_i = 1'b1;

    @(posedge clk_i);
    @(posedge clk_i);

    rst_ni                = 1;

    @(posedge clk_i);
    @(posedge clk_i);

    cfg_clear();
    // temporal loop strides
    cfg_write(0,10);
    // spatial loop strides
    cfg_write(1, 1);
    cfg_write(2, 1);
    cfg_write(3, 1);
    cfg_write(4, 1);
    // spatial loop strides
    // warning!!! give the proper unrolling strides so that is a aligned in one TCDM bank
    cfg_write(5, 1);
    cfg_write(6, 1);
    cfg_write(7, 1);
    cfg_write(8, 1);
    // base ptr
    cfg_write(9, 0);
    cfg_write(10, 8);
    cfg_write(11, 16);
    cfg_write(12, 24);
    // Continuous read
    cfg_read(0);
    cfg_read(1);
    cfg_read(2);
    cfg_read(3);
    cfg_read(4);
    cfg_read(5);
    cfg_read(6);
    cfg_read(7);
    cfg_read(8);
    cfg_read(9);
    cfg_read(10);
    cfg_read(11);
    cfg_read(12);
    // Start loop
    cfg_write(13, 1);
    cfg_clear();

    #1000ns;

  end

endmodule
