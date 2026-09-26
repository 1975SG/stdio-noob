#!/bin/sh
# glibc 2.2.5 (Guix's glibc-mesboot0) built by the installed i686 gcc 2.95.3 against the Mes 32-bit libc
# and the bootstrap Linux 4.14.67 headers, as Guix does.  Scratch-session paths; the steps are what matter.
# Inputs: glibc-2.2.5.tar.gz (sha256 checked against Guix's), glibc-boot-2.2.5.patch and
# glibc-bootstrap-system-2.2.5.patch (Guix's), linux-libre-headers-stripped-4.14.67-i686-linux.tar.xz (Guix's).
# usage: build_glibc225.sh <work dir> <gcc prefix (make install of stage 3)> <mes tree> <mes 32-bit libc dir> <patch> <make>
W=$1; GCCP=$2; MP=$3; MESLIB=$4; PATCH=$5; MAKE=$6; cd $W || exit 1
G=$GCCP/lib/gcc-lib/i686-pc-linux-gnu/2.95.3
# 1. finish the gcc install the way Guix's install2 does: libgcc.a and libgcc2.a from gcc/libgcc2.a
cp gcc-2.95.3/gcc/libgcc2.a $GCCP/lib/libgcc2.a; cp $GCCP/lib/libgcc2.a $G/libgcc.a
# 2. "mesboot-headers": Mes's include + the kernel headers (+ a stand-in linux/nfs.h, see below)
mkdir -p headers/include; cp -r $MP/include/. headers/; mkdir kh; tar xJf linux-libre-headers-stripped-4.14.67-i686-linux.tar.xz -C kh
cp -r kh/include/. headers/include/; chmod -R u+w headers
cp glibc225_linux_nfs.h headers/include/linux/nfs.h   # the stripped headers omit it; sunrpc's bootparam needs it
# 3. the gcc driver here does not turn LIBRARY_PATH into -L for ld: a wrapper adds them
mkdir -p bin; cat > bin/gcc <<EOS
#!/bin/sh
export PATH=$W/bin:\$PATH
LS=; IFS=:; for d in \$LIBRARY_PATH; do LS="\$LS -L\$d"; done; unset IFS
exec $GCCP/bin/gcc "\$@" \$LS
EOS
chmod +x bin/gcc; ln -sf $MAKE bin/make     # as/ld/ar/... wrappers (--32 / -m elf_i386) also live in bin/
export PATH=$W/bin:$PATH LC_ALL=C C_INCLUDE_PATH=$G/include:$MP/include:$MP/include/linux/x86 LIBRARY_PATH=$MESLIB:$G:$GCCP/lib
tar xzf glibc-2.2.5.tar.gz; cd glibc-2.2.5 || exit 1
$PATCH --force -p1 -i ../glibc-boot-2.2.5.patch; $PATCH --force -p1 -i ../glibc-bootstrap-system-2.2.5.patch
CPPF=" -D MES_BOOTSTRAP=1 -D BOOTSTRAP_GLIBC=1"
export CONFIG_SHELL=/bin/bash SHELL=/bin/bash CPP="gcc -E $CPPF" CC="gcc $CPPF -L $PWD"
./configure --disable-shared --enable-static --disable-sanity-checks --build=i686-unknown-linux-gnu \
  --host=i686-unknown-linux-gnu --with-headers=$W/headers/include --enable-static-nss --without-__thread \
  --without-cvs --without-gd --without-tls --prefix=$W/out
sed -i 's|INSTALL = scripts/|INSTALL = $(..)./scripts/|; s|^BASH = |SHELL = /bin/bash\nBASH = |' config.make
$MAKE SHELL=/bin/bash          # one job only: gcc 2.95.3 ICEs on massively parallel builds
$MAKE install SHELL=/bin/bash
