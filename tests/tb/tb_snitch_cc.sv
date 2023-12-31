//---------------------------------------------
// Copyright 2023 Katolieke Universiteit Leuven (KUL)
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
// Author: Ryan Antonio (ryan.antonio@kuleuven.be)
//---------------------------------------------
// Description:
// This test bench was used to test out and build the snax shell prototype.
// It should give the users an idea on how it was built.
//---------------------------------------------

`timescale 1ns/1ps

// verilog_lint: waive-start line-length
// verilog_lint: waive-start no-trailing-spaces

//---------------------------------------------
// Type definitions to include
//---------------------------------------------
`include "axi/assign.svh"
`include "axi/typedef.svh"
`include "common_cells/assertions.svh"
`include "common_cells/registers.svh"

`include "mem_interface/typedef.svh"
`include "register_interface/typedef.svh"
`include "reqrsp_interface/typedef.svh"
`include "tcdm_interface/typedef.svh"

`include "snitch_vm/typedef.svh"

//---------------------------------------------
// Packages to include
//---------------------------------------------
import snitch_pkg::*;
import snitch_ssr_pkg::*;
import snitch_pma_pkg::*;
import fpnew_pkg::*;
import reqrsp_pkg::*;

module tb_snitch_cc;

    //---------------------------------------------
    // Prototype parameters
    // Note: These were originally based on the Snitch cluster
    // This test is to see if we can compile snitch cluster as a whole, properly
    //---------------------------------------------

    parameter int unsigned PhysicalAddrWidth        = 48;
    parameter int unsigned NarrowDataWidth          = 32;
    parameter int unsigned WideDataWidth            = 512;
    parameter int unsigned WideIdWidthIn            = 1;
    parameter int unsigned WideUserWidth            = 1;
    parameter int unsigned DMAAxiReqFifoDepth       = 3;
    parameter int unsigned DMAReqFifoDepth          = 3;
    parameter int unsigned BootAddr                 = 32'h0000_1000;

    parameter int unsigned NumIntOutstandingLoads   = 4;
    parameter int unsigned NumIntOutstandingMem     = 4;
    parameter int unsigned NumFPOutstandingLoads    = 4;
    parameter int unsigned NumFPOutstandingMem      = 4;

    parameter int unsigned NumDTLBEntries           = 1;
    parameter int unsigned NumITLBEntries           = 1;
    parameter int unsigned NumSequencerInstr        = 16;
    parameter int unsigned NumSsrs                  = 3;
    parameter int unsigned SsrMuxRespDepth          = 4;

    parameter int unsigned RegisterOffloadReq       = 0;
    parameter int unsigned RegisterOffloadRsp       = 0;
    parameter int unsigned RegisterCoreReq          = 0;
    parameter int unsigned RegisterCoreRsp          = 0;
    parameter int unsigned RegisterFPUReq           = 0;
    parameter int unsigned RegisterSequencer        = 0;
    parameter int unsigned RegisterFPUIn            = 0;
    parameter int unsigned RegisterFPUOut           = 0;

    localparam int unsigned NrBanks                 = 32;
    localparam int unsigned TCDMDepth               = 512;
    localparam int unsigned TCDMSize                = NrBanks * TCDMDepth * (NarrowDataWidth/8);
    localparam int unsigned TCDMAddrWidth           = $clog2(TCDMSize);

    localparam int unsigned NrWideMasters  = 1;
    localparam int unsigned WideIdWidthOut =  WideIdWidthIn;


    //---------------------------------------------
    // For generated modules, a 1'b1 means they exist
    //---------------------------------------------
    parameter bit RVE         = 1'b0;
    parameter bit RVF         = 1'b0;
    parameter bit RVD         = 1'b0;
    parameter bit XDivSqrt    = 1'b0;
    parameter bit XF16        = 1'b0;
    parameter bit XF16ALT     = 1'b0;
    parameter bit XF8         = 1'b0;
    parameter bit XF8ALT      = 1'b0;
    parameter bit XFVEC       = 1'b0;
    parameter bit XFDOTP      = 1'b0;
    parameter bit Xdma        = 1'b0;
    parameter bit IsoCrossing = 1'b0;
    parameter bit Xfrep       = 1'b0;
    parameter bit Xssr        = 1'b0;
    parameter bit Xipu        = 1'b0;
    parameter bit VMSupport   = 1'b0;

    //---------------------------------------------
    // Necessary type definitions
    //---------------------------------------------

    typedef logic [PhysicalAddrWidth-1:0] addr_t;
    typedef logic [  NarrowDataWidth-1:0] data_t;
    typedef logic [NarrowDataWidth/8-1:0] strb_t;
    typedef logic [PhysicalAddrWidth-1:0] tcdm_addr_t;
    typedef logic [    WideIdWidthIn-1:0] id_dma_mst_t;
    typedef logic [   WideIdWidthOut-1:0] id_dma_slv_t;
    typedef logic [    WideDataWidth-1:0] data_dma_t;
    typedef logic [  WideDataWidth/8-1:0] strb_dma_t;
    typedef logic [    WideUserWidth-1:0] user_dma_t;

    typedef struct packed {
        logic [4:0] core_id;
        bit   is_core;
    } tcdm_user_t;

    typedef struct packed {
        acc_addr_e   addr;
        logic [4:0]  id;
        logic [31:0] data_op;
        data_t       data_arga;
        data_t       data_argb;
        addr_t       data_argc;
    } acc_req_t;

    typedef struct packed {
        logic [4:0] id;
        logic       error;
        data_t      data;
    } acc_rsp_t;

    // Can be found in snitch_vm/typedef.svh
    // for pa_t
    `SNITCH_VM_TYPEDEF(PhysicalAddrWidth)

    typedef struct packed {
        // Slow domain.
        logic          flush_i_valid;
        addr_t         inst_addr;
        logic          inst_cacheable;
        logic          inst_valid;
        // Fast domain.
        acc_req_t      acc_req;
        logic          acc_qvalid;
        logic          acc_pready;
        // Slow domain.
        logic [1:0]    ptw_valid;
        va_t  [1:0]    ptw_va;      // Found in snitch_pkg
        pa_t  [1:0]    ptw_ppn;     // Found in snitch_vm.svh
    } hive_req_t;

    typedef struct packed {
        // Slow domain.
        logic          flush_i_ready;
        logic [31:0]   inst_data;
        logic          inst_ready;
        logic          inst_error;
        // Fast domain.
        logic          acc_qready;
        acc_rsp_t      acc_resp;
        logic          acc_pvalid;
        // Slow domain.
        logic [1:0]    ptw_ready;
        l0_pte_t [1:0] ptw_pte;
        logic [1:0]    ptw_is_4mega;
    } hive_rsp_t;

    typedef struct packed {
        logic aw_stall, ar_stall, r_stall, w_stall,
                    buf_w_stall, buf_r_stall;
        logic aw_valid, aw_ready, aw_done, aw_bw;
        logic ar_valid, ar_ready, ar_done, ar_bw;
        logic r_valid,  r_ready,  r_done, r_bw;
        logic w_valid,  w_ready,  w_done, w_bw;
        logic b_valid,  b_ready,  b_done;
        logic dma_busy;
        axi_pkg::len_t aw_len, ar_len;
        axi_pkg::size_t aw_size, ar_size;
        logic [$clog2(WideDataWidth/8):0] num_bytes_written;
    } dma_events_t;


    //---------------------------------------------
    // SSR Configurations
    // They come from the snitch_ssr_pkg!
    //---------------------------------------------
    localparam ssr_cfg_t [3-1:0] SsrCfgs [1] = '{
        '{
            '{0, 0, 0, 0, 1, 1, 4, 14, 17, 3, 4, 3, 8, 4, 3},
            '{0, 0, 0, 0, 1, 1, 4, 14, 17, 3, 4, 3, 8, 4, 3},
            '{0, 0, 0, 0, 1, 1, 4, 14, 17, 3, 4, 3, 8, 4, 3}
        }
    };

    localparam logic [3-1:0][4:0] SsrRegs [1] = '{
        '{2, 1, 0}
    };

    //---------------------------------------------
    // Virtual memory stuff of snitch
    //---------------------------------------------
    snitch_pma_t SnitchPMACfg;

    //---------------------------------------------
    // FPU default
    //---------------------------------------------
    fpu_implementation_t FPUImplementation;

    //---------------------------------------------
    // Type definitions. Need to checkout the following from 
    // their respective declarations. They all come from the `include above this file
    //
    // AXI_TYPEDEF_ALL     - can be found in axi/typedef.svh
    // REQRSP_TYPEDEF_ALL  - can be found in reqrsp_interface/typedef.svh
    // MEM_TYPEDEF_ALL     - can be found in mem_interface/typedef.svh
    // TCDM_TYPEDEF_ALL    - can be found in tcdm_interface/typedef.svh
    // REG_BUS_TYPEDEF_REQ - can be found in register_interface/typedef.svh
    //
    // The source paths for these typedefs are found in .bender/git/checkouts/<respective package>
    //---------------------------------------------

    //---------------------------------------------
    // This generates the following:
    // reqrsp_req_t
    // reqrsp_rsp_t
    //---------------------------------------------

    `REQRSP_TYPEDEF_ALL(reqrsp, addr_t, data_t, strb_t)

    //---------------------------------------------
    // This generates the following:
    // tcdm_req_t
    // tcdm_rsp_t
    //---------------------------------------------

    `TCDM_TYPEDEF_ALL(tcdm, tcdm_addr_t, data_t, strb_t, tcdm_user_t)
    `TCDM_TYPEDEF_ALL(tcdm_dma, tcdm_addr_t, data_dma_t, strb_dma_t, logic)

    //---------------------------------------------
    // This generates the following:
    // axi_mst_dma_req_t
    // axi_mst_dma_resp_t - note that it really is resp_t based on definition
    //---------------------------------------------

    `AXI_TYPEDEF_ALL(axi_mst_dma, addr_t, id_dma_mst_t, data_dma_t, strb_dma_t, user_dma_t)
    `AXI_TYPEDEF_ALL(axi_slv_dma, addr_t, id_dma_slv_t, data_dma_t, strb_dma_t, user_dma_t)

    //---------------------------------------------
    // This generates the following:
    // mem_dma_req_t
    // mem_dma_rsp_t
    //---------------------------------------------
    `MEM_TYPEDEF_ALL(mem_dma, tcdm_addr_t, data_dma_t, strb_dma_t, logic)


    //---------------------------------------------
    // Wiring and stimuli declaration
    //---------------------------------------------
    hive_req_t          hive_req_o;
    hive_rsp_t          hive_rsp_i;

    interrupts_t        irq_i;

    reqrsp_req_t        data_req_o;
    reqrsp_rsp_t        data_rsp_i;

    tcdm_req_t [NumSsrs-1:0] tcdm_req_o;
    tcdm_rsp_t [NumSsrs-1:0] tcdm_rsp_i;


    axi_mst_dma_req_t   axi_dma_req_o;
    axi_mst_dma_resp_t  axi_dma_res_i;


    //---------------------------------------------
    // Clock and reset
    //---------------------------------------------
    logic clk_i;
    logic rst_ni;

    //---------------------------------------------
    // Main snax shell module
    //---------------------------------------------
    snitch_cc #(
      .AddrWidth              ( PhysicalAddrWidth       ), 
      .DataWidth              ( NarrowDataWidth         ),
      .DMADataWidth           ( WideDataWidth           ),
      .DMAIdWidth             ( WideIdWidthIn           ),
      //.SnitchPMACfg           ( SnitchPMACfg          ), // Use core cluster default for virtual memory. Won't be using now.
      .DMAAxiReqFifoDepth     ( DMAAxiReqFifoDepth      ),
      .DMAReqFifoDepth        ( DMAReqFifoDepth         ),
      .dreq_t                 ( reqrsp_req_t            ),
      .drsp_t                 ( reqrsp_rsp_t            ),
      .tcdm_req_t             ( tcdm_req_t              ),
      .tcdm_rsp_t             ( tcdm_rsp_t              ),
      .tcdm_user_t            ( tcdm_user_t             ),
      .axi_req_t              ( axi_mst_dma_req_t       ),
      .axi_rsp_t              ( axi_mst_dma_resp_t      ),
      .hive_req_t             ( hive_req_t              ),
      .hive_rsp_t             ( hive_rsp_t              ),
      .acc_req_t              ( acc_req_t               ),
      .acc_resp_t             ( acc_rsp_t               ),
      .dma_events_t           ( dma_events_t            ),
      .BootAddr               ( BootAddr                ),
      .RVE                    ( RVE                     ),
      .RVF                    ( RVF                     ),
      .RVD                    ( RVD                     ),
      .XDivSqrt               ( XDivSqrt                ),
      .XF16                   ( XF16                    ),
      .XF16ALT                ( XF16ALT                 ),
      .XF8                    ( XF8                     ),
      .XF8ALT                 ( XF8ALT                  ),
      .XFVEC                  ( XFVEC                   ),
      .XFDOTP                 ( XFDOTP                  ),
      .Xdma                   ( Xdma                    ),
      .IsoCrossing            ( IsoCrossing             ),
      .Xfrep                  ( Xfrep                   ),
      .Xssr                   ( Xssr                    ),
      .Xipu                   ( Xipu                    ),
      .VMSupport              ( VMSupport               ),
      .NumIntOutstandingLoads ( NumIntOutstandingLoads  ),
      .NumIntOutstandingMem   ( NumIntOutstandingMem    ),
      .NumFPOutstandingLoads  ( NumFPOutstandingLoads   ),
      .NumFPOutstandingMem    ( NumFPOutstandingMem     ),
      //.FPUImplementation      ( FPUImplementation     ), // Use core cluster default for FPU implementation. Won't be using now.
      .NumDTLBEntries         ( NumDTLBEntries          ),
      .NumITLBEntries         ( NumITLBEntries          ),
      .NumSequencerInstr      ( NumSequencerInstr       ),
      .NumSsrs                ( NumSsrs                 ),
      .SsrMuxRespDepth        ( SsrMuxRespDepth         ),
      .SsrCfgs                ( '0                      ), // Not using SSRs in this setup
      .SsrRegs                ( '0                      ), // Not using SSRs in this setup
      .RegisterOffloadReq     ( RegisterOffloadReq      ),
      .RegisterOffloadRsp     ( RegisterOffloadRsp      ),
      .RegisterCoreReq        ( RegisterCoreReq         ),
      .RegisterCoreRsp        ( RegisterCoreRsp         ),
      .RegisterFPUReq         ( RegisterFPUReq          ),
      .RegisterSequencer      ( RegisterSequencer       ),
      .RegisterFPUIn          ( RegisterFPUIn           ),
      .RegisterFPUOut         ( RegisterFPUOut          ),
      .TCDMAddrWidth          ( TCDMAddrWidth           )
    ) i_snitch_cc (
      .clk_i                  ( clk_i                   ),
      .clk_d2_i               ( clk_i                   ), // Use same clock. No clock domain crossings involved.
      .rst_ni                 ( rst_ni                  ),
      .rst_int_ss_ni          ( 1'b1                    ),
      .rst_fp_ss_ni           ( 1'b1                    ),
      .hart_id_i              ( '0                      ),
      .hive_req_o             ( hive_req_o              ),
      .hive_rsp_i             ( '0                      ),
      .irq_i                  ( '0                      ),
      .data_req_o             ( data_req_o              ),
      .data_rsp_i             ( '0                      ),
      .tcdm_req_o             ( tcdm_req_o              ),
      .tcdm_rsp_i             ( '0                      ),
      .axi_dma_req_o          ( axi_dma_req_o           ),
      .axi_dma_res_i          ( '0                      ),
      // The next *_o signals are unused for this test because
      // they are used as performance signals that go into the Snitch cluster
      // but this test only runs a single core cluster
      .axi_dma_busy_o         (                         ),
      .axi_dma_perf_o         (                         ),
      .axi_dma_events_o       (                         ),
      .core_events_o          (                         ),
      .tcdm_addr_base_i       ( 48'h0000_0000_1000      )
    );


// verilog_lint: waive-stop line-length
// verilog_lint: waive-stop no-trailing-spaces

endmodule
