# Manual

This is the short version of "how do I actually start." No

theory here. See `README.md` for what thiss why, `Bootstrap.md`

for how the curriculum itself got built. Just the steps.

## 1. Get the guest VM

Every learner runs inside their disposable Alpine Linux VM from

the very first exercise. Two ways to get one:

**Fastest: grab the prebuilt image.** This repos Releases page has a

to-go `golden-base.qcow2` with its own real already-set root

and learner credentials, listed right there in that releases notes.

Download it skip straight to step 2.

**. Build your own.** Useful if you want your credentials from

the start or just want to see the install happen. You build one

image once then each learner gets their own private copy of

it.

```sh

cd vm-build

qemu-img create -f qcow2 base.qcow2 4G

python3 build-golden.py golden-base.qcow2

```

That drives the real Alpine installer end to end, keymap, network,

timezone, disk target, the works using known test credentials by

default. For anything beyond a local test set real ones first:

```sh

NOOB_ROOT_PASSWORD=<something real> \

NOOB_USER_PASSWORD=<something real> \

python3 build-golden.py golden-base.qcow2

```

Every image built this way has different passwords if you set these

per build. Don't ship the hardcoded credentials to more than one

learner. Takes a couple of minutes; when its done you have a

bootable `golden-base.qcow2`.

I never touch `base.qcow2` directly after this. Its real

credentials written down below. Testing or

debugging needs its fresh disposable copy, built the same way.

PS: PW for the user in the alpine buid are below. Root

REDACTED-ROOT-PW

user: noob

REDACTED-USER-PW

## 2. Launch the app

```sh

cd app/electron

npm install

npm start

```

With nothing set thats a local dev shell, useful for working

on the app itself not a real learner session. To actually run against

the guest VM:

```sh

NOOB_VM_DISK=/path/to/base.qcow2 \

NOOB_VM_USER=noob \

NOOB_VM_PASSWORD=<the password you set above> \

NOOB_INJECT_PROMPT=1 \

npm start

```

The app boots the real guest in the left pane logs in as `noob` and

greets you with a real status line, your own fade-out tier, which

milestone you're on, where you left off. The right pane loads a

Chromium tutor pane empty at first.

## 3. Log into your AI provider

The app never logs you in itself. That's deliberate. Click into the

right-hand pane. Log into whatever AI provider you're using

yourself the normal way, in your own browser tab, same as any other

site. Once your providers own real chat box is visible and ready to

type into the app. Injects the real curriculum prompt for

you. You don't paste anything.

If the tutor pane just sits there with nothing happening the

likely explanation is you're still on the providers own login screen

somewhere. Finish that first.

## 4. Start the course

Once the lands the tutors first real reply back is always

the same one line: `Ready for the course?` That's not a greeting.

It's confirmation the injection actually worked and the tutor read

the whole curriculum prompt correctly. From there just talk to it.

Exercise one is building a chroot jail by hand one command at a

time. The tutor gives you one line explains it and waits.

You can walk away. Come back later. Your own progress lives inside

your VM (`~noob/.noob/MEMORY.md`) not in the chat history of whatever

provider you happened to be using that day. Log back in relaunch

the app and the tutor picks up where you left off even on a

different provider than last time.

## If something goes wrong

There's no recovery flow on purpose. The whole design is

meant to stay legible enough that you can just look. The syllabus

itself is a file (`app/syllabus/syllabus.xml`); your own

progress file is plain text too readable with `cat`/`less` from

inside your own guest shell. If the tutor prompt injection fails

just ask the tutor directly what to do or read the files

yourself. Nothing, about this course is supposed to be a box,

including the parts that occasionally break.
