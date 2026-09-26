#!/bin/sh
# patch 2.5.9 built by tcc (Guix's patch-mesboot recipe, i686 -> x86_64).
# usage: build_patch.sh <tcc wrapper> <unpacked patch-2.5.9 dir> <make>
# Guix's `pch.c` workaround ("avoid another segfault") was NOT needed here:
# patch built by tcc-boot0 and tcc-0.9.27 both pass with the unpatched file.
CC=$1; cd $2 || exit 1; MAKE=${3:-make}
PATH=$(dirname $MAKE):$PATH CC=$CC AR="$CC -ar" LD=$CC sh ./configure \
  --build=x86_64-unknown-linux-gnu --host=x86_64-unknown-linux-gnu
$MAKE CC=$CC AR="$CC -ar"
