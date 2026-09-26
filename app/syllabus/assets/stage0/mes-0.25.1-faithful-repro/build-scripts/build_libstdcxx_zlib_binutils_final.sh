#!/bin/bash
# libstdc++ (intermediate), zlib-final, binutils-final: built by the wrapped gcc-boot0 against glibc-final
JT=~/dev/stdio-noob; G8=$JT/g8; G12=$JT/g12; GF=$G12/glibc-final; . $G12/env12.sh $GF $G12/wrap-f
[ -z "$(/usr/bin/ls /usr/include 2>/dev/null)" ] || { echo "/usr/include is visible: refusing"; exit 1; }
cd $G12; mkdir -p src out
# --- libstdc++ from the gcc 14.3.0 tree (patched as for gcc-boot0)
rm -rf gccsrc; mkdir gccsrc; cd gccsrc; tar --no-same-owner -xJf $G8/gcc-14.3.0.tar.xz; cd gcc-14.3.0
for p in gcc-12-strmov-store-file-names gcc-5.0-libvtv-runpath; do patch --force -p1 -i $G8/$p.patch > /dev/null 2>&1; done
cd $G12; rm -rf lsb; mkdir lsb; cd lsb
bash ../gccsrc/gcc-14.3.0/libstdc++-v3/configure --prefix=$G12/out/libstdcxx --disable-shared --disable-libstdcxx-dual-abi --disable-libstdcxx-threads --disable-libstdcxx-pch --with-gxx-include-dir=$G12/out/libstdcxx/include > $G12/libstdcxx.configure.log 2>&1 || { echo "libstdc++ CONFIGURE-FAILED"; tail -8 $G12/libstdcxx.configure.log | cut -c1-180; }
make -j12 > $G12/libstdcxx.make.log 2>&1 && make install > $G12/libstdcxx.install.log 2>&1 && echo "libstdc++ DONE" || { echo "libstdc++ MAKE-FAILED"; grep -m3 -B2 "\*\*\* \[\|error:" $G12/libstdcxx.make.log | cut -c1-200; }
cd $G12
# --- zlib 1.3.1
rm -rf src/zlib; mkdir -p src/zlib; cd src/zlib; tar --no-same-owner -xzf $G12/zlib-1.3.1.tar.gz; cd zlib-1.3.1
{ ./configure --prefix=$G12/out/zlib > $G12/zlib.configure.log 2>&1 && make -j8 > $G12/zlib.make.log 2>&1 && make install > $G12/zlib.install.log 2>&1 && echo "zlib DONE"; } || echo "zlib FAILED"
cd $G12
# --- binutils-final 2.44 (native)
LSX=$G12/out/libstdcxx; export CPLUS_INCLUDE_PATH=$LSX/include:$LSX/include/i686-guix-linux-gnu:$CPLUS_INCLUDE_PATH
rm -rf src/binutils b_bu; mkdir -p src/binutils; cd src/binutils; tar --no-same-owner -xjf $G8/binutils-2.44.tar.bz2; cd binutils-2.44
for p in binutils-2.41-fix-cross binutils-loongson-workaround; do patch --force -p1 -i $G8/$p.patch > /dev/null 2>&1; done
cd $G12; mkdir b_bu; cd b_bu
bash ../src/binutils/binutils-2.44/configure --prefix=$G12/out/binutils-final --build=i686-guix-linux-gnu --host=i686-guix-linux-gnu --target=i686-guix-linux-gnu "LDFLAGS=-static-libgcc -L$LSX/lib" --enable-new-dtags --with-lib-path=/no-ld-lib-path --enable-install-libbfd --enable-deterministic-archives --enable-64-bit-bfd --enable-compressed-debug-sections=all --enable-lto --enable-separate-code --enable-threads > $G12/binutils.configure.log 2>&1 || { echo "binutils CONFIGURE-FAILED"; tail -8 $G12/binutils.configure.log | cut -c1-180; }
make -j12 MAKEINFO=true > $G12/binutils.make.log 2>&1 && make install MAKEINFO=true > $G12/binutils.install.log 2>&1 && echo "binutils-final (i686 triplet) DONE" || { echo "binutils MAKE-FAILED"; grep -m3 -B2 "\*\*\* \[\|error:" $G12/binutils.make.log | cut -c1-200; }
echo BUILD12C-END
