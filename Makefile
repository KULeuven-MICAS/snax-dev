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

STREAM_WRAPPER_FILENAME ?= streamer_wrapper.sv

STREAM_SCALA_PARAM_FILENAME ?= StreamParamGen.scala

STREAM_TOP_FILENAME ?= StreamerTop.sv

STREAM_TB_FILENAME ?= tb_streamer_top.sv
STREAM_TCDM_TB_FILENAME ?= tb_stream_tcdm_top.sv

#-----------------------------
# Default Path Declarations 
#-----------------------------
SNAX_STREAMER_PATH = $(shell $(BENDER) path snax-streamer)
STREAM_CFG_PATH ?= ${CURDIR}/util/cfg
STREAM_TPL_PATH ?= ${CURDIR}/util/templates
STREAM_OUT_RTL_PATH ?= ${CURDIR}/rtl
STREAM_OUT_TB_PATH ?= ${CURDIR}/tests/tb
STREAM_OUT_SCALA_PATH ?= ${SNAX_STREAMER_PATH}/src/main/scala/streamer
STREAM_OUT_TOP_PATH ?= ${STREAM_OUT_RTL_PATH}

#-----------------------------
# Default Path and File Declarations
#-----------------------------
STREAM_GEN_CFG_FILE = ${STREAM_CFG_PATH}/${STREAM_CFG_FILENAME}

STREAM_GEN_TPL_RTL_FILE = ${STREAM_TPL_PATH}/${STREAM_TPL_RTL_FILENAME}
STREAM_GEN_TPL_TB_FILE = ${STREAM_TPL_PATH}/${STREAM_TPL_TB_FILENAME}
STREAM_TCDM_GEN_TPL_TB_FILE = ${STREAM_TPL_PATH}/${STREAM_TCDM_TPL_TB_FILENAME}
STREAM_GEN_TPL_SCALA_FILE = ${STREAM_TPL_PATH}/${STREAM_TPL_SCALA_FILENAME}

STREAM_GEN_OUT_SCALA_FILE = ${STREAM_OUT_SCALA_PATH}/${STREAM_SCALA_PARAM_FILENAME}

STREAM_GEN_OUT_RTL_FILE = $(STREAM_OUT_RTL_PATH)/${STREAM_WRAPPER_FILENAME}

STREAM_GEN_OUT_TOP_FILE = $(STREAM_OUT_TOP_PATH)/${STREAM_TOP_FILENAME}

STREAM_GEN_OUT_TB_FILE = $(STREAM_OUT_TB_PATH)/${STREAM_TB_FILENAME}
STREAM_TCDM_GEN_OUT_TB_FILE = $(STREAM_OUT_TB_PATH)/${STREAM_TCDM_TB_FILENAME}

#-----------------------------
# Generate Streamer Scala Parameter
#-----------------------------
$(STREAM_GEN_OUT_SCALA_FILE):
	${PYTHON} util/scripts/template_gen.py --cfg_path="${STREAM_GEN_CFG_FILE}" \
	--tpl_path="${STREAM_GEN_TPL_SCALA_FILE}" \
	--out_path="${STREAM_GEN_OUT_SCALA_FILE}"

#-----------------------------
# Generate StreamTop.sv
#-----------------------------
$(STREAM_GEN_OUT_TOP_FILE):
	cd ${SNAX_STREAMER_PATH} && \
	sbt "runMain streamer.StreamerTopGen ${STREAM_OUT_TOP_PATH}"
	@echo "Generates output: ${STREAM_GEN_OUT_TOP_FILE}"

#-----------------------------
# Generate tb_stream_top.sv
#-----------------------------
$(STREAM_GEN_OUT_RTL_FILE):
	${PYTHON} util/scripts/template_gen.py --cfg_path="${STREAM_GEN_CFG_FILE}" \
	--tpl_path="${STREAM_GEN_TPL_RTL_FILE}" \
	--out_path="${STREAM_GEN_OUT_RTL_FILE}"

#-----------------------------
# Generate Streamer Wrapper Testbench
#-----------------------------
${STREAM_GEN_OUT_TB_FILE}:	$(STREAM_GEN_OUT_SCALA_FILE) $(STREAM_GEN_OUT_TOP_FILE) $(STREAM_GEN_OUT_RTL_FILE)
	${PYTHON} util/scripts/template_gen.py --cfg_path="${STREAM_GEN_CFG_FILE}" \
	--tpl_path="${STREAM_GEN_TPL_TB_FILE}" \
	--out_path="${STREAM_GEN_OUT_TB_FILE}"

#-----------------------------
# Generate Streamer-TCDM Wrapper Testbench
#-----------------------------
${STREAM_TCDM_GEN_OUT_TB_FILE}:	$(STREAM_GEN_OUT_SCALA_FILE) $(STREAM_GEN_OUT_TOP_FILE) $(STREAM_GEN_OUT_RTL_FILE)
	${PYTHON} util/scripts/template_gen.py --cfg_path="${STREAM_GEN_CFG_FILE}" \
	--tpl_path="${STREAM_TCDM_GEN_TPL_TB_FILE}" \
	--out_path="${STREAM_TCDM_GEN_OUT_TB_FILE}"

#-----------------------------
# Clean
#-----------------------------
clean:
	rm -f ${STREAM_GEN_OUT_RTL_FILE} ${STREAM_GEN_OUT_SCALA_FILE} \
	${STREAM_GEN_OUT_TOP_FILE} ${STREAM_GEN_OUT_TB_FILE} ${STREAM_TCDM_GEN_OUT_TB_FILE}
