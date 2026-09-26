#!/bin/bash
# Scratch-session paths; run under build-scripts/run_hidden_headers.sh so the host /usr/include cannot leak.
. ~/dev/stdio-noob/g216/env.sh; cd ~/dev/stdio-noob/g216; rm -rf bum; mkdir bum; cd bum; tar --no-same-owner -xjf ~/dev/stdio-noob/pb/binutils-2.20.1a.tar.bz2; cd binutils-2.20.1
~/dev/stdio-noob/rb/patch-2.5.9/patch -p1 < ~/dev/stdio-noob/pb/binutils-boot-2.20.1a.patch > /dev/null
export CC=gcc CPP="gcc -E" AR=ar RANLIB=ranlib CXX=false
sh ./configure --disable-nls --disable-shared --disable-werror --build=i686-unknown-linux-gnu --host=i686-unknown-linux-gnu --with-sysroot=/ --prefix=~/dev/stdio-noob/g216/bum/out > ../cfg.log 2>&1 || { echo CONFIG-FAILED; tail -5 ../cfg.log; exit 1; }
make MAKEINFO=true > ../make.log 2>&1 || { echo MAKE-FAILED; grep -m3 -B3 "\*\*\*" ../make.log | cut -c1-200; exit 1; }
echo BUILT; file gas/as-new | cut -c1-80
