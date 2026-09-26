# Building the golden Alpine image

Fedora 44, QEMU 10.2.2, KVM is installed on. This is the manual, repeatable recipe. Also, it has been automated, here is the code: `build-golden.py`, `pexpect` script that interacts with every prompt from `setup-alpine` despite the answerfile being there:

```sh
qemu-img create -f qcow2 golden-base.qcow2 4G
python3 build-golden.py golden-base.qcow2
```

These are the steps actually performed by the script in question. Read through them if you are modifying the answer file, working with the script itself, or just doing a manual installation.

## 1. Fetch the installer ISO

```sh
curl -sO https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64/alpine-virt-<version>-x86_64.iso
curl -sO https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64/alpine-virt-<version>-x86_64.iso.sha256
sha256sum -c alpine-virt-<version>-x86_64.iso.sha256
```

## 2. Create the disk

```sh
qemu-img create -f qcow2 golden-base.qcow2 4G
```

## 3. Boot the installer

```sh
qemu-system-x86_64 -m 1024 -smp 2 -enable-kvm \
  -drive file=golden-base.qcow2,format=qcow2,if=virtio \
  -cdrom alpine-virt-<version>-x86_64.iso -boot d \
  -nographic \
  -netdev user,id=n0 -device virtio-net-pci,netdev=n0
```

Log in as `root` (no password on the live ISO).

## 4. Put `answerfile` (this directory) on the guest and run setup

The answerfile handles all these: keymap, hostname, network, timezone, proxy, mirror, sshd, ntp, and disk target, but **the `setup-alpine` will ask interactively** for the following: the root password (twice), whether a user will be created (enter `noob`), user's name (enter default), user's password (twice), SSH key for that user (just enter `none`), and lastly whether to erase the disk (yes/no). It is not possible to automate this through the answer file unless you have some serial console automation tool (expect, pexpect, etc.).

```sh
setup-alpine -f /tmp/answerfile
```

Restart when installation is completed (`poweroff` from the installation session is sufficient; next boot will go right into the hard drive).

## 5. Boot the installed disk standalone (no `-cdrom`) and verify

```sh
qemu-system-x86_64 -m 1024 -smp 2 -enable-kvm \
  -drive file=golden-base.qcow2,format=qcow2,if=virtio \
  -nographic \
  -netdev user,id=n0 -device virtio-net-pci,netdev=n0
```

The absence of ISO when the user encounters the "noob-base login:" message confirms that the image is really self-contained. Login with "noob".

## 6. What was actually verified live

- `noob` is an actual `uid=1000` user who belongs to the `wheel` group.
- `doas` is setup (`permit persist :wheel` in `/etc/doas.d/20-wheel.conf`), `noob` uses **his/her** own password to escalate privileges.
- Exercise 1 in reality: `doas apk add --root ~/myjail --initdb -X <mirror>/main alpine-base` builds a minimal rootfs (requires copying `/etc/apk/keys/*` from the host to the target root, otherwise each fetch will fail due to `UNTRUSTED signature`), 27 packages, about 10 MiB. Then `doas chroot ~/myjail /bin/sh` allows entering a totally different file system (`cat /etc/alpine-release` within the jail). The jail is deleted after that to keep the golden image pristine for each learner.

## Resolved: run-the-bootstrap-command, not a tarball

An the earlier draft here mentioned that the rootfs was a pre-built tarball that had to be extracted; however, that wasn’t how the verification step 6 above works: the learner executes the actual `apk --root --initdb` bootstrap command themselves. That’s the way it stayed: running the bootstrap command by the learner won.

## Automation notes

The `build-golden.py` script types the answerfile on the guest itself as a heredoc through the serial console connection (no shared folder is defined), then answers the remaining prompts of the `setup-alpine` command based on its specific wording, not general punctuation. `"Full name for user noob [noob]"` does not have a colon at the end, and using a more flexible matching for this prompt resulted in the desynchronization of all subsequent prompts on the first real attempt. The test passwords used by the script are also not derived from the respective usernames: Alpine’s `passwd` command complains `Bad password: similar to username` when trying to use `rootpass` password for the `root` user; this prompt will not be expected by the script, and it will result in the desynchronization as well.
