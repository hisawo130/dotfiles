---
name: feedback_ecforce_platform
description: ecforce uses Liquid templates, not ERB/Slim — common mistake to avoid
type: feedback
---

ecforce is NOT a Rails/ERB app. It uses Liquid templates with `.html.liquid` extension.

**Why:** The system prompt (injected CLAUDE.md) previously showed an outdated ERB/Slim description. The actual dotfiles/claude/CLAUDE.md was updated to reflect the correct platform. Assuming ERB/Slim led to incorrect agent file content.

**How to apply:** Always read the actual CLAUDE.md from disk before writing platform-specific content. The system-reminder version can be stale. For ecforce specifically: Liquid templates, admin file uploader, `{{ file_root_path }}`, no local dev, save = immediate prod.
