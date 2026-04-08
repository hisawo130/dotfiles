#!/usr/bin/env python3
"""
nightly-inject-prompt.py
Injects the digest JSON into the nightly-review.md prompt template.
Usage: python3 nightly-inject-prompt.py <digest.json> <prompt.md>
Output: merged prompt to stdout
"""
import sys
from pathlib import Path

digest_path  = Path(sys.argv[1])
template_path = Path(sys.argv[2])

digest   = digest_path.read_text(encoding="utf-8")
template = template_path.read_text(encoding="utf-8")
print(template.replace("__DIGEST__", digest))
