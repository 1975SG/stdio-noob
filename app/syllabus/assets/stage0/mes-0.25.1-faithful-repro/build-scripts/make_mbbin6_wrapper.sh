#!/bin/bash
# make_mbbin6_wrapper.sh: gcc-mesboot (gcc 4.9.4, dynamically linked) needs its own dynamic linker and
# runpath told explicitly, both glibc 2.16's (the target of the mesboot6 stage) and its own libgcc_s's -- hence
# a thin wrapper per tool. Each wrapper execs its OWN matching real binary (gcc->gcc, g++->g++, cpp->cpp): they
# are different programs, not aliases of gcc, a bug the from-scratch driver hit once when this was
# inlined and hardcoded "gcc" for all four, breaking g++/cpp silently until a C++ link failed downstream.
# usage: make_mbbin6_wrapper.sh <output dir> <gcc-mesboot prefix, e.g. $JT/g49/out> <glibc-2.16 prefix, e.g. $JT/g216/glibc216>
OUT=$1; CCPREFIX=$2; GLIBC=$3
mkdir -p $OUT
for p in gcc cc g++ cpp; do
  case $p in cc) real=gcc;; *) real=$p;; esac
  printf '#!/bin/bash\nexec %s/bin/%s -Wl,--dynamic-linker=%s/lib/ld-linux.so.2 -Wl,--rpath=%s/lib:%s/lib "$@"\n' \
    "$CCPREFIX" "$real" "$GLIBC" "$GLIBC" "$CCPREFIX" > $OUT/$p
  chmod +x $OUT/$p
done
echo "mbbin6 wrapper: $(ls $OUT | wc -l) entries in $OUT"
