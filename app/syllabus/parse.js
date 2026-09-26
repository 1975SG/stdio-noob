// Loads and validates syllabus.xml against its own defined shape,
// and cross-checks it against the noob-file-schema fixture
// so the two pieces are proven to agree on milestone ids, not just
// designed to.
const fs = require('fs');
const path = require('path');
const { XMLParser } = require('fast-xml-parser');

const VALID_SCAFFOLDING_MODES = new Set(['scaffolded', 'from-scratch']);
const REQUIRED_STEP_FIELDS = ['does', 'needed-for', 'connects-to', 'hardware'];
// A "seed" step hands over a non-derivable trust-root
// artifact (hex0's own bytes, not logic a learner could reconstruct
// from the explanation) instead of a command whose shape follows from
// understanding it. It still carries a real, runnable <command> like
// every other step -- explanation-first never means withheld -- but
// that command is specifically a checksum check, and <checksum> is
// mandatory so the step can't silently skip the one thing that makes
// handing over an unreadable blob safe: verifying it landed intact.
const VALID_STEP_TYPES = new Set(['command', 'seed']);

function asArray(x) {
  if (x === undefined) return [];
  return Array.isArray(x) ? x : [x];
}

function loadSyllabus(xmlPath) {
  const xml = fs.readFileSync(xmlPath, 'utf8');
  const parser = new XMLParser({ ignoreAttributes: false, attributeNamePrefix: '' });
  const doc = parser.parse(xml);
  if (!doc.syllabus) throw new Error('no <syllabus> root element');

  const milestones = asArray(doc.syllabus.milestone).map((m) => {
    if (!m.id) throw new Error('milestone missing id');
    if (!m.title) throw new Error(`milestone ${m.id} missing title`);
    const modes = (m.scaffolding || 'none').split(',').map((s) => s.trim());
    for (const mode of modes) {
      if (mode !== 'none' && !VALID_SCAFFOLDING_MODES.has(mode)) {
        throw new Error(`milestone ${m.id} has unknown scaffolding mode "${mode}"`);
      }
    }
    const steps = asArray(m.step).map((s) => {
      if (!s.id) throw new Error(`a step in milestone ${m.id} is missing id`);
      for (const field of REQUIRED_STEP_FIELDS) {
        if (!(field in s)) throw new Error(`step ${s.id} missing <${field}>`);
      }
      if (!s.command) throw new Error(`step ${s.id} missing <command> -- explanation-first never means withheld`);
      if (s.scaffolding && !VALID_SCAFFOLDING_MODES.has(s.scaffolding)) {
        throw new Error(`step ${s.id} has unknown scaffolding mode "${s.scaffolding}"`);
      }
      const type = s.type || 'command';
      if (!VALID_STEP_TYPES.has(type)) {
        throw new Error(`step ${s.id} has unknown type "${type}"`);
      }
      if (type === 'seed') {
        if (!s.checksum || typeof s.checksum !== 'object' || !s.checksum['#text']) {
          throw new Error(`step ${s.id} is type="seed" but missing a real <checksum>`);
        }
        if (!s.checksum.algo) {
          throw new Error(`step ${s.id}'s <checksum> is missing the algo attribute`);
        }
      }
      return {
        id: s.id,
        type,
        scaffolding: s.scaffolding || null,
        does: s.does,
        neededFor: s['needed-for'],
        connectsTo: s['connects-to'],
        hardware: s.hardware,
        question: s.question || null,
        command: s.command,
        checksum: type === 'seed' ? { algo: s.checksum.algo, value: s.checksum['#text'] } : null,
      };
    });
    return { id: m.id, title: m.title, scaffoldingModes: modes, steps };
  });

  const ids = milestones.map((m) => m.id);
  const dupes = ids.filter((id, i) => ids.indexOf(id) !== i);
  if (dupes.length) throw new Error(`duplicate milestone id(s): ${[...new Set(dupes)].join(', ')}`);

  return milestones;
}

function crossCheckAgainstNoobFile(milestones, noobFilePath) {
  const matter = require('gray-matter');
  const { data } = matter(fs.readFileSync(noobFilePath, 'utf8'));
  const syllabusIds = new Set(milestones.map((m) => m.id));
  const missing = Object.keys(data.milestones || {}).filter((id) => !syllabusIds.has(id));
  return { checkedIds: Object.keys(data.milestones || {}), missing };
}

module.exports = { loadSyllabus, crossCheckAgainstNoobFile };

if (require.main === module) {
  const xmlPath = path.join(__dirname, 'syllabus.xml');
  const milestones = loadSyllabus(xmlPath);

  console.log(`Parsed ${milestones.length} milestones from ${xmlPath}:\n`);
  for (const m of milestones) {
    const modeInfo = m.scaffoldingModes.includes('none') ? 'no scaffolding split' : `modes: ${m.scaffoldingModes.join(', ')}`;
    console.log(`- ${m.id} ("${m.title}") -- ${m.steps.length} step(s), ${modeInfo}`);
  }

  const noobFilePath = path.join(__dirname, '..', '..', 'noob-file-schema', 'example-MEMORY.md');
  const { checkedIds, missing } = crossCheckAgainstNoobFile(milestones, noobFilePath);
  console.log(`\nCross-checked against ${noobFilePath}`);
  console.log(`noob-file milestone keys: ${checkedIds.join(', ')}`);
  if (missing.length) {
    console.error(`FAIL: noob-file references milestone id(s) not in the syllabus: ${missing.join(', ')}`);
    process.exit(1);
  }
  console.log('OK: every milestone id the noob-file references exists in the syllabus.');
}
