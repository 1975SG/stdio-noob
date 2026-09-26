#!/bin/bash
# ns_multi.sh <cmd...>: like ns.sh (hides /usr/include) but the user namespace maps inner 0 -> my own uid (so I own my files
# as root) AND inner 1..65535 -> my subuid range, so chown/setuid to other uids works (glibc's setuid-style tests).
EMPTY=~/dev/stdio-noob/emptyinc
unshare -Um sleep 100000 & P=$!
sleep 0.5
newuidmap $P 0 $(id -u) 1 1 589824 65535 && newgidmap $P 0 $(id -g) 1 1 589824 65535 || { kill $P; exit 99; }
nsenter -U -m -t $P --setuid 0 --setgid 0 -- sh -c 'mount --bind '$EMPTY' /usr/include; mount --bind '$EMPTY' /usr/local/include 2>/dev/null; exec setpriv --groups 100,101 "$@"' sh "$@"
rc=$?; kill $P 2>/dev/null; exit $rc
