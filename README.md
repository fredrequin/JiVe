
JiVe - A Size-Optimized Microcoded RISC-V CPU
=============================================

JiVe is a CPU core that implements the [RISC-V instruction set] (http://www.riscv.org/).

JiVe is free and open hardware licensed under the [BSD license](https://en.wikipedia.org/wiki/BSD_licenses).

Features and Typical Applications
---------------------------------

- Small (~860 LUTs + 2 x EBRs on an iCE40UP5K)
- 16-bit ALU (for registers operations, address computation and PC)
- Execute an instruction in ~20 cycles
- PC is stored in a special CSR (address 0x007)

This CPU is meant to be used in control applications that do not need important processing power.

Files in this Repository
------------------------

#### README.md

You are reading it right now.

#### src/jive_cpu_top.v

This is the top level of the JiVe CPU

#### src/jive_alu16.v

The 16-bit ALU (ADD, SUB, AND, OR, XOR, SHIFT).
The shifter is also the address register for the memory access.

#### src/jive_decode.v

Instruction decoder, it generates a 6-bit jump micro-address, a 4-bit ALU operation conrtol, the immediate value and latches the different fields from the instruction.

#### src/jive_reg_file.v

Memory containing the CPU registers (2 x 1024 bits), the micro-code ROM (2 x 1024 bits) and some CSRs (4 x 1024 bits)

#### src/jive_csr.v

Additional CSRs for the interrupt management (mie, mip, cycle, cycleh).

#### src/jive_ucode.v

File containing the micro-code ROM content.

#### src/jive_bootrom.v

Boot ROM that waits for an S-Record file on the serial port, loads it to RAM @ 0x80000000 and executes it.
(only used by Verilator testbench, real ROM is in the radiant folder).

#### src/jive_timer.v

Memory-mapped timer implementing time, timeh, timecmp and timecmph registers.

#### src/jive_uart.v

Simple Rx/Tx UART 8N1 at a fixed baudrate (19200).

#### src/jive_soc_top.v

Minimal system-on-a-chip required by the contest (~1600 LUTs).

#### src/tb/EBR_B.v

iCE40UP5K EBR model for Verilator.

#### src/tb/LSOSC.v

iCE40UP5K low frequency oscillator model for Verilator.

#### src/tb/SP256K.v

iCE40UP5K SPRAM model for Verilator.

#### boot/

Source code for the UART/S-Record bootloader

#### mem/

Memory initialization files for the boot ROM and the register file.

#### radiant/

Lattice Radiant project for the iCE40UP5K-B-EVN board.
It requires a PMOD USBUART on the PMOD connector for the UART communication.

#### verilator/compile.sh

Compile script for the Verilator testbench.
It also updates the JiVe simulator under riscv-compliance/riscv-jivesim

#### verilator/main.cpp

Main loop of the Verilator testbench.
Accepted "$value$plusargs" parameters :
+usec=<num>  : specify a simulation time in micro seconds.
+msec=<num>  : specify a simulation time in milli seconds.
+srec=<name> : specify a S-Record file name to load into SPRAM.
+syms=<name> : specify a symbols file name for signature range extraction.
+trc=<name>  : specify the trace file name for the RISC-V ISS
+vcd=<name>  : specify the VCD file name 

#### verilator/tb_top.v

Verilator testbench configuration file.

#### verilator/clock_gen/clock_gen.cpp/.h

Clock generator object to handle multiple clocks with different frequencies under Verilator.

#### verilator/riscv_trace/riscv_trace.cpp/.h

RISC-V ISS and tracing for the Verilator co-simulation.

#### riscv-compliance

RISC-V compliance tests, type "make" to run the RV32I ones for the JiVe soft CPU.
(first generate the RISC-V simulator with verilator/compile.sh)

#### tools/srecord/

SRecord v1.64 tool (http://srecord.sourceforge.net/).

#### zephyr

Zephyr 1.13.0 with the necessary changes for the iCE40UP5K-B-EVN board.
