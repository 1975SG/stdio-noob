#!/bin/bash
# gcc-final (Guix): gcc 14.3.0 native (i686-guix-linux-gnu), built by the wrapped gcc-boot0 against glibc-final, with libstdc++ (intermediate), zlib-final, binutils-final.
# A native gcc build bootstraps (stage1 by gcc-boot0, stage2 by stage1, stage3 by stage2, then `compare`).
JT=~/dev/stdio-noob; G8=$JT/g8; G12=$JT/g12; G9=$JT/g9; GF=$G12/glibc-final; LSX=$G12/out/libstdcxx; ZL=$G12/out/zlib; BF=$G12/out/binutils-final; OUT=$G12/out/gcc-final
. $G12/env12.sh $GF $G12/wrap-f
export PATH=$G12/bin-final:$PATH   # binutils-final first (prefixed and unprefixed): the stage compilers must not use the glibc-2.16 cross ld, which would dlopen a glibc-2.41 liblto_plugin.so
export CPLUS_INCLUDE_PATH=$LSX/include:$LSX/include/i686-guix-linux-gnu:$CPLUS_INCLUDE_PATH:$ZL/include C_INCLUDE_PATH=$C_INCLUDE_PATH:$ZL/include LIBRARY_PATH=$LIBRARY_PATH:$LSX/lib:$ZL/lib
[ -z "$(/usr/bin/ls /usr/include 2>/dev/null)" ] || { echo "/usr/include is visible: refusing"; exit 1; }
cd $G12; rm -rf gcc14src b_gcc; mkdir gcc14src; cd gcc14src; tar --no-same-owner -xJf $G8/gcc-14.3.0.tar.xz; cd gcc-14.3.0
for p in gcc-12-strmov-store-file-names gcc-5.0-libvtv-runpath; do patch --force -p1 -i $G8/$p.patch > /dev/null 2>&1 || echo "PATCH-PROBLEM $p"; done
tar --no-same-owner -xJf $G8/gmp-6.0.0a.tar.xz; tar --no-same-owner -xJf $G8/mpfr-4.2.2.tar.xz; tar --no-same-owner -xzf $G8/mpc-1.3.1.tar.gz; ln -s gmp-6.0.0 gmp; ln -s mpfr-4.2.2 mpfr; ln -s mpc-1.3.1 mpc
sed -i 's|\.\./lib64|../lib|' gcc/config/i386/t-linux64 gcc/config/i386/t-gnu64
# fix-build-with-external-libstdc++: keep the libstdc++ dir out of the include path when building libstdc++ itself
python3 - "$GF" "$OUT" "$LSX" <<'PY'
import re,sys,glob,os
libc,out,lsx=sys.argv[1:4]; libdir=out   # the template below appends /lib itself (Guix: libdir is the output prefix)
# pre-configure: hard-code the dynamic linker and the library/startfile paths of glibc-final into the compiler
for f in [p for p in glob.glob("gcc/config/**/*.h",recursive=True) if re.search(r"/(linux|gnu|sysv4)(64|-elf|-eabi)?\.h$",p)]:
    s=open(f).read()
    for _ in range(3): s=re.sub(r"(#define (?:GLIBC|GNU_USER)_DYNAMIC_LINKER[^\n]*)\\\n",r"\1",s)
    s=re.sub(r"#define ((?:GLIBC|GNU_USER)_DYNAMIC_LINKER[^ \t]*)[^\n]*",lambda m:'#define %s "%s/lib/ld-linux.so.2"'%(m.group(1),libc),s)
    open(f,"w").write(s)
for f in [p for p in glob.glob("gcc/config/gnu-user*.h")]:
    s=open(f).read()
    s=re.sub(r"#define GNU_USER_TARGET_LIB_SPEC ([^\n]*)",lambda m:'#define GNU_USER_TARGET_LIB_SPEC "-L%s/lib %%{!static:-rpath=%s/lib %%{!static-libgcc:-rpath=%s/lib -lgcc_s}} " %s'%(libc,libc,libdir,m.group(1)),s)
    s=re.sub(r"#define GNU_USER_TARGET_STARTFILE_SPEC[^\n]*",lambda m:'#define STANDARD_STARTFILE_PREFIX_1 "%s/lib/"\n#define STANDARD_STARTFILE_PREFIX_2 ""\n%s'%(libc,m.group(0)),s)
    open(f,"w").write(s)
s=open("fixincludes/fixincl.x").read(); s=re.sub(r"static char const sed_cmd_z\[\] =[^;]*;",'static char const sed_cmd_z[] = "sed";',s); open("fixincludes/fixincl.x","w").write(s)
s=open("libstdc++-v3/src/c++17/Makefile.in").read()
rest=":".join(p for p in os.environ.get("CPLUS_INCLUDE_PATH","").split(":") if not p.startswith(lsx))
s=s.replace("AM_CXXFLAGS = ","CPLUS_INCLUDE_PATH = %s\nAM_CXXFLAGS = "%rest,1); open("libstdc++-v3/src/c++17/Makefile.in","w").write(s)
PY
grep -c "$GF/lib/ld-linux.so.2" gcc/config/i386/linux.h gcc/config/linux.h 2>/dev/null | tr '\n' ' '; echo
# Guix's relax-gcc-14s-strictness: gmp 6.0's configure tests use implicit declarations, an error in gcc 14
mkdir -p $G12/relax; printf '#!/bin/bash\nexec %s/gcc "$@" -Wno-error=implicit-function-declaration\n' $G12/wrap-f > $G12/relax/gcc.sh; printf '#!/bin/bash\nexec "$@" -Wno-error=implicit-function-declaration\n' > $G12/relax/stage-gcc.sh; chmod +x $G12/relax/*.sh
export CC=$G12/relax/gcc.sh STAGE_CC_WRAPPER=$G12/relax/stage-gcc.sh
cd $G12; mkdir b_gcc; cd b_gcc
bash ../gcc14src/gcc-14.3.0/configure --prefix=$OUT --build=i686-guix-linux-gnu --host=i686-guix-linux-gnu --target=i686-guix-linux-gnu --enable-languages=c,c++,objc,obj-c++ --disable-multilib --with-system-zlib --with-zlib-include=$ZL/include --with-zlib-lib=$ZL/lib --disable-libstdcxx-pch --with-local-prefix=/no-gcc-local-prefix --with-gxx-include-dir=$OUT/include/c++ --with-native-system-header-dir=$GF/include --disable-plugin > $G12/gccfinal.configure.log 2>&1 || { echo "gcc-final CONFIGURE-FAILED"; tail -10 $G12/gccfinal.configure.log | cut -c1-200; exit 1; }
echo configured
XL="-L$LSX/lib -L$ZL/lib -Wl,-rpath=$ZL/lib"
make -j12 "LDFLAGS=-Wl,-rpath=$GF/lib -Wl,-dynamic-linker -Wl,$GF/lib/ld-linux.so.2 $XL" "BOOT_LDFLAGS=$XL" "BOOT_CFLAGS=-O2 -g0" > $G12/gccfinal.make.log 2>&1; echo "MAKE-RC=$?" > $G12/gccfinal.rc
