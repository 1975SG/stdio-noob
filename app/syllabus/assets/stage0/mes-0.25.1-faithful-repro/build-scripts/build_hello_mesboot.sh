#!/bin/bash
# Scratch-session paths; run under build-scripts/run_hidden_headers.sh so the host /usr/include cannot leak.
. ~/dev/stdio-noob/g216/env.sh; cd ~/dev/stdio-noob/g216; rm -rf hello-2.10; tar --no-same-owner -xzf hello-2.10.tar.gz; cd hello-2.10
which gcc make | head -2
sh ./configure ac_cv_path_GREP=grep > ../hello_cfg.log 2>&1 || { echo CONFIG-FAILED; tail -5 ../hello_cfg.log; exit 1; }
make > ../hello_make.log 2>&1 || { echo MAKE-FAILED; tail -8 ../hello_make.log; exit 1; }
./hello; file hello | cut -c1-90
