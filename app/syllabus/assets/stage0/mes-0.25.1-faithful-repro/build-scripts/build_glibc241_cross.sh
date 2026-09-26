#!/bin/bash
# glibc-final-with-bootstrap-bash (Guix): glibc 2.41 cross-built for i686-guix-linux-gnu by gcc 14 (gcc-cross-boot0) + binutils 2.44, against the linux-libre 6.12.17 headers
JT=~/dev/stdio-noob; G6=$JT/g6; G8=$JT/g8; G9=$JT/g9; G10=$JT/g10; G11=$JT/g11
export PATH=$G8/out14/bin:$G8/out/bin:$G6/mbbin6:$G10/out/python/bin:$G10/out/texinfo/bin:$G10/out/autoconf/bin:$G10/out/automake/bin:$G9/out/m4/bin:$G9/out/perl/bin:$G9/out/bison/bin:$G9/out/flex/bin:$G8/only
export LC_ALL=C CONFIG_SHELL=$G8/only/bash SHELL=$G8/only/bash FORCE_UNSAFE_CONFIGURE=1
unset C_INCLUDE_PATH CPLUS_INCLUDE_PATH LIBRARY_PATH
[ -z "$(/usr/bin/ls /usr/include 2>/dev/null)" ] || { echo "/usr/include is visible: refusing"; exit 1; }
cd $G11; rm -rf glibc-2.41 b out; tar --no-same-owner -xJf glibc-2.41.tar.xz || { echo UNPACK-FAILED; exit 1; }; cd glibc-2.41
for p in glibc-ldd-powerpc glibc-2.41-ldd-x86_64 glibc-2.40-dl-cache glibc-2.37-versioned-locpath glibc-guix-locpath glibc-reinstate-prlimit64-fallback glibc-supported-locales; do patch --force -p1 -i $G11/$p.patch > $G11/patch_$p.log 2>&1 && echo "patched $p" || echo "PATCH-PROBLEM $p: $(tail -2 $G11/patch_$p.log | tr '\n' ' ' | cut -c1-120)"; done
BASH=$G11/sbash; OUT=$G11/out
# the recipe's pre-configure substitutions
sed -i "s|^\$(inst_sysconfdir)/rpc\(.*\)\$|$OUT/etc/rpc\1|; s|^install-others =.*\$|install-others = $OUT/etc/rpc|" inet/Makefile
sed -i 's| -lgcc_s||' Makeconfig
sed -i 's|@STORE_DIRECTORY@|"/gnu/store"|' elf/dl-cache.c
sed -i "s|^#define[[:space:]]*SHELL_PATH.*\$|#define SHELL_PATH \"$BASH/bin/bash\"|" sysdeps/posix/system.c
sed -i "s|/bin/sh|$BASH/bin/sh|" libio/iopopen.c
for f in $(find . -name paths.h); do sed -i "s|^#define[[:space:]]*_PATH_BSHELL[[:space:]].*\$|#define _PATH_BSHELL \"$BASH/bin/sh\"|" $f; done
sed -i 's|^#!.*||; s|exec @PERL@|exec perl|' malloc/mtrace.pl
cd $G11; mkdir b; cd b
KH=$G9/out/linux-headers/include
bash ../glibc-2.41/configure --prefix=$OUT --host=i686-guix-linux-gnu --build=i686-unknown-linux-gnu --sysconfdir=/etc libc_cv_complocaledir=/run/current-system/locale/2.41 --with-headers=$KH --enable-kernel=3.2.0 BASH_SHELL=$BASH/bin/bash > $G11/configure.log 2>&1 || { echo CONFIGURE-FAILED; tail -12 $G11/configure.log | cut -c1-200; exit 1; }
echo configured
make -j12 > $G11/make.log 2>&1; echo "MAKE-RC=$?" > $G11/make.rc
