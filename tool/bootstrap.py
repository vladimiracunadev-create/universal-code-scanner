#!/usr/bin/env python3
"""Genera los proyectos nativos de Flutter y aplica la configuración requerida."""

from __future__ import annotations

import argparse
import json
import re
import shutil
import platform
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SUPPORTED_PLATFORMS = ("android", "ios", "web", "macos")


def run(command: list[str], cwd: Path | None = None) -> None:
    subprocess.run(command, cwd=cwd or ROOT, check=True)


def insert_before(text: str, marker: str, content: str) -> str:
    if content.strip() in text:
        return text
    if marker not in text:
        raise RuntimeError(f"No se encontró el marcador esperado: {marker}")
    return text.replace(marker, f"{content}\n{marker}", 1)


def patch_android() -> None:
    manifest = ROOT / "android/app/src/main/AndroidManifest.xml"
    text = manifest.read_text(encoding="utf-8")
    missing = []
    if "android.permission.CAMERA" not in text:
        missing.append('    <uses-permission android:name="android.permission.CAMERA" />')
    if "android.permission.USE_BIOMETRIC" not in text:
        missing.append('    <uses-permission android:name="android.permission.USE_BIOMETRIC" />')
    if "android.hardware.camera.any" not in text:
        missing.append('    <uses-feature android:name="android.hardware.camera.any" android:required="false" />')
    if missing:
        close = text.find(">") + 1
        text = text[:close] + "\n" + "\n".join(missing) + text[close:]
    if "android:allowBackup=" not in text:
        text = text.replace("<application", '<application android:allowBackup="false"', 1)
    text = text.replace(
        'android:label="universal_code_scanner"',
        'android:label="Universal Code Scanner"',
    )
    manifest.write_text(text, encoding="utf-8")

    for activity in list((ROOT / "android/app/src/main").rglob("MainActivity.kt")):
        activity_text = activity.read_text(encoding="utf-8")
        activity_text = activity_text.replace(
            "import io.flutter.embedding.android.FlutterActivity",
            "import io.flutter.embedding.android.FlutterFragmentActivity",
        )
        activity_text = activity_text.replace("FlutterActivity()", "FlutterFragmentActivity()")
        activity.write_text(activity_text, encoding="utf-8")
    for activity in list((ROOT / "android/app/src/main").rglob("MainActivity.java")):
        activity_text = activity.read_text(encoding="utf-8")
        activity_text = activity_text.replace(
            "import io.flutter.embedding.android.FlutterActivity;",
            "import io.flutter.embedding.android.FlutterFragmentActivity;",
        )
        activity_text = activity_text.replace("extends FlutterActivity", "extends FlutterFragmentActivity")
        activity.write_text(activity_text, encoding="utf-8")

    gradle_kts = ROOT / "android/app/build.gradle.kts"
    gradle_groovy = ROOT / "android/app/build.gradle"
    if gradle_kts.exists():
        text = gradle_kts.read_text(encoding="utf-8")
        text = text.replace("minSdk = flutter.minSdkVersion", "minSdk = 24")
        gradle_kts.write_text(text, encoding="utf-8")
    elif gradle_groovy.exists():
        text = gradle_groovy.read_text(encoding="utf-8")
        text = text.replace("minSdkVersion flutter.minSdkVersion", "minSdkVersion 24")
        text = text.replace("minSdk = flutter.minSdkVersion", "minSdk = 24")
        gradle_groovy.write_text(text, encoding="utf-8")

    for styles in (
        ROOT / "android/app/src/main/res/values/styles.xml",
        ROOT / "android/app/src/main/res/values-night/styles.xml",
    ):
        if not styles.exists():
            continue
        styles_text = styles.read_text(encoding="utf-8")
        styles_text = re.sub(
            r'(<style name="LaunchTheme" parent=")[^"]+("[^>]*>)',
            r'\g<1>Theme.AppCompat.DayNight.NoActionBar\g<2>',
            styles_text,
        )
        styles.write_text(styles_text, encoding="utf-8")


def patch_ios() -> None:
    podfile = ROOT / "ios/Podfile"
    if podfile.exists():
        pod_text = podfile.read_text(encoding="utf-8")
        pod_text = re.sub(
            r"^#?\s*platform :ios, '[^']+'",
            "platform :ios, '15.5'",
            pod_text,
            flags=re.MULTILINE,
        )
        podfile.write_text(pod_text, encoding="utf-8")

    project = ROOT / "ios/Runner.xcodeproj/project.pbxproj"
    project_text = project.read_text(encoding="utf-8")
    project_text = re.sub(
        r"IPHONEOS_DEPLOYMENT_TARGET = [^;]+;",
        "IPHONEOS_DEPLOYMENT_TARGET = 15.5;",
        project_text,
    )
    project.write_text(project_text, encoding="utf-8")

    framework_info = ROOT / "ios/Flutter/AppFrameworkInfo.plist"
    framework_text = framework_info.read_text(encoding="utf-8")
    framework_text = re.sub(
        r"(<key>MinimumOSVersion</key>\s*<string>)[^<]+(</string>)",
        r"\g<1>15.5\g<2>",
        framework_text,
    )
    framework_info.write_text(framework_text, encoding="utf-8")

    info = ROOT / "ios/Runner/Info.plist"
    text = info.read_text(encoding="utf-8")
    additions = """
	<key>NSCameraUsageDescription</key>
	<string>La cámara se utiliza para leer códigos QR y códigos de barras.</string>
	<key>NSPhotoLibraryUsageDescription</key>
	<string>La galería se utiliza para analizar códigos presentes en imágenes seleccionadas.</string>
	<key>NSFaceIDUsageDescription</key>
	<string>Face ID protege el acceso a la aplicación cuando el usuario activa el bloqueo.</string>""".strip()
    text = insert_before(text, "</dict>", additions)
    info.write_text(text, encoding="utf-8")

    entitlement = ROOT / "ios/Runner/Runner.entitlements"
    entitlement.write_text(
        """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>keychain-access-groups</key>
    <array/>
</dict>
</plist>
""",
        encoding="utf-8",
    )
    project_text = project.read_text(encoding="utf-8")
    if "CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;" not in project_text:
        project_text = project_text.replace(
            "CODE_SIGN_STYLE = Automatic;",
            "CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;\n\t\t\t\tCODE_SIGN_STYLE = Automatic;",
        )
        project.write_text(project_text, encoding="utf-8")


def patch_macos() -> None:
    info = ROOT / "macos/Runner/Info.plist"
    text = info.read_text(encoding="utf-8")
    additions = """
	<key>NSCameraUsageDescription</key>
	<string>La cámara se utiliza para leer códigos QR y códigos de barras.</string>
	<key>NSPhotoLibraryUsageDescription</key>
	<string>La galería se utiliza para analizar códigos presentes en imágenes seleccionadas.</string>""".strip()
    text = insert_before(text, "</dict>", additions)
    info.write_text(text, encoding="utf-8")

    for filename in ("DebugProfile.entitlements", "Release.entitlements"):
        entitlement = ROOT / "macos/Runner" / filename
        text = entitlement.read_text(encoding="utf-8")
        camera = """
	<key>com.apple.security.device.camera</key>
	<true/>""".strip()
        file_access = """
	<key>com.apple.security.files.user-selected.read-only</key>
	<true/>""".strip()
        keychain = """
	<key>keychain-access-groups</key>
	<array/>""".strip()
        text = insert_before(text, "</dict>", camera)
        text = insert_before(text, "</dict>", file_access)
        text = insert_before(text, "</dict>", keychain)
        entitlement.write_text(text, encoding="utf-8")


def patch_web() -> None:
    manifest_path = ROOT / "web/manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    manifest.update(
        {
            "name": "Universal Code Scanner",
            "short_name": "Code Scanner",
            "description": "Lector universal y seguro de códigos QR y códigos de barras.",
            "display": "standalone",
            "background_color": "#006B66",
            "theme_color": "#006B66",
        }
    )
    manifest_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    index = ROOT / "web/index.html"
    text = index.read_text(encoding="utf-8")
    text = text.replace("<title>universal_code_scanner</title>", "<title>Universal Code Scanner</title>")
    text = text.replace(
        'content="universal_code_scanner"',
        'content="Universal Code Scanner"',
    )
    index.write_text(text, encoding="utf-8")


def default_platforms() -> tuple[str, ...]:
    return (
        ("android", "ios", "web", "macos")
        if platform.system() == "Darwin"
        else ("android", "web")
    )


def generate_platforms(force: bool, platforms: tuple[str, ...]) -> None:
    missing = [name for name in platforms if not (ROOT / name).exists()]
    if not missing and not force:
        return

    flutter = shutil.which("flutter")
    if flutter is None:
        raise SystemExit(
            "Flutter no está instalado o no está disponible en PATH. "
            "Instálalo desde https://docs.flutter.dev/get-started/install"
        )

    with tempfile.TemporaryDirectory(prefix="universal-code-scanner-") as tmp:
        target = Path(tmp) / "universal_code_scanner"
        run(
            [
                flutter,
                "create",
                "--no-pub",
                "--org",
                "dev.vladimiracuna",
                "--project-name",
                "universal_code_scanner",
                "--platforms",
                ",".join(platforms),
                str(target),
            ]
        )
        for name in platforms:
            destination = ROOT / name
            if destination.exists():
                if not force:
                    continue
                shutil.rmtree(destination)
            shutil.copytree(target / name, destination)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--force", action="store_true", help="Regenera las carpetas nativas")
    parser.add_argument("--skip-pub-get", action="store_true")
    parser.add_argument(
        "--platforms",
        help="Lista separada por comas: android,ios,web,macos",
    )
    args = parser.parse_args()

    selected = tuple(
        item.strip()
        for item in (args.platforms or ",".join(default_platforms())).split(",")
        if item.strip()
    )
    invalid = sorted(set(selected) - set(SUPPORTED_PLATFORMS))
    if invalid:
        raise SystemExit(f"Plataformas no válidas: {', '.join(invalid)}")
    if not selected:
        raise SystemExit("Debes indicar al menos una plataforma.")

    generate_platforms(args.force, selected)
    if (ROOT / "android").exists():
        patch_android()
    if (ROOT / "ios").exists():
        patch_ios()
    if (ROOT / "macos").exists():
        patch_macos()
    if (ROOT / "web").exists():
        patch_web()

    if not args.skip_pub_get:
        flutter = shutil.which("flutter")
        if flutter is None:
            raise SystemExit("Flutter no está disponible en PATH.")
        run([flutter, "pub", "get"])

    print("Proyecto preparado correctamente.")


if __name__ == "__main__":
    main()
