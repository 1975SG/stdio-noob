#!/bin/bash
# perl's own core test suite against the just-built perl
JT=~/dev/stdio-noob; G6=$JT/g6; G8=$JT/g8; G9=$JT/g9; G216=$JT/g216; GL=$G216/glibc216
export PATH=$G6/mbbin6:$G9/out/m4/bin:$G8/only LC_ALL=C CONFIG_SHELL=$G8/only/bash SHELL=$G8/only/bash
export C_INCLUDE_PATH=$GL/include LIBRARY_PATH=$GL/lib
cd $G9/src/perl/perl-5.36.0; export TEST_JOBS=8
timeout 3000 make test_harness > $G9/perltest.log 2>&1; echo "TEST-RC=$?" > $G9/perltest.rc
