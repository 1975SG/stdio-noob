#!/bin/bash
# gcc-mesboot1 (gcc 4.6.4 with C and C++) built by gcc-mesboot0 (2.95.3).  usage: mbstage.sh <name>.  Meant to run with the
# host's /usr/include and /usr/local/include hidden.  usage: mbstage.sh <name> [<prefix of a gcc 4.6.4 to build it with>]
# (default builder: gcc-mesboot0 = gcc 2.95.3).  The host's /usr/include and /usr/local/include (unshare -rm + bind mounts of an empty dir), like Guix's sandbox.
JT=~/dev/stdio-noob; GLD=$JT/gl; G46=$JT/g46; W=$G46/$1; export LC_ALL=C
[ -z "$(ls /usr/include 2>/dev/null)" ] || { echo "/usr/include is visible: refusing"; exit 1; }
rm -rf $W; mkdir -p $W; cd $W
tar --no-same-owner -xzf $G46/gcc-core-4.6.4.tar.gz; tar --no-same-owner -xzf $G46/gcc-g++-4.6.4.tar.gz; cd gcc-4.6.4; $JT/rb/patch-2.5.9/patch --force -p1 -i $G46/gcc-boot-4.6.4.patch > /dev/null
for t in gmp-4.3.2 mpfr-2.4.2 mpc-1.0.3; do tar --no-same-owner -xzf $G46/$t.tar.gz; done; ln -s gmp-4.3.2 gmp; ln -s mpfr-2.4.2 mpfr; ln -s mpc-1.0.3 mpc
G2=$JT/gcc/s4/out/lib/gcc-lib/i686-unknown-linux-gnu/2.95.3
export PATH=$GLD/bu1bin:$PATH CONFIG_SHELL=/bin/bash EXTRA_INC="-I $W/gcc-4.6.4/mpfr/src"
export C_INCLUDE_PATH=$G2/include:$GLD/headers/include:$GLD/out/include:$W/gcc-4.6.4/mpfr/src; export CPLUS_INCLUDE_PATH=$C_INCLUDE_PATH
export LIBRARY_PATH=$GLD/out/lib:$JT/gcc/s4/out/lib CC=gcc-glibc4x CPP="gcc-glibc4x -E" AR=ar RANLIB=ranlib
if [ -n "$2" ]; then   # a gcc 4.6.4 builds it: no 2.95 include dir, no -nostdinc wrapper needed (the host headers are hidden)
  export C_INCLUDE_PATH=$GLD/headers/include:$GLD/out/include:$W/gcc-4.6.4/mpfr/src; export CPLUS_INCLUDE_PATH=$C_INCLUDE_PATH
  export LIBRARY_PATH=$GLD/out/lib CC="$2/bin/gcc" CPP="$2/bin/gcc -E"; fi
cd $W; mkdir b; cd b
sh ../gcc-4.6.4/configure --prefix=$W/out --build=i686-unknown-linux-gnu --host=i686-unknown-linux-gnu --with-native-system-header-dir=$GLD/out/include --with-build-sysroot=$GLD/out/include --disable-bootstrap --disable-decimal-float --disable-libatomic --disable-libcilkrts --disable-libgomp --disable-libitm --disable-libmudflap --disable-libquadmath --disable-libsanitizer --disable-libssp --disable-libvtv --disable-lto --disable-lto-plugin --disable-multilib --disable-plugin --disable-threads --enable-languages=c,c++ --enable-static --disable-shared --enable-threads=single --disable-libstdcxx-pch --disable-build-with-cxx > $W/configure.log 2>&1 || { echo "$1 CONFIGURE-FAILED"; exit 1; }
make NATIVE_SYSTEM_HEADER_DIR=$GLD/out/include LDFLAGS="-B$GLD/out/lib/" LDFLAGS_FOR_TARGET="-B$GLD/out/lib/" > $W/make.log 2>&1 || { echo "$1 MAKE-FAILED"; exit 1; }
make install NATIVE_SYSTEM_HEADER_DIR=$GLD/out/include LDFLAGS="-B$GLD/out/lib/" LDFLAGS_FOR_TARGET="-B$GLD/out/lib/" > $W/install.log 2>&1 || { echo "$1 INSTALL-FAILED"; exit 1; }
echo "$1 DONE"
