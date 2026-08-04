#!/usr/bin/env python3
"""Hash every distributable source file for reproducible handoff verification."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
# Generated or downloaded content is never part of the distributable source.
EXCLUDED = {
    ".git",
    ".dart_tool",
    "build",
    "coverage",
    "__pycache__",
    "android",
    "ios",
    "web",
    "macos",
    "windows",
    "linux",
}
EXCLUDED_FILES = {".flutter-plugins", ".flutter-plugins-dependencies", ".packages"}
OUTPUT = ROOT / "SOURCE_MANIFEST.json"

rows = []
for path in sorted(ROOT.rglob("*")):
    if not path.is_file() or any(part in EXCLUDED for part in path.parts) or path == OUTPUT:
        continue
    if path.name in EXCLUDED_FILES:
        continue
    rows.append(
        {
            "path": path.relative_to(ROOT).as_posix(),
            "size": path.stat().st_size,
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        }
    )
OUTPUT.write_text(
    json.dumps({"schemaVersion": 1, "files": rows}, indent=2) + "\n",
    encoding="utf-8",
    newline="\n",
)
print(OUTPUT)
