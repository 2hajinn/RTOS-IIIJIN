ARCH = armv7-a
MCPU = cortex-a8

TARGET = rvpb

CC = arm-none-eabi-gcc
AS = arm-none-eabi-as
LD = arm-none-eabi-gcc
OC = arm-none-eabi-objcopy
OD = arm-none-eabi-objdump

LINKER_SCRIPT = ./iiijin.ld
MAP_FILE = build/iiijin.map
SYM_FILE = build/iiijin.sym

ASM_SRCS = $(wildcard boot/*.S)
ASM_OBJS = $(patsubst boot/%.S, build/%.os, $(ASM_SRCS))

VPATH = boot \
	hal/$(TARGET) \
	lib \
	kernel

C_SRCS = $(notdir $(wildcard boot/*.c))
C_SRCS += $(notdir $(wildcard hal/$(TARGET)/*.c))
C_SRCS += $(notdir $(wildcard lib/*.c))
C_SRCS += $(notdir $(wildcard kernel/*.c))
C_OBJS = $(patsubst %.c, build/%.o, $(C_SRCS))

INC_DIRS = -I include   \
	   -I hal   \
	   -I hal/$(TARGET) \
	   -I lib \
	   -I kernel

CFLAGS = -c -g -std=c11 -mthumb-interwork

LDFLAGS = -nostartfiles -nostdlib -nodefaultlibs -static -lgcc

iiijin = build/iiijin.axf
iiijin_bin = build/iiijin.bin

.PHONY: all clean run debug gdb

all: $(iiijin)

clean:
	@rm -fr build

run: $(iiijin)
	qemu-system-arm -M realview-pb-a8 -kernel $(iiijin) -nographic

debug: $(iiijin)
	qemu-system-arm -M realview-pb-a8 -kernel $(iiijin) -S -gdb tcp::1234,ipv4

gdb:
	gdb-multiarch

kill:
	kill -9 `ps aux | grep 'qemu' | awk 'NR==1{print $$2}'`

$(iiijin): $(ASM_OBJS) $(C_OBJS) $(LINKER_SCRIPT)
	$(LD) -n -T $(LINKER_SCRIPT) -o $(iiijin) $(ASM_OBJS) $(C_OBJS) -Wl,-Map=$(MAP_FILE) $(LDFLAGS)
	$(OD) -t $(iiijin) > $(SYM_FILE)
	$(OC) -O binary $(iiijin) $(iiijin_bin)

build/%.os: %.S
	mkdir -p $(shell dirname $@)
	$(CC) -march=$(ARCH) -mtune=$(MCPU) -marm $(INC_DIRS) $(CFLAGS) -o $@ $<

build/%.o: %.c
	mkdir -p $(shell dirname $@)
	$(CC) -march=$(ARCH) -mtune=$(MCPU) -marm $(INC_DIRS) $(CFLAGS) -o $@ $<
