// Reaches into a real guest's filesystem over SSH -- the answer to
// where the noob-file actually lives and how the host reaches it.
// sshd is already running in the golden image by default (confirmed
// live during the guest-VM build work); a
// QEMU hostfwd rule (vm.js) exposes it on a host port, and a dedicated
// keypair (generated here, never the user's own) gets installed into
// the guest via the pty right after login (vm.js's installPublicKey),
// so every later SSH call is non-interactive and password-free.
//
// Every network call here is async (spawn, not spawnSync/execFileSync)
// on purpose: Electron's main process is single-threaded for JS, and a
// synchronous subprocess call blocks that whole process -- including
// its own CDP/DevTools server -- for as long as the SSH round-trip
// takes. A first version used spawnSync throughout and froze the
// entire app for several seconds during every guest-fs operation,
// found by a CDP connection timing out during exactly that window.
const fs = require('fs');
const path = require('path');
const { execFileSync, spawn } = require('child_process');

const KEY_DIR = path.join(__dirname, '.dev-ssh-key');
const KEY_PATH = path.join(KEY_DIR, 'id_ed25519');

// BatchMode=yes is the important one here: without it, a connection
// attempt that can't authenticate via the key (e.g. during the
// polling window before installPublicKey's write has landed) falls
// back to an interactive password prompt -- which, with a real
// display available, means OpenSSH launches a genuine ssh-askpass GUI
// dialog and then hangs forever waiting for a human who was never
// going to see it as part of an automated flow. Found live: two such
// dialogs sat open on screen after a test run, each holding a stuck
// `ssh ... true` process from waitForSsh's polling loop.
const SSH_OPTS = ['-o', 'StrictHostKeyChecking=no', '-o', 'UserKnownHostsFile=/dev/null', '-o', 'LogLevel=ERROR', '-o', 'BatchMode=yes'];

// A dedicated keypair for this app to reach guests it manages --
// deliberately never the user's own ~/.ssh key. Generated once and
// reused; gitignored, since it's a real (if low-stakes) credential.
// A one-off local ssh-keygen call is fast enough that staying
// synchronous here doesn't cause the blocking problem described above.
function ensureKeypair() {
  if (!fs.existsSync(KEY_PATH)) {
    fs.mkdirSync(KEY_DIR, { recursive: true });
    execFileSync('ssh-keygen', ['-t', 'ed25519', '-N', '', '-f', KEY_PATH, '-C', 'stdio-noob-app'], { stdio: 'ignore' });
  }
  return {
    privateKeyPath: KEY_PATH,
    publicKey: fs.readFileSync(`${KEY_PATH}.pub`, 'utf8'),
  };
}

function sshArgs(port, user) {
  return ['-i', KEY_PATH, '-p', String(port), ...SSH_OPTS, `${user}@127.0.0.1`];
}

// Runs one ssh command asynchronously, optionally piping stdin, and
// resolves with { code, stdout, stderr } rather than throwing --
// callers decide what a non-zero exit means for them.
function runSsh(args, input) {
  return new Promise((resolve) => {
    const child = spawn('ssh', args);
    let stdout = '';
    let stderr = '';
    child.stdout.on('data', (d) => { stdout += d; });
    child.stderr.on('data', (d) => { stderr += d; });
    child.on('close', (code) => resolve({ code, stdout, stderr }));
    if (input !== undefined) child.stdin.end(input);
    else child.stdin.end();
  });
}

// Polls until the guest actually accepts an SSH connection with the
// installed key -- sshd being reachable and the key actually being
// installed and picked up are two different real moments, and this
// waits for the second one, not just the first.
async function waitForSsh({ port, user, timeoutMs = 20000, intervalMs = 1000 }) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const { code } = await runSsh([...sshArgs(port, user), '-o', 'ConnectTimeout=3', 'true']);
    if (code === 0) return true;
    await new Promise((r) => setTimeout(r, intervalMs));
  }
  return false;
}

async function readRemoteFile({ port, user, remotePath }) {
  const { code, stdout } = await runSsh([...sshArgs(port, user), `cat ${remotePath}`]);
  if (code !== 0) return null;
  return stdout;
}

async function writeRemoteFile({ port, user, remotePath, content }) {
  const remoteDir = path.posix.dirname(remotePath);
  const mkdir = await runSsh([...sshArgs(port, user), `mkdir -p ${remoteDir}`]);
  if (mkdir.code !== 0) throw new Error(`writeRemoteFile mkdir failed: ${mkdir.stderr}`);
  const write = await runSsh([...sshArgs(port, user), `cat > ${remotePath}`], content);
  if (write.code !== 0) throw new Error(`writeRemoteFile failed: ${write.stderr}`);
}

module.exports = { ensureKeypair, waitForSsh, readRemoteFile, writeRemoteFile };
