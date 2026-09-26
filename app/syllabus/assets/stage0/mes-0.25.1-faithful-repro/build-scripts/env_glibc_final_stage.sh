# environment of the "boot1/boot2" stage: the cross gcc 14 (gcc-cross-boot0) wrapped to use a given glibc, cross binutils 2.44, bootstrapped tools
# usage: . env12.sh <glibc prefix> <wrapper dir>
JT=~/dev/stdio-noob; G6=$JT/g6; G8=$JT/g8; G9=$JT/g9; G10=$JT/g10; G11=$JT/g11
GLX=$1; WR=$2; KH=$G9/out/linux-headers/include
mkdir -p $WR; for p in gcc cc g++ cpp; do case $p in cc) real=gcc;; *) real=$p;; esac
  printf '#!/bin/bash\n# gcc-cross-boot0 always uses ITS binutils (glibc-2.16 ld + matching lto plugin), whatever the caller has on PATH\nexec env PATH=%s/out/bin:$PATH %s/out14/bin/i686-guix-linux-gnu-%s -B%s/lib -L%s/lib -Wl,-dynamic-linker -Wl,%s/lib/ld-linux.so.2 -Wl,-rpath=%s/lib "$@"\n' $G8 $G8 $real $GLX $GLX $GLX $GLX > $WR/$p; chmod +x $WR/$p; done
export PATH=$WR:$G8/out/bin:$G10/out/python/bin:$G10/out/texinfo/bin:$G10/out/autoconf/bin:$G10/out/automake/bin:$G9/out/m4/bin:$G9/out/perl/bin:$G9/out/bison/bin:$G9/out/flex/bin:$G8/only
export LC_ALL=C CONFIG_SHELL=$G8/only/bash SHELL=$G8/only/bash FORCE_UNSAFE_CONFIGURE=1
export C_INCLUDE_PATH=$GLX/include:$KH CPLUS_INCLUDE_PATH=$GLX/include:$KH LIBRARY_PATH=$GLX/lib
