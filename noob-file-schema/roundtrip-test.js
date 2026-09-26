// Proves the noob-file's schema is genuinely parseable and writable, not
// just designed on paper: read the example file, make the same kind
// of edit the tutor/app would make after a real session (advance a
// milestone, append a note, overwrite session-resume), write it back,
// then read it again and check nothing was corrupted or silently
// reordered.
const fs = require('fs');
const matter = require('gray-matter');

const path = './example-MEMORY.md';
const original = fs.readFileSync(path, 'utf8');

// --- read ---
const parsed = matter(original);
console.log('Parsed frontmatter tier:', parsed.data.tier);
console.log('Parsed milestone (assembler):', JSON.stringify(parsed.data.milestones.assembler));
console.log('Body has "## Notes":', parsed.content.includes('## Notes'));

// --- simulate a real session's edits ---
parsed.data.milestones.assembler.status = 'done';
parsed.data.milestones.c_compiler.status = 'in_progress';
parsed.data.milestones.c_compiler.scaffolding = 'from-scratch'; // learner chose to switch
parsed.data.tier = 3; // fluency grew, fade-out advanced a tier
parsed.data.updated = new Date().toISOString();

const notesMarker = '## Notes\n';
const notesIndex = parsed.content.indexOf(notesMarker) + notesMarker.length;
const newNote = '- 2026-09-13: finished the assembler; chose from-scratch for the C compiler.\n';
let body = parsed.content.slice(0, notesIndex) + newNote + parsed.content.slice(notesIndex);

const resumeMarker = '## Session resume\n\n';
const resumeIndex = body.indexOf(resumeMarker) + resumeMarker.length;
body = body.slice(0, resumeIndex) + 'Starting the C compiler from scratch, no scaffolding this time.\n';

// --- write back ---
const updated = matter.stringify(body, parsed.data);
fs.writeFileSync('./example-MEMORY.after.md', updated);

// --- read again, confirm round-trip integrity ---
const reparsed = matter(fs.readFileSync('./example-MEMORY.after.md', 'utf8'));
console.log('\nAfter round-trip:');
console.log('tier:', reparsed.data.tier);
console.log('assembler status:', reparsed.data.milestones.assembler.status);
console.log('c_compiler:', JSON.stringify(reparsed.data.milestones.c_compiler));
console.log('domain_deviations preserved:', JSON.stringify(reparsed.data.domain_deviations));
console.log('has new note:', reparsed.content.includes('finished the assembler'));
console.log('has old note still (append, not overwrite):', reparsed.content.includes('needed a nudge'));
console.log('session-resume overwritten (not appended):', !reparsed.content.includes('about to write the tiny assembler'));
