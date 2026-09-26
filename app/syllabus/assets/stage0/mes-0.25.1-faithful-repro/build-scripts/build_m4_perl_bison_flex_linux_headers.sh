#!/bin/bash
# Guix's boot0 build tools: m4, perl, bison, flex, and the linux-libre headers; gcc 4.9.4 on glibc 2.16; PATH = bootstrapped tools only
JT=~/dev/stdio-noob; G6=$JT/g6; G8=$JT/g8; G9=$JT/g9; G216=$JT/g216; GL=$G216/glibc216
export PATH=$G6/mbbin6:$G8/only LC_ALL=C CONFIG_SHELL=$G8/only/bash SHELL=$G8/only/bash FORCE_UNSAFE_CONFIGURE=1
export C_INCLUDE_PATH=$GL/include CPLUS_INCLUDE_PATH=$GL/include LIBRARY_PATH=$GL/lib
[ -z "$(/usr/bin/ls /usr/include 2>/dev/null)" ] || { echo "/usr/include is visible: refusing"; exit 1; }
cd $G9; mkdir -p src out
unpack() { case $1 in *.xz) xz -dc $G9/$1 | tar --no-same-owner -x;; *) tar --no-same-owner -xzf $G9/$1;; esac; }
std() { n=$1; tb=$2; d=$3; shift 3; rm -rf src/$n; mkdir -p src/$n; cd src/$n; unpack $tb; cd $d || { echo "$n UNPACK-FAILED"; cd $G9; return 1; }
  bash ./configure --prefix=$G9/out/$n "$@" > $G9/$n.configure.log 2>&1 || { echo "$n CONFIGURE-FAILED"; cd $G9; return 1; }
  make -j8 > $G9/$n.make.log 2>&1 || { echo "$n MAKE-FAILED"; cd $G9; return 1; }
  make install > $G9/$n.install.log 2>&1 || { echo "$n INSTALL-FAILED"; cd $G9; return 1; }
  echo "$n DONE"; cd $G9; }
std m4 m4-1.4.19.tar.xz m4-1.4.19 --disable-year2038
export PATH=$G9/out/m4/bin:$PATH
# perl 5.36.0: three Guix patches, pwd and gnu89 fixes, no threads (as perl-boot0), shared libperl
rm -rf src/perl; mkdir -p src/perl; cd src/perl; unpack perl-5.36.0.tar.gz; cd perl-5.36.0
for p in perl-no-sys-dirs perl-autosplit-default-time perl-reproducible-build-date; do patch --force -p1 -i $G9/$p.patch > $G9/patch_$p.log 2>&1 || echo "PATCH-PROBLEM $p"; done
sed -i "s|'/bin/pwd'|'$(command -v pwd)'|" dist/PathTools/Cwd.pm; sed -i 's/-std=c89/-std=gnu89/' cflags.SH
sed -i 's/^libswanted=\(.*\)pthread/libswanted=\1/' Configure
sh ./Configure -de -Dcc=gcc -Dprefix=$G9/out/perl -Dman1dir=none -Dman3dir=none -Uinstallusrbinperl -Dinstallstyle=lib/perl5 -Duseshrplib -Dlocincpth=$GL/include -Dloclibpth=$GL/lib > $G9/perl.configure.log 2>&1 || { echo "perl CONFIGURE-FAILED"; tail -5 $G9/perl.configure.log | cut -c1-160; }
if [ -f config.sh ]; then make -j8 > $G9/perl.make.log 2>&1 && make install > $G9/perl.install.log 2>&1 && echo "perl DONE" || echo "perl MAKE/INSTALL-FAILED"; fi
cd $G9; export PATH=$G9/out/perl/bin:$PATH
MAKE_EXTRA=(ARFLAGS=crD RANLIB=ranlib); 
rm -rf src/bison; mkdir -p src/bison; cd src/bison; unpack bison-3.8.2.tar.xz; cd bison-3.8.2
{ bash ./configure --prefix=$G9/out/bison --disable-year2038 > $G9/bison.configure.log 2>&1 && make -j8 "${MAKE_EXTRA[@]}" > $G9/bison.make.log 2>&1 && make install > $G9/bison.install.log 2>&1 && echo "bison DONE"; } || echo "bison FAILED"
cd $G9; export PATH=$G9/out/bison/bin:$PATH
std flex flex-2.6.4.tar.gz flex-2.6.4 ac_cv_func_malloc_0_nonnull=yes ac_cv_func_realloc_0_nonnull=yes
export PATH=$G9/out/flex/bin:$PATH
# linux-libre headers 6.12.17-gnu
rm -rf src/linux; mkdir -p src/linux; cd src/linux; unpack linux-libre-6.12.17-gnu.tar.xz; cd linux-6.12.17 2>/dev/null || cd $(ls -d */ | head -1)
sed -i 's/echo 5\.1\.0/echo 4.8.4/; s/echo 2\.25\.0/echo 2.20.1/' scripts/min-tool-version.sh
{ ARCH=x86 make i386_defconfig > $G9/linux.defconfig.log 2>&1 && ARCH=x86 make mrproper headers > $G9/linux.make.log 2>&1 && echo "linux headers built"; } || echo "linux FAILED"
if [ -d usr/include ]; then rm -rf $G9/out/linux-headers; mkdir -p $G9/out/linux-headers/include; (cd usr/include && find . -name '*.h' | while read f; do mkdir -p $G9/out/linux-headers/include/$(dirname $f); cp $f $G9/out/linux-headers/include/$f; done); echo "linux headers installed: $(find $G9/out/linux-headers/include -name '*.h' | wc -l) files"; fi
echo BUILD9-END
