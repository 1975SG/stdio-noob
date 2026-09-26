#!/bin/bash
# bash-final (Guix): bash-minimal (5.2 + 37 upstream patches + bash-linux-pgrp-pipe.patch), built by gcc-final against glibc-final,
# `LDFLAGS=-static-libgcc` (static-libgcc-package) so it keeps no reference to libgcc_s.
JT=~/dev/stdio-noob; G8=$JT/g8; G9=$JT/g9; G12=$JT/g12; GFIN=$G12/out/gcc-final; OUT=$G12/out/bash-final
export PATH=$GFIN/bin:$G12/bin-final:$G12/../g10/out/python/bin:$G9/out/m4/bin:$G9/out/perl/bin:$G9/out/bison/bin:$G8/only LC_ALL=C CONFIG_SHELL=$G8/only/bash SHELL=$G8/only/bash
export C_INCLUDE_PATH=$G9/out/linux-headers/include
[ -z "$(/usr/bin/ls /usr/include 2>/dev/null)" ] || { echo "/usr/include is visible: refusing"; exit 1; }
gcc --version | head -1
rm -rf $G12/src/bashfinal $OUT; mkdir -p $G12/src/bashfinal; cd $G12/src/bashfinal; tar --no-same-owner -xzf $G12/bash-5.2.tar.gz; cd bash-5.2
for i in $(ls $G12/bash52-* | sort); do patch -p0 -s < $i || echo PATCH-PROBLEM $i; done
patch -p0 -s < $G12/bash-linux-pgrp-pipe.patch || echo PATCH-PROBLEM pgrp
bash ./configure --build=i686-pc-linux-gnu --prefix=$OUT --without-bash-malloc --disable-readline --disable-history --disable-help-builtin --disable-progcomp --disable-net-redirections --disable-nls ac_cv_func_dlopen=no "CFLAGS=-g -O2 -Wno-error=implicit-function-declaration" "LDFLAGS=-static-libgcc" > $G12/bashfinal.configure.log 2>&1 || { echo "CONFIGURE-FAILED"; tail -8 $G12/bashfinal.configure.log | cut -c1-200; exit 1; }
make > $G12/bashfinal.make.log 2>&1 && make install > $G12/bashfinal.install.log 2>&1 && ln -s bash $OUT/bin/sh && echo "bash-final DONE" || { echo "MAKE-FAILED"; /usr/bin/grep -m3 -B2 "\*\*\* \[\|error:" $G12/bashfinal.make.log | cut -c1-200; }
echo BUILD13A-END
