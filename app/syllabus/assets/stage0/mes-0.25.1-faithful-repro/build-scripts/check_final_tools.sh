#!/bin/bash
# usage: check14.sh <pkg>...   run each final tool's own test suite as Guix would (`make check`), as a normal user, in the final environment.
JT=~/dev/stdio-noob; G8=$JT/g8; G9=$JT/g9; G10=$JT/g10; G12=$JT/g12; G13=$JT/g13; G14=$JT/g14
BF=$G12/out/bash-final; O=$G14/out; WR=$G13/out/ld-wrapper/bin
export PATH=$O/sed/bin:$O/coreutils/bin:$O/grep/bin:$O/xz/bin:$G13/out/pkg-config/bin:$G12/out/gcc-final/bin:$G12/bin-final:$G10/out/python/bin:$G9/out/m4/bin:$G9/out/perl/bin:$G9/out/bison/bin:$G8/only LC_ALL=C
export CONFIG_SHELL=$BF/bin/bash SHELL=$BF/bin/bash NIX_STORE=$JT GUIX_LOCPATH=$G13/out/glibc-utf8-locales/lib/locale
export C_INCLUDE_PATH=$G9/out/linux-headers/include CPLUS_INCLUDE_PATH=$G9/out/linux-headers/include
export PKG_CONFIG_PATH=$G13/out/guile/lib/pkgconfig:$G13/out/libffi/lib/pkgconfig:$G13/out/libunistring/lib/pkgconfig:$G13/out/libgc/lib/pkgconfig LIBRARY_PATH=$G13/out/libffi/lib:$G13/out/libunistring/lib:$G13/out/libgc/lib:$G13/out/guile/lib
export PATH=$G14/lessstub:$PATH
CC="gcc -B$WR"; export CC
for p in "$@"; do
  d=$(ls -d $G14/src/$p/*/ | head -1); cd $d
  case $p in
    bzip2) cmd="make test";;
    zstd)  cmd="make check CC='$CC' HAVE_LZMA=0 HAVE_LZ4=0 HAVE_ZLIB=0";;
    tar)   cmd="make check TESTSUITEFLAGS='-j8 -k !tricky\ time\ stamps'";;
    coreutils) cmd="make -j8 check";;
    *)     cmd="make -j8 check";;
  esac
  s=$(date +%s); timeout 3000 bash -c "$cmd" > $G14/$p.check.log 2>&1; rc=$?; echo "$p check rc=$rc ($(( $(date +%s)-s ))s)"
done
