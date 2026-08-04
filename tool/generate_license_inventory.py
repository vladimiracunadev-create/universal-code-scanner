#!/usr/bin/env python3
"""Create an inventory of package license files after `flutter pub get`."""
from __future__ import annotations

import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", default="build/reports/dependency-licenses.json")
    args = parser.parse_args()
    config_path = ROOT / ".dart_tool" / "package_config.json"
    if not config_path.exists():
        raise SystemExit("Falta .dart_tool/package_config.json. Ejecuta flutter pub get.")
    config = json.loads(config_path.read_text(encoding="utf-8"))
    rows: list[dict[str, object]] = []
    for package in config.get("packages", []):
        root_uri = package.get("rootUri", "")
        package_root = (config_path.parent / root_uri).resolve()
        license_files = sorted(
            str(path.relative_to(package_root))
            for pattern in ("LICENSE*", "COPYING*", "NOTICE*")
            for path in package_root.glob(pattern)
            if path.is_file()
        )
        rows.append(
            {
                "name": package.get("name"),
                "rootUri": root_uri,
                "licenseFiles": license_files,
                "reviewStatus": "found" if license_files else "manual-review-required",
            }
        )
    output = ROOT / args.output
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(
        json.dumps({"schemaVersion": 1, "packages": rows}, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    print(output)


if __name__ == "__main__":
    main()
