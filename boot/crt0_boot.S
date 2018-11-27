    .section    .boot, "ax", @progbits
    .global     _start
_start:

    /* Set all registers to zero */
    mv      x1, x0
    mv      x2, x0
    mv      x3, x0
    mv      x4, x0
    mv      x5, x0
    mv      x6, x0
    mv      x7, x0
    mv      x8, x0
    mv      x9, x0
    mv      x10, x0
    mv      x11, x0
    mv      x12, x0
    mv      x13, x0
    mv      x14, x0
    mv      x15, x0
    mv      x16, x0
    mv      x17, x0
    mv      x18, x0
    mv      x19, x0
    mv      x20, x0
    mv      x21, x0
    mv      x22, x0
    mv      x23, x0
    mv      x24, x0
    mv      x25, x0
    mv      x26, x0
    mv      x27, x0
    mv      x28, x0
    mv      x29, x0
    mv      x30, x0
    mv      x31, x0
    
    /* Stack initilization */
    la      x2, _stack_top

    /* Clear BSS */
    la      x26, _bss_start
    la      x27, _bss_stop

    bge x26, x27, zero_loop_end

zero_loop:
    sw      x0, 0(x26)
    addi    x26, x26, 4
    ble     x26, x27, zero_loop
zero_loop_end:

    /* Jump to main() with argc = argv = 0 */
    mv      x10, x0
    mv      x11, x0
    jal     x1, main
  
    .global halt
halt:
	jal     x0, halt
    
    .global jump
jump:
	jalr    x0, a0, 0
