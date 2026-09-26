#!/bin/bash
# Rebuild the whole bootstrap compiler chain against the CORRECTED Mes libc.
# usage: run_chain.sh   (expects $C2/tccmes/tcc-mes from stage 0)
set -u
JT=~/dev/stdio-noob; C2=$JT/mes25-build/chain2; MP=$JT/mes-0.25.1; CL=$JT/mes25-build/tcc-clean; P=$C2/prefix
B=$C2/boot; LOG=$C2/chain.log; : > $LOG
say() { echo "$*" | tee -a $LOG; }
rm -rf $B; mkdir -p $B $P/lib/tcc; cp -r $CL/. $B/; cd $B
cp $C2/tccmes/tcc-mes ./tcc-mes
INC="-I $MP/include -I $MP/lib"
( cd $MP; cat $(cat $JT/mes25-build/boot0/libc_gnu_files.txt) ) > libc.c
cp $MP/lib/libtcc1.c libtcc1.c; cp $CL/lib/va_list.c va_list.c; cp $CL/lib/libtcc1.c tcclibtcc1.c
for i in 1 i n; do cp $MP/lib/linux/x86_64-mes-gcc/crt$i.c .; done
libs() {   # libs <compiler> <extra flags for libc/libtcc1> ; rebuilds crt*, libc.a, libtcc1.a with that compiler
  local cc=$1; shift; local fl="$*"
  for i in 1 i n; do ./$cc $INC -D BOOTSTRAP=1 -static -nostdlib -nostdinc -c crt$i.c || return 1; done
  ./$cc -c $INC -D BOOTSTRAP=1 $fl libc.c -o libc.o 2>>$LOG || return 1; rm -f libc.a; ./$cc -ar cr libc.a libc.o || return 1
  # Mes's libtcc1.c defines WEAK placeholder float conversions (__fixxfdi, __fixunsxfdi, __floatundixf, ...) under
  # HAVE_FLOAT/HAVE_FLOAT_STUB.  Built with them they shadow TinyCC's real ones from tcclibtcc1.o on x86_64 and every
  # later stage folds (int)(float constant) to 0.  Build it WITHOUT the float flags.
  ./$cc -c $INC -D BOOTSTRAP=1 libtcc1.c -o libtcc1.o || return 1
  ./$cc -c $INC -D BOOTSTRAP=1 -D TCC_TARGET_X86_64=1 va_list.c -o va_list.o || return 1
  local extra=""; if [ "${WITH_TCCLIB:-0}" = 1 ]; then ./$cc -c -g $INC -I $CL/include -D TCC_TARGET_X86_64=1 -D HAVE_FLOAT=1 -D HAVE_LONG_LONG=1 -o tcclibtcc1.o tcclibtcc1.c || return 1; extra=tcclibtcc1.o; fi
  rm -f libtcc1.a; ./$cc -ar cr libtcc1.a libtcc1.o va_list.o $extra || return 1
  cp libc.a $P/lib/; cp libtcc1.a $P/lib/tcc/
}
stage() {  # stage <compiler> <n> <flags...>
  local prev=$1 n=$2; shift 2
  timeout 400 ./$prev -g -static -o tcc-boot$n -D BOOTSTRAP=1 "$@" -D HAVE_SETJMP=1 \
   -I . $INC -D TCC_TARGET_X86_64=1 -D inline= \
   -D CONFIG_TCCDIR=\"$P/lib/tcc\" -D CONFIG_TCC_CRTPREFIX=\"$P/lib:{B}/lib:.\" \
   -D CONFIG_TCC_ELFINTERP=\"/lib/mes-loader\" -D CONFIG_TCC_LIBPATHS=\"$P/lib:{B}/lib:.\" \
   -D CONFIG_TCC_SYSINCLUDEPATHS=\"$MP/include:$P/include:{B}/include\" \
   -D TCC_LIBGCC=\"$P/lib/libc.a\" -D CONFIG_TCCBOOT=1 -D CONFIG_TCC_STATIC=1 -D CONFIG_USE_LIBGCC=1 \
   -D TCC_MES_LIBC=1 -D TCC_LIBTCC1_MES=\"libtcc1-mes.a\" -D ONE_SOURCE=1 -L . tcc.c > boot$n.log 2>&1
  local rc=$?; say "boot$n: build rc=$rc size=$(stat -c %s tcc-boot$n 2>/dev/null) sha=$(sha256sum tcc-boot$n 2>/dev/null | cut -c1-16) version=$(timeout 10 ./tcc-boot$n -version 2>&1 | head -1)"
  return $rc
}
say "== stage 0 -> libc/libtcc1 by tcc-mes =="; libs tcc-mes || { say "libs by tcc-mes FAILED"; exit 1; }
say "== boot0..boot2 (no float) =="
stage tcc-mes 0 -D HAVE_LONG_LONG_STUB=1 || exit 1
stage tcc-boot0 1 -D HAVE_BITFIELD=1 -D HAVE_LONG_LONG=1 || exit 1
stage tcc-boot1 2 -D HAVE_BITFIELD=1 -D HAVE_FLOAT_STUB=1 -D HAVE_LONG_LONG=1 || exit 1
say "== libtcc1 gains TinyCC's long double helpers; boot3..boot6 (float) =="
WITH_TCCLIB=1 libs tcc-boot2 -D HAVE_FLOAT=1 -D HAVE_LONG_LONG=1 || { say "libs by boot2 FAILED"; exit 1; }
for n in 3 4 5 6; do prev=$((n-1)); stage tcc-boot$prev $n -D HAVE_BITFIELD=1 -D HAVE_FLOAT=1 -D HAVE_LONG_LONG=1 || exit 1; done
cmp -s tcc-boot5 tcc-boot6 && say "FIXED POINT: tcc-boot5 == tcc-boot6" || say "boot5 != boot6"
say "== libc/libtcc1 rebuilt by float-capable boot6; boot7..boot9 =="
WITH_TCCLIB=1 libs tcc-boot6 -D HAVE_FLOAT=1 -D HAVE_LONG_LONG=1 || { say "libs by boot6 FAILED"; exit 1; }
for n in 7 8 9; do prev=$((n-1)); stage tcc-boot$prev $n -D HAVE_BITFIELD=1 -D HAVE_FLOAT=1 -D HAVE_LONG_LONG=1 || exit 1; done
cmp -s tcc-boot8 tcc-boot9 && say "FIXED POINT: tcc-boot8 == tcc-boot9" || say "boot8 != boot9"
say "CHAIN_DONE"
