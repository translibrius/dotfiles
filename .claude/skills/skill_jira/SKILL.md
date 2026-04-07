---
name: skill_jira
description: View Jira ticket info. No args = current branch ticket. Pass a ticket key, or "mine" to see your open tickets.
argument-hint: "[EVNTS-10200 | mine | mine done]"
allowed-tools: Bash(git branch *), mcp__mcp-s__jira__get-issues, mcp__mcp-s__authenticate
---

# Jira

View Jira tickets without leaving the terminal.

## Constants

- **Project key**: EVNTS
- **Your account ID**: 712020:9e94ace0-1d81-4b07-9f2c-6d0833a1f746

## Modes

### No arguments — current branch ticket

1. Run `git branch --show-current` to get the branch name.
2. Extract the ticket key from the branch name. Branch format is `daumb/EVNTS-XXXX` — the ticket key is the part after the `/`. If the branch doesn't look like it contains a ticket key, tell the user and stop.
3. Fetch the ticket with JQL `key = <TICKET-KEY>` and fields `["key", "summary", "status", "issuetype", "assignee", "priority", "description", "comment"]`.
4. Display it nicely:
   ```
   EVNTS-10200: [events-guest-activities] Proper activity timestamps and sort
   Type: Story | Status: In Progress | Priority: Medium
   Assignee: Daumantas Balakauskas

   Description:
   (first ~500 chars of description, or "No description")

   https://wix.atlassian.net/browse/EVNTS-10200
   ```

### Ticket key argument (e.g. `EVNTS-10200` or just `10200`)

Same as above but use the provided key. If just a number, prepend `EVNTS-`.

### `mine` — your open tickets

Fetch with JQL: `project = EVNTS AND assignee = 712020:9e94ace0-1d81-4b07-9f2c-6d0833a1f746 AND status != Closed AND status != Resolved ORDER BY updated DESC`

Use `maxResults: 15` and fields `["key", "summary", "status", "issuetype", "priority", "updated"]`.

Display as a table:
```
Key          | Type  | Status      | Priority | Summary
EVNTS-10200  | Story | In Progress | Medium   | [events-guest-activities] Proper activity timestamps...
EVNTS-10150  | Bug   | Open        | High     | Guest count mismatch on dashboard...
```

### `mine done` — your recently resolved/closed tickets

Same as `mine` but JQL: `project = EVNTS AND assignee = 712020:9e94ace0-1d81-4b07-9f2c-6d0833a1f746 AND status in (Closed, Resolved) ORDER BY updated DESC`

Use `maxResults: 10`.
