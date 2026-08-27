# 04 · Mapa completo del código

Inventario jerárquico de todo el código fuente versionado. Cada elemento lleva
ubicación, responsabilidad, dependencias, quién lo usa y **estado aparente**:

| Estado | Significado |
|---|---|
| **Activo** | Participa en el flujo de ejecución de 1.1.0 |
| **Reservado** | Existe y funciona, pero ningún camino de ejecución lo alcanza en 1.1.0 |
| **Sin uso** | Declarado y nunca invocado |
| **Plataforma** | Se compila condicionalmente según la plataforma destino |

## Vista general del repositorio

| Directorio | Archivos versionados | Contenido |
|---|---|---|
| `lib/` | 59 `.dart` · 6 821 líneas | Todo el código de la aplicación |
| `test/` | 19 `.dart` · 57 casos | Pruebas unitarias y de widget |
| `integration_test/` | 1 `.dart` · 1 caso | Prueba de arranque, no la ejecuta `flutter test` |
| `tool/` | 12 guiones (8 Python, 3 Bash, 1 PowerShell) | Generación, validación y empaquetado |
| `docs/` | 18 `.md` previos + 2 SVG + 5 capturas + SBOM | Documentación anterior a este directorio |
| `landing/` | `index.html`, `style.css`, `favicon.svg`, `README.md` | Sitio publicado en GitHub Pages |
| `assets/` | `sounds/scan_success.wav` + iconos PNG | Recursos empaquetados y fuente de iconos |
| `test_assets/` | 8 PNG + `manifest.json` + 7 `README.md` | Catálogo de regresión visual |
| `.github/` | 2 workflows + `dependabot.yml` | Automatización |
| `android/`, `web/` | **No versionados** | Generados por `tool/bootstrap.py` |

## `lib/` — punto de entrada

### `lib/main.dart` · 14 líneas · **Activo**

| Aspecto | Detalle |
|---|---|
| Responsabilidad | Inicializar el binding, instalar los manejadores globales de error y lanzar `BootstrapHost` dentro de `runZonedGuarded` |
| Depende de | `bootstrap_host.dart`, `core/diagnostics/app_diagnostics.dart` |
| Lo usa | El sistema operativo |
| Nota | Los errores que escapan de la zona se registran con área `root_zone` |

### `lib/bootstrap.dart` · 77 líneas · **Activo**

| Aspecto | Detalle |
|---|---|
| Clases | `AppServices` (contenedor inmutable de siete servicios), `AppBootstrapper` (`abstract final class` con un único método estático) |
| Responsabilidad | Construir el grafo completo de servicios en el orden correcto |
| Depende de | `core/database`, `core/recovery`, `core/security`, `services/*_repository`, `state/*` |
| Lo usa | `bootstrap_host.dart` |
| Riesgo al modificar | **Alto.** El orden importa: la llave activa debe leerse antes de construir `PayloadCipher`, y los stores antes de podar el historial |

### `lib/bootstrap_host.dart` · 133 líneas · **Activo**

| Aspecto | Detalle |
|---|---|
| Widgets | `BootstrapHost` (`StatefulWidget`), `_StartupRecovery` (pantalla de inicio seguro) |
| Responsabilidad | Ejecutar el arranque, mostrar el indicador de progreso y, si falla, la pantalla de recuperación con cuatro salidas |
| Lo usa | `main.dart` |
| Nota | `_retry` guarda el fallo en `_failure` **y vuelve a lanzar**, de modo que el `FutureBuilder` también entra en estado de error |

### `lib/app.dart` · 277 líneas · **Activo**

| Elemento | Tipo | Responsabilidad |
|---|---|---|
| `UniversalCodeScannerApp` | `StatelessWidget` | `MaterialApp` reconstruido por `AnimatedBuilder` sobre `SettingsStore`: tema, idioma y delegados |
| `HandheldFrame` | `StatelessWidget` | Limita la interfaz a `maxWidth = 560` en pantallas anchas. **Por debajo del umbral no envuelve nada**: el árbol en un móvil es idéntico al que habría sin esta capa |
| `BiometricLockGate` | `StatefulWidget` + `WidgetsBindingObserver` | Bloquea la aplicación al pasar a `inactive`, `paused`, `hidden` o `detached` si `biometricLock` está activo |
| `HomeShell` | `StatefulWidget` | Las cinco pestañas y el banner de modo temporal |

`HandheldFrame` tiene tres pruebas de widget dedicadas
(`test/core/handheld_frame_test.dart`), incluida la del caso exacto del umbral.

## `lib/core/` — infraestructura transversal

### `core/app_info.dart` · 18 líneas · **Activo**

Dos constantes: `appVersion = '1.1.0'` y `appName = 'Universal Code Scanner'`.

Este archivo existe por un defecto real: el número de versión estaba escrito
como literal en `settings_screen.dart` y se quedó en `1.0.0` al publicar 1.1.0.
`tool/validate_structure.py::check_interface_version` compara ahora esta
constante con `pubspec.yaml` y **falla la validación si divergen**. La
documentación del propio archivo explica también por qué es una constante y no
una consulta en tiempo de ejecución: leer los metadatos reales del paquete
añadiría una dependencia de plugin para mostrar una cadena ya conocida al
compilar.

### `core/database/` · 5 archivos · **Activo** y **Plataforma**

| Archivo | Líneas | Estado | Responsabilidad |
|---|---|---|---|
| `app_database.dart` | 25 | Activo | Abre la base persistente o una en memoria; ejecuta `SchemaMigrator` |
| `database_opener.dart` | 3 | Plataforma | `export` condicional por `dart.library.io` / `dart.library.js_interop` |
| `database_opener_io.dart` | 11 | Plataforma | `getApplicationSupportDirectory()` + `universal_code_scanner_v2.db`, versión 2 |
| `database_opener_web.dart` | 5 | Plataforma | `databaseFactoryWeb` con el mismo nombre lógico, versión 2 |
| `database_opener_stub.dart` | 5 | Plataforma | Lanza `UnsupportedError` con mensaje en español |
| `schema_migrator.dart` | 42 | Activo | `currentVersion = 4`; migraciones idempotentes en una transacción |

**Detalle no obvio**: hay **dos números de versión distintos**. Sembast recibe
`version: 2` al abrir el archivo; `SchemaMigrator` mantiene su propio contador en
el almacén `_schema_meta`, actualmente en `4`. No están relacionados. Ver
[07-database.md](07-database.md).

### `core/diagnostics/` · 2 archivos · **Activo**

| Archivo | Líneas | Contenido |
|---|---|---|
| `app_diagnostics.dart` | 71 | `DiagnosticEntry`, `AppDiagnostics` (singleton, `maxEntries = 100`), `installGlobalErrorHandlers()` |
| `startup_failure.dart` | 16 | `StartupFailure` con tipo, mensaje fijo en español y huella de pila |

### `core/feature_flags/feature_flags.dart` · 70 líneas · **Reservado**

Nueve banderas booleanas, todas `false` por defecto, con `copyWith`, `toJson` y
`fromJson`. Se persisten en la preferencia `feature_flags`.

**Ningún código de `lib/` las consulta.** Comprobado con `grep` sobre los nueve
nombres: cero apariciones fuera de este archivo. Tampoco hay control en Ajustes
que permita cambiarlas. R-02.

### `core/localization/app_localizations.dart` · 47 líneas · **Activo**

Doce cadenas con doble forma español/inglés, un `LocalizationsDelegate` que
**rechaza `en`** y la extensión `AppStringsContext` que expone `context.strings`.

`supportedLocales` es `[Locale('es','CL'), Locale('es')]`. Cuatro pruebas
protegen esta decisión (`test/core/localization_test.dart`), incluida una que
verifica que las claves en inglés siguen existiendo para la traducción pendiente.

Consumidores reales de `context.strings`: `app.dart` (cinco etiquetas de
navegación), `scanner_screen.dart` (título y subtítulo) y `settings_screen.dart`
(el título «Ajustes»). El resto de las pantallas usa literales en español.

### `core/performance/` · 2 archivos · **Activo**

| Archivo | Líneas | Contenido | Lo usa |
|---|---|---|---|
| `async_write_queue.dart` | 19 | `AsyncWriteQueue`: cola serial que no se envenena ante un fallo | Solo `InventoryStore` |
| `cancellation_token.dart` | 39 | `OperationCancelledException`, `CancellationToken`, `BatchProgress` | `ScannerScreen`, `PdfPageRenderer` |

### `core/recovery/` · 3 archivos · **Activo**

| Archivo | Líneas | Contenido |
|---|---|---|
| `recovery_issue.dart` | 53 | `RecoveryEntityType` (5 valores), `RecoveryIssueState` (3 valores), `RecoveryIssue` |
| `recovery_repository.dart` | 60 | Almacén `recovery_issues`; el `id` es un SHA-256 truncado a 24 caracteres de `tipo|entidad|código` |
| `recovery_service.dart` | 84 | `retry`, `discard`, `exportBundle` |

**Detalle no obvio**: como el `id` se deriva del contenido, **una misma
incidencia detectada dos veces no crea dos registros**: la segunda sobrescribe a
la primera y reinicia su estado a `unresolved`. Es intencional para no llenar la
lista, pero significa que marcar «revisado» un problema que vuelve a ocurrir lo
devuelve a la lista.

De los cinco valores de `RecoveryEntityType`, solo `history`, `inventory` y
`migration` llegan a crearse: los repositorios registran los dos primeros y
`HistoryRepository._migrateLegacyHistory` el tercero. `database` y `startup`
están declarados y **nunca se emiten** (comprobado: no aparecen en ninguna
llamada a `record`). Su `switch` en `retry` y `discard` devuelve `false` o no
hace nada. R-09.

### `core/security/` · 4 archivos · **Activo**

| Archivo | Líneas | Contenido | Riesgo al modificar |
|---|---|---|---|
| `payload_cipher.dart` | 168 | `EncryptionKeyProvider`, `SecureStorageKeyProvider`, `MemoryEncryptionKeyProvider`, `CipherEnvelopeInfo`, `PayloadCipher` | **Crítico**: un cambio incompatible deja ilegibles los datos existentes |
| `encryption_metadata_repository.dart` | 30 | Lee y escribe `encryption_active_key_id` en `_security_meta`, con migración desde preferencias | Alto |
| `data_maintenance_service.dart` | 72 | `EncryptionRotationResult`, `DataMaintenanceService.rotateEncryptionKey()` | **Crítico** |
| `scan_security_analyzer.dart` | 165 | `RiskLevel`, `SecurityAssessment`, `ScanSecurityAnalyzer` con 16 señales | Alto: es la única defensa antes de una acción externa |

### `core/theme/app_theme.dart` · 54 líneas · **Activo**

`ColorScheme.fromSeed` con semilla `#006B66` en claro y `#5BD7CD` en oscuro.
Tres modificadores: `highContrast` (sube `contrastLevel` a 1.0 y dibuja borde en
las tarjetas), `largeControls` (`VisualDensity(1, 1)`) y `reduceMotion`
(sustituye las transiciones de página por `_NoTransitionsBuilder` en las seis
plataformas objetivo).

### `core/utils/barcode_labels.dart` · 86 líneas · **Parcialmente sin uso**

| Miembro | Estado |
|---|---|
| `BarcodeLabels.format(BarcodeFormat)` | **Activo**: `ScanRecord.fromBarcode` lo llama |
| `BarcodeLabels.contentType(Barcode)` | **Sin uso**: cero llamadas en `lib/` y en `test/` |
| `BarcodeLabels._fallbackType` | Sin uso por transitividad |

`contentType` fue reemplazado por `ParsedContent.title`, que `ScanRecord` toma
del intérprete. Las 39 líneas de `contentType` y `_fallbackType` son código
muerto. R-05.

`format` cubre los 23 valores de `BarcodeFormat` de `mobile_scanner 7.4.0`, uno
de ellos —`BarcodeFormat.itf`— con `// ignore: deprecated_member_use`. Si el
paquete añade un valor, este `switch` exhaustivo **fallará al compilar**, que es
exactamente lo que se quiere.

## `lib/models/` — entidades

| Archivo | Líneas | Clases | Estado |
|---|---|---|---|
| `scan_record.dart` | 161 | `ScanRecord` con tres factorías (`fromBarcode`, `manual`, `fromJson`) | Activo |
| `inventory_session.dart` | 94 | `InventoryItem`, `InventorySession` | Activo |
| `parsed_content.dart` | 54 | `ContentKind` (17 valores), `ParsedContent` | Activo |
| `app_settings.dart` | 89 | `AppLanguage` (4 valores), `AppSettings` (16 campos + banderas) | Activo |

Todas son inmutables (`final` en todos los campos) y todas serializan a JSON.
Ninguna sobrescribe `==` ni `hashCode`: la identidad se compara por `id` allí
donde importa.

**Detalle no obvio en `ScanRecord`**: el `id` se calcula como SHA-256 de
`rawValue|microsegundos` truncado a 20 caracteres. Dos lecturas del mismo código
en microsegundos distintos producen identificadores distintos, así que el
historial **no deduplica lecturas repetidas del mismo código**; lo que sí
deduplica es el mismo código dentro de una misma captura (`unique.putIfAbsent`)
y las lecturas repetidas dentro de una ventana de 2 segundos
(`_lastSignature` / `_lastDetectedAt`).

`AppLanguage` tiene cuatro valores, pero `AppSettings.locale` devuelve
`Locale('en')` para `AppLanguage.en` y el delegado rechaza `en`. El desplegable
de Ajustes ofrece solo tres y **traduce `en` a `system`** para no quedarse sin
coincidencia si una versión futura lo hubiera guardado (comentario en
`settings_screen.dart`, líneas 66-69).

## `lib/services/` — servicios de aplicación y plataforma

| Archivo | Líneas | Responsabilidad | Estado |
|---|---|---|---|
| `content_interpreter.dart` | 402 | 20 ramas de reconocimiento → 17 `ContentKind` | Activo |
| `history_repository.dart` | 223 | Persistencia cifrada del historial, poda, recorte y migración desde preferencias | Activo |
| `import_service.dart` | 194 | Validación y vista previa de respaldos JSON | Activo |
| `export_service.dart` | 164 | JSON, CSV y XLSX de historial e inventario vía `share_plus` | Activo |
| `inventory_repository.dart` | 58 | Persistencia cifrada de sesiones | Activo |
| `settings_repository.dart` | 77 | 17 claves de `SharedPreferencesAsync` | Activo |
| `scan_feedback.dart` | 108 | `ScanTonePlayer`, `AssetScanTonePlayer`, `ScanFeedback` | Activo |
| `pdf_page_renderer.dart` | 2 | `export` condicional | Plataforma |
| `pdf_page_renderer_io.dart` | 115 | Selección y renderizado de PDF a PNG con cancelación | Plataforma |
| `pdf_page_renderer_stub.dart` | 20 | Lanza `UnsupportedError` en web | Plataforma |
| `biometric_service.dart` | 24 | `isAvailable()` y `authenticate()`, ambos con `catch` que devuelve `false` | Activo |
| `clipboard_service.dart` | 14 | Copia con borrado programado condicional | Activo |

**Detalle no obvio en `ClipboardService.copy`**: el borrado programado
**comprueba antes que el portapapeles siga conteniendo el mismo valor**. Si el
usuario copió otra cosa entre medias, no se le borra. El temporizador no se
cancela nunca ni se guarda referencia: sobrevive al `dispose` del widget que lo
inició.

**Detalle no obvio en `ExportService`**: `_encodeCsv` antepone el BOM UTF-8
(`0xEF 0xBB 0xBF`) y usa `\r\n` como separador de línea, y **entrecomilla todas
las celdas sin excepción**. Es la combinación que hace que Excel en Windows abra
el archivo con acentos correctos.

## `lib/state/` — stores

| Archivo | Líneas | Notifica | Cola serial |
|---|---|---|---|
| `scan_store.dart` | 103 | Carga, importación, actualización, poda, borrado | No |
| `inventory_store.dart` | 145 | Cualquier cambio de sesión o de ítem | **Sí** (`AsyncWriteQueue`) |
| `settings_store.dart` | 22 | Cualquier cambio de preferencia | No |

`SettingsStore.update` **notifica antes de persistir** (`notifyListeners()` en la
línea 19, `await _repository.save(value)` en la 20). La interfaz responde al
instante y la escritura ocurre después. *Inferencia*: si la escritura fallara, la
interfaz mostraría un valor que no está guardado. No hay manejo de ese caso.

## `lib/features/` — pantallas

| Carpeta | Archivo | Líneas | Estado |
|---|---|---|---|
| `scanner/` | `scanner_screen.dart` | 638 | Activo · el archivo más grande |
| `scanner/domain/` | `scanner_engine.dart` | 16 | Activo · interfaz de 8 miembros |
| `scanner/data/` | `mobile_scanner_engine.dart` | 36 | Activo · única implementación |
| `scanner/widgets/` | `scanner_overlay.dart` | 145 | Activo · `CustomPainter` del marco y la línea |
| `scanner/widgets/` | `scan_status_bar.dart` | 137 | Activo · `ScanPhase` y la barra de estado |
| `inventory/` | `inventory_screen.dart` | 491 | Activo · **no usa `ScannerEngine`** |
| `settings/` | `settings_screen.dart` | 378 | Activo |
| `result/` | `scan_result_sheet.dart` | 318 | Activo · `ScanResultsSheet`, `ScanRecordCard`, `_RiskBanner` |
| `generator/` | `generator_screen.dart` | 310 | Activo |
| `history/` | `history_screen.dart` | 284 | Activo |
| `formats/` | `formats_screen.dart` | 170 | Activo · **lista estática de 20 formatos, escrita a mano** |
| `formats/domain/` | `content_parser.dart` | 8 | Activo · interfaz de 4 miembros |
| `formats/domain/` | `content_parser_registry.dart` | 38 | Activo |
| `recovery/` | `recovery_screen.dart` | 139 | Activo |

`FormatsScreen` mantiene tres grupos con 20 nombres de formato **escritos como
literales**, sin ninguna relación con `BarcodeLabels.format` ni con lo que el
motor declare. Si `mobile_scanner` añadiera o quitara una simbología, esta
pantalla no lo reflejaría. R-10.

`ScanRecordCard` se reutiliza en dos sitios: dentro de `ScanResultsSheet` tras
una lectura, y desde `HistoryScreen._showDetails`. Su parámetro `compact`
—que oculta la banda de riesgo y los botones de acción— **nunca se pasa como
`true`**: ambos llamantes usan el valor por defecto. R-11.

## `tool/` — herramientas

| Guion | Líneas | Qué hace | Cuándo se ejecuta |
|---|---|---|---|
| `bootstrap.py` | 407 | Genera y parchea `android`, `ios`, `web`, `macos` | Tras clonar; en ambos workflows |
| `validate_structure.py` | 185 | **Diez comprobaciones offline** (ver abajo) | CI, puerta de calidad, publicación |
| `generate_launcher_icons.py` | 174 | Dibuja los iconos por código con Pillow | Solo al cambiar la identidad visual |
| `generate_sbom.py` | 92 | SBOM CycloneDX 1.5; resuelto si hay Flutter, declarado si no | CI, puerta de calidad |
| `generate_scan_beep.py` | 60 | Sintetiza `assets/sounds/scan_success.wav` sin dependencias | Solo al cambiar el tono |
| `generate_license_inventory.py` | 49 | Inventario de licencias desde `.dart_tool/package_config.json` | CI, puerta de calidad |
| `generate_source_manifest.py` | 45 | `SOURCE_MANIFEST.json` con tamaño y SHA-256 de cada fuente | Publicación |
| `generate_checksums.py` | 8 | SHA-256 de los archivos que reciba por argumentos | CI, publicación |
| `run_quality_gate.sh` | 10 | Encadena validación, análisis, pruebas y SBOM | Manual |
| `finalize_stable.sh` | 17 | Lo anterior más compilaciones y manifiesto | Antes de etiquetar |
| `bootstrap.sh` | 4 | Envoltorio POSIX de `bootstrap.py` | Manual |
| `bootstrap.ps1` | 10 | Envoltorio Windows de `bootstrap.py` | Manual |

### Las diez comprobaciones de `validate_structure.py`

Son el **gate propio del repositorio** y revelan qué considera irrompible:

| Función | Comprueba |
|---|---|
| `check_yaml` | Que `pubspec.yaml`, `analysis_options.yaml` y `flutter-ci.yml` sean YAML válido |
| `check_imports` | Que todo `import 'package:universal_code_scanner/…'` apunte a un archivo existente |
| `check_absolute_paths` | Que ningún archivo contenga una de las tres rutas de entorno prohibidas: dos directorios de trabajo de entornos de ejecución remotos y el prefijo del directorio de perfiles de Windows. La lista literal está en la variable `bad` de esa función |
| `check_version` | Que `version` de `pubspec.yaml` sea `X.Y.Z+N` |
| `check_interface_version` | Que `appVersion` de `app_info.dart` coincida con `pubspec.yaml` |
| `check_sensitive_logging` | Que ningún `print`/`debugPrint`/`log` reciba `rawValue`, `password`, `secret`, `otp` o `payload` |
| `check_test_assets` | Que `test_assets/manifest.json` exista, tenga `schemaVersion: 1` y que **cada archivo declarado exista** |
| `check_json_files` | Que todo `.json` del repositorio sea JSON válido |
| `check_markdown_links` | Que **todo enlace relativo de todo `.md`** resuelva a un archivo existente |
| `check_source_sbom` | Que `docs/security/sbom-source.cdx.json` exista y declare `CycloneDX` |

`--require-lock` añade la exigencia de que `pubspec.lock` exista.

`check_markdown_links` es el validador de enlaces del repositorio y cubre también
esta documentación: los directorios excluidos son solo `.git`, `.dart_tool`,
`build`, `coverage` y las carpetas de plataforma.

`check_test_assets` verifica **existencia y forma**, nunca el contenido: no
decodifica ninguna imagen ni compara con `expectedPayload`. Ver R-01.

## Archivos de nivel raíz

| Archivo | Contenido | Estado |
|---|---|---|
| `pubspec.yaml` / `pubspec.lock` | Manifiesto y grafo resuelto y versionado | Activo |
| `analysis_options.yaml` | `flutter_lints` + 4 reglas: `always_declare_return_types`, `avoid_print`, `prefer_final_locals`, `use_build_context_synchronously` | Activo |
| `.fvmrc` | Solo `{"flutter": "3.44.7"}` | Declarativo |
| `.gitattributes` | `* text=auto eol=lf` y binarios explícitos. **Los hashes de `SOURCE_MANIFEST.json` dependen de esto** | Activo |
| `.gitignore` | Excluye artefactos y las cuatro carpetas de plataforma | Activo |
| `SOURCE_MANIFEST.json` | 150 archivos con tamaño y SHA-256 | Regenerable |
| `RELEASE_SOURCE.json` | Qué se validó al publicar 1.1.0, con banderas por comprobación | Manual |
| `VALIDATION.md`, `IMPLEMENTATION_STATUS.md`, `CHANGELOG.md`, `README.md` | Documentación previa | Activo |
| `LICENSE` | MIT | Activo |

## Resumen de elementos sin uso o reservados

| Elemento | Ubicación | Clasificación | Hallazgo |
|---|---|---|---|
| Las nueve banderas de `FeatureFlags` | `core/feature_flags/` | Reservado, sin lector | R-02 |
| `BarcodeLabels.contentType` y `_fallbackType` | `core/utils/` | Sin uso | R-05 |
| Reserva final de `ContentParserRegistry.parse` | `features/formats/domain/` | Inalcanzable | R-08 |
| `RecoveryEntityType.database` y `.startup` | `core/recovery/` | Declarados, nunca emitidos | R-09 |
| Parámetro `compact` de `ScanRecordCard` | `features/result/` | Nunca `true` | R-11 |
| Filtro `paths: web/**` de `deploy-landing.yml` | `.github/workflows/` | Inerte: `web/` está en `.gitignore` | R-12 |
| Seis carpetas de `test_assets/` con solo `README.md` | `test_assets/` | Reservadas a propósito y declaradas | Documentado |

---

Continúa en [05 · Referencia técnica](05-technical-reference.md).
