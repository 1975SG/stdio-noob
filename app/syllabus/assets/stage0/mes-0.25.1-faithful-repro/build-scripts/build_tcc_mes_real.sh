#!/bin/sh
# tcc-mes with REAL library paths (as Guix), from the clean patched tree.
cd ~/dev/stdio-noob/mes25-build/tcc-clean
~/dev/stdio-noob/mes25-build/wrapperbin/mescc -S -o ~/dev/stdio-noob/mes25-build/tccmes/tcc_real.s \
  -D ONE_SOURCE=1 -D BOOTSTRAP=1 -D HAVE_LONG_LONG_STUB=1 -D HAVE_SETJMP=1 \
  -I . -D TCC_TARGET_X86_64=1 -D inline= \
  -D CONFIG_TCCDIR="\"~/dev/stdio-noob/mes25-build/boot0/prefix/lib/tcc\"" \
  -D CONFIG_TCC_CRTPREFIX="\"~/dev/stdio-noob/mes25-build/boot0/prefix/lib:{B}/lib:.\"" \
  -D CONFIG_TCC_ELFINTERP="\"/lib/mes-loader\"" \
  -D CONFIG_TCC_LIBPATHS="\"~/dev/stdio-noob/mes25-build/boot0/prefix/lib:{B}/lib:.\"" \
  -D CONFIG_TCC_SYSINCLUDEPATHS="\"~/dev/stdio-noob/mes-0.25.1/include:~/dev/stdio-noob/mes25-build/boot0/prefix/include:{B}/include\"" \
  -D TCC_LIBGCC="\"~/dev/stdio-noob/mes25-build/boot0/prefix/lib/libc.a\"" \
  -D TCC_LIBTCC1_MES="\"libtcc1-mes.a\"" -D TCC_MES_LIBC=1 -D CONFIG_TCCBOOT=1 \
  -D CONFIG_TCC_STATIC=1 -D CONFIG_USE_LIBGCC=1 tcc.c
echo "exit=$?"
