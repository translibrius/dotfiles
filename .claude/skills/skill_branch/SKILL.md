---
name: skill_branch
description: Start working on a Jira ticket — fetch ticket info, create a daumb/TICKET-ID branch from master, and transition the ticket to In Progress.
argument-hint: "EVNTS-10200"
allowed-tools: Bash(git *), mcp__mcp-s__jira__get-issues, mcp__mcp-s__jira__get-available-transitions, mcp__mcp-s__jira__transition-issue, mcp__mcp-s__authenticate
---

# Branch

Start a new branch for a Jira ticket and transition it to In Progress.

## Rules

- **NEVER** chain shell commands with `&&` or `;`. Run each git command as its own Bash call.
- **NEVER** delete or force-checkout over uncommitted changes. If the working tree is dirty, warn the user and stop.
- Branch naming: `daumb/<TICKET-KEY>` (e.g. `daumb/EVNTS-10200`).
- Always branch from latest `master`.

## Steps

### 1. Parse the ticket key

`$ARGUMENTS` should be a Jira ticket key like `EVNTS-10200`. If the user just passed a number like `10200`, prepend `EVNTS-` automatically.

### 2. Fetch the ticket from Jira

Use `mcp__mcp-s__jira__get-issues` with JQL `key = <TICKET-KEY>` and fields `["key", "summary", "status", "issuetype", "assignee"]`.

Display a one-liner: `EVNTS-10200: [events-guest-activities] Proper activity timestamps and sort (Story, In Progress)`

### 3. Check for clean working tree

Run `git status --porcelain`. If there's output, warn the user about uncommitted changes and stop.

### 4. Create the branch

Run these as separate Bash calls:
1. `git fetch origin master`
2. `git checkout -b daumb/<TICKET-KEY> origin/master`

### 5. Transition to In Progress (if not already)

If the ticket status is NOT already "In Progress":
1. Use `mcp__mcp-s__jira__get-available-transitions` to find the transition that leads to "In Progress".
2. If found, use `mcp__mcp-s__jira__transition-issue` to move it.
3. If no "In Progress" transition is available (ticket might be in a state that can't go there), just mention the current status and skip.

### 6. Confirm

Print a short confirmation:
```
Checked out daumb/EVNTS-10200 from master
Ticket: [events-guest-activities] Proper activity timestamps and sort
Status: In Progress
```
