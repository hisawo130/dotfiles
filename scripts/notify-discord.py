#!/usr/bin/env python3
"""
notify-discord.py
Usage: python3 notify-discord.py <type> <date> <status> <run_number> <webhook_url>
  type: nightly | weekly
"""
import json
import sys
import urllib.request

report_type = sys.argv[1]   # nightly | weekly
jst_date    = sys.argv[2]
status      = sys.argv[3]
run_number  = sys.argv[4]
webhook_url = sys.argv[5] if len(sys.argv) > 5 else ""

if not webhook_url:
    print("DISCORD_WEBHOOK_URL is empty — skip", file=sys.stderr)
    sys.exit(0)

ok = status == "success"

if report_type == "nightly":
    emoji = "🌙" if ok else "❌"
    color = 3066993 if ok else 15158332
    section_key = f"## {jst_date} 夜間"
else:
    emoji = "📊" if ok else "❌"
    color = 3447003 if ok else 15158332
    section_key = f"## {jst_date} 週次"

try:
    lines = open("claude/scripts/growth-log.md", encoding="utf-8").read().splitlines()
    in_section, bullets = False, []
    for line in lines:
        if section_key in line:
            in_section = True
        elif in_section and line.startswith("## "):
            break
        elif in_section and line.startswith("- ") and len(bullets) < 6:
            bullets.append("• " + line[2:])
    summary = "\n".join(bullets) if bullets else "• (変更なし)"
except Exception as e:
    summary = f"• (詳細取得失敗: {e})"

title = f"{emoji} {'Nightly Self-Improve' if report_type == 'nightly' else 'Weekly CLAUDE.md Report'} — {jst_date}"
payload = json.dumps({
    "embeds": [{
        "title": title,
        "color": color,
        "description": summary,
        "footer": {"text": f"hisawo130/dotfiles • Run #{run_number}"}
    }]
}).encode()

req = urllib.request.Request(
    webhook_url, data=payload,
    headers={"Content-Type": "application/json"}, method="POST"
)
try:
    urllib.request.urlopen(req)
    print(f"Discord notified: {title}")
except Exception as e:
    print(f"Discord notify failed: {e}", file=sys.stderr)
