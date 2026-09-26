#!/bin/bash
# gcc-mesboot (Guix): gcc 4.9.4, C and C++, shared libgcc/libstdc++, built by gcc-mesboot1 (self-built 4.6.4) against glibc 2.16
JT=~/dev/stdio-noob; G216=$JT/g216; G46=$JT/g46; G49=$JT/g49; GL=$G216/glibc216; . $G49/env.sh
[ -z "$(ls /usr/include 2>/dev/null)" ] || { echo "/usr/include is visible: refusing"; exit 1; }
cd $G49; rm -rf gcc-4.9.4 b out; tar --no-same-owner -xjf gcc-4.9.4.tar.bz2; cd gcc-4.9.4
PT=$JT/rb/patch-2.5.9/patch
for p in gcc-4.9-libsanitizer-fix gcc-4.9-libsanitizer-ustat gcc-4.9-libsanitizer-mode-size gcc-arm-bug-71399 gcc-asan-missing-include gcc-libvtv-runpath gcc-fix-texi2pod; do $PT --force -p1 -i $G49/$p.patch > $G49/patch_$p.log 2>&1; echo "$p: $(tail -1 $G49/patch_$p.log | cut -c1-80)"; done
for t in gmp-4.3.2 mpfr-2.4.2 mpc-1.0.3; do tar --no-same-owner -xzf $G46/$t.tar.gz; done; ln -s gmp-4.3.2 gmp; ln -s mpfr-2.4.2 mpfr; ln -s mpc-1.0.3 mpc
cd $G49; mkdir b; cd b
sh ../gcc-4.9.4/configure --prefix=$G49/out --build=i686-unknown-linux-gnu --host=i686-unknown-linux-gnu --with-host-libstdcxx=-lsupc++ --with-native-system-header-dir=$GL/include --with-build-sysroot=$GL/include --disable-bootstrap --disable-decimal-float --disable-libatomic --disable-libcilkrts --disable-libgomp --disable-libitm --disable-libmudflap --disable-libquadmath --disable-libsanitizer --disable-libssp --disable-libvtv --disable-lto --disable-lto-plugin --disable-multilib --disable-plugin --disable-threads --enable-languages=c,c++ --enable-static --enable-shared --enable-threads=single --disable-libstdcxx-pch --disable-build-with-cxx > $G49/configure.log 2>&1 || { echo CONFIGURE-FAILED; tail -12 $G49/configure.log; exit 1; }
echo configured
LDF="-B$GL/lib -Wl,-dynamic-linker -Wl,$GL/lib/ld-linux.so.2"
make LDFLAGS="$LDF" LDFLAGS_FOR_TARGET="$LDF" > $G49/make.log 2>&1; echo "MAKE-RC=$?" > $G49/make.rc
