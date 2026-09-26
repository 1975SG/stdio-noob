#!/bin/bash
# Guix's order after coreutils/grep/xz: sed is built with the final coreutils+grep+xz (boot6), everything else also with sed-final on PATH.
JT=~/dev/stdio-noob; G14=$JT/g14; O=$G14/out; N=$JT/g46/cxx/ns.sh
FINAL_PATH="$O/coreutils/bin:$O/grep/bin:$O/xz/bin" $N $G14/build14.sh sed
FINAL_PATH="$O/sed/bin:$O/coreutils/bin:$O/grep/bin:$O/xz/bin" $N $G14/build14.sh libsigsegv bzip2 gzip tar diffutils findutils patch file gawk zstd make
