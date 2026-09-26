#!/bin/bash
# Guix's boot0 tools, second half: autoconf 2.69, automake 1.17, texinfo 6.8, expat 2.7.1 (static), Python 3.5.9; gcc 4.9.4 on glibc 2.16; bootstrapped tools only
JT=~/dev/stdio-noob; G6=$JT/g6; G8=$JT/g8; G9=$JT/g9; G10=$JT/g10; G216=$JT/g216; GL=$G216/glibc216
export PATH=$G6/mbbin6:$G9/out/m4/bin:$G9/out/perl/bin:$G9/out/bison/bin:$G9/out/flex/bin:$G8/only LC_ALL=C CONFIG_SHELL=$G8/only/bash SHELL=$G8/only/bash FORCE_UNSAFE_CONFIGURE=1
export C_INCLUDE_PATH=$GL/include CPLUS_INCLUDE_PATH=$GL/include LIBRARY_PATH=$GL/lib
[ -z "$(/usr/bin/ls /usr/include 2>/dev/null)" ] || { echo "/usr/include is visible: refusing"; exit 1; }
cd $G10; mkdir -p src out
unpack() { case $1 in *.xz) xz -dc $G10/$1 | tar --no-same-owner -x;; *) tar --no-same-owner -xzf $G10/$1;; esac; }
std() { n=$1; tb=$2; d=$3; shift 3; rm -rf src/$n; mkdir -p src/$n; cd src/$n; unpack $tb; cd $d || { echo "$n UNPACK-FAILED"; cd $G10; return 1; }
  [ -n "$PRE" ] && eval "$PRE"
  bash ./configure --prefix=$G10/out/$n "$@" > $G10/$n.configure.log 2>&1 || { echo "$n CONFIGURE-FAILED"; tail -4 $G10/$n.configure.log | cut -c1-160; cd $G10; return 1; }
  make -j8 > $G10/$n.make.log 2>&1 || { echo "$n MAKE-FAILED"; grep -m2 -B2 "\*\*\* \[" $G10/$n.make.log | cut -c1-200; cd $G10; return 1; }
  make install > $G10/$n.install.log 2>&1 || { echo "$n INSTALL-FAILED"; cd $G10; return 1; }
  echo "$n DONE"; cd $G10; }
std autoconf autoconf-2.69.tar.xz autoconf-2.69
export PATH=$G10/out/autoconf/bin:$PATH
std automake automake-1.17.tar.xz automake-1.17
export PATH=$G10/out/automake/bin:$PATH
PRE='patch --force -p1 -i $G10/texinfo-headings-single.patch > $G10/patch_texinfo.log 2>&1 || echo PATCH-PROBLEM' std texinfo texinfo-6.8.tar.xz texinfo-6.8 --disable-year2038
std expat expat-2.7.1.tar.xz expat-2.7.1 --disable-shared --disable-year2038
export PATH=$G10/out/texinfo/bin:$PATH
# Python 3.5.9 (python-boot0): bundled expat replaced by ours, ctypes/ossaudiodev off, no threads, no ensurepip
export C_INCLUDE_PATH=$C_INCLUDE_PATH:$G10/out/expat/include LIBRARY_PATH=$LIBRARY_PATH:$G10/out/expat/lib
rm -rf src/python; mkdir -p src/python; cd src/python; unpack Python-3.5.9.tar.xz; cd Python-3.5.9
rm -rf Modules/expat; sed -i 's|^#pyexpat.*|pyexpat pyexpat.c -lexpat|' Modules/Setup.dist
find Lib/distutils/command -name '*.exe' -delete; find Lib/ensurepip -name '*.whl' -delete
sed -i "s|/bin/sh|$G8/only/sh|" Lib/subprocess.py Lib/distutils/tests/test_spawn.py Lib/test/support/__init__.py Lib/test/test_subprocess.py
sed -i "s|extensions.append(ctypes)||; s|'linux', ||" setup.py
{ bash ./configure --prefix=$G10/out/python --without-ensurepip --without-threads > $G10/python.configure.log 2>&1 && make -j8 > $G10/python.make.log 2>&1 && make install > $G10/python.install.log 2>&1 && echo "python DONE"; } || { echo "python FAILED"; tail -5 $G10/python.make.log | cut -c1-200; }
rm -rf $G10/out/python/lib/python3.5/test
echo BUILD10-END
