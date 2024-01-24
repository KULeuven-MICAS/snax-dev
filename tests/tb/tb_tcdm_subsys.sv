//-----------------------------------
// Tightly Coupled Data Memory Sub-System
// Local testbench
//-----------------------------------

module tb_tcdm_subsys #(
  parameter int unsigned NarrowDataWidth   = 64,
  parameter int unsigned WideDataWidth     = 512,
  parameter int unsigned TCDMDepth         = 64,
  parameter int unsigned NrBanks           = 8,
  parameter int unsigned NumInp            = 2
);

  // Local parameters that need to be managed automatically
  localparam int unsigned TCDMMemAddrWidth = $clog2(TCDMDepth);
  localparam int unsigned TCDMSize         = NrBanks * TCDMDepth * (NarrowDataWidth/8);
  localparam int unsigned TCDMAddrWidth    = $clog2(TCDMSize);

  // Clock and reset
  logic                                     clk_i;
  logic                                     rst_ni;

  // These wirings are needed to connect to TCDM ports
  // Cocotb has packed and unpacked array limitations
  // especially when switching between verilator and modelsim
  logic [NumInp-1:0]                        tcdm_req_write;
  logic [NumInp-1:0][TCDMAddrWidth-1:0]     tcdm_req_addr;
  logic [NumInp-1:0][3:0]                   tcdm_req_amo;
  logic [NumInp-1:0][NarrowDataWidth-1:0]   tcdm_req_data;
  logic [NumInp-1:0][4:0]                   tcdm_req_user_core_id;
  logic [NumInp-1:0]                        tcdm_req_user_is_core;
  logic [NumInp-1:0][NarrowDataWidth/8-1:0] tcdm_req_strb;
  logic [NumInp-1:0]                        tcdm_req_q_valid;
  logic [NumInp-1:0]                        tcdm_rsp_q_ready;
  logic [NumInp-1:0]                        tcdm_rsp_p_valid;
  logic [NumInp-1:0][NarrowDataWidth-1:0]   tcdm_rsp_data;

  // These wirings are a necessity for cocotb driving
  logic [0:0]                   tcdm_req_write_i        [NumInp];
  logic [TCDMAddrWidth-1:0]     tcdm_req_addr_i         [NumInp];
  logic [3:0]                   tcdm_req_amo_i          [NumInp];
  logic [NarrowDataWidth-1:0]   tcdm_req_data_i         [NumInp];
  logic [4:0]                   tcdm_req_user_core_id_i [NumInp];
  logic [0:0]                   tcdm_req_user_is_core_i [NumInp];
  logic [NarrowDataWidth/8-1:0] tcdm_req_strb_i         [NumInp];
  logic [0:0]                   tcdm_req_q_valid_i      [NumInp];
  logic [0:0]                   tcdm_rsp_q_ready_o      [NumInp];
  logic [0:0]                   tcdm_rsp_p_valid_o      [NumInp];
  logic [NarrowDataWidth-1:0]   tcdm_rsp_data_o         [NumInp];

  logic                       tcdm_dma_req_write_i;
  logic [  TCDMAddrWidth-1:0] tcdm_dma_req_addr_i;
  logic [  WideDataWidth-1:0] tcdm_dma_req_data_i;
  logic [WideDataWidth/8-1:0] tcdm_dma_req_strb_i;
  logic                       tcdm_dma_req_q_valid_i;
  logic                       tcdm_dma_rsp_q_ready_o;
  logic                       tcdm_dma_rsp_p_valid_o;
  logic [  WideDataWidth-1:0] tcdm_dma_rsp_data_o;

  // Hard re-mapping just to handle the cocotb verilator translation
  always_comb begin
    for(int i = 0; i < NumInp; i++) begin
      tcdm_req_write[i]        = tcdm_req_write_i[i];
      tcdm_req_addr[i]         = tcdm_req_addr_i[i];
      tcdm_req_amo[i]          = tcdm_req_amo_i[i];
      tcdm_req_data[i]         = tcdm_req_data_i[i];
      tcdm_req_user_core_id[i] = tcdm_req_user_core_id_i[i];
      tcdm_req_user_is_core[i] = tcdm_req_user_is_core_i[i];
      tcdm_req_strb[i]         = tcdm_req_strb_i[i];
      tcdm_req_q_valid[i]      = tcdm_req_q_valid_i[i];
      tcdm_rsp_data_o[i]       = tcdm_rsp_data[i];
      tcdm_rsp_q_ready_o[i]    = tcdm_rsp_q_ready[i];
      tcdm_rsp_p_valid_o[i]    = tcdm_rsp_p_valid[i];
    end
  end

  tcdm_subsys #(
    .NarrowDataWidth          ( NarrowDataWidth       ),
    .TCDMDepth                ( TCDMDepth             ),
    .NrBanks                  ( NrBanks               ),
    .NumInp                   ( NumInp                ),
  ) i_tcdm_subsys (
    //-----------------------------
    // Clock and reset
    //-----------------------------
    .clk_i                    ( clk_i                 ),
    .rst_ni                   ( rst_ni                ),
    //-----------------------------
    // TCDM ports
    //-----------------------------
    .tcdm_req_write_i         ( tcdm_req_write        ),
    .tcdm_req_addr_i          ( tcdm_req_addr         ),
    .tcdm_req_amo_i           ( tcdm_req_amo          ),
    .tcdm_req_data_i          ( tcdm_req_data         ),
    .tcdm_req_user_core_id_i  ( tcdm_req_user_core_id ),
    .tcdm_req_user_is_core_i  ( tcdm_req_user_is_core ),
    .tcdm_req_strb_i          ( tcdm_req_strb         ),
    .tcdm_req_q_valid_i       ( tcdm_req_q_valid      ),
    .tcdm_rsp_q_ready_o       ( tcdm_rsp_q_ready      ),
    .tcdm_rsp_p_valid_o       ( tcdm_rsp_p_valid      ),
    .tcdm_rsp_data_o          ( tcdm_rsp_data         ),
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

endmodule
