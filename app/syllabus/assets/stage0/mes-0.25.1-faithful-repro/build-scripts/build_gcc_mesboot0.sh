#!/bin/sh
# gcc-mesboot0 (Guix): gcc 2.95.3 rebuilt by the installed gcc 2.95.3 against glibc 2.2.5.  With the same
# script and CC pointing at the result you get the next stage (used for the self-reproduction check).
# Scratch-session paths; the steps are what matter.
# usage: build_gcc_mesboot0.sh <fresh gcc-2.95.3 source dir> <patch> <gcc-boot-2.95.3.patch> <prefix> <compiler prefix>
#        <glibc prefix> <kernel headers dir (with linux/nfs.h stub)> <tool dir with as/ld/ar/... wrappers and make>
SRC=$1; PATCH=$2; BOOT=$3; PREFIX=$4; CP=$5; GLIBC=$6; KH=$7; BIN=$8
GD=$CP/lib/gcc-lib/i686-unknown-linux-gnu/2.95.3     # (the first native gcc was configured as i686-pc-...; adjust)
# The compiler in "glibc mode": ONLY glibc + kernel headers and libs (no host /usr/include: gcc 2.95 is a native
# config and would otherwise pick it up), LIBRARY_PATH for the startfiles, -L because its ld ignores the variable.
cat > $BIN/gcc-glibc <<EOS
#!/bin/sh
export PATH=$BIN:\$PATH
export LIBRARY_PATH=$GLIBC/lib:$GD:$CP/lib
exec $CP/bin/gcc -nostdinc "\$@" -I $GD/include -I $GLIBC/include -I $KH -L $GLIBC/lib -L $GD -L $CP/lib
EOS
chmod +x $BIN/gcc-glibc; export PATH=$BIN:$PATH CONFIG_SHELL=/bin/bash LC_ALL=C
cd $SRC || exit 1; $PATCH --force -p1 -i $BOOT
printf "\nac_cv_c_float_format='IEEE (little-endian)'\n" > config.cache
CC=gcc-glibc CPP="gcc-glibc -E" sh ./configure --disable-shared --disable-werror \
  --build=i686-unknown-linux-gnu --host=i686-unknown-linux-gnu --prefix=$PREFIX
rm -rf texinfo; touch gcc/cpp.info gcc/gcc.info                      # no info at this stage
# libgcc2/crtstuff use the just-built xgcc, which searches /usr/include: isolate them with -nostdinc
INCS="-nostdinc -I $GD/include -I $GLIBC/include -I $KH"
make RANLIB=true LIBGCC2_INCLUDES="$INCS" LANGUAGES=c CC=gcc-glibc
make install RANLIB=true LIBGCC2_INCLUDES="$INCS" LANGUAGES=c CC=gcc-glibc
# Guix's install2: libgcc.a = libgcc2.a members; also lib/libgcc2.a
mkdir -p tmp; (cd tmp && ar x ../gcc/libgcc2.a && ar r $PREFIX/lib/gcc-lib/i686-unknown-linux-gnu/2.95.3/libgcc.a *.o)
cp gcc/libgcc2.a $PREFIX/lib/libgcc2.a
