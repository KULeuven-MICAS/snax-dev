vlog -f ../flist/streamer_test.f +define+SYNTHESIS
vsim -voptargs=+acc work.tb_streamer_top
do ../do/streamer_test.do
run 2000ns