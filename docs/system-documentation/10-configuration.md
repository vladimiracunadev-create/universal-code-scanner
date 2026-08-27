# 10 · Configuración

## Cómo se configura este sistema

No hay archivos `.env`, ni variables de entorno de aplicación, ni servidor de
configuración remota. **Todo lo configurable vive en tres sitios**:

| Nivel | Dónde | Quién lo cambia | Cuándo tiene efecto |
|---|---|---|---|
| **Preferencias del usuario** | `SharedPreferencesAsync` | La persona, desde Ajustes | Al instante |
| **Constantes de compilación** | Literales en `lib/` | Quien modifica el código | Al recompilar |
| **Configuración del repositorio** | `pubspec.yaml`, `.fvmrc`, `analysis_options.yaml`, `.github/` | Quien mantiene el proyecto | Al ejecutar la herramienta correspondiente |

Las únicas variables de entorno del proyecto son de CI: `FLUTTER_VERSION` en
ambos workflows y `APP_BASE_HREF` en el de publicación. Ninguna llega a la
aplicación en ejecución.

---

## 1 · Preferencias del usuario

Diecisiete claves, todas escritas por `SettingsRepository.save` y leídas por
`SettingsRepository.load`. La tabla incluye **la consecuencia real de cada
valor**, no solo su nombre.

### Apariencia

| Clave | Tipo | Por defecto | Valores | Qué cambia |
|---|---|---|---|---|
| `theme_mode` | `String` | `system` | `system`, `light`, `dark` | `MaterialApp.themeMode` |
| `language` | `String` | `system` | `system`, `esCl`, `es` (`en` existe pero no se ofrece) | `MaterialApp.locale` |
| `high_contrast` | `bool` | `false` | — | Sube `contrastLevel` de `ColorScheme.fromSeed` a `1.0` y dibuja un borde de 1,5 px en las tarjetas |
| `large_controls` | `bool` | `false` | — | `VisualDensity(horizontal: 1, vertical: 1)`. **No cambia el tamaño del texto**: eso lo controla el sistema |
| `reduce_motion` | `bool` | `false` | — | Tres efectos: sin transiciones de página, barra de estado quieta, marco sin línea de barrido |

**Sobre `language`**: el desplegable ofrece solo tres opciones. Si una versión
futura hubiera guardado `en`, el desplegable lo traduce a `system` para no
quedarse sin coincidencia (`settings_screen.dart`, líneas 66-69). Y aunque se
guardara `en`, `_AppLocalizationsDelegate.isSupported` lo rechaza y Flutter
recae en el primer idioma admitido: **nunca se produce una interfaz a medio
traducir**. Cuatro pruebas protegen esa decisión.

### Escáner

| Clave | Tipo | Por defecto | Qué cambia |
|---|---|---|---|
| `use_scan_window` | `bool` | `true` | Si `true`, `scanWindow` es el cuadrado central del 68 %; si `false`, se pasa `null` y se analiza **toda** la imagen |
| `auto_torch` | `bool` | `false` | Enciende la linterna al crear el motor. **Solo en `ScannerScreen`**: el inventario no lo aplica |
| `sound_enabled` | `bool` | `true` | Reproduce el tono empaquetado tras cada lectura |
| `vibration_enabled` | `bool` | `true` | `HapticFeedback.mediumImpact()` tras cada lectura |

`use_scan_window` es el ajuste que el README ofrece como solución cuando un
código no entra en el marco: desactivarlo analiza la imagen completa a costa de
más trabajo por cuadro.

`sound_enabled` y `vibration_enabled` son **independientes**: hay una prueba que
comprueba que activar uno no activa el otro
(`test/services/scan_feedback_test.dart`, «each channel honours its own setting»).

### Privacidad y seguridad

| Clave | Tipo | Por defecto | Qué cambia |
|---|---|---|---|
| `save_history` | `bool` | `true` | Si `false`, **ninguna lectura del escáner se persiste**. El inventario sigue guardando |
| `private_mode` | `bool` | `false` | Si `true`, mismo efecto que apagar `save_history`. Existe como interruptor temporal frente al permanente |
| `hide_sensitive_values` | `bool` | `true` | Enmascara con `••••••••` los campos `Contraseña`, `Secreto`, `Dirección`, `IBAN` y `Carga` de un registro sensible |
| `confirm_before_open` | `bool` | `true` | Exige diálogo antes de abrir. **Desactivarlo no elimina el diálogo para riesgo `caution` o `high`** |
| `biometric_lock` | `bool` | `false` | Bloquea la aplicación al pasar a segundo plano |
| `clear_clipboard_seconds` | `int` | `30` | `0`, `15`, `30`, `60` o `300`. `0` = nunca borrar |
| `history_retention_days` | `int` | `0` | `0`, `30`, `90` o `365`. `0` = sin límite |

Tres detalles que conviene conocer:

**`save_history` y `private_mode` hacen lo mismo.** La condición es
`if (_settings.saveHistory && !_settings.privateMode)`. La diferencia es de
intención: uno es una política permanente, el otro una sesión concreta. Ninguno
de los dos afecta al inventario.

**`biometric_lock` no se puede activar a ciegas.** `_changeBiometricLock`
comprueba primero `isDeviceSupported()` y después **exige una autenticación
correcta** antes de guardar el ajuste. Si el dispositivo no lo admite o el
usuario cancela, muestra «No se pudo activar el bloqueo en este dispositivo» y
el ajuste no cambia. Es la dirección correcta: no se puede quedar bloqueado
fuera de su propia aplicación.

**`history_retention_days` se aplica en dos momentos**: al arrancar
(`AppBootstrapper.initialize` llama a `pruneOlderThan` con el valor guardado) y
al cambiarlo (`_updateRetention` guarda y poda de inmediato). Cambiarlo a 30 días
**borra ahí mismo** todo lo anterior a esa fecha, sin diálogo de confirmación.
R-30.

### Banderas de capacidad

| Clave | Tipo | Por defecto | Qué cambia |
|---|---|---|---|
| `feature_flags` | `String` (JSON) | Nueve `false` | **Nada.** Ver abajo |

`FeatureFlags` se serializa, se guarda, se lee y se restaura correctamente. Y
**ningún código lo consulta**: las nueve banderas no aparecen fuera de
`feature_flags.dart`. Tampoco hay control en Ajustes para cambiarlas, así que en
la práctica la clave siempre contiene los nueve `false` por defecto.

| Bandera | Capacidad reservada | Documentada en |
|---|---|---|
| `experimentalParsers` | Parsers experimentales | [`../quality/FEATURE_FLAGS.md`](../quality/FEATURE_FLAGS.md) |
| `secondaryScannerEngine` | Segundo motor de escaneo | idem |
| `ocr` | Reconocimiento óptico de texto | idem |
| `nfc` | Lectura NFC | idem |
| `urlReputation` | Reputación remota de URLs | idem |
| `productLookup` | Consulta de productos | idem |
| `encryptedSync` | Sincronización cifrada | idem |
| `enterpriseApi` | API empresarial | idem |
| `kioskMode` | Modo kiosco | idem |

Si un `feature_flags` malformado llegara a preferencias, `SettingsRepository.load`
lo captura y vuelve al valor por defecto en vez de fallar el arranque.

### Restablecimiento parcial

`SettingsRepository.resetNonSensitive()` —accesible desde la pantalla de inicio
seguro— borra **14 de las 17 claves**:

```dart
'theme_mode', 'language', 'sound_enabled', 'vibration_enabled', 'auto_torch',
'use_scan_window', 'confirm_before_open', 'hide_sensitive_values', 'high_contrast',
'large_controls', 'reduce_motion', 'clear_clipboard_seconds', 'history_retention_days',
'feature_flags',
```

**Deja intactas `save_history`, `private_mode` y `biometric_lock`.** Es
deliberado: un botón de recuperación de emergencia no puede desactivar el
bloqueo de la aplicación ni reactivar el guardado de historial que el usuario
había apagado a propósito. La decisión **no está documentada en el repositorio**
fuera del nombre del método.

---

## 2 · Constantes de compilación

Estas no son configurables en ejecución. Cambiarlas exige recompilar.

### Límites operativos

| Constante | Valor | Archivo | Consecuencia de subirla |
|---|---|---|---|
| Imágenes por lote | `20` | `scanner_screen.dart` | Más memoria y más tiempo de bloqueo del isolate |
| Páginas de PDF | `50` | `scanner_screen.dart`, `pdf_page_renderer_io.dart` | Idem, y más archivos temporales simultáneos |
| Píxeles objetivo del render | `2400` en el lado mayor | `_renderScale` | Memoria: un A4 a 4× son ~3400×4800 px |
| Escala mínima y máxima | `[1.5, 4.0]` | idem | Códigos pequeños ilegibles por debajo |
| Registros de historial | `5000` | `HistoryRepository.maxItems` | Tiempo de carga: `load` descifra todos |
| Registros por respaldo | `5000` | `ImportService.maxHistoryRecords` | Debe seguir igual que el anterior; ver R-15 |
| Productos por sesión importada | `10000` | `ImportService.maxInventoryItems` | Memoria |
| Tamaño de archivo importado | `25 MB` | `ImportService.maxImportBytes` | Se decodifica completo en memoria |
| Profundidad de JSON | `32` | `ImportService.maxJsonDepth` | Defensa contra JSON hostil |
| Nodos de JSON | `100 000` | `ImportService.maxJsonNodes` | Idem |
| Entradas de diagnóstico | `100` | `AppDiagnostics.maxEntries` | Solo memoria |

`docs/quality/PERFORMANCE.md` añade la regla de proceso: **estos límites no deben
ampliarse sin medir memoria, tiempo y temperatura en dispositivos reales**.

### Comportamiento de la interfaz

| Constante | Valor | Archivo | Qué controla |
|---|---|---|---|
| `HandheldFrame.maxWidth` | `560` | `app.dart` | Umbral de centrado en pantallas anchas |
| Lado del marco | `0.68` del lado menor | `scanner_screen.dart` | Tamaño del cuadrado de lectura |
| Radio del marco | `28` | `scanner_overlay.dart` | Esquinas redondeadas del recorte |
| Longitud de la esquina | `42` | idem | Las cuatro escuadras |
| Opacidad del velo | `0.58` | idem | Oscurecimiento fuera del marco |
| Duración del barrido | `2200 ms` con inversión | idem | Velocidad de la línea |
| Antirrebote del escáner | `2 s` por combinación | `scanner_screen.dart` | Evita releer el mismo conjunto |
| Antirrebote del inventario | `1200 ms` por código | `inventory_screen.dart` | Permite recontar más rápido |
| Semilla del tema claro | `#006B66` | `app_theme.dart` | Color base |
| Semilla del tema oscuro | `#5BD7CD` | idem | Color base |
| Fondo del icono adaptativo | `#005854` | `tool/bootstrap.py` | Color del icono de Android |

### Criptografía

| Constante | Valor | Consecuencia de cambiarla |
|---|---|---|
| `PayloadCipher.currentVersion` | `2` | **Datos existentes ilegibles** si se rompe la compatibilidad |
| `PayloadCipher.currentAlgorithm` | `'AES-256-GCM'` | Idem |
| `PayloadCipher.currentKeyId` | `'v2'` | Se buscaría una llave que no existe |
| `PayloadCipher.legacyKeyId` | `'v2'` | Los sobres heredados dejarían de leerse |
| `SecureStorageKeyProvider._prefix` | `'ucs_database_key_'` | Se perdería el acceso a todas las llaves guardadas |
| `SchemaMigrator.currentVersion` | `4` | Bajarla deja bases existentes por delante del código |

Estas seis son las **más peligrosas del repositorio**. Cambiar cualquiera sin
una migración explícita convierte los datos del usuario en ruido.

### Señales de riesgo

Dos conjuntos literales en `scan_security_analyzer.dart`:

- **`_shorteners`**, 11 dominios: `bit.ly`, `tinyurl.com`, `t.co`, `goo.gl`,
  `ow.ly`, `buff.ly`, `is.gd`, `cutt.ly`, `rebrand.ly`, `shorturl.at`,
  `tiny.one`.
- **`_dangerousExtensions`**, 17 extensiones: `.apk .appx .bat .cmd .com .dmg
  .exe .hta .iso .jar .js .msi .pkg .ps1 .scr .vbs .zip`.

Ambas son listas cerradas y **no se actualizan sin recompilar**. Es la
consecuencia directa de no consultar reputación remota: la aplicación no puede
aprender de acortadores nuevos. Está declarado como límite en `README.md` y en
`docs/SECURITY.md`.

Y dos listas más, en otros archivos:

- **Campos enmascarados**, en `scan_result_sheet.dart`: `Contraseña`, `Secreto`,
  `Dirección`, `IBAN`, `Carga`.
- **Palabras de inicio de sesión**, en `_looksLikeLogin`: `login`, `signin`,
  `verify`, `account`, `password`, `wallet`, `bank`.

---

## 3 · Configuración del repositorio

### `pubspec.yaml`

| Campo | Valor | Nota |
|---|---|---|
| `name` | `universal_code_scanner` | Determina el prefijo de todos los `import 'package:…'` |
| `version` | `1.1.0+2` | `validate_structure.py` exige la forma `X.Y.Z+N` y que coincida con `appVersion` |
| `publish_to` | `"none"` | Impide una publicación accidental en pub.dev |
| `environment.sdk` | `>=3.12.0 <4.0.0` | — |
| `environment.flutter` | `>=3.44.0` | El toolchain real se fija en `.fvmrc` |
| `flutter.assets` | `assets/sounds/` | **Única carpeta empaquetada**. Los iconos de `assets/launcher/` los copia `bootstrap.py`, no se empaquetan |

**Detalle no obvio**: `assets/launcher/` **no está en `flutter.assets`**. Sus PNG
no viajan dentro del APK como recursos de Flutter; los copia `bootstrap.py` a
`android/app/src/main/res/` y a `web/icons/`, donde el sistema operativo los
consume como iconos nativos.

### Los tres anclajes de dependencia

| Paquete | Fijado en | Motivo exacto |
|---|---|---|
| `share_plus` | `12.0.2` | Desde `13.0.0` exige `win32 ^6`, incompatible con el `win32 ^5.9` de `file_picker 11.x` |
| `pdfrx` | `2.4.5` | Desde `2.4.6` arrastra `archive ^4`, incompatible con el `archive ^3.6.1` de `excel 4.0.6` |
| `excel` | `4.0.6` | Última publicada; es la que ancla `archive` a la serie 3 |

Los dos primeros están además en `.github/dependabot.yml` con la razón escrita al
lado, para que Dependabot no proponga subirlos. `flutter pub outdated` sí los
muestra como actualizables: **subirlos rompe `pub get`**.

### `analysis_options.yaml`

```yaml
include: package:flutter_lints/flutter.yaml
linter:
  rules:
    always_declare_return_types: true
    avoid_print: true
    prefer_final_locals: true
    use_build_context_synchronously: true
```

Cuatro reglas sobre `flutter_lints 6.0.0`. `avoid_print` es un control de
privacidad además de estilo: se combina con `check_sensitive_logging` del
validador, que además prohíbe que cualquier `print`, `debugPrint` o `log` reciba
`rawValue`, `password`, `secret`, `otp` o `payload`.

**Comprobado**: `grep -rn "print(" lib --include=*.dart | wc -l` devuelve `0`.

### `.gitattributes`

```text
* text=auto eol=lf
*.png binary
*.jpg binary
*.jpeg binary
*.zip binary
*.ttf binary
*.otf binary
*.ps1 text eol=crlf
```

El comentario que lo encabeza explica el porqué: **los SHA-256 de
`SOURCE_MANIFEST.json` dependen de que los finales de línea sean estables tras
un clon en Windows**. La excepción de `.ps1` a CRLF es para que PowerShell lo
lea de forma nativa.

Consecuencia práctica: cualquier archivo de texto nuevo que se añada al
repositorio **debe escribirse con LF**. Un CRLF de más rompe la verificación del
manifiesto.

### Variables de los workflows

| Variable | Valor | Dónde | Para qué |
|---|---|---|---|
| `FLUTTER_VERSION` | `3.44.7` | Ambos workflows | `subosito/flutter-action@v2` |
| `APP_BASE_HREF` | `/universal-code-scanner/app/` | `deploy-landing.yml` | `flutter build web --base-href` |

`APP_BASE_HREF` **debe empezar y terminar en `/`**, y hay un comentario en el
workflow que lo dice. Es la ruta desde la que GitHub Pages sirve la PWA.

### `.gitignore`

Además de los artefactos habituales (`.dart_tool/`, `build/`, `coverage/`,
`.idea/`, `.vscode/`, `*.iml`), excluye las **cuatro carpetas de plataforma**:

```text
# Se generan con tool/bootstrap.py
/android/
/ios/
/web/
/macos/
```

Es la decisión estructural del repositorio. Ver
[02-installation-and-execution.md](02-installation-and-execution.md).

---

## 4 · Matriz de decisión: qué ajuste tocar para conseguir qué

| Quiero… | Ajuste | Valor |
|---|---|---|
| Que no quede rastro de mis lecturas | Sesión privada | Activada |
| Que no quede rastro nunca | Guardar historial | Desactivado |
| Que el historial se limpie solo | Retención del historial | 30, 90 o 365 días |
| Leer códigos fuera del marco central | Marco de lectura real | Desactivado |
| Que nadie más abra la aplicación | Bloqueo de la aplicación | Activado |
| Escanear en silencio | Sonido de confirmación | Desactivado |
| Escanear sin vibración | Vibración | Desactivada |
| Ver las contraseñas Wi-Fi sin pulsar el ojo | Ocultar valores sensibles | Desactivado |
| Abrir enlaces sin diálogo (salvo los de riesgo) | Confirmar antes de abrir | Desactivado |
| Que lo copiado no se quede en el portapapeles | Borrar portapapeles | 15 s |
| Que lo copiado se quede | Borrar portapapeles | Nunca |
| Menos animación | Reducir movimiento | Activado |
| Botones más grandes | Controles más grandes | Activado |
| Más contraste | Alto contraste | Activado |
| Cambiar la llave de cifrado | Rotar llave de cifrado | Acción, no ajuste |

---

## 5 · Lo que **no** es configurable

Merece decirse, porque alguien lo buscará:

- **El idioma inglés.** Existe la infraestructura, existen las claves, y el
  delegado lo rechaza a propósito.
- **Las banderas de capacidad.** Se guardan pero no se leen ni se pueden cambiar.
- **La lista de acortadores y de extensiones peligrosas.** Literales de
  compilación.
- **Los límites de lote, de historial y de importación.** Constantes.
- **La ubicación de la base de datos.** La decide `path_provider`.
- **El nivel de riesgo a partir del cual se exige confirmación.** Está fijo en
  «cualquier cosa que no sea `low`».
- **Qué campos se enmascaran.** Lista literal de cinco nombres.

---

Continúa en [11 · Seguridad](11-security.md).
