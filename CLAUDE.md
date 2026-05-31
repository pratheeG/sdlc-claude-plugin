# SDLC Automation Plugin

## Purpose
This plugin automates the full Software Development Lifecycle using Claude Code.
Team members run each stage via slash commands. Each command is self-contained,
idempotent, and leaves a state file (`.claude/sdlc-state.json`) so stages can
hand off context to the next.

## Required MCP Servers
Configure these in `~/.claude.json` before using the plugin:

```json
{
  "mcpServers": {
    "confluence": {
      "type": "url",
      "url": "https://mcp.atlassian.com/confluence/sse",
      "note": "Requires Atlassian API token in env: ATLASSIAN_TOKEN"
    },
    "jira": {
      "type": "url",
      "url": "https://mcp.atlassian.com/jira/sse",
      "note": "Requires Atlassian API token in env: ATLASSIAN_TOKEN"
    },
    "github": {
      "type": "url",
      "url": "https://api.githubcopilot.com/mcp/",
      "note": "Requires GITHUB_TOKEN env var"
    }
  }
}
```

## SDLC Commands (run in order)

| Stage | Command                    | Persona  | What it does                                              |
|-------|----------------------------|----------|-----------------------------------------------------------|
| 1     | `/sdlc-ingest <url\|file>` | Winston  | Read Confluence/Docx requirements, surface questions      |
| 1b    | `/sdlc-clarify`            | Winston  | Apply answered questions, finalize requirements           |
| 2     | `/sdlc-plan <PROJECT-KEY>` | Priya    | Create Jira epics & stories with acceptance criteria      |
| 2b    | `/sdlc-breakdown <CARD>`   | Priya    | Drill into a story and generate TDD subtasks              |
| 3     | `/sdlc-sprint [SPRINT]`    | Marcus   | Check DoR, map dependencies, populate the sprint board    |
| 4     | `/sdlc-build <CARD>`       | Amelia   | TDD implementation — micro commits per Red/Green/Refactor |
| 4b    | `/sdlc-commit`             | Amelia   | Verify subtasks done, push branch, open MR on GitHub      |
| QA-A  | `/sdlc-e2e <CARD>`         | Quinn    | Write Playwright E2E tests for every acceptance scenario  |
| QA-B  | `/sdlc-perf <CARD>`        | Quinn    | Write K6 load/stress tests from NFRs                      |
| 5     | `/sdlc-review`             | Devon    | Review MR diff, run tests, post inline comments           |
| 6     | `/sdlc-fix`                | Devon    | Fix review comments + failing tests, loop until green     |
| —     | `/sdlc-status`             | Any      | Show current pipeline state and next command              |

## State File
All stages read/write `.claude/sdlc-state.json`. Never edit manually.

## Conventions
- Branch naming: `feature/<jira-card-id>-<short-description>`
- Commit style: Conventional Commits (`feat:`, `fix:`, `test:`, `refactor:`)
- TDD cycle: Red → Green → Refactor. Never skip writing tests first.
- Micro commits: one commit per TDD phase per subtask (`test:` → `feat:` → `refactor:`)
- MR description must reference the Jira card ID.
- Coverage threshold: 80% minimum before MR is production-ready.
