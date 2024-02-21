
`ifdef TARGET_SYNTHESIS
import riscv_instr::*;
import reqrsp_pkg::*;
`endif 

module snax_streamer_gemm_wrapper #(
    parameter int unsigned DataWidth     = 64,
    parameter int unsigned SnaxTcdmPorts = 24,
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
    logic [31:0] io_csr_req_bits_data_i,
    logic [31:0] io_csr_req_bits_addr_i,
    logic        io_csr_req_bits_write_i,
    logic        io_csr_req_valid_i,
    logic        io_csr_req_ready_o,

    // Response
    logic        io_csr_rsp_ready_i,
    logic        io_csr_rsp_valid_o,
    logic [31:0] io_csr_rsp_bits_data_o

    snax_interface_translator #(
        .acc_req_t ( acc_req_t ),
        .acc_rsp_t ( acc_resp_t ),
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

    stream_gemm_wrapper i_stream_gemm_wrapper(
        //-----------------------------
        // Clocks and reset
        //-----------------------------
        .clk_i(clk_i),
        .rst_ni(rst_ni),

        //-----------------------------
        // TCDM ports
        //-----------------------------
        // Request
        .tcdm_req_write_o(snax_tcdm_req_o.q.write),
        .tcdm_req_addr_o(snax_tcdm_req_o.q.addr),
        .tcdm_req_amo_o(snax_tcdm_req_o.q.amo), //Note that tcdm_req_amo_i is 4 bits based on reqrsp definition
        .tcdm_req_data_o(snax_tcdm_req_o.q.data),
        .tcdm_req_user_core_id_o(snax_tcdm_req_o.q.user.core_id), //Note that tcdm_req_user_core_id_i is 5 bits based on Snitch definition
        .tcdm_req_user_is_core_o(snax_tcdm_req_o.q.user.is_core),
        .tcdm_req_strb_o(snax_tcdm_req_o.q.strb),
        .tcdm_req_q_valid_o(snax_tcdm_req_o.q.q_valid),

        // Response
        .tcdm_rsp_q_ready_i(snax_tcdm_rsp_i.q_ready),
        .tcdm_rsp_p_valid_i(snax_tcdm_rsp_i.p_valid),
        .tcdm_rsp_data_i(snax_tcdm_rsp_i.p.data),

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

    assign snax_barrier_o = io_csr_req_ready_o
    
endmodule
