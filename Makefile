#-----------------------------
# Path Declarations 
#-----------------------------
BENDER = bender
PYTHON = python3

#-----------------------------
# Default Filename Declarations
#-----------------------------
STREAM_CFG_FILENAME ?= streamer_cfg.hjson
STREAM_TPL_SV_FILENAME ?= streamer_wrapper.sv.tpl
STREAM_TPL_SCALA_FILENAME ?= StreamParamGen.scala.tpl
STREAM_WRAPPER_FILENAME ?= streamer_wrapper.sv
STREAM_SCALA_PARAM_FILENAME ?= StreamParamGen.scala
STREAM_TOP_FILENAME ?= StreamerTop.sv

#-----------------------------
# Default Path Declarations 
#-----------------------------
SNAX_STREAMER_PATH = $(shell $(BENDER) path snax-streamer)
STREAM_CFG_PATH ?= ${CURDIR}/util/cfg
STREAM_TPL_PATH ?= ${CURDIR}/util/templates
STREAM_OUT_SV_PATH ?= ${CURDIR}/rtl
STREAM_OUT_SCALA_PATH ?= ${SNAX_STREAMER_PATH}/src/main/scala/streamer
STREAM_OUT_TOP_PATH ?= ${STREAM_OUT_SV_PATH}

STREAM_GEN_CFG_PATH = ${STREAM_CFG_PATH}/${STREAM_CFG_FILENAME}
STREAM_GEN_TPL_SV_PATH = ${STREAM_TPL_PATH}/${STREAM_TPL_SV_FILENAME}
STREAM_GEN_TPL_SCALA_PATH = ${STREAM_TPL_PATH}/${STREAM_TPL_SCALA_FILENAME}
STREAM_GEN_OUT_SV_PATH = $(STREAM_OUT_SV_PATH)/${STREAM_WRAPPER_FILENAME}
STREAM_GEN_OUT_SCALA_PATH = ${STREAM_OUT_SCALA_PATH}/${STREAM_SCALA_PARAM_FILENAME}
STREAM_GEN_OUT_TOP_PATH = $(STREAM_OUT_TOP_PATH)/${STREAM_TOP_FILENAME}

#-----------------------------
# Generate streamer wrapper
#-----------------------------
$(STREAM_GEN_OUT_SV_PATH):
	python3 util/scripts/template_gen.py --cfg_path="${STREAM_GEN_CFG_PATH}" \
	--tpl_path="${STREAM_GEN_TPL_SV_PATH}" \
	--out_path="${STREAM_GEN_OUT_SV_PATH}"

#-----------------------------
# Generate streamer scala parameter
#-----------------------------
$(STREAM_GEN_OUT_SCALA_PATH):
	python3 util/scripts/template_gen.py --cfg_path="${STREAM_GEN_CFG_PATH}" \
	--tpl_path="${STREAM_GEN_TPL_SCALA_PATH}" \
	--out_path="${STREAM_GEN_OUT_SCALA_PATH}"

#-----------------------------
# Generate StreamTop.sv
#-----------------------------
gen_stream_top: $(STREAM_GEN_OUT_SV_PATH) $(STREAM_GEN_OUT_SCALA_PATH)
	cd ${SNAX_STREAMER_PATH} && \
	sbt "runMain streamer.StreamerTopGen ${STREAM_OUT_TOP_PATH}"
	@echo "Generates output: ${STREAM_GEN_OUT_TOP_PATH}"

#-----------------------------
# Clean
#-----------------------------
clean:
	rm -f ${STREAM_GEN_OUT_SV_PATH} ${STREAM_GEN_OUT_SCALA_PATH} ${STREAM_GEN_OUT_TOP_PATH}

debug_path:
	@echo ${STREAM_GEN_OUT_TOP_PATH}
