#!/bin/bash
# ld-wrapper (Guix make-ld-wrapper "ld-wrapper"): binutils-final's ld wrapped by gnu/packages/ld-wrapper.in, run by guile-final and bash-final.
JT=~/dev/stdio-noob; G12=$JT/g12; G13=$JT/g13; O=$G13/out
GUILE=$O/guile/bin/guile; BASH=$G12/out/bash-final/bin/bash; LD=$G12/out/binutils-final/bin/ld
OUT=$O/ld-wrapper; rm -rf $OUT; mkdir -p $OUT/bin; ld=$OUT/bin/ld
[ -x $LD ] || { echo "no $LD"; exit 1; }
cp $G13/ld-wrapper.in $ld
sed -i -e "s#@SELF@#$ld#g" -e "s#@GUILE@#$GUILE#g" -e "s#@BASH@#$BASH#g" -e "s#@LD@#$LD#g" $ld
chmod 555 $ld
# compile-file with guile-final, as make-ld-wrapper does (output ld.go next to it)
env -i PATH=$O/guile/bin $GUILE -c "(use-modules (system base compile)) (compile-file \"$ld\" #:output-file \"$ld.go\")" && ls -la $ld $ld.go | awk '{print $5,$9}'
