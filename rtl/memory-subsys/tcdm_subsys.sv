//-----------------------------------
// Tightly Coupled Data Memory Sub-System
//-----------------------------------

// These includes are necessary for pre-defined typedefs
`include "axi/typedef.svh"
`include "mem_interface/typedef.svh"
`include "tcdm_interface/typedef.svh"

//-----------------------------------
// Parameter definitions
//-----------------------------------
// NarrowDataWidth - data width
// TCDMDepth - number of elements per bank
// NrBanks - number of banks
// TCDMMemAddrWidth - address width of a single bank
// TCDMSize - total size of TCDM memory
// TCDMAddrWidth - total address width of memory
// NumInp - number of requesters (core or accelerator)
// NumOut - number of ports connected to memory
//        - this one should actually be equal to NrBanks
//-----------------------------------

module tcdm_subsys #(
  parameter int unsigned NarrowDataWidth  = 64,
  parameter int unsigned TCDMDepth        = 512,
  parameter int unsigned NrBanks          = 32,
  parameter int unsigned TCDMMemAddrWidth = $clog2(TCDMDepth),
  parameter int unsigned TCDMSize         = NrBanks * TCDMDepth * (NarrowDataWidth/8),
  parameter int unsigned TCDMAddrWidth    = $clog2(TCDMSize),
  parameter int unsigned NumOut           = 2,
  parameter int unsigned NumInp           = NumOut
 
)(
  input  logic                                      clk_i,
  input  logic                                      rst_ni,
  input  logic  [NumInp-1:0]                        tcdm_req_write_i,
  input  logic  [NumInp-1:0][TCDMAddrWidth-1:0]     tcdm_req_addr_i,
  //Note that tcdm_req_amo_i is 4 bits based on reqrsp definition
  input  logic  [NumInp-1:0][3:0]                   tcdm_req_amo_i,
  input  logic  [NumInp-1:0][NarrowDataWidth-1:0]   tcdm_req_data_i,
  //Note that tcdm_req_user_core_id_i is 5 bits based on Snitch definition
  input  logic  [NumInp-1:0][4:0]                   tcdm_req_user_core_id_i,
  input  bit    [NumInp-1:0]                        tcdm_req_user_is_core_i,
  input  logic  [NumInp-1:0][NarrowDataWidth/8-1:0] tcdm_req_strb_i,
  input  logic  [NumInp-1:0]                        tcdm_req_q_valid_i,
  output logic  [NumInp-1:0]                        tcdm_rsp_q_ready_o,
  output logic  [NumInp-1:0]                        tcdm_rsp_p_valid_o,
  output logic  [NumInp-1:0][NarrowDataWidth-1:0]   tcdm_rsp_data_o
);

  typedef logic [  NarrowDataWidth-1:0] data_t;
  typedef logic [NarrowDataWidth/8-1:0] strb_t;
  typedef logic [    TCDMAddrWidth-1:0] tcdm_addr_t;
  typedef logic [ TCDMMemAddrWidth-1:0] tcdm_mem_addr_t;

  typedef struct packed {
    logic [4:0] core_id;
    bit         is_core;
  } tcdm_user_t;

  typedef struct packed {
    logic [0:0] reserved;
  } sram_cfg_t;

  typedef struct packed {
    sram_cfg_t icache_tag;
    sram_cfg_t icache_data;
    sram_cfg_t tcdm;
  } sram_cfgs_t;

  sram_cfgs_t sram_cfgs;

  `TCDM_TYPEDEF_ALL (tcdm, tcdm_addr_t, data_t, strb_t, tcdm_user_t)
  `MEM_TYPEDEF_ALL (mem, tcdm_mem_addr_t, data_t, strb_t, tcdm_user_t)

  // Main connections
  tcdm_req_t [NumInp-1:0] tcdm_req;
  tcdm_rsp_t [NumInp-1:0] tcdm_rsp;

  mem_req_t  [NumOut-1:0] mem_req;
  mem_rsp_t  [NumOut-1:0] mem_rsp;

  // Hard re-mapping of TCDM req and rsp
  // To make the control ports more generic
  always_comb begin: gen_hard_remap
    for(int i=0; i < NumInp; i++) begin

      // Request (incoming) remapping
      tcdm_req[i].q.write         = tcdm_req_write_i[i];
      tcdm_req[i].q.addr          = tcdm_req_addr_i[i];
      tcdm_req[i].q.data          = tcdm_req_data_i[i];
      tcdm_req[i].q.user.core_id  = tcdm_req_user_core_id_i[i];
      tcdm_req[i].q.user.is_core  = tcdm_req_user_is_core_i[i];
      tcdm_req[i].q.strb          = tcdm_req_strb_i[i];
      tcdm_req[i].q_valid         = tcdm_req_q_valid_i[i];

      // Hard re-mapping of atomic memory operation (AMO)
      // This is necessary due to SV limitations of strict
      // Typedef declarations
      case(tcdm_req_amo_i[i])
        4'h0:    tcdm_req[i].q.amo = reqrsp_pkg::AMONone;
        4'h1:    tcdm_req[i].q.amo = reqrsp_pkg::AMOSwap;
        4'h2:    tcdm_req[i].q.amo = reqrsp_pkg::AMOAdd;
        4'h3:    tcdm_req[i].q.amo = reqrsp_pkg::AMOAnd;
        4'h4:    tcdm_req[i].q.amo = reqrsp_pkg::AMOOr;
        4'h5:    tcdm_req[i].q.amo = reqrsp_pkg::AMOXor;
        4'h6:    tcdm_req[i].q.amo = reqrsp_pkg::AMOMax;
        4'h7:    tcdm_req[i].q.amo = reqrsp_pkg::AMOMaxu;
        4'h8:    tcdm_req[i].q.amo = reqrsp_pkg::AMOMin;
        4'h9:    tcdm_req[i].q.amo = reqrsp_pkg::AMOMinu;
        4'hA:    tcdm_req[i].q.amo = reqrsp_pkg::AMOLR;
        4'hB:    tcdm_req[i].q.amo = reqrsp_pkg::AMOSC;
        default: tcdm_req[i].q.amo = reqrsp_pkg::AMONone;
      endcase

      // Response (outgoing) remapping
      tcdm_rsp_q_ready_o[i] = tcdm_rsp[i].q_ready;
      tcdm_rsp_p_valid_o[i] = tcdm_rsp[i].p_valid;
      tcdm_rsp_data_o[i]    = tcdm_rsp[i].p.data;

    end
  end

  snitch_tcdm_interconnect #(
    .NumInp                ( NumInp                              ),
    .NumOut                ( NumOut                              ),
    .tcdm_req_t            ( tcdm_req_t                          ),
    .tcdm_rsp_t            ( tcdm_rsp_t                          ),
    .mem_req_t             ( mem_req_t                           ),
    .mem_rsp_t             ( mem_rsp_t                           ),
    .MemAddrWidth          ( TCDMMemAddrWidth                    ),
    .DataWidth             ( NarrowDataWidth                     ),
    .user_t                ( tcdm_user_t                         ),
    .MemoryResponseLatency ( 1                                   ),
    .Radix                 ( 2                                   ),
    .Topology              ( snitch_pkg::LogarithmicInterconnect )
  ) i_tcdm_interconnect (
    .clk_i                 ( clk_i                               ),
    .rst_ni                ( rst_ni                              ),
    .req_i                 ( tcdm_req                            ),
    .rsp_o                 ( tcdm_rsp                            ),
    .mem_req_o             ( mem_req                             ),
    .mem_rsp_i             ( mem_rsp                             )
  );

  // Generate multi-bank memories
  // Number of banks matches number of memories
  for (genvar i = 0; i < NumOut; i++) begin : gen_tcdm_bank

    logic           mem_cs;
    logic           mem_wen;
    tcdm_mem_addr_t mem_add;
    strb_t          mem_be;
    data_t          mem_rdata;
    data_t          mem_wdata;
    data_t          amo_rdata_local;

    tc_sram_impl #(
      .NumWords   ( TCDMDepth       ),
      .DataWidth  ( NarrowDataWidth ),
      .ByteWidth  ( 8               ),
      .NumPorts   ( 1               ),
      .SimInit    ( "zeros"         ),
      .Latency    ( 1               ),
      .impl_in_t  ( sram_cfg_t      )
    ) i_data_mem (
      .clk_i      ( clk_i           ),
      .rst_ni     ( rst_ni          ),
      .impl_i     ( sram_cfgs.tcdm  ),
      .impl_o     (                 ), //Unused since it's SRAM dependent
      .req_i      ( mem_cs          ),
      .we_i       ( mem_wen         ),
      .addr_i     ( mem_add         ),
      .wdata_i    ( mem_wdata       ),
      .be_i       ( mem_be          ),
      .rdata_o    ( mem_rdata       )
    );

    // Atomic memory operations
    snitch_amo_shim #(
      .AddrMemWidth   ( TCDMMemAddrWidth          ),
      .DataWidth      ( NarrowDataWidth           ),
      .CoreIDWidth    ( 5                         )
    ) i_amo_shim (
      .clk_i          ( clk_i                     ),
      .rst_ni         ( rst_ni                    ),
      .valid_i        ( mem_req[i].q_valid        ),
      .ready_o        ( mem_rsp[i].q_ready        ),
      .addr_i         ( mem_req[i].q.addr         ),
      .write_i        ( mem_req[i].q.write        ),
      .wdata_i        ( mem_req[i].q.data         ),
      .wstrb_i        ( mem_req[i].q.strb         ),
      .core_id_i      ( mem_req[i].q.user.core_id ),
      .is_core_i      ( mem_req[i].q.user.is_core ),
      .rdata_o        ( amo_rdata_local           ),
      .amo_i          ( mem_req[i].q.amo          ),
      .mem_req_o      ( mem_cs                    ),
      .mem_add_o      ( mem_add                   ),
      .mem_wen_o      ( mem_wen                   ),
      .mem_wdata_o    ( mem_wdata                 ),
      .mem_be_o       ( mem_be                    ),
      .mem_rdata_i    ( mem_rdata                 ),
      .dma_access_i   ( 1'b0                      ), // Unused since we don't simulate DMA here
      .amo_conflict_o (                           )
    );

    // Insert a pipeline register at the output of each SRAM.
    shift_reg #(
      .dtype  ( data_t            ),
      .Depth  ( 0                 ) // Unused for now
    ) i_sram_pipe (
      .clk_i  ( clk_i             ),
      .rst_ni ( rst_ni            ),
      .d_i    ( amo_rdata_local   ),
      .d_o    ( mem_rsp[i].p.data )
    );
  end

endmodule
