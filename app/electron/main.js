// stdio::noob real app shell. One Electron window, fixed two-pane split --
// a real terminal on the left (xterm.js + node-pty), a real tutor
// webview on the right (electron-injection-prototype/'s mechanism) --
// wired to the syllabus, the noob-file (and its real in-guest location
// over SSH), a real QEMU guest instead of a local shell (vm.js), and
// the real curriculum prompt, all combinable into one real session
// (session.js).
const { app, BrowserWindow, BrowserView, ipcMain } = require('electron');
const pty = require('node-pty');
const path = require('path');
const { resolveNoobFilePath, greetingCommand, SYLLABUS_PATH } = require('./state');
const { spawnGuest } = require('./vm');
const { injectCurriculumPrompt } = require('./tutor');
const { startRealSession } = require('./session');

const SPLIT = 0.45; // left pane fraction of the window width

function createWindow() {
  const win = new BrowserWindow({
    width: 1400,
    height: 900,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
    },
  });
  win.loadFile('index.html');

  // --- right pane: tutor webview, same mechanism as
  // electron-injection-prototype/. NOOB_INJECT_PROMPT opts into
  // actually sending the curriculum prompt -- gated behind
  // an env var since, unlike everything else in this file, a real run
  // of this sends a real message to whatever account is logged in.
  const view = new BrowserView({ webPreferences: {} });
  win.setBrowserView(view);
  const layout = () => {
    const [w, h] = win.getContentSize();
    const leftW = Math.floor(w * SPLIT);
    view.setBounds({ x: leftW, y: 0, width: w - leftW, height: h });
  };
  win.on('resize', layout);
  win.once('ready-to-show', layout);
  layout();
  view.webContents.loadURL('https://claude.ai/new');

  // Curriculum-prompt injection needs the real paths to reference,
  // which in full-session mode (NOOB_VM_SSH_PORT set) only become
  // known once the guest is logged in and its noob-file/syllabus are
  // confirmed in place -- so injection waits on whichever of "the
  // tutor page loaded" and "the guest session is ready" finishes
  // last, rather than firing on page-load alone (the host
  // stand-in path never needed this, since its paths are known
  // up front).
  let viewLoaded = false;
  let sessionPaths = null; // { syllabusPath, noobFilePath }, or null in host-stand-in mode
  let sessionReady = !process.env.NOOB_VM_SSH_PORT;

  const maybeInjectPrompt = () => {
    if (!process.env.NOOB_INJECT_PROMPT || !viewLoaded || !sessionReady) return;
    const { syllabusPath, noobFilePath } = sessionPaths || { syllabusPath: SYLLABUS_PATH, noobFilePath: resolveNoobFilePath() };
    injectCurriculumPrompt(view.webContents, { syllabusPath, noobFilePath });
  };

  view.webContents.once('did-finish-load', () => {
    viewLoaded = true;
    maybeInjectPrompt();
  });

  // --- left pane: piped to xterm.js in the renderer over IPC. Three
  // modes: a full real session against a real guest with its noob-file
  // reached over SSH (NOOB_VM_SSH_PORT set); a real guest
  // without SSH wiring, using the host stand-in noob-file path
  // (NOOB_VM_DISK alone); or a local shell for dev work that
  // doesn't need a whole VM boot each time.
  let session;

  if (process.env.NOOB_VM_SSH_PORT) {
    startRealSession({
      diskPath: process.env.NOOB_VM_DISK,
      username: process.env.NOOB_VM_USER,
      password: process.env.NOOB_VM_PASSWORD,
      sshPort: Number(process.env.NOOB_VM_SSH_PORT),
      localFixtureNoobFile: path.join(__dirname, '..', '..', 'noob-file-schema', 'example-MEMORY.md'),
      onData: (data) => win.webContents.send('pty-data', data),
      onReady: ({ syllabusPath, noobFilePath }) => {
        sessionPaths = { syllabusPath, noobFilePath };
        sessionReady = true;
        maybeInjectPrompt();
      },
    }).then((guest) => {
      session = guest;
    });
  } else if (process.env.NOOB_VM_DISK) {
    const noobFilePath = resolveNoobFilePath();
    session = spawnGuest({
      diskPath: process.env.NOOB_VM_DISK,
      username: process.env.NOOB_VM_USER,
      password: process.env.NOOB_VM_PASSWORD,
      onData: (data) => win.webContents.send('pty-data', data),
      onLoggedIn: (guest) => guest.write(greetingCommand(noobFilePath)),
    });
  } else {
    const noobFilePath = resolveNoobFilePath();
    session = pty.spawn(process.env.SHELL || 'bash', [], {
      name: 'xterm-256color',
      cols: 100,
      rows: 40,
      cwd: process.env.HOME,
      env: process.env,
    });
    session.onData((data) => win.webContents.send('pty-data', data));
    session.write(greetingCommand(noobFilePath));
  }

  ipcMain.on('pty-input', (event, data) => {
    if (session) session.write(data);
  });
  ipcMain.on('pty-resize', (event, cols, rows) => {
    if (session) session.resize(cols, rows);
  });
}

app.whenReady().then(createWindow);
app.on('window-all-closed', () => app.quit());
