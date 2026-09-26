#!/bin/bash
# glibc's own test suite for selected subdirectories, against the just-built glibc 2.16
JT=~/dev/stdio-noob; G216=$JT/g216; . $G216/env.sh
export SHELL=/bin/bash MAKE=make LD=gcc libc_cv_ssp=false
cd $G216/gf/glibc-2.16.0/build
for d in "$@"; do timeout 1500 make check subdirs="$d" SHELL=/bin/bash > $G216/gcheck_$d.log 2>&1; echo "$d rc=$?" >> $G216/gcheck.summary; done
echo CHECK-END >> $G216/gcheck.summary
