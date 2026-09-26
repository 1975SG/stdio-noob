#!/bin/bash
JT=~/dev/stdio-noob; G6=$JT/g6; G8=$JT/g8; G9=$JT/g9; G10=$JT/g10; G11=$JT/g11
export TMPDIR=$G11/suidtmp
export PATH=$G11/logwrap:$G8/out14/bin:$G8/out/bin:$G6/mbbin6:$G10/out/python/bin:$G10/out/texinfo/bin:$G9/out/m4/bin:$G9/out/perl/bin:$G9/out/bison/bin:$G8/only LC_ALL=C SHELL=$G8/only/bash
unset C_INCLUDE_PATH CPLUS_INCLUDE_PATH LIBRARY_PATH
cd $G11/b; timeout 1500 make -k subdirs="$1" check run-built-tests=yes > $G11/multi_$1.log 2>&1; echo rc=$?
