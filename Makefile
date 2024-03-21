#-----------------------------
# Path Declarations 
#-----------------------------
BENDER = bender
PYTHON = python3

#-----------------------------
# Default Filename Declarations
#-----------------------------
STREAM_CFG_FILENAME ?= streamer_cfg.hjson

STREAM_TPL_RTL_FILENAME ?= streamer_wrapper.sv.tpl
STREAM_TPL_SCALA_FILENAME ?= StreamParamGen.scala.tpl
STREAM_TPL_TB_FILENAME ?= tb_streamer_top.sv.tpl
STREAM_TCDM_TPL_TB_FILENAME ?= tb_stream_tcdm_top.sv.tpl
STREAM_MUL_TPL_TB_FILENAME ?= tb_stream_alu.sv.tpl
STREAM_MUL_TPL_RTL_FILENAME ?= stream_alu_wrapper.sv.tpl
STREAM_RESHUFFLER_TPL_RTL_FILENAME ?= stream_reshuffler_wrapper.sv.tpl
STREAM_RESHUFFLER_TPL_TB_FILENAME ?= tb_stream_reshuffler.sv.tpl
STREAM_DEV_RESHUFFLER_TPL_RTL_FILENAME ?= stream_dev_reshuffler_wrapper.sv.tpl
STREAM_DEV_RESHUFFLER_TPL_TB_FILENAME ?= tb_stream_dev_reshuffler.sv.tpl

STREAM_WRAPPER_FILENAME ?= streamer_wrapper.sv
STREAM_MUL_WRAPPER_FILENAME ?= stream_alu_wrapper.sv
STREAM_RESHUFFLER_WRAPPER_FILENAME ?= stream_reshuffler_wrapper.sv
STREAM_DEV_RESHUFFLER_WRAPPER_FILENAME ?= stream_dev_reshuffler_wrapper.sv

STREAM_SCALA_PARAM_FILENAME ?= StreamParamGen.scala

STREAM_TOP_FILENAME ?= StreamerTop.sv

STREAM_TB_FILENAME ?= tb_streamer_top.sv
STREAM_TCDM_TB_FILENAME ?= tb_stream_tcdm_top.sv
STREAM_MUL_TB_FILENAME ?= tb_stream_alu.sv
STREAM_RESHUFFLER_TB_FILENAME ?= tb_stream_reshuffler.sv
STREAM_DEV_RESHUFFLER_TB_FILENAME ?= tb_stream_dev_reshuffler.sv

#-----------------------------
# Default Path Declarations 
#-----------------------------
SNAX_STREAMER_PATH = $(shell $(BENDER) path snax-streamer)
CFG_PATH ?= ${CURDIR}/util/cfg
TPL_PATH ?= ${CURDIR}/util/templates
RTL_PATH ?= ${CURDIR}/rtl
TB_PATH ?= ${CURDIR}/tests/tb
STREAM_OUT_SCALA_PATH ?= ${SNAX_STREAMER_PATH}/src/main/scala/streamer

#-----------------------------
# Default Path and File Declarations
#-----------------------------
STREAM_GEN_CFG_FILE = ${CFG_PATH}/${STREAM_CFG_FILENAME}

STREAM_GEN_TPL_RTL_FILE = ${TPL_PATH}/${STREAM_TPL_RTL_FILENAME}
STREAM_MUL_TPL_RTL_FILE = ${TPL_PATH}/${STREAM_MUL_TPL_RTL_FILENAME}
STREAM_RESHUFFLER_TPL_RTL_FILE = ${TPL_PATH}/${STREAM_RESHUFFLER_TPL_RTL_FILENAME}
STREAM_DEV_RESHUFFLER_TPL_RTL_FILE = ${TPL_PATH}/${STREAM_DEV_RESHUFFLER_TPL_RTL_FILENAME}

STREAM_GEN_TPL_SCALA_FILE = ${TPL_PATH}/${STREAM_TPL_SCALA_FILENAME}

STREAM_GEN_TPL_TB_FILE = ${TPL_PATH}/${STREAM_TPL_TB_FILENAME}
STREAM_TCDM_GEN_TPL_TB_FILE = ${TPL_PATH}/${STREAM_TCDM_TPL_TB_FILENAME}
STREAM_MUL_GEN_TPL_TB_FILE = ${TPL_PATH}/${STREAM_MUL_TPL_TB_FILENAME}
STREAM_RESHUFFLER_GEN_TPL_TB_FILE = ${TPL_PATH}/${STREAM_RESHUFFLER_TPL_TB_FILENAME}
STREAM_DEV_RESHUFFLER_GEN_TPL_TB_FILE = ${TPL_PATH}/${STREAM_DEV_RESHUFFLER_TPL_TB_FILENAME}

STREAM_GEN_OUT_SCALA_FILE = ${STREAM_OUT_SCALA_PATH}/${STREAM_SCALA_PARAM_FILENAME}

STREAM_GEN_OUT_RTL_FILE = $(RTL_PATH)/${STREAM_WRAPPER_FILENAME}
STREAM_MUL_OUT_RTL_FILE = $(RTL_PATH)/${STREAM_MUL_WRAPPER_FILENAME}
STREAM_RESHUFFLER_OUT_RTL_FILE = $(RTL_PATH)/${STREAM_RESHUFFLER_WRAPPER_FILENAME}
STREAM_DEV_RESHUFFLER_OUT_RTL_FILE = $(RTL_PATH)/${STREAM_DEV_RESHUFFLER_WRAPPER_FILENAME}

STREAM_GEN_OUT_TOP_FILE = $(RTL_PATH)/${STREAM_TOP_FILENAME}

STREAM_GEN_OUT_TB_FILE = $(TB_PATH)/${STREAM_TB_FILENAME}
STREAM_TCDM_GEN_OUT_TB_FILE = $(TB_PATH)/${STREAM_TCDM_TB_FILENAME}
STREAM_MUL_GEN_OUT_TB_FILE = $(TB_PATH)/${STREAM_MUL_TB_FILENAME}
STREAM_RESHUFFLER_GEN_OUT_TB_FILE = $(TB_PATH)/${STREAM_RESHUFFLER_TB_FILENAME}
STREAM_DEV_RESHUFFLER_GEN_OUT_TB_FILE = $(TB_PATH)/${STREAM_DEV_RESHUFFLER_TB_FILENAME}

#-----------------------------
# Useful function
#-----------------------------
define generate_file
	${PYTHON} util/scripts/template_gen.py --cfg_path="$(1)" \
	--tpl_path="$(2)" \
	--out_path="$(3)"
endef

#-----------------------------
# Generate Streamer Scala Parameter
#-----------------------------
$(STREAM_GEN_OUT_SCALA_FILE):
	$(call generate_file,${STREAM_GEN_CFG_FILE},${STREAM_GEN_TPL_SCALA_FILE},${STREAM_GEN_OUT_SCALA_FILE})

#-----------------------------
# Generate StreamTop.sv
#-----------------------------
$(STREAM_GEN_OUT_TOP_FILE):
	cd ${SNAX_STREAMER_PATH} && \
	sbt "runMain streamer.StreamerTopGen ${RTL_PATH}"
	@echo "Generates output: ${STREAM_GEN_OUT_TOP_FILE}"

#-----------------------------
# Generate tb_stream_top.sv
#-----------------------------
$(STREAM_GEN_OUT_RTL_FILE):
	$(call generate_file,${STREAM_GEN_CFG_FILE},${STREAM_GEN_TPL_RTL_FILE},${STREAM_GEN_OUT_RTL_FILE})

#-----------------------------
# Generate Streamer Wrapper Testbench
#-----------------------------
${STREAM_GEN_OUT_TB_FILE}:	$(STREAM_GEN_OUT_SCALA_FILE) $(STREAM_GEN_OUT_TOP_FILE) $(STREAM_GEN_OUT_RTL_FILE)
	$(call generate_file,${STREAM_GEN_CFG_FILE},${STREAM_GEN_TPL_TB_FILE},${STREAM_GEN_OUT_TB_FILE})

#-----------------------------
# Generate Streamer-TCDM Wrapper Testbench
#-----------------------------
${STREAM_TCDM_GEN_OUT_TB_FILE}:	$(STREAM_GEN_OUT_SCALA_FILE) $(STREAM_GEN_OUT_TOP_FILE) $(STREAM_GEN_OUT_RTL_FILE)
	$(call generate_file,${STREAM_GEN_CFG_FILE},${STREAM_TCDM_GEN_TPL_TB_FILE},${STREAM_TCDM_GEN_OUT_TB_FILE})

#-----------------------------
# Generate Stream-mul Wrapper
#-----------------------------
$(STREAM_MUL_OUT_RTL_FILE):
	$(call generate_file,${STREAM_GEN_CFG_FILE},${STREAM_MUL_TPL_RTL_FILE},${STREAM_MUL_OUT_RTL_FILE})

#-----------------------------
# Generate Streamer-MUL Wrapper Testbench
#-----------------------------
${STREAM_MUL_GEN_OUT_TB_FILE}: $(STREAM_GEN_OUT_SCALA_FILE) $(STREAM_GEN_OUT_TOP_FILE) $(STREAM_GEN_OUT_RTL_FILE) $(STREAM_MUL_OUT_RTL_FILE)
	$(call generate_file,${STREAM_GEN_CFG_FILE},${STREAM_MUL_GEN_TPL_TB_FILE},${STREAM_MUL_GEN_OUT_TB_FILE})

#-----------------------------
# Generate Stream-Reshuffler Wrapper
#-----------------------------
$(STREAM_RESHUFFLER_OUT_RTL_FILE):
	$(call generate_file,${STREAM_GEN_CFG_FILE},${STREAM_RESHUFFLER_TPL_RTL_FILE},${STREAM_RESHUFFLER_OUT_RTL_FILE})

#-----------------------------
# Generate Streamer-Reshuffler Wrapper Testbench
#-----------------------------
${STREAM_RESHUFFLER_GEN_OUT_TB_FILE}: $(STREAM_GEN_OUT_SCALA_FILE) $(STREAM_GEN_OUT_TOP_FILE) $(STREAM_GEN_OUT_RTL_FILE) $(STREAM_RESHUFFLER_OUT_RTL_FILE)
	$(call generate_file,${STREAM_GEN_CFG_FILE},${STREAM_RESHUFFLER_GEN_TPL_TB_FILE},${STREAM_RESHUFFLER_GEN_OUT_TB_FILE})

#-----------------------------
# Generate Dev-Stream-Reshuffler Wrapper
#-----------------------------
$(STREAM_DEV_RESHUFFLER_OUT_RTL_FILE):
	$(call generate_file,${STREAM_GEN_CFG_FILE},${STREAM_DEV_RESHUFFLER_TPL_RTL_FILE},${STREAM_DEV_RESHUFFLER_OUT_RTL_FILE})

#-----------------------------
# Generate Dev-Streamer-Reshuffler Wrapper Testbench
#-----------------------------
${STREAM_DEV_RESHUFFLER_GEN_OUT_TB_FILE}: $(STREAM_GEN_OUT_SCALA_FILE) $(STREAM_GEN_OUT_TOP_FILE) $(STREAM_GEN_OUT_RTL_FILE) $(STREAM_DEV_RESHUFFLER_OUT_RTL_FILE)
	$(call generate_file,${STREAM_GEN_CFG_FILE},${STREAM_DEV_RESHUFFLER_GEN_TPL_TB_FILE},${STREAM_DEV_RESHUFFLER_GEN_OUT_TB_FILE})


#-----------------------------
# Clean
#-----------------------------
clean:
	rm -f ${STREAM_GEN_OUT_RTL_FILE} ${STREAM_GEN_OUT_SCALA_FILE} \
	${STREAM_GEN_OUT_TOP_FILE} ${STREAM_GEN_OUT_TB_FILE} \
	${STREAM_TCDM_GEN_OUT_TB_FILE} ${STREAM_MUL_OUT_RTL_FILE} \
	${STREAM_MUL_GEN_OUT_TB_FILE} \
	${STREAM_RESHUFFLER_OUT_RTL_FILE} ${STREAM_RESHUFFLER_GEN_OUT_TB_FILE} \
	${STREAM_DEV_RESHUFFLER_OUT_RTL_FILE} ${STREAM_DEV_RESHUFFLER_GEN_OUT_TB_FILE} \
