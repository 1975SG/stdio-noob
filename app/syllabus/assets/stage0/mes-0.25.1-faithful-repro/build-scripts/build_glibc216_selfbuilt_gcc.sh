#!/bin/bash
# glibc-mesboot (glibc 2.16.0, full), built by gcc-mesboot1 against glibc-headers-mesboot
JT=~/dev/stdio-noob; GLD=$JT/gl; G216=$JT/g216; . $G216/env3.sh
cd $G216; rm -rf gfb; mkdir gfb; cd gfb; tar --no-same-owner -xzf $G216/glibc-2.16.0.tar.gz; cd glibc-2.16.0
PT=$JT/rb/patch-2.5.9/patch
$PT --force -p1 -i $G216/glibc-boot-2.16.0.patch > $G216/gfb_patch.log 2>&1; $PT --force -p1 -i $G216/glibc-bootstrap-system-2.16.0.patch >> $G216/gfb_patch.log 2>&1
sed -i 's#\$[{]vdso_symver//\./_[}]#$(echo $vdso_symver | sed -e "s/\\./_/g")#' sysdeps/unix/make-syscalls.sh
CPPF=" -I $PWD/nptl/sysdeps/pthread/bits -D BOOTSTRAP_GLIBC=1"
export libc_cv_friendly_stddef=yes SHELL=/bin/bash MAKE=make
export CPP="gcc -E $CPPF" CC="gcc $CPPF -L $PWD -L $GLD/out/lib" LD=gcc libc_cv_ssp=false
sed -i 's#/bin/pwd#pwd#' configure
mkdir build; cd build
../configure --prefix=$G216/glibc216b --disable-obsolete-rpc --host=i686-unknown-linux-gnu --with-headers=$G216/hdr_out/include --enable-static-nss --with-pthread --without-cvs --without-gd --enable-add-ons=nptl libc_cv_predef_stack_protector=no > $G216/gfb_cfg.log 2>&1 || { echo CONFIG-FAILED; tail -12 $G216/gfb_cfg.log; exit 1; }
printf '\nSHELL := /bin/bash\n' >> Makefile
sed -i 's#^SHELL := /bin/sh#SHELL := /bin/bash#' ../Makefile ../Makeconfig ../elf/Makefile
make $PWD/sysd-sorted SHELL=/bin/bash > $G216/gfb_sysd.log 2>&1 || { echo SYSD-FAILED; exit 1; }
sed -i 's# sunrpc# #; s# nis# #' sysd-sorted
make SHELL=/bin/bash > $G216/gfb_make.log 2>&1; echo "MAKE-RC=$?" > $G216/gfb_make.rc
