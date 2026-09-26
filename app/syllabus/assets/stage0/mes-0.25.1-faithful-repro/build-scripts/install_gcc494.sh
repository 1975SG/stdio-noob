#!/bin/bash
JT=~/dev/stdio-noob; G216=$JT/g216; G49=$JT/g49; GL=$G216/glibc216; . $G49/env.sh
cd $G49/b; LDF="-B$GL/lib -Wl,-dynamic-linker -Wl,$GL/lib/ld-linux.so.2"
make install LDFLAGS="$LDF" LDFLAGS_FOR_TARGET="$LDF" > $G49/install.log 2>&1; echo "install rc=$?"
