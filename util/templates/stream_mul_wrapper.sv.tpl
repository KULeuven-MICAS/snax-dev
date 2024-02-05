<%
  import math

  num_loop_dim = cfg["temporalAddrGenUnitParams"]["loopDim"]
  num_data_mover = (len(cfg["dataReaderParams"]["tcdmPortsNum"]) + len(cfg["dataWriterParams"]["tcdmPortsNum"])) 
  num_dmove_x_loop_dim = num_data_mover * num_loop_dim
  num_spatial_dim = sum(cfg["dataReaderParams"]["spatialDim"]) + sum(cfg["dataWriterParams"]["spatialDim"])
  
  csr_num = num_loop_dim + num_dmove_x_loop_dim + num_data_mover + num_spatial_dim + 1
  csr_width = math.ceil(math.log2(csr_num))
%>
//-------------------------------
// Streamer-MUL wrapper
// This is the entire accelerator
// That connecst to the TCDM subsystem
//-------------------------------
module stream_mul_wrapper # (
  parameter int unsigned NarrowDataWidth = ${cfg["tcdmDataWidth"]},
  parameter int unsigned TCDMDepth = ${cfg["tcdmDepth"]},
  parameter int unsigned TCDMReqPorts = ${sum(cfg["dataReaderParams"]["tcdmPortsNum"]) + sum(cfg["dataWriterParams"]["tcdmPortsNum"])},
  parameter int unsigned TCDMSize = TCDMReqPorts * TCDMDepth * (NarrowDataWidth/8),
  parameter int unsigned TCDMAddrWidth = $clog2(TCDMSize),
  parameter int unsigned SpatPar = ${cfg["dataReaderParams"]["spatialBounds"][0][0]}
)(
  //-----------------------------
  // Clocks and reset
  //-----------------------------
  input logic clk_i,
  input logic rst_ni,

  //-----------------------------
  // TCDM ports
  //-----------------------------
  // Request
  output logic [TCDMReqPorts-1:0] tcdm_req_write_o,
  output logic [TCDMReqPorts-1:0][TCDMAddrWidth-1:0] tcdm_req_addr_o,
  output logic [TCDMReqPorts-1:0][3:0] tcdm_req_amo_o, //Note that tcdm_req_amo_i is 4 bits based on reqrsp definition
  output logic [TCDMReqPorts-1:0][NarrowDataWidth-1:0] tcdm_req_data_o,
  output logic [TCDMReqPorts-1:0][4:0] tcdm_req_user_core_id_o, //Note that tcdm_req_user_core_id_i is 5 bits based on Snitch definition
  output logic [TCDMReqPorts-1:0] tcdm_req_user_is_core_o,
  output logic [TCDMReqPorts-1:0][NarrowDataWidth/8-1:0] tcdm_req_strb_o,
  output logic [TCDMReqPorts-1:0] tcdm_req_q_valid_o,

  // Response
  input logic [TCDMReqPorts-1:0] tcdm_rsp_q_ready_i,
  input logic [TCDMReqPorts-1:0] tcdm_rsp_p_valid_i,
  input logic [TCDMReqPorts-1:0][NarrowDataWidth-1:0] tcdm_rsp_data_i,

  //-----------------------------
  // CSR control ports
  //-----------------------------
  // Request
  input logic [31:0] io_csr_req_bits_data_i,
  input logic [${csr_width-1}:0] io_csr_req_bits_addr_i,
  input logic io_csr_req_bits_write_i,
  input logic io_csr_req_valid_i,
  output logic io_csr_req_ready_o,

  // Response
  input logic io_csr_rsp_ready_i,
  output logic io_csr_rsp_valid_o,
  output logic [31:0] io_csr_rsp_bits_data_o
);

  // ports from accelerator to streamer
% for idx, dw in enumerate(cfg["fifoWriterParams"]['fifoWidth']):
  logic [${dw-1}:0] acc2stream_data_${idx}_bits;
  logic acc2stream_data_${idx}_valid;
  logic acc2stream_data_${idx}_ready;

% endfor
  // ports from streamer to accelerator
% for idx, dw in enumerate(cfg["fifoReaderParams"]['fifoWidth']):
  logic [${dw-1}:0] stream2acc_data_${idx}_bits;
  logic stream2acc_data_${idx}_valid;
  logic stream2acc_data_${idx}_ready;

% endfor

  streamer_wrapper #(
    .NarrowDataWidth ( NarrowDataWidth ),
    .TCDMDepth ( TCDMDepth ),
    .TCDMReqPorts ( TCDMReqPorts ),
    .TCDMSize ( TCDMSize ),
    .TCDMAddrWidth ( TCDMAddrWidth )
  ) i_streamer_wrapper (
    //-----------------------------
    // Clocks and reset
    //-----------------------------
    .clk_i ( clk_i ),
    .rst_ni ( rst_ni ),

    //-----------------------------
    // Accelerator ports
    //-----------------------------
    // ports from acclerator to streamer
    .acc2stream_data_0_bits_i ( acc2stream_data_0_bits ),
    .acc2stream_data_0_valid_i ( acc2stream_data_0_valid ),
    .acc2stream_data_0_ready_o ( acc2stream_data_0_ready ),

    // ports from streamer to accelerator
    .stream2acc_data_0_bits_o ( stream2acc_data_0_bits ),
    .stream2acc_data_0_valid_o ( stream2acc_data_0_valid ),
    .stream2acc_data_0_ready_i ( stream2acc_data_0_ready ),

    .stream2acc_data_1_bits_o ( stream2acc_data_1_bits ),
    .stream2acc_data_1_valid_o ( stream2acc_data_1_valid ),
    .stream2acc_data_1_ready_i ( stream2acc_data_1_ready ),

    //-----------------------------
    // TCDM ports
    //-----------------------------
    // Request
    .tcdm_req_write_o ( tcdm_req_write_o ),
    .tcdm_req_addr_o ( tcdm_req_addr_o ),
    .tcdm_req_amo_o ( tcdm_req_amo_o ), 
    .tcdm_req_data_o ( tcdm_req_data_o ),
    .tcdm_req_user_core_id_o ( tcdm_req_user_core_id_o ), 
    .tcdm_req_user_is_core_o ( tcdm_req_user_is_core_o ),
    .tcdm_req_strb_o ( tcdm_req_strb_o ),
    .tcdm_req_q_valid_o ( tcdm_req_q_valid_o ),
    // Response
    .tcdm_rsp_q_ready_i ( tcdm_rsp_q_ready_i ),
    .tcdm_rsp_p_valid_i ( tcdm_rsp_p_valid_i ),
    .tcdm_rsp_data_i ( tcdm_rsp_data_i ),

    //-----------------------------
    // CSR control ports
    //-----------------------------
    // Request
    .io_csr_req_bits_data_i ( io_csr_req_bits_data_i ),
    .io_csr_req_bits_addr_i ( io_csr_req_bits_addr_i ),
    .io_csr_req_bits_write_i ( io_csr_req_bits_write_i ),
    .io_csr_req_valid_i ( io_csr_req_valid_i ),
    .io_csr_req_ready_o ( io_csr_req_ready_o ),
    // Response
    .io_csr_rsp_ready_i ( io_csr_rsp_ready_i ),
    .io_csr_rsp_valid_o ( io_csr_rsp_valid_o ),
    .io_csr_rsp_bits_data_o ( io_csr_rsp_bits_data_o )
  );

  //-----------------------------
  // MUL Accelerator
  //-----------------------------
  simple_mul_wrapper #(
    .SpatPar ( SpatPar ),
    .DataWidth ( NarrowDataWidth )
  ) i_simple_mul_wrapper (
    .clk_i ( clk_i ),
    .rst_ni ( rst_ni ),
    .a_i ( stream2acc_data_0_bits ),
    .a_valid_i ( stream2acc_data_0_valid),
    .a_ready_o ( stream2acc_data_0_ready ),
    .b_i ( stream2acc_data_1_bits ),
    .b_valid_i ( stream2acc_data_1_valid ),
    .b_ready_o ( stream2acc_data_1_ready ),
    .result_o ( acc2stream_data_0_bits ),
    .result_valid_o ( acc2stream_data_0_valid ),
    .result_ready_i ( acc2stream_data_0_ready)
  );


endmodule
