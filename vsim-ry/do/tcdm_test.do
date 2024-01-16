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
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {39 ns} 0}
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
WaveRestoreZoom {0 ns} {105 ns}
