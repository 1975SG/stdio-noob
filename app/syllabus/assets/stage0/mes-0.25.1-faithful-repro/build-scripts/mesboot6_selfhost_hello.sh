#!/bin/bash
# build hello-2.10 with a PATH containing ONLY the bootstrapped tools (no host /usr/bin, /bin)
JT=~/dev/stdio-noob; G6=$JT/g6; G216=$JT/g216
export PATH=$G6/only LC_ALL=C CONFIG_SHELL=$G6/only/bash SHELL=$G6/only/bash FORCE_UNSAFE_CONFIGURE=1
export C_INCLUDE_PATH=$G216/glibc216/include LIBRARY_PATH=$G216/glibc216/lib
[ -z "$(/usr/bin/ls /usr/include 2>/dev/null)" ] || { echo "/usr/include visible"; exit 1; }
cd $G6; rm -rf sh_hello; mkdir sh_hello; cd sh_hello
tar -xzf $G216/hello-2.10.tar.gz || { echo UNTAR-FAILED; exit 1; }; cd hello-2.10
bash ./configure ac_cv_path_GREP=grep > ../cfg.log 2>&1 || { echo CONFIGURE-FAILED; grep -n "not found\|No such\|error" ../cfg.log | head -8 | cut -c1-180; exit 1; }
make > ../make.log 2>&1 || { echo MAKE-FAILED; grep -n "not found\|No such\|Error" ../make.log | head -6 | cut -c1-180; exit 1; }
./hello; echo "built with only bootstrapped tools: OK"; file hello | cut -c1-80
