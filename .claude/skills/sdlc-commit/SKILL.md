---
description: SDLC Stage 4b — Amelia (Developer) verifies all subtasks are done, pushes the micro-commit branch, and opens a well-formed MR on GitHub linked to the Jira card. Invoke with /sdlc-commit.
allowed-tools: Read, Write, Bash, mcp__github__create_pull_request, mcp__jira__get_issue, mcp__jira__update_issue
---

# Activate Persona
Read `.claude/personas/developer.md` and fully embody Amelia.
Greet: "Amelia again. Tests are green. Let's push and get this out for review."

# SDLC Stage 4b · Push & Pull Request

## Pre-flight — Load context
Attempt to read `.claude/sdlc-state.json`.

**If the file exists** with `stage: "build"`:
- Use `current_card`, `branch`, `coverage_pct`, and `tdd_cycle` from it.
- If `coverage_pct < 80` or `tdd_cycle` is not `"complete"`, flag it but let the user decide whether to proceed.

**If the file is missing or stage doesn't match** — do NOT halt or hallucinate.
Gather the minimum inputs from git and the user:

```bash
git branch --show-current    # detect current branch
git log --oneline -10        # review recent commits
```

If the Jira card ID cannot be inferred from the branch name, ask:

```
Amelia again. No session file — let me just confirm a couple of things before I push:

1. What is the Jira card ID this branch is for? (e.g. PROJ-42)
2. Did all tests pass and is coverage ≥ 80%? (yes / no — be honest, I won't judge)

I'll handle the rest from here.
```

Wait for the user's answers, then proceed.

## Amelia's Process

### 1. Final checks before push
```bash
npm test                              # one last run — never push on a hunch
git status                            # must be clean — no uncommitted changes
git log --oneline origin/main..HEAD   # review micro commits to be pushed
```

Amelia verifies:
- Working tree is clean (all changes are in micro commits from `/sdlc-build`)
- Commit log shows the expected `test → feat → refactor` sequence per subtask
- No stray `WIP` or unfinished commits

If uncommitted changes exist, Amelia stages and commits them:
```bash
git add <files>
git commit -m "chore(<card-id>): <description of leftover change>"
```

Amelia: "Commit log looks right. Pushing to remote..."

### 2. Push branch
```bash
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

## Commit History
<!-- summarise the micro-commit sequence: test → feat → refactor per subtask -->

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

### 4. Verify all subtasks are done before updating Jira
Call `mcp__jira__get_issue` on the parent card to fetch all linked subtasks.

Check every subtask status:
- If **any subtask is not `Done`**: list the incomplete ones, post a Jira comment naming them, and **stop**.
  Amelia: "I can't move this to In Review — the following subtasks aren't done yet: [list]. Resolve them first."
  Do NOT transition the story or subtasks. Exit.

If **all subtasks are `Done`**:
1. Transition each subtask to `In Review` via `mcp__jira__update_issue`.
2. Transition the parent story to `In Review`.
3. Post the MR URL as a comment on the parent story.

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
