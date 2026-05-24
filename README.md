# SDLC Automation Plugin for Claude Code

A reusable Claude Code plugin that automates the full SDLC — from reading requirements to a production-ready MR — using slash commands.

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

### 3. Configure MCP servers in `~/.claude.json`
```json
{
  "mcpServers": {
    "confluence": {
      "type": "url",
      "url": "https://mcp.atlassian.com/confluence/sse"
    },
    "jira": {
      "type": "url",
      "url": "https://mcp.atlassian.com/jira/sse"
    },
    "github": {
      "type": "url",
      "url": "https://api.githubcopilot.com/mcp/"
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

Open Claude Code in your project, then run commands in order:

```
/sdlc-ingest https://your-org.atlassian.net/wiki/spaces/PROJ/pages/12345
```
Reads requirements, surfaces clarifying questions.

```
/sdlc-plan PROJ
```
Creates Jira cards with acceptance criteria and story points.

```
/sdlc-build PROJ-42
```
TDD implementation: writes failing tests, implements, refactors.

```
/sdlc-commit
```
Semantic commit + push + MR opened on GitHub.

```
/sdlc-review
```
Agent reviews the diff, runs tests, posts inline comments.

```
/sdlc-fix
```
Autonomous loop: fixes issues, commits, pushes, re-checks until green.

```
/sdlc-status
```
Check pipeline state at any time.

---

## Plugin Structure

```
sdlc-claude-plugin/
├── CLAUDE.md                          # Project constitution (copied to target project)
├── install.sh                         # Team member setup script
├── README.md
└── .claude/
    └── skills/
        ├── sdlc-ingest/SKILL.md       →  /sdlc-ingest
        ├── sdlc-plan/SKILL.md         →  /sdlc-plan
        ├── sdlc-build/SKILL.md        →  /sdlc-build
        ├── sdlc-commit/SKILL.md       →  /sdlc-commit
        ├── sdlc-review/SKILL.md       →  /sdlc-review
        ├── sdlc-fix/SKILL.md          →  /sdlc-fix
        └── sdlc-status/SKILL.md       →  /sdlc-status
```

## How state is passed between stages
Each skill reads and writes `.claude/sdlc-state.json` (git-ignored).
This file is the pipeline's memory — no context is lost between commands.

## Updating the plugin
```bash
bash /path/to/sdlc-claude-plugin/install.sh
```
Re-running install updates all skills in place.
