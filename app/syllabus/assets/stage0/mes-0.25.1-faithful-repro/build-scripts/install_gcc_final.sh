#!/bin/bash
# gcc-final (Guix): gcc 14.3.0 native (i686-guix-linux-gnu), built by the wrapped gcc-boot0 against glibc-final, with libstdc++ (intermediate), zlib-final, binutils-final.
# A native gcc build bootstraps (stage1 by gcc-boot0, stage2 by stage1, stage3 by stage2, then `compare`).
JT=~/dev/stdio-noob; G8=$JT/g8; G12=$JT/g12; G9=$JT/g9; GF=$G12/glibc-final; LSX=$G12/out/libstdcxx; ZL=$G12/out/zlib; BF=$G12/out/binutils-final; OUT=$G12/out/gcc-final
. $G12/env12.sh $GF $G12/wrap-f
export PATH=$G12/bin-final:$PATH   # binutils-final first (prefixed and unprefixed): the stage compilers must not use the glibc-2.16 cross ld, which would dlopen a glibc-2.41 liblto_plugin.so
export CPLUS_INCLUDE_PATH=$LSX/include:$LSX/include/i686-guix-linux-gnu:$CPLUS_INCLUDE_PATH:$ZL/include C_INCLUDE_PATH=$C_INCLUDE_PATH:$ZL/include LIBRARY_PATH=$LIBRARY_PATH:$LSX/lib:$ZL/lib
[ -z "$(/usr/bin/ls /usr/include 2>/dev/null)" ] || { echo "/usr/include is visible: refusing"; exit 1; }
export CC=$G12/relax/gcc.sh STAGE_CC_WRAPPER=$G12/relax/stage-gcc.sh
XL="-L$LSX/lib -L$ZL/lib -Wl,-rpath=$ZL/lib"
cd $G12/b_gcc; make install "LDFLAGS=-Wl,-rpath=$GF/lib -Wl,-dynamic-linker -Wl,$GF/lib/ld-linux.so.2 $XL" "BOOT_LDFLAGS=$XL" "BOOT_CFLAGS=-O2 -g0" > $G12/gccfinal.install.log 2>&1; echo "install rc=$?"
