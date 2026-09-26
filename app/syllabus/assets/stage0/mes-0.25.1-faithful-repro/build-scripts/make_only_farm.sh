#!/bin/bash
# make_only_farm.sh: build the "only" PATH farm used exclusively (no $PATH fallback) by
# build_boot0_tools.sh/build_binutils244.sh/build_gcc14_cross_boot0.sh, purely from real bootstrapped
# tool outputs -- no host-gcc-built driver tools (unlike the original g6/only, which used g6/out_host,
# a host-gcc-built bash/coreutils/grep/sed/tar/xz never vendored.)
# usage: make_only_farm.sh <output dir> <mesboot6 g6 root> [<g7 root> [<g8 root>]]
#   with only <g6 root>: builds the mesboot6-stage-only farm (used to build g7/boot0tools)
#   with <g7 root> too:  adds g7's own new outputs (used to build g8/binutils244+gcc14cross)
#   with <g8 root> too:  adds g8's own new outputs (matches the historical g8/only)
OUT=$1; G6=$2; G7=$3; G8=$4
JT=~/dev/stdio-noob
rm -rf $OUT; mkdir -p $OUT
link() { [ -e "$2" ] && ln -sf "$2" "$OUT/$1" || echo "make_only_farm.sh: MISSING $1 -> $2 (not linked)"; }
relink() { ln -sf "$2" "$OUT/$1"; }  # $2 is a bare name, resolved WITHIN $OUT (e.g. gunzip -> gzip)

# the compiler (gcc-mesboot1, wraps g49's gcc 4.9.4 with a dynamic-linking wrapper) and its binutils/awk,
# from before mesboot6 (unchanged, "given")
link cc  $G6/mbbin6/gcc
link gcc $G6/mbbin6/gcc
link cpp $G6/mbbin6/cpp
link g++ $G6/mbbin6/g++
for t in ar as ld make nm objcopy objdump ranlib strip; do link $t $JT/g49/bumbin/$t; done
link awk  $JT/g216/tools/awk
link gawk $JT/g216/tools/gawk
# early bootstrap infrastructure (gzip, patch) built by the much earlier tcc-mes/gcc-2.95/4.6.4 lineage;
# used only to unpack/patch tarballs, not part of any documented "built by X" provenance claim, same category
# as the system's own tar/coreutils/bash used to run `./configure`/`make` outside this farm ($PATH suffix)
link gzip  $JT/gm/out_gzip_new/gzip
relink gunzip gzip
relink zcat gzip
link patch $JT/rb/patch-2.5.9/patch

# mesboot6's own outputs (this reconstruction): bash, sed, xz+its aliases, tar, grep+egrep/fgrep, all of coreutils
link bash $G6/out/bash/bin/bash
relink sh bash
for t in $(ls $G6/out/xz/bin 2>/dev/null); do link $t $G6/out/xz/bin/$t; done
link sed  $G6/out/sed/bin/sed
link tar  $G6/out/tar/bin/tar
link grep $G6/out/grep/bin/grep
link egrep $G6/out/grep/bin/egrep
link fgrep $G6/out/grep/bin/fgrep
for t in $(ls $G6/out/coreutils/bin 2>/dev/null); do link $t $G6/out/coreutils/bin/$t; done

if [ -n "$G7" ]; then
  # g7 = boot0tools: make, bzip2, diffutils, findutils, file, gawk, patch, sed all rebuilt with
  # only the bootstrapped tools above; replace the earlier (mesboot6/earlier) entries with g7's own where present
  for pkg in make bzip2 diffutils findutils file gawk patch sed; do
    [ -d $G7/out/$pkg/bin ] || continue
    for t in $(ls $G7/out/$pkg/bin 2>/dev/null); do link $t $G7/out/$pkg/bin/$t; done
  done
fi
if [ -n "$G8" ]; then
  # g8's own new outputs (binutils 2.44 cross-boot0): not usually added to `only` itself (build_binutils244.sh
  # uses `only` to BUILD them), but supported for completeness / a g8-stage-onward-only farm
  [ -d $G8/out/bin ] && for t in $(ls $G8/out/bin 2>/dev/null); do link $t $G8/out/bin/$t; done
fi
echo "only farm: $(ls $OUT | wc -l) entries in $OUT"
