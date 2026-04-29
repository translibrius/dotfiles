---
name: skill_resume
description: Load the saved session state from RESUME.md and get back up to speed. Use at the start of a new session to continue previous work.
allowed-tools: Read, Bash(git *), Glob
---

# Resume

Read `~/.claude/plans/RESUME.md` and restore context.

## Steps

### 1. Read resume file

Read `~/.claude/plans/RESUME.md`. If it doesn't exist, tell user "No resume file found. Use /skill_save to create one."

### 2. Verify state

Parallel checks:
- `git branch --show-current` — confirm on the right branch. If not, tell user.
- `git status --short` — check for uncommitted changes.

### 3. Report

Print a short summary of where things stand:
```
Resuming: <branch> | <PR link or "no PR">
Done: <one-liner>
Next: <one-liner>
```

Then ask: "Want me to continue with <next item>, or something else?"
