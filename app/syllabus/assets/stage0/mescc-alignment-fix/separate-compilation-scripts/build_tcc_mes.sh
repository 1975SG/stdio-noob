#!/bin/sh
# Replicates Guix's real bootstrap.sh: separate compilation, not ONE_SOURCE.
# Preserved as evidence/reference -- paths below
# are this scratch session's own job tmp directory and are NOT portable.
# A real syllabus step needs this ported to the project's own build/
# tree layout, not run as-is. What matters is the flag set, the file
# list, and that it's separate mescc invocations, not one ONE_SOURCE run.
set -e

JT2=~/dev/stdio-noob/reduce-work
export PATH="$JT2:$JT2/bin:$PATH"
BINDIR=$JT2/fakeroot/bin
export MES_PREFIX=$JT2/build/mes-0.27.1
export GUILE_LOAD_PATH=$MES_PREFIX/mes/module:$MES_PREFIX/module:$JT2/build/nyacc-1.00.2/module
export MES_STACK=15000000 MES_ARENA=30000000 MES_MAX_ARENA=30000000
PREFIX=$JT2/fakeroot
LIBDIR=$PREFIX/lib/x86_64-mes
MES=$BINDIR/mes-m2
MESCC_SCM=$BINDIR/mescc.scm

cd ~/dev/stdio-noob/realbuild

compile_one () {
  src="$1"
  out="$2"
  echo "  CC  $src -> $out"
  "$MES" --no-auto-compile -e main "$MESCC_SCM" -- \
    -S -o "$out" \
    -I "${PREFIX}/include/mes" \
    -D BOOTSTRAP=1 -D HAVE_LONG_LONG=1 \
    -I . -D TCC_TARGET_X86_64=1 -D inline= \
    -D CONFIG_TCCDIR="\"x\"" \
    -D CONFIG_SYSROOT="\"/\"" \
    -D CONFIG_TCC_CRTPREFIX="\"x\"" \
    -D CONFIG_TCC_ELFINTERP="\"x\"" \
    -D CONFIG_TCC_LIBPATHS="\"x\"" \
    -D CONFIG_TCC_SYSINCLUDEPATHS="\"x\"" \
    -D TCC_LIBGCC="\"x\"" \
    -D TCC_LIBTCC1_MES="\"libtcc1-mes.a\"" \
    -D TCC_MES_LIBC=1 \
    -D CONFIG_TCCBOOT=1 \
    -D CONFIG_TCC_STATIC=1 \
    -D CONFIG_USE_LIBGCC=1 \
    -D TCC_VERSION="\"0.9.26\"" \
    "$src" > "$out.log" 2>&1
  if [ ! -f "$out" ]; then
    echo "FAILED: $src"
    tail -20 "$out.log"
    exit 1
  fi
}

compile_one tccpp.c    tccpp.s
compile_one tccgen.c   tccgen.s
compile_one tccelf.c   tccelf.s
compile_one tccrun.c   tccrun.s
compile_one x86_64-gen.c  x86_64-gen.s
compile_one x86_64-link.c x86_64-link.s
compile_one i386-asm.c    x86_64-asm.s
compile_one tccasm.c   tccasm.s
compile_one libtcc.c   libtcc.s
compile_one tcc.c      tcc.s

echo "  CCLD tcc-mes (separate-compilation build)"
"$MES" --no-auto-compile -e main "$MESCC_SCM" -- \
  -o tcc-mes -L "${LIBDIR}" \
  tccpp.s tccgen.s tccelf.s tccrun.s x86_64-gen.s x86_64-link.s x86_64-asm.s tccasm.s libtcc.s tcc.s \
  -l c+tcc > tcc-mes-link.log 2>&1
if [ ! -f tcc-mes ]; then
  echo "LINK FAILED"
  tail -30 tcc-mes-link.log
  exit 1
fi
chmod 755 tcc-mes
echo "BUILD OK"
