#!/bin/bash
# Master driver for the from-scratch fresh-root rebuild of glibc-final through the final tools.
# g8/g9/g10/g11 (binutils-cross-boot0, gcc-cross-boot0, m4/perl/bison/flex/headers, autotools/python, glibc-2.41-cross)
# are taken as GIVEN, unchanged, at their original location; only g12/g13/g14 are rebuilt here, fresh.
# Several vendored scripts do not propagate a build failure as their own exit status (they write a .rc file
# or print FAILED/PROBLEM and keep going); `check` inspects the real success markers, not just $?.
set -u
JT=~/dev/stdio-noob; JT2=$JT/rebuild_g12_g14; NS=$JT/g46/cxx/ns.sh; B=$JT2/build-scripts
LOG=$JT2/run_all.log; : > $LOG

step() { echo "=== $(date -Iseconds) START: $* ===" | tee -a $LOG; "$@" >> $LOG 2>&1; rc=$?; echo "=== $(date -Iseconds) END rc=$rc: $* ===" | tee -a $LOG; return $rc; }
fail() { echo "STOPPED: $*" | tee -a $LOG; exit 1; }
rc_is_zero() { local f=$1 n=$2; [ -f "$f" ] || fail "$n: no $f"; /usr/bin/grep -qE '(RC|rc)=0\b' "$f" || { cat "$f"; fail "$n: $f does not say rc=0"; }; echo "CHECK-OK: $n ($f)"; }

step $NS $B/build_static_bash_and_gettext_boot0.sh || fail "static-bash/gettext script itself errored"
/usr/bin/grep -q "static bash DONE" $LOG || fail "static bash did not report DONE"
/usr/bin/grep -q "gettext-boot0 DONE" $LOG || fail "gettext-boot0 did not report DONE"

step $NS $B/build_glibc_final.sh || fail "glibc-final script itself errored"
rc_is_zero $JT2/g12/make_final.rc "glibc-final make"

step $NS $B/install_glibc_final.sh || fail "glibc-final install script itself errored"
/usr/bin/grep -q "install rc=0" $LOG || fail "glibc-final install did not report rc=0"

step $NS $B/build_libstdcxx_zlib_binutils_final.sh || fail "libstdc++/zlib/binutils-final script itself errored"
for m in "libstdc++ DONE" "zlib DONE" "binutils-final (i686 triplet) DONE"; do /usr/bin/grep -q "$m" $LOG || fail "missing: $m"; done

step $B/make_bin_final.sh $JT2/g12 || fail "bin-final generation failed"

step $NS $B/build_gcc_final.sh || fail "gcc-final build script itself errored"
rc_is_zero $JT2/g12/gccfinal.rc "gcc-final make"

step $NS $B/install_gcc_final.sh || fail "gcc-final install script itself errored"
/usr/bin/grep -q "install rc=0" $LOG || fail "gcc-final install did not report rc=0"

step $NS $B/build_bash_final.sh || fail "bash-final script itself errored"
/usr/bin/grep -q "bash-final DONE" $LOG || fail "bash-final did not report DONE"

step $NS $B/build_guile_final.sh || fail "guile-final script itself errored (its own steps already exit 1 on failure)"

step $B/build_ld_wrapper.sh || fail "ld-wrapper build failed"

step $B/build_glibc_utf8_locales_final.sh || fail "glibc-utf8-locales-final script itself errored"
/usr/bin/grep -q "FAILED" $LOG && fail "a locale FAILED"

step $NS $B/build_final_tools.sh || fail "final tools (unstaged, all) script itself errored"
for pkg in coreutils grep xz; do /usr/bin/grep -q "^$pkg DONE" $LOG || fail "final tool $pkg (unstaged pass) did not report DONE"; done
step $NS $B/run_final_tools_staged.sh || fail "final tools staged build script itself errored"
for pkg in sed libsigsegv coreutils grep xz bzip2 gzip tar diffutils findutils patch file gawk zstd make; do
  /usr/bin/grep -q "^$pkg DONE" $LOG || fail "final tool $pkg did not report DONE"
done

echo "RUN-ALL-END $(date -Iseconds) — every stage's real success markers checked" | tee -a $LOG
