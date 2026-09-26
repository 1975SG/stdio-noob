# Bootstrap

What I actually did to get from a 229-byte seed to a real self-hosting GNU toolchain, gcc, binutils, glibc, the works with nothing at any point taken on faith. Every claim below is something I ran on hardware and checked. This is the version: what worked what didn't what I got wrong along the way and had to retract and what I still don't have a guarantee on.

## What I was trying to do

Trace a toolchain back to something small enough to actually audit by eye. Not "download gcc. Trust the binary." Start from a 229-byte hex0 seed (a published trust root, `oriansj/bootstrap-seeds`) hand-verify its checksum and build every single stage above it myself checking each one against a real oracle before trusting it enough to build the next. Hex0 to hex1 to hex2 to M2-Planet all hand-typed and checked. Then a real C library (Mes) a real C compiler self-hosting from that then real historic GCC versions climbing one generation at a time up to a modern gcc 14 toolchain that can rebuild itself byte-for-byte.

The rule throughout: if I can't verify it against something a checksum a trusted reference build a programs own correct output I don't get to call it done.

## The real fork in the road: TinyCC wouldn't self-host

Mes went fine. Real Scheme interpreter, self-hosted and the install matched all 12 of the published checksums exactly the strongest proof I'd gotten up to that point.

Then I tried to get Mess own C compiler (`mescc`) to compile TinyCC against itself so TinyCC could take over as the working compiler. This is where it fell apart the time. Compiling TinyCCs source as one big file worked, mostly but trying to get the *result* to compile its own C library or its own source a second time crashed. Not a clean error. A segfault, inside the compiler that moved around depending on what else was going on in the binary. Add a function somewhere else in the file and the crash relocates. That's the kind of bug to chase.

I spent a time on this. Found and fixed one bug (Mess own compiler had no idea how to compute struct/union field offsets correctly when the fields had mixed sizes it just summed sizes with zero alignment padding so anything indexed off a struct pointer read from the wrong offset). Fixed that verified it byte-for-byte against a reference build. The original crash was gone.

Then I hit a *different* crash. Past the one in a different function same "only wrong at real scale" shape:

```

tccpp.c:216: error: 64 bit addend in load

```

I didn't solve this one. I want to be straight about that I tried, found nothing and moved on with it honestly marked as blocked. If you're reading this because you hit something that specific line, that specific error, from that specific compiler version on that specific build recipe. I never got past it.

## Where the real answer actually was

Here's the thing I got wrong at first: I assumed the version of Mes I was using and the way I was compiling TinyCC (one amalgamated source file, `ONE_SOURCE=1`) were the right defaults. They're not. Reading Guixs real build recipe directly not a summary of it the actual script, turned up two things I'd been getting wrong:

1. The Mes version Guix actually pins for this stage is older than the one I'd started with. A different codebase, not just a version bump.

2. Guixs own default is to compile TinyCCs real source files **, not as one amalgamated blob. The one-big-file approach I'd been using the time is Guixs own non-default less-tested alternative.

Once I switched to the version and the right build shape, a whole category of "only wrong at real scale" bugs simply stopped happening. Not because I fixed them because the giant-file compile was triggering compiler state that never got exercised the way. That's a useful lesson on its own: if your own setup diverges from a projects documented default "just because it should also work " and you hit something that looks impossible to pin down check whether you're actually still on the happy path.

From there the *real* bugs (there were several once the giant-file artifact was out of the way) were genuinely fixable one at a time:

- A bug in the compilers own struct-copy handling, a specific C idiom (declare a struct-typed local initialize it with a plain expression rather than a `{...}` list) silently truncated the copy to one registers width instead of copying the whole struct. Rare in a test program. Constant in a compilers own code because its exactly how you'd naturally write a value-swap.

- A genuine upstream bug in TinyCC itself not the bootstrap chain. Its own linker built a PLT stub for a linked binary calling an ordinary function and then never patched it with the real address because the patching code was accidentally gated behind a check thats only true for dynamic linking. I only trust this diagnosis because I checked it against TinyCC built by a different independently-trusted compiler doing the identical broken thing. That's what tells you the bug is real and upstream not a symptom of your bootstrap chain.

- A sign-extension bug: a value getting sign-extended instead of zero-extended in one specific code path so a loop that should shift a value down to zero instead converged on all-ones and spun forever.

- A interesting side discovery: the whole chain on my own x86-64 machine is supposed to target a 32-bit architecture the whole way through even while running as real 64-bit code on a real 64-bit host. I'd assumed "runs on x86-64" meant "targets x86-64." It doesn't this early in the chain. Once I built for the right target instead a whole family of confusing type-size errors (`Elf64_Addr` showing up somewhere it had no business being referenced) simply stopped existing.

Once all of that was sorted the compiler reached what I actually consider the milestone: it could compile a fresh copy of itself and that fresh copy could compile *another* fresh copy and the two outputs were byte-for-byte identical. That's the proof a self-hosting compiler is doing its job correctly not "it seems to work " a literal `cmp` with zero differences between two generations that never touched each others source.

## Building up through historic compilers

From a working self-hosting TinyCC the climb was building real historic GCC versions one on top of the last each one compiled by the previous each one checked against an independent reference before I trusted it to build the next:

- A real gcc 2.95.3 old enough that it can't even emit 64-bit code so it had to be built as a cross-compiler at first (64-bit host, 32-bit target) then rebuilt a second time as a genuinely native 32-bit compiler once there was a real 32-bit C library to build it against.

- A real historic glibc (2.2.5) built by that compiler checked with real test programs against the hosts own modern glibc, printf, math functions, threads, signals, the works, matched line for line.

- gcc 4.6.4 next the first one in the whole chain that isn't from the late 90s/early 2000s and the first real C++ support anywhere in this chain.

- A glibc (2.16) then finally a gcc 4.9.4 with real shared libraries and a shared C++ runtime, the actual real destination this whole climb was building toward.

The single useful debugging technique across this entire stretch was always the same one: build the identical unmodified source with a completely independent already-trusted compiler and diff the output. Any real difference is a bug in *my* chain. Anything that fails identically in both is not my bug all it's something, about the source itself or the environment and chasing it further is wasted time. I used this constantly. Its the only reason some of the harder bugs above were findable at all instead of just "weird, moving on."

**One methodology mistake, worth naming honestly**: partway through I found that two of my own "verification" comparisons had silently been checking nothing at all. A command I was using to

extract one section of a binary for comparison was, because of how I invoked it writing to a file literally named `-` instead of to its output stream so both sides of the comparison were comparing empty input against empty input and "agreeing" every time. The real lesson: a check that can ever report "same" is worthless. Every comparison I trust now has to be provably capable of failing. I confirmed the fixed version by running it against a pair I already knew had to differ, before trusting it on anything

## The climb and where it stands today

From that gcc 4.9.4 baseline the rest is a more conventional (if still fully from-scratch) climb: a cross-built gcc 14 targeting the same platform, a real userland (coreutils, bash, make, grep, sed, tar and the rest all built from source through this same chain) Guile 3 and a final natively self-hosting gcc 14 toolchain that reproduces itself just like the very first self-hosting TinyCC did, a real `stage2 == stage3` bootstrap comparison, byte for byte.

I ran the reconstruction from scratch a second time independently specifically to prove the recipe itself is reliable and not just something that happened to work once. That rerun found two real bugs neither of the first attempts had caught including a genuinely embarrassing one where a wrapper script accidentally aliased four different real compiler tools (`gcc` `g++` `cpp` and the plain `cc` alias) to the exact same binary, which stayed invisible the entire time because `gcc` and `cc` happen to be the same real program until something downstream genuinely needed the *other* two and silently got the wrong tool instead.

I also went back. Split glibcs own build output into the real separate pieces a proper Linux distribution actually ships. The runtime itself its debug symbols and its static libraries each independently installable than one big merged directory. Verified with a real debugger session finding and using the separated debug info on a fully stripped binary not just "the files are there."

## What I'm honest is NOT guaranteed

- **The known nptl (thread) test failures were never fully closed.** glibcs own real test suite at every stage I ran it has a fairly small percentage of thread-related tests that fail for reasons I could only partially explain. Some environmental (a virtual-memory ceiling that moves depending on system load, ASLR and how much else is running on the machine at the time) some genuinely still unexplained. This is named honestly everywhere it shows up. Its not swept under anything.

- **The 32-bit targets own 64-bit-value handling has a unfixed gap** in the earliest most minimal compiler stage something that would need real open-ended compiler engineering to properly fix, not a quick patch. I found it understood exactly what was missing and deliberately did not attempt to fix it because the 64-bit-hosted line of this chain doesn't need it and never hits the wall.

- **None of this has been run on period hardware.** Every single stage of this ran on a fast 64-bit machine using modern tools to drive it (a modern kernels own 32-bit compatibility mode for anything that had to run as genuine 32-bit code). It is not a claim that this exact sequence reproduces cleanly on the kind of machine this software actually shipped on originally.

## A disclaimer worth saying plainly

If you're thinking about reproducing any of this yourself on a modern machine, the biggest source of real hard-to-predict trouble was never the actual bootstrap logic. It was the size and shape of the gap between a 64-bit system and the 32-bit much simpler hardware and toolchains this software actually assumed when it was written. Struct layouts, register conventions, syscall ABIs kernel header assumptions, basic things like whether a C library treats a given type as 4 or 8 bytes all of it can differ in ways that don't show up as an obvious error just as a program that runs and produces the wrong answer.

Do research into your own specific host/target combination before you start not after something breaks in a confusing way. The single useful thing I did over and over was going back to read a real authoritative build recipe directly instead of trusting my own summary of it and independently verifying every real claim against hardware I could actually observe. That habit is worth more than any fix, in this whole writeup.
