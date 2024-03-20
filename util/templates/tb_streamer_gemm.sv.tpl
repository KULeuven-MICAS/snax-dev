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
module tb_streamer_gemm;

  localparam int unsigned NarrowDataWidth = ${cfg["tcdmDataWidth"]};
  localparam int unsigned WideDataWidth = ${cfg["tcdmDmaDataWidth"]};
  localparam int unsigned TCDMDepth = ${cfg["tcdmDepth"]};
  localparam int unsigned TCDMReqPorts = ${sum(cfg["dataReaderParams"]["tcdmPortsNum"]) + sum(cfg["dataWriterParams"]["tcdmPortsNum"])};
  localparam int unsigned NrBanks = ${cfg["numBanks"]};
  localparam int unsigned TCDMSize = NrBanks * TCDMDepth * (NarrowDataWidth/8);
  localparam int unsigned TCDMAddrWidth = $clog2(TCDMSize);
  localparam int unsigned SpatPar = ${cfg["dataReaderParams"]["spatialBounds"][0][0]};

  // clock and resets
  logic clk_i;
  logic rst_ni;

  //-----------------------------
  // CSR control ports
  //-----------------------------
  // Request
  logic [31:0] io_csr_req_bits_data_i;
  logic [31:0] io_csr_req_bits_addr_i;
  logic        io_csr_req_bits_write_i;
  logic        io_csr_req_valid_i;
  logic        io_csr_req_ready_o;

  // Response
  logic        io_csr_rsp_ready_i;
  logic        io_csr_rsp_valid_o;
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

  logic tcdm_dma_req_write_i;
  logic [TCDMAddrWidth-1:0] tcdm_dma_req_addr_i;
  logic [WideDataWidth-1:0] tcdm_dma_req_data_i;
  logic [WideDataWidth/8-1:0] tcdm_dma_req_strb_i;
  logic tcdm_dma_req_q_valid_i;
  logic tcdm_dma_rsp_q_ready_o;
  logic tcdm_dma_rsp_p_valid_o;
  logic [WideDataWidth-1:0] tcdm_dma_rsp_data_o;

  // TCDM subsystem
  tcdm_subsys #(
    .NarrowDataWidth  ( NarrowDataWidth ),
    .TCDMDepth        ( TCDMDepth       ),
    .TCDMAddrWidth    ( TCDMAddrWidth   ),
    .NrBanks          ( NrBanks         ),
    .NumInp           ( TCDMReqPorts    )
  ) i_tcdm_subsys (
    //-----------------------------
    // Clock and reset
    //-----------------------------
    .clk_i  ( clk_i  ),
    .rst_ni ( rst_ni ),
    //-----------------------------
    // TCDM ports
    //-----------------------------
    .tcdm_req_write_i         ( tcdm_req_write         ),
    .tcdm_req_addr_i          ( tcdm_req_addr          ),
    .tcdm_req_amo_i           ( tcdm_req_amo           ),
    .tcdm_req_data_i          ( tcdm_req_data          ),
    .tcdm_req_user_core_id_i  ( tcdm_req_user_core_id  ),
    .tcdm_req_user_is_core_i  ( tcdm_req_user_is_core  ),
    .tcdm_req_strb_i          ( tcdm_req_strb          ),
    .tcdm_req_q_valid_i       ( tcdm_req_q_valid       ),
    .tcdm_rsp_q_ready_o       ( tcdm_rsp_q_ready       ),
    .tcdm_rsp_p_valid_o       ( tcdm_rsp_p_valid       ),
    .tcdm_rsp_data_o          ( tcdm_rsp_data          ),
    //-----------------------------
    // Wide TCDM ports
    //-----------------------------
    .tcdm_dma_req_write_i     ( tcdm_dma_req_write_i   ),
    .tcdm_dma_req_addr_i      ( tcdm_dma_req_addr_i    ),
    .tcdm_dma_req_data_i      ( tcdm_dma_req_data_i    ),
    .tcdm_dma_req_strb_i      ( tcdm_dma_req_strb_i    ),
    .tcdm_dma_req_q_valid_i   ( tcdm_dma_req_q_valid_i ),
    .tcdm_dma_rsp_q_ready_o   ( tcdm_dma_rsp_q_ready_o ),
    .tcdm_dma_rsp_p_valid_o   ( tcdm_dma_rsp_p_valid_o ),
    .tcdm_dma_rsp_data_o      ( tcdm_dma_rsp_data_o    )
  );

  stream_gemm_wrapper #(
    .NarrowDataWidth  ( NarrowDataWidth ),
    .TCDMDepth        ( TCDMDepth       ),
    .TCDMReqPorts     ( TCDMReqPorts    ),
    .TCDMSize         ( TCDMSize        ),
    .TCDMAddrWidth    ( TCDMAddrWidth   )
  ) i_stream_alu_wrapper (
    //-----------------------------
    // Clocks and reset
    //-----------------------------
    .clk_i  ( clk_i  ),
    .rst_ni ( rst_ni ),

    //-----------------------------
    // TCDM ports
    //-----------------------------
    // Request
    .tcdm_req_write_o         ( tcdm_req_write        ),
    .tcdm_req_addr_o          ( tcdm_req_addr         ),
    .tcdm_req_amo_o           ( tcdm_req_amo          ), 
    .tcdm_req_data_o          ( tcdm_req_data         ),
    .tcdm_req_user_core_id_o  ( tcdm_req_user_core_id ), 
    .tcdm_req_user_is_core_o  ( tcdm_req_user_is_core ),
    .tcdm_req_strb_o          ( tcdm_req_strb         ),
    .tcdm_req_q_valid_o       ( tcdm_req_q_valid      ),
    // Response
    .tcdm_rsp_q_ready_i       ( tcdm_rsp_q_ready      ),
    .tcdm_rsp_p_valid_i       ( tcdm_rsp_p_valid      ),
    .tcdm_rsp_data_i          ( tcdm_rsp_data         ),

    //-----------------------------
    // CSR control ports
    //-----------------------------
    // Request
    .io_csr_req_bits_data_i   ( io_csr_req_bits_data_i  ),
    .io_csr_req_bits_addr_i   ( io_csr_req_bits_addr_i  ),
    .io_csr_req_bits_write_i  ( io_csr_req_bits_write_i ),
    .io_csr_req_valid_i       ( io_csr_req_valid_i      ),
    .io_csr_req_ready_o       ( io_csr_req_ready_o      ),
    // Response
    .io_csr_rsp_ready_i       ( io_csr_rsp_ready_i      ),
    .io_csr_rsp_valid_o       ( io_csr_rsp_valid_o      ),
    .io_csr_rsp_bits_data_o   ( io_csr_rsp_bits_data_o  )
  );

endmodule
