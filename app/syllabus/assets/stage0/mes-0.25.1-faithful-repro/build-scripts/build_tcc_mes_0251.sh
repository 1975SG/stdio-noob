#!/bin/sh
# Scratch-session recipe (paths are this session's job dir, NOT portable) that
# produced a working tcc-mes under Mes 0.25.1 + tcc-0.9.26-1149. Flag set and
# link method are what matter: mescc -S -> blood-elf -> M1 -> raw hex2 WITH
# elf64-header.hex2 first and elf64-footer-single-main.hex2 last, individual
# libc .o files (never the .a), --base-address 0x08048000.
JT=~/dev/stdio-noob
M=$JT/mes-0.25.1/lib; L=$JT/mes25-build/libcbuild; T=$JT/reduce-work
cd $JT/real-repro/tcc-src
$JT/mes25-build/wrapperbin/mescc -S -o tcc.s -D ONE_SOURCE=1 -D BOOTSTRAP=1 \
  -D HAVE_LONG_LONG_STUB=1 -D HAVE_SETJMP=1 -I . -D TCC_TARGET_X86_64=1 -D inline= \
  -D CONFIG_TCCDIR='"x"' -D CONFIG_SYSROOT='"/"' -D CONFIG_TCC_CRTPREFIX='"x"' \
  -D CONFIG_TCC_ELFINTERP='"x"' -D CONFIG_TCC_LIBPATHS='"x"' \
  -D CONFIG_TCC_SYSINCLUDEPATHS='"x"' -D TCC_LIBGCC='"x"' \
  -D TCC_LIBTCC1_MES='"libtcc1-mes.a"' -D TCC_MES_LIBC=1 -D CONFIG_TCCBOOT=1 \
  -D CONFIG_TCC_STATIC=1 -D CONFIG_USE_LIBGCC=1 -D TCC_VERSION='"0.9.26"' tcc.c
$T/blood-elf --little-endian -f tcc.s -o tcc-footer.s
$T/M1 --little-endian --architecture amd64 -f $M/x86_64-mes/x86_64.M1 -f tcc.s -f tcc-footer.s -o tcc.o
FARGS="-f $M/linux/x86_64-mes/elf64-header.hex2 -f $L/crt1.o -f tcc.o -f $L/abort.o"
for f in $(ls $L/*.o | grep -v -e /crt1.o -e /abort.o | LC_ALL=C sort); do FARGS="$FARGS -f $f"; done
$T/hex2 --little-endian --architecture amd64 --base-address 0x08048000 $FARGS \
  -f $M/linux/x86_64-mes/elf64-footer-single-main.hex2 -o tcc-mes
