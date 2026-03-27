---
description: Comprehensive PR review using 6 specialized agents in parallel — comments, tests, error handling, types, code quality, and simplification
argument-hint: Optional scope (e.g. "focus on error handling" or specific files)
---

# Comprehensive PR Review

Run a thorough PR review using specialized agents. Each agent examines a different quality dimension.

## Scope Determination

1. Run `git diff --name-only HEAD~1` (or `git status`) to identify changed files
2. Note file types changed to determine which reviewers are most relevant
3. If `$ARGUMENTS` specifies a focus or scope, apply it

## Review Agents

Launch all applicable agents in parallel:

| Agent | Focus |
|---|---|
| `code-reviewer` | CLAUDE.md compliance, bugs, style violations |
| `comment-analyzer` | Comment accuracy, completeness, technical debt |
| `pr-test-analyzer` | Test coverage quality and behavioral gaps |
| `silent-failure-hunter` | Error handling, silent failures, swallowed exceptions |
| `type-design-analyzer` | Type encapsulation and invariant quality (skip if no new types) |
| `code-simplifier` | Clarity, DRY, readability improvements |

Pass each agent: the list of changed files and the diff content.

## Results Aggregation

Consolidate all findings into four categories:

### 🔴 Critical Issues
Must fix before merging — bugs, security issues, silent failures, confidence 90+

### 🟡 Important Improvements
Should fix — guideline violations, test gaps, poor error handling, confidence 80-89

### 💡 Suggestions
Optional — simplification opportunities, comment improvements, type design

### ✅ Strengths
Notable positive aspects worth calling out

## Output

Present the consolidated report with specific file:line references. For critical and important issues, include the concrete fix suggestion from the agent.

At the end, give a one-line verdict:
- ✅ **Ready to merge** — no critical or important issues
- ⚠️ **Needs work** — N critical, M important issues to address
