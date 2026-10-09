---
name: preflight-profile
description: Build, calibrate or update the review profile that the preflight reviewer works from, for the repository being worked on. Use it when /pr-preflight:preflight finds no profile, when the user asks to set one up or refresh it, and whenever a real review or the user shows that the profile is wrong or missing something.
---

# Review profile: build, calibrate, update

The `preflight-reviewer` agent predicts what a project's reviewers will object to. It knows nothing
about the project except its **review profile**, a short Markdown file of ranked rules. This skill
is how that file is made and kept right. The reviewer only reads it; only this procedure writes it.

Template: `${CLAUDE_PLUGIN_ROOT}/templates/profile.md`. An example built from a real project's
history: `${CLAUDE_PLUGIN_ROOT}/examples/profiles/rmk-rs__rmk.md`.

## Where the profile lives

Look in this order and use the first that exists:

1. `.claude/review-profile.md` in the repository: shared with everyone working on it. Use this only
   for the user's own or their team's repository, never for an upstream project they contribute to.
2. `~/.claude/pr-preflight/profiles/<owner>__<repo>.md`: the user's own copy. This is the default.

`<owner>/<repo>` is the repository whose reviewers are predicted. For a fork, that is the upstream:
use the `upstream` remote if there is one, otherwise ask whether `origin` is a fork and of what.

## Building a new profile

Work through these steps in order. Each adds what it can; later steps only fill the gaps.

### 1. Whose taste

Decide whose reviews are predicted, and record it as `whose_taste`:

- **maintainers**: the user contributes to someone else's project (a fork, or an upstream remote).
- **team**: a shared repository where the user's colleagues review.
- **author**: the user's own project, reviewed by nobody else. The profile then captures the
  user's own standards.

If the remotes and history don't make this obvious, ask.

### 2. The repository itself

Always do this, even in an empty repository. Read, where present:

- Contributor guides: `CONTRIBUTING*`, `CLAUDE.md`, `AGENTS.md`, `.github/PULL_REQUEST_TEMPLATE*`,
  `docs/` pages on development, code of conduct only for tone.
- CI workflows and linter or formatter configs: these fill **Already enforced by tooling**.
- The README and manifest files (`Cargo.toml`, `package.json`, `pyproject.toml`, ...): what kind
  of project this is (library, firmware, web service, CLI, ...) and what it targets.
- `git log` on the default branch: commit message style, squash or merge, changelog habits.

Tag everything learned here `[repo]`.

### 3. Review history

Only when the repository is on GitHub, `gh auth status` succeeds, and others review in it. If
`gh` isn't installed or authenticated, tell the user how (`gh auth login`) and offer to continue
without history.

1. Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/fetch-review-history.sh" <owner/repo> <tmp-dir>` with a
   temporary directory. It lists who reviews other people's PRs most.
2. Pick the reviewers: for `maintainers`, the top reviewers of outside PRs; for `team`, the people
   the user names. Confirm the choice with the user if more than one is plausible.
3. Pick two or three **holdout PRs** for calibration: PRs by others where the chosen reviewers
   left four or more code comments, preferably recent ones. Then run the script again with the
   logins and the holdout PR numbers. Their comments are kept out of `reviewer_comments.txt`, so
   the profile can't learn the answers to the calibration.
4. Read all of `reviewer_comments.txt`. For a few hundred comments, read every one; for thousands,
   read the most recent thousand and sample the rest. Group them into themes and rank the themes
   by how often they come up and how hard they are pressed (blocking language, PRs closed over
   them, "please split this PR"). Note how they write: length, questions or statements, "I
   prefer", suggestions with code.
5. Also note what they **never** comment on although it appears in the diffs: formatting, naming,
   test style, doc wording. That fills **Not worth raising**, and keeps the reviewer from padding
   reviews.
6. For each rule, cite one or two PRs as `(#123)`. Paraphrase, don't quote at length: the profile
   holds rules, not comments.
7. Delete the temporary directory.

If there is too little history (fewer than about 30 comments by the chosen reviewers on others'
PRs), say so and lean on steps 2 and 4. Tag rules from here `[history]`.

### 4. Ask the user what's still missing

Ask only what steps 2 and 3 didn't settle, in one short round, offering a sensible default for
each. Typical gaps:

- What matters most here: correctness, performance, binary or bundle size, memory, security, API
  stability, test coverage, docs, accessibility, ...?
- How strict should the pre-review be: only what would block a merge, or also likely questions?
- Pull request expectations: size, one topic per PR, commit squashing, changelog, docs, tests.
- Anything the reviewers are known to care about that isn't written down.

For a brand-new project with no history, this is the main source: combine the answers with
`[default]` rules for that kind of project. Tag answers `[author]`.

### 5. Write the profile

Fill in the template. Keep it under about 200 lines: ranked priorities, each with what the
reviewers look for, how they tend to ask, its source tag and PR links; then the other sections.
Set `sources` and `updated`. Add a first line under **Changes**.

### 6. Calibrate

Only when there are holdout PRs. For each, launch the `preflight-reviewer` agent on the PR's
diff as it was when reviewed (its head commit at the time, against its base), with the new profile
and the PR's own description as context. Don't give it the PR's review comments.

Compare its findings with the reviewers' real comments on that PR. Count how many real comments it
found (a near match counts as half), and how many of its findings the reviewers never raised.
Show the user both lists side by side.

- Real comments it missed point at a priority the profile underrates or lacks. Adjust the profile,
  but phrase the change as a general rule, never as the specific answer: the next calibration
  has to stay honest.
- Findings the reviewers never raised are either real issues they missed, which is fine, or noise.
  For noise, add the pattern to **Not worth raising**.

Record the result in `calibration`, such as `2026-10-09: 4 of 6 on #1220 v2, 2 of 5 on #1220 v1`.
One round of adjustment is usually enough; don't tune until it reproduces the holdout exactly.

## Updating a profile

Update when one of these happens, and say so to the user when you do:

- **The user corrects it**: "that doesn't matter here", "they care a lot about X". Tag `[author]`.
- **A real review disagrees with a prediction**: the reviewers raised something the pre-review
  missed, or ignored something it flagged. Tag `[learned]`, cite the PR.
- **It's stale**: `updated` is more than about six months old, a new person does most of the
  reviewing, or the project changed course. Offer to rebuild from step 3; don't do it unasked.

How to edit:

1. Change the smallest thing that fixes it: a priority's rank, a new rule, a line in **Not worth
   raising**. Keep the profile short; merge instead of appending near-duplicates.
2. Respect the source tags: a `[history]` or `[repo]` rule doesn't override an `[author]` one.
   If new evidence contradicts an `[author]` rule, ask the user.
3. Add a line under **Changes**: date, what changed, why, source. Update `updated`.
4. Changes that reorder priorities, or remove a rule, need the user's OK first; adding a line to
   **Not worth raising** or a citation doesn't.
