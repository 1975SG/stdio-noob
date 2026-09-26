// First real end-to-end session: every previously-separate piece
// wired together against a real guest -- login, the noob-file read
// from and written to its real location inside the guest over SSH
// (guest-fs.js, closing the open question of where it actually lives),
// the real greeting built from that real content, and the real
// curriculum prompt injected referencing the guest's own real paths
// (not the host stand-in path earlier work used).
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnGuest, installPublicKey } = require('./vm');
const { ensureKeypair, waitForSsh, readRemoteFile, writeRemoteFile } = require('./guest-fs');
const { greetingCommand, SYLLABUS_PATH } = require('./state');

const GUEST_SYLLABUS_PATH = '/home/noob/course/syllabus.xml';
const GUEST_NOOB_FILE_PATH = '/home/noob/.noob/MEMORY.md';

async function startRealSession({ diskPath, username, password, sshPort, localFixtureNoobFile, onData, onReady }) {
  const { publicKey } = ensureKeypair();

  const guest = spawnGuest({
    diskPath,
    username,
    password,
    sshHostPort: sshPort,
    onData,
    onLoggedIn: async (guestPty) => {
      installPublicKey(guestPty, publicKey);
      const ok = await waitForSsh({ port: sshPort, user: username });
      if (!ok) {
        console.log('session: SSH never became reachable with the installed key.');
        return;
      }

      // Seed the guest's copies on first run. The syllabus is always
      // refreshed from the host's canonical copy (it's not something
      // a session should fork); the noob-file is only seeded if the
      // guest doesn't already have one -- it's the learner's own
      // persistent progress, never overwritten by a later session.
      const syllabusXml = fs.readFileSync(SYLLABUS_PATH, 'utf8');
      await writeRemoteFile({ port: sshPort, user: username, remotePath: GUEST_SYLLABUS_PATH, content: syllabusXml });

      let noobFileContent = await readRemoteFile({ port: sshPort, user: username, remotePath: GUEST_NOOB_FILE_PATH });
      if (!noobFileContent) {
        noobFileContent = fs.readFileSync(localFixtureNoobFile, 'utf8');
        await writeRemoteFile({ port: sshPort, user: username, remotePath: GUEST_NOOB_FILE_PATH, content: noobFileContent });
      }

      // state.js's greeting logic is path-based (loads via
      // gray-matter from a local file); mirror the guest's real
      // content to a local temp file so it can build the greeting
      // from what's actually in the guest, not a stand-in.
      const mirrorPath = path.join(os.tmpdir(), `noob-file-mirror-${process.pid}.md`);
      fs.writeFileSync(mirrorPath, noobFileContent);
      guestPty.write(greetingCommand(mirrorPath));

      onReady({
        guestPty,
        sshPort,
        username,
        syllabusPath: GUEST_SYLLABUS_PATH,
        noobFilePath: GUEST_NOOB_FILE_PATH,
      });
    },
  });

  return guest;
}

module.exports = { startRealSession, GUEST_SYLLABUS_PATH, GUEST_NOOB_FILE_PATH };
