# app/electron, the real app shell

The real build. Consolidates `app-shell-prototype/`s two-pane

Electron window into the product wires it to the real syllabus

(`app/syllabus/`) and the real `noob`-user memory/config file, reached at

its real location inside a real guest over SSH (`guest-fs.js`) can

connect the left pane to a real QEMU guest (`vm.js`) instead of a

local shell can inject the real curriculum prompt

(`curriculum-prompt.js`/`tutor.js`) into the tutor pane and can run

all of it together as one real session (`session.js`).

- **Left pane**, a terminal (`xterm.js` + `node-pty`). Two

modes (`main.js` picks based on env vars see below): a real QEMU

guest or (no `NOOB_VM_DISK` set) a shell for dev work that

doesn't need a whole VM boot every time. Either way once a real

prompt is live it prints a session-status greeting built from

the real syllabus milestone list and the real noob-files

recorded progress (`state.js`).

- **Right pane** the tutor webview. With `NOOB_INJECT_PROMPT` set once the chat UI is ready it fills and sends the curriculum prompt, gated behind that env var since unlike the rest

of this file a real run sends a real message to whoevers logged

in. Login itself is never automated, by design: the learner logs

into their chosen provider. If the chat input never appears,

`tutor.js` times out and skips, on the assumption the learner

is still on the providers own login page.

## Running a full session

```sh

NOOB_VM_DISK=/path/to/a.qcow2 NOOB_VM_USER=noob NOOB_VM_PASSWORD=... \

NOOB_VM_SSH_PORT=10022 NOOB_INJECT_PROMPT=1 npx electron.

```

`session.js` drives the whole real session. It calls `vm.js` which spawns

`qemu-system-x86_64` inside the kind of pty the local-shell path

uses with a QEMU `hostfwd` rule exposing the real guest’s `sshd` (already

running by default) on `NOOB_VM_SSH_PORT`. Once logged in

`vm.js`s `installPublicKey` writes a keypair

(`guest-fs.js` generates it under `.dev-ssh-key/` gitignored, never

the users own `~/.ssh` key) into `~/.ssh/authorized_keys` via a

heredoc typed through the pty the same line‑line technique

`build-golden.py` uses for the answerfile. From there every read and write of the noob-file and real syllabus goes over real, non‑interactive, key‑based SSH: the real syllabus is always refreshed from the hosts canonical copy and the real noob-file is seeded from `noob-file-schema/example-MEMORY.md` only if the real guest does not already have one.

Point `NOOB_VM_DISK` at a per‑session overlay

(`qemu-img create -f qcow2 -F qcow2 -b <image> <session>.qcow2`)

never a golden image directly. There is no snapshotting here so

anything the real session does persists to whatever disk you point it at.

Without `NOOB_VM_SSH_PORT` set, `NOOB_VM_DISK` alone falls back to a

mode (a real guest but the host stand‑in noob-file path)

useful for testing the terminal and login wiring without the SSH

machinery.

## A real significant bug found building this

The first version of `guest-fs.js` used `spawnSync`/`execFileSync` for

every SSH call. Electrons main process is single‑threaded for JS so

each synchronous real SSH round‑trip blocked the real app, including

its own CDP/DevTools server for as long as that round‑trip took.

Found by a Playwright CDP connection timing out during that

window not by inspection. Fixed by rewriting every network call around

async `spawn`. A second bug, from the pass: `session.js` had

been written against the old synchronous API and never `await`ed the

new async calls, silently passing unresolved Promises into

`fs.writeFileSync`. Nodes own `UnhandledPromiseRejectionWarning`

caught it immediately on the test run.

## A real bug found building this

The first version sent the greeting into the shell as a echo '...'` command.

The command had embedded `\r\n` bytes inside the quotes.

The command caused a break immediately.

An interactive bash reading from a pty does its line editing.

That line editing treats an embedded `\r` or `\n` byte as an Enter keystroke even if it is inside a single quote.

So the command was split into wrong partial commands.

Fixed this by building the greeting as an array of lines and joining them with the two-character escape sequence `\n` inside a `printf` format string.

`Printf` processes backslashes in the format argument so the output still contains newlines but no raw bytes ever go through the pty input stream.

Escaped the %` because a provider URL could contain one and `printf` treats `%` as a conversion specifier.

## Running it

```sh

npm install

npx electron-rebuild   # node-ptys native module must match Electrons Node ABI

npx electron.

```

**Result (local-shell path):** live verified with a window on this boxs Wayland display.

The terminal pane printed the syllabus-and-noob-file-derived greeting as one clean block.

Then the terminal pane dropped to a working prompt.

This was confirmed real by the users own shell config surfaces a real error" signal used elsewhere.

The tutor pane loaded claude.ai's login page at the same time.

Both were shown together.

**Result (real-VM path):** built a disposable test VM via `build-golden.py` with known credentials.

Launched the app pointed at the VM and watched a real boot through the terminal pane with zero manual typing.

Alpines boot log, the login prompt, automatic `noob` login, the real greeting and a clean shell prompt.

Typed a command through the apps real input path and got back `3.24.1` / `uid=1000(noob)` / a distinct guest kernel.

Confirmed bytes trip through a genuinely separate machine.

**Result (curriculum- injection):** with an authenticated claude.ai session, filled and sent the real 2178-character curriculum prompt through the tutor panes actual chat input.

Got back Ready for the course?" showing the whole glass-box enforcement mechanism working end to end against the real provider.

Separately confirmed, from a fresh never-logged-in profile that a real login requires an email-verification step and the app does not try to automate the login.

The successful test rode on a session authenticated outside that test not one this app logged into itself.

Test profiles were deleted afterward.

**Result ( real session):** built a disposable per-session overlay from a golden image launched the app and watched a full real session bootstrap through the terminal pane with zero manual typing.

Saw boot, login the SSH key install heredoc and the greeting.

Independently confirmed from the host over ssh` that the syllabus (124 real lines) and the noob-file both genuinely exist inside the guest.

Typed the syllabuss first two `chroot` steps through the apps own terminal-input path and confirmed via SSH that they created real files.

Then  used `guest-fs.js`s write function to update the noob-file and re-read it back over SSH.

The same append-, vs-overwrite behavior and YAML-date-coercion quirk found in isolation was now reproduced against a remote file.

Test overlay, image and Electron profile were all deleted after.
