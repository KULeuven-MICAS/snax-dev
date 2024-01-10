//-----------------------------------
// Tightly Coupled Data Memory Sub-System 
// Local testbench
//-----------------------------------

module tb_tcdm_subsys #(
  parameter int unsigned NarrowDataWidth   = 64,
  parameter int unsigned TCDMDepth         = 64,
  parameter int unsigned NrBanks           = 8,
  parameter int unsigned NumInp            = 2,
  parameter int unsigned NumOut            = NrBanks
);

  localparam int unsigned TCDMMemAddrWidth = $clog2(TCDMDepth);
  localparam int unsigned TCDMSize         = NrBanks * TCDMDepth * (NarrowDataWidth/8);
  localparam int unsigned TCDMAddrWidth    = $clog2(TCDMSize);

  logic                                     clk_i;
  logic                                     rst_ni;
  logic [NumInp-1:0]                        tcdm_req_write_i;
  logic [NumInp-1:0][TCDMAddrWidth-1:0]     tcdm_req_addr_i;
  logic [NumInp-1:0][3:0]                   tcdm_req_amo_i;
  logic [NumInp-1:0][NarrowDataWidth-1:0]   tcdm_req_data_i;
  logic [NumInp-1:0][4:0]                   tcdm_req_user_core_id_i;
  logic [NumInp-1:0]                        tcdm_req_user_is_core_i;
  logic [NumInp-1:0][NarrowDataWidth/8-1:0] tcdm_req_strb_i;
  logic [NumInp-1:0]                        tcdm_req_q_valid_i;
  logic [NumInp-1:0]                        tcdm_rsp_q_ready_o;
  logic [NumInp-1:0]                        tcdm_rsp_p_valid_o;
  logic [NumInp-1:0][NarrowDataWidth-1:0]   tcdm_rsp_data_o;

  tcdm_subsys #(
    .NarrowDataWidth          ( NarrowDataWidth         ),
    .TCDMDepth                ( TCDMDepth               ),
    .NrBanks                  ( NrBanks                 ),
    .NumInp                   ( NumInp                  ),
    .NumOut                   ( NumOut                  )
  ) i_tcdm_subsys (
    .clk_i                    ( clk_i                   ),
    .rst_ni                   ( rst_ni                  ),
    .tcdm_req_write_i         ( tcdm_req_write_i        ),
    .tcdm_req_addr_i          ( tcdm_req_addr_i         ),
    .tcdm_req_amo_i           ( tcdm_req_amo_i          ),
    .tcdm_req_data_i          ( tcdm_req_data_i         ),
    .tcdm_req_user_core_id_i  ( tcdm_req_user_core_id_i ),
    .tcdm_req_user_is_core_i  ( tcdm_req_user_is_core_i ),
    .tcdm_req_strb_i          ( tcdm_req_strb_i         ),
    .tcdm_req_q_valid_i       ( tcdm_req_q_valid_i      ),
    .tcdm_rsp_q_ready_o       ( tcdm_rsp_q_ready_o      ),
    .tcdm_rsp_p_valid_o       ( tcdm_rsp_p_valid_o      ),
    .tcdm_rsp_data_o          ( tcdm_rsp_data_o         )
  );

endmodule
