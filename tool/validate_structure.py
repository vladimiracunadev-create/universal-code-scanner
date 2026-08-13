#!/usr/bin/env python3
"""Fast offline checks. It does not replace flutter analyze or flutter test."""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
import yaml

ROOT = Path(__file__).resolve().parents[1]

# Directories that hold generated or downloaded content. They are never part of
# the distributable source, so no check may read them.
EXCLUDED_DIRS = {
    ".git",
    ".dart_tool",
    "build",
    "coverage",
    "android",
    "ios",
    "web",
    "macos",
    "windows",
    "linux",
}


def is_excluded(path: Path) -> bool:
    return any(part in EXCLUDED_DIRS for part in path.relative_to(ROOT).parts)


def source_files(pattern: str = "*"):
    for path in ROOT.rglob(pattern):
        if path.is_file() and not is_excluded(path):
            yield path


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def check_yaml() -> None:
    for relative in ("pubspec.yaml", "analysis_options.yaml", ".github/workflows/flutter-ci.yml"):
        path = ROOT / relative
        try:
            yaml.safe_load(path.read_text(encoding="utf-8"))
        except Exception as exc:
            fail(f"YAML inválido en {relative}: {exc}")


def check_imports() -> None:
    pattern = re.compile(r"import 'package:universal_code_scanner/([^']+)';|export 'package:universal_code_scanner/([^']+)';")
    for path in (ROOT / "lib").rglob("*.dart"):
        text = path.read_text(encoding="utf-8")
        for match in pattern.finditer(text):
            relative = match.group(1) or match.group(2)
            if not (ROOT / "lib" / relative).exists():
                fail(f"Import local inexistente en {path.relative_to(ROOT)}: {relative}")


def check_absolute_paths() -> None:
    bad = ("/mnt/data/", "/home/oai/", "C:\\Users\\")
    for path in source_files():
        if path == Path(__file__).resolve() or path.suffix in {".png", ".jpg", ".zip"}:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        if any(value in text for value in bad):
            fail(f"Ruta absoluta del entorno encontrada en {path.relative_to(ROOT)}")


def check_version() -> None:
    pubspec = yaml.safe_load((ROOT / "pubspec.yaml").read_text(encoding="utf-8"))
    version = str(pubspec.get("version", ""))
    if not re.fullmatch(r"\d+\.\d+\.\d+\+\d+", version):
        fail(f"Versión inválida: {version}")


def check_interface_version() -> None:
    """The version shown in the interface must match the one that is built.

    The «Acerca de» tile carried the number as a literal and stayed at 1.0.0
    after the release was raised, so the application told the user a version it
    was not. `lib/core/app_info.dart` is now the only place that writes it, and
    this check keeps it tied to `pubspec.yaml`.
    """
    pubspec = yaml.safe_load((ROOT / "pubspec.yaml").read_text(encoding="utf-8"))
    expected = str(pubspec.get("version", "")).split("+", 1)[0]
    path = ROOT / "lib" / "core" / "app_info.dart"
    if not path.exists():
        fail("Falta lib/core/app_info.dart con la versión de la interfaz")
    match = re.search(r"const String appVersion = '([^']+)';", path.read_text(encoding="utf-8"))
    if match is None:
        fail("No se encontró appVersion en lib/core/app_info.dart")
    if match.group(1) != expected:
        fail(
            "La versión mostrada en la interfaz "
            f"({match.group(1)}) no coincide con pubspec.yaml ({expected})"
        )


def check_sensitive_logging() -> None:
    suspicious = re.compile(r"(?:print|debugPrint|log)\s*\([^\n]*(?:rawValue|password|secret|otp|payload)", re.IGNORECASE)
    for path in (ROOT / "lib").rglob("*.dart"):
        if suspicious.search(path.read_text(encoding="utf-8")):
            fail(f"Posible registro de contenido sensible: {path.relative_to(ROOT)}")



def check_test_assets() -> None:
    manifest_path = ROOT / 'test_assets' / 'manifest.json'
    if not manifest_path.exists():
        fail('Falta test_assets/manifest.json')
    try:
        manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    except Exception as exc:
        fail(f'Manifiesto de pruebas inválido: {exc}')
    if manifest.get('schemaVersion') != 1 or not isinstance(manifest.get('items'), list):
        fail('Estructura inválida en test_assets/manifest.json')
    for item in manifest['items']:
        relative = item.get('file') if isinstance(item, dict) else None
        if not isinstance(relative, str) or not (ROOT / 'test_assets' / relative).is_file():
            fail(f'Recurso de regresión inexistente: {relative}')



def check_json_files() -> None:
    for path in source_files('*.json'):
        try:
            json.loads(path.read_text(encoding='utf-8'))
        except Exception as exc:
            fail(f'JSON inválido en {path.relative_to(ROOT)}: {exc}')


def check_markdown_links() -> None:
    pattern = re.compile(r'\[[^\]]*\]\(([^)]+)\)')
    for path in source_files('*.md'):
        text = path.read_text(encoding='utf-8')
        for target in pattern.findall(text):
            target = target.strip().split(' ', 1)[0].strip('<>')
            if not target or target.startswith(('#', 'http://', 'https://', 'mailto:', 'sandbox:')):
                continue
            clean = target.split('#', 1)[0]
            if clean and not (path.parent / clean).resolve().exists():
                fail(f'Enlace Markdown local inexistente en {path.relative_to(ROOT)}: {target}')


def check_source_sbom() -> None:
    path = ROOT / 'docs' / 'security' / 'sbom-source.cdx.json'
    if not path.exists():
        fail('Falta el SBOM de fuente')
    try:
        value = json.loads(path.read_text(encoding='utf-8'))
    except Exception as exc:
        fail(f'SBOM de fuente inválido: {exc}')
    if value.get('bomFormat') != 'CycloneDX':
        fail('El SBOM de fuente no declara CycloneDX')


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--require-lock", action="store_true")
    args = parser.parse_args()
    check_yaml()
    check_imports()
    check_absolute_paths()
    check_version()
    check_interface_version()
    check_sensitive_logging()
    check_test_assets()
    check_json_files()
    check_markdown_links()
    check_source_sbom()
    if args.require_lock and not (ROOT / "pubspec.lock").exists():
        fail("Falta pubspec.lock. Ejecuta flutter pub get en la versión fijada de Flutter y confirma el archivo.")
    print("Validación estructural completada.")


if __name__ == "__main__":
    main()
