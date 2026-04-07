---
name: skill_transition
description: Transition the current branch's Jira ticket to a new status (e.g. done, open, resolve).
argument-hint: "[done | open | resolve | in progress]"
allowed-tools: Bash(git branch *), mcp__mcp-s__jira__get-issues, mcp__mcp-s__jira__get-available-transitions, mcp__mcp-s__jira__transition-issue, mcp__mcp-s__authenticate
---

# Transition

Move the current branch's Jira ticket to a different workflow status.

## Steps

### 1. Get the ticket key

Run `git branch --show-current`. Extract the ticket key from the branch name (format: `daumb/EVNTS-XXXX`). If no ticket key found, tell the user and stop.

### 2. Resolve the target status

Map `$ARGUMENTS` to the Jira transition name:

| Argument | Target transition name (partial match OK) |
|---|---|
| `done`, `close` | Close Issue |
| `resolve` | Resolve Issue |
| `open`, `stop`, `todo` | Stop Progress |
| `start`, `progress`, `in progress` | Start Progress |

If `$ARGUMENTS` doesn't match any of these, list available transitions and ask the user to pick.

### 3. Get available transitions

Use `mcp__mcp-s__jira__get-available-transitions` with the ticket key.

### 4. Match and execute

Find the transition whose name best matches the target from step 2 (case-insensitive partial match).

- If found: execute it with `mcp__mcp-s__jira__transition-issue`.
- If not found: the ticket is probably already in that state, or the workflow doesn't allow it from the current status. Show the current status and list what transitions ARE available.

### 5. Confirm

```
EVNTS-10200: In Progress -> Closed
```

If no arguments were provided, just show the current status and list available transitions:
```
EVNTS-10200 is currently: In Progress

Available transitions:
  - done/close  -> Closed
  - resolve     -> Resolved
  - open/stop   -> Open
```
