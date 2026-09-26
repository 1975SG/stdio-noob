#!/bin/bash
# split_glibc_final_outputs.sh: splits glibc-final's own real, already-built prefix into
# the three real outputs Guix's own gcc-toolchain package actually ships -- "out" (the
# stripped runtime), "debug" (separated DWARF debug info, GDB's own real global-debug-
# directory convention), and "static" (the .a archives) -- rather than leaving everything
# merged into one directory the way this reproduction originally built it
# ("Not shown" in the original build). Verified: a real program still links and runs against the stripped
# "out" (dynamic) and against "static" (static -B$STATIC/lib -B$OUT/lib); gdb, pointed at
# "debug" via `set debug-file-directory`, resolves real source-level info on a fully
# stripped binary with zero embedded debug sections.
# usage: split_glibc_final_outputs.sh <glibc-final prefix> <out-dir> <debug-dir> <static-dir>
SRC=$1; OUT=$2; DEBUGROOT=$3; STATIC=$4
rm -rf "$OUT" "$DEBUGROOT" "$STATIC"
cp -a "$SRC" "$OUT"
mkdir -p "$STATIC/lib" "$DEBUGROOT"

# 1. static output: every real .a archive, out of "out" entirely
for f in "$OUT"/lib/*.a; do
  [ -f "$f" ] || continue
  mv "$f" "$STATIC/lib/"
done

# 2. debug output: for every real ELF with real DWARF debug_info, the standard
# objcopy --only-keep-debug / --strip-debug / --add-gnu-debuglink sequence, into a
# sibling .debug/ subdirectory first (so the relative debuglink resolves while both
# still live in the same tree), then relocated into DEBUGROOT mirroring "out"'s own
# full absolute path -- GDB's real global-debug-directory lookup rule when no
# build-id is present (these binaries were not linked with --build-id).
find "$OUT" -type f | while read -r f; do
  readelf -S "$f" 2>/dev/null | grep -q debug_info || continue
  d="$(dirname "$f")/.debug"; mkdir -p "$d"; b="$(basename "$f")"
  objcopy --only-keep-debug "$f" "$d/$b.debug" || continue
  objcopy --strip-debug --strip-unneeded "$f" || continue
  objcopy --add-gnu-debuglink="$d/$b.debug" "$f" || continue
done
find "$OUT" -type d -name .debug | while read -r d; do
  parent="$(dirname "$d")"; target="$DEBUGROOT$parent"; mkdir -p "$target"
  mv "$d"/* "$target/" 2>/dev/null; rmdir "$d"
done

echo "out:    $(find "$OUT" -name '*.a' | wc -l) .a files left (expect 0)"
echo "static: $(ls "$STATIC/lib" | wc -l) archives"
echo "debug:  $(find "$DEBUGROOT" -name '*.debug' | wc -l) separated debug files"
