---
name: preflight
description: Pre-review a branch, commit range or pull request the way the project's reviewers would, before it is sent or while it waits for review. Use when the user asks to pre-review, "preflight", check a PR before opening it, or predict what the maintainers will say. Takes an optional branch, range or PR number.
---

# Preflight a change

Predict what this project's reviewers will raise about a change, using its review profile, and
report only the findings that hold up against the code.

## 1. What to review

From the user's request, work out:

- **Repository**: the current checkout, unless the user names another.
- **Range**: a branch means `<base>..<branch>`, where `<base>` is the merge base with the
  upstream default branch (`upstream/main`, else `origin/main`, else ask). A PR number means its
  head against its base: fetch it with `gh pr view <n> --json headRefOid,baseRefName` and
  `git fetch`. With nothing given, use the current branch.
- **Context**:
  - The change's description: the PR body, or the commit messages.
  - If it is one of a series of stacked changes, what the earlier ones did and what later ones
    will add, so the reviewer judges this one on its own.
  - If it is an open PR that already has review, the questions the reviewers asked and the
    answers they accepted (`gh pr view <n> --comments` and `gh api repos/<owner>/<repo>/pulls/<n>/comments`).
    Accepted answers must not be raised again.

## 2. The profile

Find the review profile as described in the `preflight-profile` skill (repository
`.claude/review-profile.md`, else `~/.claude/pr-preflight/profiles/<owner>__<repo>.md`, where the
repository is the upstream one for a fork).

- **No profile**: tell the user, and offer to build one with the `preflight-profile` skill now. It
  takes a few minutes with review history, or one short round of questions without. If the user
  declines, run with `${CLAUDE_PLUGIN_ROOT}/templates/profile.md` as a stand-in, and say the
  review is generic.
- **Stale profile** (`updated` more than about six months ago): mention it once, then go on.

## 3. Run the reviewer

Launch the `preflight-reviewer` agent with:

```
Profile: <absolute path to the profile>
Repository: <absolute path to the checkout>
Range: <base>..<head>
Context:
<what the change is for, its place in a series, accepted answers from earlier review>

Work only from the repository and the profile. Do not modify any files or git state.
```

For several independent changes, launch one agent per change in parallel.

## 4. Check each finding yourself

The reviewer is told to check its claims, but check every finding again before showing it:

- Open the file and line. Confirm the code says what the finding claims.
- For "unused", search the repository, and the later changes in a series, for uses.
- For "duplicate" or "already exists", look at the other place it names.
- For a consequence, trace it far enough to believe it, or write a test if it's cheap.
- Drop a finding that the context already answers, such as a question the reviewers accepted an
  answer to.

Sort the result into **confirmed** and **dropped** (with a one-line reason).

## 5. Report

Show the confirmed findings, most likely to block first. For each, give the reviewers' likely
words, the evidence in one or two sentences, and what you'd change. List the dropped findings in
one short paragraph at the end. Don't change code unless the user asks.

## 6. Learn from the real review

When the real review comes in, for a change that was pre-reviewed (the user mentions it, or you
see it on the PR), compare it with the prediction:

- Something the reviewers raised that the pre-review missed: a candidate `[learned]` rule.
- Something the pre-review flagged that they let pass, more than once: a candidate for **Not worth
  raising**.

Propose the profile change to the user and, once they agree, make it as the `preflight-profile`
skill describes under "Updating a profile".
