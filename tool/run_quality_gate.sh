#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 tool/validate_structure.py
flutter pub get
flutter analyze
flutter test --coverage
python3 tool/generate_sbom.py
python3 tool/generate_license_inventory.py
flutter pub outdated || true
