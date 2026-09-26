#!/bin/bash
# static-bash-for-glibc and gettext-boot0, built by the wrapped gcc-boot0 against glibc-intermediate
JT=~/dev/stdio-noob; G11=$JT/g11; G12=$JT/g12; . $G12/env12.sh $G11/out $G12/wrap-i
[ -z "$(/usr/bin/ls /usr/include 2>/dev/null)" ] || { echo "/usr/include is visible: refusing"; exit 1; }
gcc --version | head -1
cd $G12; mkdir -p src out
# static bash: bash-minimal flags + static, 5.2 with its 37 patches
rm -rf src/bash; mkdir -p src/bash; cd src/bash; tar --no-same-owner -xzf $G12/bash-5.2.tar.gz; cd bash-5.2
for i in $(ls $G12/bash52-* | sort); do patch -p0 -s < $i || echo PATCH-PROBLEM $i; done
bash ./configure --prefix=$G12/out/bash --without-bash-malloc --disable-readline --disable-history --disable-help-builtin --disable-progcomp --disable-net-redirections --disable-nls ac_cv_func_dlopen=no "CFLAGS=-g -O2 -Wno-error=implicit-function-declaration" "LDFLAGS=-static -L$G11/out/lib" > $G12/bash.configure.log 2>&1 || { echo "bash CONFIGURE-FAILED"; tail -6 $G12/bash.configure.log | cut -c1-160; }
make -j8 > $G12/bash.make.log 2>&1 && make install > $G12/bash.install.log 2>&1 && echo "static bash DONE" || { echo "bash MAKE-FAILED"; grep -m3 -B2 "\*\*\* \[\|error:" $G12/bash.make.log | cut -c1-200; }
cd $G12
# gettext-boot0: 0.19.8.1, tools only
rm -rf src/gettext; mkdir -p src/gettext; cd src/gettext; tar --no-same-owner -xzf $G12/gettext-0.19.8.1.tar.gz; cd gettext-0.19.8.1/gettext-tools
sed -i 's/^PROGRAMS =.*$/PROGRAMS =/' tests/Makefile.in
bash ./configure --prefix=$G12/out/gettext "CFLAGS=-g -O2 -std=gnu99 -Wno-implicit-function-declaration -Wno-int-conversion -Wno-incompatible-pointer-types -Wno-implicit-int" > $G12/gettext.configure.log 2>&1 || { echo "gettext CONFIGURE-FAILED"; tail -6 $G12/gettext.configure.log | cut -c1-160; }
make -j8 > $G12/gettext.make.log 2>&1 && make install > $G12/gettext.install.log 2>&1 && echo "gettext-boot0 DONE" || { echo "gettext MAKE-FAILED"; grep -m3 -B2 "\*\*\* \[\|error:" $G12/gettext.make.log | cut -c1-200; }
echo BUILD12A-END
