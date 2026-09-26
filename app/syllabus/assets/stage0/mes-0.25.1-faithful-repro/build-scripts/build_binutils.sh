#!/bin/sh
# binutils 2.20.1a built by tcc-0.9.27 and the tcc-built make (Guix's
# binutils-mesboot0 recipe, i686 -> x86_64).  Scratch-session paths.
# usage: build_binutils.sh <tcc wrapper> <patch> <make> <unpacked binutils-2.20.1 dir> <binutils-boot-2.20.1a.patch>
# The wrapper must NOT prepend options when its first argument is -ar (see below).
CC=$1; PATCH=$2; MAKE=$3; cd $4 || exit 1
$PATCH -p1 < $5                                       # Guix's bootstrap patch
CPPF=" -D __GLIBC_MINOR__=6 -D MES_BOOTSTRAP=1"
PATH=$(dirname $MAKE):$PATH CONFIG_SHELL=/bin/sh CPPFLAGS="$CPPF" AR="$CC -ar" CXX=false RANLIB=true CC="$CC$CPPF" \
  sh ./configure --disable-nls --disable-shared --disable-werror \
    --build=x86_64-unknown-linux-gnu --host=x86_64-unknown-linux-gnu --with-sysroot=/
PATH=$(dirname $MAKE):$PATH $MAKE MAKEINFO=true
