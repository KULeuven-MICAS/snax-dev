onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_stream_tcdm/i_tcdm_subsys/clk_i
add wave -noupdate /tb_stream_tcdm/i_tcdm_subsys/rst_ni
add wave -noupdate /tb_stream_tcdm/i_tcdm_subsys/tcdm_req_write_i
add wave -noupdate /tb_stream_tcdm/i_tcdm_subsys/tcdm_req_addr_i
add wave -noupdate /tb_stream_tcdm/i_tcdm_subsys/tcdm_req_amo_i
add wave -noupdate /tb_stream_tcdm/i_tcdm_subsys/tcdm_req_data_i
add wave -noupdate /tb_stream_tcdm/i_tcdm_subsys/tcdm_req_user_core_id_i
add wave -noupdate /tb_stream_tcdm/i_tcdm_subsys/tcdm_req_user_is_core_i
add wave -noupdate /tb_stream_tcdm/i_tcdm_subsys/tcdm_req_strb_i
add wave -noupdate /tb_stream_tcdm/i_tcdm_subsys/tcdm_req_q_valid_i
add wave -noupdate /tb_stream_tcdm/i_tcdm_subsys/tcdm_rsp_q_ready_o
add wave -noupdate /tb_stream_tcdm/i_tcdm_subsys/tcdm_rsp_p_valid_o
add wave -noupdate /tb_stream_tcdm/i_tcdm_subsys/tcdm_rsp_data_o
add wave -noupdate -divider <NULL>
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/clk_i
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/rst_ni
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/acc2stream_data_0_bits_i
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/acc2stream_data_0_valid_i
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/acc2stream_data_0_ready_o
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/stream2acc_data_0_bits_o
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/stream2acc_data_0_valid_o
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/stream2acc_data_0_ready_i
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/stream2acc_data_1_bits_o
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/stream2acc_data_1_valid_o
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/stream2acc_data_1_ready_i
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/stream2acc_data_2_bits_o
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/stream2acc_data_2_valid_o
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/stream2acc_data_2_ready_i
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/tcdm_req_write_o
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/tcdm_req_addr_o
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/tcdm_req_amo_o
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/tcdm_req_data_o
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/tcdm_req_user_core_id_o
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/tcdm_req_user_is_core_o
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/tcdm_req_strb_o
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/tcdm_req_q_valid_o
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/tcdm_rsp_q_ready_i
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/tcdm_rsp_p_valid_i
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/tcdm_rsp_data_i
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/io_csr_req_bits_data_i
add wave -noupdate -radix unsigned /tb_stream_tcdm/i_streamer_wrapper/io_csr_req_bits_addr_i
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/io_csr_req_bits_write_i
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/io_csr_req_valid_i
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/io_csr_req_ready_o
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/io_csr_rsp_ready_i
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/io_csr_rsp_valid_o
add wave -noupdate -radix unsigned /tb_stream_tcdm/i_streamer_wrapper/io_csr_rsp_bits_data_o
add wave -noupdate -divider <NULL>
add wave -noupdate -expand /tb_stream_tcdm/tcdm_req_write
add wave -noupdate /tb_stream_tcdm/tcdm_req_addr
add wave -noupdate /tb_stream_tcdm/tcdm_req_amo
add wave -noupdate /tb_stream_tcdm/tcdm_req_data
add wave -noupdate /tb_stream_tcdm/tcdm_req_user_core_id
add wave -noupdate /tb_stream_tcdm/tcdm_req_user_is_core
add wave -noupdate /tb_stream_tcdm/tcdm_req_strb
add wave -noupdate /tb_stream_tcdm/tcdm_req_q_valid
add wave -noupdate /tb_stream_tcdm/tcdm_rsp_q_ready
add wave -noupdate /tb_stream_tcdm/tcdm_rsp_p_valid
add wave -noupdate /tb_stream_tcdm/tcdm_rsp_data
add wave -noupdate -divider <NULL>
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/i_streamer_top/io_data_tcdm_req_0_bits_addr
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/i_streamer_top/io_data_tcdm_req_1_bits_addr
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/i_streamer_top/io_data_tcdm_req_2_bits_addr
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/i_streamer_top/io_data_tcdm_req_3_bits_addr
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/i_streamer_top/io_data_tcdm_req_4_bits_addr
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/i_streamer_top/io_data_tcdm_req_5_bits_addr
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/i_streamer_top/io_data_tcdm_req_6_bits_addr
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/i_streamer_top/io_data_tcdm_req_7_bits_addr
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/i_streamer_top/io_data_tcdm_req_8_bits_addr
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/i_streamer_top/io_data_tcdm_req_9_bits_addr
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/i_streamer_top/io_data_tcdm_req_10_bits_addr
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/i_streamer_top/io_data_tcdm_req_11_bits_addr
add wave -noupdate /tb_stream_tcdm/i_streamer_wrapper/i_streamer_top/io_data_tcdm_req_12_bits_addr
add wave -noupdate -divider <NULL>
add wave -noupdate -divider <NULL>
add wave -noupdate -divider <NULL>
add wave -noupdate -divider <NULL>
add wave -noupdate -divider <NULL>
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {219 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 643
configure wave -valuecolwidth 167
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {830 ns}
