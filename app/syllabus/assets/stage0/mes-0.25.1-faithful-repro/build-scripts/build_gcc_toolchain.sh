#!/bin/bash
# build_gcc_toolchain.sh: Guix's `gcc-toolchain` = make-gcc-toolchain gcc-final glibc-final.
# A trivial-build-system package: union-build (guix/build/union.scm, reimplemented in union_build.py --
# a faithful port, not a lookalike, verified against a synthetic collision case first) of gcc-final,
# ld-wrapper, binutils-final, glibc-final into one prefix, in that order (so ld-wrapper's ld wins the
# collision with binutils' own ld -- the package's own documented "raison d'etre"), plus a cc -> gcc
# symlink (gcc already provides c++, oddly enough per Guix's own comment).
JT=~/dev/stdio-noob; G12=$JT/g12; G13=$JT/g13
HERE=$(cd "$(dirname "$0")" && pwd)
OUT=$G12/out/gcc-toolchain
rm -rf $OUT
python3 $HERE/union_build.py $OUT $G12/out/gcc-final $G13/out/ld-wrapper $G12/out/binutils-final $G12/glibc-final || exit 1
ln -s gcc $OUT/bin/cc
echo "gcc-toolchain: $(find $OUT | wc -l) entries in $OUT"
