#!/bin/bash
# stage49.sh <name> <prefix of the gcc 4.9.4 that builds it>: gcc 4.9.4 again, built by a gcc 4.9.4 (bootstrap comparison).  Run hidden-headers.
JT=~/dev/stdio-noob; G216=$JT/g216; G46=$JT/g46; G49=$JT/g49; GL=$G216/glibc216; n=$1; CP=$2; W=$G49/$n; export LC_ALL=C
[ -z "$(ls /usr/include 2>/dev/null)" ] || { echo "/usr/include is visible: refusing"; exit 1; }
rm -rf $W; mkdir -p $W/wrap; cd $W
for p in gcc cc g++ cpp; do case $p in cc) real=gcc;; *) real=$p;; esac; printf '#!/bin/bash\nexec %s/bin/%s -Wl,--dynamic-linker=%s/lib/ld-linux.so.2 -Wl,--rpath=%s/lib:%s/lib "$@"\n' $CP $real $GL $GL $CP > $W/wrap/$p; chmod +x $W/wrap/$p; done
export PATH=$W/wrap:$G49/bumbin:$G216/tools:$PATH CONFIG_SHELL=/bin/bash
export C_INCLUDE_PATH=$GL/include:$W/gcc-4.9.4/mpfr/src CPLUS_INCLUDE_PATH=$GL/include:$W/gcc-4.9.4/mpfr/src LIBRARY_PATH=$GL/lib:$CP/lib
tar --no-same-owner -xjf $G49/gcc-4.9.4.tar.bz2; cd gcc-4.9.4; PT=$JT/rb/patch-2.5.9/patch
for p in gcc-4.9-libsanitizer-fix gcc-4.9-libsanitizer-ustat gcc-4.9-libsanitizer-mode-size gcc-arm-bug-71399 gcc-asan-missing-include gcc-libvtv-runpath gcc-fix-texi2pod; do $PT --force -p1 -i $G49/$p.patch > /dev/null 2>&1; done
for t in gmp-4.3.2 mpfr-2.4.2 mpc-1.0.3; do tar --no-same-owner -xzf $G46/$t.tar.gz; done; ln -s gmp-4.3.2 gmp; ln -s mpfr-2.4.2 mpfr; ln -s mpc-1.0.3 mpc
cd $W; mkdir b; cd b
sh ../gcc-4.9.4/configure --prefix=$W/out --build=i686-unknown-linux-gnu --host=i686-unknown-linux-gnu --with-host-libstdcxx=-lsupc++ --with-native-system-header-dir=$GL/include --with-build-sysroot=$GL/include --disable-bootstrap --disable-decimal-float --disable-libatomic --disable-libcilkrts --disable-libgomp --disable-libitm --disable-libmudflap --disable-libquadmath --disable-libsanitizer --disable-libssp --disable-libvtv --disable-lto --disable-lto-plugin --disable-multilib --disable-plugin --disable-threads --enable-languages=c,c++ --enable-static --enable-shared --enable-threads=single --disable-libstdcxx-pch --disable-build-with-cxx > $W/configure.log 2>&1 || { echo "$n CONFIGURE-FAILED"; exit 1; }
LDF="-B$GL/lib -Wl,-dynamic-linker -Wl,$GL/lib/ld-linux.so.2"
make LDFLAGS="$LDF" LDFLAGS_FOR_TARGET="$LDF" > $W/make.log 2>&1 || { echo "$n MAKE-FAILED"; exit 1; }
make install LDFLAGS="$LDF" LDFLAGS_FOR_TARGET="$LDF" > $W/install.log 2>&1 || { echo "$n INSTALL-FAILED"; exit 1; }
echo "$n DONE"
