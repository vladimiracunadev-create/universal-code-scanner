#!/usr/bin/env python3
"""Generate a CycloneDX SBOM.

Uses the resolved Flutter dependency graph when available. Without Flutter, it
creates a clearly marked source SBOM containing only direct declared packages.
"""
from __future__ import annotations

import argparse
import json
import shutil
import subprocess
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]


def resolved_components(flutter: str) -> tuple[list[dict[str, object]], str]:
    # The executable is passed already resolved: on Windows the entry point is
    # `flutter.bat`, and CreateProcess does not apply PATHEXT to a bare name.
    raw = subprocess.check_output([flutter, "pub", "deps", "--json"], cwd=ROOT, text=True)
    data = json.loads(raw)
    components: list[dict[str, object]] = []
    for package in data.get("packages", []):
        components.append(
            {
                "type": "library",
                "name": package.get("name"),
                "version": package.get("version"),
                "properties": [{"name": "dart:source", "value": str(package.get("source"))}],
            }
        )
    return components, "resolved-transitive"


def declared_components() -> tuple[list[dict[str, object]], str]:
    pubspec = yaml.safe_load((ROOT / "pubspec.yaml").read_text(encoding="utf-8"))
    components: list[dict[str, object]] = []
    for section, scope in (("dependencies", "required"), ("dev_dependencies", "optional")):
        for name, value in (pubspec.get(section) or {}).items():
            if isinstance(value, dict) and "sdk" in value:
                continue
            components.append(
                {
                    "type": "library",
                    "name": name,
                    "version": str(value),
                    "scope": scope,
                    "properties": [{"name": "ucs:resolution", "value": "declared-only"}],
                }
            )
    return components, "declared-direct-only"


def application_version() -> str:
    pubspec = yaml.safe_load((ROOT / "pubspec.yaml").read_text(encoding="utf-8"))
    return str(pubspec.get("version", "0.0.0"))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", default="build/reports/sbom.cdx.json")
    args = parser.parse_args()
    flutter = shutil.which("flutter")
    if flutter:
        components, completeness = resolved_components(flutter)
    else:
        components, completeness = declared_components()
    output = {
        "bomFormat": "CycloneDX",
        "specVersion": "1.5",
        "version": 1,
        "metadata": {
            "component": {"type": "application", "name": "universal_code_scanner", "version": application_version()},
            "properties": [{"name": "ucs:completeness", "value": completeness}],
        },
        "components": components,
    }
    path = ROOT / args.output
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(output, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    print(path)


if __name__ == "__main__":
    main()
