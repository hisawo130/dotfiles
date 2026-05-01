#!/usr/bin/env python3
"""
cleanup-local-permissions — settings.local.json の使い捨て permission を掃除

permission allowlist には日々の許可で雑多なエントリが溜まる。
明確に使い捨てとわかるものだけを安全に削除する。

判定ルール:
  EPHEMERAL (削除候補):
    - /tmp/ を含む（一時ファイルへのコマンド）
    - shell キーワード単独 (Bash(do), Bash(done), Bash(sh), 等)
    - $dir, $repo 等の変数を含むワンショット代入
    - 重複（完全一致）

  KEEP (常に保持):
    - WebFetch / WebSearch / Skill 系
    - 末尾 :* / * を持つワイルドカード許可（再利用前提）
    - 上記ルールに当てはまらない普通の Bash 許可

Usage:
  cleanup-local-permissions.py            # dry-run （何が削除されるか表示）
  cleanup-local-permissions.py --apply    # 実際に書き換える（バックアップ作成）
  cleanup-local-permissions.py --json     # 機械可読

セーフティ:
  - 必ず ~/.trash/ にタイムスタンプ付きバックアップを残す
  - 削除候補が >50% を超える場合は abort（誤検知防止）
"""
from __future__ import annotations
import argparse
import json
import re
import shutil
import sys
import time
from pathlib import Path

SETTINGS = Path.home() / ".claude/settings.local.json"
TRASH = Path.home() / ".trash"

# 単独 shell キーワードや明らかに意味を成さないトークン
SHELL_NOISE = {
    "do", "done", "if", "fi", "then", "else", "elif",
    "case", "esac", "while", "for", "until",
    "true", "false", "exit",
    "sh",  # bash自身は除外
}


def is_ephemeral(perm: str) -> tuple[bool, str]:
    """このエントリは使い捨てか? (判定, 理由) を返す。"""

    # /tmp/ を含む = 一時ファイル
    if "/tmp/" in perm:
        return True, "/tmp 参照"

    # Bash(...) の中身を抜き出して判定
    m = re.fullmatch(r"Bash\((.+)\)", perm)
    if not m:
        return False, ""
    body = m.group(1).strip()

    # 単独 shell キーワード
    if body in SHELL_NOISE:
        return True, f"shellキーワード単独 ({body})"

    # 引用符を含む one-time 代入（"..."=...形式）
    if re.match(r'^[A-Za-z_]+="\$', body):
        return True, "ワンショット変数代入"

    # 一時 mkdir -p with $variable in path (no wildcard)
    if re.match(r"^mkdir -p \"\$", body):
        return True, "ワンショット mkdir"

    # cp with concrete absolute paths (no :* wildcard) AND embedded $var
    if body.startswith("cp ") and "$" in body and ":*" not in body:
        return True, "ワンショット cp"

    return False, ""


def dedupe(items: list[str]) -> tuple[list[str], list[str]]:
    """順序保持の重複除去。"""
    seen: set[str] = set()
    kept: list[str] = []
    dups: list[str] = []
    for x in items:
        if x in seen:
            dups.append(x)
        else:
            seen.add(x)
            kept.append(x)
    return kept, dups


def analyze() -> dict:
    if not SETTINGS.exists():
        return {"error": "settings.local.json not found"}
    data = json.loads(SETTINGS.read_text())
    allow = data.get("permissions", {}).get("allow", [])

    deduped, dups = dedupe(allow)
    keep: list[str] = []
    remove: list[tuple[str, str]] = []
    for p in deduped:
        eph, reason = is_ephemeral(p)
        if eph:
            remove.append((p, reason))
        else:
            keep.append(p)

    return {
        "data": data,
        "before_count": len(allow),
        "duplicates": dups,
        "remove": remove,
        "keep": keep,
        "after_count": len(keep),
    }


def backup() -> Path:
    TRASH.mkdir(exist_ok=True)
    dest = TRASH / f"{time.strftime('%Y%m%d-%H%M%S')}-settings.local.json"
    shutil.copy2(SETTINGS, dest)
    return dest


def fmt(r: dict) -> str:
    out = ["━━━ settings.local.json 掃除プレビュー ━━━"]
    out.append(f"  before: {r['before_count']}件 → after: {r['after_count']}件 "
               f"(削除 {len(r['remove'])}件 + 重複 {len(r['duplicates'])}件)")
    if r["duplicates"]:
        out.append("")
        out.append("  [重複]")
        for d in r["duplicates"][:10]:
            out.append(f"    × {d}")
    if r["remove"]:
        out.append("")
        out.append("  [使い捨てと判定]")
        for p, reason in r["remove"]:
            out.append(f"    × {p}   ({reason})")
    if r["after_count"] == r["before_count"]:
        out.append("")
        out.append("  ✓ 掃除対象なし")
    return "\n".join(out)


def apply(r: dict) -> dict:
    """実際にファイルを書き換える。"""
    removed = len(r["remove"]) + len(r["duplicates"])
    if r["before_count"] == 0:
        return {"applied": False, "reason": "empty"}

    # セーフティ 1: 重要 prefix が削除候補に混ざっていたら即 abort（regex 暴走への保険）
    SAFE_PREFIXES = ("WebFetch", "WebSearch", "Skill(", "MCP(")
    bad = [p for p, _ in r["remove"] if p.startswith(SAFE_PREFIXES)]
    if bad:
        return {
            "applied": False,
            "reason": f"refusing to remove protected prefix entries: {bad[:3]}",
        }

    # セーフティ 2: 削除候補にワイルドカード末尾があれば abort（再利用前提のはず）
    wild = [p for p, _ in r["remove"] if p.rstrip(")").endswith(":*") or p.endswith("*)")]
    if wild:
        return {
            "applied": False,
            "reason": f"refusing to remove wildcard permission: {wild[:3]}",
        }

    # セーフティ 3: 大量削除のみガード（小さい list は通す。20件超かつ 50%以上で停止）
    if r["before_count"] > 20 and removed / r["before_count"] > 0.5:
        return {
            "applied": False,
            "reason": f"removal ratio {removed}/{r['before_count']} > 50% on large list",
        }

    backup_path = backup()
    new = dict(r["data"])
    new.setdefault("permissions", {})["allow"] = r["keep"]
    SETTINGS.write_text(json.dumps(new, indent=2, ensure_ascii=False) + "\n")
    return {"applied": True, "backup": str(backup_path), "removed": removed}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true", help="実際に書き換える")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    r = analyze()
    if "error" in r:
        print(r["error"], file=sys.stderr)
        return 1

    if args.json:
        # data フィールドは大きすぎるので除外
        report = {k: v for k, v in r.items() if k != "data"}
        if args.apply:
            report["apply_result"] = apply(r)
        print(json.dumps(report, indent=2, ensure_ascii=False))
        return 0

    print(fmt(r))
    if args.apply:
        result = apply(r)
        if result.get("applied"):
            print(f"\n✓ 適用完了。バックアップ: {result['backup']}")
        else:
            print(f"\n✗ skip: {result.get('reason')}")
    else:
        print("\n→ 適用するには --apply")
    return 0


if __name__ == "__main__":
    sys.exit(main())
