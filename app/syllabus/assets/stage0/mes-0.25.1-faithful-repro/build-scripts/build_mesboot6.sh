#!/bin/bash
# the mesboot6 packages (Guix's real recipe: bash-mesboot, sed-mesboot, xz-mesboot, tar-mesboot, grep-mesboot,
# coreutils-mesboot from commencement.scm), each into $G6/out/<name>; failures are recorded and do not stop the rest.
JT=~/dev/stdio-noob; G6=$JT/rebuild_g6_g8/g6; . $G6/env.sh
[ -z "$(ls /usr/include 2>/dev/null)" ] || { echo "/usr/include is visible: refusing"; exit 1; }
cd $G6; mkdir -p src out
pkg() { # pkg <name> <tarball> <dir> [configure args...]; env PRE, MAKEFLAGS_EXTRA via the caller
  n=$1; tb=$2; d=$3; shift 3; rm -rf src/$n; mkdir -p src/$n; cd src/$n
  case $tb in *.xz) xz -dc $G6/$tb | tar --no-same-owner -x;; *) tar --no-same-owner -xzf $G6/$tb;; esac
  cd $d || { echo "$n UNPACK-FAILED"; cd $G6; return 1; }
  [ -n "$PRE" ] && eval "$PRE"
  sh ./configure --prefix=$G6/out/$n "$@" > $G6/$n.configure.log 2>&1 || { echo "$n CONFIGURE-FAILED"; cd $G6; return 1; }
  make $MAKEFLAGS_EXTRA > $G6/$n.make.log 2>&1 || { echo "$n MAKE-FAILED"; cd $G6; return 1; }
  make install > $G6/$n.install.log 2>&1 || { echo "$n INSTALL-FAILED"; cd $G6; return 1; }
  echo "$n DONE"; cd $G6; }
# bash-mesboot: (mesboot-package "bash-mesboot" static-bash) = bash-minimal + static-package, 5.2 with its 37 upstream patches
PRE='for i in $(ls $G6/bash52-* | sort); do patch -p0 -s < $i || echo PATCH-PROBLEM $i; done' \
  MAKEFLAGS_EXTRA= LDFLAGS=-static pkg bash bash-5.2.tar.gz bash-5.2 "CFLAGS=-g -O2 -Wno-error=implicit-function-declaration" --without-bash-malloc --disable-readline --disable-history --disable-help-builtin --disable-progcomp --disable-net-redirections --disable-nls ac_cv_func_dlopen=no
# sed-mesboot: real 4.8 + coreutils-gnulib-tests.patch + the bug-36150 Makefile.in snippet (both from commencement.scm)
PRE='patch -p1 -s < $G6/coreutils-gnulib-tests.patch || echo PATCH-PROBLEM sed-gnulib; python3 $G6/sed_makefile_snippet.py' MAKEFLAGS_EXTRA= pkg sed sed-4.8.tar.gz sed-4.8
# xz-mesboot: real xz, parallel build disabled explicitly (Guix's own comment: "the build gets stuck when parallel build is enabled")
PRE= MAKEFLAGS_EXTRA=-j1 pkg xz xz-5.4.5.tar.gz xz-5.4.5
# tar-mesboot: real tar + --disable-year2038
PRE= MAKEFLAGS_EXTRA= pkg tar tar-1.35.tar.xz tar-1.35 --disable-year2038
# grep-mesboot: real grep, #:configure-flags STRIPPED (no --enable-perl-regexp: no PCRE yet)
PRE= MAKEFLAGS_EXTRA= pkg grep grep-3.11.tar.xz grep-3.11 --disable-year2038  # Guix strips configure-flags entirely here, relying on its build daemon's own --host= triplet to skip this probe; tar-mesboot already uses the same flag for the same reason
# coreutils-mesboot: real coreutils, no extra flags beyond the base recipe
PRE= MAKEFLAGS_EXTRA= pkg coreutils coreutils-9.1.tar.xz coreutils-9.1 --disable-year2038  # same reason as grep above
echo MESBOOT6-END
