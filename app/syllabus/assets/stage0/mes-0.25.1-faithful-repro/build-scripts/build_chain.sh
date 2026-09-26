#!/bin/sh
# stages boot2..boot6, flags exactly as boot.sh selects them (x86_64)
B=$(cd "$(dirname "$0")" && pwd); MP=~/dev/stdio-noob/mes-0.25.1; P=$B/prefix
cd $B
stage() { prev=$1; n=$2; shift 2
  timeout 300 ./$prev -g -static -o tcc-boot$n -D BOOTSTRAP=1 "$@" -D HAVE_SETJMP=1 \
   -I . -I $MP/lib -I $MP/include -D TCC_TARGET_X86_64=1 -D inline= \
   -D CONFIG_TCCDIR=\"$P/lib/tcc\" -D CONFIG_TCC_CRTPREFIX=\"$P/lib:{B}/lib:.\" \
   -D CONFIG_TCC_ELFINTERP=\"/lib/mes-loader\" -D CONFIG_TCC_LIBPATHS=\"$P/lib:{B}/lib:.\" \
   -D CONFIG_TCC_SYSINCLUDEPATHS=\"$MP/include:$P/include:{B}/include\" \
   -D TCC_LIBGCC=\"$P/lib/libc.a\" -D CONFIG_TCCBOOT=1 -D CONFIG_TCC_STATIC=1 \
   -D CONFIG_USE_LIBGCC=1 -D TCC_MES_LIBC=1 -D TCC_LIBTCC1_MES=\"libtcc1-mes.a\" \
   -D ONE_SOURCE=1 -L . tcc.c > boot$n.log 2>&1
  echo "boot$n build exit=$? size=$(stat -c %s tcc-boot$n 2>/dev/null)"; }
# boot2 already built
stage tcc-boot2 3 -D HAVE_BITFIELD=1 -D HAVE_FLOAT=1 -D HAVE_LONG_LONG=1
stage tcc-boot3 4 -D HAVE_BITFIELD=1 -D HAVE_FLOAT=1 -D HAVE_LONG_LONG=1
stage tcc-boot4 5 -D HAVE_BITFIELD=1 -D HAVE_FLOAT=1 -D HAVE_LONG_LONG=1
stage tcc-boot5 6 -D HAVE_BITFIELD=1 -D HAVE_FLOAT=1 -D HAVE_LONG_LONG=1
