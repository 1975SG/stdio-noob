#!/bin/bash
# run_hidden_headers.sh <cmd...> : run a command with the host's /usr/include and /usr/local/include replaced by an empty
# directory (unprivileged user + mount namespace, `unshare -rm`), so nothing in the host's headers or host g++ can leak into a
# bootstrap step: the equivalent of Guix's build sandbox, which has no /usr/include.  Nothing outside the namespace
# changes.  Note: tar must be run with --no-same-owner inside it (uid 0 is mapped, chown fails).
EMPTY=${EMPTY_INCLUDE_DIR:-$(mktemp -d)}
exec unshare -rm sh -c 'mount --bind "$0" /usr/include; mount --bind "$0" /usr/local/include 2>/dev/null; shift; exec "$@"' "$EMPTY" "$@"
