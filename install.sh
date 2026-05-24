#!/usr/bin/env bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  SDLC Plugin Installer
#  Usage: bash install.sh
#  Copies skills into your project's .claude/ directory.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${1:-.}"   # default: current directory

SKILLS_SRC="$PLUGIN_DIR/.claude/skills"
SKILLS_DST="$TARGET_DIR/.claude/skills"
CLAUDE_MD_SRC="$PLUGIN_DIR/CLAUDE.md"
CLAUDE_MD_DST="$TARGET_DIR/CLAUDE.md"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  SDLC Plugin Installer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Installing into: $TARGET_DIR"
echo ""

# 1. Copy skills
mkdir -p "$SKILLS_DST"
for skill_dir in "$SKILLS_SRC"/*/; do
  skill_name=$(basename "$skill_dir")
  dest="$SKILLS_DST/$skill_name"
  if [ -d "$dest" ]; then
    echo "  ↻  Updating skill: $skill_name"
  else
    echo "  +  Installing skill: $skill_name"
  fi
  cp -r "$skill_dir" "$SKILLS_DST/"
done

# 2. Copy or merge CLAUDE.md
if [ -f "$CLAUDE_MD_DST" ]; then
  echo ""
  echo "  ⚠  CLAUDE.md already exists. Appending SDLC section..."
  echo "" >> "$CLAUDE_MD_DST"
  echo "---" >> "$CLAUDE_MD_DST"
  echo "" >> "$CLAUDE_MD_DST"
  cat "$CLAUDE_MD_SRC" >> "$CLAUDE_MD_DST"
else
  cp "$CLAUDE_MD_SRC" "$CLAUDE_MD_DST"
  echo "  +  CLAUDE.md created"
fi

# 3. Gitignore state file (contains session data, not for commit)
GITIGNORE="$TARGET_DIR/.gitignore"
if [ -f "$GITIGNORE" ]; then
  if ! grep -q "sdlc-state.json" "$GITIGNORE"; then
    echo ".claude/sdlc-state.json" >> "$GITIGNORE"
    echo "  +  Added sdlc-state.json to .gitignore"
  fi
fi

# 4. Check MCP config
MCP_JSON="$HOME/.mcp.json"
echo ""
if [ -f "$MCP_JSON" ]; then
  if grep -q "confluence" "$MCP_JSON" && grep -q "jira" "$MCP_JSON" && grep -q "github" "$MCP_JSON"; then
    echo "  ✅  MCP servers detected in ~/.mcp.json"
  else
    echo "  ⚠️   MCP servers NOT fully configured in ~/.mcp.json"
    echo "      Add confluence, jira, and github MCP entries."
    echo "      See CLAUDE.md for the required config snippet."
  fi
else
  echo "  ⚠️   ~/.mcp.json not found."
  echo "      Create it with MCP server config before using the plugin."
  echo "      See CLAUDE.md for the required config snippet."
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅  Installation complete!"
echo ""
echo "  Available commands in Claude Code:"
echo "    /sdlc-ingest  <confluence-url or file>"
echo "    /sdlc-plan    <jira-project-key>"
echo "    /sdlc-build   <JIRA-CARD-ID>"
echo "    /sdlc-commit"
echo "    /sdlc-review"
echo "    /sdlc-fix"
echo "    /sdlc-status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""