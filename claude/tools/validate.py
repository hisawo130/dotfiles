#!/usr/bin/env python3
"""validate.py — Mechanical code validation in a single call.

Replaces most of what the reviewer agent does mechanically.

Usage:
  python3 validate.py '{"files": ["sections/hero.liquid"], "checks": ["liquid", "schema", "completeness"]}'
  python3 validate.py '{"action": "pre-push"}'
  echo '{"files": ["*.liquid"], "platform": "shopify"}' | python3 validate.py

Actions:
  review     — Run all applicable checks on specified files (default)
  liquid     — Liquid syntax checks only
  schema     — JSON schema validation only
  pre-push   — Pre-push checks (staged files, sensitive file detection)
"""

import json
import os
import re
import subprocess
import sys
from pathlib import Path


def run(cmd: list[str]) -> tuple[int, str]:
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
    return r.returncode, (r.stdout + r.stderr).strip()


def resolve_files(file_patterns: list[str]) -> list[Path]:
    """Resolve glob patterns and explicit paths to actual files."""
    files = []
    for p in file_patterns:
        if "*" in p or "?" in p:
            files.extend(Path(".").glob(p))
        else:
            path = Path(p)
            if path.is_file():
                files.append(path)
    return sorted(set(files))


def check_liquid(filepath: Path) -> list[dict]:
    """Check Liquid template for common issues."""
    errors = []
    try:
        content = filepath.read_text(encoding="utf-8")
    except Exception as e:
        return [{"type": "read_error", "severity": "critical", "message": str(e)}]

    # Unmatched tags
    for tag in ["if", "for", "unless", "capture", "form", "paginate", "case"]:
        opens = len(re.findall(rf"\{{%\s*{tag}\b", content))
        closes = len(re.findall(rf"\{{% \s*end{tag}\s*%\}}", content))
        if opens != closes:
            errors.append({
                "type": "unmatched_tag",
                "severity": "critical",
                "message": f"{{% {tag} %}} count ({opens}) != {{% end{tag} %}} count ({closes})",
            })

    # Deprecated {% include %} (Shopify OS 2.0)
    includes = re.findall(r"\{%[-\s]*include\s+['\"]([^'\"]+)['\"]", content)
    for inc in includes:
        errors.append({
            "type": "include_deprecated",
            "severity": "warning",
            "message": f"{{% include '{inc}' %}} → use {{% render '{inc}' %}}",
        })

    # Hardcoded asset URLs (ecforce check)
    hardcoded = re.findall(r'(?:src|href)=["\']https?://[^"\']+\.(css|js|png|jpg|svg)', content)
    for url in hardcoded:
        errors.append({
            "type": "hardcoded_url",
            "severity": "warning",
            "message": f"Hardcoded asset URL found, use asset_url filter or file_root_path",
        })

    return errors


def check_schema(filepath: Path) -> list[dict]:
    """Validate {% schema %} JSON block in Liquid files."""
    errors = []
    try:
        content = filepath.read_text(encoding="utf-8")
    except Exception:
        return []

    schema_match = re.search(
        r"\{%[-\s]*schema\s*[-]?%\}(.*?)\{%[-\s]*endschema\s*[-]?%\}",
        content,
        re.DOTALL,
    )
    if not schema_match:
        return []

    schema_text = schema_match.group(1).strip()
    try:
        schema = json.loads(schema_text)
    except json.JSONDecodeError as e:
        return [{"type": "invalid_schema_json", "severity": "critical", "message": str(e)}]

    # Check for duplicate setting IDs
    settings = schema.get("settings", [])
    blocks = schema.get("blocks", [])
    all_settings = list(settings)
    for block in blocks:
        all_settings.extend(block.get("settings", []))

    ids = [s.get("id") for s in all_settings if s.get("id")]
    seen = set()
    for sid in ids:
        if sid in seen:
            errors.append({
                "type": "duplicate_setting_id",
                "severity": "critical",
                "message": f"Duplicate setting ID: '{sid}'",
            })
        seen.add(sid)

    return errors


def check_completeness(filepath: Path) -> list[dict]:
    """Check for incomplete code markers."""
    errors = []
    try:
        content = filepath.read_text(encoding="utf-8")
    except Exception:
        return []

    patterns = [
        (r"//\s*\.\.\.\s*rest\s*of\s*code", "Incomplete code marker: '// ... rest of code'"),
        (r"#\s*TODO", "TODO comment found"),
        (r"//\s*FIXME", "FIXME comment found"),
    ]
    for pattern, msg in patterns:
        if re.search(pattern, content, re.IGNORECASE):
            errors.append({"type": "completeness", "severity": "warning", "message": msg})

    return errors


def check_smartphone_variant(filepath: Path) -> list[dict]:
    """Check if ecforce desktop template has a smartphone variant."""
    errors = []
    name = filepath.stem
    if "+smartphone" in name:
        return []

    sp_name = name + "+smartphone" + filepath.suffix
    sp_path = filepath.parent / sp_name
    if sp_path.exists():
        errors.append({
            "type": "smartphone_variant",
            "severity": "warning",
            "message": f"Smartphone variant exists: {sp_path}. May need same change.",
        })
    return errors


def check_pre_push() -> dict:
    """Pre-push validation: staged sensitive files, settings_data.json."""
    errors = []
    _, staged = run(["git", "diff", "--cached", "--name-only"])
    staged_files = staged.splitlines() if staged else []

    sensitive = ["settings_data.json", ".env", "credentials.json", ".secrets"]
    for f in staged_files:
        basename = os.path.basename(f)
        if basename in sensitive:
            errors.append({
                "type": "sensitive_file_staged",
                "severity": "critical",
                "message": f"Sensitive file staged: {f}",
            })

    return {
        "verdict": "FAIL" if any(e["severity"] == "critical" for e in errors) else "PASS",
        "errors": errors,
        "staged_files": staged_files,
    }


def review(files: list[str], platform: str = "auto", checks: list[str] | None = None) -> dict:
    """Run all applicable checks on files."""
    if checks is None:
        checks = ["liquid", "schema", "completeness", "smartphone"]

    resolved = resolve_files(files)
    all_errors = []
    files_checked = 0

    for fp in resolved:
        file_errors = []
        suffix = fp.suffix.lower()

        if suffix in (".liquid",) or suffix == "":
            if "liquid" in checks:
                file_errors.extend(check_liquid(fp))
            if "schema" in checks:
                file_errors.extend(check_schema(fp))
            if "smartphone" in checks and platform in ("ecforce", "auto"):
                file_errors.extend(check_smartphone_variant(fp))

        if "completeness" in checks:
            file_errors.extend(check_completeness(fp))

        for e in file_errors:
            e["file"] = str(fp)

        all_errors.extend(file_errors)
        files_checked += 1

    critical = [e for e in all_errors if e["severity"] == "critical"]
    warnings = [e for e in all_errors if e["severity"] == "warning"]

    return {
        "verdict": "FAIL" if critical else "PASS",
        "critical": critical,
        "warnings": warnings,
        "stats": {
            "files_checked": files_checked,
            "critical_count": len(critical),
            "warning_count": len(warnings),
        },
    }


def main():
    if len(sys.argv) > 1:
        data = json.loads(sys.argv[1])
    else:
        data = json.loads(sys.stdin.read())

    action = data.get("action", "review")

    if action == "pre-push":
        result = check_pre_push()
    elif action in ("review", "liquid", "schema"):
        checks = [action] if action != "review" else data.get("checks")
        result = review(
            data.get("files", []),
            data.get("platform", "auto"),
            checks,
        )
    else:
        result = {"verdict": "error", "message": f"Unknown action: {action}"}

    json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
    print()


if __name__ == "__main__":
    main()
