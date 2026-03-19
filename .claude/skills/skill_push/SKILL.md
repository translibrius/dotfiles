---
name: skill_push
description: Stage, commit, push, and optionally open a PR. Follows git conventions — no Co-Authored-By, single-line conventional commits, human PR descriptions.
argument-hint: "[pr]"
allowed-tools: Bash(git *), Bash(gh *), Read, Grep, Glob
---

# Push

Stage changes, commit, push to remote, and optionally create a PR.

## Rules — follow these exactly

### Shell discipline
- **NEVER** chain commands with `&&` or `;` or `||`. Run each git/gh command as its own separate Bash call.
- **NEVER** `cd` anywhere. We are already in the project root.
- **NEVER** add a `Co-Authored-By` line to commit messages.
- **NEVER** use `--no-verify`, `--no-gpg-sign`, or any hook-bypass flag.
- **NEVER** use `-i` (interactive) flags on any git command.
- **NEVER** use `git add -A` or `git add .` — stage specific files by name.
- **NEVER** force-push to `master`/`main`. Warn the user and stop if they ask for this.

### Commit message format
Single summary line only, no body. Conventional commit format:
```
type(scope): description
```
Types: `feat`, `fix`, `refactor`, `chore`, `docs`, `style`, `test`, `ci`.
Scope: relevant module or subsystem name.

### PR descriptions
- Must read like a human wrote it. Casual, short.
- No markdown headers, no `## Summary` / `## Test plan` sections, no bullet checklists.
- Just a few normal sentences explaining what changed and why.
- If the diff speaks for itself, one line is fine.

## Steps

### 1. Assess the current state

Run these as **separate** Bash calls (parallel is fine):
- `git status` — see what's changed and what's staged
- `git diff` — see unstaged changes
- `git diff --cached` — see already-staged changes
- `git log --oneline -5` — recent commits for style reference

### 2. Stage files

Stage relevant changed files **by name**. Skip anything that looks like secrets (`.env`, credentials, tokens). If unsure what the user wants staged, ask.

### 3. Commit

Create the commit with a single-line conventional commit message. Pass the message via `-m`. No body, no `Co-Authored-By`.

Example:
```bash
git commit -m "feat(gui): add color picker widget"
```

If a pre-commit hook fails: fix the issue, re-stage, and create a **new** commit (never `--amend` unless the user explicitly asks).

### 4. Push

Determine the current branch. If it has no upstream, push with `-u`:
```bash
git push -u origin <branch>
```
Otherwise:
```bash
git push
```

### 5. PR (only if `$ARGUMENTS` contains "pr")

If the user passed `pr` as an argument or explicitly asked for a PR:

1. Run `git log` to see all commits on this branch vs the default branch.
2. Run `git diff` against the default branch to understand the full changeset.
3. Create the PR with `gh pr create`. Write the title and body following the PR rules above — human, casual, no markdown structure. Use a HEREDOC for the body:

```bash
gh pr create --title "short title here" --body "$(cat <<'EOF'
A few sentences about what this does and why.
EOF
)"
```

4. Output the PR URL.

## What NOT to do

- Don't read or explore code beyond git commands — this skill is just for shipping.
- Don't make changes to any files.
- Don't push without committing first.
- Don't create empty commits.
