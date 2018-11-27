RISCV_CC=riscv32-unknown-elf-gcc
RISCV_LD=riscv32-unknown-elf-ld
RISCV_OBJCOPY=riscv32-unknown-elf-objcopy
RISCV_OBJDUMP=riscv32-unknown-elf-objdump

SREC_CAT ?= ../tools/srecord/srec_cat

BINFILE=uart_boot.bin
HEXFILE=uart_boot.hex
MEMFILE=uart_boot.mem
MIFFILE=uart_boot.mif

LIBS= -L/usr/riscv/lib/gcc/riscv32-unknown-elf/8.2.0/rv32i/ilp32 -lgcc
CFLAGS=-MMD -Os -Wall -g -s -march=rv32i -mabi=ilp32 -static -nostdlib -nostartfiles
LDFLAGS=-nostartfiles $(LIBS) -Tuart_boot.ld
SEGMENTS = -j .boot -j .text -j .rodata -j .data

all: $(BINFILE) $(HEXFILE) $(MEMFILE) $(MIFFILE) $(COEFILE)

crt0_boot.o: crt0_boot.S
	$(RISCV_CC) $(CFLAGS) -c crt0_boot.S

uart_boot.o: uart_boot.c
	$(RISCV_CC) $(CFLAGS) -c uart_boot.c

uart_boot.elf: crt0_boot.o uart_boot.o
	$(RISCV_LD) crt0_boot.o uart_boot.o $(LDFLAGS) --cref -Map uart_boot.map -n -o uart_boot.elf

uart_boot.lst: uart_boot.elf
	$(RISCV_OBJDUMP) -h -S $< > $@

uart_boot.srec: uart_boot.elf uart_boot.lst
	$(RISCV_OBJCOPY) $(SEGMENTS) -O srec uart_boot.elf uart_boot.srec

$(BINFILE): uart_boot.srec
	$(SREC_CAT) uart_boot.srec -fill 0x00 0x000 0x400 -o $(BINFILE) -binary
    
$(HEXFILE): $(BINFILE)
	$(SREC_CAT) $(BINFILE) -binary -o $(HEXFILE) -intel

$(MEMFILE): $(BINFILE)
	$(SREC_CAT) $(BINFILE) -binary -byte-swap 4 -o $(MEMFILE) -mem 32

$(MIFFILE): $(BINFILE)
	$(SREC_CAT) $(BINFILE) -binary -byte-swap 4 -o $(MIFFILE) -mif 32

clean:
	rm -f uart_boot.elf uart_boot.lst uart_boot.srec uart_boot.map  *.o *.d

DEPS := $(wildcard *.d)
ifneq ($(DEPS),)
include $(DEPS)
endif
