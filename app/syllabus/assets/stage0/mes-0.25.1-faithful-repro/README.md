- # Mes 0.25.1 faithful reproduction (clean-slate fallback)
  
  Why this folder is here: After fixing some real problems in the
  `mescc-alignment-fix`/`tcc-config-and-patches` branch (aimed at
  Mes **0.27.1** + `tcc-0.9.26-1147-gee75a10c`), a new problem
  was discovered: the actual compiled `mescc` code for `x86_64-gen.c`
  (`gen_shift`, power-of-2 multiply to shift optimization) generates
  `shl reg,0` for a shift by 1 instead of `shl reg,1`, which is a
  real code generation bug in `mescc` and not a TinyCC source bug.
  Instead of debugging the actual `mescc.scm` code (Scheme, off
  topic), we verified what was actually built by the real production
  Guix `tcc-boot0` package, read directly from Savannah git at
  `gnu/packages/commencement.scm`, and noticed it uses:
  
  - TinyCC version **`tcc-0.9.26-1149-g46a75d0c`** (2 commits
    ahead of our `-1147`; tarball at
    `https://lilypond.org/janneke/tcc/tcc-0.9.26-1149-g46a75d0c.tar.gz`)
  - Mes version **`0.25.1`** (not 0.27.1); `mes-boot` version
    pin from `commencement.scm`.
  - `ONE_SOURCE=true` set explicitly (instead of the `false` default
    in `bootstrap.sh`) before running the actual `bootstrap.sh`.

This directory contains the full rebuild from scratch of that *precise* lineage,
separated from the `mescc-alignment-fix`/0.27.1 line in order for it to remain intact
as a fall-back if this line runs into a dead end as well.
Real reference:
[Guix's blog post "The Full-Source Bootstrap"](https://guix.gnu.org/pt/blog/2023/the-full-source-bootstrap-building-from-source-all-the-way-down/)
(x86_64-linux is confirmed as being currently, really supported, so this
is not a field of unresearched territory).

## Verified real, so far

**`mes-m2` compiled from real Mes 0.25.1 C source code, fully done from this
project's own already vendored M2-Planet/blood-elf/M1/hex2 toolchain**
(recompilation of hex0->M2-Planet is unnecessary, this chain does not depend on Mes version).
Used the real, untouched `kaem.run` file list (~100 real `-f` flags)
from the real Mes 0.25.1 tarball (`https://ftp.gnu.org/gnu/mes/mes-0.25.1.tar.gz`, 
the `lilypond.org` mirror commencement.scm gives 404s). One real, required local file:
`include/mes/config.h` (autoconf-generated, not included in the
tarball, reused this project's own 0.27.1 era template,
only the version string was updated).

**Real, upstream M2-Planet/Mes opcode-table gaps found and closed**
(`x86_64-defs-patch/x86_64_defs.M1`, 4637 lines, the real Mes 0.25.1
`lib/m2/x86_64/x86_64_defs.M1` with these additions), following a
precedent that had already been set elsewhere in this project (M2-Planet HEAD
generated addressing modes that the hand-written 1149/0.25.1-era opcode
tables had never anticipated). Neither M2-Planet HEAD (`v1.13.1`) nor the
project's own vendored `M2-Planet-pinned` (`bd2fe4b0`) had avoided
this, so the deficiency was in the *opcode table*, not version
discrepancy between M2-Planet builds:

- `xor_eax,eax` (not present at all)
- the complete push/pop table for all 16 general registers (only
  rax/rbx/rdi/rbp were known)
- the complete 16x16 `mov reg,reg` table (only 9 pairs known)
- the complete 16x16 table for `add`/`or`/`and`/`sub`/`xor`/`cmp`/`test`
  reg,reg (only 1 pair each known)
- the complete `lea reg,[base+DWORD]` table, including the SIB-byte variant
  for `rsp`/`r12` as base and the RIP-relative variant for all destination
  registers (only 6 known)
- the complete unary-group table (`mul`/`imul`/`div`/`idiv`/`not`/`neg`)
  for all 16 registers (only 5 known)
- the complete 32-bit-registers (`eax`/`ecx`/.../`r15d`) table for `mov`
  and all 7 arithmetic operations above

All of these generated programmatically based on the true Intel encoding
(REX.W/R/B, ModRM, SIB) rules; every formula was checked against an
existing, already correct entry first (e.g. generated `mov_rax,rdx 4889D0`
matched the entry from the file byte-by-byte). With `M1` assembling the
true, unmodified Mes 0.25.1 source code fixed from failing on line 7 to
perfect passing.

**The real `Elf64_Addr`/`elf.h` `HAVE_LONG_LONG` problem exactly**
**reproduces using this exact real configuration**: tested by running
the true, unmodified `tcc-0.9.26-1149-g46a75d0c` source code through
the true Mes 0.25.1 `mescc`, with the true `configure` and `bootstrap.sh`
scripts, `ONE_SOURCE=true`. The same error message, `<stdin>:1: parse
failed... on input "Elf64_Addr"` as when using 0.27.1. It clearly shows
that the problem is really a version-independent issue with TinyCC
itself. There are 23 locations which guard `Elf64_Addr` and its friends
with just `#if HAVE_LONG_LONG` while `-boot0` only defines
`HAVE_LONG_LONG_STUB` and nothing else. The same `#if HAVE_LONG_LONG_STUB ||
HAVE_LONG_LONG` patching (which has been already proven on -1147 line)
fixes the problem here as well.

**The actual fix: Mes 0.25.1's `mescc` implements an entirely different
code generation path for `shift_by_const` that avoids the flawed
immediate-encoding path entirely.** While 0.27.1 generates
`shl reg,$imm` in compiled `gen_shift` support code (getting the
immediate encoding byte incorrect), 0.25.1 always generates the register-
based encoding `sar %cl,%rax` and loads the shift amount into `CL`.
This avoids the broken ternary into immediate encoding
`vtop->c.i & (ll?63:31)` entirely under 0.27.1. Verified **in
practice**, not just inspecting the assembly output file:
compiled, assembled (into M1 object code), and linked (into ELF
binary by `hex2`) an actual minimal ELF binary against actual
sources for Mes 0.25.1's own library (39 sources from
kaem.run's actual library list, plus the real transitive
dependencies `__init_io.c`,`__mes_debug.c`, and `getenv.c` not found
on the original crt-only list, compiled using `mescc` rather than
M2-planet this time), and run it. **Actual exit code 1** on
`n=-1; l2=2; while(l2){l2>>=1;n++;} exit(n);`. Correct (2 takes
precisely two right shifts to become zero). Not just disassembly,
but actual execution with correct output.

### Two Mescc Environment Quirks Encountered and Fixed

- **Misreporting of mescc's own `-o out file.c` (build in one go)
  assemble step `M1` as failure** (`assert-system*`'s status check),
  despite `.o` output being correct and M1's real exit code being 0
  (checked by repeating `M1` on its own). Fixed in exactly the same
  way as the rest of the scripts for this project's build:
  `mescc -S` only to compile, then run M1 and `hex2` directly. Real
  cause still undetermined (probably some `system*` status decoding
  problem in this Mes version under `mes-m2`), not an issue, no further
  investigation attempted yet.
- `<arch/syscall.h>` (needed by several real `lib/linux/*.c`) requires
  a real `include/arch -> include/linux/x86_64` symlink which is not
  included in the raw tarball (made at normal install/build time);
  made by hand.

## The true pivot: this entire series of patches was trying to solve the wrong architectural problem

Further investigating the `Elf64_Addr` problem showed the true nature of
the actual formula that Guix used: `bootstrap.sh`'s `CPPFLAGS_TCC`
(flag set when building `tcc-mes` itself – the very first stage)
**doesn't define `HAVE_LONG_LONG`** at all on x86_64, proven by
carefully reading the actual unmodified shell script, twice. Because
`x86_64-gen.c` always `#define PTR_SIZE 8`, and the definition of
`ElfW`/`addr_t` in `tcc.h` always picks `Elf64_Addr` whenever
`PTR_SIZE == 8` (and not because of `HAVE_LONG_LONG`), the reference to
`Elf64_Addr` will **always** be present when compiling for x86_64,
regardless of `HAVE_LONG_LONG`. And yet Guix includes this as a part of
production-ready release.

Tthe problem: **this is not an x86_64 target.**
`commencement.scm` sets up `mes-boot` with
`--host=i686-linux-gnu`, and the entire early bootstrap sequence
(`gzip-mesboot`, `make-mesboot0`, et al) explicitly hardcodes
`i686-unknown-linux-gnu` even if `%current-system` is `x86_64-linux`.
So `mescc`'s own `-dumpmachine` (as compiled and installed by
`mes-boot`) says that the host is i686, `bootstrap.sh`'s
`mes_cpu` case statement sets `tcc_cpu=i386`, and `tcc-mes` and
`tcc-boot0` are built as i386-targetting compilers, `PTR_SIZE=4`,
`addr_t` is always defined as `Elf32_Addr`, and `Elf64_Addr` is
never defined at all. **Empirically verified:** the actual, full,
unpatched `tcc.c` (~20k lines, `ONE_SOURCE=1`) compiles without
error under `-D TCC_TARGET_I386=1`, no `Elf64_Addr` problems at
all, the bug this entire line was chasing for two sessions doesn't
exist on the proper sequence. The native 64-bit compiler comes later.

This reflects the context of the blog post itself (i686-linux as the base
even where x86_64-linux is supposedly "supported") as well as the entirety
of the rest of this project's prior `stage0/` development (hex0 through M2-Planet
were all amd64 native, but the TCC bootstrapping phase favors i386 first,
even on an x86_64 host).

## The actual working i386 environment

Created an entirely parallel i386/x86 environment based on the exact
same methodology as the x86_64 series, from actual Mes 0.25.1 source:

- **`mescc32`**: a second entry-point wrapper
  (`module/mescc/mescc-entry-x86.scm`, `%arch` set to `x86` in
  `@mes_cpu@` instead of `x86_64`), confirmed that `mescc`'s own
  target architecture is driven by `%arch` environment variable (read
  from `%host-arch` in `module/mescc.scm`, `mescc:main`) which is
  totally separate from `-D TCC_TARGET_*` TCC-source-level options.
  The real-life gotcha found: in the initial `tcc.c` compilation `%D
  TCC_TARGET_I386=1` passed through the wrapper for `mescc` targeting
  x86_64, silently producing 64-bit register code (%rbp) for 32-bit
  TCC source, found by inspection of the actual `.s` output, not by
  assumption.
- **Real-life `M1` file mixup fixed**: for the `mescc`
  compiled output (instead of Planet M2 bootstrapping output),
  the proper opcode table is `lib/x86-mes/x86.M1` (mescc-target
  file), not `lib/m2/x86/x86_defs.M1` (M2-Planet bootstrap file),
  confirmed by test with a pre-existing hand-written `crt1.M1` on
  both and finding the same error against the wrong file, thereby
  ruling out any compiled output issue. `lib/x86-mes/x86.M1`
  (345 lines) was fully complete in its opcodes tables for everything
  needed for this build, unlike `x86_64_defs.M1`.
- The **complete and real 139 file `libc+tcc.a`** is determined by
  the same `configure-lib.sh` sourcing process as the one for the
  x86_64 line, but with `mes_cpu=x86` this time, resulting in all
  139 files compiling and assembling without any errors.
- The **complete, unaltered `tcc.c` file** is successfully
  compiled (two harmless warnings about `BufferedFile/rank`
  type-deducing), assembled and linked into a real 755 KB `tcc-mes`
  ELF binary.
- A real bug in `hex2` identified: linking to the `.a` archive
  file directly `-f libc+tcc.a` gives a fake
  `Target label <arch is not valid` warning followed by the
  program crashing due to `SIGBUS` on the very first instruction,
  even for a trivial `return 0`. The fact that the bug lies within
  the archive itself (and not the constituent files) was verified by
  building an almost identical trivial program with explicitly
  specified `.o` files only, which linked successfully (real exit
  code 0). The string `"!<arch>\n"` (which is TCC's own real magic
  number for `ar` archives, coming from `tcctools.c`) is found in
  `tcc.s` file and is most certainly the source of the error of
  `hex2`'s archive member scanner mistaking it for a label.

## Diagnosing the i386 crash: true register-pair misalignment, not a bounded error

As mentioned above, the so-called "new, real, unexplained crash"
proved to be unrelated to any struct alignment issue already
discovered. It was narrowed down using a very simple direct test
statement, namely `long long x = 5;`. Compiling it under
`mescc32` results in *one* 32-bit immediate load instruction
(`mov $0x5,%eax`) without the higher 32-bits being calculated
anywhere. `mescc` itself uses a single 32-bit register when doing
expression evaluation on i386 codegen stage, thus the
register-pair (edx:eax) is never handled at all upstream from the
local variable store location. It has been independently verified
that `r->local+n-text` (i.e. the actual store emitter)
supports only 0/1/2/4 byte writes, but not 8 bytes.

Fixing this properly requires a 64-bit value representation to be
woven through constant-folding, arithmetic, and all expression evaluation
points in `compile.scm`, open-ended compiler engineering effort,
not a constrained one. Intentionally not attempted. As directed, this
line for i386 is left as-is (not removed, `x86_64-defs-patch/` and all
this documentation remain just in case this needs to be reopened some day)
in favor of reverting back to the x86_64 line where this whole category
of issue simply does not exist (native 64-bit register values, no pairing).

## Back to x86_64, now under the right Mes 0.25.1 version

1. The same target architecture as the first tries in this project’s
   0.27.1 series, except now using the faithful Mes
   0.25.1 + faithful `tcc-0.9.26-1149` combo set up above. Identified
   and fixed three distinct previously latent bugs on the way (all
   real-vendored before/after pair-wise in `simple-patches/`, see below):
   1. **`module/mescc/x86_64/info.scm`: `long double` is size 8, the
      same as `double`.** The same class of bug already discovered
      and patched in this file for 0.27.1 series, this is an
      independent vendoring of the 0.25.1 version of this file.
      Real TCC's `x86_64-gen.c:100` says `#define LDOUBLE_SIZE 16`.
      Fixed: 8 -> 16.
2. **`module/mescc/i386/info.scm`: four wrong type sizes**, never
   used by this project until this session's work on i386 above:
   `long long`/`unsigned long long` at 4 bytes instead of 8; `double` at
   4 (identical to `float`) instead of 8; `long double` at 4 instead of
   actual `LDOUBLE_SIZE 12` (`i386-gen.c:69`). Fixed all four. This
   bug fix *revealed* the register pair limit, since the original,
   wrong 4-byte sizes had avoided it by never storing any
   8-byte locals at all.
2. **`module/mescc/compile.scm`'s `lshift`/`rshift`: a bare `>`
   instead of `>=`** in deciding the type of the shift result, which
   falls back to signed `int` (`default`) whenever `type-a`'s size is
   NOT greater than `default`'s, even when *equal*, so loses C's real
   usual arithmetic conversions rule about keeping an equal-sized
   unsigned type unsigned. Live symptom: using `sar` (sign-extending)
   instead of `shr` (logical) for `>>=` in `size_t`. Root-caused via
   live `gdb -p <pid>` attach + `objdump` disassembly of hung process,
   fingerprinted against `tcc.s` labels, not guesswork.

**Proof of concept, live tested**: `tcc-mes -version` outputs
`tcc version 0.9.27 (x86_64 Linux)` and exits with status 0, having been compiled
from source using this true Mes 0.25.1 + tcc-0.9.26-1149 recipe. (The version
output is "0.9.27" -- a harmless artifact left in `config.h`
following failed attempts to build 0.9.27 in the 0.27.1 release series.)

**Exact blocking call found, with precise location**:
`tcc-mes -c ret42.c -o ret42.o` (compiling the code, rather than just
`-version`) hangs. Systematic debug print bisection, `fprintf` and
`fflush` added at the boundaries of calls in the real source code,
rebuilt (`mescc -S` -> `M1` -> `hex2`, always individual object
files, never the archive as per above `hex2` problem), run under
`timeout -s KILL N ... > out.log 2>&1` (never pipe a SIGKILLED
program to `tail`, buffering will eat the output, redirect to a file
instead), narrowed down to an exact blocking call: `decl(VT_CONST)`
in `libtcc.c`'s `tcc_compile`. Everything before it is proven
working: `tcc_open` (real FD), `setjmp`, `preprocess_start`,
`tccgen_start`, including even the first call of `next()` (correctly
tokenizing `ret42.c` leading `int` keyword, `tok` = `256`). The
function `decl()` itself, core TCC declaration/statement parser does
not return at all. First hypothesis about possible disassembly and
code analysis (`cstr_realloc` like doubling buffer problem) was a
wild goose chase, direct instrumentation of actual `cstr_realloc`/
`cstr_ccat` functions source shows that they terminate correctly on
each call.

- **Two additional infrastructure findings, observed but not fixed:**
  - The `vfprintf` provided by Mes itself does not handle `%p`, and
    emits instead the error `vfprintf: not supported: %:p`.
    Observed firsthand while implementing the debugging instrumentation above
    (the first format string I tried containing `%p` appeared to break all
    debugging output silently until this problem was observed and worked around).
  - The `hex2` multi-.a-archive bug mentioned in the i386 section above
    occurs in the x86_64 environment as well (same `hex2`, same bug),
    same workaround (single .o files).

The directory `simple-patches/` contains the three actual before and after files:
`i386-info.{before,after}`, `x86_64-info.{before,after}` and `compile-scm.{before,after}` (the latter file contains two fixes, one for the `lshift`/`rshift` problem and the other for the `init-local` struct-copy problem, because both can be applied to this architecture-independent file, which is part of 0.25.1).

- ## Open, not yet finished
  
  - **Resolved:** the `decl()` hang was the `convert-r0` sign-
    extension of unsigned 32-bit loads (`long-signed-r` -> `long-r`, like in
    0.27.1). `tcc-mes` now compiles real C. Check out
    `simple-patches/compile-scm.after` (now also carrying the previous alignment
    patch) and `build-scripts/`.
  - **Finished:** `tcc-boot0`..`tcc-boot6` compile per this recipe and are
    identical bytewise. Vendor patches in `simple-patches/` (`compile-scm`,
    `stdarg-h`), build scripts in `build-scripts/`.
  - **Finished:** the float-literal problem was in the naive `strtod`
    (`abtod`) of Mes itself, not a compiler bug; the `simple-patches/abtod-c.*`
    fixes it and the chain is now at a fixed point (`boot8 == boot9`), with
    proper float folding.
  - **Finished:** `tcc-0.9.27` compiled using `tcc-boot9`, self-hosted with a
    byte-identical fixed point; two static-linking problems with 0.9.27 patched
    (`simple-patches/tcc027-tccelf-c.*`, `build-scripts/build027.sh`,
    `self027.sh`).
  - **Finished:** gzip 1.2.4 (byte-identical with system gzip) and make 3.80
    (self-hosting, same as host make) compiled with the bootstrap compilers;
    detected and fixed a libc `_exit` inline-assembly bug (`simple-patches/exit-c.*`).
  - **Completed:** Patch 2.5.9 and binutils 2.20.1a compiled and checked against a gcc compilation of the
    same source (1070/1070 tool output matches, ld 7/7 modes, `as` byte identical); nine errors in Mes's libc and headers
    corrected (`simple-patches/{setjmp,ntoab,qsort,fopen,rewind,malloc,free,realloc}-c.*`, `kernel-stat-h.*`).
  - **Completed:** The full chain of compilers (tcc-mes, boot0..9, tcc-0.9.27) recompiled from stage 0 using the
    corrected libc (`build-scripts/run_chain.sh`, `run_027.sh`); measured not just by fixed points, but by actual behavior;
    two further bugs identified and corrected (`abtod` v2, Mes `libtcc1.c` should not be compiled with HAVE_FLOAT).
  - **Completed:** gcc 2.95.3 cross-compiler from x86-64 host to i686 (`build-scripts/build_gcc295.sh`,
    `simple-patches/gcc295-xm-i386-h.*`, `freopen-c.*`); a sample test program gives the same results as host-gcc at
    -O0, -O1, -O2.
  - **Completed:** The tcc-compiled gcc 2.95.3 passes 880 assembly checks against the same-source host gcc build,
    but does not yet show the correctness of the host port for 64-bits.**Done:** Mes's 32-bit libc built by the cross gcc 2.95.3 links (256/256) and passes 189/211 Mes tests at -O0
    and 187 at -O2; all other results traced (harness, layout-dependent tests, C89-unspecified), none a codegen defect.
  - **Completed:** Patch and binutils rebuilt by the fixed chain; binutils is consistent with the host-gcc reference
    (1070/1070 tool outputs, as 112/112, ld 7/7) and the previous cross-compiler rebuild (112/112 objects).
  - **Completed:** gcc 2.95.3 rebuilt as an actual i686-hosted compiler (`build-scripts/build_gcc295_i686.sh`) and self-reproduces: stage-2 and stage-3 code/data segments are identical, assembly 256/256 (stage 1 vs. 2, 8 differences due to the same constant being spelled differently, objects identical).
  - **Completed:** glibc 2.2.5 built using i686 gcc 2.95.3 (`build-scripts/build_glibc225.sh`, Guix patches and kernel headers); programs using glibc produce output indistinguishable from host glibc. Exception: stub `linux/nfs.h`.
  - **Completed:** gcc-mesboot0: gcc 2.95.3 rebuilt using glibc 2.2.5 (`build-scripts/build_gcc_mesboot0.sh`); stage 4 vs. 3 assembly 256/256, stage 5 vs. 4 all loadable segments identical.
  - **Completed:** binutils-mesboot1 (216/216 objects, 600/600 tool outputs, ld 8/8 against the old build) and make 3.82 on
    glibc. **Erratum:** section comparisons made in both the previous two steps were vacuous (`objcopy -O binary ... -` does not
    output to stdout); done properly by comparing bytes from sections, the glibc line comparison fixed point is correct, the 2-stage vs 3-stage
    pair is incorrect (64-bit hosted stage 1 compiles some constants differently), and an issue with the wrapper script produced 64-bit
    `struct stat` for stage 2/3 tools.
  - **Completed:** gcc 4.6.4 built by gcc 2.95.3 (`build-scripts/build_gcc464.sh`); C99 compilation works; Mes's suite 203/211 at -O0
    (all 12 C99 tests compiled); bootstrap comparison: stage 2 vs 3 all 1305 objects' `.text` sections identical; stage 1 (built by 2.95) vs
    stage 2 assembly code identical in 256+256 libc files, 18 TinyCC files, 194 gcc files.
  - **Completed:** gcc-mesboot1: GCC 4.6.4 with C++ and libstdc++, compiled by 2.95.3 in a sandbox that HIDES the
    host's /usr/include (`build-scripts/run_hidden_headers.sh`; the first build was leaking the host configure results, like SSP). Fixed
    point mb3 vs mb4: 3506 objects, the only difference is build-dir; libstdc++ 121/121; mb2 vs mb3 asm identical for C++ and C corpora.
  - **Done:** Hello, binutils-mesboot, gawk-mesboot and glibc 2.16.0 (static+dynamic+pthreads, shared libraries) were compiled with gcc-mesboot1;
    glibc's test suite 654/796 (25 tests require ungenerated locales; ~63 nptl cancel/exit tests require libgcc_s; ~43 nptl tests are not yet analyzed). **Found:** gcc 2.95.3
    compiles MPFR 2.4.2 incorrectly, thus the gcc built with 2.95 crashes on FP constants folding; gcc built from itself compiles glibc into byte-identical objects (except `__TIME__`).
    This comparison had a blind spot there.
  - **Done:** gcc-mesboot: gcc 4.9.4 with shared libgcc_s/libstdc++ against glibc 2.16, built with self-built gcc 4.6.4. C11/C++11 works;
    stage 2 vs stage 3: 4104/4118 objects are identical (the rest: path digit); MPFR corpus (FP heavy) 207/207 identical; libgcc_s.so.1/libstdc++.so
    are byte-identical. libgcc_s hypothesis proved: glibc nptl 169 -> 238 of 275 (37 are still failing, mostly unknown).
  - **Completed:** bash 5.2.37, sed 4.8, xz 5.4.5, tar 1.35, grep 3.11, coreutils 9.1 compiled with gcc 4.9.4 on glibc 2.16; compared to actual GNU
    versions (identical in bytes tar archives; grep 20/20 matches; coreutils 95/99, rest detailed); **sed/grep/tar recompiled with just these tools are byte-identical**
    to the compilation by host-tools. Oracle pitfall: host's `grep` is ugrep.
  - **Completed:** make 4.4.1, bzip2, diffutils, findutils, file, gawk 5.3.0, patch, sed 4.9 compiled with just the bootstrap tools; 86/88 commands identical
    to those on the host (bzip2 output byte-identical; 2 are gawk version strings).
  - **Completed:** binutils 2.44 (cross-boot0) compiled with gcc 4.9.4: assembles the 216-file corpus (disassembly identical for 212 files, the other are padding), 8/8 ld modes,
    compiles/runs the gcc 4.9.4 test cases, ar is deterministic, objdump/readelf/nm/size 360/360 identical to host's 2.46.1.
  - **Completed:** gcc 14.3.0 (cross-boot0, C/C++, no libc) compiled with gcc 4.9.4; C23, C++20, the glibc programs and Mes's suite (204/211 at -O0, 198 at -O2 with crt1.o at -O0:
    gcc 14 does not generate frame setup for Mes's `_start`).
  - **Completed:** m4 1.4.19, perl 5.36.0, bison 3.8.2, flex 2.6.4, Linux-libre headers 6.12.17, compiled with only bootstrapped tools; bison/flex produces output byte-identical to the host's, perl's core suite
    contains 2756 files (7 fail, sandbox related except one file), headers compile against glibc 2.16.
  - **Completed:** autoconf 2.69, automake 1.17, texinfo 6.8, expat 2.7.1, Python 3.5.9 (real autotools project from end to end; Python's suite 321 OK / 14 failed (sandbox, timezone,
    and expat-version XML cases) / 49 skipped). The first build of Python silently missed modules _socket/_bz2/_lzma; redo.
  - **Completed:** glibc 2.41 cross-built using gcc 14 + binutils 2.44 against the 6.12 headers; programs include POSIX/dlopen/iconv/pthreads/C23 (mktime now uses host timezone); glibc test suite
    5889 tests: 4940 pass / 477 fail (as built); 298 of those failures are due to Guix patch's namespace pollution; if libgcc_s.so.1 is provided (diagnostics) 5074 pass / 343 fail.
  - **Completed:** static bash, gettext-boot0, glibc-final, libstdc++, zlib, binutils-final (byte-identical to the cross-boot0 binutils) and gcc-final (gcc 14.3.0 native, three-stage build;
    second stage == third stage for 540/540 object files plus cc1/cc1plus/xgcc if debug info removed). Works without `LD_LIBRARY_PATH`.
  - **Done:** explanation of gcc 14 `70-stdarg` failure at -O2: Mes' `va_start` walks from `&one`, gcc 14 copies this parameter into its own frame slot; `__builtin_va_start` and a `volatile` parameter pass.
  - **Done:** explanation of the 29 glibc 2.41 nptl failures: tests link gcc-cross-boot0 `inhibit_libc` libgcc (no `_dl_find_object`, static unwinder traps); relinked like a proper gcc driver 28/29 pass, the remaining one (`tst-setuid3`) is my one-uid sandbox test and passes with a uid range.
  - **Done:** explanation of the other 8 unexplained glibc 2.41 failures: 2 boot0-libgcc (pass relinked), tst-rseq (kernel 7.1 rseq size 33), 4 container-shell-path/PATH tests (Guix baked bootstrap-bash path), and a genuine tiny memory leak in Guix's dl-cache patch (`mtrace-tst-loading`).
  - **Done:** the remaining 7: 5 setuid/chown tests pass in a multi-uid namespace (with a supplementary group and a non-nosuid TMPDIR); the 2 ldconfig tests fail due to Guix design (ld.so ignores `/etc/ld.so.cache` outside `/gnu/store`).
  - **Done:** bash-final (bash-minimal, gcc-final, `-static-libgcc`, pgrp patch): refers only to glibc-final; deterministic; bash's own suite 81/83 identical to host build with same configuration, the other 2 are harness artefacts.
  - **Completed:** guile-final (Guile 3.0.9, mini-GMP) + pkg-config 0.29.2, libffi 3.4.6, libunistring 1.3, libgc 8.2.8, source files match hashes from Guix's; two builds: 958/959 files are identical (the buildstamp is the only difference); Guile's test suite: 42380 pass / 3 environment related failures / 16 unanswered.
  - **Completed:** ld-wrapper (guile script compiled with guile-final; 9/9 behavioral tests) and glibc-utf8-locales-final (same as host in behavior of locales; identical to my previous approach for files).
  - **Completed:** the final tools (coreutils 9.1, grep, sed, xz, bzip2, gzip, tar, diffutils, findutils, patch, file, gawk+libsigsegv, zstd, GNU make with Guile), built in Guix's staged order; source files match hashes from Guix's; all ELF files depend on the final toolchain; all suites passed except 3 reasons stated.
    -**Done:** a from-scratch fresh-root rebuild of glibc-final through the final tools, g8-g11 taken as given; found and fixed two real bugs (binutils-final's vendored script was missing its i686 triplet; the final-tools staged rebuild assumes coreutils/grep/xz already exist) and vendored the previously hand-built `bin-final` farm generator; completed end to end in ~66 min, zero bootstrap-toolchain references in any of 152 ELF files, functional + differential (61/74, same as the step above) checks pass, cross-root comparison shows only path-length noise. Also: g6/g7/g8's `only` PATH farms are real, previously-undocumented hand-built glue mixing the bootstrapped compiler with host-gcc-built driver tools — noted, not reproduced (out of scope; g8 unchanged and already tested).
  - **Done:** The 37 glibc 2.16 nptl failures left over from the previous run explained: 16 resolved via relinking (again, the same `-fexceptions`/two-unwinders workaround as one step earlier); 17 is a real but genuine ~60-64 MiB virtual memory limit on pthread stack total size; 4 is an inconsistency between test's use of `SO_SNDBUF` and the kernel era. All nptl failures in the whole chain (2.16 and 2.41) now have a confirmed explanation.
  - **Done:** g6 (mesboot6)/g7 (boot0tools)/g8 (binutils-cross-boot0+gcc-cross-boot0) recompiled in a clean root from a `PATH` farm constructed purely out of the bootstrapping build products, not host-gcc-produced glue (addresses an omission discovered in the original `g6/only`'s undocumented `g6/out_host`). It was found that mesboot6 package itself was not complete (its own `xz` was a symlink to the host-build version, while `bash`/`coreutils` were absent); all six packages rebuilt for real, following the Guix mesboot recipe precisely. Two bugs detected by executing it: an incorrect auxiliary-file directory, and a wrapper-generator that assumed hard-coded `gcc` as a compiler for `g++`/`cpp` (silently breaking C++ builds and causing linking errors). Both bugs fixed; all RUNPATH/interpreter paths checked reference only the legitimate input files. 
  - **Done:** `gcc-toolchain` (Guix's union build closure at last, gcc-final + ld-wrapper + binutils-final + glibc-final all in one merged prefix, `union_build.py` an exact port of the real algorithm in `guix/build/union.scm`, even validated with a constructed collision test first). 683 items, no broken links, 2 actual collisions all solved correctly (ld-wrapper's `ld` takes priority here, just as the package intends). Single merged `bin/` in `PATH` builds, links, runs real C programs; and even C++ inside the package's actual scope works fine, until kernel header inclusion is required (that's an actual separate Guix package, not a bug) (`build-scripts/build_gcc_toolchain.sh`).
  - Is the gap in i386 registers worth a separate follow-on study,
    probably not unless the x86_64 architecture encounters something
    fundamentally harder to solve than `decl()`.
  - Many member archive linking issue with `hex2`, definitely real,
    definitely reproducible, worked around, but not root-caused in `hex2`
    sources.
  - The Mes `vfprintf()` function lacking `%p` support, observed,
    but not followed up further.
  - `tcc-boot0` and the entire rest of the actual `boot0`..`boot6`
    series, blocked by the `decl()` hang above.
  - Other `mescc.scm`/`compile.scm` code generation bugs outside the
    three identified and fixed this session.
