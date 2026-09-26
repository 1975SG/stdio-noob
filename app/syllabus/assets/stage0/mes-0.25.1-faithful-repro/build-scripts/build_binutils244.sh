#!/bin/bash
# binutils-cross-boot0 (Guix): binutils 2.44 cross-built for i686-guix-linux-gnu by gcc 4.9.4; PATH = only the bootstrapped tools
JT=~/dev/stdio-noob; G8=$JT/g8; G216=$JT/g216
export PATH=$G8/only LC_ALL=C CONFIG_SHELL=$G8/only/bash SHELL=$G8/only/bash FORCE_UNSAFE_CONFIGURE=1
export C_INCLUDE_PATH=$G216/glibc216/include CPLUS_INCLUDE_PATH=$G216/glibc216/include LIBRARY_PATH=$G216/glibc216/lib
[ -z "$(/usr/bin/ls /usr/include 2>/dev/null)" ] || { echo "/usr/include is visible: refusing"; exit 1; }
TRIPLET=i686-guix-linux-gnu; cd $G8; rm -rf binutils-2.44 b out; tar --no-same-owner -xjf binutils-2.44.tar.bz2 || { echo UNPACK-FAILED; exit 1; }
cd binutils-2.44; for p in binutils-2.41-fix-cross binutils-loongson-workaround; do patch --force -p1 -i $G8/$p.patch > $G8/patch_$p.log 2>&1; echo "$p: $(tail -1 $G8/patch_$p.log | cut -c1-70)"; done
cd $G8; mkdir b; cd b
bash ../binutils-2.44/configure --prefix=$G8/out --build=i686-unknown-linux-gnu --host=i686-unknown-linux-gnu --target=$TRIPLET --disable-gprofng LDFLAGS=-static-libgcc --enable-new-dtags --with-lib-path=/no-ld-lib-path --enable-install-libbfd --enable-deterministic-archives --enable-64-bit-bfd --enable-compressed-debug-sections=all --enable-lto --enable-separate-code --enable-threads > $G8/configure.log 2>&1 || { echo CONFIGURE-FAILED; tail -8 $G8/configure.log | cut -c1-200; exit 1; }
echo configured
make MAKEINFO=true > $G8/make.log 2>&1 || { echo MAKE-FAILED; grep -n "\*\*\* \[\|error:" $G8/make.log | head -5 | cut -c1-220; exit 1; }
make install MAKEINFO=true > $G8/install.log 2>&1 || { echo INSTALL-FAILED; exit 1; }
cd $G8/out/bin; for f in ${TRIPLET}-*; do ln -sf $f ${f#${TRIPLET}-}; done
echo BINUTILS244-DONE; ls | tr '\n' ' ' | cut -c1-300
