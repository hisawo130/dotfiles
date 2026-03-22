---
name: feedback_autonomy
description: User's strong preference for autonomous operation — do not ask, just act
type: feedback
---

Proceed without confirmation on all non-destructive actions, including multi-file edits, batch repo operations, `gh api` writes, and git push when implied by task.

**Why:** User explicitly wants autonomous operation. Confirmation prompts interrupt flow and signal lack of confidence.

**How to apply:** State the assumption made in one line, then act. Only stop for: destructive ops (force push, file deletion, db drop), truly ambiguous intent, or external publish actions (deploy, send message).
