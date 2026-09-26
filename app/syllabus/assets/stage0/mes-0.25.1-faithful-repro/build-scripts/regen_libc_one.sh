#!/bin/sh
JT=~/dev/stdio-noob; MP=$JT/mes-0.25.1; NEW=$JT/mes25-build/libcbuild-fixed
export MES_ARENA=30000000 MES_MAX_ARENA=30000000 MES_STACK=15000000
b=$(basename $1 .c); cd $NEW
$JT/mes25-build/wrapperbin/mescc -S -o $b.s -D HAVE_CONFIG_H=1 -I $MP/include -I $MP/include/linux/x86_64 $MP/$1 > $b.compile.log 2>&1 || echo "FAIL $1"
