
`ifdef QUESTA_SIM_XYI
import riscv_instr::*;
import reqrsp_pkg::*;
`endif 

module snax_streamer_gemm_wrapper #(
    parameter int unsigned DataWidth     = 64,
    parameter int unsigned SnaxTcdmPorts = 24,
    parameter int unsigned TCDMAddrWidth = 48,
    parameter type         acc_req_t     = logic,
    parameter type         acc_rsp_t     = logic,
    parameter type         tcdm_req_t    = logic,
    parameter type         tcdm_rsp_t    = logic
) (
    input logic clk_i,
    input logic rst_ni,

    input  logic     snax_qvalid_i,
    output logic     snax_qready_o,
    input  acc_req_t snax_req_i,

    output acc_rsp_t snax_resp_o,
    output logic     snax_pvalid_o,
    input  logic     snax_pready_i,

    output tcdm_req_t [SnaxTcdmPorts-1:0] snax_tcdm_req_o,
    input  tcdm_rsp_t [SnaxTcdmPorts-1:0] snax_tcdm_rsp_i,

    output logic                          snax_barrier_o
);

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

    snax_interface_translator #(
        .acc_req_t ( acc_req_t ),
        .acc_rsp_t ( acc_rsp_t )
    ) i_snax_interface_translator(
        //-----------------------------
        // Clocks and reset
        //-----------------------------
        .clk_i(clk_i),
        .rst_ni(rst_ni),

        .snax_qvalid_i(snax_qvalid_i),
        .snax_qready_o(snax_qready_o),
        .snax_req_i(snax_req_i),

        .snax_resp_o(snax_resp_o),
        .snax_pvalid_o(snax_pvalid_o),
        .snax_pready_i(snax_pready_i),

        //-----------------------------
        // Simplified CSR control ports
        //-----------------------------
        // Request
        .io_csr_req_bits_data_i(io_csr_req_bits_data_i),
        .io_csr_req_bits_addr_i(io_csr_req_bits_addr_i),
        .io_csr_req_bits_write_i(io_csr_req_bits_write_i),
        .io_csr_req_valid_i(io_csr_req_valid_i),
        .io_csr_req_ready_o(io_csr_req_ready_o),

        // Response
        .io_csr_rsp_ready_i(io_csr_rsp_ready_i),
        .io_csr_rsp_valid_o(io_csr_rsp_valid_o),
        .io_csr_rsp_bits_data_o(io_csr_rsp_bits_data_o)

    );

    //-----------------------------
    // Seperated TCDM ports signals
    //-----------------------------
    logic  [SnaxTcdmPorts-1:0]                        tcdm_req_write_i;
    logic  [SnaxTcdmPorts-1:0][TCDMAddrWidth-1:0]     tcdm_req_addr_i;
    //Note that tcdm_req_amo_i is 4 bits based on reqrsp definition
    logic  [SnaxTcdmPorts-1:0][3:0]                   tcdm_req_amo_i;
    logic  [SnaxTcdmPorts-1:0][DataWidth-1:0]   tcdm_req_data_i;
    //Note that tcdm_req_user_core_id_i is 5 bits based on Snitch definition
    logic  [SnaxTcdmPorts-1:0][4:0]                   tcdm_req_user_core_id_i;
    bit    [SnaxTcdmPorts-1:0]                        tcdm_req_user_is_core_i;
    logic  [SnaxTcdmPorts-1:0][DataWidth/8-1:0] tcdm_req_strb_i;
    logic  [SnaxTcdmPorts-1:0]                        tcdm_req_q_valid_i;
    logic  [SnaxTcdmPorts-1:0]                        tcdm_rsp_q_ready_o;
    logic  [SnaxTcdmPorts-1:0]                        tcdm_rsp_p_valid_o;
    logic  [SnaxTcdmPorts-1:0][DataWidth-1:0]   tcdm_rsp_data_o;

    // bundle the seperated signals to one type

    always_comb begin: gen_hard_bundle
        for(int i=0; i < SnaxTcdmPorts; i++) begin
            
            snax_tcdm_req_o[i].q.write           = tcdm_req_write_i[i];
            snax_tcdm_req_o[i].q.addr            = tcdm_req_addr_i[i];
            // snax_tcdm_req_o[i].q.amo             = tcdm_req_amo_i[i];
            snax_tcdm_req_o[i].q.amo             = AMONone;
            snax_tcdm_req_o[i].q.data            = tcdm_req_data_i[i];
            snax_tcdm_req_o[i].q.user.core_id    = tcdm_req_user_core_id_i[i];
            snax_tcdm_req_o[i].q.user.is_core    = tcdm_req_user_is_core_i[i];
            snax_tcdm_req_o[i].q.strb            = tcdm_req_strb_i[i];
            snax_tcdm_req_o[i].q_valid            = tcdm_req_q_valid_i[i];

            tcdm_rsp_q_ready_o[i]                = snax_tcdm_rsp_i[i].q_ready;
            tcdm_rsp_p_valid_o[i]                = snax_tcdm_rsp_i[i].p_valid;
            tcdm_rsp_data_o[i]                   = snax_tcdm_rsp_i[i].p.data;

        end
    end


    stream_gemm_wrapper #(
        .TCDMAddrWidth(TCDMAddrWidth)
    )i_stream_gemm_wrapper(
        //-----------------------------
        // Clocks and reset
        //-----------------------------
        .clk_i(clk_i),
        .rst_ni(rst_ni),

        //-----------------------------
        // TCDM ports
        //-----------------------------
        // Request
        .tcdm_req_write_o(tcdm_req_write_i),
        .tcdm_req_addr_o(tcdm_req_addr_i),
        .tcdm_req_amo_o(tcdm_req_amo_i), //Note that tcdm_req_amo_i is 4 bits based on reqrsp definition
        .tcdm_req_data_o(tcdm_req_data_i),
        .tcdm_req_user_core_id_o(tcdm_req_user_core_id_i), //Note that tcdm_req_user_core_id_i is 5 bits based on Snitch definition
        .tcdm_req_user_is_core_o(tcdm_req_user_is_core_i),
        .tcdm_req_strb_o(tcdm_req_strb_i),
        .tcdm_req_q_valid_o(tcdm_req_q_valid_i),

        // Response
        .tcdm_rsp_q_ready_i(tcdm_rsp_q_ready_o),
        .tcdm_rsp_p_valid_i(tcdm_rsp_p_valid_o),
        .tcdm_rsp_data_i(tcdm_rsp_data_o),

        //-----------------------------
        // CSR control ports
        //-----------------------------
        // Request
        .io_csr_req_bits_data_i(io_csr_req_bits_data_i),
        .io_csr_req_bits_addr_i(io_csr_req_bits_addr_i),
        .io_csr_req_bits_write_i(io_csr_req_bits_write_i),
        .io_csr_req_valid_i(io_csr_req_valid_i),
        .io_csr_req_ready_o(io_csr_req_ready_o),

        // Response
        .io_csr_rsp_ready_i(io_csr_rsp_ready_i),
        .io_csr_rsp_valid_o(io_csr_rsp_valid_o),
        .io_csr_rsp_bits_data_o(io_csr_rsp_bits_data_o)
    );

    assign snax_barrier_o = io_csr_req_ready_o;
    
endmodule
