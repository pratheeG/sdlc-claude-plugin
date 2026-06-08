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
       ├─► sdlc-alex     (Product Manager)      ── brainstorm
       ├─► sdlc-winston  (Solution Architect)   ── ingest, clarify
       ├─► sdlc-priya    (Business Analyst)     ── plan, breakdown
       ├─► sdlc-marcus   (Scrum Master)         ── sprint
       ├─► sdlc-amelia   (Senior Developer)     ── build, commit, pr
       ├─► sdlc-quinn    (QA Engineer)          ── qa, e2e, functional, perf
       └─► sdlc-devon    (Staff Engineer)       ── review, fix
```

Each sub-agent runs in an isolated context with only the tools it needs.
The orchestrator passes the current state as context, the agent writes updates back to `.claude/sdlc-state.json`.

## Required MCP Servers

Configure in `.mcp.json` (project-level) or `~/.mcp.json` (global):

```json
{
  "mcpServers": {
    "confluence": {
      "type": "url",
      "url": "https://mcp.atlassian.com/v1/mcp"
    },
    "jira": {
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
| `brainstorm`| `[rough idea or problem]`  | sdlc-alex    | Discovery conversation → create Confluence requirements   |
| `ingest`    | `<confluence-url\|file>`   | sdlc-winston | Read requirements, extract structure, surface questions   |
| `clarify`   | —                          | sdlc-winston | Apply answers, update source document                     |
| `plan`      | `<JIRA-PROJECT-KEY>`       | sdlc-priya   | Create Jira epics & stories with acceptance criteria      |
| `breakdown` | `<CARD-ID or all>`         | sdlc-priya   | Add TDD subtasks (TEST/IMPL/REFACTOR/REVIEW) to stories   |
| `sprint`    | `[sprint-name]`            | sdlc-marcus  | Check DoR, map dependencies, populate the sprint board    |
| `build`     | `<CARD-ID>`                | sdlc-amelia  | HITL card selection → TDD implementation with micro commits |
| `commit`    | —                          | sdlc-amelia  | Final checks, push branch, show PR preview (HITL stop)    |
| `pr`        | —                          | sdlc-amelia  | Open GitHub PR after user confirms (HITL gate)            |
| `qa`        | `<CARD-ID> [types...]`     | sdlc-quinn   | HITL menu: pick test types, then run selected with micro commits |
| `e2e`       | `<CARD-ID>`                | sdlc-quinn   | Playwright E2E tests — full user journeys                 |
| `smoke`     | `<CARD-ID>`                | sdlc-quinn   | Critical-path smoke tests for post-deploy checks          |
| `acceptance`| `<CARD-ID>`                | sdlc-quinn   | AC-driven tests — one test per Given/When/Then            |
| `perf`      | `<CARD-ID>`                | sdlc-quinn   | K6 load/stress/spike/soak tests from NFR SLAs             |
| `review`    | —                          | sdlc-devon   | Review PR diff, run tests, post inline comments           |
| `fix`       | —                          | sdlc-devon   | Fix blockers + failing tests, loop until CI is green      |
| `status`    | —                          | (inline)     | Show pipeline dashboard and next command                  |
| `pipeline`  | `<url> <PROJECT-KEY>`      | all agents   | Auto-run stages 1–3 (ingest → plan → sprint)              |

### Starting from scratch (no requirements doc)
```
/sdlc brainstorm "rough idea or problem statement"
```
Alex scans the existing codebase, runs a structured discovery conversation, and creates the Confluence requirements page. Auto-chains to Winston on completion.

### Starting from an existing requirements doc
```
/sdlc ingest <confluence-url or file>
```

### Full auto-run example (ingest → plan → sprint)
```
/sdlc pipeline https://your-confluence.atlassian.net/wiki/spaces/PROJ/pages/123 MYPROJ
```

## HITL Gates

Key human-in-the-loop checkpoints enforced by the agents:

| Gate | Command | What happens |
|------|---------|--------------|
| Card selection | `/sdlc build` | Amelia lists sprint cards and stops — user picks one |
| PR gate | `/sdlc build <ID>` | Blocked if an open unmerged PR exists from a prior card |
| Branch review | `/sdlc commit` | Pushes branch, shows PR preview, stops — user reviews |
| PR creation | `/sdlc pr` | User explicitly triggers after reviewing the branch |
| Test type selection | `/sdlc qa <ID>` | Quinn presents E2E / Smoke / Acceptance / Perf menu, stops — user picks |

## State File
All agents read/write `.claude/sdlc-state.json`. Do not edit manually.
This file is added to `.gitignore` — it contains session data, not code.

## Conventions
- Branch naming: `feature/<jira-card-id>`
- Commit style: Conventional Commits (`feat:`, `fix:`, `test:`, `refactor:`)
- TDD cycle: Red → Green → Refactor. Never skip writing tests first.
- Micro commits: one commit per TDD phase per subtask (`test:` → `feat:` → `refactor:`)
- QA micro commits: one commit per test file written
- PR description must reference the Jira card ID.
- Coverage threshold: 80% minimum before PR is production-ready.
- Jira card is transitioned to **In Review** automatically after build completes.

## Agent Files
Sub-agents are in `.claude/agents/`. Each is self-contained — persona + stage logic in one file.

| File                | Persona | Stages handled                  |
|---------------------|---------|---------------------------------|
| `sdlc-alex.md`      | Alex    | brainstorm                      |
| `sdlc-winston.md`   | Winston | ingest, clarify                 |
| `sdlc-priya.md`     | Priya   | plan, breakdown                 |
| `sdlc-marcus.md`    | Marcus  | sprint                          |
| `sdlc-amelia.md`    | Amelia  | build, commit, pr               |
| `sdlc-quinn.md`     | Quinn   | qa, e2e, smoke, acceptance, perf |
| `sdlc-devon.md`     | Devon   | review, fix                     |
