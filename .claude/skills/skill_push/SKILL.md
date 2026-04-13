---
name: skill_push
description: Stage, commit, push, and optionally open a PR. Follows git conventions — no Co-Authored-By, single-line conventional commits, human PR descriptions.
argument-hint: "[pr]"
allowed-tools: Bash(git *), Bash(gh *), Read, Grep, Glob
---

# Push

Stage changes, commit, push to remote, optionally create PR.

## Rules — follow these exactly

### Shell discipline
- **NEVER** chain commands with `&&` or `;` or `||`. Run each git/gh command as own separate Bash call.
- **NEVER** `cd` anywhere. Already in project root.
- **NEVER** add `Co-Authored-By` line to commit messages.
- **NEVER** use `--no-verify`, `--no-gpg-sign`, or any hook-bypass flag.
- **NEVER** use `-i` (interactive) flags on any git command.
- **NEVER** use `git add -A` or `git add .` — stage specific files by name.
- **NEVER** force-push to `master`/`main`. Warn user and stop if they ask.

### Commit message format
Single summary line only, no body.

**Standalone commits** (pushing directly to branch with no PR, or first commit on new PR branch):
Use conventional commit format: `type(scope): description`
Types: `feat`, `fix`, `refactor`, `chore`, `docs`, `style`, `test`, `ci`.
Scope: relevant module or subsystem name.

**Follow-up commits inside existing PR branch** (branch already has commits beyond base):
Write casual, human commit message. No conventional commit prefix — describe what changed in plain English. Keep short.
Examples: `fix the off-by-one in retry loop`, `actually handle the nil case`, `clean up unused imports`.

### PR descriptions
- Must read like human wrote it. Casual, short.
- No markdown headers, no `## Summary` / `## Test plan` sections, no bullet checklists.
- Max 1 sentence. If diff speaks for itself, even that can be skipped.

## Steps

### 1. Assess current state

Run as **separate** Bash calls (parallel fine):
- `git status` — what changed and staged
- `git diff` — unstaged changes
- `git diff --cached` — already-staged changes
- `git log --oneline -5` — recent commits for style reference

### 2. Stage files

Stage relevant changed files **by name**. Skip anything that looks like secrets (`.env`, credentials, tokens). If unsure what user wants staged, ask.

### 3. Commit

Create commit with single-line message via `-m`. No body, no `Co-Authored-By`.

To decide format: check `git log --oneline` — see if branch already has commits beyond base branch. First commit (or standalone push) → conventional format. Branch has prior commits (follow-up work inside PR) → casual human message.

Examples:
```bash
# first commit / standalone
git commit -m "feat(gui): add color picker widget"

# follow-up commit inside a PR
git commit -m "fix the hover state on dark theme"
```

If pre-commit hook fails: fix issue, re-stage, create **new** commit (never `--amend` unless user explicitly asks).

### 4. Push

Determine current branch. If no upstream, push with `-u`:
```bash
git push -u origin <branch>
```
Otherwise:
```bash
git push
```

### 5. PR (only if `$ARGUMENTS` contains "pr")

If user passed `pr` as argument or explicitly asked for PR:

1. Run `git log` — see all commits on branch vs default branch.
2. Run `git diff` against default branch — understand full changeset.
3. Create PR with `gh pr create`. **Title** uses conventional commit format (`type(scope): description`). **Body** follows PR rules above — human, casual, no markdown structure. Use HEREDOC for body:

```bash
gh pr create --title "short title here" --body "$(cat <<'EOF'
A few sentences about what this does and why.
EOF
)"
```

4. Output PR URL.

## What NOT to do

- Don't read or explore code beyond git commands — skill just for shipping.
- Don't make changes to any files.
- Don't push without committing first.
- Don't create empty commits.