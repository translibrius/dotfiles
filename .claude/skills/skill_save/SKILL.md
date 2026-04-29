---
name: skill_save
description: Save current session state to a resume file so a future session can pick up where you left off. Use at the end of a task or before clearing context.
allowed-tools: Bash(git *), Read, Write, Glob
---

# Save

Write a resume file to `~/.claude/plans/RESUME.md` capturing current session state.

## Rules

- ALWAYS overwrite `~/.claude/plans/RESUME.md` (one active resume at a time).
- Keep it ultra-short. Raw facts only.

## Steps

### 1. Gather state

Parallel Bash calls:
- `git branch --show-current`
- `git log --oneline -3`
- `git status --short`
- `gh pr view --json url,title 2>/dev/null || echo "no PR"`

### 2. Write resume file

Write `~/.claude/plans/RESUME.md` with this format:

```markdown
# Resume

**Branch**: daumb/XXXXX
**PR**: [PR-XXXXX](url) or "none"
**Repo**: <absolute path to repo root>
**Date**: YYYY-MM-DD

## Done
- bullet per completed item

## In Progress
- what was being worked on when session ended

## Next
- what should happen next

## Key Files
- paths to files most relevant to the work

## Notes
- anything non-obvious a fresh session needs to know
```

Keep each section 1-3 bullets max. If a section is empty, omit it.
