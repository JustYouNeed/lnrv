
TB_TOP 			:= lnrv_cpu_tb

SIM_DIR 		:= ${PWD}


TEST_CASE 		:= ${SIM_DIR}/../riscv-tools/riscv-tests/isa/generated/rv32ui-p-addi
TEST_NAME 		:= $(notdir $(patsubst %.dump,%,${TESTCASE}.dump))
TEST_RUNDIR  	:= ${TESTNAME}

TB_DIR 			:= ${SIM_DIR}/../tb
RTL_DIR 		:= ${SIM_DIR}/../design/rtl

RTL_V_FILES 	:= $(wildcard ${RTL_DIR}/*/*.v)
TB_V_FILES		:= ${TB_DIR}/${TB_TOP}.v

SIM_TOOL 		:= vcs

INC_DIR 		:= ${SIM_DIR}/../rtl/core

# 
ifeq (${SIM_TOOL},vcs)
FILE_LIST 		:= ${SIM_DIR}/../tb/filelist.f
else
FILE_LIST 		:= ${RTL_V_FILES}
endif

ifeq (${SIM_TOOL},vcs)
SIM_OPTIONS   	:= +v2k 
SIM_OPTIONS  	+= -sverilog 
SIM_OPTIONS 	+= -q 
SIM_OPTIONS 	+= +lint=all,noSVA-NSVU,noVCDE,noUI,noSVA-CE,noSVA-DIU  
SIM_OPTIONS 	+= -debug_access+all 
SIM_OPTIONS 	+= -full64 
SIM_OPTIONS 	+= -timescale=1ns/10ps 
SIM_OPTIONS 	+= -cpp g++-4.8 
SIM_OPTIONS 	+= -cc gcc-4.8 
SIM_OPTIONS 	+= -LDFLAGS -Wl,--no-as-needed
SIM_OPTIONS   	+= $(foreach n, ${INC_DIR}, +incdir+${n})
SIM_OPTIONS 	+= -f ${FILE_LIST}
endif

ifeq ($(SIM_TOOL),iverilog)
SIM_OPTIONS		:= -I ${inc_dir} -o wave -s ${TB_TOP} -D DISABLE_SV_ASSERTION=1 -g2005 
endif

ifeq ($(SIM_TOOL),vcs)
SIM_EXEC      := ${RUN_DIR}/simv +ntb_random_seed_automatic
endif

ifeq (${SIM_TOOL},iverilog)
SIM_EXEC      := vvp ${RUN_DIR}/vvp.exec -lxt2	
endif

# waveform tool
ifeq ($(SIM_TOOL),vcs)
WAV_TOOL := verdi
endif
ifeq ($(SIM_TOOL),iverilog) 
WAV_TOOL := gtkwave
endif

# waveform file
ifeq ($(WAV_TOOL),verdi)
WAV_FILE      := -ssf ${TEST_RUNDIR}/tb_top.fsdb
endif
ifeq ($(WAV_TOOL),gtkwave)
WAV_FILE      := ${TEST_RUNDIR}/tb_top.vcd
endif

all: run

compile.flg: ${RTL_V_FILES} ${TB_V_FILES}
	@-rm -rf compile.flg
# sed -i '1i\`define ${SIM_TOOL}\'  ${VTB_DIR}/tb_top.v
	${SIM_TOOL} ${SIM_OPTIONS} ${TB_V_FILES} ;
	touch compile.flg

compile: compile.flg 

wave: 
	gvim -p ${TESTCASE}.spike.log ${TESTCASE}.dump &
	${WAV_TOOL} ${WAV_OPTIONS} ${WAV_INC} ${WAV_RTL} ${WAV_FILE}  & 

run: compile
	rm -rf ${TEST_RUNDIR}
	mkdir ${TEST_RUNDIR}
	cd ${TEST_RUNDIR}; ${SIM_EXEC} +DUMPWAVE=${DUMPWAVE} +TESTCASE=${TESTCASE} +SIM_TOOL=${SIM_TOOL} 2>&1 | tee ${TESTNAME}.log; cd ${RUN_DIR}; 


.PHONY: run clean all 

# com:
# 	${SIM_TOOL} ${SIM_OPTIONS} ${src_list} ${TB_FILE} 
# 	vvp -n wave -lxt2

# wave:
# 	gtkwave wave.vcd
# 	@echo ${SIM_DIR}

# clean:
# 	rm wave
# 	rm wave.vcd

# .PHONY : com wave clean