# SDLC Automation Plugin for Claude Code

A reusable Claude Code plugin that automates the full SDLC — from reading requirements to a production-ready PR — using a single orchestrator command that delegates to specialised AI persona agents.

## How it works

```
/sdlc <stage> [args]
       │
       ▼
  Orchestrator  ──routes to──►  sdlc-alex      (Product Manager)      ← start here
                                sdlc-winston   (Solution Architect)
                                sdlc-priya     (Business Analyst)
                                sdlc-marcus    (Scrum Master)
                                sdlc-amelia    (Senior Developer)
                                sdlc-quinn     (QA Engineer)
                                sdlc-devon     (Staff Engineer)
```

Each agent runs in an isolated context with only the tools it needs, writes its results to a shared state file, and hands off cleanly to the next stage.

---

## Quick Start

### 1. Clone this plugin repo
```bash
git clone <your-org>/sdlc-claude-plugin
```

### 2. Run the installer in your project
```bash
cd /path/to/your-project
bash /path/to/sdlc-claude-plugin/install.sh
```

This copies:
- `.claude/agents/` — 6 persona sub-agents
- `.claude/skills/sdlc/` — the orchestrator slash command
- `CLAUDE.md` — project conventions
- `.mcp.json` — MCP server config template

### 3. Configure MCP credentials

Edit `.mcp.json` in your project (or `~/.mcp.json` globally):
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

### 4. Set environment variables
```bash
export ATLASSIAN_TOKEN=your_atlassian_api_token
export GITHUB_TOKEN=your_github_pat
```

---

## Usage

One command for everything:

```
/sdlc <stage> [args]
```

### Full pipeline reference

| Stage         | Command                              | Agent   | What it does                                              |
|---------------|--------------------------------------|---------|-----------------------------------------------------------|
| 0 · Brainstorm| `/sdlc brainstorm [idea]`            | Alex    | Discovery conversation → create Confluence requirements   |
| 1 · Ingest    | `/sdlc ingest <confluence-url\|file>`| Winston | Read requirements, extract structure, surface questions   |
| 1b · Clarify| `/sdlc clarify`                      | Winston | Apply answers, update Confluence doc                      |
| 2 · Plan    | `/sdlc plan <PROJECT-KEY>`           | Priya   | Create Jira epics & stories with acceptance criteria      |
| 2b · Break  | `/sdlc breakdown <CARD-ID\|all>`     | Priya   | Add TDD subtasks (TEST/IMPL/REFACTOR/REVIEW) to stories   |
| 3 · Sprint  | `/sdlc sprint [sprint-name]`         | Marcus  | Check DoR, map dependencies, populate sprint board        |
| 4 · Build   | `/sdlc build <CARD-ID>`              | Amelia  | TDD implementation — Red → Green → Refactor, 80% coverage |
| 4b · Commit | `/sdlc commit`                       | Amelia  | Push branch, open GitHub PR linked to Jira card           |
| QA-A · E2E  | `/sdlc e2e <CARD-ID>`               | Quinn   | Playwright E2E tests for every acceptance scenario        |
| QA-B · Perf | `/sdlc perf <CARD-ID>`              | Quinn   | K6 load/stress/spike/soak tests from NFR SLAs             |
| 5 · Review  | `/sdlc review`                       | Devon   | Three-lens code review, inline PR comments                |
| 6 · Fix     | `/sdlc fix`                          | Devon   | Autonomous fix loop until all CI checks are green         |
| — · Status  | `/sdlc status`                       | —       | Show pipeline dashboard and next command                  |

### Auto-run stages 1–3

```
/sdlc pipeline <confluence-url> <JIRA-PROJECT-KEY>
```

Automatically chains: ingest → clarify → plan → breakdown → sprint.
Pauses before build to let you choose which card to implement first.

---

## Personas

| Agent          | Persona | Expertise                          |
|----------------|---------|------------------------------------|
| `sdlc-alex`    | Alex    | Product Manager, 10 yrs            |
| `sdlc-winston` | Winston | Solution Architect, 20 yrs         |
| `sdlc-priya`   | Priya   | Business Analyst, 12 yrs           |
| `sdlc-marcus`  | Marcus  | Scrum Master / Agile Coach, 10 yrs |
| `sdlc-amelia`  | Amelia  | Senior Developer, 8 yrs, TDD       |
| `sdlc-quinn`   | Quinn   | QA Engineer, 10 yrs, Playwright+K6 |
| `sdlc-devon`   | Devon   | Staff Engineer, 15 yrs, reviewer   |

Each agent is self-contained — persona, stage logic, and tool access in a single file.

---

## Plugin Structure

```
sdlc-claude-plugin/
├── CLAUDE.md                     # Project constitution (copied to target project)
├── README.md
├── install.sh                    # Setup script
├── .mcp.json                     # MCP server config template
└── .claude/
    ├── agents/
    │   ├── sdlc-alex.md          # Alex    — brainstorm
    │   ├── sdlc-winston.md       # Winston — ingest, clarify
    │   ├── sdlc-priya.md         # Priya   — plan, breakdown
    │   ├── sdlc-marcus.md        # Marcus  — sprint
    │   ├── sdlc-amelia.md        # Amelia  — build, commit
    │   ├── sdlc-quinn.md         # Quinn   — e2e, perf
    │   └── sdlc-devon.md         # Devon   — review, fix
    └── skills/
        └── sdlc/
            └── SKILL.md          # /sdlc orchestrator
```

---

## State file

All agents read/write `.claude/sdlc-state.json` (added to `.gitignore` by the installer).
This is the pipeline's shared memory — context is preserved across commands and agents.

Key fields written by each stage:

| Stage    | Fields written                                              |
|----------|-------------------------------------------------------------|
| ingest   | `epic`, `stories`, `acceptance_criteria`, `nfr`, `open_questions` |
| plan     | `jira_project`, `cards`, `dependency_order`                 |
| sprint   | `sprint`, `committed_stories`, `capacity_points`            |
| build    | `current_card`, `branch`, `coverage_pct`, `tdd_cycle`       |
| commit   | `pr_number`, `pr_url`                                       |
| review   | `review_result`, `blockers`, `ci_passing`                   |

---

## Conventions

- **Branch naming:** `feature/<jira-card-id>-<short-description>`
- **Commit style:** Conventional Commits — `feat:`, `fix:`, `test:`, `refactor:`
- **TDD cycle:** Red → Green → Refactor. Tests always written first.
- **Coverage threshold:** 80% minimum before a PR is production-ready.
- **PR description** must reference the Jira card ID.
- **E2E selectors:** Always `data-testid` — never CSS classes or text content.
- **Performance thresholds:** Hard pass/fail, derived from Winston's NFRs.

---

## Updating the plugin

```bash
bash /path/to/sdlc-claude-plugin/install.sh
```

Re-running install updates all agents and the orchestrator skill in place.
