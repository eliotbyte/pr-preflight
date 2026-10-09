---
repo: rmk-rs/rmk
whose_taste: maintainers
reviewers: [lead maintainer]
sources:
  - repository: [CLAUDE.md, CONTRIBUTING.md, .github/workflows, scripts/format_all.sh]
  - history: "~460 code review comments and ~515 conversation comments on 102 outside PRs, 2024-03..2026-10"
  - questionnaire: none
calibration: "2026-10-09: 4 of 6 real comments found on #1220 (second version), 2.5 of 5 on its first version"
updated: 2026-10-09
---

# Review profile: rmk-rs/rmk

An example profile, built with the `preflight-profile` skill from the project's public review
history. RMK is Rust firmware for keyboards (`no_std`, embassy), so size, power and async weigh far
more than they would in most projects. Use it as a model for the shape of a profile, not as rules
for another repository.

## Who reviews, and how

One lead maintainer reviews nearly every outside PR. Comments are short (median around 80
characters), usually a question ("Why X?", "Is this needed?", "It seems duplicate?") or a
preference ("I prefer ..."), often with a code snippet of the alternative. Admits a misreading
openly. Pragmatic: merges with follow-up work noted for later rather than blocking on everything.
Of 102 reviewed outside PRs, 88 were merged.

## Priorities

1. **Design and boundaries** [history]: who owns what and what crosses the split link. A transport
   only forwards and owns no logic (#1030). Software transforms belong in a processor, optional
   capabilities in their own trait (#689). Hardware is reached through embedded-hal or
   embedded-storage traits, not hardcoded peripherals (#877, #1018). Events over direct links
   between modules (#877). A unified mechanism over a one-off (#1085, #1030). Over-engineering
   gets called out (#752).
2. **Duplication and dead weight** [history]: unused fields and options get "remove it?" (#1220,
   #782); thin wrappers, one-line helpers, statics where a field will do (#1030, #798, #1107);
   redundant guards and states (#785, #371); types or handlers similar enough to merge (#1030).
3. **Flash and RAM** [history]: reads the CI size report on every PR. Objects to cost that every
   keyboard pays for a feature only some use (#933, #1137, #782), default channel sizes grown for
   everyone (#782), and logic duplicated across paths (#859). Prefers narrow types (`HidKeyCode`,
   `u16`) (#859, #789).
4. **Async and power** [history]: no busy loops or blocking delays, all delays async (#689,
   #798); wait on events or interrupts rather than poll (#1030, #287); keep the keyboard's main loop
   simple (#859, #756).
5. **Concrete misbehavior** [history]: asks in scenarios. What if more keys are held than a buffer
   holds, two of these are pressed, the layer changes mid-press, the board sleeps, the peripheral
   reconnects (#74, #859, #785). Stuck keys, panics, `unwrap`, unchecked indices (#859, #1003,
   #516).
6. **Compatibility** [history]: don't break public API, add `with_x` instead of a new parameter
   (#789); keep user-facing names (#859); keep existing tests and add new ones (#854); keep default
   features (#74, #371).
7. **Feature gates and build constants** [history]: gate what only one feature uses; use
   `cfg(feature)` directly rather than emitting new cfgs (#752); emit build constants only with
   their feature (#756).
8. **keyboard.toml** [history]: fewer, simpler options; reuse an existing option before adding
   one (#834, #720); no option for a rare case (#786, #1106); group by interface (`spi = {...}`)
   (#660, #782); fail the build on invalid values rather than silently adjusting them (#756, #782);
   full, clear names (#522, #659).

## Not worth raising

- Formatting: CI runs it [history][repo]
- Test names, doc comment length and wording [history]
- The number of constants or small helpers that aren't dead weight [history]
- Renames, unless a name actively misleads (#14, #808) [history]
- Typos outside user-facing docs [history]

## Already enforced by tooling

- `cargo +nightly fmt` per crate (`scripts/format_all.sh`) [repo]
- `clippy`, the test matrix in `scripts/test_all.sh`, example builds, and a size report on every PR
  [repo]

## Pull request expectations

- One topic per PR; a large or mixed PR is asked to split (#1001, #583, #1220) [history]
- One commit, squashed; no AI co-author trailers (#1206) [history]
- A one-line changelog entry; none for a fix to something not yet released (#1106, #1219)
  [history]
- New options documented (#891, #871) [history]
- Tested on real hardware when it touches hardware (#807, #1060) [history]
- No code derived from GPL projects such as QMK (#1001, #814) [history]
- Unrelated changes reverted: editor settings, workflows, stray binaries (#859, #886) [history]

## Changes

- 2026-10-09: created from the review history of outside PRs and the repository's own docs;
  calibrated on two versions of #1220, then the "everything the change adds" checklist moved into
  the reviewer agent, where it applies to every project.
