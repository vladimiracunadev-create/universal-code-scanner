#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
command -v flutter >/dev/null || { echo "Flutter no está disponible en PATH." >&2; exit 1; }
flutter --version
flutter pub get
test -f pubspec.lock
flutter analyze
flutter test
flutter build apk --debug
flutter build web --release
python3 tool/validate_structure.py --require-lock
python3 tool/generate_sbom.py
python3 tool/generate_license_inventory.py
python3 tool/generate_source_manifest.py
git diff -- pubspec.lock pubspec.yaml
echo "Validación estable terminada. Revisa y confirma pubspec.lock antes de etiquetar la versión."
