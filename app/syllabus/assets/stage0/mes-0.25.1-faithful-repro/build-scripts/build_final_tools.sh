#!/bin/bash
# The final tools of Guix's %final-inputs: coreutils 9.1, grep 3.11, sed 4.9, xz 5.4.5, bzip2 1.0.8, gzip 1.14, tar 1.35, diffutils 3.12,
# findutils 4.10.0, patch 2.7.6, file 5.46, gawk 5.3.0 (+ libsigsegv 2.14), zstd 1.5.6, make 4.4.1 (with Guile).  Built by gcc-final, linked through ld-wrapper,
# with bash-final as the shell, in the header-free sandbox.  usage: build14.sh [package ...]  (default: all)
JT=~/dev/stdio-noob; G8=$JT/g8; G9=$JT/g9; G10=$JT/g10; G12=$JT/g12; G13=$JT/g13; G14=$JT/g14
BF=$G12/out/bash-final; O=$G14/out; WR=$G13/out/ld-wrapper/bin
export PATH=${FINAL_PATH:+$FINAL_PATH:}$G13/out/pkg-config/bin:$G12/out/gcc-final/bin:$G12/bin-final:$G10/out/python/bin:$G9/out/m4/bin:$G9/out/perl/bin:$G9/out/bison/bin:$G8/only LC_ALL=C
export CONFIG_SHELL=$BF/bin/bash SHELL=$BF/bin/bash FORCE_UNSAFE_CONFIGURE=1 NIX_STORE=$JT
export C_INCLUDE_PATH=$G9/out/linux-headers/include CPLUS_INCLUDE_PATH=$G9/out/linux-headers/include
[ -z "$(/usr/bin/ls /usr/include 2>/dev/null)" ] || { echo "/usr/include is visible: refusing"; exit 1; }
CC="gcc -B$WR"; export CC
mkdir -p $G14/src $O
unpack(){ n=$1; t=$2; d=$3; rm -rf $G14/src/$n $O/$n; mkdir -p $G14/src/$n; cd $G14/src/$n; tar --no-same-owner -xf $G14/$t || return 1; cd $d; }
patches(){ for p in "$@"; do patch -p1 -s < $G14/patches/$p.patch || { echo "PATCH-FAILED $p"; return 1; }; done; }
cfg(){ n=$1; shift; $BF/bin/bash ./configure --prefix=$O/$n "$@" > $G14/$n.configure.log 2>&1 || { echo "$n CONFIGURE-FAILED"; tail -6 $G14/$n.configure.log | cut -c1-200; return 1; }; }
mk(){ n=$1; shift; make "$@" > $G14/$n.make.log 2>&1 || { echo "$n MAKE-FAILED"; /usr/bin/grep -m3 -B2 "\*\*\* \[\|error:" $G14/$n.make.log | cut -c1-220; return 1; }; }
inst(){ n=$1; shift; make install "$@" > $G14/$n.install.log 2>&1 || { echo "$n INSTALL-FAILED"; tail -5 $G14/$n.install.log | cut -c1-200; return 1; }; echo "$n DONE"; }
sub(){ f=$1; from=$2; to=$3; sed -i "s#$from#$to#" $f; }

b_libsigsegv(){ unpack libsigsegv libsigsegv-2.14.tar.gz libsigsegv-2.14 && cfg libsigsegv --build=i686-pc-linux-gnu && mk libsigsegv && inst libsigsegv; }
b_coreutils(){ unpack coreutils coreutils-9.1.tar.xz coreutils-9.1 && cfg coreutils --build=i686-pc-linux-gnu && mk coreutils -j1 && inst coreutils; }
b_grep(){ unpack grep grep-3.11.tar.xz grep-3.11 && patches grep-timing-sensitive-test && cfg grep --build=i686-pc-linux-gnu && mk grep && inst grep && sed -i "s#^exec grep#exec $O/grep/bin/grep#" $O/grep/bin/egrep $O/grep/bin/fgrep; }
b_sed(){ unpack sed sed-4.9.tar.gz sed-4.9 && cfg sed --build=i686-pc-linux-gnu && mk sed && inst sed; }
b_xz(){ unpack xz xz-5.4.5.tar.gz xz-5.4.5 && cfg xz --build=i686-pc-linux-gnu && mk xz && inst xz; }
b_bzip2(){ unpack bzip2 bzip2-1.0.8.tar.gz bzip2-1.0.8 && sed -i "s#^SHELL=.*#SHELL=$BF/bin/sh#" Makefile-libbz2_so 2>/dev/null; mk bzip2 CC="$CC" && mk bzip2 -f Makefile-libbz2_so CC="$CC" && make install PREFIX=$O/bzip2 > $G14/bzip2.install.log 2>&1 && lib=$(ls libbz2.so.1.0.* | head -1) && install -m755 $lib $O/bzip2/lib/ && (cd $O/bzip2/lib && ln -sf $lib libbz2.so.1.0 && ln -sf libbz2.so.1.0 libbz2.so.1 && ln -sf libbz2.so.1 libbz2.so) && echo "bzip2 DONE"; }
b_gzip(){ unpack gzip gzip-1.14.tar.xz gzip-1.14 && sed -i "s#exec 'gzip'#exec $O/gzip/bin/gzip#" gunzip.in && cfg gzip --build=i686-pc-linux-gnu 'ac_cv_prog_LESS="less"' && mk gzip && inst gzip; }
b_tar(){ unpack tar tar-1.35.tar.xz tar-1.35 && patches tar-skip-unreliable-tests tar-remove-wholesparse-check && sed -i "s#/bin/sh#$BF/bin/sh#" src/system.c && cfg tar --build=i686-pc-linux-gnu && mk tar && inst tar; }
b_diffutils(){ unpack diffutils diffutils-3.12.tar.xz diffutils-3.12 && cfg diffutils --build=i686-pc-linux-gnu && mk diffutils && inst diffutils; }
b_findutils(){ unpack findutils findutils-4.10.0.tar.xz findutils-4.10.0 && patches findutils-localstatedir && cfg findutils --build=i686-pc-linux-gnu --localstatedir=/var && mk findutils && inst findutils; }
b_patch(){ unpack patch patch-2.7.6.tar.xz patch-2.7.6 && cfg patch --build=i686-pc-linux-gnu && mk patch && inst patch; }
b_file(){ unpack file file-5.46.tar.gz file-5.46 && cfg file --build=i686-pc-linux-gnu && mk file && inst file; }
b_gawk(){ unpack gawk gawk-5.3.0.tar.xz gawk-5.3.0 && sed -i "s#/bin/sh#$BF/bin/sh#" io.c && cfg gawk --build=i686-pc-linux-gnu --with-libsigsegv-prefix=$O/libsigsegv "LDFLAGS=-Wl,-rpath=$O/libsigsegv/lib" && mk gawk && inst gawk; }
b_zstd(){ unpack zstd zstd-1.5.6.tar.gz zstd-1.5.6 && sed -i "s#(:-)grep#\1$O/grep/bin/grep#; s#(:-)zstdcat#\1$O/zstd/bin/zstdcat#" -E programs/zstdgrep; sed -i "s#zstdcat#$O/zstd/bin/zstdcat#" programs/zstdless; mk zstd CC="$CC" prefix=$O/zstd libdir=$O/zstd/lib includedir=$O/zstd/include PCLIBDIR=lib PCINCDIR=include HAVE_LZMA=0 HAVE_LZ4=0 HAVE_ZLIB=0 && make install CC="$CC" prefix=$O/zstd libdir=$O/zstd/lib includedir=$O/zstd/include PCLIBDIR=lib PCINCDIR=include HAVE_LZMA=0 HAVE_LZ4=0 HAVE_ZLIB=0 > $G14/zstd.install.log 2>&1 && echo "zstd DONE"; }
b_make(){ unpack make make-4.4.1.tar.gz make-4.4.1 && patches make-impure-dirs && sed -i "s#default_shell =.*\$#default_shell = \"$BF/bin/sh\";#" src/job.c && export PKG_CONFIG_PATH=$G13/out/guile/lib/pkgconfig:$G13/out/libffi/lib/pkgconfig:$G13/out/libunistring/lib/pkgconfig:$G13/out/libgc/lib/pkgconfig && export LIBRARY_PATH=$G13/out/libffi/lib:$G13/out/libunistring/lib:$G13/out/libgc/lib:$G13/out/guile/lib && export LDFLAGS="-Wl,-rpath=$G13/out/guile/lib -Wl,-rpath=$G13/out/libgc/lib -Wl,-rpath=$G13/out/libffi/lib -Wl,-rpath=$G13/out/libunistring/lib" && cfg make --build=i686-pc-linux-gnu && mk make && inst make; }

ALL="libsigsegv coreutils grep sed xz bzip2 gzip tar diffutils findutils patch file gawk zstd make"
for p in ${@:-$ALL}; do b_$p; done
echo BUILD14-END
