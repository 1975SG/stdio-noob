#!/bin/bash
# gcc-cross-boot0 (Guix): gcc 14.3.0 cross-built for i686-guix-linux-gnu with --without-headers, host compiler gcc 4.9.4 (C++11), binutils 2.44 (cross-boot0)
JT=~/dev/stdio-noob; G8=$JT/g8; G6=$JT/g6; G49=$JT/g49; G216=$JT/g216; GL=$G216/glibc216
export PATH=$G6/mbbin6:$G8/out/bin:$G8/only LC_ALL=C CONFIG_SHELL=$G8/only/bash SHELL=$G8/only/bash FORCE_UNSAFE_CONFIGURE=1
export C_INCLUDE_PATH=$GL/include CPLUS_INCLUDE_PATH=$GL/include LIBRARY_PATH=$GL/lib:$G49/out/lib
[ -z "$(/usr/bin/ls /usr/include 2>/dev/null)" ] || { echo "/usr/include is visible: refusing"; exit 1; }
TRIPLET=i686-guix-linux-gnu; cd $G8; rm -rf gcc-14.3.0 gmp-6.0.0 mpfr-4.2.2 mpc-1.3.1 b14 out14
tar --no-same-owner -xJf gcc-14.3.0.tar.xz || { echo UNPACK-FAILED; exit 1; }; cd gcc-14.3.0
for p in gcc-12-strmov-store-file-names gcc-5.0-libvtv-runpath; do patch --force -p1 -i $G8/$p.patch > $G8/patch14_$p.log 2>&1; echo "$p: $(tail -1 $G8/patch14_$p.log | cut -c1-70)"; done
tar --no-same-owner -xJf $G8/gmp-6.0.0a.tar.xz; tar --no-same-owner -xJf $G8/mpfr-4.2.2.tar.xz; tar --no-same-owner -xzf $G8/mpc-1.3.1.tar.gz
ln -s gmp-6.0.0 gmp; ln -s mpfr-4.2.2 mpfr; ln -s mpc-1.3.1 mpc
sed -i '0,/#ifndef SIZE_MAX/s//#define SIZE_MAX (ULONG_MAX)\n#ifndef SIZE_MAX/' gcc/system.h      # recipe: patch-system.h (x86 linux)
sed -i 's|\.\./lib64|../lib|' gcc/config/i386/t-linux64 gcc/config/i386/t-gnu64                     # gcc-14's own phase
sed -i 's|\$gcc_cv_objdump -T|$OBJDUMP_FOR_TARGET -T|' libcc1/configure                            # gcc-canadian-cross-objdump-snippet
sed -i "s|la_LDFLAGS =|la_LDFLAGS = -Wl,-rpath=$G49/out/lib|" libcc1/Makefile.in                   # fix-libcc1
sed -i 's|g++ -v|true|' libcc1/configure
cd $G8; mkdir b14; cd b14
bash ../gcc-14.3.0/configure --prefix=$G8/out14 --build=i686-unknown-linux-gnu --host=i686-unknown-linux-gnu --target=$TRIPLET --without-headers --disable-shared --enable-languages=c,c++ --disable-libstdc++-v3 --disable-threads --disable-libmudflap --disable-libatomic --disable-libsanitizer --disable-libitm --disable-libgomp --disable-libmpx --disable-libcilkrts --disable-libvtv --disable-libssp --disable-libquadmath --disable-decimal-float --enable-plugin --disable-multilib --disable-libstdcxx-pch --with-local-prefix=/no-gcc-local-prefix --with-gxx-include-dir=$G8/out14/include/c++ > $G8/configure14.log 2>&1 || { echo CONFIGURE-FAILED; tail -12 $G8/configure14.log | cut -c1-200; exit 1; }
echo configured
LDF="-Wl,-rpath=$GL/lib -Wl,-rpath=$G49/out/lib -Wl,-dynamic-linker -Wl,$GL/lib/ld-linux.so.2"
make -j12 LDFLAGS="$LDF" > $G8/make14.log 2>&1; echo "MAKE-RC=$?" > $G8/make14.rc
