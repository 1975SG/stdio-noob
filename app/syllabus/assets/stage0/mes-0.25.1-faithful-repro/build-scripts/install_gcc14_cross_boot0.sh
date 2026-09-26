#!/bin/bash
JT=~/dev/stdio-noob; G8=$JT/g8; G6=$JT/g6; G49=$JT/g49; G216=$JT/g216; GL=$G216/glibc216
export PATH=$G6/mbbin6:$G8/out/bin:$G8/only LC_ALL=C CONFIG_SHELL=$G8/only/bash SHELL=$G8/only/bash
export C_INCLUDE_PATH=$GL/include CPLUS_INCLUDE_PATH=$GL/include LIBRARY_PATH=$GL/lib:$G49/out/lib
cd $G8/b14; LDF="-Wl,-rpath=$GL/lib -Wl,-rpath=$G49/out/lib -Wl,-dynamic-linker -Wl,$GL/lib/ld-linux.so.2"
make install LDFLAGS="$LDF" > $G8/install14.log 2>&1; echo "install rc=$?"
(cd $G8/out14/lib/gcc/i686-guix-linux-gnu/14.3.0 && ln -sf libgcc.a libgcc_eh.a)
