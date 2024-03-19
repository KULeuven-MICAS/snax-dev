#-----------------------------
# Path Declarations 
#-----------------------------
BENDER = bender
PYTHON = python3

ifndef SNAX_DEV_ROOT
	SNAX_DEV_ROOT = ${CURDIR}
endif

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

STREAM_WRAPPER_FILENAME ?= streamer_wrapper.sv
STREAM_MUL_WRAPPER_FILENAME ?= stream_alu_wrapper.sv

STREAM_SCALA_PARAM_FILENAME ?= StreamParamGen.scala

STREAM_TOP_FILENAME ?= StreamerTop.sv

STREAM_TB_FILENAME ?= tb_streamer_top.sv
STREAM_TCDM_TB_FILENAME ?= tb_stream_tcdm_top.sv
STREAM_MUL_TB_FILENAME ?= tb_stream_alu.sv

#-----------------------------
# Default Path Declarations 
#-----------------------------
SNAX_STREAMER_PATH = $(shell $(BENDER) path snax-streamer)
CFG_PATH ?= ${SNAX_DEV_ROOT}/util/cfg
TPL_PATH ?= ${SNAX_DEV_ROOT}/util/templates
RTL_PATH ?= ${SNAX_DEV_ROOT}/rtl
TB_PATH ?= ${SNAX_DEV_ROOT}/tests/tb
STREAM_OUT_SCALA_PATH ?= ${SNAX_STREAMER_PATH}/src/main/scala/streamer

#-----------------------------
# Default Path and File Declarations
#-----------------------------
STREAM_GEN_CFG_FILE = ${CFG_PATH}/${STREAM_CFG_FILENAME}

STREAM_GEN_TPL_RTL_FILE = ${TPL_PATH}/${STREAM_TPL_RTL_FILENAME}
STREAM_MUL_TPL_RTL_FILE = ${TPL_PATH}/${STREAM_MUL_TPL_RTL_FILENAME}

STREAM_GEN_TPL_SCALA_FILE = ${TPL_PATH}/${STREAM_TPL_SCALA_FILENAME}

STREAM_GEN_TPL_TB_FILE = ${TPL_PATH}/${STREAM_TPL_TB_FILENAME}
STREAM_TCDM_GEN_TPL_TB_FILE = ${TPL_PATH}/${STREAM_TCDM_TPL_TB_FILENAME}
STREAM_MUL_GEN_TPL_TB_FILE = ${TPL_PATH}/${STREAM_MUL_TPL_TB_FILENAME}

STREAM_GEN_OUT_SCALA_FILE = ${STREAM_OUT_SCALA_PATH}/${STREAM_SCALA_PARAM_FILENAME}

STREAM_GEN_OUT_RTL_FILE = $(RTL_PATH)/${STREAM_WRAPPER_FILENAME}
STREAM_MUL_OUT_RTL_FILE = $(RTL_PATH)/${STREAM_MUL_WRAPPER_FILENAME}

STREAM_GEN_OUT_TOP_FILE = $(RTL_PATH)/${STREAM_TOP_FILENAME}

STREAM_GEN_OUT_TB_FILE = $(TB_PATH)/${STREAM_TB_FILENAME}
STREAM_TCDM_GEN_OUT_TB_FILE = $(TB_PATH)/${STREAM_TCDM_TB_FILENAME}
STREAM_MUL_GEN_OUT_TB_FILE = $(TB_PATH)/${STREAM_MUL_TB_FILENAME}

#-----------------------------
# Useful function
#-----------------------------
define generate_file
	${PYTHON} ${SNAX_DEV_ROOT}/util/scripts/template_gen.py --cfg_path="$(1)" \
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
# Generate Streamer Wrapper
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

#####################################
# Added by xyi for Streamer-GEMM
#####################################

GEMM_SV_PATH = ${SNAX_DEV_ROOT}/rtl/streamer-gemm
SNAX_GEMM_PATH = $(shell $(BENDER) path snax-gemm)

#-----------------------------
# Generate BareBlockGemmTop.sv
#-----------------------------

GEMM_TOP_FILENAME ?= BareBlockGemmTop.sv
GEMM_GEN_OUT_TOP_FILE ?= $(GEMM_SV_PATH)/${GEMM_TOP_FILENAME}

$(GEMM_GEN_OUT_TOP_FILE):
	mkdir ${GEMM_SV_PATH} || \
	cd ${SNAX_GEMM_PATH} && \
	sbt "runMain gemm.BareBlockGemmTopGen ${GEMM_SV_PATH}"
	@echo "Generates output for GEMM: ${GEMM_GEN_OUT_TOP_FILE}"

#-----------------------------
# Generate streamer related files
#-----------------------------

#-----------------------------
# Generate StreamerTop.sv for GEMM
#-----------------------------

GEMM_STREAMER = $(GEMM_SV_PATH)/StreamerTop.sv
$(GEMM_STREAMER):
	cd ${SNAX_STREAMER_PATH} && \
	sbt "runMain streamer.GeMMStreamerTop ${GEMM_SV_PATH}"
	@echo "Generates output for Streamer for SIMD: ${GEMM_STREAMER}"

#-----------------------------
# Generate Streamer Wrapper
#-----------------------------

STREAM_GEMM_CFG_FILENAME ?= streamer_gemm_cfg.hjson
STREAM_GEMM_CFG_FILE = ${CFG_PATH}/${STREAM_GEMM_CFG_FILENAME}

STREAM_FOR_GEMM_WRAPPER = $(GEMM_SV_PATH)/streamer_for_gemm_wrapper.sv
$(STREAM_FOR_GEMM_WRAPPER):
	$(call generate_file,${STREAM_GEMM_CFG_FILE},${STREAM_GEN_TPL_RTL_FILE},${STREAM_FOR_GEMM_WRAPPER})

#-----------------------------
# Generate streamer_gemm_wrapper.sv
#-----------------------------

STREAM_GEMM_WRAPPER_TPL_RTL_FILENAME ?= streamer_gemm_wrapper.sv.tpl
STREAM_GEMM_TPL_RTL_FILE = ${TPL_PATH}/${STREAM_GEMM_WRAPPER_TPL_RTL_FILENAME}

STREAM_GEMM_WRAPPER_FILENAME ?= streamer_gemm_wrapper.sv
STREAM_GEMM_OUT_RTL_FILE ?= $(GEMM_SV_PATH)/${STREAM_GEMM_WRAPPER_FILENAME}

# streamer_gemm_wrapper replies on gemm.sv, streamer.sv, streamer_wrapper.sv
$(STREAM_GEMM_OUT_RTL_FILE): $(STREAM_GEMM_CFG_FILE) $(GEMM_GEN_OUT_TOP_FILE) $(GEMM_STREAMER) $(STREAM_FOR_GEMM_WRAPPER)
	$(call generate_file,${STREAM_GEMM_CFG_FILE},${STREAM_GEMM_TPL_RTL_FILE},${STREAM_GEMM_OUT_RTL_FILE})

#-----------------------------
# Generate tb_streamer_gemm.sv
#-----------------------------
STREAM_GEMM_TB_TPL_FILENAME ?= tb_streamer_gemm.sv.tpl
STREAM_GEMM_TB_FILENAME ?= tb_streamer_gemm.sv

STREAM_GEMM_TB_TPL_FILE = ${TPL_PATH}/${STREAM_GEMM_TB_TPL_FILENAME}
STREAM_GEMM_OUT_TB_FILE = ${TB_PATH}/${STREAM_GEMM_TB_FILENAME}

$(STREAM_GEMM_OUT_TB_FILE): $(STREAM_GEMM_OUT_RTL_FILE) $(STREAM_FOR_GEMM_WRAPPER)
	$(call generate_file,${STREAM_GEMM_CFG_FILE},${STREAM_GEMM_TB_TPL_FILE},${STREAM_GEMM_OUT_TB_FILE})


#-----------------------------
# Clean
#-----------------------------
clean:
	rm -rf ${STREAM_GEN_OUT_RTL_FILE} ${STREAM_GEN_OUT_SCALA_FILE} \
	${STREAM_GEN_OUT_TOP_FILE} ${STREAM_GEN_OUT_TB_FILE} \
	${STREAM_TCDM_GEN_OUT_TB_FILE} ${STREAM_MUL_OUT_RTL_FILE} \
	${STREAM_MUL_GEN_OUT_TB_FILE} \
	$(GEMM_GEN_OUT_TOP_FILE) $(STREAM_GEMM_SCALA_FILE) $(STREAM_FOR_GEMM_WRAPPER) $(STREAM_GEMM_OUT_RTL_FILE) \
	$(GEMM_GEN_OUT_TOP_FILE) $(GEMM_STREAMER) $(STREAM_FOR_GEMM_WRAPPER) $(STREAM_GEMM_OUT_RTL_FILE) $(STREAM_GEMM_OUT_TB_FILE) \
	.bender Bender.lock \
	./tests/cocotb/sim_build ./tests/cocotb/__pycache__
