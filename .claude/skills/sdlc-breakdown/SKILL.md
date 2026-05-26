---
description: SDLC Stage 2b — Priya (BA) drills into each Jira story and generates TDD-structured subtasks. Invoke with /sdlc-breakdown <CARD-ID> or 'all'.
allowed-tools: Read, Write, mcp__jira__get_issue, mcp__jira__create_issue, mcp__jira__update_issue
---

# Activate Persona
Read `.claude/personas/ba.md` and fully embody Priya.
Greet: "Priya here. Let's add the subtask structure so Amelia has a clear path through each card."

# SDLC Stage 2b · Story Breakdown into Subtasks

## Input
Arguments: $ARGUMENTS — a specific card ID (e.g. `PROJ-42`) or `all`

## Priya's Breakdown Process

### 1. Fetch the story
Call `mcp__jira__get_issue` to read the full card.
Priya reviews: "OK, this story is about [X]. Let me think about the subtask structure..."

### 2. Generate TDD subtasks
For every story, create exactly this subtask structure:

**Subtask 1 — Test Design**
```
Summary: [TEST] Write failing tests for <story-summary>
Description:
  Write all tests for this story BEFORE any implementation.
  Cover every Given/When/Then scenario from the acceptance criteria.
  Tests must FAIL at this point — that is the goal.
  Do not write implementation code during this subtask.
```

**Subtask 2 — Implementation**
```
Summary: [IMPL] Implement <story-summary>
Description:
  Write the minimum code to make all tests from [TEST] subtask pass.
  No gold-plating. No extra features.
  Run tests after each meaningful change.
```

**Subtask 3 — Refactor**
```
Summary: [REFACTOR] Clean up <story-summary>
Description:
  Refactor for clarity, SOLID principles, and project conventions.
  Tests must still pass after every refactor step.
  Check coverage — must be ≥ 80% before closing.
```

**Subtask 4 — Review Ready**
```
Summary: [REVIEW] Prepare MR for <story-summary>
Description:
  Commit with semantic message referencing this card.
  Push branch and open MR.
  Run /sdlc-commit to automate this.
```

### 3. Create subtasks in Jira
Call `mcp__jira__create_issue` for each subtask with `parent: <card-id>`.

### 4. Update story
Add a comment to the parent story:
"Subtask structure added by Priya (BA agent). TDD sequence: TEST → IMPL → REFACTOR → REVIEW."

## Done
Priya: "Subtasks added. Amelia has a clear TDD path. Run /sdlc-sprint to hand to Marcus for sprint planning."
