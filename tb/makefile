inc_dir = "../rtl/core"

src_list = 	"../rtl/gen/lnrv_gnrl_fifo.v" \
			"../rtl/gen/lnrv_gnrl_buffer.v" \
			"../rtl/core/idu/lnrv_idu_decode.v" \
			"../rtl/core/idu/lnrv_idu.v" 		\
			"../rtl/core/ifu/lnrv_ifu.v" 		\
			"../rtl/core/ifu/lnrv_ifu_ifetch.v" 		\
			"../rtl/core/reg/lnrv_gpr.v" 		\
			"../rtl/core/reg/lnrv_csr.v" 		\
			"../rtl/core/biu/lnrv_biu.v" 		\
			"../rtl/core/exu/lnrv_exu_alu_mux.v" 	\
			"../rtl/core/exu/lnrv_exu_alu.v" 		\
			"../rtl/core/exu/lnrv_exu_brch.v" 		\
			"../rtl/core/exu/lnrv_exu_cmt.v" 		\
			"../rtl/core/exu/lnrv_exu_csr.v" 		\
			"../rtl/core/exu/lnrv_exu_debug.v" 		\
			"../rtl/core/exu/lnrv_exu_disp.v" 		\
			"../rtl/core/exu/lnrv_exu_excp.v" 		\
			"../rtl/core/exu/lnrv_exu_irq.v" 		\
			"../rtl/core/exu/lnrv_exu_lsu.v" 		\
			"../rtl/core/exu/lnrv_exu_mdv.v" 		\
			"../rtl/core/exu/lnrv_exu_rglr.v" 		\
			"../rtl/core/exu/lnrv_exu_sys.v" 		\
			"../rtl/core/exu/lnrv_exu_wbck.v" 		\
			"../rtl/core/exu/lnrv_exu.v" 		\
			"../rtl/gen/lnrv_gnrl_arbiter.v"	\
			"../rtl/gen/lnrv_icb_cmd_buf.v"			\
			"../rtl/gen/lnrv_icb_rsp_buf.v"			\
			"../rtl/gen/lnrv_icb_buf.v"			\
			"../rtl/bus/lnrv_icb_demux.v"		\
			"../rtl/bus/lnrv_icb_mux.v"			\
			"../rtl/gen/lnrv_icb2sram.v"		\
			"../rtl/gen/lnrv_gen_ram.v"			\
			"../rtl/core/top/lnrv_cpu.v"		\
			"../rtl/core/top/lnrv_core.v"		

SIM_DIR 		:= .
RTL_DIR 		:= ${SIM_DIR}/../design/rtl

RTL_FILES 		:= $(wildcard ${RTL_DIR}/*/*.v)
TB_DIR 			:= ${SIM_DIR}
TB_TOP 			:= lnrv_cpu_tb
TB_FILE 		:= ${TB_DIR}/${TB_TOP}.v

SIM_TOOL 		:= iverilog
SIM_OPTIONS		:= -I ${inc_dir} -o wave -s ${TB_TOP} -D DISABLE_SV_ASSERTION=1 -g2005 

com:
	${SIM_TOOL} ${SIM_OPTIONS} ${src_list} ${TB_FILE} 
	vvp -n wave -lxt2

wave:
	gtkwave wave.vcd
	@echo ${SIM_DIR}

clean:
	rm wave
	rm wave.vcd

.PHONY : com wave clean