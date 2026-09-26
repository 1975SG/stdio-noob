#!/usr/bin/env python3
"""union_build.py <output> <input1> <input2> ...

Faithful reimplementation of Guix's (guix build union) union-build, used to build gcc-toolchain.
Recursively merges INPUTS into OUTPUT as a symlink tree. At each name, if only one input
provides it, symlink straight to that input (even a whole directory, undescended). Only where two or
more inputs genuinely provide the same name does this create a real directory in OUTPUT and recurse one
level deeper. A collision between differing regular files is resolved by keeping the FIRST input in the
given order (matching Guix's resolve-collision/default), with a warning printed to stderr; a collision
between two directories always recurses (never a true conflict, just deeper merging); a same-content file
collision is silent. See guix/build/union.scm's docstring/algorithm, read from the upstream Guix mirror.
"""
import os, sys, filecmp

def real_is_dir(path):
    # Guix's file-is-directory? follows symlinks (uses stat, not lstat) - so a symlink TO a directory counts as a directory here.
    try:
        return os.path.isdir(path)
    except OSError:
        return False

def files_in_directory(d):
    return sorted(os.listdir(d))

def same_content(a, b):
    try:
        return os.path.samefile(a, b) or (os.path.isfile(a) and os.path.isfile(b) and filecmp.cmp(a, b, shallow=False))
    except OSError:
        return False

def union(output, inputs):
    if len(inputs) == 1:
        os.symlink(inputs[0], output)
        return
    dirs = [i for i in inputs if real_is_dir(i)]
    files = [i for i in inputs if not real_is_dir(i)]
    if dirs and not files:
        union_of_directories(output, dirs)
    elif files and not dirs:
        if all(same_content(files[0], f) for f in files[1:]):
            os.symlink(files[0], output)
        else:
            print(f"warning: collision encountered:\n  " + "\n  ".join(files), file=sys.stderr)
            print(f"warning: choosing {files[0]}", file=sys.stderr)
            os.symlink(files[0], output)
    else:
        print(f"warning: collision (file vs directory):\n  " + "\n  ".join(inputs), file=sys.stderr)
        print(f"warning: choosing {inputs[0]}", file=sys.stderr)
        os.symlink(inputs[0], output)

def union_of_directories(output, dirs):
    os.mkdir(output)
    table = {}
    for d in dirs:
        for name in files_in_directory(d):
            table.setdefault(name, []).append(d)
    for name, dirs_with_name in table.items():
        union(os.path.join(output, name), [os.path.join(d, name) for d in dirs_with_name])

def main():
    output, inputs = sys.argv[1], sys.argv[2:]
    inputs = [os.path.abspath(i) for i in inputs]
    seen = []
    for i in inputs:
        if i not in seen:
            seen.append(i)
    if os.path.exists(output):
        sys.exit(f"union_build.py: refusing to overwrite existing {output}")
    union_of_directories(output, seen)
    print(f"union-build: {output} from {len(seen)} inputs")

if __name__ == "__main__":
    main()
