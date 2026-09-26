#!/bin/bash
# gcc 4.6.4 (Guix's gcc-core-mesboot1): gcc-core-4.6.4 + GMP 4.3.2 + MPFR 2.4.2 + MPC 1.0.3 unpacked in-tree (symlinks gmp,
# mpfr, mpc), Guix's gcc-boot-4.6.4.patch, C only, --disable-bootstrap, built by the compiler at <prefix>.  Run it with the
# gcc-mesboot0 (gcc 2.95.3 in glibc mode) for stage 1, then with the result for stages 2 and 3 (bootstrap comparison).
# Scratch-session paths ($JT, $GLD = the glibc/binutils-mesboot1/make-3.82 environment built earlier, $G46 = sources).
# Needs: `-nostdinc` + explicit -isystem for glibc, kernel headers and the compiler's own dirs, because gcc 4.6.4 (like 2.95)
# still searches /usr/include (the boot patch comments out NATIVE_SYSTEM_HEADER_DIR); C_INCLUDE_PATH as in Guix's recipe.
# usage: build_gcc464.sh <name> <prefix of the compiler that builds it>   -> builds+installs gcc 4.6.4 into $G46/<name>/out
JT=~/dev/stdio-noob; GLD=$JT/gl; G46=$JT/g46; n=$1; CP=$2; W=$G46/$n; export LC_ALL=C
GI=$CP/lib/gcc/i686-unknown-linux-gnu/4.6.4
rm -rf $W; mkdir -p $W; cd $W
cat > cc <<EOS
#!/bin/sh
export PATH=$GLD/bu1bin:\$PATH LIBRARY_PATH=$GLD/out/lib
exec $CP/bin/gcc -nostdinc "\$@" -isystem $GI/include -isystem $GI/include-fixed -isystem $GLD/out/include -isystem $GLD/headers/include \$EXTRA_INC
EOS
chmod +x cc
tar xzf $G46/gcc-core-4.6.4.tar.gz; cd gcc-4.6.4; $JT/rb/patch-2.5.9/patch --force -p1 -i $G46/gcc-boot-4.6.4.patch >/dev/null
for t in gmp-4.3.2 mpfr-2.4.2 mpc-1.0.3; do tar xzf $G46/$t.tar.gz; done; ln -s gmp-4.3.2 gmp; ln -s mpfr-2.4.2 mpfr; ln -s mpc-1.0.3 mpc
export PATH=$GLD/bu1bin:$PATH CONFIG_SHELL=/bin/bash EXTRA_INC="-I $W/gcc-4.6.4/mpfr/src" CC=$W/cc CPP="$W/cc -E" AR=ar RANLIB=ranlib
mkdir ../b; cd ../b
sh ../gcc-4.6.4/configure --prefix=$W/out --build=i686-unknown-linux-gnu --host=i686-unknown-linux-gnu --with-native-system-header-dir=$GLD/out/include --with-build-sysroot=$GLD/out/include --disable-bootstrap --disable-decimal-float --disable-libatomic --disable-libcilkrts --disable-libgomp --disable-libitm --disable-libmudflap --disable-libquadmath --disable-libsanitizer --disable-libssp --disable-libvtv --disable-lto --disable-lto-plugin --disable-multilib --disable-plugin --disable-threads --enable-languages=c --enable-static --disable-shared --enable-threads=single --disable-libstdcxx-pch --disable-build-with-cxx > $W/configure.log 2>&1 || { echo "$n CONFIGURE-FAILED"; exit 1; }
export C_INCLUDE_PATH=$JT/gcc/s4/out/lib/gcc-lib/i686-unknown-linux-gnu/2.95.3/include:$GLD/headers/include:$GLD/out/include:$W/gcc-4.6.4/mpfr/src LIBRARY_PATH=$GLD/out/lib
[ "$CP" = "$G46/out" ] || export C_INCLUDE_PATH=$GLD/headers/include:$GLD/out/include:$W/gcc-4.6.4/mpfr/src
make LDFLAGS="-B$GLD/out/lib/" LDFLAGS_FOR_TARGET="-B$GLD/out/lib/" > $W/make.log 2>&1 || { echo "$n MAKE-FAILED"; exit 1; }
make install LDFLAGS="-B$GLD/out/lib/" LDFLAGS_FOR_TARGET="-B$GLD/out/lib/" > $W/install.log 2>&1 || { echo "$n INSTALL-FAILED"; exit 1; }
echo "$n DONE"
