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

| Command              | What it does                                         |
|----------------------|------------------------------------------------------|
| `/sdlc-ingest`       | Read Confluence/Docx requirements, surface questions |
| `/sdlc-plan`         | Create Jira cards from confirmed requirements        |
| `/sdlc-build`        | TDD implementation from a Jira card                  |
| `/sdlc-commit`       | Commit, push branch, open MR on GitHub               |
| `/sdlc-review`       | Agent reviews diff + runs tests                      |
| `/sdlc-fix`          | Fix failing tests/review comments, loop until green  |
| `/sdlc-status`       | Show current pipeline state                          |

## State File
All stages read/write `.claude/sdlc-state.json`. Never edit manually.

## Conventions
- Branch naming: `feature/<jira-card-id>-<short-description>`
- Commit style: Conventional Commits (`feat:`, `fix:`, `test:`, `refactor:`)
- TDD cycle: Red → Green → Refactor. Never skip writing tests first.
- MR description must reference the Jira card ID.
- Coverage threshold: 80% minimum before MR is production-ready.
