#!/bin/bash
# nptl tests again, now that libgcc_s.so.1 (from gcc 4.9.4) is in the glibc build directory
JT=~/dev/stdio-noob; G216=$JT/g216; . $G216/env3.sh
export SHELL=/bin/bash MAKE=make LD=gcc libc_cv_ssp=false
cd $G216/gfb/glibc-2.16.0/build
timeout 3000 make -k check subdirs=nptl SHELL=/bin/bash > $G216/gcheckn.log 2>&1; echo "nptl rc=$?" > $G216/gcheckn.summary
