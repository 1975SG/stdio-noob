#!/usr/bin/env python3
"""Make C99 mixed declarations acceptable to gcc 2.95.3 without changing behaviour.
Driven by the compiler: compile, and for each `parse error` on a declaration line, hoist that declaration to the top of
its enclosing block (initialiser becomes an assignment; `static` declarations move whole).  Repeats until it compiles.
usage: c89ize.py <source.c> -- <compile command with {src} and {out}>"""
import re, subprocess, sys, os
src = sys.argv[1]; cmd = sys.argv[sys.argv.index("--")+1:]
DECL = re.compile(r'^(\s*)((?:static\s+|const\s+|unsigned\s+|signed\s+|struct\s+|long\s+|short\s+)*[A-Za-z_]\w*(?:\s+const)?(?:[\s\*]+))([A-Za-z_]\w*)(\s*\[[^\]]*\])?\s*(=\s*[^;]*)?;\s*$', re.S)
FOR  = re.compile(r'^(\s*for\s*\(\s*)((?:unsigned\s+|const\s+|struct\s+|long\s+)*[A-Za-z_]\w*[\s\*]+)([A-Za-z_]\w*)(\s*=)')
def compile_():
    r = subprocess.run([c.format(src=src, out="/tmp/c89.o") for c in cmd], capture_output=True, text=True)
    return r.returncode, r.stderr
def enclosing_open(lines, i):
    depth = 0
    for j in range(i-1, -1, -1):
        depth += lines[j].count('}') - lines[j].count('{')
        if depth < 0: return j
    return None
def stmt_end(lines, i):
    j = i; depth = 0
    while j < len(lines):
        depth += lines[j].count('{') + lines[j].count('(') - lines[j].count('}') - lines[j].count(')')
        if lines[j].rstrip().rstrip(';') != lines[j].rstrip() and depth <= 0: return j
        j += 1
    return i
changed = 0
for it in range(80):
    rc, err = compile_()
    if rc == 0: print("OK", src, "hoisted", changed); sys.exit(0)
    m = re.search(r':(\d+): parse error', err)
    if not m: print("CANNOT-FIX", src, err.strip().splitlines()[-1][:100]); sys.exit(2)
    n = int(m.group(1)) - 1
    lines = open(src).read().split('\n')
    # the error may be reported on the line after the offending declaration's type keyword; search this and the previous line
    done = False
    for i in (n, n-1, n-2, n-3):
        if i < 0: continue
        f = FOR.match(lines[i])
        e = stmt_end(lines, i)
        text = '\n'.join(lines[i:e+1])
        o = enclosing_open(lines, i)
        if o is None: continue
        indent = re.match(r'\s*', lines[o]).group(0) + '  '
        if f:
            decl = indent + f.group(2).rstrip() + ' ' + f.group(3) + ';'
            lines[i] = FOR.sub(lambda mm: mm.group(1) + mm.group(3) + mm.group(4), lines[i], count=1)
            lines.insert(o+1, decl); done = True; changed += 1; break
        d = DECL.match(text)
        if d and 'return' not in text.split()[0:1] :
            ind, typ, name, arr, init = d.groups()
            if 'static' in typ or (arr and init) or (init and init.lstrip('= \t\n').startswith('{')):    # static or array-with-initialiser: move the whole statement unchanged
                moved = [indent + l.lstrip() if k == 0 else l for k, l in enumerate(text.split('\n'))]
                del lines[i:e+1]; lines[o+1:o+1] = moved
            else:
                decl = indent + typ.strip() + ' ' + name + (arr or '') + ';'
                if init: lines[i:e+1] = [ind + name + ' ' + init.strip() + ';']
                else: del lines[i:e+1]
                lines.insert(o+1, decl)
            done = True; changed += 1; break
    if not done: print("CANNOT-FIX", src, "line", n+1, lines[n].strip()[:70]); sys.exit(2)
    open(src, 'w').write('\n'.join(lines))
print("GAVE-UP", src); sys.exit(2)
