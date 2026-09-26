# noob-file-schema prototype

Proof of concept: The single persistent file belonging to each learner,
`~noob/.noob/MEMORY.md`, located inside the virtual machine, formatted
as Markdown with a YAML frontmatter block, analyzed and modified using
the [`gray-matter`](https://github.com/jonschlinkert/gray-matter)
library (standard, opinionated frontmatter library without schema
validation, and it's fine because this file is read and written by one
program only: tutor process and the app respectively).

## Schema

Frontmatter:

- `tier`, the current fade-out tier (1-4).
- `provider`, the URL of the last AI website that the learner was
  authenticated on.
- `milestones`, an object with `{status, scaffolding?}` properties for
  each `{id}` of syllabus XML id; `status` could be either
  `not_started` / `in_progress` / `done`; `scaffolding`
  (`scaffolded` / `from-scratch`) property available if the milestone
  has that option.
- `domain_deviations`, an array of `{language, date, proceeded}`,
  having one item per each tutor-identified off-curriculum language
  deviation.
- `config`, `{resistance_override, domain}`, both properties nullable.
- `updated`, ISO timestamp of the last modification.

Body: `## Notes` (append-only, durable across the entire course),
`## Session resume` (short, wiped each time).

## Files

- `example-MEMORY.md`, a realistic fixture, halfway through the course.
- `roundtrip-test.js`, which reads it, performs edits typical of a
  real session (progress a milestone, flip the scaffolding flag,
  increment the fade-out level, add a comment, overwrite session
  resume), writes it out again, re-reads it, and checks that nothing
  was corrupted or reordered.

## Running it

```sh
npm install
node roundtrip-test.js
```

**Outcome:** The round trip is clean, milestone data remains intact inside
nesting, notes get appended, session resumption causes overwrite, file remains
human-readable at all times.

**Observed quirk, not a bug:** When the YAML `date:` is a simple string,
it will be converted to an ISO format datestamp after one write-back cycle,
since YAML date strings become JS `Date` objects. Not an issue, but worth
noting before doing any diffs on this file.

`example-MEMORY.after.md` (output from the script) is gitignored. Rebuild
it by re-running the script.
