//-----------------------------------
// Tightly Coupled Data Memory Sub-System 
// Local testbench
//-----------------------------------
module tb_tcdm_subsys;

  localparam int unsigned NarrowDataWidth  = 64;
  localparam int unsigned TCDMDepth        = 64;
  localparam int unsigned NrBanks          = 8;
  localparam int unsigned TCDMMemAddrWidth = $clog2(TCDMDepth);
  localparam int unsigned TCDMSize         = NrBanks * TCDMDepth * (NarrowDataWidth/8);
  localparam int unsigned TCDMAddrWidth    = $clog2(TCDMSize);
  localparam int unsigned NumInp           = 2;
  localparam int unsigned NumOut           = NrBanks;

  logic                                     clk_i;
  logic                                     rst_ni;
  logic [NumOut-1:0]                        tcdm_req_write;
  logic [NumOut-1:0][TCDMAddrWidth-1:0]     tcdm_req_addr;
  logic [NumOut-1:0][3:0]                   tcdm_req_amo;
  logic [NumOut-1:0][NarrowDataWidth-1:0]   tcdm_req_data;
  logic [NumOut-1:0][4:0]                   tcdm_req_user_core_id;
  logic [NumOut-1:0]                        tcdm_req_user_is_core;
  logic [NumOut-1:0][NarrowDataWidth/8-1:0] tcdm_req_strb;
  logic [NumOut-1:0]                        tcdm_req_q_valid;
  logic [NumOut-1:0]                        tcdm_rsp_q_ready;
  logic [NumOut-1:0]                        tcdm_rsp_p_valid;
  logic [NumOut-1:0][NarrowDataWidth-1:0]   tcdm_rsp_data;

  tcdm_subsys #(
    .NarrowDataWidth          ( NarrowDataWidth       ),
    .TCDMDepth                ( TCDMDepth             ),
    .NrBanks                  ( NrBanks               ),
    .NumInp                   ( NumInp                ),
    .NumOut                   ( NumOut                )
  ) i_tcdm_subsys (
    .clk_i                    ( clk_i                 ),
    .rst_ni                   ( rst_ni                ),
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
    .tcdm_rsp_data_o          ( tcdm_rsp_data         )
  );

  always begin #10; clk_i <= !clk_i; end
  
  initial begin

    clk_i                 = 0;
    rst_ni                = 0;
    tcdm_req_write        = '0;
    tcdm_req_addr         = '0;
    tcdm_req_amo          = '0;
    tcdm_req_data         = '0;
    tcdm_req_user_core_id = '0;
    tcdm_req_user_is_core = '0;
    tcdm_req_strb         = '0;
    tcdm_req_q_valid      = '0;

    @(posedge clk_i);
    @(posedge clk_i);

    rst_ni                = 1;

    @(posedge clk_i);
    @(posedge clk_i);

    tcdm_req_addr[0]  = 48'd0;
    tcdm_req_data[0]  = 64'h0000_0000_abcd_1234;
    tcdm_req_strb[0]  = '1;
    tcdm_req_write[0] = 1'b1;
    tcdm_req_q_valid[0] = 1'b1;

    tcdm_req_addr[1]  = 48'd8;
    tcdm_req_data[1]  = 64'h0000_0000_5555_ffff;
    tcdm_req_strb[1]  = '1;
    tcdm_req_write[1] = 1'b1;
    tcdm_req_q_valid[1] = 1'b1;

    @(posedge clk_i);

    tcdm_req_addr[0]  = 48'd16;
    tcdm_req_data[0]  = 64'h0000_0000_1111_1111;
    tcdm_req_strb[0]  = '1;
    tcdm_req_write[0] = 1'b1;
    tcdm_req_q_valid[0] = 1'b1;

    tcdm_req_addr[1]  = 48'd24;
    tcdm_req_data[1]  = 64'h0000_0000_4321_1234;
    tcdm_req_strb[1]  = '1;
    tcdm_req_write[1] = 1'b1;
    tcdm_req_q_valid[1] = 1'b1;

    @(posedge clk_i);

    tcdm_req_addr[0]  = 48'd32;
    tcdm_req_data[0]  = 64'h0000_0000_dead_beef;
    tcdm_req_strb[0]  = '1;
    tcdm_req_write[0] = 1'b1;
    tcdm_req_q_valid[0] = 1'b1;

    tcdm_req_addr[1]  = 48'd40;
    tcdm_req_data[1]  = 64'h0000_0000_9999_8888;
    tcdm_req_strb[1]  = '1;
    tcdm_req_write[1] = 1'b1;
    tcdm_req_q_valid[1] = 1'b1;

    @(posedge clk_i);

    tcdm_req_addr[0]  = 48'd0;
    tcdm_req_data[0]  = 64'h0000_0000_0000_0000;
    tcdm_req_strb[0]  = '1;
    tcdm_req_write[0] = 1'b0;
    tcdm_req_q_valid[0] = 1'b1;

    tcdm_req_addr[1]  = 48'd8;
    tcdm_req_data[1]  = 64'h0000_0000_0000_0000;
    tcdm_req_strb[1]  = '1;
    tcdm_req_write[1] = 1'b0;
    tcdm_req_q_valid[1] = 1'b1;

    @(posedge clk_i);

    tcdm_req_addr[0]  = 48'd16;
    tcdm_req_data[0]  = 64'h0000_0000_0000_0000;
    tcdm_req_strb[0]  = '1;
    tcdm_req_write[0] = 1'b0;
    tcdm_req_q_valid[0] = 1'b1;

    tcdm_req_addr[1]  = 48'd24;
    tcdm_req_data[1]  = 64'h0000_0000_0000_0000;
    tcdm_req_strb[1]  = '1;
    tcdm_req_write[1] = 1'b0;
    tcdm_req_q_valid[1] = 1'b1;

    @(posedge clk_i);

    tcdm_req_addr[0]  = 48'd32;
    tcdm_req_data[0]  = 64'h0000_0000_0000_0000;
    tcdm_req_strb[0]  = '1;
    tcdm_req_write[0] = 1'b0;
    tcdm_req_q_valid[0] = 1'b1;

    tcdm_req_addr[1]  = 48'd40;
    tcdm_req_data[1]  = 64'h0000_0000_0000_0000;
    tcdm_req_strb[1]  = '1;
    tcdm_req_write[1] = 1'b0;
    tcdm_req_q_valid[1] = 1'b1;

    @(posedge clk_i);
    @(posedge clk_i);
    @(posedge clk_i);
    
  end

endmodule
