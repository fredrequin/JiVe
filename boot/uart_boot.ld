OUTPUT_FORMAT("elf32-littleriscv")
ENTRY(_start)

__DYNAMIC = 0;

MEMORY
{
    brom (rx)   : ORIGIN = 0x00000000, LENGTH = 0x00400          /*  1 kB */
    regs (rw)   : ORIGIN = 0x00010000, LENGTH = 0x10000          /* 64 kB */
    bram (rwx)  : ORIGIN = 0x80000000, LENGTH = 0x10000          /* 64 kB */
}

SECTIONS
{
    .boot : 
    {
        _boot_start = .;
        *(.boot)
        _boot_stop = .;
    } > brom
  
    .text : 
    {
        _text_start = .;
        *(.text .stub .text.* .gnu.linkonce.t.*)
        _text_stop = .;
    } > brom

    .rodata :
    {
        . = ALIGN(4);
        _rodata_start = .;
        *(.rodata .rodata.* .gnu.linkonce.r.*)
        *(.rodata1)
        _rodata_stop = .;
    } > brom

    .data : 
    {
        . = ALIGN(4);
        _data_start = .;
        _gp_loc = . + 0x8000;
        *(.data .data.* .gnu.linkonce.d.*)
        *(.data1)
        *(.sdata .sdata.* .gnu.linkonce.s.*)
        _data_stop = .;
    } > bram

    .bss :
    {
        . = ALIGN(4);
        _bss_start = .;
        *(.dynsbss)
        *(.sbss .sbss.* .gnu.linkonce.sb.*)
        *(.scommon)
        *(.dynbss)
        *(.bss .bss.* .gnu.linkonce.b.*)
        *(COMMON)
        . = ALIGN(4);
        _bss_stop = .;
        _end = .;
    } > bram
}

PROVIDE(_stack_top = ORIGIN(bram) + LENGTH(bram) - 4);
