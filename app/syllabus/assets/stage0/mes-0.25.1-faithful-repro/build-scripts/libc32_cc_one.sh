#!/bin/sh
o=$(echo $3 | sed -e 's,/,-,g' -e 's,[.]c$,,').o
~/dev/stdio-noob/gcc/g295/gcc/xgcc -B~/dev/stdio-noob/gcc/g295/gcc/ $2 -c -D HAVE_CONFIG_H=1 -I ~/dev/stdio-noob/gcc/libc32/inc -I ~/dev/stdio-noob/mes-0.25.1/include -I ~/dev/stdio-noob/mes-0.25.1/include/linux/x86 -static -nostdinc -nostdlib -fno-builtin -o $1/$o ~/dev/stdio-noob/gcc/libc32/mes32/$3 > $1/$o.log 2>&1 || echo "FAIL $3"
