#!/bin/bash
JT=~/dev/stdio-noob; G6=$JT/g6; G8=$JT/g8; G9=$JT/g9; G10=$JT/g10; G12=$JT/g12
export PATH=$G12/out/gettext/bin:$G8/out14/bin:$G8/out/bin:$G6/mbbin6:$G10/out/python/bin:$G10/out/texinfo/bin:$G9/out/m4/bin:$G9/out/perl/bin:$G9/out/bison/bin:$G8/only LC_ALL=C SHELL=$G8/only/bash
unset C_INCLUDE_PATH CPLUS_INCLUDE_PATH LIBRARY_PATH
cd $G12/gf/b; make install > $G12/install_final.log 2>&1; echo "install rc=$?"
