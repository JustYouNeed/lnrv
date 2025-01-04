BSP_DIR 	= ../../bsp
COMMON_DIR	= $(BSP_DIR)/common

RISCV_ARCH := rv32i
RISCV_ABI := ilp32
RISCV_MCMODEL := medlow

TARGET 		= helloworld


CFLAGS += -DSIMULATION
#CFLAGS += -O2
#ASM_SRCS +=
#LDFLAGS +=
#INCLUDES += -I.

C_SRCS := \
	main.c \


include $(COMMON_DIR)/common.mk
