# 02 · Instalación y ejecución

## Lo primero: un clon no compila tal cual

Es el hecho de primer orden de este repositorio y conviene leerlo antes que
nada. `.gitignore` contiene:

```text
/android/
/ios/
/web/
/macos/
```

con el comentario `# Se generan con tool/bootstrap.py`. Las carpetas de
plataforma **no están versionadas**. `flutter run` sobre un clon recién hecho
falla porque no existe ningún proyecto nativo al que apuntar.

El paso obligatorio es:

```bash
python tool/bootstrap.py --platforms android,web
```

Ese script hace tres cosas, en este orden (`tool/bootstrap.py`, función `main`):

1. **Genera** las carpetas ausentes ejecutando `flutter create` en un directorio
   temporal y copiando el resultado (`generate_platforms`);
2. **Parchea** cada plataforma generada (`patch_android`, `patch_ios`,
   `patch_macos`, `patch_web`);
3. **Resuelve** dependencias con `flutter pub get`, salvo que se pase
   `--skip-pub-get`.

## Requisitos

| Requisito | Versión | Cómo se comprueba |
|---|---|---|
| Flutter | **3.44.7** | Fijado en [`../../.fvmrc`](../../.fvmrc) y en la variable `FLUTTER_VERSION` de los dos workflows |
| Dart | `>=3.12.0 <4.0.0` | `environment.sdk` de `pubspec.yaml`; viene con el propio Flutter |
| Python | 3 (la CI usa 3.12) | `actions/setup-python@v7` en `.github/workflows/flutter-ci.yml` |
| `pyyaml` | cualquiera reciente | La CI hace `python3 -m pip install --upgrade pyyaml`; lo importan `tool/validate_structure.py`, `tool/generate_sbom.py` y `tool/bootstrap.py` no |
| JDK y Android SDK | Los que exija la cadena AGP 8.11.1 / Gradle 8.14.3 | Solo para compilar Android |
| Xcode | Solo en macOS | Solo para iOS y macOS |
| Pillow | opcional | Únicamente para **regenerar** los iconos con `tool/generate_launcher_icons.py`. Compilar no lo necesita |

**Comprobado**: `tool/bootstrap.py` no importa `yaml`; los que sí lo hacen son
`tool/validate_structure.py` (línea 11) y `tool/generate_sbom.py` (línea 302).

### Sobre `.fvmrc` y la versión exacta

`.fvmrc` contiene únicamente:

```json
{
  "flutter": "3.44.7"
}
```

El repositorio **no incluye la configuración de FVM más allá de ese archivo**:
no hay `.fvm/`, ni script que lo consuma, ni paso de CI que lo lea —la CI fija la
versión con `subosito/flutter-action@v2` y su propia variable de entorno. En la
práctica `.fvmrc` funciona como declaración de la versión de referencia. Si usas
FVM, `fvm use` la respetará; si no, basta con tener 3.44.7 en el `PATH`.

Una versión distinta de Flutter **no está bloqueada por ningún gate**: nada en
`tool/validate_structure.py` compara la versión instalada con `.fvmrc`.
*Inferencia*: compilar con 3.44.6 o 3.45.x probablemente funcione, pero
`pubspec.lock` fue resuelto con 3.44.7 y las plantillas de `flutter create`
cambian entre versiones menores, así que el resultado de `bootstrap.py` puede
diferir. **Requiere validación.**

## Instalación paso a paso

### 1 · Clonar y resolver dependencias

```bash
git clone https://github.com/vladimiracunadev-create/universal-code-scanner.git
cd universal-code-scanner
flutter pub get
```

`pubspec.lock` **está versionado** (es una aplicación, no un paquete; la política
está en [`../quality/LOCKFILE.md`](../quality/LOCKFILE.md)), así que `pub get`
reproduce exactamente el grafo con el que se validó la versión.

`flutter pub outdated` mostrará ~30 paquetes con versiones más nuevas. **Tres de
ellos no deben subirse**: `share_plus`, `pdfrx` y `excel`. El motivo está en el
propio `.github/dependabot.yml`, que los ignora con la razón escrita al lado.

### 2 · Generar las plataformas

```bash
python tool/bootstrap.py --platforms android,web
```

En Windows existe un envoltorio equivalente:

```powershell
.\tool\bootstrap.ps1 --platforms android,web
```

`tool/bootstrap.ps1` prefiere el lanzador `py -3` y cae a `python` si no existe.
En POSIX, `tool/bootstrap.sh` hace lo mismo con `python3`.

Sin `--platforms`, la lista por defecto depende del sistema operativo
(`default_platforms`): en macOS son `android, ios, web, macos`; en cualquier otro,
`android, web`.

Opciones:

| Opción | Efecto |
|---|---|
| `--platforms a,b,c` | Lista explícita. Valores válidos: `android`, `ios`, `web`, `macos`. Cualquier otro aborta con `Plataformas no válidas` |
| `--force` | Borra y regenera las carpetas aunque ya existan |
| `--skip-pub-get` | Omite el `flutter pub get` final |

**Detalle que sorprende**: si la carpeta ya existe y no se pasa `--force`, el
script **no la regenera pero sí vuelve a parchearla**. Las funciones `patch_*`
se ejecutan siempre que la carpeta exista (`main`, líneas 388-395). Los parches
son idempotentes: `insert_before` comprueba si el contenido ya está presente
antes de insertarlo, y las sustituciones de texto son estables al repetirlas.

### 3 · Verificar

```bash
python tool/validate_structure.py
flutter analyze --fatal-infos
flutter test
```

### 4 · Ejecutar

```bash
flutter run                 # dispositivo o emulador conectado
flutter run -d chrome       # PWA en local, sin --base-href
```

## Qué aplica exactamente `bootstrap.py` a cada plataforma

Esta tabla es el contenido real de las funciones `patch_*`. Es la única
documentación de esos valores: los archivos resultantes no se versionan, así que
**no se pueden leer en el repositorio**.

### Android (`patch_android`)

| Cambio | Valor | Por qué |
|---|---|---|
| `uses-permission` | `android.permission.CAMERA` | Lectura con cámara |
| `uses-permission` | `android.permission.USE_BIOMETRIC` | Bloqueo de la aplicación |
| `uses-feature` | `android.hardware.camera.any` con `required="false"` | Permite instalar en dispositivos sin cámara |
| `android:allowBackup` | `false` | Evita que una llave del Keystore se restaure sin su material criptográfico compatible (`docs/SECURITY.md`) |
| `android:label` | `Universal Code Scanner` | La plantilla genera `universal_code_scanner` |
| `MainActivity` | `FlutterFragmentActivity` en vez de `FlutterActivity` | Requisito de `local_auth` para el diálogo biométrico |
| `minSdk` | `24` | Sustituye `flutter.minSdkVersion` |
| `LaunchTheme` | `Theme.AppCompat.DayNight.NoActionBar` | En `values/` y `values-night/` |
| Android Gradle Plugin | `8.11.1` | Ver el bloque siguiente |
| Kotlin Gradle Plugin | `2.2.20` | Mínimo que Flutter 3.44.7 no marca obsoleto |
| Distribución de Gradle | `8.14.3` | Compatible con AGP 8.11.1 |
| `android.builtInKotlin` | `false` | Coherente con AGP 8 |
| Iconos | Copiados de `assets/launcher/android/` | Heredados, adaptativos y monocromos |

El anclaje de AGP tiene una explicación concreta escrita como comentario en el
propio script (líneas 31-39): la plantilla de Flutter 3.44.7 genera AGP 9, cuyo
valor por defecto es el Kotlin integrado; varios plugins de este conjunto
—`file_picker` entre ellos— **dejan de aplicar el Kotlin Gradle Plugin en cuanto
detectan AGP 9**, dando por hecho que el integrado está activo. Pero la misma
plantilla entrega `android.builtInKotlin=false`, así que nadie compila el Kotlin
de esos plugins y la compilación falla con `cannot find symbol: class
FilePickerPlugin`. Activar el Kotlin integrado rompe el caso contrario. La serie
8 de AGP deja a todos los plugins en la ruta que todos soportan.

### iOS (`patch_ios`)

| Cambio | Valor |
|---|---|
| `platform :ios` del `Podfile` | `15.5` |
| `IPHONEOS_DEPLOYMENT_TARGET` | `15.5` |
| `MinimumOSVersion` de `AppFrameworkInfo.plist` | `15.5` |
| `NSCameraUsageDescription` | «La cámara se utiliza para leer códigos QR y códigos de barras.» |
| `NSPhotoLibraryUsageDescription` | «La galería se utiliza para analizar códigos presentes en imágenes seleccionadas.» |
| `NSFaceIDUsageDescription` | «Face ID protege el acceso a la aplicación cuando el usuario activa el bloqueo.» |
| `Runner.entitlements` | `keychain-access-groups` vacío |
| `CODE_SIGN_ENTITLEMENTS` | Añadido al `project.pbxproj` junto a `CODE_SIGN_STYLE` |

### macOS (`patch_macos`)

Añade `NSCameraUsageDescription` y `NSPhotoLibraryUsageDescription` al
`Info.plist`, y a **ambos** archivos de entitlements
(`DebugProfile.entitlements` y `Release.entitlements`) las tres claves
`com.apple.security.device.camera`,
`com.apple.security.files.user-selected.read-only` y `keychain-access-groups`.

### Web (`patch_web`)

Reescribe `web/manifest.json` con nombre, nombre corto, descripción,
`display: standalone` y los colores `#006B66`; cambia el `<title>` y el
`content` del `index.html`; y copia los iconos y el favicon desde
`assets/launcher/web/`.

## Comandos agrupados

El repositorio ya trae dos guiones que encadenan lo anterior.

### `tool/run_quality_gate.sh` — puerta de calidad

```bash
python3 tool/validate_structure.py
flutter pub get
flutter analyze
flutter test --coverage
python3 tool/generate_sbom.py
python3 tool/generate_license_inventory.py
flutter pub outdated || true
```

Nota: usa `flutter analyze` **sin** `--fatal-infos`, a diferencia de la CI y de
`README.md`. Ver el hallazgo R-06 de
[15-risks-and-technical-debt.md](15-risks-and-technical-debt.md).

### `tool/finalize_stable.sh` — antes de etiquetar

Añade a lo anterior `flutter build apk --debug`, `flutter build web --release`,
`validate_structure.py --require-lock`, `generate_source_manifest.py` y un
`git diff -- pubspec.lock pubspec.yaml` final. Ambos guiones son `bash` y
requieren `flutter` en el `PATH`; **no existe un equivalente PowerShell**.

## Ejecución de las pruebas

```bash
flutter test                  # 57 casos en test/
flutter test --coverage       # además escribe coverage/lcov.info
```

La prueba de integración **no la ejecuta `flutter test`**: vive en
`integration_test/` y necesita un dispositivo.

```bash
flutter test integration_test/app_launch_test.dart -d macos
```

La CI la omite a propósito, con el motivo escrito al final de
`.github/workflows/flutter-ci.yml`: los runners macOS de GitHub no tienen sesión
gráfica interactiva, así que la aplicación arranca sin llegar a establecer la
conexión de depuración.

## Compilaciones

| Objetivo | Comando | Verificado en 1.1.0 |
|---|---|---|
| Web release | `flutter build web --release` | Sí, local y CI |
| APK de depuración | `flutter build apk --debug` | Sí, CI |
| APK por arquitectura | `flutter build apk --release --split-per-abi` | Sí: 32,8 MB arm64-v8a · 26,8 MB armeabi-v7a · 35,3 MB x86_64 |
| APK universal | `flutter build apk --release` | Sí: 88,1 MB |
| iOS sin firma | `flutter build ios --release --no-codesign` | CI, trabajo `apple` |
| macOS | `flutter build macos --release` | CI, trabajo `apple` |
| App Bundle (`.aab`) | `flutter build appbundle` | **No**: fuera del alcance de 1.1.0 |

Los tamaños provienen de `RELEASE_SOURCE.json`, campo
`runtimeValidation.androidReleaseApk`.

## Verificación ejecutada en este análisis

Sobre el commit `c1f9878`, con Flutter 3.44.7 y Dart 3.12.2:

| Comando | Salida real |
|---|---|
| `flutter pub get` | `Got dependencies!` · `30 packages have newer versions incompatible with dependency constraints.` |
| `flutter analyze --fatal-infos` | `No issues found! (ran in 100.8s)` · código de salida `0` |
| `flutter test` | `00:24 +57: All tests passed!` · código de salida `0` |

## Problemas frecuentes al instalar

| Síntoma | Causa | Solución |
|---|---|---|
| `flutter run` no encuentra dispositivo Android ni proyecto | Falta ejecutar `bootstrap.py` | `python tool/bootstrap.py --platforms android,web` |
| `cannot find symbol: class FilePickerPlugin` | Se está usando AGP 9 en vez del 8.11.1 que fija el script | Volver a ejecutar `bootstrap.py`, que reescribe `settings.gradle.kts` |
| `Falta pubspec.lock` al validar | Se ejecutó `validate_structure.py --require-lock` sin haber hecho `pub get` | `flutter pub get` |
| `ModuleNotFoundError: No module named 'yaml'` | Falta `pyyaml` | `python -m pip install --upgrade pyyaml` |
| `Ruta absoluta del entorno encontrada en …` al validar | Un archivo contiene una de las tres rutas de entorno que el validador prohíbe: dos directorios de trabajo de entornos de ejecución remotos y el prefijo del directorio de perfiles de Windows | Quitar la ruta; el validador la considera contaminación del entorno de origen. La lista literal está en la variable `bad` de `check_absolute_paths` |
| `flutter pub outdated` propone subir `share_plus`, `pdfrx` o `excel` | Anclajes deliberados | No subirlos; ver [`../quality/LOCKFILE.md`](../quality/LOCKFILE.md) |

Más casos, ya en ejecución y no en instalación, en
[14-troubleshooting.md](14-troubleshooting.md).

---

Continúa en [03 · Arquitectura](03-architecture.md).
