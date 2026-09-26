#!/bin/bash
# gcc wrapper for glibc 2.16's nptl tests: gcc-mesboot1 (gcc 4.6.4, --disable-shared) links every
# test with the static `-lgcc`.  For the -fexceptions family (tst-cancelx*, tst-cleanupx*, tst-oncex*) this puts
# a SECOND, independent copy of the unwinder in the process alongside the one libpthread dlopen's at runtime for
# forced-unwind cancellation (gcc 4.9.4's libgcc_s.so.1, already placed in the build dir) -
# two unwinders, SIGABRT.  This wrapper links against that SAME libgcc_s.so.1 directly instead of statically, at
# link time only, so there is exactly one unwinder implementation in the process.
# usage: PATH-prepend this as `gcc`/`cc` ahead of gcc-mesboot1's own, in glibc 2.16's build env (env3.sh).
JT=~/dev/stdio-noob; B=$JT/g216/gfb/glibc-2.16.0/build
static=0; for a in "$@"; do [ "$a" = -static ] && static=1; done
args=()
for a in "$@"; do
  case "$a" in
    -lgcc) if [ $static = 1 ]; then args+=("$a"); else args+=("$B/libgcc_s.so.1"); fi;;
    *) args+=("$a");;
  esac
done
exec $JT/g216/mbbin3/gcc "${args[@]}"
