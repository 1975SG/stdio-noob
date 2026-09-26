# Syllabus

The real course content and its parser. Bootstrap curriculum

(Modules 1-5) redesigned onto the stage0-posix`/`live-bootstrap`

chain.

## Schema

`syllabus.xml`: a `<syllabus>` root holding ordered `<>`

elements (`id` `title` `scaffolding` `"none"` or a comma-separated

list of modes) each holding ordered `<step>` elements. A steps `id`

may repeat across steps that represent the point on different

scaffolding paths (distinguished by the steps own `scaffolding`

attribute) no milestone currently uses this (every one is

`scaffolding="none"` currently) but the parser still supports it

for whenever a milestone genuinely needs a scaffolded/from-scratch

split again.

Every step carries a fixed explanation shape: `<does>`

`<needed-for>` `<connects-to>` `<hardware>` an

optional `<question>` then `<command>` the runnable line,

always present. "Explanation first" governs order never withholding.

**Step `type`:** defaults to `"command"` (the shape.

`type="seed"` is for a -derivable trust-root artifact something

handed over not derived from its own explanation (hex0s own bytes,

not logic a learner could reconstruct). It additionally requires a

`<checksum algo="...">` child; its `<command>` is the verification

itself (a hash check) never a build action.

Milestone ids are the ids the `noob`-user files `milestones` map

keys against this file is the one source of truth for

which ids exist at all; the noob-file only ever tracks position

against it.

## Content status

`chroot` is fully. Matches the real sequence verified live

against Alpine/QEMU though Module 1s own later redesign (air-gapped

`-net none` context VFS bind-mounts) is named as a real future task,

not yet applied. `Namespaces` (Module 2) and `self_hosting_os`

(Module 5) both started as structural placeholders but

are now fully written, see below.

`assembler`

and `c_compiler` had their old scaffolded/from-scratch

placeholder content superseded by the real `stage0-posix`/

`live-bootstrap` framing (not extended there's no "your own

version" to pick a depth for once the milestone works through real

upstream source so both moved to `scaffolding="none"`). **`Assembler`

is now :** 9 real live-verified

steps carrying a learner from checksumming a 229-byte trust-root seed

through hex1 hex2, catm, M0, cc_amd64 and a self-hosted M2-Planet

ending with a real compiled program actually executed (exit code 42).

**`c_compiler` has opened for real:** 18

live-verified steps. Steps 01-07 (hand-typed, like `assembler`)

carry the toolchain through `stage0-posix`s further self-hosting

bootstrap (blood-elf a real macro assembler and linker a real

shell a gcc-like driver M2-Mesoplanet and 13 real utility programs

built with it). Steps 08-14 are Mes itself end to end

the first real trigger-and-observe package step this milestone locked

culminating in a real self-hosted Scheme interpreter (`mes-m2`)

actually interpreting Scheme and a real install verified against the

actual officially published `mes-0.27.1.amd64.checksums`: **12 of

12 binary/library artifacts match exactly** the strongest

correctness proof in this whole project so far. Steps 15-18 open

TinyCC (`tcc-0.9.26`) a fully independent real C compiler

(`tcc-mes`) now self-hosted and running `tcc-mes -version` a real

compile to a real ELF object and two pieces of its own runtime

library (`crt1.o` `libtcc1.a`) all proven live.. Handled

six real tooling bugs across this whole pass (a version-pin mismatch

in M2-Planet an unreliable `kaem` invocation, a false-failure in

`mescc`s one-shot link mode worked around by pre-assembling with

`M1` directly a real permission bug and separately a real

header-install-path bug in already-shipped `c_compiler-14` both

fixed after the fact) plus one found-but-inert mismatch left open (a

template text file that doesn't checksum-match despite every compiled

output matching perfectly). **An earlier "genuine non-determinism"

finding here was wrong. Was retracted.** It was an embedded

output-filename string label, not code variance; `mescc` is

fully deterministic.

**That specific attempt (Mes 0.27.1 the `ONE_SOURCE` amalgamation)

never got unblocked, real not glossed over.** An earlier

diagnosis here (a diffuse register-allocator-level defect) was also

retracted: the real cause was `mescc.scm` having no struct/union

alignment logic all fixed and verified, but self-compilation

then hit a different later-stage TinyCC diagnostic

(`tccpp.c:216: error: 64 bit addend in load`) and THAT specific line

of investigation stops there at `c_compiler-18` exactly as written.

**. A separate later investigation found the real resolution**

(`c_compiler-19` through `-77` 59 more real steps): under Mes 0.25.1 Guixs own actual

version pin, not 0.27.1 `tcc-mes` genuinely became self-hosting.

The real story along the way: a struct-copy bug in `mescc.scm`s

`init-local`; a genuine upstream TinyCC PLT-relocation defect; the

real discovery (by reading Guixs own `commencement.scm` directly)

that this whole chain targets i686, not x86-64 regardless of host;

an i386 register-pair gap found and honestly set aside as real

open-ended compiler engineering; `tcc-boot0` through `tcc-boot9`

reaching two real byte-identical fixed points (one silently wrong on

floats one corrected); `tcc-0.9.27` self-hosting for real; then a

real historic GCC **2.95.3 not 4.0.4** (a correction made after

reading Guixs `commencement.scm` directly matching it exactly

rather than `fosslinux/live-bootstrap`s documented-but-different

chain) a real historic glibc

2.2.5 and four more compiler/library generations ending at exactly

gcc 4.9.4 and glibc 2.16.0. `$BOOTSTRAP_GCC`/`$BOOTSTRAP_GLIBC`/

`$BOOTSTRAP_BINUTILS`/`$BOOTSTRAP_AWK` referenced throughout

`self_hosting_os` are `c_compiler-77`s own real verified

output now not an assumed input, the real structural gap this

closes. `C_compiler` is now **77 live-verified steps** end to

end.

**`self_hosting_os` is now fully written:** 64 real

grounded steps, Parts D through N plus a real closing

pair (`self_hosting_os-63/64`: splits

glibc-final into Guixs own real `out`/`static`/`debug` outputs

verified with a real static link, a real dynamic link and a real GDB

session against the separated debug info). Parts D-N pick up

where `c_compiler-77` leaves off (gcc 4.9.4 on glibc 2.16 real and

built not assumed) and carrying that through two more compiler

generations and two more C libraries to a

complete modern self-hosting GNU toolchain, gcc 14.3.0 binutils

2.44, glibc 2.41 a real userland and Guile 3.0.9 reproducing the

real `mes-0.25.1-faithful-repro` build as course content. Every steps `<command>` is grounded in an

read vendored build script from

`assets/stage0/mes-0.25.1-faithful-repro/build-scripts/` not

reconstructed from memory. Covers: the mesboot6/boot0tools bootstrap

chain, the cross gcc-14/binutils-2.44 pair, buildtools (m4 through

Python including a silent-missing-module bug) glibc 2.41

(cross, then final) gcc-finals own real three-stage native bootstrap

with a `compare` a full nptl/test-suite failure analysis (the same

`libgcc_s.so.1` forced-unwind diagnostic this project used on the

previous milestones glibc 2.16 applied here to glibc 2.41 plus a

real tested hypothesis about the 29 failures that diagnostic does

NOT fix) bash-final/guile-final/ld-wrapper/locales the real final

userland (Guixs own `%final-inputs` set) with upstream test suites

and a reference-hygiene audit the two from-scratch reproducibility

reruns (including a real bug found on rerun re-told as course content) and

the closing `gcc-toolchain` union-build. Closes with a milestone-level

note on whats NOT included (init, boot, a package

manager, real open-ended research past this point not more fixed

steps); Zig/Rust, by explicit instruction live only in

`curriculum-prompt.js`s own rule 7 not here.

namespaces is now fully written ( research and one grounding measurement): 31 real steps covering every primitive a container runtime is actually built from the real unshare -pfmuni --mount-proc combined-namespace demo under doas escalation (this milestones deliberate privileged-not-rootless choice) pivot_roots real mechanics including the honest gotcha that it supplies no rootfs by itself a user-namespace uid-mapping contrast real environment sanitization (env -i clears HOME but not PATH) cgroups v2 resource limits taught in the deliberately-honest order (memory.max alone fails memory.swap.max=0 fixes it) a real cgroups-sizing methodology grounded in an actual measured number (792 MiB peak to compile self_hosting_oss own largest file, insn-recog.cc with the exact compiler that milestone produces a genuine cross-milestone data point, not an invented demo value) and a full PID-1 zombie-accumulation arc that tries the obvious approach first (a plain shell as PID 1) finds it doesn't actually reproduce the classic failure (BusyBox ashs own job control incidentally reaps reparented orphans) and then builds the genuinely minimal non-shell PID 1 that does. Beyond deliberately has no fixed steps (README: " high as the learner goes... Not a requirement") the tutor improvises there against the curriculum prompt.

## Parser

parse.js (fast-xml-parser). Validates the file: unique milestone ids, every required explanation field present on every step no unknown scaffolding mode, no unknown step type, a real <checksum algo="..."> on every type="seed" step, a runnable <command> on every step. It also cross-checks against noob-file-schema/example-MEMORY.md every milestone id that fixtures milestones map references must exist in the syllabus proving the two pieces actually agree, not just were designed to.

```sh

npm install

node parse.js

```

Result: parses 4 milestones, 10 steps the cross-check against the noob-file fixture passes. Validation was also checked against malformed input (a step missing a required field a duplicate milestone id) both correctly rejected.

Result: parses 6 milestones now. The new type="seed" steps <checksum algo="sha256"> round-trips through fast-xml-parser correctly (confirmed the parsers actual #text-plus-attributes shape live not assumed). Validation checked against three malformed cases each correctly rejected with a distinct message: a type="seed" step with no <checksum> at all one whose <checksum> has no algo attribute (confirmed this is a real reachable branch and not dead code, a bare <checksum>text</checksum> with zero attributes collapses to a plain string in this parser, not an object so the test had to force an unrelated attribute onto the tag to reach the actual missing-algo check) and an unrecognized step type.

Result: assembler gained a real step closing an earlier open item on hex0s real invocation. Hex0s actual C reference source to get the real argv[1]/argv[2] contract and byte-level algorithm, then reproduced the real Phase 0 self-check live: ran the vendored hex0-seed binary (assets/stage0/) against its own vendored human-readable annotated source and the rebuilt binary came back byte-for-byte identical to the seed (same sha256). Re-verified a time by extracting the exact command string as written in syllabus.xml (entities decoded) and running it verbatim in a clean directory same result. See assets/stage0/README.md for the vendored files real provenance and license (GPL-3.0-or-later party doesn't apply to the rest of this repo).

Result: assembler gained two real steps, hex1 and hex2 same treatment. Fetched hex1.c/hex2.cs real C reference. The real projects own orchestration script for the exact real Phase 1/Phase 2 commands (not reconstructed from prose). Live-built hex1 from its vendored source via hex0-seed then hex2-0 from its real vendored source via the freshly-built hex1 both real valid ELF executables, both rebuilt a second time and diffed byte-for-byte identical. Confirmed the 4-command sequence as written in syllabus.xml runs clean end to end in a fresh directory. Also confirmed live that neither output needs a manual chmod +x (hex0s chmod(argv[2] 0700) already does it) avoided writing a redundant command into the syllabus.

Result: assembler gained three real steps, catm, M0 and cc_amd64 closing out Phases 0-4 before M2-Planet. Fetched M0-macro.c for M0s algorithm (a genuine mnemonic-macro preprocessor, not just "hex2 with more features") and the real orchestration script for the exact commands. Live-built catm then M0 (confirming live that the real M0 binary unlike its C reference prototype takes the same file-pair CLI shape as every earlier tool) then cc_amd64 and functionally exercised it by compiling a real int main() { return 42; } getting exactly correct output at both the mnemonic and machine-code level. Found and documented, not glossed over: linking that output standalone fails with a Exec format error " since nothing provides a _start that calls main correctly outside cc_amd64s own scope the job the real chains libc-core.M1 does phases later. Confirmed the 7-command sequence as written in syllabus.xml runs clean end to end in a fresh directory.

Result: assembler gained its two steps, M2-Planet (Phase 5) closing the milestone entirely. Fetched M2-Planets real complete 9-file compiler source. M2libcs real 3-file platform support (8871 lines combined) and the real libc-core.M1 runtime-startup file (closing an open item confirmed by reading it: sets up argv/envp calls main exits with its return value). Compiled M2-Planets own source with cc_amd64 in under a second linked a 200792-byte ELF, rebuilt and diffed byte-for-byte identical. Then used the self-hosted M2-Planet to compile, link (with the libc-core.M1 this time). Actually run the same return 42 test program, real exit code 42 the first binary in the whole ladder verified end to end not just built. Confirmed the full 9-step sequence, zero manual chmod anywhere runs clean start to finish in a fresh directory.

Result: c_compiler opened for real with its 6 steps. Corrected the chain against the actual current fosslinux/live-bootstrap steps/ directory (146 total package steps): mes-0.27.1 -> tcc-0.9.26 -> tcc-0.9.27 -> gcc-4.0.4 -> gcc-4.7.4, not the placeholder comments "GCC 2.95.3". Found a substantial phase the original homework never accounted for: stage0-posixs own further self-hosting bootstrap of mescc-tools and M2-Mesoplanet (a gcc-like driver) sitting between M2-Planet and Mes 10 more real phases, all live-built from the already-vendored assembler toolchain functionally proven by using the finished M2-Mesoplanet to compile and run a real program in one command (exit code 42).. Fixed two real bugs live: a path mix-up between two different real files that both happen to be named amd64_defs.M1/libc-core.M1 (one at level from stage0-posix-amd64, a fuller one under M2libc/amd64/) that first manifested as apparent non-determinism in a rebuilt binary; and a real name collision between the flat vendored layouts M2-Mesoplanet/M2-Planet source directories and the binaries those same names need to be built to fixed by building those two specific tools into a bin/ subdirectory matching the real projects own convention. Also locks the pedagogy split first raised as a question: c_compiler-01 through -06 stay hand-typed (fast self-contained no downloads, same shape as assembler); from Mes onward steps switch to trigger-the-real-build-and-verify-by-diff since real package builds there are hours-plus need external tarballs and run their own nested build scripts hand-typing stops being practical past that real scale boundary, not, at an arbitrary milestone line. Confirmed the exact corrected

A 15-step process (from assembler-01 to c_compiler-06) ran from a start in a new directory that only had the downloaded project files.

Result: c_compiler added 5 steps (08 through 12) Mes itself the first real live-bootstrap package step. Downloaded the Mes/nyacc tarballs checked the fingerprints against the real list and unzipped them using this projects own tools. Found and fixed two issues before writing any code: M2-Planet at HEAD creates an addressing mode that Mess own opcode table does not support (fixed by rebuilding M2-Planet from stage0-posixs actual pinned commit, bd2fe4b0); the execution of Mess real orchestration script by kaem sometimes wrongly says success is failure on one large real run (fixed by running the same four commands directly which worked reliably in several clean-room runs). Built mes-m2, a Scheme interpreter self-hosted through the whole chain back to the 229-byte seed and it actually ran real Scheme. Used it to make the nyaccs C99 grammar (8 files under 5 minutes total) fixing this milestones earlier "hours-plus" worry with actual time measurements. Re-checked the fixed 21-step process (assembler-01 through c_compiler-12) from a clean directory twice after fixing both issues.

Result: c_compiler added a 13th step, Mess C library, completed with mescc (Mess own C compiler, a Scheme program run by mes-m2) compiling and making crt1.o, libc-mini.a libmescc.a libc.a and finally libc+tcc.a (132576 bytes combining all the earlier libraries inside it) the real target pass1.kaem. Ran the same command from a completely new directory: identical output, byte-for-byte. C_compiler is now 13 steps; installing Mes into a location and checking against the real published fingerprints is next before TinyCC.

Result: c_compiler added a step completing Mes entirely installed mes-m2, mescc.scm all the libraries both real ELF linker templates and about 65 real headers into a real location then checked all 12 real binary/library files against the actual officially published mes-0.27.1.amd64.checksums fetched fresh from fosslinux/live-bootstrap. All 12 matched not a self-consistency check, a match against an artifact this session never touched. One real checked mismatch (mescc.scm, a text template) proven not functional: every output it helped make matches the real project perfectly. Re-ran the install+checksum command from a completely new directory: same 12-of-12 result. C_compiler is now 14 steps; Mes is done, TinyCC (tcc-0.9.26) is next.

Result: c_compiler added two steps, opening TinyCC. Built tcc-mes, a separate real C compiler, self-hosted through this projects whole chain via mescc/mes-m2 rather than the M2-Planet line. Proven to work: tcc-mes -version shows the real version string; tcc-mes -c ret42.c -o ret42.o compiles to an ELF object no catm/M0/hex2 pipeline needed. Found and handled three bugs as they happened: real run-to-run non-determinism in mesccs compilation of TinyCCs own 3.5MB source (a first for this project); a false failure in mesccs one-shot link mode (confirmed by running the exact failing M1 command directly which always works) fixed by pre-assembling with M1 first; and a real permission problem in the already-shipped c_compiler-14 (mes-m2s execute bit not reliably kept into the real location) fixed there directly since this was the first real use of the installed binary. C_compiler is now 16 steps; TinyCCs remaining work (a tcc-mes-linkable Mes libc rebuild, then boot0/boot1/boot2 self-hosting) is next.

Result: c_compiler added a step the 13 real utility programs from mescc-tools-extra (sha256sum, catm, untar, ungz...) built via the finished M2-Mesoplanet. Found and fixed a M2-Mesoplanet bug along the way: its file reader opens every #elif branchs #include target while scanning past it not just the one that is used so a header listing every supported architecture (, like sys/stat.h) stops the build if any sibling architectures file is missing regardless of which branch is actually used. Fixed by replacing the cherry-picked M2libc/ (built up file by file across earlier steps) with a full real checkout of oriansj/M2libc (106 files) matching how the real project actually uses it as a git submodule. Confirmed no regression by re-running the prior 15-step process before adding the new step. Verified all 13 tools functionally not just compiled them: sha256sum matches the hosts own; ungz matches gunzip on a real.tar.gz; untar correctly extracts that same real nested tarball. C_compiler is now 7 steps; Mes is the milestones remaining open item.
