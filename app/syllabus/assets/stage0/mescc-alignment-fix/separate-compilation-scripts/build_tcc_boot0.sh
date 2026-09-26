#!/bin/sh
# Real, working -boot0 generation (boot.sh's own recipe, adapted), built
# via build_tcc_mes.sh's tcc-mes. Preserved as evidence/reference --
# paths are this scratch session's job tmp dir, not portable. Left off
# at a real, ordinary tcc.h:518 parse error, not yet resolved as of
# this script (see the top-level Bootstrap.md for the full story).
set -e

JT2=~/dev/stdio-noob/reduce-work
PREFIX=$JT2/fakeroot
LIBDIR=$PREFIX/lib/x86_64-mes

cd ~/dev/stdio-noob/realbuild
TCC=./tcc-mes

compile_one () {
  src="$1"
  out="$2"
  echo "  CC  $src -> $out"
  "$TCC" -c -g -o "$out" \
    -I "${PREFIX}/include/mes" \
    -D BOOTSTRAP=1 -D HAVE_LONG_LONG_STUB=1 -D HAVE_SETJMP=1 \
    -I . -D TCC_TARGET_X86_64=1 -D inline= \
    -D CONFIG_TCCDIR="\"${LIBDIR}/tcc\"" \
    -D CONFIG_TCC_CRTPREFIX="\"${LIBDIR}\"" \
    -D CONFIG_TCC_ELFINTERP="\"/mes/loader\"" \
    -D CONFIG_TCC_LIBPATHS="\"${LIBDIR}:${LIBDIR}/tcc\"" \
    -D CONFIG_TCC_SYSINCLUDEPATHS="\"${PREFIX}/include/mes\"" \
    -D TCC_LIBGCC="\"${LIBDIR}/libc.a\"" \
    -D TCC_LIBTCC1_MES="\"libtcc1-mes.a\"" \
    -D TCC_MES_LIBC=1 \
    -D CONFIG_TCCBOOT=1 \
    -D CONFIG_TCC_STATIC=1 \
    -D CONFIG_USE_LIBGCC=1 \
    "$src" > "$out.log" 2>&1
  if [ ! -f "$out" ]; then
    echo "FAILED: $src"
    tail -20 "$out.log"
    exit 1
  fi
}

compile_one tccpp.c    tccpp2.o
compile_one tccgen.c   tccgen2.o
compile_one tccelf.c   tccelf2.o
compile_one tccrun.c   tccrun2.o
compile_one x86_64-gen.c  x86_64-gen2.o
compile_one x86_64-link.c x86_64-link2.o
compile_one i386-asm.c    x86_64-asm2.o
compile_one tccasm.c   tccasm2.o
compile_one libtcc.c   libtcc2.o
compile_one tcc.c      tcc2.o

echo "  CCLD tcc-boot0"
"$TCC" -g -static -o tcc-boot0 \
  -D BOOTSTRAP=1 -D HAVE_LONG_LONG_STUB=1 -D HAVE_SETJMP=1 \
  -D TCC_TARGET_X86_64=1 \
  -D CONFIG_TCCDIR="\"${LIBDIR}/tcc\"" \
  -D CONFIG_TCC_CRTPREFIX="\"${LIBDIR}\"" \
  -D CONFIG_TCC_ELFINTERP="\"/mes/loader\"" \
  -D CONFIG_TCC_LIBPATHS="\"${LIBDIR}:${LIBDIR}/tcc\"" \
  -D CONFIG_TCC_SYSINCLUDEPATHS="\"${PREFIX}/include/mes\"" \
  -D TCC_LIBGCC="\"${LIBDIR}/libc.a\"" \
  -D TCC_LIBTCC1_MES="\"libtcc1-mes.a\"" \
  -D TCC_MES_LIBC=1 \
  -D CONFIG_TCCBOOT=1 \
  -D CONFIG_TCC_STATIC=1 \
  -D CONFIG_USE_LIBGCC=1 \
  -L . \
  tccpp2.o tccgen2.o tccelf2.o tccrun2.o x86_64-gen2.o x86_64-link2.o x86_64-asm2.o tccasm2.o libtcc2.o tcc2.o \
  > tcc-boot0-link.log 2>&1
if [ ! -f tcc-boot0 ]; then
  echo "LINK FAILED"
  tail -30 tcc-boot0-link.log
  exit 1
fi
chmod 755 tcc-boot0
echo "BUILD OK"
