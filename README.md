# Notes on relocations

To re-run these test builds, type:

```console
$ curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
$ source ~/.cargo/bin/env
$ rustup toolchain install nightly
$ rustup component add rust-src --toolchain=nightly
$ ./build-all.sh
```

## static

Statically linked.
Table contains full 32-bit addresses of strings.
This is the default

Table <$d.6>: contains address of the print functions for the two types.

## ropi

References to read-only portions (i.e. .text and .rodata) should be position independent.

"relocatable code and read-only data"

## rwpi

References to the read-write portions (i.e. .data and .bss) should be position independent."

"relocatable read-write data"

This fails to link with a debug build, but it's OK in release mode (I guess because the dynamic trait objects are optimised out)?

```text
rust-lld: error:  <path> has non-ABS relocation R_ARM_SBREL32 against symbol 'API'
```

## ropi-rwpi

Both of the above.

Compared to ropi, adding rwpi does some stuff with r9 (which should be set to the start of `.data`)

Compared to rwpi, adding ropi makes the `$d.X` tables of function pointers PC-relative. A table load into `r0` is followed by an `add r0, PC`

This fails to link with a debug build, but it's OK in release mode (I guess because the dynamic trait objects are optimised out)?

```text
rust-lld: error:  <path> has non-ABS relocation R_ARM_SBREL32 against symbol 'API'
```

## dynamic-no-pic

No idea. "Only makes sense on Darwin and is rarely used." [Link](https://doc.rust-lang.org/rustc/codegen-options/index.html)

## pic

Position Independent Code. Allows for LD_PRELOAD to replace symbols. Used for shared libraries.

On thumbv6m comes out the same as pie.

pic has a GOT. ropi-rwpi does not.

GOT is at 20001b24. It contains: 1c 1b 00 20, which is 0x20001b1c. That's the address of the API global variable. Loading the API variable in the print function involves a double-indirection.

However, the V-tables for the trait objects are in .data, with absolute addresses:

```text
L__unnamed_1:
0x20001a1c: 200010d1 // <core::ptr::drop_in_place$LT$rtest..Square$GT$::hb52cb0c23578a53b>:
0x20001a20: 00000004
0x20001a24: 00000004
0x20001a28: 20001135 // <_$LT$rtest..Square$u20$as$u20$rtest..Printable$GT$::print::h58d946f7495f44df>:
0x20001a2c: 200011c1 // <_$LT$rtest..Square$u20$as$u20$rtest..Printable$GT$::sides::h818113962c3ebd1e>:

L__unnamed_2:
0x20001a30: 200010c9 // <core::ptr::drop_in_place$LT$rtest..Circle$GT$::hf35e0a44e9a6f1ec>:
0x20001a34: 00000004
0x20001a38: 00000004
0x20001a3c: 200011cd // <_$LT$rtest..Circle$u20$as$u20$rtest..Printable$GT$::print::hdf2bc70fa60a549e>:
0x20001a40: 20001259 // <_$LT$rtest..Circle$u20$as$u20$rtest..Printable$GT$::sides::heb588e34044954f2>:
```

If you look in the `.rel.data` section, it will tell us about these absolute addresses:

```console
$ readelf -Cr ./target/thumbv6m-neotron-neotron-pic/debug/rtest
...
Relocation section '.rel.data' at offset 0x1da8 contains 27 entries:
 Offset     Info    Type            Sym.Value  Sym. Name
200019ac  00000c02 R_ARM_ABS32       20001650   .rodata
200019b4  00000c02 R_ARM_ABS32       20001650   .rodata
200019c4  00000c02 R_ARM_ABS32       20001650   .rodata
200019cc  00000c02 R_ARM_ABS32       20001650   .rodata
200019dc  00000c02 R_ARM_ABS32       20001650   .rodata
200019ec  00000c02 R_ARM_ABS32       20001650   .rodata
200019fc  00000c02 R_ARM_ABS32       20001650   .rodata
20001a0c  00000c02 R_ARM_ABS32       20001650   .rodata
20001a1c  00001c02 R_ARM_ABS32       200010d1   core::ptr::drop_i[...]
20001a28  00002802 R_ARM_ABS32       20001135   <rtest::Square as[...]
20001a2c  00003002 R_ARM_ABS32       200011c1   <rtest::Square as[...]
20001a30  00001b02 R_ARM_ABS32       200010c9   core::ptr::drop_i[...]
20001a3c  00003202 R_ARM_ABS32       200011cd   <rtest::Circle as[...]
20001a40  00003802 R_ARM_ABS32       20001259   <rtest::Circle as[...]
20001a84  00000c02 R_ARM_ABS32       20001650   .rodata
20001a94  00000c02 R_ARM_ABS32       20001650   .rodata
20001a9c  00000c02 R_ARM_ABS32       20001650   .rodata
20001aac  00000c02 R_ARM_ABS32       20001650   .rodata
20001ab4  00000c02 R_ARM_ABS32       20001650   .rodata
20001abc  00000c02 R_ARM_ABS32       20001650   .rodata
20001acc  00000c02 R_ARM_ABS32       20001650   .rodata
20001ad4  00000c02 R_ARM_ABS32       20001650   .rodata
20001ae4  00007702 R_ARM_ABS32       2000161f   core::ptr::drop_i[...]
20001af0  00009b02 R_ARM_ABS32       20001515   <T as core::any::[...]
20001af4  00000c02 R_ARM_ABS32       20001650   .rodata
20001b04  00000c02 R_ARM_ABS32       20001650   .rodata
20001b0c  00000c02 R_ARM_ABS32       20001650   .rodata
```

https://refspecs.linuxbase.org/elf/gabi4+/ch4.reloc.html says that this table is:

```c
typedef struct {
	Elf32_Addr	r_offset;
	Elf32_Word	r_info;
} Elf32_Rel;

#define ELF32_R_SYM(i)	((i)>>8)
#define ELF32_R_TYPE(i)   ((unsigned char)(i))
#define ELF32_R_INFO(s,t) (((s)<<8)+(unsigned char)(t))
```

Based on that:

```
 Offset     Info    Type            Sym.Value  Sym. Name
200019ac  00000c 02 R_ARM_ABS32       20001650   .rodata
200019b4  00000c 02 R_ARM_ABS32       20001650   .rodata
200019c4  00000c 02 R_ARM_ABS32       20001650   .rodata
200019cc  00000c 02 R_ARM_ABS32       20001650   .rodata
200019dc  00000c 02 R_ARM_ABS32       20001650   .rodata
200019ec  00000c 02 R_ARM_ABS32       20001650   .rodata
200019fc  00000c 02 R_ARM_ABS32       20001650   .rodata
20001a0c  00000c 02 R_ARM_ABS32       20001650   .rodata
20001a1c  00001c 02 R_ARM_ABS32       200010d1   core::ptr::drop_i[...]
20001a28  000028 02 R_ARM_ABS32       20001135   <rtest::Square as[...]
20001a2c  000030 02 R_ARM_ABS32       200011c1   <rtest::Square as[...]
20001a30  00001b 02 R_ARM_ABS32       200010c9   core::ptr::drop_i[...]
20001a3c  000032 02 R_ARM_ABS32       200011cd   <rtest::Circle as[...]
20001a40  000038 02 R_ARM_ABS32       20001259   <rtest::Circle as[...]
20001a84  00000c 02 R_ARM_ABS32       20001650   .rodata
20001a94  00000c 02 R_ARM_ABS32       20001650   .rodata
20001a9c  00000c 02 R_ARM_ABS32       20001650   .rodata
20001aac  00000c 02 R_ARM_ABS32       20001650   .rodata
20001ab4  00000c 02 R_ARM_ABS32       20001650   .rodata
20001abc  00000c 02 R_ARM_ABS32       20001650   .rodata
20001acc  00000c 02 R_ARM_ABS32       20001650   .rodata
20001ad4  00000c 02 R_ARM_ABS32       20001650   .rodata
20001ae4  000077 02 R_ARM_ABS32       2000161f   core::ptr::drop_i[...]
20001af0  00009b 02 R_ARM_ABS32       20001515   <T as core::any::[...]
20001af4  00000c 02 R_ARM_ABS32       20001650   .rodata
20001b04  00000c 02 R_ARM_ABS32       20001650   .rodata
20001b0c  00000c 02 R_ARM_ABS32       20001650   .rodata
```

These are all R_TYPE=0x02, which is [R_ARM_ABS32](https://elixir.bootlin.com/linux/latest/source/arch/arm/include/asm/elf.h#L53).

The 24-bit R_SYM value seems to be an entry into the symbol table. If we pick, say, `20001ae4`, that is symbol 0x000077, which is decimal 119. The symbol table shows us:

```text
   119: 2000161f     8 FUNC    LOCAL  HIDDEN     2 core::ptr::drop_[...]
```

## pie

Position Independent Executable. Does not allow for LD_PRELOAD to replace symbols. Used for executables. Cannot be linked into a shared library.

On thumbv6m comes out the same as pic.

Table <$d.6>: contains negative numbers? Oh, those are also PC-relative.


