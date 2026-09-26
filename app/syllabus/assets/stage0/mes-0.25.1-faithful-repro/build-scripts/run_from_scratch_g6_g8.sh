#!/bin/bash
# Master driver for the from-scratch fresh-root reconstruction of g6/g7/g8: mesboot6, boot0tools,
# binutils-cross-boot0, gcc-cross-boot0, with a PATH farm assembled purely from real bootstrapped outputs
# (make_only_farm.sh) instead of the original, undocumented g6/out_host host-gcc-built scaffolding found
# in an earlier pass. g49/g216/gm/rb (everything before mesboot6) are taken as given, unchanged, at their original
# location. Edit JT2= to a fresh root before running; it is written for one specific run, not parameterized.
set -u
JT=~/dev/stdio-noob; JT2=$JT/rebuild_g6_g8; NS=$JT/g46/cxx/ns.sh
R=/home/SG/dev/stdio-noob/app/syllabus/assets/stage0/mes-0.25.1-faithful-repro; B=$R/build-scripts
LOG=$JT2/run_all.log; : > $LOG
step() { echo "=== $(date -Iseconds) START: $* ===" | tee -a $LOG; "$@" >> $LOG 2>&1; rc=$?; echo "=== $(date -Iseconds) END rc=$rc: $* ===" | tee -a $LOG; return $rc; }
fail() { echo "STOPPED: $*" | tee -a $LOG; exit 1; }

mkdir -p $JT2/g6 $JT2/g7 $JT2/g8
cp $JT/g6/bash-5.2.tar.gz $JT/g6/bash52-* $JT/g6/xz-5.4.5.tar.gz $JT/g6/tar-1.35.tar.xz $JT/g6/grep-3.11.tar.xz $JT/g6/coreutils-9.1.tar.xz $JT2/g6/ 2>/dev/null
curl -sL --max-time 300 -o $JT2/g6/sed-4.8.tar.gz https://ftp.gnu.org/gnu/sed/sed-4.8.tar.gz
V=$R/tests/verify_guix_hash.py
declare -A H=(
 [g6/sed-4.8.tar.gz]=0alqagh0nliymz23kfjg6g9w3cr086k0sfni56gi8fhzqwa3xksk
 [g6/bash-5.2.tar.gz]=1yrjmf0mqg2q8pqphjlark0mcmgf88b0acq7bqf4gx3zvxkc2fd1
 [g6/xz-5.4.5.tar.gz]=1mmpwl4kg1vs6n653gkaldyn43dpbjh8gpk7sk0gps5f6jwr0p0k
 [g6/tar-1.35.tar.xz]=05nw7q7sazkana11hnf3f77lmybw1j9j6lsk93bsxirf6hvzyqjd
 [g6/grep-3.11.tar.xz]=1avf4x8skxbqrjp5j2qr9sp5vlf8jkw2i5bdn51fl3cxx3fsxchx
 [g6/coreutils-9.1.tar.xz]=08q4b0w7mwfxbqjs712l6wrwl2ijs7k50kssgbryg9wbsw8g98b1
 [g7/make-4.4.1.tar.gz]=1cwgcmwdn7gqn5da2ia91gkyiqs9birr10sy5ykpkaxzcwfzn5nx
 [g7/diffutils-3.12.tar.xz]=1zbxf8vv7z18ypddwqgzj51n426k959fiv4wxbyl34b0r2gpz2vw
 [g7/findutils-4.10.0.tar.xz]=1xd4y24qfsdfp3ndz7d5j49lkhbhpzgr13wrvsmx4izjgyvf11qk
 [g7/bzip2-1.0.8.tar.gz]=0s92986cv0p692icqlw1j42y9nld8zd83qwhzbqd61p1dqbh6nmb
 [g7/file-5.46.tar.gz]=1230v1sks2p4ijc7x68iy2z9sqfm17v5lmfwbq9l7ib0qp3pgk69
 [g7/gawk-5.3.0.tar.xz]=02x97iyl9v84as4rkdrrkfk2j4vy4r3hpp3rkp3gh3qxs79id76a
 [g7/patch-2.7.6.tar.xz]=1zfqy4rdcy279vwn2z1kbv19dcfw25d2aqy9nzvdkq5bjzd0nqdc
 [g7/sed-4.9.tar.gz]=0bi808vfkg3szmpy9g5wc7jnn2yk6djiz412d30km9rky0c8liyi
 [g8/binutils-2.44.tar.bz2]=0fnwaasfglbphqzvz5n25js9gl695p7pjbmb1z81g8gsc6k90qzn
 [g8/gcc-14.3.0.tar.xz]=0fna78ly417g69fdm4i5f3ms96g8xzzjza8gwp41lqr5fqlpgp70
 [g8/gmp-6.0.0a.tar.xz]=0r5pp27cy7ch3dg5v0rsny8bib1zfvrza6027g2mp5f6v8pd6mli
 [g8/mpfr-4.2.2.tar.xz]=00ffqs0sssb81bx007d0k2wc7hsyxy4yiqil6xbais7p7qwa0yxn
 [g8/mpc-1.3.1.tar.gz]=1f2rqz0hdrrhx4y1i5f8pv6yv08a876k1dqcm9s2p26gyn928r5b
)
for f in "${!H[@]}"; do
  p=$JT2/$f; [ -f "$p" ] || fail "source missing: $f"
  python3 $V "$p" "${H[$f]}" || fail "hash mismatch: $f"
done
cp $B/guix-patches/coreutils-gnulib-tests.patch $B/sed_makefile_snippet.py $B/make_only_farm.sh $JT2/g6/
$B/make_mbbin6_wrapper.sh $JT2/g6/mbbin6 $JT/g49/out $JT/g216/glibc216
cat > $JT2/g6/env.sh <<ENVEOF
export LC_ALL=C PATH=$JT2/g6/mbbin6:$JT/g49/bumbin:$JT/g216/tools:\$PATH CONFIG_SHELL=/bin/bash FORCE_UNSAFE_CONFIGURE=1
export C_INCLUDE_PATH=$JT/g216/glibc216/include CPLUS_INCLUDE_PATH=$JT/g216/glibc216/include LIBRARY_PATH=$JT/g216/glibc216/lib
ENVEOF
sed "s#JT=~/dev/stdio-noob; G6=\$JT/g6#JT=~/dev/stdio-noob; G6=$JT2/g6#" $B/build_mesboot6.sh > $JT2/g6/build6.sh
chmod +x $JT2/g6/build6.sh
step $NS $JT2/g6/build6.sh || fail "mesboot6 script itself errored"
for pkg in bash sed xz tar grep coreutils; do /usr/bin/grep -q "^$pkg DONE" $LOG || fail "mesboot6 $pkg did not report DONE"; done

step $JT2/g6/make_only_farm.sh $JT2/g6/only $JT2/g6 || fail "only-farm generation (g6 stage) failed"

cp $JT/g7/*.tar.gz $JT/g7/*.tar.xz $JT2/g7/ 2>/dev/null
sed -e "s#G6=\$JT/g6#G6=$JT2/g6#" -e "s#G7=\$JT/g7#G7=$JT2/g7#" $R/build-scripts/build_boot0_tools.sh > $JT2/build_boot0_tools.sh
chmod +x $JT2/build_boot0_tools.sh
step $NS $JT2/build_boot0_tools.sh || fail "boot0tools script itself errored"
/usr/bin/grep -q "BOOT0TOOLS-END" $LOG || fail "boot0tools did not finish"

step $JT2/g6/make_only_farm.sh $JT2/g8/only $JT2/g6 $JT2/g7 || fail "only-farm generation (g7 stage) failed"

cp $JT/g8/binutils-2.44.tar.bz2 $JT/g8/binutils-2.41-fix-cross.patch $JT/g8/binutils-loongson-workaround.patch $JT2/g8/ 2>/dev/null
sed -e "s#G8=\$JT/g8#G8=$JT2/g8#" $R/build-scripts/build_binutils244.sh | sed -e "s#PATH=\$G8/only#PATH=$JT2/g8/only#" -e "s#CONFIG_SHELL=\$G8/only/bash SHELL=\$G8/only/bash#CONFIG_SHELL=$JT2/g8/only/bash SHELL=$JT2/g8/only/bash#" > $JT2/build_binutils244.sh
chmod +x $JT2/build_binutils244.sh
step $NS $JT2/build_binutils244.sh || fail "binutils244 script itself errored"
/usr/bin/grep -q "BINUTILS244-DONE" $LOG || fail "binutils244 did not finish"

cp $JT/g8/gcc-14.3.0.tar.xz $JT/g8/gmp-6.0.0a.tar.xz $JT/g8/mpfr-4.2.2.tar.xz $JT/g8/mpc-1.3.1.tar.gz $JT/g8/gcc-12-strmov-store-file-names.patch $JT/g8/gcc-5.0-libvtv-runpath.patch $JT2/g8/ 2>/dev/null
sed -e "s#G8=\$JT/g8#G8=$JT2/g8#" -e "s#G6=\$JT/g6#G6=$JT2/g6#" $R/build-scripts/build_gcc14_cross_boot0.sh > $JT2/build_gcc14_cross_boot0.sh
chmod +x $JT2/build_gcc14_cross_boot0.sh
step $NS $JT2/build_gcc14_cross_boot0.sh || fail "gcc14-cross-boot0 script itself errored"
/usr/bin/grep -qE 'MAKE-RC=0' $JT2/g8/make14.rc || fail "gcc14-cross-boot0 make did not report MAKE-RC=0"

sed -e "s#G8=\$JT/g8#G8=$JT2/g8#" -e "s#G6=\$JT/g6#G6=$JT2/g6#" $R/build-scripts/install_gcc14_cross_boot0.sh > $JT2/install_gcc14_cross_boot0.sh
chmod +x $JT2/install_gcc14_cross_boot0.sh
step $NS $JT2/install_gcc14_cross_boot0.sh || fail "gcc14-cross-boot0 install script itself errored"
/usr/bin/grep -q "install rc=0" $LOG || fail "gcc14-cross-boot0 install did not report rc=0"

echo "RUN-ALL-END $(date -Iseconds) — g6/g7/g8 rebuilt from a purely bootstrapped only-farm, no host-gcc glue" | tee -a $LOG
