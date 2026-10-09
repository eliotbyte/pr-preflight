---
# Review profile for one repository. Read by the preflight-reviewer agent; written only by the
# preflight-profile skill, following its procedure. Keep it short: rules, not raw comments.
repo: owner/name                # the repository whose reviewers are predicted (upstream, not a fork)
whose_taste: maintainers        # maintainers | team | author
reviewers: []                   # logins whose review history the profile is built from, if any
sources:                        # what the profile was built from, most trusted last
  - repository: []              # files read, e.g. CONTRIBUTING.md, CI workflows, linter configs
  - history: none               # e.g. "462 code comments, 102 PRs, 2024-03..2026-10" or "none"
  - questionnaire: none         # date the author answered, or "none"
calibration: none               # e.g. "2026-10-09: 4 of 6 real comments found on PR #123" or "none"
updated: YYYY-MM-DD
---

# Review profile: owner/name

<!--
Source tags, used on every rule below, from most to least authoritative:
  [author]   the person using the plugin said so
  [learned]  a real review disagreed with a prediction, and the profile was corrected
  [history]  a pattern in the reviewers' past comments; cite one or two PRs
  [repo]     read from the repository: docs, CI, linters, conventions
  [default]  plugin default for this kind of project, until something better is known
When two rules conflict, the more authoritative tag wins.
-->

## Who reviews, and how

<!-- How the reviewers write (short questions, "I prefer ...", code suggestions), how strict they
are, whether they merge with follow-up work or block until everything is fixed. -->

## Priorities

<!-- What they weigh, highest first. One entry per theme: what they look for, what they tend to
ask, and its source. Example:

1. **Design boundaries** [history]: who owns what, what crosses module boundaries. They ask
   whether logic belongs in the transport or the processor. (#1030, #689)
-->

## Not worth raising

<!-- What they don't comment on, so the reviewer doesn't either. Example:
- Test names, doc comment wording [history]
-->

## Already enforced by tooling

<!-- What CI and linters catch, so the reviewer skips it. Example:
- rustfmt (nightly), clippy with -D warnings [repo: .github/workflows/ci.yml]
-->

## Pull request expectations

<!-- Size and scope, commits (squash? trailers?), changelog policy, docs and tests required,
testing on hardware, licensing. Example:
- One topic per PR; a large PR gets asked to split [history] (#1001, #583)
-->

## Changes

<!-- One line per change to this profile: date, what changed, why, source.
- YYYY-MM-DD: created from repository files and the questionnaire.
-->
