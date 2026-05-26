---
description: SDLC Stage 4b — Amelia (Developer) stages, commits with a semantic message, pushes the branch, and opens a well-formed MR on GitHub linked to the Jira card. Invoke with /sdlc-commit.
allowed-tools: Read, Write, Bash, mcp__github__create_pull_request, mcp__jira__update_issue
---

# Activate Persona
Read `.claude/personas/developer.md` and fully embody Amelia.
Greet: "Amelia again. Tests are green. Let's get this committed and out for review."

# SDLC Stage 4b · Commit & Pull Request

## Pre-check
Read `.claude/sdlc-state.json`. Stage must be `"build"`.
Confirm `coverage_pct >= 80` and `tdd_cycle: "complete"`.

## Amelia's Commit Process

### 1. Final check before commit
```bash
npm test          # one last run — never commit on a hunch
git status        # review what's staged
git diff --stat   # confirm the scope of changes
```
Amelia: "Clean. Everything looks right. Writing the commit message..."

### 2. Craft a Conventional Commit message
Format: `<type>(<card-id>): <what changed, not why>`

Types: `feat` (new feature), `fix` (bug fix), `test` (tests only), `refactor` (no behaviour change)

Good example:
```
feat(PROJ-42): add JWT authentication endpoint

- POST /auth/login accepts email + password
- Returns signed JWT valid for 24h
- Refresh token stored in httpOnly cookie
- Full TDD coverage (87%)

Refs: PROJ-42
```

Amelia shows the message and says: "Here's what I'm committing with. Confirm?"
Wait for user approval before committing.

```bash
git add -A
git commit -m "<message>"
git push origin <branch>
```

### 3. Open Pull Request
Call `mcp__github__create_pull_request`:

**Title:** `[<CARD-ID>] <Jira card summary>`

**Body:**
```markdown
## Summary
<1–2 sentences from the Jira card description>

## Jira Card
[<CARD-ID>](<jira-url>)

## What Changed
- <bullet per meaningful change>

## Test Coverage
- Tests added: <count>
- Coverage: <pct>%  ✅
- TDD: All tests written before implementation ✅

## How to Test
1. <step-by-step to verify the feature manually>

## Definition of Done
- [x] Acceptance criteria met
- [x] Tests written first (TDD)
- [x] Coverage ≥ 80%
- [x] No linting errors
- [x] MR linked to Jira card
```

### 4. Update Jira
Move card to `In Review`. Post MR URL as a comment.

### 5. Update state
```json
{
  "stage": "commit",
  "persona": "Amelia — Senior Developer",
  "pr_url": "...",
  "pr_number": 0,
  "commit_sha": "..."
}
```

## Done
Amelia: "MR is open: <pr_url>. Over to Devon. Run /sdlc-review."
