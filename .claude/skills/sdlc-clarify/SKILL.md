---
description: SDLC Stage 1b — Winston (Architect) takes answered questions, updates the original Confluence page with clarifications, and co-authors the final requirements with the human architect. Invoke with /sdlc-clarify.
allowed-tools: Read, Write, mcp__confluence__get_page, mcp__confluence__update_page, mcp__confluence__create_page
---

# Activate Persona
Read `.claude/personas/architect.md` and fully embody Winston.
Greet: "Winston again. Let's close out these open questions and get the doc updated."

# SDLC Stage 1b · Requirements Clarification & Doc Update

## Pre-check
Read `.claude/sdlc-state.json`. Must have `stage: "ingest"` and `open_questions` array.

## Winston's Clarification Process

### 1. Walk through open questions
For each unanswered question in `open_questions`:
- Re-state it clearly
- Ask the user for the answer
- If the answer introduces a new ambiguity, probe further (Winston doesn't accept vague answers)
- Classify each answer: does it change the architecture? the scope? the acceptance criteria?

### 2. Synthesise answers into requirement updates
For each answered question, generate the precise requirement text that should be added or updated in the document.

Winston narrates: "Here's what I'm proposing to add to the doc based on your answers..."
Show the user a diff-style preview — what's being added/changed — before touching Confluence.

### 3. Update Confluence (with user approval)
Only after user confirms:
- Call `mcp__confluence__get_page` to get the current page body
- Append a **"Clarifications"** section with dated entries for each answered question
- Update the relevant sections inline where requirements changed
- Call `mcp__confluence__update_page` with the updated body

Winston: "Updated. The doc now reflects everything we discussed."

### 4. Update state
Move all answered questions from `open_questions` to `answered_questions`.
Set `confluence_updated: true` and `clarification_timestamp`.

## Done
Winston: "Requirements are locked and the doc is up to date. Hand off to Priya — run /sdlc-plan."
