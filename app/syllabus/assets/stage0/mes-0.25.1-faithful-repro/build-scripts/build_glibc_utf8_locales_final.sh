#!/bin/bash
# glibc-utf8-locales-final (Guix make-glibc-utf8-locales): the default UTF-8 locales, localedef of glibc-final with `gzip` on PATH.
JT=~/dev/stdio-noob; G8=$JT/g8; G12=$JT/g12; G13=$JT/g13; GF=$G12/glibc-final
OUT=$G13/out/glibc-utf8-locales; LD=$OUT/lib/locale/2.41
rm -rf $OUT; mkdir -p $LD
export PATH=$GF/bin:$G8/only LC_ALL=C   # localedef needs gzip (charmaps are .gz): glibc-final's bin + the bootstrap gzip
for locale in C de_DE el_GR en_US fr_FR tr_TR; do
  localedef --no-archive --prefix $LD -i $locale -f UTF-8 $LD/$locale.utf8 || echo "FAILED $locale"
  ln -s $locale.utf8 $LD/$locale.UTF-8
done
ls $LD
