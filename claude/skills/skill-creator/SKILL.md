---
name: skill-creator
description: Use when creating a new Claude Code skill (SKILL.md). Guides the user through an interactive interview, then generates and saves the skill file to ~/.claude/skills/.
disable-model-invocation: true
allowed-tools: Bash(mkdir *) Bash(cat *) Bash(ls *) Bash(cp *)
argument-hint: "[skill-name]"
---

# Skill Creator

Interactively create a new Claude Code skill. Follow the steps below in order.

## Phase 1 — Interview

Ask the user the following questions ONE AT A TIME. Wait for each answer before asking the next.

1. **Skill name** (if not already provided as `$ARGUMENTS`):
   - What is the name of the skill? (lowercase letters and hyphens only, e.g. `review-pr`, `daily-standup`)

2. **Trigger conditions**:
   - When should Claude automatically use this skill? Give specific phrases, situations, or symptoms.
   - Example: "When the user asks to create a PR, review a branch, or mentions 'pull request'"

3. **Purpose**:
   - What does this skill do in 1-2 sentences?

4. **Steps / instructions**:
   - List the main steps or instructions Claude should follow when this skill runs.
   - For each step, ask if there are tools, files, or commands involved.

5. **Invocation style**:
   - Should the user trigger this manually only (e.g. `/skill-name`), or can Claude also trigger it automatically?
   - → If manual-only: `disable-model-invocation: true`

6. **Forked subagent**:
   - Should this skill run in an isolated subagent context (no conversation history)?
   - → Recommended for long research or generation tasks.

7. **Save location**:
   - Personal (all projects): `~/.claude/skills/<name>/SKILL.md`  ← default
   - Dotfiles (persistent across installs): also copy to `~/GitHub/dotfiles/claude/skills/<name>/SKILL.md`

## Phase 2 — Generate

After collecting answers, generate the complete `SKILL.md` content using this template:

```
---
name: <skill-name>
description: <trigger-focused description starting with "Use when...">
[disable-model-invocation: true   # if manual-only]
[context: fork                    # if forked subagent]
[allowed-tools: Bash(*) ...]      # if specific tools needed
---

# <Skill Title>

## Overview
<Purpose in 1-2 sentences>

## Steps

<Numbered or bulleted instructions>

## Notes
<Edge cases, warnings, examples if any>
```

Rules for good SKILL.md:
- `description` must start with "Use when" and describe TRIGGERING CONDITIONS (not what it does)
- Keep `description` under 500 characters
- `name` field: lowercase letters, numbers, and hyphens only (max 64 chars)
- Total frontmatter under 1,024 characters
- Skill body under 500 lines

## Phase 3 — Save

1. Show the generated content to the user and ask for confirmation or edits.
2. Once confirmed, run:

```bash
mkdir -p ~/.claude/skills/<skill-name>
cat > ~/.claude/skills/<skill-name>/SKILL.md << 'EOF'
<generated content>
EOF
```

3. If the user also wants it in dotfiles:

```bash
mkdir -p ~/GitHub/dotfiles/claude/skills/<skill-name>
cp ~/.claude/skills/<skill-name>/SKILL.md ~/GitHub/dotfiles/claude/skills/<skill-name>/SKILL.md
```

4. Confirm with:
   - Path where the file was saved
   - The slash command to invoke it: `/<skill-name>`
   - Reminder: the skill is live immediately (no restart needed)
