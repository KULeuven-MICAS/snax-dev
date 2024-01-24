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
//-----------------------------------

module tcdm_subsys #(
  parameter int unsigned NarrowDataWidth  = 64,
  parameter int unsigned TCDMDepth        = 512,
  parameter int unsigned NrBanks          = 32,
  parameter int unsigned WideDataWidth    = 512, // Need to set wide data width to max bits of banks
  parameter int unsigned TCDMMemAddrWidth = $clog2(TCDMDepth),
  parameter int unsigned TCDMSize         = NrBanks * TCDMDepth * (NarrowDataWidth/8),
  parameter int unsigned TCDMAddrWidth    = $clog2(TCDMSize),
  parameter int unsigned NumInp           = 2
)(
  //-----------------------------
  // Clocks and Reset
  //-----------------------------
  input  logic  clk_i,
  input  logic  rst_ni,

  //-----------------------------
  // TCDM ports
  //-----------------------------
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
  output logic  [NumInp-1:0][NarrowDataWidth-1:0]   tcdm_rsp_data_o,

  //-----------------------------
  // Wide TCDM ports
  //-----------------------------
  input  logic                        tcdm_dma_req_write_i,
  input  logic  [  TCDMAddrWidth-1:0] tcdm_dma_req_addr_i,
  input  logic  [  WideDataWidth-1:0] tcdm_dma_req_data_i,
  input  logic  [WideDataWidth/8-1:0] tcdm_dma_req_strb_i,
  input  logic                        tcdm_dma_req_q_valid_i,
  output logic                        tcdm_dma_rsp_q_ready_o,
  output logic                        tcdm_dma_rsp_p_valid_o,
  output logic  [  WideDataWidth-1:0] tcdm_dma_rsp_data_o
);

  localparam int unsigned BanksPerSuperBank = WideDataWidth/NarrowDataWidth;
  localparam int unsigned NrSuperBanks      = NrBanks/BanksPerSuperBank;

  typedef logic [  NarrowDataWidth-1:0] data_t;
  typedef logic [    WideDataWidth-1:0] data_dma_t;
  typedef logic [NarrowDataWidth/8-1:0] strb_t;
  typedef logic [  WideDataWidth/8-1:0] strb_dma_t;
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

  `TCDM_TYPEDEF_ALL(tcdm_dma, tcdm_addr_t, data_dma_t, strb_dma_t, logic)
  `MEM_TYPEDEF_ALL (mem_dma, tcdm_mem_addr_t, data_dma_t, strb_dma_t, logic)

  // Main connections for narrow TCDM
  tcdm_req_t [NumInp-1:0] tcdm_req;
  tcdm_rsp_t [NumInp-1:0] tcdm_rsp;

  mem_req_t [NrSuperBanks-1:0][BanksPerSuperBank-1:0] narrow_req;
  mem_rsp_t [NrSuperBanks-1:0][BanksPerSuperBank-1:0] narrow_rsp;

  // Main connections for wide TCDM
  tcdm_dma_req_t tcdm_dma_req;
  tcdm_dma_rsp_t tcdm_dma_rsp;

  mem_dma_req_t [NrSuperBanks-1:0] wide_dma_req;
  mem_dma_rsp_t [NrSuperBanks-1:0] wide_dma_rsp;

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

  always_comb begin

    // These signals are never used
    tcdm_dma_req.q.amo   = reqrsp_pkg::AMONone;
    tcdm_dma_req.q.user = '0;

    // Remapping for visibility
    // Request (incoming) remapping
    tcdm_dma_req.q.write  = tcdm_dma_req_write_i;
    tcdm_dma_req.q.addr   = tcdm_dma_req_addr_i;
    tcdm_dma_req.q.data   = tcdm_dma_req_data_i;
    tcdm_dma_req.q.strb   = tcdm_dma_req_strb_i;
    tcdm_dma_req.q_valid  = tcdm_dma_req_q_valid_i;

    // Response (outgoing) remapping
    tcdm_dma_rsp_q_ready_o = tcdm_dma_rsp.q_ready;
    tcdm_dma_rsp_p_valid_o     = tcdm_dma_rsp.p_valid;
    tcdm_dma_rsp_data_o    = tcdm_dma_rsp.p.data;
  end

  snitch_tcdm_interconnect #(
    .NumInp                ( NumInp                              ),
    .NumOut                ( NrBanks                             ),
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
    .mem_req_o             ( narrow_req                          ),
    .mem_rsp_i             ( narrow_rsp                          )
  );

  snitch_tcdm_interconnect #(
    .NumInp                ( 1                                   ),
    .NumOut                ( NrSuperBanks                        ),
    .tcdm_req_t            ( tcdm_dma_req_t                      ),
    .tcdm_rsp_t            ( tcdm_dma_rsp_t                      ),
    .mem_req_t             ( mem_dma_req_t                       ),
    .mem_rsp_t             ( mem_dma_rsp_t                       ),
    .MemAddrWidth          ( TCDMMemAddrWidth                    ),
    .DataWidth             ( WideDataWidth                       ),
    .user_t                ( logic                               ),
    .MemoryResponseLatency ( 1                                   ),
    .Radix                 ( 2                                   ),
    .Topology              ( snitch_pkg::LogarithmicInterconnect )
  ) i_dma_tcdm_interconnect (
    .clk_i                 ( clk_i                               ),
    .rst_ni                ( rst_ni                              ),
    .req_i                 ( tcdm_dma_req                        ),
    .rsp_o                 ( tcdm_dma_rsp                        ),
    .mem_req_o             ( wide_dma_req                        ),
    .mem_rsp_i             ( wide_dma_rsp                        )
  );


  for(genvar i = 0; i < NrSuperBanks; i++) begin: gen_tcdm_super_bank

    mem_req_t [BanksPerSuperBank-1:0] amo_req;
    mem_rsp_t [BanksPerSuperBank-1:0] amo_rsp;

    mem_wide_narrow_mux #(
      .NarrowDataWidth    ( NarrowDataWidth         ),
      .WideDataWidth      ( WideDataWidth           ),
      .mem_narrow_req_t   ( mem_req_t               ),
      .mem_narrow_rsp_t   ( mem_rsp_t               ),
      .mem_wide_req_t     ( mem_dma_req_t           ),
      .mem_wide_rsp_t     ( mem_dma_rsp_t           )
    ) i_tcdm_mux (
      .clk_i              ( clk_i                   ),
      .rst_ni             ( rst_ni                  ),
      .in_narrow_req_i    ( narrow_req[i]           ),
      .in_narrow_rsp_o    ( narrow_rsp[i]           ),
      .in_wide_req_i      ( wide_dma_req[i]         ),
      .in_wide_rsp_o      ( wide_dma_rsp[i]         ),
      .out_req_o          ( amo_req                 ),
      .out_rsp_i          ( amo_rsp                 ),
      .sel_wide_i         ( wide_dma_req[i].q_valid )
    );

    // Generate multi-bank memories
    // Number of banks matches number of memories
    for (genvar j = 0; j < BanksPerSuperBank; j++) begin : gen_tcdm_bank

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
        .valid_i        ( amo_req[j].q_valid        ),
        .ready_o        ( amo_rsp[j].q_ready        ),
        .addr_i         ( amo_req[j].q.addr         ),
        .write_i        ( amo_req[j].q.write        ),
        .wdata_i        ( amo_req[j].q.data         ),
        .wstrb_i        ( amo_req[j].q.strb         ),
        .core_id_i      ( amo_req[j].q.user.core_id ),
        .is_core_i      ( amo_req[j].q.user.is_core ),
        .rdata_o        ( amo_rdata_local           ),
        .amo_i          ( amo_req[j].q.amo          ),
        .mem_req_o      ( mem_cs                    ),
        .mem_add_o      ( mem_add                   ),
        .mem_wen_o      ( mem_wen                   ),
        .mem_wdata_o    ( mem_wdata                 ),
        .mem_be_o       ( mem_be                    ),
        .mem_rdata_i    ( mem_rdata                 ),
        .dma_access_i   ( wide_dma_req[i].q_valid   ), // Unused since we don't simulate DMA here
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
        .d_o    ( amo_rsp[j].p.data )
      );
    end
  end

endmodule
