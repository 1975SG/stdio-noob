#!/bin/sh
# gcc 2.95.3 as a genuine i686-HOSTED compiler: built by the cross gcc (stage 1) against Mes's 32-bit
# libc, giving stage 2; run again with stage 2 as the compiler it gives stage 3 (the bootstrap compare).
# Scratch-session paths; the steps are what matter.
# usage: build_gcc295_i686.sh <compiler gcc dir (holds xgcc, include/, libgcc2.a)> <32-bit libc dir (crt1.o libc.a)>
#        <patch> <binutils build tree> <fresh gcc-2.95.3 source dir> <gcc-boot-2.95.3.patch> <mes tree> <as/ld wrapper dir>
#        <dir containing arch -> $MP/include/linux/x86>   (it MUST come first: the Mes tree's own include/arch may point at x86_64,
#        which gives the tools a 64-bit struct stat)
NEW=$1; LIB=$2; PATCH=$3; BU=$4; SRC=$5; BOOTPATCH=$6; MP=$7; BIN=$8; ARCHINC=$9; HERE=$(pwd)
# compiler wrapper: static, Mes headers only, link against Mes libc + libgcc2 (only when it is a link step)
cat > $HERE/cc32.sh <<EOS
#!/bin/sh
PRE="-B$NEW/ -static -nostdinc -I $ARCHINC -I $NEW/include -I $MP/include -I $MP/include/linux/x86"
link=1; for a in "\$@"; do case \$a in -c|-S|-E) link=0;; esac; done
export PATH=$BIN:\$PATH
if [ \$link = 1 ]; then exec $NEW/xgcc \$PRE -nostdlib "\$@" $LIB/crt1.o -L$LIB -lc $NEW/libgcc2.a -lc; else exec $NEW/xgcc \$PRE "\$@"; fi
EOS
chmod +x $HERE/cc32.sh; C=$HERE/cc32.sh; CPPF=" -D __GLIBC_MINOR__=6"
export PATH=$BIN:$PATH; cd $SRC || exit 1
$PATCH -p1 < $BOOTPATCH; cp $BU/config.sub $BU/config.guess . ; cp $BU/config.sub $BU/config.guess gcc/
# NO HOST_BITS_PER_LONG change here: the host really is 32-bit, unlike the earlier cross build
printf "\nac_cv_c_float_format='IEEE (little-endian)'\n" > config.cache
CONFIG_SHELL=/bin/sh CPPFLAGS="$CPPF" CC="$C$CPPF" CC_FOR_BUILD="$C$CPPF" CPP="$C -E$CPPF" \
  sh ./configure --enable-static --disable-shared --disable-werror \
    --build=i686-pc-linux-gnu --host=i686-pc-linux-gnu --target=i686-pc-linux-gnu --prefix=$HERE/out
rm -rf texinfo; touch gcc/cpp.info gcc/gcc.info
make LANGUAGES=c CC="$C$CPPF" OLDCC="$C$CPPF" CC_FOR_BUILD="$C$CPPF" AR=ar RANLIB=ranlib LIBGCC2_INCLUDES="-I $MP/include"
# Result: gcc/{xgcc,cc1,cpp0,cccp,libgcc2.a}, all ELF 32-bit.  Stage 3: rerun with NEW = the stage-2 gcc dir.
