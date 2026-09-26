#!/bin/sh
# tcc-boot0 = tcc-mes compiling tcc.c (ONE_SOURCE), faithful boot.sh flags
cd ~/dev/stdio-noob/mes25-build/boot0
timeout 300 ./tcc-mes -g -v -static -o tcc-boot0 \
  -D BOOTSTRAP=1 -D HAVE_LONG_LONG_STUB=1 -D HAVE_SETJMP=1 \
  -I . -I ~/dev/stdio-noob/mes-0.25.1/lib -I ~/dev/stdio-noob/mes-0.25.1/include -D TCC_TARGET_X86_64=1 -D inline= \
  -D CONFIG_TCCDIR=\"~/dev/stdio-noob/mes25-build/boot0/prefix/lib/tcc\" -D CONFIG_TCC_CRTPREFIX=\"~/dev/stdio-noob/mes25-build/boot0/prefix/lib:{B}/lib:.\" \
  -D CONFIG_TCC_ELFINTERP=\"/lib/mes-loader\" -D CONFIG_TCC_LIBPATHS=\"~/dev/stdio-noob/mes25-build/boot0/prefix/lib:{B}/lib:.\" \
  -D CONFIG_TCC_SYSINCLUDEPATHS=\"~/dev/stdio-noob/mes-0.25.1/include:~/dev/stdio-noob/mes25-build/boot0/prefix/include:{B}/include\" \
  -D TCC_LIBGCC=\"~/dev/stdio-noob/mes25-build/boot0/prefix/lib/libc.a\" -D CONFIG_TCCBOOT=1 -D CONFIG_TCC_STATIC=1 \
  -D CONFIG_USE_LIBGCC=1 -D TCC_MES_LIBC=1 -D TCC_LIBTCC1_MES=\"libtcc1-mes.a\" \
  -D ONE_SOURCE=1 -L . tcc.c
