#!/bin/sh
# binutils-mesboot1 (Guix): binutils 2.20.1a again, now built by gcc-mesboot0 against glibc 2.2.5 (i686 host).
# Same recipe as binutils-mesboot0 minus the tcc-specific settings.  Scratch-session paths.
# usage: build_binutils_mesboot1.sh <gcc-in-glibc-mode wrapper> <patch> <unpacked binutils-2.20.1 dir> <binutils-boot-2.20.1a.patch> <prefix>
# then, for make 3.82 (Guix's gnu-make-mesboot):  CC=<wrapper> ./configure "LIBS=-lc -lnss_files -lnss_dns -lresolv" && make
CC=$1; PATCH=$2; cd $3 || exit 1; $PATCH -p1 < $4
export CONFIG_SHELL=/bin/bash CC CPP="$CC -E" AR=ar RANLIB=ranlib CXX=false LC_ALL=C
sh ./configure --disable-nls --disable-shared --disable-werror --build=i686-unknown-linux-gnu \
  --host=i686-unknown-linux-gnu --with-sysroot=/ --prefix=$5
make MAKEINFO=true
