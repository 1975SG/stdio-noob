#!/bin/sh
# make 3.80 built by tcc (Guix's gnu-make-mesboot0 recipe, adapted i686 -> x86_64).
# usage: build_make.sh <tcc wrapper script> <unpacked make-3.80 dir>
# Paths and the wrapper are scratch-session specific; the steps are what matter.
CC=$1; cd $2 || exit 1
sed -i 's/@LIBOBJS@/getloadavg.o/; s/@REMOTE@/stub/' build.sh.in      # Guix 'scripted-patch'
CC=$CC CPP="$CC -E" LD=$CC sh ./configure --build=x86_64-unknown-linux-gnu \
   --host=x86_64-unknown-linux-gnu --disable-nls
sed -i 's|^extern long int lseek.*|// &|' make.h                        # Guix 'configure-fixup'
cat >> config.h <<'EOT'

/* x86-64 fix-up (not in Guix's i686 recipe): Mes's headers do not declare
   these, and an implicit `int` return truncates the pointer. */
struct passwd;
extern char *strdup ();
extern char *ctime ();
extern struct passwd *getpwnam ();
EOT
sh ./build.sh
