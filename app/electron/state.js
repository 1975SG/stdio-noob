// Real integration between the app shell and the two pieces already
// designed and prototyped separately: the syllabus and the
// noob-user memory/config file. Reads both for real and
// produces the session's opening status line.
//
// Where the noob-file actually lives is still an open question this
// slice deliberately doesn't answer: in the real product it
// lives inside the learner's QEMU guest (`~noob/.noob/MEMORY.md`),
// and the terminal pane isn't talking to a real guest yet (that's
// later work). Until then, `resolveNoobFilePath` uses a local
// path as a stand-in, seeded from the noob-file-schema fixture on
// first run -- real read/write code exercised against a real file,
// just not yet the real location.
const fs = require('fs');
const path = require('path');
const matter = require('gray-matter');
const { loadSyllabus } = require('../syllabus/parse.js');

const SYLLABUS_PATH = path.join(__dirname, '..', 'syllabus', 'syllabus.xml');
const FIXTURE_PATH = path.join(__dirname, '..', '..', 'noob-file-schema', 'example-MEMORY.md');
const DEV_NOOB_FILE_PATH = path.join(__dirname, '.dev-noob-file', 'MEMORY.md');

function resolveNoobFilePath() {
  const configured = process.env.NOOB_FILE;
  if (configured) return configured;
  if (!fs.existsSync(DEV_NOOB_FILE_PATH)) {
    fs.mkdirSync(path.dirname(DEV_NOOB_FILE_PATH), { recursive: true });
    fs.copyFileSync(FIXTURE_PATH, DEV_NOOB_FILE_PATH);
  }
  return DEV_NOOB_FILE_PATH;
}

function loadNoobFile(noobFilePath) {
  return matter(fs.readFileSync(noobFilePath, 'utf8'));
}

function saveNoobFile(noobFilePath, parsed) {
  fs.writeFileSync(noobFilePath, matter.stringify(parsed.content, parsed.data));
}

// Returns the greeting as an array of lines, not a joined string --
// deliberately, so a caller piping this through a shell command (as
// main.js does, via printf) never has to worry about a raw embedded
// CR/LF being read back as a literal Enter keystroke by the shell's
// own line editor. Join with '\r\n' only for something that writes
// straight to a terminal emulator, never for something typed at a
// live shell.
function sessionGreetingLines(noobFilePath) {
  const milestones = loadSyllabus(SYLLABUS_PATH);
  const { data } = loadNoobFile(noobFilePath);
  const lines = milestones.map((m) => {
    const entry = (data.milestones || {})[m.id];
    if (!entry) return `  ${m.id}: not started`;
    const scaffoldingNote = entry.scaffolding ? ` (${entry.scaffolding})` : '';
    return `  ${m.id}: ${entry.status}${scaffoldingNote}`;
  });
  return [
    `stdio::noob -- welcome back.`,
    `Tier ${data.tier ?? 1}, last signed into ${data.provider ?? 'no provider yet'}.`,
    `Milestones:`,
    ...lines,
  ];
}

// Builds the actual command line to type at a live shell to print the
// greeting -- shared by every place that injects it (a local dev
// shell, or a real guest once login succeeds), so the printf-escaping
// fix only has to exist once. This goes through printf's own
// backslash-escape processing (a literal `\n`, not a raw newline byte)
// rather than an embedded newline, because an interactive bash reading
// from a pty does its own line editing and treats a raw embedded
// `\r`/`\n` as a real Enter keystroke, even mid single-quote --
// fragmenting what should be one command into several bogus partial
// ones. `%` is escaped too, since printf's format string treats it as
// a conversion specifier and a provider URL could plausibly contain one.
function greetingCommand(noobFilePath) {
  const greetingFormat = sessionGreetingLines(noobFilePath)
    .map((line) => line.replace(/\\/g, '\\\\').replace(/%/g, '%%').replace(/'/g, "'\\''"))
    .join('\\n');
  return `printf '${greetingFormat}\\n\\n'\r`;
}

module.exports = {
  resolveNoobFilePath,
  loadNoobFile,
  saveNoobFile,
  sessionGreetingLines,
  greetingCommand,
  SYLLABUS_PATH,
};
