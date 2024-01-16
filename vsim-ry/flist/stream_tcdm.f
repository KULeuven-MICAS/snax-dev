#------------------------------------
# Include directories
#------------------------------------
+incdir+../../.bender/git/checkouts/common_cells-9e51f4fce2109f7f/include
+incdir+../../.bender/git/checkouts/axi-ce2f2a7fa65f3d1d/include
+incdir+../../.bender/git/checkouts/register_interface-c2acb33430a1b464/include
+incdir+../../.bender/git/checkouts/snitch_cluster-ee28f139ef0e92e9/hw/snitch/include
+incdir+../../.bender/git/checkouts/snitch_cluster-ee28f139ef0e92e9/hw/mem_interface/include
+incdir+../../.bender/git/checkouts/snitch_cluster-ee28f139ef0e92e9/hw/tcdm_interface/include

#------------------------------------
# PULP common cells components
#------------------------------------
../../.bender/git/checkouts/common_cells-9e51f4fce2109f7f/src/cf_math_pkg.sv
../../.bender/git/checkouts/common_cells-9e51f4fce2109f7f/src/stream_demux.sv
../../.bender/git/checkouts/common_cells-9e51f4fce2109f7f/src/rr_arb_tree.sv
../../.bender/git/checkouts/common_cells-9e51f4fce2109f7f/src/stream_xbar.sv
../../.bender/git/checkouts/common_cells-9e51f4fce2109f7f/src/shift_reg.sv
../../.bender/git/checkouts/common_cells-9e51f4fce2109f7f/src/shift_reg_gated.sv
../../.bender/git/checkouts/common_cells-9e51f4fce2109f7f/src/spill_register_flushable.sv
../../.bender/git/checkouts/common_cells-9e51f4fce2109f7f/src/spill_register.sv
../../.bender/git/checkouts/common_cells-9e51f4fce2109f7f/src/lzc.sv

#------------------------------------
# DM pkg components
#------------------------------------
../../.bender/git/checkouts/riscv-dbg-57624590bf1fdfd3/src/dm_pkg.sv

#------------------------------------
# SRAM components
#------------------------------------
../../.bender/git/checkouts/tech_cells_generic-4d110630f7d586c3/src/rtl/tc_sram.sv
../../.bender/git/checkouts/tech_cells_generic-4d110630f7d586c3/src/rtl/tc_sram_impl.sv

#------------------------------------
# AXI pkgs
#------------------------------------
../../.bender/git/checkouts/axi-ce2f2a7fa65f3d1d/src/axi_pkg.sv 

#------------------------------------
# Snitch subcomponents
#------------------------------------
../../.bender/git/checkouts/snitch_cluster-ee28f139ef0e92e9/hw/reqrsp_interface/src/reqrsp_pkg.sv
../../.bender/git/checkouts/snitch_cluster-ee28f139ef0e92e9/hw/snitch/src/snitch_pkg.sv
../../.bender/git/checkouts/snitch_cluster-ee28f139ef0e92e9/hw/snitch_cluster/src/snitch_tcdm_interconnect.sv
../../.bender/git/checkouts/snitch_cluster-ee28f139ef0e92e9/hw/snitch_cluster/src/snitch_amo_shim.sv

#------------------------------------
# TCDM local subsystem
#------------------------------------
../../rtl/memory-subsys/tcdm_subsys.sv

#------------------------------------
# Streamer subsys
#------------------------------------
/users/micas/rantonio/no_backup/kul_main/snax-dev/rtl/StreamerTop.sv
/users/micas/rantonio/no_backup/kul_main/snax-dev/rtl/streamer_wrapper.sv
/users/micas/rantonio/no_backup/kul_main/snax-dev/vsim-ry/tb/tb_streamer_top.sv

#------------------------------------
# TCDM TB subsystem
#------------------------------------
../tb/tb_stream_tcdm.sv
