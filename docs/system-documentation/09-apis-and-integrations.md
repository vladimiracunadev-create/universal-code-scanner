# 09 · APIs e integraciones

## No hay red. Y aquí está la demostración

Este repositorio **no define ninguna API HTTP, no consume ninguna, y no abre
ningún socket**. No es una afirmación de intención: es verificable con tres
comandos.

```bash
# 1 · ¿Hay algún cliente de red en el código?
grep -rn "HttpClient\|package:http\|WebSocket\|Socket(\|dart:html\|XMLHttpRequest" lib --include="*.dart"
# → sin resultados
```

```bash
# 2 · ¿Hay algún paquete de red entre las dependencias?
grep -nE "^  (http|dio|grpc|graphql|firebase|supabase|sentry|amplitude|posthog)" pubspec.yaml
# → sin resultados
```

(La búsqueda va anclada al inicio de la línea de dependencia a propósito: un
`grep` suelto de `dio` encuentra `au**dio**players`, que no es un cliente de red
sino el reproductor del tono de lectura.)

```bash
# 3 · ¿Qué es lo único que envía algo fuera de la aplicación?
grep -rn "launchUrl\|SharePlus" lib --include="*.dart"
# → 1 uso de launchUrl, en scan_result_sheet.dart:239
# → 9 usos de SharePlus.instance.share: export_service.dart (4),
#   generator_screen.dart (3) y scan_result_sheet.dart (2)
```

Los tres se ejecutaron sobre el commit `c1f9878` y dieron ese resultado.

Las dos únicas rutas por las que un dato abandona el proceso son delegaciones al
sistema operativo:

| Paquete | Qué hace | Confirmación |
|---|---|---|
| `url_launcher 6.3.2` | Entrega una URI al sistema, que decide qué aplicación la abre | Diálogo obligatorio si `confirmBeforeOpen` o riesgo ≠ `low` |
| `share_plus 12.0.2` | Abre el selector de compartir del sistema con texto o archivos | Diálogo solo si el registro es sensible |

Ninguno de los dos es un cliente de red: no hablan con ningún servidor, hablan
con el sistema operativo.

## Qué se documenta entonces en este capítulo

Como no hay red, lo que sí existe y merece contrato son:

1. **Los contratos de datos JSON** que la aplicación produce y consume.
2. **Las interfaces de plataforma** que usa a través de plugins.
3. **Las fronteras internas** que otro código podría implementar.

---

## 1 · Contratos de datos JSON

Hay cinco formatos JSON con forma estable. Tres son de intercambio con el
usuario, uno es interno persistido y uno es de diagnóstico.

### 1.1 Respaldo de historial · `type: history`

**Produce**: `ExportService.shareHistoryJson`.
**Consume**: `ImportService.parseHistoryBytes`.
**Nombre de archivo**: `historial-escaneos.json`.

```json
{
  "application": "Universal Code Scanner",
  "schemaVersion": 2,
  "exportedAt": "2026-08-27T12:00:00.000Z",
  "type": "history",
  "records": [
    {
      "id": "a1b2c3d4e5f60718293a",
      "rawValue": "https://example.com/producto?id=42",
      "displayValue": "https://example.com/producto?id=42",
      "format": "QR Code",
      "contentType": "Enlace web",
      "scannedAt": "2026-08-27T09:15:32.100",
      "source": "Cámara",
      "riskLevel": "low",
      "riskReasons": [],
      "canOpen": true,
      "parsed": {
        "kind": "url",
        "title": "Enlace web",
        "summary": "example.com",
        "fields": {
          "Dominio": "example.com",
          "Protocolo": "HTTPS",
          "Ruta": "/producto",
          "Consulta": "id=42",
          "Dirección": "https://example.com/producto?id=42"
        },
        "sensitive": false
      },
      "favorite": false,
      "tags": [],
      "notes": ""
    }
  ]
}
```

Reglas de aceptación en la importación:

| Regla | Comprobación | Fallo |
|---|---|---|
| Tamaño | `bytes.length ≤ 25 MB` | `FormatException('El archivo supera el límite de 25 MB.')` |
| Profundidad | `≤ 32` por rama | `FormatException('El archivo contiene una estructura demasiado profunda.')` |
| Nodos | `≤ 100 000` en total | `FormatException('El archivo contiene demasiados elementos.')` |
| Procedencia | `application == 'Universal Code Scanner'` **y** `type == 'history'` | `FormatException('El respaldo no pertenece al historial de Universal Code Scanner.')` |
| Versión | `schemaVersion ≤ 2` | `FormatException('El respaldo fue creado por una versión más reciente.')` |
| Estructura | `records` debe ser una lista | `FormatException('El respaldo no contiene registros.')` |
| Cantidad | `≤ 5000` | `FormatException('El respaldo supera el límite de registros.')` |

**Formato heredado aceptado**: si la raíz es una **lista** en vez de un objeto,
se acepta como `schemaVersion: 1` sin comprobar procedencia. Es la
compatibilidad con la versión que exportaba el array desnudo.

**Tolerancia por registro**: un elemento que no sea un mapa, o que no pueda
reconstruirse como `ScanRecord`, se cuenta en `rejected` y **no aborta la
importación**.

**Compromiso de compatibilidad**: el punto 6 de
[`../quality/COMPATIBILITY_CONTRACT.md`](../quality/COMPATIBILITY_CONTRACT.md)
dice que un respaldo con `schemaVersion: 2` seguirá siendo importable en
versiones futuras.

### 1.2 Respaldo de inventario · `type: inventory`

**Produce**: `ExportService.shareInventoryJson`.
**Consume**: `ImportService.parseInventoryBytes`.
**Nombre de archivo**: `inventario-<id>.json`.

```json
{
  "application": "Universal Code Scanner",
  "schemaVersion": 2,
  "exportedAt": "2026-08-27T12:00:00.000Z",
  "type": "inventory",
  "session": {
    "id": "0f1e2d3c4b5a6978",
    "name": "Bodega central agosto",
    "createdAt": "2026-08-20T08:00:00.000",
    "closedAt": null,
    "items": {
      "7801234567890": {
        "code": "7801234567890",
        "format": "EAN-13",
        "label": "Producto",
        "quantity": 12,
        "firstScannedAt": "2026-08-20T08:05:11.000",
        "lastScannedAt": "2026-08-20T09:41:02.000",
        "notes": "Estante 3"
      }
    }
  }
}
```

Reglas propias: `items.length ≤ 10 000`; se acepta también un objeto **heredado**
sin campo `application` (se toma como `schemaVersion: 1` y se valida como sesión
directamente).

**La importación siempre crea una copia**: `InventoryStore.importSession` genera
un `id` nuevo, añade `(importado)` al nombre y usa `DateTime.now()` como
`createdAt`. Nunca sobrescribe una sesión existente.

### 1.3 Paquete de recuperación

**Produce**: `RecoveryService.exportBundle`.
**Consume**: nadie. **No existe importador.** Es un artefacto de diagnóstico
para entregar a soporte. R-28.

```json
{
  "application": "Universal Code Scanner",
  "type": "recovery",
  "schemaVersion": 1,
  "exportedAt": "2026-08-27T12:00:00.000Z",
  "notice": "Encrypted payloads remain encrypted. No decryption key is included.",
  "issues": [
    {
      "id": "3f9a1c8b2d7e4f60a5b3c1d2",
      "entityType": "history",
      "entityId": "a1b2c3d4e5f60718293a",
      "detectedAt": "2026-08-27T11:58:03.412Z",
      "code": "decrypt_StateError",
      "state": "unresolved",
      "encryptedPayload": "{\"version\":2,\"algorithm\":\"AES-256-GCM\",…}"
    }
  ]
}
```

Los `encryptedPayload` salen **todavía cifrados** y ninguna llave se incluye. Hay
una prueba que lo comprueba cifrando un objeto con un marcador y verificando que
ni ese marcador ni la cadena `ucs_database_key` aparecen en el paquete
(`test/core/recovery_service_test.dart`).

### 1.4 Diagnóstico privado

**Produce**: `AppDiagnostics.exportJson`.
**Consume**: nadie. Es texto para pegar en un reporte.

```json
{
  "application": "Universal Code Scanner",
  "schemaVersion": 1,
  "generatedAt": "2026-08-27T12:00:00.000Z",
  "privacy": "No scan payloads, URLs, passwords, one-time codes, notes or inventory values are included.",
  "entries": [
    {
      "at": "2026-08-27T11:59:12.004Z",
      "area": "bootstrap",
      "errorType": "StateError",
      "stackFingerprint": "1a2b3c4d"
    }
  ]
}
```

Cuatro campos por entrada, y ninguno puede contener datos del usuario por
construcción: `area` está saneada a `[a-zA-Z0-9_.-]` y recortada a 80 caracteres,
`errorType` es el `runtimeType`, y `stackFingerprint` es un hash de 8 dígitos
hexadecimales.

### 1.5 Sobre de cifrado (interno)

Es el formato de la columna `payload` de Sembast. Documentado en
[07-database.md](07-database.md). No sale de la aplicación salvo dentro de un
paquete de recuperación, y ahí sigue cifrado.

### 1.6 Contratos de la herramienta

Tres JSON más, producidos por `tool/` y no por la aplicación:

| Archivo | Lo produce | Lo valida | Contenido |
|---|---|---|---|
| `SOURCE_MANIFEST.json` | `tool/generate_source_manifest.py` | `validate_structure.py::check_json_files` | `{schemaVersion: 1, files: [{path, size, sha256}]}` · 150 archivos |
| `docs/security/sbom-source.cdx.json` | `tool/generate_sbom.py` | `validate_structure.py::check_source_sbom` (exige `bomFormat == 'CycloneDX'`) | CycloneDX 1.5 |
| `test_assets/manifest.json` | A mano | `validate_structure.py::check_test_assets` | `{schemaVersion: 1, items: [{file, expectedPayload, format, scenario}]}` |
| `RELEASE_SOURCE.json` | A mano | `check_json_files` | Qué se validó al publicar |

`build/reports/sbom.cdx.json` y `build/reports/dependency-licenses.json` se
generan en cada ejecución de la CI y **no se versionan**.

---

## 2 · Formatos de salida no JSON

### CSV

| Aspecto | Valor | Motivo |
|---|---|---|
| Codificación | UTF-8 **con BOM** (`EF BB BF`) | Sin el BOM, Excel en Windows abre el archivo en la página de códigos del sistema y rompe los acentos |
| Separador de línea | `\r\n` | Convención de Excel |
| Entrecomillado | **Todas** las celdas, siempre | Evita razonar sobre qué celda lo necesita |
| Escape | `"` se duplica a `""` | RFC 4180 |

Columnas del historial (8): `fecha, tipo, formato, origen, riesgo, favorito,
etiquetas, contenido`. Las etiquetas se unen con `|`.

Columnas del inventario (8): `sesion, codigo, formato, descripcion, cantidad,
primera_lectura, ultima_lectura, notas`.

### XLSX

Generado con `excel 4.0.6` en un isolate aparte. Una sola hoja, con nombre
`Historial` o `Inventario`; la hoja por defecto que crea la librería se elimina
si su nombre difiere. Todas las celdas son `TextCellValue`: **no hay tipos
numéricos ni de fecha**, así que una hoja de cálculo mostrará las cantidades
como texto.

Columnas del historial (9): añade `Notas` respecto al CSV. Columnas del
inventario (8): las mismas que su CSV.

### vCard e iCalendar

`ScanRecordCard._shareRecord` comparte el `rawValue` íntegro como archivo cuando
el tipo es contacto o evento:

| Tipo | Extensión | MIME |
|---|---|---|
| `ContentKind.contact` | `.vcf` | `text/vcard` |
| `ContentKind.event` | `.ics` | `text/calendar` |

No se reformatea nada: se entrega exactamente lo que decía el código.

### PNG y SVG del generador

| Formato | Cómo se produce | Tamaño |
|---|---|---|
| PNG | Captura del `RepaintBoundary` a `pixelRatio: 3` | El del widget × 3 |
| SVG | `Barcode.toSvg(payload, …)` | 900×900 para 2D, 1200×420 para lineales |

Ambos se comparten como `XFile.fromData`: **no se escriben a disco**.

---

## 3 · Interfaces de plataforma

Estas sí son integraciones reales, y son las únicas que existen.

| Interfaz | Plugin | Qué pide | Permiso | Degradación |
|---|---|---|---|---|
| Cámara | `mobile_scanner 7.4.0` | Cuadros de vídeo y detección | `CAMERA` en Android; `NSCameraUsageDescription` en Apple | Fase `unavailable` con motivo y botón de reintento |
| Galería | `image_picker 1.2.3` | Hasta 20 imágenes | Lo gestiona el selector del sistema | Lista vacía → no ocurre nada |
| Archivos | `file_picker 11.0.3` | Un `.json` o un `.pdf` | Selector del sistema | `null` → no ocurre nada |
| Almacén seguro | `flutter_secure_storage 10.3.1` | Guardar y leer llaves AES | Ninguno explícito | `read` devuelve `null` → `StateError('encryption_key_missing:…')` |
| Biometría | `local_auth 3.0.2` | Autenticación local | `USE_BIOMETRIC`; `NSFaceIDUsageDescription` | Ambos métodos capturan y devuelven `false` |
| Audio | `audioplayers 6.8.1` | Reproducir el tono empaquetado | Ninguno | Degrada a `SystemSound.play` y deja de intentarlo |
| Vibración | `flutter/services` (`HapticFeedback`) | Vibración media | Ninguno | `catch` vacío: un dispositivo sin vibrador no rompe la lectura |
| Portapapeles | `flutter/services` (`Clipboard`) | Leer y escribir texto | Ninguno | Ninguna |
| Compartir | `share_plus 12.0.2` | Selector del sistema | Ninguno | Ninguna |
| Abrir URI | `url_launcher 6.3.2` | Delegar al sistema | Ninguno | `opened == false` → mensaje «No existe una aplicación compatible» |
| Rutas | `path_provider 2.1.6` | Directorio de soporte y temporal | Ninguno | Fallo → arranque fallido → inicio seguro |
| PDF | `pdfrx 2.4.5` | Renderizar páginas | Ninguno | No disponible en web (`pdf_page_renderer_stub.dart`) |

`BiometricService` merece mención por lo explícito de su degradación:

```dart
Future<bool> isAvailable() async {
  try { return await _authentication.isDeviceSupported(); } on Object { return false; }
}
Future<bool> authenticate() async {
  try { return await _authentication.authenticate(localizedReason: '…', persistAcrossBackgrounding: true); }
  on Object { return false; }
}
```

Cualquier fallo se convierte en «no autenticado», nunca en «autenticado por
defecto». Es la dirección correcta para un control de seguridad.

`persistAcrossBackgrounding: true` evita que el propio diálogo biométrico
—que pasa la aplicación a inactivo— dispare un nuevo bloqueo en bucle.

---

## 4 · Fronteras internas implementables

Tres interfaces que otro código podría implementar sin tocar el resto.

### `ScannerEngine`

```dart
abstract interface class ScannerEngine {
  MobileScannerController get controller;
  ValueListenable<MobileScannerState> get state;
  Future<void> start();
  Future<void> stop();
  Future<void> dispose();
  Future<void> toggleTorch();
  Future<void> switchCamera();
  Future<void> setZoomScale(double value);
  Future<BarcodeCapture?> analyzeImage(String path);
}
```

**Problema de la abstracción**: dos de sus nueve miembros —`controller` y
`state`— devuelven tipos de `mobile_scanner`. Un motor alternativo tendría que
producir un `MobileScannerController` y un `MobileScannerState`, lo cual la hace
inservible como frontera real. Es una abstracción de conveniencia sobre el
paquete actual, no un puerto independiente del proveedor. R-29.

Y `InventoryScreen` no la usa (R-04).

### `ContentParser` y `ContentParserRegistry`

```dart
abstract interface class ContentParser {
  String get id;
  int get priority;
  bool canParse(String rawValue);
  ParsedContent parse(String rawValue);
}
```

Esta sí es una frontera limpia: no depende de ningún paquete externo. Registrar
un parser propio es una llamada:

```dart
ContentParserRegistry.instance.register(MiParser());
```

Se ordena por prioridad descendente; el integrado tiene `-1000` y **no puede
desregistrarse**. Hay una prueba que registra un parser de prueba, verifica que
gana, lo desregistra y comprueba que el integrado vuelve a atender
(`test/services/content_parser_registry_test.dart`).

**No hay ningún punto de la aplicación desde el que un usuario o una
configuración registre un parser.** La extensibilidad es en tiempo de
compilación, para quien bifurque el repositorio.

### `EncryptionKeyProvider`

```dart
abstract interface class EncryptionKeyProvider {
  Future<SecretKey?> read(String keyId);
  Future<SecretKey> readOrCreate(String keyId, AesGcm algorithm);
  Future<void> forget(String keyId);
}
```

Dos implementaciones reales (`SecureStorageKeyProvider`,
`MemoryEncryptionKeyProvider`) y una tercera en las pruebas
(`_TrackingKeyProvider`, que envuelve la de memoria para observar creaciones y
olvidos). Es la frontera mejor diseñada del repositorio: no filtra ningún tipo
de plataforma.

### `ScanTonePlayer`

```dart
abstract interface class ScanTonePlayer {
  Future<void> play();
  Future<void> dispose();
}
```

Dos miembros, cero acoplamiento. Existe para poder probar `ScanFeedback` sin un
motor de audio, y las cuatro pruebas de `scan_feedback_test.dart` lo usan.

---

## 5 · Integraciones de infraestructura

No son de la aplicación, sino del repositorio.

| Servicio | Para qué | Dónde se configura |
|---|---|---|
| GitHub Actions | Analizar, probar y compilar en cada `push` y PR | `.github/workflows/flutter-ci.yml` |
| GitHub Pages | Publicar la landing y la PWA | `.github/workflows/deploy-landing.yml` |
| GitHub Releases | Distribuir los APK con sus SHA-256 | Manual, `gh release create` |
| Dependabot | Actualizaciones semanales de pub y mensuales de acciones | `.github/dependabot.yml` |
| `pub.dev` | Resolución de dependencias | `pubspec.yaml` / `pubspec.lock` |

`deploy-landing.yml` publica en `https://vladimiracunadev-create.github.io/universal-code-scanner/`
con la PWA en `/app/` y `APP_BASE_HREF = /universal-code-scanner/app/`. Detalle
en [13-deployment-and-operations.md](13-deployment-and-operations.md).

---

Continúa en [10 · Configuración](10-configuration.md).
