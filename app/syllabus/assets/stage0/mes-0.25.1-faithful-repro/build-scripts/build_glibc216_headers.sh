#!/bin/bash
# Scratch-session paths; run under build-scripts/run_hidden_headers.sh so the host /usr/include cannot leak.
# glibc-headers-mesboot (glibc 2.16.0, headers only)
JT=~/dev/stdio-noob; GLD=$JT/gl; G216=$JT/g216; . $G216/env.sh
cd $G216; rm -rf glibc-2.16.0 hdr_out; tar --no-same-owner -xzf glibc-2.16.0.tar.gz; cd glibc-2.16.0
PT=$JT/rb/patch-2.5.9/patch
$PT --force -p1 -i $G216/glibc-boot-2.16.0.patch > $G216/gh_patch.log 2>&1; tail -1 $G216/gh_patch.log
$PT --force -p1 -i $G216/glibc-bootstrap-system-2.16.0.patch >> $G216/gh_patch.log 2>&1; tail -1 $G216/gh_patch.log
# remove-bashism, per the recipe
sed -i 's#\$[{]vdso_symver//\./_[}]#$(echo $vdso_symver | sed -e "s/\\./_/g")#' sysdeps/unix/make-syscalls.sh; grep -c 'echo \$vdso_symver' sysdeps/unix/make-syscalls.sh
CPPF=" -I $PWD/nptl/sysdeps/pthread/bits -D BOOTSTRAP_GLIBC=1"
export libc_cv_friendly_stddef=yes SHELL=/bin/bash MAKE=make
export CPP="gcc -E $CPPF" CC="gcc $CPPF -L $PWD -L $GLD/out/lib" LD=gcc libc_cv_ssp=false
sed -i 's#/bin/pwd#pwd#' configure
mkdir build; cd build
../configure --prefix=$G216/hdr_out --disable-obsolete-rpc --host=i686-unknown-linux-gnu --with-headers=$GLD/headers/include --enable-static-nss --with-pthread --without-cvs --without-gd --enable-add-ons=nptl libc_cv_predef_stack_protector=no > $G216/gh_cfg.log 2>&1 || { echo CONFIG-FAILED; tail -12 $G216/gh_cfg.log; exit 1; }
echo configured
printf '\nSHELL := /bin/bash\n' >> Makefile
sed -i 's#^SHELL := /bin/sh#SHELL := /bin/bash#' ../Makefile ../Makeconfig ../elf/Makefile
make $PWD/sysd-sorted SHELL=/bin/bash > $G216/gh_sysd.log 2>&1 || { echo SYSD-FAILED; tail -5 $G216/gh_sysd.log; exit 1; }
sed -i 's# sunrpc# #; s# nis# #' sysd-sorted
make install-bootstrap-headers=yes install-headers SHELL=/bin/bash > $G216/gh_make.log 2>&1 || { echo HEADERS-FAILED; grep -m3 -B5 "\*\*\*" $G216/gh_make.log | cut -c1-200; exit 1; }
echo HEADERS-INSTALLED; ls $G216/hdr_out/include | head -5 | tr '\n' ' '
