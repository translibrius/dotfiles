---
name: skill_ticket
description: Create a new Jira ticket in EVNTS assigned to you. Pass a summary and optionally a type (bug/story/task).
argument-hint: "[bug|story|task] summary of the ticket"
allowed-tools: mcp__mcp-s__jira__create-issue, mcp__mcp-s__jira__update-issue, mcp__mcp-s__authenticate
---

# Ticket

Create a new Jira ticket in the EVNTS project, assigned to you.

## Constants

- **Project key**: EVNTS
- **Your account ID**: 712020:9e94ace0-1d81-4b07-9f2c-6d0833a1f746
- **Component "Events Server"**: 12013

### Issue type IDs
- Bug: 10024
- Story: 10023
- Task: 10007

## Steps

### 1. Parse arguments

`$ARGUMENTS` format: `[type] description of the ticket`

- If the first word is `bug`, `story`, or `task`, use that as the issue type. Remove it from the summary.
- If no type is specified, default to **Story**.
- The rest of the arguments become the ticket summary.

### 2. Create the ticket

Use `mcp__mcp-s__jira__create-issue` with:
- `projectKey`: "EVNTS"
- `summary`: the parsed summary
- `issueTypeId`: the ID from the table above
- `customFields`: assign to the user:
  ```json
  { "assignee": { "accountId": "712020:9e94ace0-1d81-4b07-9f2c-6d0833a1f746" } }
  ```

If the user provided extra context beyond a one-liner (like multi-line description, acceptance criteria, etc.), include it in the `description` field as markdown.

### 3. Confirm

Print a short confirmation with the ticket URL:
```
Created EVNTS-10201 (Story): Fix guest count on dashboard
https://wix.atlassian.net/browse/EVNTS-10201
```

Optionally suggest: `Run /branch EVNTS-10201 to start working on it.`
