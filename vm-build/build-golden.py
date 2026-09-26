#!/usr/bin/env python3
"""
Non-interactive golden-image build: drives setup-alpine's
prompts that the answerfile can't cover -- root password, user
creation, that user's password, ssh key, disk-erase confirm -- via
pexpect. Boots the installer ISO against a target qcow2,
types the answerfile onto the guest over the serial console (no
shared folder is configured), runs setup-alpine, answers every
remaining prompt, then powers off.

Usage: build-golden.py <target.qcow2>

Root and noob passwords come from NOOB_ROOT_PASSWORD/NOOB_USER_PASSWORD
-- every image built this way sharing the same hardcoded
password (as earlier versions of this script did) would mean one
learner's copy leaking compromises every other learner's copy too.
Falls back to fixed test values if unset, for quick disposable-VM use.
"""
import os
import sys
import pexpect

ISO = "alpine-virt-3.24.1-x86_64.iso"
ANSWERFILE = "answerfile"

if len(sys.argv) < 2:
    print(f"usage: {sys.argv[0]} <target.qcow2>", file=sys.stderr)
    sys.exit(1)

DISK = sys.argv[1]
# Deliberately not derived from the username: Alpine's passwd warns
# ("Bad password: similar to username") on e.g. root/rootpass --
# harmless, but avoidable noise in the transcript.
ROOT_PASSWORD = os.environ.get("NOOB_ROOT_PASSWORD", "TuringTape7")
NOOB_PASSWORD = os.environ.get("NOOB_USER_PASSWORD", "SolderIron9")

qemu_cmd = (
    f"qemu-system-x86_64 -m 1024 -smp 2 -enable-kvm "
    f"-drive file={DISK},format=qcow2,if=virtio "
    f"-cdrom {ISO} -boot d -nographic "
    f"-netdev user,id=n0 -device virtio-net-pci,netdev=n0"
)

child = pexpect.spawn(qemu_cmd, timeout=180, encoding="utf-8")
child.logfile = sys.stdout

child.expect("login:")
child.sendline("root")
child.expect("~#")

with open(ANSWERFILE) as f:
    contents = f.read()
child.sendline("cat > /tmp/answerfile << 'NOOBEOF'")
for line in contents.splitlines():
    child.sendline(line)
child.sendline("NOOBEOF")
child.expect("~#")

child.sendline("setup-alpine -f /tmp/answerfile")

# root password: two "New password:"/"Retype password:" prompts,
# matched on their distinct wording -- a generic "(?i)password" on
# both ends up racing across prompt boundaries, which caused a real
# timeout on the first live attempt at this script.
child.expect("(?i)new password")
child.sendline(ROOT_PASSWORD)
child.expect("(?i)retype password")
child.sendline(ROOT_PASSWORD)

child.expect("(?i)setup a user")
child.sendline("noob")
child.expect("(?i)full name for user")
child.sendline("")  # accept the offered default
child.expect("(?i)new password")
child.sendline(NOOB_PASSWORD)
child.expect("(?i)retype password")
child.sendline(NOOB_PASSWORD)
child.expect("(?i)ssh key")
child.sendline("none")
child.expect("(?i)erase")
child.sendline("y")

child.expect("~#", timeout=120)
child.sendline("poweroff")
child.expect(pexpect.EOF, timeout=60)
print("\n--- build-golden.py: install completed, guest powered off ---")
