#!/bin/bash
# rebuild sed, grep, tar with a PATH containing ONLY the bootstrapped tools; installs into out/
JT=~/dev/stdio-noob; G6=$JT/g6; G216=$JT/g216
export PATH=$G6/only LC_ALL=C CONFIG_SHELL=$G6/only/bash SHELL=$G6/only/bash FORCE_UNSAFE_CONFIGURE=1
export C_INCLUDE_PATH=$G216/glibc216/include LIBRARY_PATH=$G216/glibc216/lib
[ -z "$(/usr/bin/ls /usr/include 2>/dev/null)" ] || { echo "/usr/include visible"; exit 1; }
cd $G6; mkdir -p src out
one() { n=$1; tb=$2; d=$3; shift 3; rm -rf src/$n; mkdir -p src/$n; cd src/$n
  case $tb in *.xz) xz -dc $G6/$tb | tar --no-same-owner -x;; *) tar --no-same-owner -xzf $G6/$tb;; esac
  cd $d && bash ./configure --prefix=$G6/out/$n "$@" > $G6/$n.3.configure.log 2>&1 && make > $G6/$n.3.make.log 2>&1 && make install > $G6/$n.3.install.log 2>&1 && echo "$n DONE" || echo "$n FAILED"; cd $G6; }
one sed sed-4.8.tar.gz sed-4.8
one grep grep-3.11.tar.xz grep-3.11 --disable-year2038
one tar tar-1.35.tar.xz tar-1.35 --disable-year2038
echo REBUILD-END
