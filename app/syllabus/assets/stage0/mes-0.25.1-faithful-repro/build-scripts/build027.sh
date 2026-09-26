#!/bin/sh
# tcc-0.9.27 built by tcc-boot9 (Guix's tcc-boot build phase, i386 -> x86_64)
cd $(dirname $0)/build
O=$(pwd)/../out027; mkdir -p $O
timeout 300 ../tcc-boot9 -g -v -static -o tcc \
  -D BOOTSTRAP=1 -D ONE_SOURCE=1 -D TCC_TARGET_X86_64=1 -D HAVE_FLOAT=1 -D HAVE_LONG_LONG=1 -D HAVE_SETJMP=1 \
  -D CONFIG_TCCBOOT=1 -D CONFIG_TCC_STATIC=1 -D CONFIG_USE_LIBGCC=1 -D inline= \
  -I . -I ~/dev/stdio-noob/mes-0.25.1/lib -I ~/dev/stdio-noob/mes-0.25.1/include \
  -D CONFIG_TCCDIR=\"$O/lib/tcc\" -D CONFIG_TCC_CRTPREFIX=\"$O/lib:{B}/lib:.\" \
  -D CONFIG_TCC_ELFINTERP=\"/mes/loader\" -D CONFIG_TCC_LIBPATHS=\"~/dev/stdio-noob/mes25-build/boot0/prefix/lib:{B}/lib:.\" \
  -D CONFIG_TCC_SYSINCLUDEPATHS=\"~/dev/stdio-noob/mes-0.25.1/include:/include:{B}/include\" \
  -D TCC_LIBGCC=\"~/dev/stdio-noob/mes25-build/boot0/prefix/lib/libc.a\" -L ~/dev/stdio-noob/mes25-build/boot0 tcc.c
