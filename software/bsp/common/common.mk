# TARGET		?= common

RISCV_PATH 			:= /tools/Nuclei/toolchain/gcc
RISCV_TOOLS_DIR 	:= /tools/Nuclei/toolchain/gcc

RISCV_PREFIX 		?= ${RISCV_TOOLS_DIR}/bin/riscv64-unknown-elf-
RISCV_GCC 			?= $(RISCV_PREFIX)gcc
RISCV_GCC_OPTS 		?= -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles
RISCV_OBJDUMP 		?= $(RISCV_PREFIX)objdump --disassemble-all
RISCV_OBJCOPY 		?= $(RISCV_PREFIX)objcopy -O verilog

# RISCV_GCC     := $(abspath $(RISCV_PATH)/bin/riscv-none-embed-gcc)
# RISCV_AS      := $(abspath $(RISCV_PATH)/bin/riscv-none-embed-as)
# RISCV_GXX     := $(abspath $(RISCV_PATH)/bin/riscv-none-embed-g++)
# RISCV_OBJDUMP := $(abspath $(RISCV_PATH)/bin/riscv-none-embed-objdump)
# RISCV_GDB     := $(abspath $(RISCV_PATH)/bin/riscv-none-embed-gdb)
# RISCV_AR      := $(abspath $(RISCV_PATH)/bin/riscv-none-embed-ar)
# RISCV_OBJCOPY := $(abspath $(RISCV_PATH)/bin/riscv-none-embed-objcopy)
# RISCV_READELF := $(abspath $(RISCV_PATH)/bin/riscv-none-embed-readelf)

.PHONY: all
all: $(TARGET)

ASM_SRCS += $(COMMON_DIR)/start.S
ASM_SRCS += $(COMMON_DIR)/trap_entry.S

C_SRCS += $(COMMON_DIR)/trap_handler.c

LINKER_SCRIPT := $(COMMON_DIR)/link.lds

INCLUDES += -I $(COMMON_DIR)

LDFLAGS += -T $(LINKER_SCRIPT) -nostartfiles -Wl,--gc-sections -Wl,--check-sections

ASM_OBJS := $(ASM_SRCS:.S=.o)
C_OBJS := $(C_SRCS:.c=.o)

LINK_OBJS += $(ASM_OBJS) $(C_OBJS)
LINK_DEPS += $(LINKER_SCRIPT)

CLEAN_OBJS += $(TARGET) $(LINK_OBJS) $(TARGET).dump $(TARGET).bin

CFLAGS += -march=$(RISCV_ARCH)
CFLAGS += -mabi=$(RISCV_ABI)
CFLAGS += -mcmodel=$(RISCV_MCMODEL) -ffunction-sections -fdata-sections -fno-builtin-printf -fno-builtin-malloc

$(TARGET): $(LINK_OBJS) $(LINK_DEPS) Makefile
	$(RISCV_GCC) $(CFLAGS) $(INCLUDES) $(LINK_OBJS) -o $@ $(LDFLAGS)
	$(RISCV_OBJCOPY) -O binary $@ $@.bin
	$(RISCV_OBJDUMP) --disassemble-all $@ > $@.dump
	$(RISCV_OBJCOPY) $@ $@.verilog

$(ASM_OBJS): %.o: %.S
	echo $@
	$(RISCV_GCC) $(CFLAGS) $(INCLUDES) -c -o $@ $<

$(C_OBJS): %.o: %.c
	$(RISCV_GCC) $(CFLAGS) $(INCLUDES) -c -o $@ $<


.PHONY: clean show
clean:
	rm -f $(CLEAN_OBJS) *.verilog

show:
	@echo ${C_OBJS}
