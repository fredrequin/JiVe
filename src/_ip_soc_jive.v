
// RISC-V CPU :
//=============
`include "../src/_ip_cpu_jive.v"

// RISC-V PERIPHERALS :
//=====================
`include "../src/jive_timer.v"
`include "../src/jive_uart.v"

// RISC-V TOP LEVEL :
//===================
`include "../src/jive_soc_top.v"

// FOR TESTBENCH :
// ===============
`ifdef verilator3
`include "../tb/EBR_B.v"
`include "../tb/LSOSC.v"
`include "../tb/SP256K.v"
`include "../src/jive_bootrom.v"
`endif
