#!/bin/bash
# the "boot0" tool set (Guix): make 4.4.1, bzip2, diffutils, findutils, file, gawk, patch, sed; PATH = ONLY the bootstrapped tools
JT=~/dev/stdio-noob; G6=$JT/g6; G7=$JT/g7; G216=$JT/g216
export PATH=$G6/only LC_ALL=C CONFIG_SHELL=$G6/only/bash SHELL=$G6/only/bash FORCE_UNSAFE_CONFIGURE=1
export C_INCLUDE_PATH=$G216/glibc216/include LIBRARY_PATH=$G216/glibc216/lib
[ -z "$(/usr/bin/ls /usr/include 2>/dev/null)" ] || { echo "/usr/include is visible: refusing"; exit 1; }
cd $G7; mkdir -p src out
unpack() { case $1 in *.xz) xz -dc $G7/$1 | tar --no-same-owner -x;; *) tar --no-same-owner -xzf $G7/$1;; esac; }
MAKEARGS=()
std() { # std <name> <tarball> <dir> [configure args]: configure, make, make install
  n=$1; tb=$2; d=$3; shift 3; rm -rf src/$n; mkdir -p src/$n; cd src/$n; unpack $tb; cd $d || { echo "$n UNPACK-FAILED"; cd $G7; return 1; }
  bash ./configure --prefix=$G7/out/$n "$@" > $G7/$n.configure.log 2>&1 || { echo "$n CONFIGURE-FAILED"; cd $G7; return 1; }
  make "${MAKEARGS[@]}" > $G7/$n.make.log 2>&1 || { echo "$n MAKE-FAILED"; cd $G7; return 1; }
  make install > $G7/$n.install.log 2>&1 || { echo "$n INSTALL-FAILED"; cd $G7; return 1; }
  echo "$n DONE"; cd $G7; }
# make 4.4.1: no make yet that is 4.x, so build.sh; install the binary
rm -rf src/make; mkdir -p src/make; cd src/make; unpack make-4.4.1.tar.gz; cd make-4.4.1
{ bash ./configure --prefix=$G7/out/make --disable-dependency-tracking > $G7/make.configure.log 2>&1 && bash ./build.sh > $G7/make.make.log 2>&1 && mkdir -p $G7/out/make/bin && cp make $G7/out/make/bin/ && echo "make DONE"; } || echo "make FAILED"
cd $G7
std diffutils diffutils-3.12.tar.xz diffutils-3.12 --disable-year2038
PATH=$PATH:$G7/out/diffutils/bin
std findutils findutils-4.10.0.tar.xz findutils-4.10.0 --disable-year2038
# bzip2 1.0.8: plain Makefile
rm -rf src/bzip2; mkdir -p src/bzip2; cd src/bzip2; unpack bzip2-1.0.8.tar.gz; cd bzip2-1.0.8
{ make CC=gcc AR=ar RANLIB=ranlib > $G7/bzip2.make.log 2>&1 && make install PREFIX=$G7/out/bzip2 > $G7/bzip2.install.log 2>&1 && echo "bzip2 DONE"; } || echo "bzip2 FAILED"
cd $G7
PATH=$PATH:$G7/out/findutils/bin
MAKEARGS=(CFLAGS='-g -O2 -std=c11') std file file-5.46.tar.gz file-5.46 --disable-bzlib
std gawk gawk-5.3.0.tar.xz gawk-5.3.0
std patch patch-2.7.6.tar.xz patch-2.7.6
std sed sed-4.9.tar.gz sed-4.9
echo BOOT0TOOLS-END
