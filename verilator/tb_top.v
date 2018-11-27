
// Trace configuration
// -------------------
`verilator_config

// RISC-V CPU :
//=============
tracing_on -file "../src/jive_decode.v"
tracing_on -file "../src/jive_reg_file.v"
tracing_on -file "../src/jive_alu16.v"
tracing_on -file "../src/jive_csr.v"
tracing_on -file "../src/jive_cpu_top.v"

// RISC-V PERIPHERALS :
//=====================
tracing_on -file "../src/jive_timer.v"
tracing_on -file "../src/jive_uart.v"

// RISC-V TEST BENCH :
//====================
tracing_on -file "../src/jive_soc_top.v"

`verilog

`include "../src/_ip_soc_jive.v"
