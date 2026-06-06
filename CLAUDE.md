# SDLC Automation Plugin

## Purpose
This plugin automates the full Software Development Lifecycle using Claude Code.
A single orchestrator command (`/sdlc`) routes to specialised persona sub-agents.
Each agent is self-contained, writes a shared state file, and hands off cleanly to the next stage.

## Architecture — Orchestrator + Sub-agents

```
/sdlc <stage> [args]
       │
       ▼
  Orchestrator (skill)
       │
       ├─► sdlc-winston  (Solution Architect)  ── ingest, clarify
       ├─► sdlc-priya    (Business Analyst)     ── plan, breakdown
       ├─► sdlc-marcus   (Scrum Master)         ── sprint
       ├─► sdlc-amelia   (Senior Developer)     ── build, commit
       ├─► sdlc-quinn    (QA Engineer)          ── e2e, perf
       └─► sdlc-devon    (Staff Engineer)       ── review, fix
```

Each sub-agent runs in an isolated context with only the tools it needs.
The orchestrator passes the current state as context, the agent writes updates back to `.claude/sdlc-state.json`.

## Required MCP Servers

Configure in `.mcp.json` (project-level) or `~/.mcp.json` (global):

```json
{
  "mcpServers": {
    "atlassian": {
      "type": "url",
      "url": "https://mcp.atlassian.com/v1/mcp"
    },
    "github": {
      "type": "url",
      "url": "https://api.githubcopilot.com/mcp"
    }
  }
}
```

## Primary Command — Orchestrator

```
/sdlc <stage> [args]
```

| Stage       | Args                       | Agent        | What it does                                              |
|-------------|----------------------------|--------------|-----------------------------------------------------------|
| `ingest`    | `<confluence-url\|file>`   | sdlc-winston | Read requirements, extract structure, surface questions   |
| `clarify`   | —                          | sdlc-winston | Apply answers, update source document                     |
| `plan`      | `<JIRA-PROJECT-KEY>`       | sdlc-priya   | Create Jira epics & stories with acceptance criteria      |
| `breakdown` | `<CARD-ID or all>`         | sdlc-priya   | Add TDD subtasks (TEST/IMPL/REFACTOR/REVIEW) to stories   |
| `sprint`    | `[sprint-name]`            | sdlc-marcus  | Check DoR, map dependencies, populate the sprint board    |
| `build`     | `<CARD-ID>`                | sdlc-amelia  | TDD implementation — micro commits per Red/Green/Refactor |
| `commit`    | —                          | sdlc-amelia  | Verify subtasks done, push branch, open PR on GitHub      |
| `e2e`       | `<CARD-ID>`                | sdlc-quinn   | Write Playwright E2E tests for every acceptance scenario  |
| `perf`      | `<CARD-ID>`                | sdlc-quinn   | Write K6 load/stress/spike/soak tests from NFRs           |
| `review`    | —                          | sdlc-devon   | Review PR diff, run tests, post inline comments           |
| `fix`       | —                          | sdlc-devon   | Fix blockers + failing tests, loop until CI is green      |
| `status`    | —                          | (inline)     | Show pipeline dashboard and next command                  |
| `pipeline`  | `<url> <PROJECT-KEY>`      | all agents   | Auto-run stages 1–3 (ingest → plan → sprint)              |

### Full auto-run example
```
/sdlc pipeline https://your-confluence.atlassian.net/wiki/spaces/PROJ/pages/123 MYPROJ
```

## Legacy Individual Commands (backwards compatible)

The original per-stage skills still work if you prefer them:

```
/sdlc-ingest  <url|file>
/sdlc-clarify
/sdlc-plan    <PROJECT-KEY>
/sdlc-breakdown <CARD-ID|all>
/sdlc-sprint  [sprint-name]
/sdlc-build   <CARD-ID>
/sdlc-commit
/sdlc-e2e     <CARD-ID>
/sdlc-perf    <CARD-ID>
/sdlc-review
/sdlc-fix
/sdlc-status
```

## State File
All agents read/write `.claude/sdlc-state.json`. Do not edit manually.
This file is added to `.gitignore` by the installer — it contains session data, not code.

## Conventions
- Branch naming: `feature/<jira-card-id>-<short-description>`
- Commit style: Conventional Commits (`feat:`, `fix:`, `test:`, `refactor:`)
- TDD cycle: Red → Green → Refactor. Never skip writing tests first.
- Micro commits: one commit per TDD phase per subtask (`test:` → `feat:` → `refactor:`)
- PR description must reference the Jira card ID.
- Coverage threshold: 80% minimum before PR is production-ready.

## Agent Files
Sub-agents are in `.claude/agents/`. Each is self-contained — persona + stage logic in one file.

| File                | Persona | Stages handled          |
|---------------------|---------|-------------------------|
| `sdlc-winston.md`   | Winston | ingest, clarify         |
| `sdlc-priya.md`     | Priya   | plan, breakdown         |
| `sdlc-marcus.md`    | Marcus  | sprint                  |
| `sdlc-amelia.md`    | Amelia  | build, commit           |
| `sdlc-quinn.md`     | Quinn   | e2e, perf               |
| `sdlc-devon.md`     | Devon   | review, fix             |
