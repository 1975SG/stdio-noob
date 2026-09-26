// Injects the real curriculum prompt into the tutor pane at
// session start -- the background-process injection mechanism designed
// earlier, now wired to real content and verified against the
// real chosen provider (claude.ai). Selectors are inherently
// provider-specific (a real chat UI's own DOM); these target claude.ai.
const { curriculumPrompt } = require('./curriculum-prompt');

const EDITABLE_SELECTOR = '[aria-label="Write your prompt to Claude"]';
const SEND_BUTTON_SELECTOR = 'button[aria-label="Send message"]';

// The app never automates login itself (glass-box design --
// the learner logs into whatever real provider they choose). If the
// chat input never appears within this window, the most likely
// explanation is the learner is still sitting on the provider's own
// login page, not a bug here.
async function waitForEditable(webContents, timeoutMs = 30000, intervalMs = 1000) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const found = await webContents.executeJavaScript(
      `!!document.querySelector(${JSON.stringify(EDITABLE_SELECTOR)})`,
    );
    if (found) return true;
    await new Promise((r) => setTimeout(r, intervalMs));
  }
  return false;
}

async function injectCurriculumPrompt(webContents, { syllabusPath, noobFilePath }) {
  const ready = await waitForEditable(webContents);
  if (!ready) {
    console.log('tutor: chat input never appeared within the timeout -- injection skipped.');
    return false;
  }

  const prompt = curriculumPrompt({ syllabusPath, noobFilePath });
  // execCommand('insertText') dispatches real beforeinput/input events,
  // which ProseMirror-based editors (claude.ai's chat box included)
  // need to register the change -- setting .textContent/.innerText
  // directly is silently ignored by the editor's own state.
  await webContents.executeJavaScript(`
    (function() {
      const editable = document.querySelector(${JSON.stringify(EDITABLE_SELECTOR)});
      editable.focus();
      document.execCommand('insertText', false, ${JSON.stringify(prompt)});
    })();
  `);
  await new Promise((r) => setTimeout(r, 500)); // let the editor's own framework register the input before checking Send

  const sent = await webContents.executeJavaScript(`
    (function() {
      const btn = document.querySelector(${JSON.stringify(SEND_BUTTON_SELECTOR)});
      if (!btn || btn.disabled) return false;
      btn.click();
      return true;
    })();
  `);
  console.log('tutor: curriculum prompt', sent ? 'sent' : 'filled but Send was unavailable');
  return sent;
}

module.exports = { injectCurriculumPrompt };
