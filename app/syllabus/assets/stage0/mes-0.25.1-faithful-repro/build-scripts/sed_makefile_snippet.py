#!/usr/bin/env python3
"""Guix's sed-mesboot snippet (bug 36150): insert a CONFIG_HEADER line into Makefile.in right after
abs_srcdir='$(abs_srcdir)', matching commencement.scm's substitute* exactly."""
import re, sys
s = open("Makefile.in").read()
pat = re.compile(r"^(  abs_srcdir='\$\(abs_srcdir\)'.*)$", re.M)
new, n = pat.subn(lambda m: m.group(1) + "\n  CONFIG_HEADER='$(CONFIG_HEADER)'\t\t\\", s, count=1)
if n != 1:
    print("SNIPPET-DID-NOT-MATCH", file=sys.stderr); sys.exit(1)
open("Makefile.in", "w").write(new)
print("snippet applied")
