# PR Preflight

A [Claude Code](https://code.claude.com) plugin that pre-reviews your change the way the project's
reviewers would, before you send it.

Generic review tools look for bugs. Maintainers look for other things too: the extra field nobody
uses, the feature that every user pays for, the PR that should have been two. What they ask about
differs a lot between projects. PR Preflight learns what this project's reviewers care about,
writes it down as a short **review profile**, and has an agent review your change against it. Only
findings that hold up against the code reach you.

## Install

```bash
claude plugin marketplace add eliotbyte/pr-preflight
claude plugin install pr-preflight@pr-preflight
```

Or inside a session: `/plugin marketplace add eliotbyte/pr-preflight`, then
`/plugin install pr-preflight@pr-preflight`.

Building a profile from review history needs the [GitHub CLI](https://cli.github.com), logged in
with `gh auth login`. Without it, the profile is built from the repository and a few questions.

## Use

In a checkout of the project you're contributing to:

```
/pr-preflight:preflight              # the current branch
/pr-preflight:preflight my-branch    # a branch
/pr-preflight:preflight 1234         # an open pull request
```

Or just ask: "preflight this branch", "what will the maintainers say about this PR?".

The first time in a repository there is no profile yet, and Claude offers to build one with
`/pr-preflight:preflight-profile`.

## How it works

**The review profile** is a short Markdown file of ranked rules for one repository: whose reviews
it predicts, what they weigh most, what they never comment on, what CI already catches, and what
they expect of a pull request. Every rule carries its source, and the more authoritative source
wins: `[author]` (you said so) > `[learned]` (a real review corrected it) > `[history]` (the
reviewers' past comments) > `[repo]` (docs and CI) > `[default]`.

**Building one** (`preflight-profile` skill) goes in steps, each filling what the last couldn't:

1. Whose taste to predict: an upstream project's maintainers, your team, or your own.
2. The repository: contributor guides, CI and linter configs, commit history.
3. Review history, if there is any: the reviewers' comments on other people's PRs, downloaded
   with `gh`, grouped into themes and ranked. A few PRs are held back to calibrate on.
4. Questions to you, only about what is still unknown. For a new project with no history, this is
   the main source.
5. Calibration: the reviewer runs blind on the held-back PRs, and its findings are compared with
   what the reviewers really said.

Raw comments are only used while building the profile and deleted afterwards. The profile keeps
rules and PR links.

**Reviewing** (`preflight` skill): Claude finds the profile, gathers the change's context
(including a series of stacked PRs, and answers the reviewers already accepted), runs the
read-only `preflight-reviewer` agent, then checks each finding against the code itself and drops
those that don't hold.

**Keeping it right**: when the real review comes in, Claude compares it with the prediction and
proposes profile changes: a rule the reviewers turned out to care about, or a kind of finding they
let pass. You confirm anything that reorders priorities.

## Where profiles live

- `~/.claude/pr-preflight/profiles/<owner>__<repo>.md`: your own copy, the default. Use this for
  projects you contribute to, so nothing about the plugin lands in their repository.
- `.claude/review-profile.md` in the repository: shared with your team. Only for repositories you
  or your team own.

[`examples/profiles/rmk-rs__rmk.md`](examples/profiles/rmk-rs__rmk.md) is a profile built from the
public review history of [RMK](https://github.com/rmk-rs/rmk), a Rust keyboard firmware.

## Layout

```
.claude-plugin/         plugin and marketplace manifests
agents/                 preflight-reviewer: reviews a change against a profile, read-only
skills/preflight/       running a pre-review, checking findings, learning from real reviews
skills/preflight-profile/  building, calibrating and updating a profile
scripts/                fetch-review-history.sh: review history via the GitHub CLI
templates/profile.md    the profile format
examples/profiles/      a real profile
```

## License

MIT
