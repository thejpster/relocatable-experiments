#!/bin/sh

# Build with all known ~~frequencies~~ relocations
for i in `cat relocations.txt`; do
    echo "****** $i ********"
    cargo build --target=thumbv6m-neotron-neotron-$i.json
done   

# Generate some dissassembly to look at
for i in ./target/*/debug/rtest; do
    llvm-objdump -C -t -T -r -d -S -s $i > $i.asm
    readelf -C -all $i > $i.txt
done
