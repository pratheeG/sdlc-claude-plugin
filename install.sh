#!/usr/bin/env bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  SDLC Plugin Installer
#  Usage: bash install.sh [target-directory]
#  Copies agents, orchestrator skill, and CLAUDE.md into
#  your project's .claude/ directory.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${1:-.}"   # default: current directory

AGENTS_SRC="$PLUGIN_DIR/.claude/agents"
AGENTS_DST="$TARGET_DIR/.claude/agents"

SKILL_SRC="$PLUGIN_DIR/.claude/skills/sdlc"
SKILL_DST="$TARGET_DIR/.claude/skills/sdlc"

CLAUDE_MD_SRC="$PLUGIN_DIR/CLAUDE.md"
CLAUDE_MD_DST="$TARGET_DIR/CLAUDE.md"

MCP_JSON_SRC="$PLUGIN_DIR/.mcp.json"
MCP_JSON_DST="$TARGET_DIR/.mcp.json"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  SDLC Plugin Installer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Installing into: $TARGET_DIR"
echo ""

# ── 1. Copy sub-agents ────────────────────────────────────
echo "  Installing persona agents..."
mkdir -p "$AGENTS_DST"
for agent_file in "$AGENTS_SRC"/*.md; do
  agent_name=$(basename "$agent_file")
  if [ -f "$AGENTS_DST/$agent_name" ]; then
    echo "  ↻  Updating agent: $agent_name"
  else
    echo "  +  Installing agent: $agent_name"
  fi
  cp "$agent_file" "$AGENTS_DST/"
done

# ── 2. Copy orchestrator skill ───────────────────────────
echo ""
echo "  Installing orchestrator skill..."
mkdir -p "$SKILL_DST"
if [ -f "$SKILL_DST/SKILL.md" ]; then
  echo "  ↻  Updating skill: sdlc"
else
  echo "  +  Installing skill: sdlc"
fi
cp "$SKILL_SRC/SKILL.md" "$SKILL_DST/"

# ── 3. Copy or merge CLAUDE.md ───────────────────────────
echo ""
if [ -f "$CLAUDE_MD_DST" ]; then
  echo "  ⚠  CLAUDE.md already exists. Appending SDLC section..."
  echo "" >> "$CLAUDE_MD_DST"
  echo "---" >> "$CLAUDE_MD_DST"
  echo "" >> "$CLAUDE_MD_DST"
  cat "$CLAUDE_MD_SRC" >> "$CLAUDE_MD_DST"
else
  cp "$CLAUDE_MD_SRC" "$CLAUDE_MD_DST"
  echo "  +  CLAUDE.md created"
fi

# ── 4. Copy .mcp.json if not present ─────────────────────
if [ ! -f "$MCP_JSON_DST" ]; then
  cp "$MCP_JSON_SRC" "$MCP_JSON_DST"
  echo "  +  .mcp.json created (add your Atlassian + GitHub credentials)"
else
  echo "  ✓  .mcp.json already exists — skipping"
fi

# ── 5. Gitignore state file ───────────────────────────────
GITIGNORE="$TARGET_DIR/.gitignore"
if [ -f "$GITIGNORE" ]; then
  if ! grep -q "sdlc-state.json" "$GITIGNORE"; then
    echo ".claude/sdlc-state.json" >> "$GITIGNORE"
    echo "  +  Added sdlc-state.json to .gitignore"
  fi
fi

# ── 6. Check MCP config ───────────────────────────────────
echo ""
mcp_ok=false
for mcp_file in "$MCP_JSON_DST" "$HOME/.mcp.json"; do
  if [ -f "$mcp_file" ] && grep -q "atlassian" "$mcp_file" && grep -q "github" "$mcp_file"; then
    echo "  ✅  MCP servers detected in $mcp_file"
    mcp_ok=true
    break
  fi
done
if [ "$mcp_ok" = false ]; then
  echo "  ⚠️   Atlassian + GitHub MCP servers not configured."
  echo "      Edit .mcp.json and add your credentials."
  echo "      See CLAUDE.md for the required config snippet."
fi

# ── 7. Summary ────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅  Installation complete!"
echo ""
echo "  Agents installed (.claude/agents/):"
echo "    sdlc-winston  Winston  · ingest, clarify"
echo "    sdlc-priya    Priya    · plan, breakdown"
echo "    sdlc-marcus   Marcus   · sprint"
echo "    sdlc-amelia   Amelia   · build, commit"
echo "    sdlc-quinn    Quinn    · e2e, perf"
echo "    sdlc-devon    Devon    · review, fix"
echo ""
echo "  Usage — one command for everything:"
echo "    /sdlc <stage> [args]"
echo ""
echo "  Examples:"
echo "    /sdlc ingest  <confluence-url or file>"
echo "    /sdlc plan    <JIRA-PROJECT-KEY>"
echo "    /sdlc build   <CARD-ID>"
echo "    /sdlc review"
echo "    /sdlc status"
echo ""
echo "  Full auto-run (stages 1 → sprint):"
echo "    /sdlc pipeline <confluence-url> <JIRA-PROJECT-KEY>"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
