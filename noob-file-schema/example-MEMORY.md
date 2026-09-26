---
tier: 2
provider: https://claude.ai
milestones:
  chroot:
    status: done
  assembler:
    status: in_progress
    scaffolding: scaffolded
  c_compiler:
    status: not_started
domain_deviations:
  - language: haskell
    date: 2026-09-12
    proceeded: false
config:
  resistance_override: null
  domain: null
updated: 2026-09-12T23:10:00.000Z
---

## Notes

- 2026-09-12: built the chroot jail on the second try; needed a nudge
  on copying /etc/apk/keys first.
- 2026-09-12: asked about Haskell as a tangent; told the tradeoff,
  chose to stay on track.

## Session resume

Currently inside `myjail`, about to write the tiny assembler's
tokenizer. Last line given: reading one mnemonic at a time from stdin.
