ENTRY(__farcry_entrypoint)
OUTPUT_FORMAT(elf32-i386)

PHDRS
{
  boot PT_LOAD ;
  text PT_LOAD ;
  rodata PT_LOAD ;
  data PT_LOAD ;
}

SECTIONS {
    . = 0;
    KERNEL_START = .;

    .boot ALIGN(4K) : {
        KEEP(*(.multiboot_header))
    } : boot

    . = 1M;

    .text ALIGN(4K) : {
        *(.text .text.*)
    } : text

    .rodata ALIGN(4K) : {
        *(.rodata .rodata.*)
    } : rodata

    .data ALIGN(4K) : {
        *(.data .data.*)
    } : data

    .got ALIGN(4K) : {
        *(.got)
    } : data

    .bss ALIGN(4K) : {
        BSS_START = .;
        *(.bss)
        BSS_END = .;
    } : data

    .data.rel.ro ALIGN(4K) : {
        *(.data.rel.ro.local.*) *(data.rel.ro .data.rel.ro.*)
        . = ALIGN(4K);
    } : data

    . = ALIGN(4K);
    KERNEL_END = .;

    /* Stabs debugging sections.  */
    .stab          0 : { *(.stab) }
    .stabstr       0 : { *(.stabstr) }
    .stab.excl     0 : { *(.stab.excl) }
    .stab.exclstr  0 : { *(.stab.exclstr) }
    .stab.index    0 : { *(.stab.index) }
    .stab.indexstr 0 : { *(.stab.indexstr) }
    .comment       0 : { *(.comment) }
    /* DWARF debug sections.
        Symbols in the DWARF debugging sections are relative to the beginning
        of the section so we begin them at 0.  */
    /* DWARF 1 */
    .debug          0 : { *(.debug) }
    .line           0 : { *(.line) }
    /* GNU DWARF 1 extensions */
    .debug_srcinfo  0 : { *(.debug_srcinfo) }
    .debug_sfnames  0 : { *(.debug_sfnames) }
    /* DWARF 1.1 and DWARF 2 */
    .debug_aranges  0 : { *(.debug_aranges) }
    .debug_pubnames 0 : { *(.debug_pubnames) }
    /* DWARF 2 */
    .debug_info     0 : { *(.debug_info .gnu.linkonce.wi.*) }
    .debug_abbrev   0 : { *(.debug_abbrev) }
    .debug_line     0 : { *(.debug_line .debug_line.* .debug_line_end ) }
    .debug_frame    0 : { *(.debug_frame) }
    .debug_str      0 : { *(.debug_str) }
    .debug_loc      0 : { *(.debug_loc) }
    .debug_macinfo  0 : { *(.debug_macinfo) }
    /* SGI/MIPS DWARF 2 extensions */
    .debug_weaknames 0 : { *(.debug_weaknames) }
    .debug_funcnames 0 : { *(.debug_funcnames) }
    .debug_typenames 0 : { *(.debug_typenames) }
    .debug_varnames  0 : { *(.debug_varnames) }
    /* DWARF 3 */
    .debug_pubtypes 0 : { *(.debug_pubtypes) }
    .debug_ranges   0 : { *(.debug_ranges) }
    /* DWARF Extension.  */
    .debug_macro    0 : { *(.debug_macro) }
    .debug_addr     0 : { *(.debug_addr) }
    .gnu.attributes 0 : { KEEP (*(.gnu.attributes)) }

    /DISCARD/ : {
        *(.comment*)
        *(.eh_frame*)
        *(.gcc_except_table*)
        *(.note*)
        *(.rel.eh_frame*)
    }
}