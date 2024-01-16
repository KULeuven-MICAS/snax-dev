vlog -f ../flist/stream_tcdm.f +define+SYNTHESIS
vsim -voptargs=+acc work.tb_stream_tcdm
do ../do/streamer_tcdm.do
run 2000ns
