vlog -f ../flist/tcdm_subsys.f +define+SYNTHESIS
vsim -voptargs=+acc work.tb_tcdm_subsys
do ../do/tcdm_test.do
run 500ns