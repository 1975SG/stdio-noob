#!/bin/bash
# check_glibc216_nptl_relinked.sh: reruns glibc 2.16's nptl tests with gcc wrapped so `-lgcc`
# becomes gcc 4.9.4's shared libgcc_s.so.1 (link_with_gcc494_libgcc_s.sh), fixing the -fexceptions family
# (tst-cancelx*, tst-cleanupx*, tst-oncex*: two independent unwinders in one process -> SIGABRT).
# usage: run this script's own directory must contain link_with_gcc494_libgcc_s.sh.
JT=~/dev/stdio-noob; G216=$JT/g216; B=$G216/gfb/glibc-2.16.0/build
HERE=$(cd "$(dirname "$0")" && pwd)
W=$(mktemp -d); ln -s $HERE/link_with_gcc494_libgcc_s.sh $W/gcc; ln -s gcc $W/cc
. $G216/env3.sh
export PATH=$W:$PATH SHELL=/bin/bash MAKE=make LD=gcc libc_cv_ssp=false
cd $B
timeout 3000 make -k check subdirs=nptl SHELL=/bin/bash > $G216/relink_check.log 2>&1
echo "rc=$?"
rm -rf $W
