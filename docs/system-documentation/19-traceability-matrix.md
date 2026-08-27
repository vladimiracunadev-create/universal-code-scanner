# 19 · Matriz de trazabilidad

Cada fila permite seguir una funcionalidad **desde la interfaz hasta la
persistencia y sus pruebas, sin salir de la fila**.

Convención de la columna «Prueba»: se cita el archivo y el nombre del caso. Un
`—` significa **sin prueba automatizada**, y es un dato, no un descuido de esta
tabla.

---

## 1 · Lectura de códigos

| Funcionalidad | Interfaz | Orquestación | Lógica | Datos | Prueba |
|---|---|---|---|---|---|
| Leer con la cámara | `ScannerScreen` · pestaña Escanear | `_handleCapture` | `ScanRecord.fromBarcode` | `scan_history` si procede | — |
| Ver el estado del escáner | `ScanStatusBar` + `ScannerOverlay` | `_phaseFor` | `ScanPhase` | Ninguno | `scan_status_bar_test.dart`: 5 casos |
| Pausar y reanudar | Botón «Pausar»/«Escanear»; toque en la vista | `_togglePause`, `_resumeScanning` | `MobileScannerEngine.stop`/`start` | Ninguno | `scan_status_bar_test.dart`: «a paused camera is announced and offers the way back» |
| Reiniciar la cámara | Botón «Reiniciar cámara» | `_restartCamera` | Nuevo `MobileScannerEngine` + nueva `_previewKey` | Ninguno | — |
| Linterna | Botón de linterna | `_engine.toggleTorch` | `MobileScannerController` | Preferencia `auto_torch` | — |
| Zoom | Deslizador | `_engine.setZoomScale` | `MobileScannerController` | Ninguno | — |
| Cambiar de cámara | Botón | `_engine.switchCamera` | `MobileScannerController` | Ninguno | — |
| Enfocar al tocar | Toque en la vista | `tapToFocus: true` | `MobileScanner` | Ninguno | — |
| Marco de lectura | Ajustes → «Marco de lectura real» | `_settings.useScanWindow` | `scanWindow` o `null` | Preferencia `use_scan_window` | — |
| Varios códigos a la vez | Automático | `_handleCapture` con mapa `unique` | `payloadForBarcode` | Un registro por código | — |
| Antirrebote de 2 s | Automático | `_lastSignature`, `_lastDetectedAt` | Firma ordenada de la captura | Ninguno | — |
| Tono y vibración | Automático tras leer | `ScanFeedback.success` | `AssetScanTonePlayer` · `HapticFeedback` | `assets/sounds/scan_success.wav` | `scan_feedback_test.dart`: 4 casos |
| Movimiento reducido | Ajustes → «Reducir movimiento» | `animate: !reduceMotion` | `_ScanProgressBar`, `ScannerOverlay` | Preferencia `reduce_motion` | `scan_status_bar_test.dart`: «reduced motion keeps the bar readable without movement» |

---

## 2 · Lectura desde archivo

| Funcionalidad | Interfaz | Orquestación | Lógica | Datos | Prueba |
|---|---|---|---|---|---|
| Importar imágenes | Menú → «Varias imágenes» | `_scanFromGallery` | `ImagePicker.pickMultiImage(limit: 20)` · `analyzeImage` | `scan_history`, `source: 'Imagen'` | — |
| Importar PDF | Menú → «Documento PDF» | `_scanFromPdf` | `PdfPageRenderer.pickAndRender(maxPages: 50)` | `scan_history`, `source: 'PDF · página N'` | — |
| Progreso del lote | `_BatchProgressDialog` | `_runBatchDialog` | `BatchProgress` | Ninguno | `cancellation_token_test.dart`: «batch progress reports a bounded fraction» |
| Cancelar un lote | Botón «Cancelar» | `token.cancel()` | `CancellationToken` · `PdfPageRenderCancellationToken` | **Nada se modifica** | `cancellation_token_test.dart`: «cancellation token stops batch work deterministically» |
| Limpieza de temporales | Automática | `PdfPageRenderer.cleanup` | Borra PNG y directorio | Directorio temporal | — |

---

## 3 · Interpretación del contenido

| Tipo interpretado | Detección | Función | `sensitive` | Prueba |
|---|---|---|---|---|
| Enlace web | `http`/`https` o `www.` | `ContentInterpreter.parse` rama 18 | no | `content_interpreter_test.dart`: «normaliza un enlace que comienza con www» |
| Wi-Fi | `wifi:` | `_wifi` + `_segments` | **sí si trae contraseña** | «interpreta Wi-Fi con campos escapados» |
| Contacto vCard | `begin:vcard` | `_vcard` | no | «interpreta una vCard» |
| Contacto MeCard | `mecard:` | `_mecard` | no | — |
| Evento | `begin:vevent` | `_event` | no | — |
| Correo | `mailto:` o `matmsg:` | `_email` | no | — |
| Teléfono | `tel:` | Rama en línea | no | — |
| SMS | `sms:` o `smsto:` | `_sms` | no | — |
| Ubicación | `geo:` | `_geo` | no | — |
| OTP | `otpauth:` | `_otp` | **sí** | `scan_record_test.dart`: «identifica OTP y Wi-Fi con contraseña como sensibles» |
| Criptomoneda | `bitcoin:`, `lightning:`, `ethereum:` | `_crypto` | **sí** | — |
| Swiss QR Bill | Empieza por `SPC\n` | `_swissQr` | **sí** | — |
| EPC / SEPA | Empieza por `BCD\n` | `_epc` | **sí** | — |
| EMVCo | `000201` y contiene `6304` | `_emv` + `_tlv` | **sí** | «interpreta datos EMVCo» |
| AAMVA | `@` y contiene `ANSI ` | `_aamva` | **sí** | — |
| GS1 | `(NN)` o `<GS>` | `_gs1` + `_aiLabel` | no | «interpreta identificadores GS1» |
| ISBN | 13 dígitos con `978`/`979`, o 10 caracteres | `_isIsbn` | no | «identifica ISBN» |
| Producto | 8 a 14 dígitos | Rama en línea | no | — |
| Binario | `binary-base64:` | Rama 1 | no | `scan_record_test.dart`: «conserva un contenido binario como Base64» |
| Texto | Todo lo demás | Rama final | no | — |
| Parser propio | `register()` | `ContentParserRegistry` | Lo decide el parser | `content_parser_registry_test.dart`: «custom parser is isolated and removable» |

**Cobertura**: 6 de 20 ramas tienen prueba. Ver R-10 y la propuesta 6 de
[12-testing-and-quality.md](12-testing-and-quality.md).

---

## 4 · Análisis de riesgo

| Señal | Nivel | Prueba |
|---|---|---|
| HTTPS normal, sin señales | `low` | `scan_security_analyzer_test.dart`: «acepta un enlace HTTPS común» |
| `http` sin TLS | `caution` | «advierte cuando el enlace usa HTTP» |
| Host vacío | `high` | — |
| Credenciales antes del dominio | `high` | «marca credenciales antes del dominio como riesgo elevado» |
| Correo en la consulta, no credencial | `low` | «no marca un correo dentro de la consulta como credencial» |
| Punycode (`xn--`) | `high` | «marca Punycode como riesgo elevado» |
| Alfabetos mezclados | `high` | — |
| Caracteres internacionales en el host | `caution` | — |
| IP literal | `caution` | — |
| Red privada, `localhost` o `.local` | `high` | — |
| Acortador conocido (11 dominios) | `caution` | — |
| Más de 5 subdominios | `caution` | — |
| Puerto inusual | `caution` | — |
| Longitud mayor de 240 | `caution` | — |
| Caracteres de control o `%00` | `high` | — |
| Descarga ejecutable (17 extensiones) | `high` | — |
| Ruta que aparenta inicio de sesión | `caution` | — |
| Tres o más parámetros de seguimiento | `caution` | — |
| Esquema de aplicación no permitido | `high`, `canOpen: false` | «bloquea esquemas desconocidos» |
| Esquema de sistema (`tel:`) | `low`, `canOpen: true` | «permite acciones telefónicas explícitas» |
| Contenido estructurado (Wi-Fi) | `low`, `canOpen: false` | «trata un QR Wi-Fi como contenido estructurado» |
| Pago o secreto (`otpauth:`) | `caution`, `canOpen: false` | «advierte que una clave OTP es sensible» |

Todo en `lib/core/security/scan_security_analyzer.dart`. **9 de 22 casos tienen
prueba.**

---

## 5 · Acciones sobre un resultado

| Funcionalidad | Interfaz | Orquestación | Condición | Salida | Prueba |
|---|---|---|---|---|---|
| Abrir un enlace | Botón «Abrir» | `_openRecord` | Diálogo si `confirmBeforeOpen` **o** riesgo distinto de `low` | `launchUrl` | — |
| Llamar, correo, SMS, mapa | Botón contextual | `_openRecord` + `_actionUri` | Misma condición | `launchUrl` | — |
| Copiar | Botón «Copiar» | `ClipboardService.copy` | Ninguna | Portapapeles, con borrado programado | — |
| Compartir texto | Botón «Compartir» | `_shareRecord` | **Diálogo si el registro es sensible** | `share_plus` | — |
| Compartir contacto | Idem, tipo `contact` | `_shareRecord` | Idem | Archivo `.vcf`, MIME `text/vcard` | — |
| Compartir evento | Idem, tipo `event` | `_shareRecord` | Idem | Archivo `.ics`, MIME `text/calendar` | — |
| Enmascarar valores sensibles | Botón del ojo | `_revealed` local | `isSensitive && hideSensitiveValues` | Ninguna: solo pantalla | — |
| Banda de riesgo | `_RiskBanner` | — | Siempre visible salvo `compact` | Ninguna | — |

**Ninguna fila de esta tabla tiene prueba automatizada.** Es el hueco más
relevante de la suite: aquí viven la decisión de confirmación y la de
enmascarado. Ver la propuesta 8 de
[12-testing-and-quality.md](12-testing-and-quality.md).

---

## 6 · Historial

| Funcionalidad | Interfaz | Orquestación | Persistencia | Prueba |
|---|---|---|---|---|
| Guardar una lectura | Automático | `_persistAndShow` → `ScanStore.addAll` | `HistoryRepository.upsertAll` → `scan_history` | — |
| **No** guardar contenido sensible | Automático | `records.where((r) => !r.isSensitive)` | Nada se escribe | `scan_record_test.dart` prueba `isSensitive`, **no el filtro** |
| No guardar con sesión privada | Ajustes → «Sesión privada» | `!privateMode` | Nada se escribe | — |
| No guardar nunca | Ajustes → «Guardar historial» | `saveHistory` | Nada se escribe | — |
| Listar y filtrar | `HistoryScreen` | Filtro en memoria | Lectura de `scan_history` | — |
| Buscar | Campo de búsqueda | `rawValue`, `contentType`, `format`, etiquetas, notas | En memoria | — |
| Filtrar por riesgo | `ChoiceChip` | `_risk` | En memoria | — |
| Favoritos | Icono de estrella | `ScanStore.toggleFavorite` | `upsert` recifrando | — |
| Notas y etiquetas | Menú → «Notas y etiquetas» | `_edit` → `ScanStore.update` | `upsert` recifrando | — |
| Eliminar un registro | Menú → «Eliminar» | `ScanStore.remove` | `_store.record(id).delete` | — |
| Borrar todo | Menú → «Borrar historial», con diálogo | `ScanStore.clear` | `_store.delete` | — |
| Retención automática | Ajustes → «Retención del historial» | `_updateRetention` | `pruneOlderThan` por `scannedAt` | — |
| Recorte a 5 000 | Automático tras escribir | `_trim` | Borra los más antiguos | — |
| Cargar al arrancar | Automático | `ScanStore.initialize` | `HistoryRepository.load` | — |
| Actualizar sobres antiguos | Automático al cargar | `inspect` + `upgradeEnvelope` | Reescribe el `payload` | — |
| Aislar registros dañados | Automático | `catch` en `load` | Incidencia en `recovery_issues` | — |

---

## 7 · Importación y exportación

| Funcionalidad | Interfaz | Orquestación | Validación | Prueba |
|---|---|---|---|---|
| Importar historial | Menú → «Importar respaldo JSON» | `_importHistory` | 6 puertas en `ImportService` | `import_service_test.dart`: 4 casos |
| Vista previa | Diálogo con válidos, duplicados y rechazados | `HistoryImportPreview` | Nada se escribe hasta elegir | «history import previews valid, duplicate, and rejected records» |
| Estrategia «Omitir duplicados» | Botón | `preview.apply(ids, skipDuplicates)` | — | Misma prueba |
| Estrategia «Combinar» | Botón | `ScanStore.addAll` | — | — |
| Estrategia «Reemplazar» | Botón | `HistoryRepository.replaceAll` | Transacción atómica | `history_repository_test.dart`: «replaceAll atomically replaces the stored history» |
| Rechazar esquema futuro | Automático | `schemaVersion > 2` | `FormatException` | «future schema is rejected before modifying data» |
| Colapsar duplicados internos | Automático | Mapa por `id` | — | «duplicate records inside the same file are collapsed before import» |
| Rechazar JSON profundo | Automático | `_validateJsonShape` | `FormatException` | «excessively deep JSON is rejected before persistence» |
| Exportar historial JSON | Menú | `ExportService.shareHistoryJson` | — | — |
| Exportar historial CSV | Menú | `shareHistoryCsv` → `compute(_encodeCsv)` | — | — |
| Exportar historial XLSX | Menú | `shareHistoryXlsx` → `compute(_encodeXlsx)` | — | — |
| Importar inventario | Botón «Importar JSON» | `_importInventory` | `maxInventoryItems` | — |
| Exportar inventario | Menú de la sesión | Tres métodos de `ExportService` | — | — |

---

## 8 · Inventario

| Funcionalidad | Interfaz | Orquestación | Persistencia | Prueba |
|---|---|---|---|---|
| Crear una sesión | Campo + «Iniciar inventario» | `InventoryStore.createSession` | `inventory_sessions` | — |
| Contar leyendo | Cámara del inventario | `_onDetect` → `addScan` | Cifrado, con cola serial | — |
| Antirrebote de 1200 ms | Automático | `_lastCode`, `_lastAt` | Ninguna | — |
| Cambiar cantidad | Botones ± | `setQuantity` | Cifrado | — |
| Quitar un producto | Menú, o restar hasta cero | `setQuantity(code, 0)` | Elimina del mapa | — |
| Nota de producto | Menú → «Editar nota» | `updateItemNotes` | Cifrado | — |
| Cerrar la sesión | Botón «Cerrar», con diálogo | `closeActive` | Escribe `closedAt` | — |
| Reabrir | Menú → «Reabrir sesión» | `reopenSession` | Limpia `closedAt` | — |
| Eliminar la sesión | Menú → «Eliminar» | `deleteSession` | Borra el registro | — |
| Importar como copia | «Importar JSON» | `importSession` | **Siempre `id` nuevo** | — |
| Serializar el modelo | — | `toJson`/`fromJson` | — | `inventory_session_test.dart`: «calcula unidades y conserva datos al serializar» |
| Escrituras serializadas | Automático | `AsyncWriteQueue` | — | `async_write_queue_test.dart`: 2 casos |

**El inventario no filtra contenido sensible** (R-03) y **no usa `ScannerEngine`**
(R-04).

---

## 9 · Generador

| Funcionalidad | Interfaz | Lógica | Salida | Prueba |
|---|---|---|---|---|
| Nueve tipos de carga | Desplegable | `_payload` | Cadena | — |
| Diez formatos visuales | Desplegable | `_barcode` | `Barcode` de `barcode_widget` | — |
| Corrección de errores | Interruptor, solo QR | `BarcodeQRCorrectionLevel` | — | — |
| Escapar el Wi-Fi | Automático | `_escape` | Inverso de `_segments` | — |
| Normalizar la URL | Automático | `_normalizeUrl` | Antepone `https://` | — |
| Vista previa | `BarcodeWidget` | — | Pantalla | — |
| Error de contenido inválido | `errorBuilder` | — | Mensaje explícito | — |
| Copiar los datos | Botón | `ClipboardService.copy` | Portapapeles | — |
| Compartir los datos | Botón | `SharePlus` | Texto | — |
| Exportar PNG | Botón | `RepaintBoundary.toImage(pixelRatio: 3)` | Archivo PNG | — |
| Exportar SVG | Botón | `Barcode.toSvg` | Archivo SVG | — |

**Nada del generador se persiste.**

---

## 10 · Cifrado y datos

| Funcionalidad | Módulo | Detalle | Prueba |
|---|---|---|---|
| Cifrar una carga | `PayloadCipher.encryptJson` | AES-256-GCM, sobre versionado | `payload_cipher_test.dart`: «versioned envelope round-trips without exposing clear values» |
| Descifrar | `decryptJson` | Acepta sobre actual y heredado | Misma prueba |
| Leer un sobre heredado | `decryptJson` con `legacy` | Sin campo `version` | «legacy envelope remains readable and can be upgraded» |
| Actualizar un sobre | `upgradeEnvelope` | Solo si hace falta | Misma prueba |
| Inspeccionar sin descifrar | `inspect` | Versión, algoritmo, `keyId` | Usada en varias pruebas |
| Rechazar versión futura | `decryptJson` | `FormatException` | «future cipher envelope versions are rejected explicitly» |
| Rechazar manipulación | `decryptJson` | Fallo del MAC | «tampered authenticated ciphertext is rejected» |
| **No** regenerar llave ausente | `_missingKeyIds` | Bloquea cifrado **y** descifrado | «a missing decryption key is never replaced silently» |
| Guardar la llave | `SecureStorageKeyProvider` | `ucs_database_key_<keyId>` | — |
| Llave en memoria | `MemoryEncryptionKeyProvider` | Modo temporal y pruebas | Usada en todas |
| Rotar la llave | `DataMaintenanceService` | Transacción única | `data_maintenance_test.dart`: «key rotation updates records and active metadata in one database transaction» |
| Abortar rotación incompleta | Idem | `StateError` | «rotation aborts before changing metadata when a payload is incomplete» |
| Limpiar llave huérfana | Idem | `forgetKey` en el `catch` | «failed rotation removes a newly generated orphan key» |
| Guardar la llave activa | `EncryptionMetadataRepository` | `_security_meta` | Cubierta indirectamente |
| Migrar el metadato desde preferencias | Idem | Lee, escribe y borra | — |
| Migrar el esquema | `SchemaMigrator` | Idempotente y transaccional | `schema_migrator_test.dart`: «schema migration is idempotent and non-destructive» |
| Migrar el historial heredado | `HistoryRepository._migrateLegacyHistory` | Respaldo, verificación, borrado | **—** (R-34) |

---

## 11 · Recuperación y diagnóstico

| Funcionalidad | Interfaz | Módulo | Persistencia | Prueba |
|---|---|---|---|---|
| Inicio seguro | `_StartupRecovery` | `BootstrapHost` | Ninguna | `app_launch_test.dart` (integración) |
| Reintentar arranque | Botón «Reintentar» | `_retry()` | Ninguna | — |
| Modo temporal | Botón | `initialize(temporary: true)` | **Memoria** | — |
| Restablecer preferencias | Botón | `resetNonSensitive()` | Borra 14 de 17 claves | — |
| Copiar diagnóstico | Botón | `AppDiagnostics.exportJson` | Ninguna | `diagnostics_test.dart`: «diagnostic export excludes error messages and sensitive values» |
| Registrar errores globales | Automático | `installGlobalErrorHandlers` | Memoria, 100 entradas | Misma prueba |
| Listar incidencias | `RecoveryScreen` | `RecoveryService.load` | `recovery_issues` | — |
| Reintentar recuperación | Menú | `RecoveryService.retry` | Reinserta el registro | — |
| Descartar | Menú, con diálogo | `RecoveryService.discard` | Borra el registro | — |
| Marcar revisado | Menú | `repository.mark` | Cambia el estado | — |
| Limpiar resueltas | Botón | `clearResolved` | Borra las no pendientes | — |
| Exportar paquete | Icono de la barra | `exportBundle` | Ninguna | `recovery_service_test.dart`: «recovery bundle preserves ciphertext but never includes the key or clear payload» |
| Accesibilidad de la pantalla | — | — | — | `accessibility_test.dart`: texto al 200 % |

---

## 12 · Ajustes

| Ajuste | Clave | Consume | Prueba |
|---|---|---|---|
| Tema | `theme_mode` | `MaterialApp.themeMode` | — |
| Idioma | `language` | `MaterialApp.locale` | `localization_test.dart`: 4 casos |
| Alto contraste | `high_contrast` | `AppTheme` | — |
| Controles grandes | `large_controls` | `AppTheme` | — |
| Reducir movimiento | `reduce_motion` | Tema, barra y marco | `scan_status_bar_test.dart` |
| Marco de lectura | `use_scan_window` | Ambas pantallas de cámara | — |
| Linterna al iniciar | `auto_torch` | **Solo `ScannerScreen`** | — |
| Sonido | `sound_enabled` | `ScanFeedback.success` | `scan_feedback_test.dart` |
| Vibración | `vibration_enabled` | Idem | Idem |
| Guardar historial | `save_history` | `_persistAndShow` | — |
| Sesión privada | `private_mode` | Idem | — |
| Ocultar sensibles | `hide_sensitive_values` | `ScanRecordCard` | — |
| Confirmar antes de abrir | `confirm_before_open` | `_openRecord` | — |
| Bloqueo de la aplicación | `biometric_lock` | `BiometricLockGate` | — |
| Borrar portapapeles | `clear_clipboard_seconds` | `ClipboardService.copy` | — |
| Retención | `history_retention_days` | `pruneOlderThan` | — |
| Banderas | `feature_flags` | **Nadie** (R-02) | — |
| Ancho de teléfono | — | `HandheldFrame` | `handheld_frame_test.dart`: 3 casos |

---

## 13 · Garantías públicas y su verificación

Cada afirmación que el proyecto hace de cara al público, con el código que la
implementa y el estado real de su verificación.

| Garantía | Fuente | Código | Prueba | Estado |
|---|---|---|---|---|
| «Nada se abre solo» | `README.md` | `_openRecord` · un solo `launchUrl` | — | **Verificado por lectura** |
| «Historial cifrado AES-256-GCM» | `README.md` | `PayloadCipher` | 5 casos | **Verificado** |
| «Llave ausente ≠ llave nueva» | `README.md` | `_missingKeyIds` | 1 caso | **Verificado** |
| «Rotación segura» | `README.md` | `rotateEncryptionKey` | 3 casos | **Verificado** |
| «OTP y Wi-Fi fuera del historial» | `README.md`, `docs/SECURITY.md` | `_persistAndShow` | `isSensitive` sí; el filtro **no** | **Parcial** · falso en el inventario (R-03) |
| «Diagnóstico sin datos» | `README.md` | `AppDiagnostics` | 1 caso | **Verificado** |
| «Telemetría cero» | `README.md` | Sin cliente de red ni permiso `INTERNET` | — | **Verificado por `grep`** |
| «16 señales locales» | `README.md`, `CHANGELOG.md` | `analyze` | 9 de 22 casos | **Verificado por conteo** |
| «57 pruebas en verde» | `README.md`, `VALIDATION.md` | — | `flutter test` | **Verificado ejecutando** |
| «`analyze --fatal-infos`: 0 hallazgos» | `README.md`, `VALIDATION.md` | — | `flutter analyze` | **Verificado ejecutando** |
| «Modo temporal en memoria» | `README.md` | `openTemporary` | — | Verificado por lectura |
| «Centro de recuperación por registro» | `README.md` | `RecoveryService` | 1 caso | **Verificado** |
| «Generador de 10 simbologías» | `README.md` | `_CodeFormat` | — | **Verificado por conteo** |
| «Lotes de 20 imágenes y 50 páginas» | `README.md` | `limit: 20`, `maxPages: 50` | — | **Verificado por lectura** |
| «Catálogo de regresión de 8 imágenes» | `CHANGELOG.md` | `test_assets/manifest.json` | **Ninguna** | **Existe, no se ejecuta** (R-01) |
| «`ScannerEngine` aísla el motor» | `docs/ARCHITECTURE.md` | Solo en `ScannerScreen` | — | **Parcial** (R-04) |
| «`FeatureFlags` reserva capacidades» | `docs/quality/FEATURE_FLAGS.md` | Persistido, sin lector | — | **Reserva de forma** (R-02) |
| «Interfaz solo en español» | `README.md` | Delegado rechaza `en` | 4 casos | **Verificado** |
| «APK con clave de depuración» | `README.md`, `docs/RELEASE.md` | — | — | **Declarado** |
| «Sin pruebas en dispositivos físicos» | `IMPLEMENTATION_STATUS.md` | — | — | **Declarado** |

---

## 14 · De un archivo a su cobertura

Vista inversa: qué archivo prueba qué.

| Archivo de prueba | Cubre |
|---|---|
| `test/core/payload_cipher_test.dart` | `PayloadCipher`, `MemoryEncryptionKeyProvider` |
| `test/core/data_maintenance_test.dart` | `DataMaintenanceService`, `EncryptionMetadataRepository` |
| `test/core/recovery_service_test.dart` | `RecoveryService.exportBundle`, `RecoveryRepository.record` |
| `test/core/schema_migrator_test.dart` | `SchemaMigrator` |
| `test/core/diagnostics_test.dart` | `AppDiagnostics` |
| `test/core/async_write_queue_test.dart` | `AsyncWriteQueue` |
| `test/core/cancellation_token_test.dart` | `CancellationToken`, `BatchProgress` |
| `test/core/localization_test.dart` | `AppLocalizations` y su delegado |
| `test/core/handheld_frame_test.dart` | `HandheldFrame` |
| `test/core/accessibility_test.dart` | `RecoveryScreen` con texto al 200 % |
| `test/features/scan_status_bar_test.dart` | `ScanStatusBar`, `ScannerOverlay` |
| `test/services/import_service_test.dart` | `ImportService`, `HistoryImportPreview` |
| `test/services/history_repository_test.dart` | `HistoryRepository.replaceAll` y `load` |
| `test/services/scan_feedback_test.dart` | `ScanFeedback`, `ScanTonePlayer` |
| `test/services/content_parser_registry_test.dart` | `ContentParserRegistry`, `ContentParser` |
| `test/content_interpreter_test.dart` | `ContentInterpreter`, 6 de 20 ramas |
| `test/scan_security_analyzer_test.dart` | `ScanSecurityAnalyzer`, 9 de 22 casos |
| `test/scan_record_test.dart` | `ScanRecord` y su serialización |
| `test/inventory_session_test.dart` | `InventorySession`, `InventoryItem` |
| `integration_test/app_launch_test.dart` | `BootstrapHost`, arranque completo |

### Archivos de `lib/` sin ninguna prueba que los toque

`app.dart` (salvo `HandheldFrame`), `bootstrap.dart`, `bootstrap_host.dart`,
`main.dart`, `core/app_info.dart`, `core/feature_flags/`, `core/theme/`,
`core/utils/barcode_labels.dart`, `models/app_settings.dart`, `models/parsed_content.dart`,
`services/biometric_service.dart`, `services/clipboard_service.dart`,
`services/export_service.dart`, `services/inventory_repository.dart`,
`services/settings_repository.dart`, `services/pdf_page_renderer*.dart`,
`state/scan_store.dart`, `state/inventory_store.dart`, `state/settings_store.dart`,
y **todas** las pantallas de `features/` salvo los dos widgets del escáner.

---

Vuelve al [índice](README.md).
