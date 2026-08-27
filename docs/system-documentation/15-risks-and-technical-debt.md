# 15 · Riesgos y deuda técnica

## Alcance de este documento

**Informativo. No se corrigió ninguno de estos hallazgos.** El encargo de esta
documentación excluye expresamente modificar el comportamiento del código: los
únicos cambios aplicados a `lib/` son comentarios y documentación de símbolos,
que no alteran la ejecución.

Cada hallazgo lleva severidad, impacto, probabilidad, evidencia verificable,
ubicación, recomendación y prioridad. Todos se comprobaron con `grep` o leyendo
el código; ninguno es una sospecha.

## Antes de la lista: lo que está bien

Un informe que solo enumera problemas da una imagen falsa y se descarta por
sesgado. Estas propiedades del repositorio son **sólidas** y alguien las romperá
si nadie dice que importan:

1. **Ninguna acción externa sin confirmación.** `launchUrl` aparece **una sola
   vez** en las 6 821 líneas de `lib/`, y está detrás de un diálogo cuya
   condición es una disyunción entre el ajuste del usuario y el nivel de riesgo.
2. **Una llave ausente nunca se regenera en silencio.** Doble barrera en
   `PayloadCipher`, con prueba dedicada.
3. **La rotación de llave limpia su propia basura.** Con prueba dedicada.
4. **La migración verifica antes de borrar**, dentro de la transacción.
5. **La importación se valida completa antes de tocar la base**, con seis
   puertas y vista previa.
6. **El diagnóstico es estructuralmente incapaz de filtrar datos**: acepta un
   `Object` y guarda su `runtimeType`, no el mensaje.
7. **Cero telemetría, cero red saliente propia, cero permiso `INTERNET`.**
8. **Las 19 dependencias directas usan versión exacta**, sin `^`, con lockfile
   versionado.
9. **La degradación está declarada, nunca silenciosa**: el SBOM marca su
   cobertura real, la CI explica por qué omite la prueba de integración, y
   `ScanFeedback` avisa por bandera cuando el audio dejó de funcionar.
10. **El repositorio tiene gates propios y baratos**: diez comprobaciones
    offline que corren en menos de un segundo.
11. **La documentación previa declara lo que no se ha verificado**, sin adornos.

## Resumen por severidad

| Severidad | Cantidad | Identificadores |
|---|---|---|
| **Alta** | 3 | R-01, R-02, R-03 |
| **Media** | 9 | R-04, R-06, R-13, R-15, R-19, R-27, R-32, R-33, R-34 |
| **Baja** | 23 | El resto |
| **Total** | 35 | R-01 a R-35 |

Ninguno es crítico: no hay pérdida de datos, fuga de secretos ni fallo de
seguridad explotable en el estado actual del código.

---

## Severidad alta

### R-01 · El catálogo de regresión no lo ejecuta ninguna prueba

| Aspecto | Detalle |
|---|---|
| **Severidad** | Alta |
| **Impacto** | Ocho escenarios de lectura —daño parcial, poca luz, deformación, varios códigos en una imagen— están preparados, versionados y documentados, y **nunca se ejecutan**. Una regresión en la lectura no la detecta nada |
| **Probabilidad** | Certeza: ya ocurre |
| **Evidencia** | `grep -rn "test_assets" test/ integration_test/ lib/` devuelve **0 resultados**. `tool/validate_structure.py::check_test_assets` comprueba únicamente que el manifiesto exista, tenga `schemaVersion: 1` y que **cada archivo declarado exista en disco**: no decodifica ninguna imagen ni compara con `expectedPayload` |
| **Ubicación** | `test_assets/manifest.json`, `tool/validate_structure.py` líneas 116-129 |
| **Recomendación** | Añadir una prueba de integración con dispositivo que use `analyzeImage` sobre las ocho imágenes y compare con `expectedPayload`. Mientras no exista, decir en `test_assets/README.md` que el catálogo es material para la matriz manual, no una suite automatizada |
| **Prioridad** | 1 |

*Inferencia basada en el código*: una prueba que use
`MobileScannerController.analyzeImage` necesita el motor de plataforma, que no
existe bajo `flutter test`. Esa es probablemente la razón de que no se haya
escrito. **No está documentada en el repositorio.**

### R-02 · Nueve banderas de capacidad que nadie consulta

| Aspecto | Detalle |
|---|---|
| **Severidad** | Alta como deuda de coherencia; nula como riesgo de ejecución |
| **Impacto** | `FeatureFlags` se serializa, se persiste y se restaura correctamente, y **ningún código de la aplicación la lee**. `docs/quality/FEATURE_FLAGS.md`, `IMPLEMENTATION_STATUS.md` y el contrato de compatibilidad la presentan como una frontera de extensión activa. Un lector concluye que existe un mecanismo de activación que no existe |
| **Probabilidad** | Certeza |
| **Evidencia** | `grep` sobre los nueve nombres (`experimentalParsers`, `secondaryScannerEngine`, `ocr`, `nfc`, `urlReputation`, `productLookup`, `encryptedSync`, `enterpriseApi`, `kioskMode`) devuelve **0 apariciones fuera de `lib/core/feature_flags/feature_flags.dart`**. Tampoco hay control en Ajustes para cambiarlas |
| **Ubicación** | `lib/core/feature_flags/feature_flags.dart`, `lib/models/app_settings.dart`, `lib/services/settings_repository.dart` |
| **Recomendación** | Documentar en `docs/quality/FEATURE_FLAGS.md` que en 1.1.0 las banderas son una **reserva de forma persistida**, no un mecanismo activo, y que activar una no tiene efecto |
| **Prioridad** | 2 |

### R-03 · El inventario persiste contenido sensible; el escáner no

| Aspecto | Detalle |
|---|---|
| **Severidad** | Alta |
| **Impacto** | Un QR de Wi-Fi con contraseña, un OTP, un QR de pago o un documento AAMVA escaneado **dentro de una sesión de inventario** se persiste con su texto íntegro como clave del ítem. Va cifrado, pero contradice una garantía enunciada públicamente. Además, ese texto sale **en claro** al exportar la sesión |
| **Probabilidad** | Media: requiere que alguien escanee un código sensible en modo inventario |
| **Evidencia** | `InventoryScreen._onDetect` llama a `widget.store.addScan(record)` sin comprobar `record.isSensitive`. `InventoryStore.addScan` indexa por `record.rawValue`. Compárese con `ScannerScreen._persistAndShow`, que sí filtra: `records.where((r) => !r.isSensitive)` |
| **Contradice** | `docs/SECURITY.md` punto 5 («No persistir automáticamente OTP ni Wi-Fi con contraseña»), `docs/PRIVACY_POLICY.md` y `README.md` |
| **Ubicación** | `lib/features/inventory/inventory_screen.dart` líneas 389-405; `lib/state/inventory_store.dart` líneas 89-106 |
| **Recomendación** | Decidir explícitamente: o filtrar también aquí, o documentar la excepción. Un inventario de códigos de producto nunca contiene secretos, así que filtrar no rompería el caso de uso real |
| **Prioridad** | 1 |

---

## Severidad media

### R-04 · `InventoryScreen` no usa `ScannerEngine`

| Aspecto | Detalle |
|---|---|
| **Severidad** | Media |
| **Impacto** | La frontera de extensión no cubre las dos pantallas que usan cámara. Un segundo motor exigiría reescribir también el inventario. Además, `autoTorch` **no se aplica** allí: es una diferencia de comportamiento observable |
| **Probabilidad** | Certeza |
| **Evidencia** | `inventory_screen.dart` construye `MobileScannerController` directamente en `_createController()` y llama al controlador sin pasar por la interfaz. Sus opciones omiten `torchEnabled` y `returnImage` |
| **Contradice** | `docs/ARCHITECTURE.md`: «`ScannerEngine` es la frontera estable alrededor del paquete de captura» |
| **Ubicación** | `lib/features/inventory/inventory_screen.dart` líneas 41-48 |
| **Recomendación** | Migrar `InventoryScreen` a `ScannerEngine`, o documentar que la frontera cubre solo la pestaña Escanear |
| **Prioridad** | 3 |

### R-06 · La puerta de calidad local es más laxa que la CI

| Aspecto | Detalle |
|---|---|
| **Severidad** | Media |
| **Impacto** | Un desarrollador ejecuta `tool/run_quality_gate.sh`, lo ve en verde, hace push, y la CI falla |
| **Probabilidad** | Alta cuando aparece un aviso informativo nuevo |
| **Evidencia** | `tool/run_quality_gate.sh` línea 6: `flutter analyze`. `.github/workflows/flutter-ci.yml` línea 44: `flutter analyze --fatal-infos`. `README.md` y `VALIDATION.md` documentan la forma estricta |
| **Ubicación** | `tool/run_quality_gate.sh` |
| **Recomendación** | Añadir `--fatal-infos`. Coste: un cambio de una línea |
| **Prioridad** | 3 |

### R-13 · `legacyKeyId` y `currentKeyId` valen lo mismo

| Aspecto | Detalle |
|---|---|
| **Severidad** | Media en potencia, baja hoy |
| **Impacto** | Ambas constantes valen `'v2'`. Cambiar `currentKeyId` sin cambiar `legacyKeyId` rompería **silenciosamente** la lectura de los sobres heredados: se buscaría una llave que no existe |
| **Probabilidad** | Baja hoy; alta si alguien introduce un `v3` como identificador por defecto |
| **Evidencia** | `payload_cipher.dart` líneas 82-83: `static const String currentKeyId = 'v2'; static const String legacyKeyId = 'v2';` |
| **Ubicación** | `lib/core/security/payload_cipher.dart` |
| **Recomendación** | Comentar por qué coinciden, o definir `legacyKeyId` con un literal propio para que un cambio en `currentKeyId` no lo arrastre |
| **Prioridad** | 4 |

### R-15 · `replaceAll` no recorta el historial

| Aspecto | Detalle |
|---|---|
| **Severidad** | Media |
| **Impacto** | `upsert` y `upsertAll` llaman a `_trim()`; `replaceAll` no. Hoy no puede desbordar porque `ImportService.maxHistoryRecords` vale también `5000`, pero **la protección depende de que dos constantes de archivos distintos sigan siendo iguales** |
| **Probabilidad** | Baja hoy; certeza si alguien sube el límite de importación |
| **Evidencia** | `history_repository.dart` líneas 99-114: `replaceAll` no invoca `_trim()`. `maxItems = 5000` en `history_repository.dart` línea 27; `maxHistoryRecords = 5000` en `import_service.dart` línea 46 |
| **Ubicación** | `lib/services/history_repository.dart` |
| **Recomendación** | Llamar a `_trim()` también desde `replaceAll`, o derivar `ImportService.maxHistoryRecords` de `HistoryRepository.maxItems` |
| **Prioridad** | 4 |

### R-19 · La lista de campos enmascarados es literal

| Aspecto | Detalle |
|---|---|
| **Severidad** | Media |
| **Impacto** | Solo cinco nombres se enmascaran: `Contraseña`, `Secreto`, `Dirección`, `IBAN`, `Carga`. Un parser nuevo que produjera un campo sensible con otro nombre —`Clave`, `Semilla`, `PIN`— **se mostraría en claro** aunque el registro estuviera marcado como sensible |
| **Probabilidad** | Baja hoy; certeza si se añade un parser |
| **Evidencia** | `scan_result_sheet.dart` línea 113 |
| **Ubicación** | `lib/features/result/scan_result_sheet.dart` |
| **Recomendación** | Mover la marca de sensibilidad al nivel de campo dentro de `ParsedContent`, en lugar de deducirla del nombre |
| **Prioridad** | 4 |

### R-27 · La exportación sale en claro sin advertencia en la interfaz

| Aspecto | Detalle |
|---|---|
| **Severidad** | Media |
| **Impacto** | Compartir **un registro** sensible abre un diálogo de advertencia. Exportar **todo el historial** a CSV, XLSX o JSON no muestra ninguno, y el archivo resultante no está cifrado |
| **Probabilidad** | Alta: es la vía normal de exportar |
| **Evidencia** | `ExportService` no cifra nada; `HistoryScreen` invoca los tres métodos de exportación desde un `PopupMenuButton` sin diálogo previo. Compárese con `ScanRecordCard._shareRecord`, que sí lo tiene |
| **Ubicación** | `lib/features/history/history_screen.dart` líneas 76-81; `lib/services/export_service.dart` |
| **Recomendación** | Añadir un diálogo antes de exportar, con el número de registros y la advertencia de que el archivo va en claro |
| **Prioridad** | 3 |

### R-32 · Sin CSP ni cabeceras de seguridad para la PWA

| Aspecto | Detalle |
|---|---|
| **Severidad** | Media |
| **Impacto** | `docs/SECURITY.md` exige publicar la PWA «con HSTS y cabeceras de seguridad apropiadas». No hay ninguna configuración que las aplique |
| **Probabilidad** | Certeza |
| **Evidencia** | **No identificado**: no existe archivo de cabeceras, ni meta `Content-Security-Policy` en `landing/index.html`, ni paso en `deploy-landing.yml` que las añada. GitHub Pages no permite cabeceras personalizadas |
| **Ubicación** | `landing/`, `.github/workflows/deploy-landing.yml` |
| **Recomendación** | Añadir una meta CSP en el HTML, que es lo único que GitHub Pages permite, o rebajar la exigencia de `docs/SECURITY.md` a lo que la plataforma soporta |
| **Prioridad** | 4 |

### R-33 · Las acciones de GitHub no están fijadas a SHA

| Aspecto | Detalle |
|---|---|
| **Severidad** | Media |
| **Impacto** | Riesgo de cadena de suministro. Un compromiso de cualquiera de esos repositorios ejecutaría código arbitrario en el runner que compila los APK publicados |
| **Probabilidad** | Baja, pero de impacto alto |
| **Evidencia** | Los 13 `uses:` de los dos workflows apuntan a etiquetas móviles: `actions/checkout@v7`, `actions/setup-python@v7`, `subosito/flutter-action@v2`, `actions/upload-artifact@v7`, `actions/configure-pages@v5`, `actions/upload-pages-artifact@v3`, `actions/deploy-pages@v4` |
| **Mitigación presente** | `permissions: contents: read` en el trabajo de calidad; permisos acotados en el de publicación; ningún secreto consumido |
| **Ubicación** | `.github/workflows/flutter-ci.yml`, `.github/workflows/deploy-landing.yml` |
| **Recomendación** | Fijar cada acción a un SHA de commit y dejar que Dependabot los actualice |
| **Prioridad** | 3 |

### R-34 · La migración del historial no tiene prueba

| Aspecto | Detalle |
|---|---|
| **Severidad** | Media |
| **Impacto** | Es el flujo con más precauciones del repositorio —respaldo cifrado, verificación dentro de la transacción, borrado solo al final— y el que más daño haría si se rompiera: es el único que puede **perder datos del usuario**. No tiene ninguna prueba |
| **Probabilidad** | Baja de que se rompa; alta de que nadie lo note si se rompe |
| **Evidencia** | Ningún archivo de `test/` menciona `scan_history_v1`, `_migrateLegacyHistory` ni `HistoryMigrationStatus`. `history_repository_test.dart` cubre solo `replaceAll` |
| **Ubicación** | `lib/services/history_repository.dart` líneas 154-221 |
| **Recomendación** | Tres casos: instalación limpia, migración correcta con verificación del respaldo cifrado, y fallo que conserva el origen y crea la incidencia |
| **Prioridad** | 2 |

---

## Severidad baja

### R-05 · Código muerto en `BarcodeLabels`

`BarcodeLabels.contentType` y `_fallbackType` (39 líneas) **no se llaman desde
ningún sitio**: `grep -rn "BarcodeLabels\." lib test` devuelve una sola línea,
`scan_record.dart:44`, que usa `format`. Fueron sustituidos por
`ParsedContent.title`. **Recomendación**: eliminarlos. **Prioridad**: 6.

### R-07 · Un modelo importa una carpeta de `features`

`lib/models/scan_record.dart` línea 9 importa
`features/formats/domain/content_parser_registry.dart`. No es un ciclo, pero
invierte la dirección declarada de las capas. El registro de parsers pertenece
conceptualmente a `services`. **Recomendación**: mover
`features/formats/domain/` a `lib/services/parsers/`. **Prioridad**: 6.

### R-08 · Línea inalcanzable en `ContentParserRegistry.parse`

La reserva final `return ContentInterpreter.parse(rawValue)` no se alcanza nunca:
`LegacyContentParser.canParse` devuelve siempre `true` y `unregister` protege
`builtin-v2`. Es defensa redundante, no un error. **Recomendación**: comentarla
como defensa deliberada. **Prioridad**: 7.

### R-09 · Dos valores de enumeración que nunca se emiten

`RecoveryEntityType.database` y `.startup` están declarados y **nunca se pasan a
`RecoveryRepository.record`**: `grep -rn "entityType: RecoveryEntityType\." lib`
muestra solo `history` (2), `inventory` (2) y `migration` (1). Sus ramas en
`retry` y `discard` son inalcanzables. **Recomendación**: emitirlos desde el
manejador de fallo de arranque, o eliminarlos. **Prioridad**: 6.

### R-10 · `FormatsScreen` lista formatos a mano

Tres grupos con 20 nombres escritos como literales, sin relación con
`BarcodeLabels.format` ni con lo que declare el motor. Si `mobile_scanner`
añadiera o quitara una simbología, la pantalla no lo reflejaría. **Prioridad**: 6.

### R-11 · El parámetro `compact` nunca se usa

`ScanRecordCard.compact` tiene valor por defecto `false` y **ningún llamante lo
pasa como `true`**: `grep -rn "compact" lib test` muestra solo la declaración, el
campo y su uso interno. La rama que oculta la banda de riesgo y los botones es
inalcanzable. **Prioridad**: 7.

### R-12 · Un filtro de ruta inerte en el workflow de publicación

`deploy-landing.yml` incluye `web/**` en su lista `paths:`, pero `/web/` está en
`.gitignore` y no hay ningún archivo versionado bajo esa ruta. Ese filtro **no
puede dispararse nunca**. **Recomendación**: eliminarlo. **Prioridad**: 7.

### R-14 · Cualquier cadena de 10 dígitos se clasifica como ISBN

`ContentInterpreter._isIsbn` devuelve `true` si, tras eliminar todo lo que no sea
dígito o `X`, la longitud es exactamente 10. Como esa comprobación va **antes**
de la rama de producto (`^\d{8,14}$`), un código de producto de 10 dígitos
aparece como «ISBN». **Recomendación**: validar el dígito de control del ISBN-10.
**Prioridad**: 5.

### R-16 · El CSV del historial no incluye las notas; el XLSX sí

El CSV tiene 8 columnas y omite `notas`; el XLSX tiene 9 y la incluye. Los dos
del inventario tienen 8 y ambos incluyen `notas`. Es una asimetría sin motivo
aparente. **Recomendación**: añadir `notas` al CSV del historial.
**Prioridad**: 6.

### R-17 · `_failure` se asigna fuera de `setState`

En `_BootstrapHostState._retry`, el `catchError` asigna `_failure` sin envolver
en `setState`. Funciona porque el `setState` que asigna `_future` ya programó una
reconstrucción y el `FutureBuilder` se reconstruye al resolverse el `Future`,
pero **depende de ese orden**. **Recomendación**: envolver la asignación.
**Prioridad**: 5.

### R-18 · Los formatos de pago se interpretan por posición de línea

Swiss QR Bill y EPC/SEPA leen campos por índice fijo (`lines[3]`, `lines[5]`,
`lines[18]`, `lines[19]`). Es lo que especifican ambos estándares, pero una
variante con líneas insertadas produciría campos desplazados **sin ningún aviso**:
los `if (lines.length > N)` evitan el desbordamiento, no el desalineamiento.
**Recomendación**: validar la versión del formato antes de mapear.
**Prioridad**: 5.

### R-20 · Las llaves antiguas no se borran tras rotar

`rotateEncryptionKey` no llama a `forgetKey` sobre la llave anterior en el camino
de éxito. El almacén seguro acumula una entrada por rotación, y material capaz de
descifrar datos antiguos permanece en el dispositivo. Es prudente, pero **no está
documentado**. **Prioridad**: 5.

### R-21 · `RecoveryService.retry` pierde la causa del fallo

Su `catch` es `on Object { return false; }`: cualquier error se convierte en un
`false` que la interfaz traduce a «No fue posible recuperar el elemento». **No se
registra en `AppDiagnostics`**, así que la causa se pierde justo en la pantalla
diseñada para diagnosticar. **Recomendación**: registrar antes de devolver
`false`. **Prioridad**: 4.

### R-22 · Mezcla de fechas locales y UTC

`ScanRecord.scannedAt` e `InventorySession.createdAt` usan `DateTime.now()`
(**local**) y se serializan sin sufijo de zona. `RecoveryIssue.detectedAt`, el
`createdAt` del sobre de cifrado y los `exportedAt` usan `toUtc()`. Comparar
registros creados en zonas horarias distintas —por ejemplo tras importar un
respaldo ajeno— produciría un orden incorrecto. **Recomendación**: unificar en
UTC y mostrar en local. **Prioridad**: 4.

### R-23 · Cuatro marcas de esquema que nadie lee

`v2MigratedAt`, `recoveryStoreEnabled`, `cipherEnvelopeVersion` y
`encryptionMetadataInDatabase` se escriben en `_schema_meta` y **no se leen
nunca**: `grep` sobre los cuatro nombres devuelve solo `schema_migrator.dart`.
Son registro histórico, no configuración. **Recomendación**: documentarlo como
tal. **Prioridad**: 7.

### R-24 · `SchemaMigrationResult` se descarta

`AppDatabase.open()` y `openTemporary()` hacen `await
SchemaMigrator(...).migrate();` sin usar el resultado. `fromVersion`, `toVersion`
y `applied` solo los consume la prueba. **Recomendación**: registrar el resultado
en `AppDiagnostics` cuando `applied` no esté vacío. **Prioridad**: 6.

### R-25 · `normalizedHost` se calcula y se descarta

`SecurityAssessment.normalizedHost` se rellena en `analyze` y **`ScanRecord` no lo
guarda**: no aparece en `toJson`. Sería útil para filtrar el historial por
dominio. **Prioridad**: 7.

### R-26 · El temporizador del portapapeles no se puede cancelar

`ClipboardService.copy` crea un `Timer` cuya referencia no se guarda. Sobrevive
al `dispose` del widget y se dispara aunque se haya salido de la pantalla. Es
intencional —el objetivo es limpiar pase lo que pase— y está mitigado por la
comprobación de que el valor no haya cambiado. **No está documentado.**
**Prioridad**: 6.

### R-28 · El paquete de recuperación no tiene importador

`RecoveryService.exportBundle` produce un JSON con `schemaVersion: 1` que **nada
consume**. No hay importador ni herramienta que lo procese. Su utilidad real es
entregarlo a soporte. **Recomendación**: decirlo en
`docs/quality/RECOVERY.md`. **Prioridad**: 6.

### R-29 · `ScannerEngine` filtra tipos de `mobile_scanner`

Dos de sus nueve miembros —`controller` y `state`— devuelven
`MobileScannerController` y `ValueListenable<MobileScannerState>`. Un motor
alternativo tendría que producir esos tipos, lo que la hace inservible como
frontera independiente del proveedor. Es una abstracción de conveniencia sobre el
paquete actual. **Recomendación**: rediseñarla con tipos propios si alguna vez se
añade un segundo motor. **Prioridad**: 5.

### R-30 · Cambiar la retención poda sin confirmar

`_updateRetention` guarda el ajuste y llama de inmediato a `pruneOlderThan`.
Elegir «30 días» **borra ahí mismo** todo lo anterior, sin diálogo y sin
posibilidad de deshacer. Compárese con «Borrar todo el historial», que sí
confirma. **Recomendación**: añadir un diálogo que indique cuántos registros se
eliminarán. **Prioridad**: 4.

### R-31 · Dos funciones hash distintas para el mismo propósito

`ScanRecord.id` usa SHA-256 truncado a 20; `InventorySession.id` usa SHA-1
truncado a 16. No es un problema de seguridad —son identificadores locales con
marca de tiempo en la entrada— pero es una inconsistencia entre dos modelos
hermanos. **Prioridad**: 7.

### R-35 · Sin umbral de cobertura

`flutter test --coverage` genera `lcov.info` y la CI lo sube como artefacto,
pero **nada falla si la cobertura baja**: no hay umbral en el workflow, ni en
`validate_structure.py`, ni en la documentación. **Recomendación**: declarar un
mínimo y hacerlo fallar la CI. **Prioridad**: 5.

---

## Deuda de documentación

Contradicciones o vacíos entre lo que la documentación previa afirma y lo que el
código hace. Se registran aquí, **no se corrigieron**.

| # | Documento | Afirma | Realidad |
|---|---|---|---|
| D-1 | `docs/SECURITY.md` punto 5 | «No persistir automáticamente OTP ni Wi-Fi con contraseña» | Cierto en el escáner; **falso en el inventario** (R-03) |
| D-2 | `docs/ARCHITECTURE.md` | «`ScannerEngine` es la frontera estable alrededor del paquete de captura» | `InventoryScreen` no la usa (R-04) |
| D-3 | `docs/quality/FEATURE_FLAGS.md` | Presenta las nueve banderas como funciones aisladas activables | Ninguna se consulta (R-02) |
| D-4 | `docs/quality/DEVICE_TEST_MATRIX.md` | «Los recursos reproducibles están en `test_assets/manifest.json`» | Correcto, pero ninguna prueba automatizada los usa (R-01) |
| D-5 | `docs/SECURITY.md` | Exige HSTS y cabeceras de seguridad para la PWA | No hay configuración que las aplique (R-32) |
| D-6 | Ningún documento | — | El **momento** de cada lectura queda en claro en la base, aunque el contenido no. No estaba dicho en ningún sitio |
| D-7 | Ningún documento | — | `resetNonSensitive` deja intactas exactamente tres claves. Solo lo dice el nombre del método |
| D-8 | Ningún documento | — | `HistoryRepository.load` **escribe** en la base al actualizar sobres antiguos |

Los ocho quedan documentados en este directorio: D-6, D-7 y D-8 en
[07-database.md](07-database.md) y
[06-deep-code-explanation.md](06-deep-code-explanation.md).

### Referencia histórica correcta

No es deuda y conviene no «corregirlo»: `docs/quality/SCOPE_1_0.md` y el
`CHANGELOG.md` mencionan **48 pruebas**. Es correcto: se refieren a la versión
1.0.0. El marcador de estado actual —57— aparece en `README.md`,
`VALIDATION.md`, `IMPLEMENTATION_STATUS.md` y `RELEASE_SOURCE.json`, y los cuatro
coinciden con lo medido.

Igual ocurre con `COMPATIBILITY_CONTRACT.md`, que habla de «los compromisos que
la versión 1.0.0 adquiere»: es una referencia histórica deliberada.

---

## Priorización sugerida

Informativo. **Nada de esto se aplicó.**

| Prioridad | Hallazgos | Esfuerzo conjunto estimado |
|---|---|---|
| **1** | R-01, R-03 | 1 jornada |
| **2** | R-02, R-34 | Media jornada |
| **3** | R-04, R-06, R-27, R-33 | 1 jornada |
| **4** | R-13, R-15, R-19, R-21, R-22, R-30, R-32 | 1 jornada |
| **5** | R-14, R-17, R-18, R-20, R-29, R-35 | Media jornada |
| **6** | R-05, R-07, R-09, R-10, R-16, R-24, R-26, R-28 | Media jornada |
| **7** | R-08, R-11, R-12, R-23, R-25, R-31 | 2 horas |

Los dos de prioridad 1 son los únicos que afectan a una garantía enunciada
públicamente (R-03) o a una capacidad de detección que se cree tener y no se
tiene (R-01).

---

Continúa en [16 · Glosario](16-glossary.md).
