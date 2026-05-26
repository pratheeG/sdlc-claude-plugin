# SDLC Automation Plugin for Claude Code

A reusable Claude Code plugin that automates the full SDLC — from reading requirements to a production-ready MR — using slash commands driven by AI personas.

## Quick Start (for each team member)

### 1. Clone this plugin repo
```bash
git clone <your-org>/sdlc-claude-plugin
```

### 2. Run the installer in your project
```bash
cd /path/to/your-project
bash /path/to/sdlc-claude-plugin/install.sh
```

### 3. Configure MCP servers in `~/.mcp.json`
```json
{
  "mcpServers": {
      "atlassian": {
          "type": "url",
          "url": " https://mcp.atlassian.com/v1/mcp"
      },
      "github": {
          "type": "url",
          "url": " https://api.githubcopilot.com/mcp"
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

## Personas

Each stage is driven by a named AI persona. Persona definitions live in `.claude/personas/`.

| Persona | Role | Stages |
|---------|------|--------|
| Winston | Solution Architect | Ingest, Clarify |
| Priya | Business Analyst | Plan, Breakdown |
| Marcus | Scrum Master | Sprint planning |
| Amelia | Senior Developer | Build, Commit |
| Quinn | QA Engineer | E2E tests, Performance tests |
| Devon | Staff Engineer | Review, Fix |

---

## Usage

Open Claude Code in your project, then run commands in order:

### Stage 1 · Requirements Ingestion
```
/sdlc-ingest <confluence-url or file>
```
Winston reads requirements, extracts structured criteria (stories, acceptance criteria, NFRs, integrations), and surfaces numbered clarifying questions before handing off.

### Stage 1b · Clarification
```
/sdlc-clarify
```
Winston walks through each open question, gets your answers, and updates the Confluence page with a dated Clarifications section.

### Stage 2 · Jira Card Generation
```
/sdlc-plan PROJ
```
Priya decomposes requirements into Jira epics and user stories with full acceptance criteria, story points (Fibonacci), and dependency ordering.

### Stage 2b · Story Breakdown
```
/sdlc-breakdown PROJ-42
/sdlc-breakdown all
```
Priya drills into each story and creates four TDD-structured subtasks: `[TEST]` → `[IMPL]` → `[REFACTOR]` → `[REVIEW]`.

> `/sdlc-sprint` is an alias for `/sdlc-breakdown`.

### Stage 4 · TDD Implementation
```
/sdlc-build PROJ-42
```
Amelia creates a feature branch and implements with strict TDD — Red (failing tests) → Green (minimal implementation) → Refactor. Enforces 80% coverage before proceeding.

### Stage 4b · Commit & Pull Request
```
/sdlc-commit
```
Amelia runs a final test pass, writes a Conventional Commit message (requires your approval), pushes the branch, and opens a well-formed PR on GitHub linked to the Jira card.

### Stage QA-A · Playwright E2E Tests
```
/sdlc-e2e PROJ-42
```
Quinn reads acceptance criteria from Confluence and Jira, scans Amelia's implementation for routes and components, then writes a full Playwright E2E suite using Page Object Model — covering happy paths, edge cases, error states, accessibility, and network resilience.

### Stage QA-B · K6 Performance Tests
```
/sdlc-perf PROJ-42
```
Quinn reads Winston's NFRs and turns every performance SLA into a K6 load test with hard pass/fail thresholds. Covers load, stress, spike, and soak scenarios. Creates a Jira bug card if any threshold fails.

### Stage 5 · Code Review
```
/sdlc-review
```
Devon reviews the PR diff through three lenses — correctness, maintainability, and security — runs tests locally, checks CI, and posts structured inline comments on GitHub (`🔴 Blocker` / `🟡 Warning` / `🔵 Suggestion`).

### Stage 6 · Autonomous Fix
```
/sdlc-fix
```
Devon reads his own review comments and failing tests, applies targeted fixes, commits, pushes, and loops until all CI checks are green. Stops and escalates after 5 iterations if issues remain.

### Any time · Pipeline Status
```
/sdlc-status
```
Shows the full stage pipeline, which persona last ran, current card/branch/MR, and exactly what to run next.

---

## Plugin Structure

```
sdlc-claude-plugin/
├── CLAUDE.md                              # Project constitution (copied to target project)
├── install.sh                             # Team member setup script
├── README.md
└── .claude/
    ├── personas/
    │   ├── architect.md                   # Winston — Solution Architect
    │   ├── ba.md                          # Priya — Business Analyst
    │   ├── scrum-master.md                # Marcus — Scrum Master
    │   ├── developer.md                   # Amelia — Senior Developer
    │   ├── qa.md                          # Quinn — QA Engineer
    │   └── reviewer.md                    # Devon — Staff Engineer
    └── skills/
        ├── sdlc-ingest/SKILL.md           →  /sdlc-ingest      (Stage 1)
        ├── sdlc-clarify/SKILL.md          →  /sdlc-clarify     (Stage 1b)
        ├── sdlc-plan/SKILL.md             →  /sdlc-plan        (Stage 2)
        ├── sdlc-breakdown/SKILL.md        →  /sdlc-breakdown   (Stage 2b)
        ├── sdlc-sprint/SKILL.md           →  /sdlc-sprint      (Stage 2b alias)
        ├── sdlc-build/SKILL.md            →  /sdlc-build       (Stage 4)
        ├── sdlc-commit/SKILL.md           →  /sdlc-commit      (Stage 4b)
        ├── sdlc-e2e/SKILL.md              →  /sdlc-e2e         (Stage QA-A)
        ├── sdlc-perf/SKILL.md             →  /sdlc-perf        (Stage QA-B)
        ├── sdlc-review/SKILL.md           →  /sdlc-review      (Stage 5)
        ├── sdlc-fix/SKILL.md              →  /sdlc-fix         (Stage 6)
        └── sdlc-status/SKILL.md           →  /sdlc-status      (any time)
```

---

## How state is passed between stages

Each skill reads and writes `.claude/sdlc-state.json` (git-ignored). This file is the pipeline's memory — no context is lost between commands.

Each stage validates the expected prior stage before running:

| Command | Requires state stage |
|---------|----------------------|
| `/sdlc-clarify` | `ingest` |
| `/sdlc-plan` | `ingest` or `clarify` |
| `/sdlc-build` | `sprint` |
| `/sdlc-commit` | `build` + `coverage_pct >= 80` + `tdd_cycle: "complete"` |
| `/sdlc-e2e` | `commit` or `review` |
| `/sdlc-perf` | `commit`, `review`, or `e2e` |
| `/sdlc-review` | `commit` |
| `/sdlc-fix` | `review` |

---

## Conventions

- **Branch naming:** `feature/<jira-card-id>-<short-description>`
- **Commit style:** Conventional Commits — `feat:`, `fix:`, `test:`, `refactor:`
- **TDD cycle:** Red → Green → Refactor. Never skip writing tests first.
- **PR description** must reference the Jira card ID.
- **Coverage threshold:** 80% minimum before a PR is production-ready.
- **E2E selectors:** Always use `data-testid` attributes — never CSS classes or text.
- **Performance thresholds:** Derived directly from Winston's captured NFRs.

---

## Updating the plugin
```bash
bash /path/to/sdlc-claude-plugin/install.sh
```
Re-running install updates all skills and personas in place.
