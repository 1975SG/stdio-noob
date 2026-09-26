#!/bin/sh
# usage: build_gzip.sh <compiler> <outdir>   (Guix gzip-mesboot recipe)
TCC=$1; OUT=$2; rm -rf $OUT; mkdir -p $OUT; cp -r $(dirname $0)/gzip-1.2.4/. $OUT/; cd $OUT
sed -i 's/^char \*strlwr/char *strlwr_tcc_cannot_handle_dupe/' util.c
for x in bits crypt deflate getopt gzip inflate lzw trees unlzh unlzw unpack unzip util zip; do
  $TCC -c -D NO_UTIME=1 -D HAVE_UNISTD_H=1 -D __SIZEOF_LONG_LONG__=8 $x.c 2>&1 | grep -v "^DBG" | head -3
done
$TCC -o gzip bits.o crypt.o deflate.o getopt.o gzip.o inflate.o lzw.o trees.o unlzh.o unlzw.o unpack.o unzip.o util.o zip.o 2>&1 | head -5
ln -sf gzip gunzip; ls -la gzip 2>&1 | awk '{print $5,$9}'
