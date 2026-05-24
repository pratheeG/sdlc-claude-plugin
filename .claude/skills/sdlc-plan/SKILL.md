---
description: SDLC Stage 2 — Read confirmed requirements from sdlc-state.json and create Jira user story cards with acceptance criteria, story points, and labels. Invoke with /sdlc-plan <jira-project-key>.
allowed-tools: Read, Write, mcp__jira__create_issue, mcp__jira__get_project, mcp__jira__update_issue, Bash
---

# SDLC Stage 2 · Jira Card Generation

You are running Stage 2 of the SDLC automation pipeline.

## Pre-check
Read `.claude/sdlc-state.json`. If `stage` is not `"ingest"`, stop and tell the user to run `/sdlc-ingest` first.

If `open_questions` has unanswered items, warn the user and ask if they want to proceed anyway.

## Input
Arguments: $ARGUMENTS (expected: Jira project key, e.g. `PROJ`)

## Your Tasks

### 1. Load requirements
Read stories and acceptance criteria from the state file.

### 2. Break down epics into stories
For each user story:
- Write a concise Jira summary (≤ 72 chars)
- Write a full description with:
  - **As a** / **I want** / **So that**
  - **Acceptance Criteria** in Given/When/Then format (min 3 scenarios)
  - **Definition of Done** checklist
- Estimate story points using Fibonacci (1, 2, 3, 5, 8, 13)
  - 1-2: trivial UI or config change
  - 3-5: standard feature with tests
  - 8-13: complex, cross-cutting, or uncertain
- Add labels: `ai-generated`, `tdd`, and any domain tags from requirements
- Set priority based on dependency order

### 3. Create sub-tasks for each story
Each story gets sub-tasks:
- `[TEST] Write failing tests for <story>`
- `[IMPL] Implement <story>`
- `[REFACTOR] Refactor <story>`

### 4. Create Jira issues
Call `mcp__jira__create_issue` for each card. Capture the returned card IDs.

### 5. Update state
Update `.claude/sdlc-state.json`:
```json
{
  "stage": "plan",
  "jira_project": "<key>",
  "cards": [
    {
      "id": "PROJ-42",
      "summary": "...",
      "points": 5,
      "url": "https://..."
    }
  ]
}
```

## Done Condition
Print a table of all created cards with IDs and URLs, then:
```
✅ Stage 2 complete. Run /sdlc-build <CARD-ID> to start implementation.
```
