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
    /* 124K starting at 4K */
    SRAM (rwx) : ORIGIN = 0x20001000, LENGTH = 0x0001F000
}

EXTERN(ENTRY_POINT);

SECTIONS
{
    .entry ORIGIN(SRAM) :
    {
        KEEP(*(.entry_point))
    } > SRAM

    .text :
    {
        *    (.text .text.*)
        *    (.init)
        *    (.fini)
    } > SRAM

    .rodata : ALIGN(4)
    {
        *(.rodata .rodata.*);
        /* 4-byte align the end (VMA) of this section.
           This is required by LLD to ensure the LMA of the following .data
           section will have the correct alignment. */
        . = ALIGN(4);
    } > SRAM

    .data : ALIGN(4)
    {
        *    (.data .data.*)
        . = ALIGN(4);
    }  > SRAM

    .bss (NOLOAD) : ALIGN(4)
    {
        *    (.bss .bss.*)
        . = ALIGN(4);
    } > SRAM

    .got : ALIGN(4)
    {
        KEEP(*(.got .got.*));
    }

    /* ## Discarded sections */
    /DISCARD/ :
    {
        /* Unused exception related info that only wastes space */
        *(.ARM.exidx.*);
    }
}
