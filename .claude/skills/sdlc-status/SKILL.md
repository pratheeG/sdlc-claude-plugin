---
description: Show the current SDLC pipeline status — which persona last ran, what stage you're on, and exactly what to run next. Available to all roles at any time. Invoke with /sdlc-status.
allowed-tools: Read, mcp__jira__get_issue, mcp__github__get_pull_request
---

# SDLC Pipeline Status

Read `.claude/sdlc-state.json`.

If the file doesn't exist:
```
ℹ️  No active SDLC session.
Start with: /sdlc-ingest <confluence-url or file>
Winston (Architect) will handle Stage 1.
```

Otherwise, print:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  SDLC Pipeline · <epic name>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Stage 1a · Ingest     Winston (Architect)   ✅ / ⏳
  Stage 1b · Clarify    Winston (Architect)   ✅ / ⏳ / skipped
  Stage 2a · Plan       Priya (BA)            ✅ / ⏳
  Stage 2b · Breakdown  Priya (BA)            ✅ / ⏳ / skipped
  Stage 3  · Sprint     Marcus (Scrum Master) ✅ / ⏳
  Stage 4a · Build      Amelia (Developer)    ✅ / ⏳
  Stage 4b · Commit     Amelia (Developer)    ✅ / ⏳
  Stage 5  · Review     Devon (Staff Eng.)    ✅ / ⏳
  Stage 6  · Fix        Devon (Staff Eng.)    ✅ / ⏳
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Last run by: <persona from state>
  Current card: <card-id> — <summary>
  Branch: <branch>
  MR: <pr_url>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ▶  Next: /<command>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If a card ID is in state, call `mcp__jira__get_issue` for live Jira status.
If a PR number is in state, call `mcp__github__get_pull_request` for live CI status.
