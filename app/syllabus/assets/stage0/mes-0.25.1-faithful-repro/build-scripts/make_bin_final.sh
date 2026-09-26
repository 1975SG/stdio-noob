#!/bin/bash
# bin-final: binutils-final's tools under both their plain names and their i686-guix-linux-gnu- prefixed
# aliases, in one directory. Mechanically derived (not hand-picked): every file in binutils-final/bin,
# twice. build_gcc_final.sh/build_guile_final.sh/build_bash_final.sh/build_final_tools.sh put it first on
# PATH so the stage compilers see binutils-final (not the cross-boot0 binutils) under either name.
# usage: make_bin_final.sh <G12 prefix, e.g. $JT/g12>
G12=$1
BU=$G12/out/binutils-final/bin; OUT=$G12/bin-final
[ -d "$BU" ] || { echo "no $BU: build binutils-final first"; exit 1; }
rm -rf $OUT; mkdir -p $OUT
for f in $BU/*; do n=$(basename $f); ln -s $f $OUT/$n; ln -s $f $OUT/i686-guix-linux-gnu-$n; done
echo "bin-final: $(ls $OUT | wc -l) entries"
