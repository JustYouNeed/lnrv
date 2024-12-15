SIM_DIR     	:= ${PWD}
RUN_DIR      	:= ${SIM_DIR}/run
TB_DIR 			:= ${SIM_DIR}/../tb
TB_TOP 			:= lnrv_cpu_tb

TEST_NAME     	:= rv32si-p-wfi
TEST_CASE     	:= ${RUN_DIR}/../../riscv-tools/riscv-tests/isa/generated/${TEST_NAME}

SIM_TOOL       	:= vcs 
DUMPWAVE     	:= 1

CORE        := e203
CFG         := ${CORE}_config


CORE_NAME = $(shell echo $(CORE) | tr a-z A-Z)
core_name = $(shell echo $(CORE) | tr A-Z a-z)

all: run_test

install: 
	mkdir -p ${SIM_DIR}/install/tb
	cp ${TB_DIR}/*.v ${SIM_DIR}/install/tb -rf
	cp ${SIM_DIR}/../rtl/${core_name} ${SIM_DIR}/install/rtl -rf

${RUN_DIR}:
	mkdir -p ${RUN_DIR}
	rm -f ${RUN_DIR}/Makefile
	ln -s ${SIM_DIR}/Makefile.run ${RUN_DIR}/Makefile

# 编译代码
compile: ${RUN_DIR}
	make compile RUN_DIR=${RUN_DIR} SIM_TOOL=${SIM_TOOL} -C ${RUN_DIR}

# 打开波形文件
wave: ${RUN_DIR}
	make wave TESTCASE=${TEST_CASE} SIM_TOOL=${SIM_TOOL} RUN_DIR=${RUN_DIR} -C ${RUN_DIR}

# 运行测试
run_test: compile
	make run DUMPWAVE=${DUMPWAVE} TESTCASE=${TEST_CASE} SIM_TOOL=${SIM_TOOL} RUN_DIR=${RUN_DIR} -C ${RUN_DIR}

SELF_TESTS := $(patsubst %.dump,%,$(wildcard ${SIM_DIR}/../riscv-tools/riscv-tests/isa/generated/rv32uc-p*.dump))
ifeq ($(core_name),${E203})
SELF_TESTS += $(patsubst %.dump,%,$(wildcard ${SIM_DIR}/../riscv-tools/riscv-tests/isa/generated/rv32um-p*.dump))
SELF_TESTS += $(patsubst %.dump,%,$(wildcard ${SIM_DIR}/../riscv-tools/riscv-tests/isa/generated/rv32ua-p*.dump))
endif

SELF_TESTS += $(patsubst %.dump,%,$(wildcard ${SIM_DIR}/../riscv-tools/riscv-tests/isa/generated/rv32ui-p*.dump))
# SELF_TESTS += $(patsubst %.dump,%,$(wildcard ${RUN_DIR}/../../riscv-tools/riscv-tests/isa/generated/rv32mi-p*.dump))

regress_prepare:
	make compile
	@-rm -rf ${RUN_DIR}/rv32*.log
regress_run:
	$(foreach tst,$(SELF_TESTS), make run_test DUMPWAVE=0 TEST_CASE=$(tst) RUN_DIR=${RUN_DIR};)
regress_collect:
	@-rm -rf ${RUN_DIR}/regress.res
	@find ${RUN_DIR} -name "rv32*.log" -exec bin/find_test_fail.csh {} >> ${RUN_DIR}/regress.res \;
	@cat ${RUN_DIR}/regress.res
regress: regress_prepare regress_run regress_collect 

echo:
	echo ${SELF_TESTS}

clean:
	rm -rf run
	rm -rf install

.PHONY: compile run install clean all run_test regress regress_prepare regress_run regress_collect 

