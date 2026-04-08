#!/usr/bin/env python3
"""
nightly-monitor.py — API-free nightly Shopify info monitoring
Runs without Claude/LLM via GitHub Actions or cron.

Tasks:
  S1  Shopify changelog  (changelog.shopify.com feed)
  S2  GitHub repo releases  (Dawn / CLI / Hydrogen / Liquid)
  S3  Shopify API version  (shopify.dev/docs/api/usage/versioning)
  S4  Reference staleness audit
  S5  Learning metrics  (claude/learnings/ entry counts)
  FINAL  Discord notification
"""

import sys, os, re, json, subprocess, urllib.request, xml.etree.ElementTree as ET
from datetime import datetime, timezone, timedelta
from pathlib import Path
from email.utils import parsedate_to_datetime

# ── Config ────────────────────────────────────────────────────────────────────

REPO_DIR = Path(__file__).resolve().parent.parent.parent
REFS_DIR = REPO_DIR / "claude" / "references"
LEARNINGS_DIR = REPO_DIR / "claude" / "learnings"
DISCORD_WEBHOOK = os.environ.get(
    "DISCORD_WEBHOOK",
    "https://discord.com/api/webhooks/1486928286541021345/4po5j-0O5Qzdql7wBdNr0Ga0_Ian-t7P66IMj7DzHWKMuDRr9IH7OSYoHTu0S644C8E6",
)
JST = timezone(timedelta(hours=9))
JST_NOW = datetime.now(JST)
JST_DATE = JST_NOW.strftime("%Y-%m-%d")

REPOS = [
    ("dawn",     "Shopify/dawn",     ".dawn-version-last-known"),
    ("cli",      "Shopify/cli",      ".cli-version-last-known"),
    ("hydrogen", "Shopify/hydrogen", ".hydrogen-version-last-known"),
    ("liquid",   "Shopify/liquid",   ".liquid-version-last-known"),
]

# ── Helpers ───────────────────────────────────────────────────────────────────

def log(msg): print(msg, flush=True)

def fetch(url, timeout=20):
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "nightly-monitor/1.0"})
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.read().decode("utf-8", errors="replace")
    except Exception as e:
        log(f"  ⚠ fetch failed ({url}): {e}")
        return ""

def read_file(path, default=""):
    try:
        return Path(path).read_text(encoding="utf-8")
    except:
        return default

def write_file(path, content):
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    Path(path).write_text(content, encoding="utf-8")

# ── S1: Shopify Changelog ─────────────────────────────────────────────────────

def task_changelog():
    log("▶ S1: Shopify changelog")

    last_sync_file = REFS_DIR / ".shopify-changelog-last-sync"
    last_sync_str = read_file(last_sync_file).strip()
    try:
        last_sync = datetime.fromisoformat(last_sync_str.replace("Z", "+00:00"))
    except:
        last_sync = datetime.now(timezone.utc) - timedelta(days=7)

    feed = ""
    for url in [
        "https://changelog.shopify.com/feed.xml",
        "https://changelog.shopify.com/atom.xml",
        "https://shopify.dev/changelog/feed.xml",
    ]:
        feed = fetch(url)
        if feed:
            break

    if not feed:
        log("  ⚠ all changelog feeds unavailable")
        return {"count": 0, "entries": []}

    try:
        root = ET.fromstring(feed)
    except Exception as e:
        log(f"  ⚠ XML parse error: {e}")
        return {"count": 0, "entries": []}

    items = []

    # RSS
    for item in root.findall(".//item"):
        t = item.find("title")
        l = item.find("link")
        p = item.find("pubDate")
        if t is None or p is None:
            continue
        try:
            pub = parsedate_to_datetime(p.text)
            if not pub.tzinfo:
                pub = pub.replace(tzinfo=timezone.utc)
        except:
            continue
        if pub > last_sync:
            items.append((pub, (t.text or "").strip(), (l.text or "").strip() if l is not None else ""))

    # Atom
    NS = "{http://www.w3.org/2005/Atom}"
    for entry in root.findall(f".//{NS}entry"):
        t = entry.find(f"{NS}title")
        l = entry.find(f"{NS}link")
        p = entry.find(f"{NS}published") or entry.find(f"{NS}updated")
        if t is None or p is None:
            continue
        try:
            pub = datetime.fromisoformat(p.text.replace("Z", "+00:00"))
        except:
            continue
        if pub > last_sync:
            href = l.get("href", "") if l is not None else ""
            items.append((pub, (t.text or "").strip(), href))

    items.sort(key=lambda x: x[0], reverse=True)

    if items:
        write_file(last_sync_file, items[0][0].strftime("%Y-%m-%dT%H:%M:%SZ"))

    log(f"  ✓ {len(items)} new entries since {last_sync.strftime('%Y-%m-%d')}")
    return {
        "count": len(items),
        "entries": [(pub.strftime("%Y-%m-%d"), title) for pub, title, _ in items[:10]],
    }

# ── S2: GitHub Release Versions ───────────────────────────────────────────────

def get_latest_release(repo):
    data = fetch(f"https://api.github.com/repos/{repo}/releases/latest")
    if not data:
        return None, None
    try:
        j = json.loads(data)
        return j.get("tag_name", ""), j.get("published_at", "")[:10]
    except:
        return None, None

def task_versions():
    log("▶ S2: GitHub release versions")
    updates = []

    for name, repo, store_file in REPOS:
        tag, pub_date = get_latest_release(repo)
        if not tag:
            log(f"  ⚠ {name}: fetch failed")
            continue

        store_path = REFS_DIR / store_file
        last_known = read_file(store_path).strip()

        if not last_known:
            write_file(store_path, tag)
            log(f"  ✓ {name}: initialized ({tag})")
            updates.append(f"{name}:new({tag})")
        elif last_known != tag:
            write_file(store_path, tag)
            log(f"  🆕 {name}: {last_known} → {tag}")
            updates.append(f"{name}:{last_known}→{tag}")
        else:
            log(f"  · {name}: {tag} (no change)")

    return {"updates": updates}

# ── S3: Shopify API Version ───────────────────────────────────────────────────

def task_api_version():
    log("▶ S3: Shopify API version")

    store_path = REFS_DIR / ".shopify-api-last-known"
    page = fetch("https://shopify.dev/docs/api/usage/versioning")
    if not page:
        return {"alert": "", "version": "?"}

    versions = re.findall(r"20\d{2}-(?:01|04|07|10)", page)
    if not versions:
        return {"alert": "", "version": "?"}

    current = versions[0]
    last_data = read_file(store_path).strip()
    last_stable = ""
    if last_data:
        m = re.search(r"stable=(\d{4}-\d{2})", last_data)
        if m:
            last_stable = m.group(1)

    alert = ""
    if not last_stable:
        write_file(store_path, f"stable={current}\n")
        log(f"  ✓ initialized: {current}")
    elif last_stable != current:
        write_file(store_path, f"stable={current}\n")
        alert = f"{last_stable}→{current}"
        log(f"  🆕 API: {alert}")
    else:
        log(f"  · API: {current} (no change)")

    return {"alert": alert, "version": current}

# ── S4: Reference Staleness Audit ────────────────────────────────────────────

def task_staleness():
    log("▶ S4: Reference staleness audit")

    stale, aging, ok = [], [], []
    now = datetime.now(timezone.utc)

    for md_file in sorted(REFS_DIR.glob("*.md")):
        rel = str(md_file.relative_to(REPO_DIR))
        try:
            result = subprocess.run(
                ["git", "log", "--follow", "-1", "--format=%ci", "--", rel],
                capture_output=True, text=True, cwd=str(REPO_DIR), timeout=10,
            )
            raw = result.stdout.strip()
            if not raw:
                continue
            parts = raw.split()
            last_commit = datetime.fromisoformat(parts[0] + "T" + parts[1] + parts[2])
            days = (now - last_commit.astimezone(timezone.utc)).days
        except:
            continue

        has_ub = "UPDATE BEFORE USE" in read_file(md_file, "")
        name = md_file.name

        if days > 30 and has_ub:
            stale.append(f"{name}({days}d)")
        elif days > 30:
            aging.append(f"{name}({days}d)")
        else:
            ok.append(name)

    report = "\n".join(
        [f"# Reference Staleness {JST_DATE}"]
        + [f"STALE: {f}" for f in stale]
        + [f"AGING: {f}" for f in aging]
        + [f"OK: {f}" for f in ok]
    ) + "\n"
    write_file(REFS_DIR / ".staleness-report", report)

    log(f"  ✓ STALE:{len(stale)} AGING:{len(aging)} OK:{len(ok)}")
    return {"stale": stale, "aging": aging}

# ── S5: Learning Metrics ──────────────────────────────────────────────────────

def task_learning_metrics():
    log("▶ S5: Learning metrics")

    if not LEARNINGS_DIR.exists():
        return {"total": 0, "by_tag": {}}

    tag_counts = {"gotcha": 0, "recurring": 0, "pattern": 0, "correction": 0, "open": 0}
    total = 0

    for f in LEARNINGS_DIR.glob("*.md"):
        content = read_file(f, "")
        entries = [l for l in content.splitlines() if l.strip().startswith("- ")]
        total += len(entries)
        for tag in tag_counts:
            tag_counts[tag] += content.count(f"[{tag}]")

    log(f"  ✓ total:{total} gotcha:{tag_counts['gotcha']} recurring:{tag_counts['recurring']}")
    return {"total": total, "by_tag": tag_counts}

# ── Discord ───────────────────────────────────────────────────────────────────

def send_discord(message):
    if not DISCORD_WEBHOOK:
        log("⚠ DISCORD_WEBHOOK not set — skipping")
        return
    payload = json.dumps({"content": message}).encode("utf-8")
    req = urllib.request.Request(
        DISCORD_WEBHOOK,
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as r:
            log(f"  ✓ Discord: HTTP {r.status}")
    except Exception as e:
        log(f"  ⚠ Discord failed: {e}")

# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    log(f"=== nightly-monitor {JST_DATE} ===\n")

    r_cl = task_changelog()
    r_vr = task_versions()
    r_api = task_api_version()
    r_st = task_staleness()
    r_lm = task_learning_metrics()

    # Build Discord message
    lines = [f"**nightly-monitor** (API-free) {JST_DATE} 03:00 JST"]

    # S1 changelog
    lines.append(f"[S1] Changelog — new:{r_cl['count']}")
    for date, title in r_cl["entries"]:
        lines.append(f"　• {date}: {title}")

    # S2 repo versions
    v_str = " / ".join(r_vr["updates"]) if r_vr["updates"] else "no_changes"
    lines.append(f"[S2] Repos — {v_str}")

    # S3 API version
    api_info = r_api["alert"] if r_api["alert"] else f"stable={r_api['version']} (no_change)"
    lines.append(f"[S3] API — {api_info}")

    # S4 staleness
    stale_str = ", ".join(r_st["stale"]) if r_st["stale"] else "all_OK"
    lines.append(f"[S4] Stale refs — {stale_str}")

    # S5 metrics
    lm = r_lm["by_tag"]
    lines.append(
        f"[S5] Learnings — total:{r_lm['total']} "
        f"gotcha:{lm.get('gotcha',0)} recurring:{lm.get('recurring',0)} open:{lm.get('open',0)}"
    )

    lines.append("https://github.com/hisawo130/dotfiles/commits/master")

    message = "\n".join(lines)
    if len(message) > 1900:
        message = message[:1900] + "\n…(truncated)"

    log("\n--- Discord message preview ---")
    log(message)
    log("-------------------------------\n")

    send_discord(message)
    log("✅ nightly-monitor complete")


if __name__ == "__main__":
    main()
