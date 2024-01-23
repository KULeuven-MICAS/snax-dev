<%
  import math

  num_loop_dim = cfg["temporalAddrGenUnitParams"]["loopDim"]
  num_data_mover = (len(cfg["dataReaderParams"]["tcdmPortsNum"]) + len(cfg["dataWriterParams"]["tcdmPortsNum"])) 
  num_dmove_x_loop_dim = num_data_mover * num_loop_dim
  num_spatial_dim = sum(cfg["dataReaderParams"]["spatialDim"]) + sum(cfg["dataWriterParams"]["spatialDim"])
  
  csr_num = num_loop_dim + num_dmove_x_loop_dim + num_data_mover + num_spatial_dim + 1
  csr_width = math.ceil(math.log2(csr_num))
%>
//-----------------------------------
// Basic SNAX streamer testbench
//-----------------------------------
module tb_streamer_top #(
  parameter int unsigned NarrowDataWidth = ${cfg["tcdmDataWidth"]},
  parameter int unsigned TCDMDepth       = ${cfg["tcdmDepth"]},
  parameter int unsigned TCDMReqPorts    = ${sum(cfg["dataReaderParams"]["tcdmPortsNum"]) + sum(cfg["dataWriterParams"]["tcdmPortsNum"])}
);

  localparam int unsigned NrBanks        = 32;
  localparam int unsigned TCDMSize       = NrBanks * TCDMDepth * (NarrowDataWidth/8);
  localparam int unsigned TCDMAddrWidth  = $clog2(TCDMSize);

  // clock and resets
  logic clk_i;
  logic rst_ni;

  // ports from streamer to accelerator
% for idx, dw in enumerate(cfg["fifoWriterParams"]['fifoWidth']):
  logic [${dw-1}:0] acc2stream_data_${idx}_bits_i;
  logic acc2stream_data_${idx}_valid_i;
  logic acc2stream_data_${idx}_ready_o;

% endfor
  // ports from acclerator to streamer
% for idx, dw in enumerate(cfg["fifoReaderParams"]['fifoWidth']):
  logic [${dw-1}:0] stream2acc_data_${idx}_bits_o;
  logic stream2acc_data_${idx}_valid_o;
  logic stream2acc_data_${idx}_ready_i;

% endfor
  //-----------------------------
  // CSR control ports
  //-----------------------------
  // Request
  logic [31:0] io_csr_req_bits_data_i;
  logic [${csr_width-1}:0] io_csr_req_bits_addr_i;
  logic io_csr_req_bits_write_i;
  logic io_csr_req_valid_i;
  logic io_csr_req_ready_o;

  // Response
  logic io_csr_rsp_ready_i;
  logic io_csr_rsp_valid_o;
  logic [31:0] io_csr_rsp_bits_data_o;

  //-----------------------------
  // TCDM ports
  //-----------------------------
  // Request
  logic [TCDMReqPorts-1:0] tcdm_req_write;
  logic [TCDMReqPorts-1:0][TCDMAddrWidth-1:0] tcdm_req_addr;
  logic [TCDMReqPorts-1:0][3:0] tcdm_req_amo; 
  logic [TCDMReqPorts-1:0][NarrowDataWidth-1:0] tcdm_req_data;
  logic [TCDMReqPorts-1:0][4:0] tcdm_req_user_core_id; 
  logic [TCDMReqPorts-1:0] tcdm_req_user_is_core;
  logic [TCDMReqPorts-1:0][NarrowDataWidth/8-1:0] tcdm_req_strb;
  logic [TCDMReqPorts-1:0] tcdm_req_q_valid;
  // Response
  logic [TCDMReqPorts-1:0] tcdm_rsp_q_ready;
  logic [TCDMReqPorts-1:0] tcdm_rsp_p_valid;
  logic [TCDMReqPorts-1:0][NarrowDataWidth-1:0] tcdm_rsp_data;

  logic [0:0] tcdm_req_write_o [TCDMReqPorts-1:0];
  logic [TCDMAddrWidth-1:0] tcdm_req_addr_o [TCDMReqPorts-1:0];
  logic [3:0] tcdm_req_amo_o [TCDMReqPorts-1:0]; 
  logic [NarrowDataWidth-1:0] tcdm_req_data_o [TCDMReqPorts-1:0];
  logic [4:0] tcdm_req_user_core_id_o [TCDMReqPorts-1:0]; 
  logic [0:0] tcdm_req_user_is_core_o [TCDMReqPorts-1:0];
  logic [NarrowDataWidth/8-1:0] tcdm_req_strb_o [TCDMReqPorts-1:0];
  logic [0:0] tcdm_req_q_valid_o [TCDMReqPorts-1:0];
  // Response
  logic [0:0] tcdm_rsp_q_ready_i [TCDMReqPorts-1:0];
  logic [0:0] tcdm_rsp_p_valid_i [TCDMReqPorts-1:0];
  logic [NarrowDataWidth-1:0] tcdm_rsp_data_i [TCDMReqPorts-1:0];

  // Hard re-mapping just to handle the cocotb verilator translation
  always_comb begin
    for(int i = 0; i < TCDMReqPorts; i++) begin
      tcdm_req_write_o[i] = tcdm_req_write[i];
      tcdm_req_addr_o[i] = tcdm_req_addr[i];
      tcdm_req_amo_o[i] = tcdm_req_amo[i];
      tcdm_req_data_o[i] = tcdm_req_data[i];
      tcdm_req_user_core_id_o[i] = tcdm_req_user_core_id[i];
      tcdm_req_user_is_core_o[i] = tcdm_req_user_is_core[i];
      tcdm_req_strb_o[i] = tcdm_req_strb[i];
      tcdm_req_q_valid_o[i] = tcdm_req_q_valid[i];
      tcdm_rsp_data[i] = tcdm_rsp_data_i[i];
      tcdm_rsp_q_ready[i] = tcdm_rsp_q_ready_i[i];
      tcdm_rsp_p_valid[i] = tcdm_rsp_p_valid_i[i];
    end
  end

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
% for idx, dw in enumerate(cfg["fifoWriterParams"]['fifoWidth']):
    .acc2stream_data_${idx}_bits_i ( acc2stream_data_${idx}_bits_i ),
    .acc2stream_data_${idx}_valid_i ( acc2stream_data_${idx}_valid_i ),
    .acc2stream_data_${idx}_ready_o ( acc2stream_data_${idx}_ready_o ),

% endfor
    // ports from streamer to accelerator
% for idx, dw in enumerate(cfg["fifoReaderParams"]['fifoWidth']):
    .stream2acc_data_${idx}_bits_o ( stream2acc_data_${idx}_bits_o ),
    .stream2acc_data_${idx}_valid_o ( stream2acc_data_${idx}_valid_o ),
    .stream2acc_data_${idx}_ready_i ( stream2acc_data_${idx}_ready_i ),

% endfor

    //-----------------------------
    // TCDM ports
    //-----------------------------
    // Request
    .tcdm_req_write_o ( tcdm_req_write ),
    .tcdm_req_addr_o ( tcdm_req_addr ),
    .tcdm_req_amo_o ( tcdm_req_amo ), 
    .tcdm_req_data_o ( tcdm_req_data ),
    .tcdm_req_user_core_id_o ( tcdm_req_user_core_id ), 
    .tcdm_req_user_is_core_o ( tcdm_req_user_is_core ),
    .tcdm_req_strb_o ( tcdm_req_strb ),
    .tcdm_req_q_valid_o ( tcdm_req_q_valid ),
    // Response
    .tcdm_rsp_q_ready_i ( tcdm_rsp_q_ready ),
    .tcdm_rsp_p_valid_i ( tcdm_rsp_p_valid ),
    .tcdm_rsp_data_i ( tcdm_rsp_data ),

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

endmodule
