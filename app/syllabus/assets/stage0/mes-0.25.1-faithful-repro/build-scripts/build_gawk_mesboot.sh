#!/bin/bash
# Scratch-session paths; run under build-scripts/run_hidden_headers.sh so the host /usr/include cannot leak.
. ~/dev/stdio-noob/g216/env.sh; cd ~/dev/stdio-noob/g216; rm -rf gawk-3.1.8; tar --no-same-owner -xzf gawk-3.1.8.tar.gz; cd gawk-3.1.8
sh ./configure ac_cv_func_connect=no > ../gawk_cfg.log 2>&1 || { echo CONFIG-FAILED; tail -5 ../gawk_cfg.log; exit 1; }
make gawk > ../gawk_make.log 2>&1 || { echo MAKE-FAILED; grep -m3 -B4 "\*\*\*" ../gawk_make.log | cut -c1-200; exit 1; }
./gawk --version | head -1; file gawk | cut -c1-80
