#!/bin/bash
# tcc-0.9.27 from the rebuilt tcc-boot9, then its own libc/libtcc1 and a self-hosting fixed-point check.
set -u
JT=~/dev/stdio-noob; C2=$JT/mes25-build/chain2; MP=$JT/mes-0.25.1; P=$C2/prefix; O=$C2/out027; LOG=$C2/027.log; : > $LOG
say() { echo "$*" | tee -a $LOG; }
rm -rf $C2/t027 $O; mkdir -p $C2/t027 $O/lib/tcc $O/bin; cp -r $JT/t027/build/. $C2/t027/; cd $C2/t027; rm -f tcc tcc27* tcc-test *.o h3_* plt plt_d 2>/dev/null
INC="-I $MP/include -I $MP/lib"
cc027() { local cc=$1 out=$2
  timeout 300 $cc -g -static -o $out -D __SIZEOF_LONG_LONG__=8 -D BOOTSTRAP=1 -D ONE_SOURCE=1 -D TCC_TARGET_X86_64=1 -D HAVE_FLOAT=1 -D HAVE_LONG_LONG=1 -D HAVE_SETJMP=1 \
    -D CONFIG_TCCBOOT=1 -D CONFIG_TCC_STATIC=1 -D CONFIG_USE_LIBGCC=1 -D inline= -I . $INC \
    -D CONFIG_TCCDIR=\"$O/lib/tcc\" -D CONFIG_TCC_CRTPREFIX=\"$O/lib:{B}/lib:.\" -D CONFIG_TCC_ELFINTERP=\"/mes/loader\" \
    -D CONFIG_TCC_LIBPATHS=\"$P/lib:{B}/lib:.\" -D CONFIG_TCC_SYSINCLUDEPATHS=\"$MP/include:/include:{B}/include\" \
    -D TCC_LIBGCC=\"$P/lib/libc.a\" -L $C2/boot tcc.c > $out.log 2>&1
  say "$out: rc=$? size=$(stat -c %s $out 2>/dev/null) sha=$(sha256sum $out 2>/dev/null | cut -c1-16) $(timeout 10 ./$out -version 2>&1 | head -1)"; }
cp $C2/boot/crt1.o $C2/boot/crti.o $C2/boot/crtn.o $O/lib/; cp $C2/boot/crt1.o $C2/boot/crti.o $C2/boot/crtn.o $P/lib/; cp $P/lib/libc.a $O/lib/; cp $P/lib/tcc/libtcc1.a $O/lib/libtcc1.a; cp $P/lib/tcc/libtcc1.a $O/lib/tcc/
say "== tcc-0.9.27 by tcc-boot9 =="; cc027 $C2/boot/tcc-boot9 tcc27a || exit 1
say "== libc/libtcc1 rebuilt by tcc-0.9.27 =="
FL="-D BOOTSTRAP=1 -D HAVE_FLOAT=1 -D HAVE_LONG_LONG=1 -D __SIZEOF_LONG_LONG__=8"
./tcc27a -c -g $INC $FL -o $C2/boot/libc_27.o $C2/boot/libc.c 2>>$LOG || exit 1; rm -f $C2/boot/libc_27.a; ./tcc27a -ar rc $C2/boot/libc_27.a $C2/boot/libc_27.o
./tcc27a -c -g $INC -D BOOTSTRAP=1 -o $C2/boot/libtcc1_27.o $C2/boot/libtcc1.c || exit 1
./tcc27a -c -g $INC -D BOOTSTRAP=1 -D TCC_TARGET_X86_64=1 -o $C2/boot/va_list_27.o $C2/boot/va_list.c || exit 1
./tcc27a -c -g $INC -I $C2/boot/include -D TCC_TARGET_X86_64=1 -D HAVE_FLOAT=1 -D HAVE_LONG_LONG=1 -o $C2/boot/tcclibtcc1_27.o $C2/boot/tcclibtcc1.c || exit 1
rm -f $C2/boot/libtcc1_27.a; ./tcc27a -ar rc $C2/boot/libtcc1_27.a $C2/boot/libtcc1_27.o $C2/boot/va_list_27.o $C2/boot/tcclibtcc1_27.o
cp $C2/boot/libc_27.a $P/lib/libc.a; cp $C2/boot/libc_27.a $O/lib/libc.a; cp $C2/boot/libtcc1_27.a $P/lib/tcc/libtcc1.a; cp $C2/boot/libtcc1_27.a $O/lib/libtcc1.a; cp $C2/boot/libtcc1_27.a $O/lib/tcc/libtcc1.a
say "libc.a $(stat -c %s $O/lib/libc.a) libtcc1.a $(stat -c %s $O/lib/libtcc1.a); libtcc1 members: $(ar t $O/lib/libtcc1.a | tr '\n' ' ')"
say "== self-hosting generations =="; cc027 ./tcc27a tcc27b || exit 1; cc027 ./tcc27b tcc27c || exit 1; cc027 ./tcc27c tcc27d || exit 1
cmp -s tcc27b tcc27c && cmp -s tcc27c tcc27d && say "FIXED POINT: tcc27b == tcc27c == tcc27d" || say "no fixed point b/c/d"
cmp -s tcc27a tcc27b && say "(tcc27a == tcc27b as well)" || say "(tcc27a != tcc27b, as before: a was built by boot9)"
say "TCC027_DONE"
