// Wires the terminal pane to a real QEMU guest instead of a local
// shell. Spawns qemu-system-x86_64 itself inside a real pty -- the
// exact same architecture already used for a local shell, just a
// different command, so nothing about the xterm.js/IPC wiring on the
// renderer side changes.
//
// Drives the guest's login prompt the same way build-golden.py
// drives setup-alpine's: watch the byte stream for known
// text, respond once, move on. A single login (unlike setup-alpine's
// several near-identical "New password"/"Retype password" prompts)
// has exactly one occurrence each of "login:" and "Password:", so a
// plain substring check is safe here -- build-golden.py hit real
// trouble matching on a generic colon-ended prompt instead (a match
// landed on the wrong occurrence several prompts later and hung), but
// that risk only exists when several near-identical prompts share the
// same generic shape, which isn't the case for a single login.
const pty = require('node-pty');

function spawnGuest({ diskPath, username, password, sshHostPort, onData, onLoggedIn }) {
  const netdev = sshHostPort
    ? `user,id=n0,hostfwd=tcp::${sshHostPort}-:22`
    : 'user,id=n0';
  const child = pty.spawn(
    'qemu-system-x86_64',
    [
      '-m', '1024',
      '-smp', '2',
      '-enable-kvm',
      '-drive', `file=${diskPath},format=qcow2,if=virtio`,
      '-nographic',
      '-netdev', netdev,
      '-device', 'virtio-net-pci,netdev=n0',
    ],
    { name: 'xterm-256color', cols: 100, rows: 40, cwd: process.cwd(), env: process.env },
  );

  let stage = 'login';
  let tail = '';

  child.onData((data) => {
    onData(data);
    tail = (tail + data).slice(-500);
    if (stage === 'login' && tail.includes('login:')) {
      stage = 'password';
      tail = '';
      child.write(`${username}\r`);
    } else if (stage === 'password' && /password:/i.test(tail)) {
      stage = 'prompt';
      tail = '';
      child.write(`${password}\r`);
    } else if (stage === 'prompt' && /:~\$\s*$/.test(tail)) {
      stage = 'done';
      onLoggedIn(child);
    }
  });

  return child;
}

// Installs a host-provided SSH public key into the guest's
// authorized_keys, using the same technique build-golden.py
// uses to type the answerfile onto a guest: a heredoc sent as several
// separate writes, one real Enter (\r) per line. This is NOT the same
// situation found broken elsewhere (embedding raw \r\n *inside* a single
// quoted argument, mid one-line command) -- a heredoc is genuinely
// multi-line input, so a real Enter between each line is exactly what
// a human typing it would send too.
function installPublicKey(guestPty, publicKey) {
  guestPty.write('mkdir -p ~/.ssh && chmod 700 ~/.ssh\r');
  guestPty.write("cat >> ~/.ssh/authorized_keys << 'NOOBKEY'\r");
  guestPty.write(`${publicKey.trim()}\r`);
  guestPty.write('NOOBKEY\r');
  guestPty.write('chmod 600 ~/.ssh/authorized_keys\r');
}

module.exports = { spawnGuest, installPublicKey };
