.section .multiboot_header
.global start_multiboot_header
.align 8

# TODO: crystalize this
start_multiboot_header:
    # Multiboot 2 magic
    .long 0xe85250d6 
    # Architecture
    .long 0
    # Header size
    .long end_multiboot_header - start_multiboot_header
    # Checksum TODO
    .long 0x100000000 - (0xe85250d6 + 0 + (end_multiboot_header - start_multiboot_header))

    # TODO tags

    # End tag
    # type
    .short 0
    # flags
    .short 0
    # size
    .long 8
end_multiboot_header:

.section .data
.global __farcry_early_stack_bottom
.global __farcry_early_stack_top
__farcry_early_stack_bottom:
.rept 16384
.short 0
.endr
__farcry_early_stack_top:
