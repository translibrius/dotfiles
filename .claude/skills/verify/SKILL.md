---
name: verify
description: Spawn a thorough verification agent to audit recent changes for missed spots, correctness, and consistency.
argument-hint: "[focus area or description of what to verify]"
allowed-tools: Agent, Read, Grep, Glob, Bash(cat *), Bash(git diff *), Bash(git log *), Bash(git show *)
---

# Verify

Launch an independent verification agent to audit recent work for completeness and correctness.

## Rules

- **NEVER** modify any files. This skill is read-only.
- **NEVER** run builds or tests — just analyze code.
- Use the Explore subagent type for thorough codebase analysis.
- Set thoroughness to "very thorough" — the whole point is to catch things we missed.

## Steps

### 1. Determine what to verify

If `$ARGUMENTS` is provided, use it as the focus area. Otherwise, infer from recent git changes:

Run `git diff --stat HEAD~1` (or broader if needed) to understand what changed recently.

### 2. Launch verification agent

Spawn an Explore agent with a detailed prompt covering:

#### Completeness check
- Did the change touch all the files it should have?
- Are there similar patterns in other files that were missed?
- Use Grep to search for the old patterns that should have been replaced.

#### Correctness check
- Are the replacements semantically equivalent to the originals?
- Any accidental negation flips, type mismatches, or subtle behavioral changes?
- Spot-check 5-10 call sites by reading the surrounding context.

#### Consistency check
- Are all necessary includes/imports present?
- Do new functions have proper declarations, implementations, and exports?
- Is naming consistent with existing conventions?

#### Test coverage check
- Do new functions/APIs have tests?
- Are tests registered and actually running?
- Do tests assert meaningful behavior (not trivial)?

### 3. Report findings

The agent should report in this format:

```
## Verification Results

### Completeness
(missed files/patterns, or "All clear")

### Correctness
(semantic mismatches found, or "All spot-checks passed")

### Consistency
(missing includes, naming issues, or "All consistent")

### Test Coverage
(gaps found, or "Adequate coverage")

### Overall Verdict
PASS / PASS WITH NOTES / FAIL
```

Present the agent's findings to the user as-is. Do not summarize or editorialize.
