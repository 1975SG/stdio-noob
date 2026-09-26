#!/bin/sh
# gcc 2.95.3 (Guix's gcc-core-mesboot0) built by tcc-0.9.27 as an x86-64-HOSTED CROSS compiler targeting i686.
# gcc 2.95.3 cannot generate x86-64 code, and Guix's chain is i686 throughout; here the host stays x86-64 and the
# kernel runs the 32-bit output (CONFIG_IA32_EMULATION).  Scratch-session paths; the steps are what matter.
# usage: build_gcc295.sh <tcc wrapper> <patch> <binutils build tree> <gcc-2.95.3 dir> <gcc-boot-2.95.3.patch> <mes tree>
CC=$1; PATCH=$2; BU=$3; SRC=$4; BOOTPATCH=$5; MP=$6; HERE=$(pwd)
mkdir -p $HERE/bin
# 32-bit defaulting wrappers around the tcc-built binutils (gcc invokes plain `as` and `ld`)
printf '#!/bin/sh\nexec %s --32 "$@"\n' $BU/gas/as-new > $HERE/bin/as
printf '#!/bin/sh\nexec %s -m elf_i386 "$@"\n' $BU/ld/ld-new > $HERE/bin/ld
for t in ar:binutils/ar ranlib:binutils/ranlib nm:binutils/nm-new objdump:binutils/objdump strip:binutils/strip-new objcopy:binutils/objcopy; do
  printf '#!/bin/sh\nexec %s "$@"\n' $BU/${t##*:} > $HERE/bin/${t%%:*}; done; chmod +x $HERE/bin/*
export PATH=$HERE/bin:$PATH
cd $SRC || exit 1
$PATCH -p1 < $BOOTPATCH                                  # Guix's patch: Makefile-only changes
cp $BU/config.sub $BU/config.guess . ; cp $BU/config.sub $BU/config.guess gcc/   # 1999 config.sub predates x86_64
# The i386 host file says long is 32 bits; the host here is 64-bit (target stays 32-bit i386).
sed -i 's/^#define HOST_BITS_PER_LONG 32$/#define HOST_BITS_PER_LONG 64/' gcc/config/i386/xm-i386.h
CPPF=" -D __GLIBC_MINOR__=6"
printf "\nac_cv_c_float_format='IEEE (little-endian)'\n" > config.cache
# present the machine as i686 so configure selects the i386 files; tests still run natively with the 64-bit tcc
CONFIG_SHELL=/bin/sh CPPFLAGS="$CPPF" CC="$CC$CPPF" CC_FOR_BUILD="$CC$CPPF" CPP="$CC -E$CPPF" \
  sh ./configure --enable-static --disable-shared --disable-werror \
    --build=i686-pc-linux-gnu --host=i686-pc-linux-gnu --target=i686-pc-linux-gnu --prefix=$HERE/out
rm -rf texinfo; touch gcc/cpp.info gcc/gcc.info          # no info at this stage (Guix 'remove-info')
# run make at the TOP level (libiberty first); LANGUAGES=c
make LANGUAGES=c CC="$CC -static$CPPF" OLDCC="$CC -static$CPPF" CC_FOR_BUILD="$CC -static$CPPF" \
     AR=ar RANLIB=ranlib LIBGCC2_INCLUDES="-I $MP/include"
# Result: gcc/xgcc gcc/cc1 gcc/cpp0 and gcc/libgcc2.a.  The "libgcc.a ... Error 1 (ignored)" line is expected:
# Guix's own install2 phase builds libgcc.a from libgcc2.a + libtcc1.a instead.
# NOTE: `make` does not relink when libc.a changes; delete cccp cpp0 cc1 xgcc to force it.
