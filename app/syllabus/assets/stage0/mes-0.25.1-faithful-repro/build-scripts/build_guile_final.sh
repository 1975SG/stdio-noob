#!/bin/bash
# guile-final (Guix commencement.scm `guile-final` = guile-3.0/pinned = Guile 3.0.9, --enable-mini-gmp, libxcrypt dropped) and the
# packages it is built from, in the boot4 environment: gcc-final + binutils-final + glibc-final, bash-final as the shell.
JT=~/dev/stdio-noob; G8=$JT/g8; G9=$JT/g9; G10=$JT/g10; G12=$JT/g12; G13=$JT/g13
GFIN=$G12/out/gcc-final; BF=$G12/out/bash-final; O=$G13/out
export PATH=$O/pkg-config/bin:$GFIN/bin:$G12/bin-final:$G10/out/python/bin:$G9/out/m4/bin:$G9/out/perl/bin:$G9/out/bison/bin:$G8/only LC_ALL=C
export CONFIG_SHELL=$BF/bin/bash SHELL=$BF/bin/bash FORCE_UNSAFE_CONFIGURE=1
export C_INCLUDE_PATH=$G9/out/linux-headers/include CPLUS_INCLUDE_PATH=$G9/out/linux-headers/include
[ -z "$(/usr/bin/ls /usr/include 2>/dev/null)" ] || { echo "/usr/include is visible: refusing"; exit 1; }
gcc --version | head -1
step(){ # step <name> <tarball> <srcdir> <configure args...>
  n=$1; t=$2; d=$3; shift 3
  rm -rf $G13/src/$n $O/$n; mkdir -p $G13/src/$n; cd $G13/src/$n; tar --no-same-owner -xf $G13/$t || { echo "$n UNPACK-FAILED"; return 1; }; cd $d
  [ -n "$PRE" ] && eval "$PRE"
  $BF/bin/bash ./configure --build=i686-pc-linux-gnu --prefix=$O/$n "$@" > $G13/$n.configure.log 2>&1 || { echo "$n CONFIGURE-FAILED"; tail -8 $G13/$n.configure.log | cut -c1-200; return 1; }
  make $MAKEFLAGS_EXTRA > $G13/$n.make.log 2>&1 && make install > $G13/$n.install.log 2>&1 && echo "$n DONE" || { echo "$n MAKE-FAILED"; /usr/bin/grep -m3 -B2 "\*\*\* \[\|error:" $G13/$n.make.log | cut -c1-220; return 1; }
}
PRE= MAKEFLAGS_EXTRA= step pkg-config pkg-config-0.29.2.tar.gz pkg-config-0.29.2 --with-internal-glib || exit 1
export PKG_CONFIG_PATH=$O/libffi/lib/pkgconfig:$O/libunistring/lib/pkgconfig:$O/libgc/lib/pkgconfig
PRE= step libffi libffi-3.4.6.tar.gz libffi-3.4.6 --enable-portable-binary --without-gcc-arch || exit 1
PRE= MAKEFLAGS_EXTRA="-j1" step libunistring libunistring-1.3.tar.xz libunistring-1.3 || exit 1
PRE= step libgc gc-8.2.8.tar.gz gc-8.2.8 --enable-cplusplus || exit 1
export LDFLAGS="-Wl,-rpath=$O/libffi/lib -Wl,-rpath=$O/libunistring/lib -Wl,-rpath=$O/libgc/lib"
export CFLAGS="-I$O/libffi/include -I$O/libunistring/include -I$O/libgc/include" CPPFLAGS="-I$O/libffi/include -I$O/libunistring/include -I$O/libgc/include"
export LIBRARY_PATH=$O/libffi/lib:$O/libunistring/lib:$O/libgc/lib
PRE="find prebuilt -name '*.go' -delete; sed -i 's#/bin/sh#$BF/bin/bash#' module/ice-9/popen.scm" MAKEFLAGS_EXTRA="-j1" step guile guile-3.0.9.tar.xz guile-3.0.9 --disable-static --enable-mini-gmp "CFLAGS=-g -O2 -fexcess-precision=standard -I$O/libffi/include -I$O/libunistring/include -I$O/libgc/include" || exit 1
echo BUILD13B-END
