/**
 * Neotron Application linker script.
 *
 * Copyright (c) Jonathan 'theJPster' Pallant 2019-2023
 * Copyright (c) Rust Embedded Working Group 2018
 *
 * Available under the MIT or Apache 2.0 licence, at your option.
 */

MEMORY
{
    CODE (rx) : ORIGIN = 0x30000000, LENGTH = 128K
    DATA (rw)  : ORIGIN = 0x40000000, LENGTH = 128K
}

EXTERN(ENTRY_POINT);
ENTRY(entry_point);

SECTIONS
{
    .entry ORIGIN(CODE) :
    {
        KEEP(*(.entry_point))
    } > CODE

    .text :
    {
        *    (.text .text.*)
        *    (.init)
        *    (.fini)
    } > CODE

    .rodata : ALIGN(4)
    {
        *(.rodata .rodata.*);
        /* 4-byte align the end (VMA) of this section.
           This is required by LLD to ensure the LMA of the following .data
           section will have the correct alignment. */
        . = ALIGN(4);
    } > CODE

    .data : ALIGN(4)
    {
        *    (.data .data.*)
        . = ALIGN(4);
    } > DATA

    .bss (NOLOAD) : ALIGN(4)
    {
        *    (.bss .bss.*)
        . = ALIGN(4);
    } > DATA

    .got : ALIGN(4)
    {
        KEEP(*(.got .got.*));
    } > DATA

    /* ## Discarded sections */
    /DISCARD/ :
    {
        /* Unused exception related info that only wastes space */
        *(.ARM.exidx.*);
    }
}
