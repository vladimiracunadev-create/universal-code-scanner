# 14 · Solución de problemas

Cada entrada sigue la misma estructura: **síntoma → causa → diagnóstico →
solución → archivos → riesgo de aplicar la solución**.

Las entradas de la sección 1 son para quien usa la aplicación; las de la 2 y la
3, para quien la desarrolla o la publica.

---

## 1 · Problemas de uso

### 1.1 · «Escaneando» y la barra se mueve, pero el código no entra

| Aspecto | Detalle |
|---|---|
| **Síntoma** | La barra de estado dice «Escaneando» y se mueve, la imagen se ve, y ningún código se lee |
| **Causa** | El motor **sí** está analizando cuadros: la barra en movimiento lo demuestra. El problema es el encuadre, la distancia, el enfoque o la luz. Con el marco activado, solo se analiza el cuadrado central del 68 % |
| **Diagnóstico** | Si la barra se mueve, descarta un fallo de arranque. Prueba a acercar o alejar el teléfono y a usar el deslizador de zoom |
| **Solución** | Acercar o alejar, usar el zoom, encender la linterna, tocar la imagen para enfocar. Si sigue sin entrar, desactivar **Marco de lectura real** en Ajustes para analizar toda la imagen |
| **Archivos** | `lib/features/scanner/scanner_screen.dart` (cálculo de `window`), `lib/models/app_settings.dart` (`useScanWindow`) |
| **Riesgo** | Ninguno. Desactivar el marco solo aumenta el trabajo por cuadro; puede reducir la velocidad de detección en teléfonos modestos |

### 1.2 · «Escaneando» y ningún código de ningún tipo entra

| Aspecto | Detalle |
|---|---|
| **Síntoma** | Con el marco activado, ni siquiera un QR grande y bien iluminado se lee |
| **Causa** | El recorte de lectura podría no coincidir con lo que se ve. La ventana se calcula desde el tamaño de la cámara y la orientación, datos que pueden llegar después del primer cuadro |
| **Diagnóstico** | Desactivar **Marco de lectura real**. Si con la imagen completa sí lee, era la ventana |
| **Solución** | Pulsar **Reiniciar cámara**, que reconstruye el controlador y la vista previa con una clave nueva. O desactivar el marco |
| **Archivos** | `scanner_screen.dart`, método `_restartCamera` |
| **Riesgo** | Ninguno. `_restartCamera` libera el controlador antiguo antes de crear el nuevo y reinicia el zoom a 0 |

Este es exactamente el defecto que originó la versión 1.1.0. La causa técnica
—un umbral de actualización de la ventana fijado en `4` sobre una magnitud que se
expresa entre 0 y 1, es decir, «no recalcular nunca»— está en
[`../quality/SCANNER_UX.md`](../quality/SCANNER_UX.md). Ya está corregida: el
umbral se eliminó.

### 1.3 · «Iniciando cámara…» que no avanza

| Aspecto | Detalle |
|---|---|
| **Síntoma** | La barra dice «Iniciando cámara…» y se queda ahí |
| **Causa** | `MobileScannerState.isRunning` sigue en `false`: la cámara no llegó a entregar imagen. Suele ser otra aplicación ocupando el sensor |
| **Diagnóstico** | La fase `starting` significa que no hubo error, solo ausencia de cuadros. Si hubiera error, la fase sería `unavailable` |
| **Solución** | **Reiniciar cámara**. Si persiste, cerrar otras aplicaciones que la usen |
| **Archivos** | `scanner_screen.dart`, método `_phaseFor` |
| **Riesgo** | Ninguno |

### 1.4 · «Cámara no disponible»

| Aspecto | Detalle |
|---|---|
| **Síntoma** | Barra en color de error, con un motivo concreto debajo |
| **Causa** | Tres posibles, y el mensaje las distingue: falta el permiso (`permissionDenied`), el dispositivo no lo admite (`unsupported`), o cualquier otro fallo de arranque |
| **Diagnóstico** | Leer el mensaje. «Falta el permiso de cámara» es inequívoco |
| **Solución** | Conceder el permiso en los ajustes del sistema y pulsar **Reintentar**. Si dice que el dispositivo no lo permite, usar la importación desde galería |
| **Archivos** | `scanner_screen.dart`, método `_describe`; permisos en `tool/bootstrap.py` |
| **Riesgo** | Ninguno |

### 1.5 · Lee, pero no suena

| Aspecto | Detalle |
|---|---|
| **Síntoma** | El código se lee y aparece el resultado, pero no hay tono |
| **Causa** | Tres posibles: el ajuste **Sonido de confirmación** está apagado; el volumen multimedia está a cero; o el reproductor de audio falló y `ScanFeedback` degradó al sonido del sistema, que Android silencia si los sonidos táctiles están apagados |
| **Diagnóstico** | Revisar el ajuste y el volumen multimedia. La tercera causa no es observable desde la interfaz |
| **Solución** | Activar **Sonido** en Ajustes y subir el volumen multimedia |
| **Archivos** | `lib/services/scan_feedback.dart`; el recurso es `assets/sounds/scan_success.wav` |
| **Riesgo** | Ninguno |

El tono es un **recurso propio empaquetado**, no el efecto de sonido del sistema.
El motivo está en [`../quality/SCANNER_UX.md`](../quality/SCANNER_UX.md):
`SystemSound.play` se traduce al efecto de la interfaz, que Android silencia en
cuanto se apagan los sonidos táctiles, que es el ajuste habitual.

### 1.6 · «Inicio seguro» al abrir la aplicación

| Aspecto | Detalle |
|---|---|
| **Síntoma** | En vez de la aplicación aparece una tarjeta con «Inicio seguro», un diagnóstico y cuatro botones |
| **Causa** | `AppBootstrapper.initialize` lanzó. Puede ser la apertura de la base, la migración de esquema, la lectura de la llave activa o la inicialización de un store |
| **Diagnóstico** | El texto muestra `errorType` y una huella de pila. Copiar el diagnóstico privado da hasta 100 entradas con área y tipo, **sin ningún dato escaneado** |
| **Solución** | En orden: **Reintentar**; si falla, **Restablecer preferencias visuales** y reintentar; si sigue fallando, **Abrir sin historial ni inventarios persistentes** |
| **Archivos** | `lib/bootstrap.dart`, `lib/bootstrap_host.dart`, `lib/core/diagnostics/` |
| **Riesgo** | **Reintentar** y **modo temporal** no tocan datos. **Restablecer preferencias visuales** borra 14 de las 17 claves de configuración y **no se puede deshacer**; deja intactas `save_history`, `private_mode` y `biometric_lock` |

### 1.7 · Banner permanente de «Modo temporal»

| Aspecto | Detalle |
|---|---|
| **Síntoma** | Un aviso fijo sobre las pestañas: «el historial y los inventarios se eliminarán al cerrar la aplicación» |
| **Causa** | Se arrancó desde el inicio seguro con **Abrir sin historial ni inventarios persistentes**. La base es de memoria y la llave también |
| **Diagnóstico** | Ajustes muestra además «Modo temporal activo», y **Rotar llave de cifrado** aparece deshabilitado |
| **Solución** | Cerrar y volver a abrir la aplicación para intentar el arranque normal |
| **Archivos** | `bootstrap.dart` (rama `temporary`), `app.dart` (el banner) |
| **Riesgo** | **Todo lo escaneado o inventariado en modo temporal se pierde al cerrar.** Exportarlo antes si interesa conservarlo |

### 1.8 · Faltan registros en el historial

| Aspecto | Detalle |
|---|---|
| **Síntoma** | Se escanearon códigos y no aparecen en Historial |
| **Causa** | Cinco posibles: **Guardar historial** apagado; **Sesión privada** activa; el contenido era **sensible** (OTP, Wi-Fi con contraseña, pago, AAMVA, cripto); la **retención** los podó; o se superaron los 5 000 registros y se recortaron los más antiguos |
| **Diagnóstico** | Revisar los dos interruptores y el valor de retención en Ajustes. Un registro sensible se muestra al leerlo pero nunca se guarda |
| **Solución** | Ajustar las preferencias. Lo ya no guardado **no se puede recuperar**: nunca se escribió |
| **Archivos** | `scanner_screen.dart` (`_persistAndShow`), `history_repository.dart` (`pruneOlderThan`, `_trim`) |
| **Riesgo** | Ninguno al cambiar los ajustes; afectan solo a lecturas futuras |

El caso del contenido sensible es **deliberado y está documentado** en
`docs/SECURITY.md` y en la política de privacidad. El del inventario es
distinto: ahí sí se guarda. Ver el hallazgo R-03 de
[15-risks-and-technical-debt.md](15-risks-and-technical-debt.md).

### 1.9 · Aparecen elementos en el Centro de recuperación

| Aspecto | Detalle |
|---|---|
| **Síntoma** | Ajustes → Centro de recuperación muestra incidencias con un código como `decrypt_StateError` o `missing_payload` |
| **Causa** | Al cargar, un registro no se pudo descifrar o no tenía carga. La causa más frecuente es que **la llave ya no está** en el almacén seguro: reinstalación, restauración del sistema o cambio de dispositivo |
| **Diagnóstico** | El código lo dice. `decrypt_StateError` corresponde casi siempre a `encryption_key_missing`. `missing_payload` es un registro sin `payload`, más raro |
| **Solución** | **Reintentar recuperación** si aparece la opción; funciona si la llave volvió. Si no, **Descartar registro afectado** elimina solo ese registro. **Marcar revisado** lo oculta sin borrar nada |
| **Archivos** | `lib/core/recovery/`, `lib/services/history_repository.dart`, `lib/services/inventory_repository.dart` |
| **Riesgo** | **Descartar borra ese registro de forma definitiva.** Marcar revisado no borra nada, pero si el problema se repite la incidencia **vuelve a aparecer**: su identificador es determinista |

Los registros dañados **nunca se borran automáticamente**, y una llave ausente
**nunca se reemplaza en silencio**: el descifrado informa y **bloquea nuevas
escrituras** con ese identificador hasta que la persona recupere, rote o
descarte. Es la propiedad descrita en
[`../quality/RECOVERY.md`](../quality/RECOVERY.md).

### 1.10 · Ajustes ofrece «Reintentar migración del historial»

| Aspecto | Detalle |
|---|---|
| **Síntoma** | Una fila extra en Ajustes con un código como `legacy_FormatException` |
| **Causa** | La conversión del historial guardado en preferencias a la base cifrada falló |
| **Diagnóstico** | El subtítulo muestra el código. La fila solo aparece si `migrationStatus.completed == false` |
| **Solución** | Pulsarla. El mensaje dirá si se completó o si sigue pendiente |
| **Archivos** | `history_repository.dart`, método `_migrateLegacyHistory` |
| **Riesgo** | **Ninguno.** El origen se conserva intacto y hay un respaldo cifrado. La conversión no se marca completada hasta que se verifica dentro de la transacción |

### 1.11 · La rotación de llave falló

| Aspecto | Detalle |
|---|---|
| **Síntoma** | «No se modificaron los datos porque la rotación no pudo completarse» |
| **Causa** | Un registro sin `payload`, un fallo de descifrado con la llave actual, o un error de la transacción |
| **Diagnóstico** | El mensaje es genérico a propósito. Revisar el Centro de recuperación por si aparecieron incidencias |
| **Solución** | Resolver primero las incidencias del Centro de recuperación y volver a intentarlo |
| **Archivos** | `lib/core/security/data_maintenance_service.dart` |
| **Riesgo** | **Ninguno.** Es una operación todo o nada: registros y metadato se escriben en una única transacción, y la llave nueva se borra del almacén seguro si algo falla. Hay prueba dedicada |

### 1.12 · «No existe una aplicación compatible para esta acción»

| Aspecto | Detalle |
|---|---|
| **Síntoma** | Al pulsar «Abrir», «Llamar», «Correo», «SMS» o «Mapa» aparece ese aviso |
| **Causa** | `launchUrl` devolvió `false`: el sistema no encontró ninguna aplicación que atienda ese esquema |
| **Diagnóstico** | Frecuente en emuladores y en macOS sin cliente de correo configurado |
| **Solución** | Instalar o configurar una aplicación para ese esquema. Alternativa: **Copiar** y pegarlo donde haga falta |
| **Archivos** | `scan_result_sheet.dart`, método `_openRecord` |
| **Riesgo** | Ninguno |

### 1.13 · El contenido copiado desapareció del portapapeles

| Aspecto | Detalle |
|---|---|
| **Síntoma** | Se copió algo y al pegarlo más tarde no está |
| **Causa** | Es el comportamiento previsto. **Borrar portapapeles** vale 30 segundos por defecto |
| **Diagnóstico** | El mensaje al copiar lo dice: «se borrará en N segundos» |
| **Solución** | Ajustes → **Borrar portapapeles** → `Nunca`, o un valor mayor |
| **Archivos** | `lib/services/clipboard_service.dart` |
| **Riesgo** | Poner `Nunca` deja información posiblemente sensible en el portapapeles indefinidamente |

El borrado **comprueba antes** que el portapapeles siga conteniendo el mismo
valor: si se copió otra cosa entre medias, no se borra nada.

### 1.14 · El QR generado no se lee al escanearlo

| Aspecto | Detalle |
|---|---|
| **Síntoma** | Se genera un código y otro lector no lo interpreta |
| **Causa** | El contenido no es válido para el formato elegido —letras en un EAN-13, longitud incorrecta en un UPC-A— o la corrección de errores es insuficiente |
| **Diagnóstico** | Si el contenido es inválido, la vista previa muestra «El contenido no es válido para \<formato\>» con el error concreto |
| **Solución** | Elegir un formato compatible (QR o Code 128 admiten casi cualquier texto) y activar **Corrección de errores alta** |
| **Archivos** | `lib/features/generator/generator_screen.dart` |
| **Riesgo** | Ninguno: el generador no persiste nada |

### 1.15 · El Excel exportado muestra los acentos rotos

| Aspecto | Detalle |
|---|---|
| **Síntoma** | Un CSV abierto en Excel muestra caracteres extraños en lugar de acentos |
| **Causa** | **No debería ocurrir**: `_encodeCsv` antepone el BOM UTF-8. Si ocurre, la aplicación que abre el archivo lo está ignorando |
| **Diagnóstico** | Abrir el CSV en un editor de texto: si los acentos se ven bien, el archivo es correcto |
| **Solución** | Usar la exportación **XLSX** en lugar de CSV, o importar el CSV indicando UTF-8 explícitamente |
| **Archivos** | `lib/services/export_service.dart`, función `_encodeCsv` |
| **Riesgo** | Ninguno |

El XLSX escribe **todas las celdas como texto** (`TextCellValue`), así que las
cantidades aparecerán como texto, no como números.

---

## 2 · Problemas de desarrollo

### 2.1 · `flutter run` no encuentra nada que ejecutar

| Aspecto | Detalle |
|---|---|
| **Síntoma** | Tras clonar, `flutter run` falla o no ofrece dispositivos |
| **Causa** | `android/`, `ios/`, `web/` y `macos/` **no están versionados** |
| **Diagnóstico** | `cat .gitignore` muestra las cuatro rutas bajo el comentario «Se generan con tool/bootstrap.py» |
| **Solución** | `python tool/bootstrap.py --platforms android,web` |
| **Archivos** | `.gitignore`, `tool/bootstrap.py` |
| **Riesgo** | Ninguno sin `--force`. **Con `--force` se borran y regeneran** las carpetas, perdiendo cualquier cambio manual hecho en ellas |

### 2.2 · `cannot find symbol: class FilePickerPlugin`

| Aspecto | Detalle |
|---|---|
| **Síntoma** | `flutter build apk` falla con ese error de Java |
| **Causa** | Se está usando AGP 9. Varios plugins —`file_picker` entre ellos— dejan de aplicar el Kotlin Gradle Plugin al detectar AGP 9, dando por hecho que el Kotlin integrado está activo; pero la plantilla entrega `android.builtInKotlin=false`, así que nadie compila su Kotlin |
| **Diagnóstico** | Comprobar la versión en `android/settings.gradle.kts`; debe ser `8.11.1` |
| **Solución** | Volver a ejecutar `python tool/bootstrap.py`, que reescribe AGP a `8.11.1`, Kotlin a `2.2.20` y Gradle a `8.14.3` |
| **Archivos** | `tool/bootstrap.py`, función `patch_android_toolchain` |
| **Riesgo** | Ninguno. Activar el Kotlin integrado en su lugar **rompe el caso contrario**, en los plugins que sí aplican el plugin de Kotlin |

### 2.3 · `pub get` falla al resolver

| Aspecto | Detalle |
|---|---|
| **Síntoma** | Conflicto de versiones, casi siempre alrededor de `win32` o `archive` |
| **Causa** | Se subió `share_plus`, `pdfrx` o `excel` por encima de su tope. `share_plus >= 13` exige `win32 ^6`, incompatible con el `^5.9` de `file_picker 11.x`; `pdfrx >= 2.4.6` arrastra `archive ^4`, incompatible con el `^3.6.1` de `excel 4.0.6` |
| **Diagnóstico** | `git diff pubspec.yaml` |
| **Solución** | Revertir esas versiones a `12.0.2`, `2.4.5` y `4.0.6` |
| **Archivos** | `pubspec.yaml`, `.github/dependabot.yml`, [`../quality/LOCKFILE.md`](../quality/LOCKFILE.md) |
| **Riesgo** | Ninguno al revertir |

### 2.4 · `ModuleNotFoundError: No module named 'yaml'`

| Aspecto | Detalle |
|---|---|
| **Síntoma** | `validate_structure.py` o `generate_sbom.py` fallan al importar |
| **Causa** | Falta `pyyaml` |
| **Diagnóstico** | `python -c "import yaml"` |
| **Solución** | `python -m pip install --upgrade pyyaml` |
| **Archivos** | `tool/validate_structure.py` línea 11, `tool/generate_sbom.py` |
| **Riesgo** | Ninguno. `tool/bootstrap.py` **no** necesita `yaml` |

### 2.5 · `La versión mostrada en la interfaz no coincide con pubspec.yaml`

| Aspecto | Detalle |
|---|---|
| **Síntoma** | `validate_structure.py` falla con ese mensaje |
| **Causa** | Se cambió `version` en `pubspec.yaml` sin cambiar `appVersion` en `lib/core/app_info.dart`, o al revés |
| **Diagnóstico** | El mensaje muestra ambos valores |
| **Solución** | Igualar `appVersion` a la parte `X.Y.Z` de `version` |
| **Archivos** | `lib/core/app_info.dart`, `pubspec.yaml` |
| **Riesgo** | Ninguno. Este gate existe porque la aplicación llegó a mostrar `1.0.0` siendo `1.1.0` |

### 2.6 · `Ruta absoluta del entorno encontrada en …`

| Aspecto | Detalle |
|---|---|
| **Síntoma** | `validate_structure.py` falla señalando un archivo |
| **Causa** | Ese archivo contiene una de las tres rutas de entorno que prohíbe la variable `bad` de `check_absolute_paths`: dos directorios de trabajo de entornos remotos y el prefijo del directorio de perfiles de Windows. Suele ser una traza pegada desde una máquina concreta |
| **Diagnóstico** | El mensaje da la ruta del archivo |
| **Solución** | Sustituir la ruta absoluta por una relativa o por un marcador genérico |
| **Archivos** | `tool/validate_structure.py`, función `check_absolute_paths` |
| **Riesgo** | Ninguno |

Afecta también a **esta documentación**: no se pueden citar rutas absolutas de la
máquina de análisis.

### 2.7 · `Enlace Markdown local inexistente en …`

| Aspecto | Detalle |
|---|---|
| **Síntoma** | `validate_structure.py` falla señalando un `.md` y un destino |
| **Causa** | Un enlace relativo apunta a un archivo que no existe |
| **Diagnóstico** | El mensaje da el archivo y el destino exactos |
| **Solución** | Corregir el enlace |
| **Archivos** | `tool/validate_structure.py`, función `check_markdown_links` |
| **Riesgo** | Ninguno |

Este gate valida **toda** la documentación del repositorio, incluida la de
`docs/system-documentation/`. Es el verificador de enlaces del proyecto.

### 2.8 · Una prueba de widget se cuelga

| Aspecto | Detalle |
|---|---|
| **Síntoma** | `flutter test` no termina, o tarda minutos en un solo caso |
| **Causa** | Dos posibles: `pumpAndSettle` sobre una animación infinita —la barra indeterminada nunca para—, o abrir la base de datos dentro del reloj falso de `testWidgets`, que usa temporizadores reales |
| **Diagnóstico** | Comentar el caso sospechoso y volver a ejecutar |
| **Solución** | Usar `await tester.pump()` en lugar de `pumpAndSettle`, y envolver el trabajo con temporizadores reales en `tester.runAsync(...)` |
| **Archivos** | `test/features/scan_status_bar_test.dart` y `test/core/accessibility_test.dart` traen el patrón correcto comentado |
| **Riesgo** | Ninguno |

Ambos casos son defectos reales ya corregidos, registrados en
[`../../VALIDATION.md`](../../VALIDATION.md).

### 2.9 · La CI falla en un paso que pasa en local

| Aspecto | Detalle |
|---|---|
| **Síntoma** | `flutter analyze` en verde localmente, `analyze` en rojo en la CI |
| **Causa** | `tool/run_quality_gate.sh` ejecuta `flutter analyze` **sin** `--fatal-infos`; la CI lo ejecuta **con** |
| **Diagnóstico** | Ejecutar `flutter analyze --fatal-infos` en local |
| **Solución** | Corregir también los avisos informativos |
| **Archivos** | `tool/run_quality_gate.sh`, `.github/workflows/flutter-ci.yml` |
| **Riesgo** | Ninguno |

Registrado como R-06.

---

## 3 · Problemas de publicación

### 3.1 · La landing publicada no se actualiza

| Aspecto | Detalle |
|---|---|
| **Síntoma** | Se hizo push a `main` y GitHub Pages sigue igual |
| **Causa** | `deploy-landing.yml` solo se dispara si el push toca `landing/**`, `lib/**`, `web/**`, `assets/**`, `docs/images/**`, `pubspec.yaml`, `pubspec.lock`, `tool/bootstrap.py` o el propio workflow. Un cambio en `docs/system-documentation/` o en `README.md` **no lo dispara** |
| **Diagnóstico** | Comparar los archivos del commit con la lista `paths:` |
| **Solución** | Lanzarlo a mano con `workflow_dispatch` desde la pestaña Actions |
| **Archivos** | `.github/workflows/deploy-landing.yml` |
| **Riesgo** | Ninguno. La concurrencia usa el grupo `pages` sin cancelar en curso |

### 3.2 · Las capturas de la landing salen rotas en local

| Aspecto | Detalle |
|---|---|
| **Síntoma** | Al abrir `landing/index.html` desde el disco, las imágenes y `/app/` no cargan |
| **Causa** | Es el comportamiento previsto. Las imágenes **no se duplican** en `landing/`: se copian al artefacto durante la publicación |
| **Diagnóstico** | `ls landing/assets/` muestra solo `favicon.svg` y `style.css` |
| **Solución** | Reproducir el montaje. El guion exacto está en [`../../landing/README.md`](../../landing/README.md) |
| **Archivos** | `landing/`, `.github/workflows/deploy-landing.yml` |
| **Riesgo** | Ninguno |

### 3.3 · El SHA-256 del APK descargado no coincide

| Aspecto | Detalle |
|---|---|
| **Síntoma** | El hash del archivo descargado difiere del de `checksums.txt` |
| **Causa** | Descarga incompleta o corrupta. **O un artefacto que no es el publicado** |
| **Diagnóstico** | `python tool/generate_checksums.py <archivo>` y comparar |
| **Solución** | Volver a descargar. Si vuelve a no coincidir, **no instalar** y reportarlo |
| **Archivos** | `tool/generate_checksums.py` |
| **Riesgo** | Instalar un artefacto cuyo hash no coincide es exactamente lo que la publicación de checksums existe para evitar |

### 3.4 · Android no deja instalar el APK

| Aspecto | Detalle |
|---|---|
| **Síntoma** | «Aplicación no instalada» o un aviso de origen desconocido |
| **Causa** | Dos posibles: falta permitir la instalación desde esa fuente, o **ya hay instalada una versión firmada con otra clave** |
| **Diagnóstico** | El mensaje de conflicto de firma es explícito |
| **Solución** | Permitir la instalación desde esa fuente. Si es conflicto de firma, **desinstalar la versión anterior** |
| **Archivos** | Declarado en `README.md` y en `docs/RELEASE.md` |
| **Riesgo** | **Desinstalar borra el historial y los inventarios de forma definitiva.** Están cifrados con una llave que también se borra, y no hay copia remota porque no hay servidor. **Exportar antes** |

### 3.5 · `SOURCE_MANIFEST.json` no cuadra tras clonar en Windows

| Aspecto | Detalle |
|---|---|
| **Síntoma** | Los SHA-256 de archivos de texto no coinciden con los del manifiesto |
| **Causa** | Finales de línea. El manifiesto se calcula sobre bytes, y CRLF produce otro hash |
| **Diagnóstico** | Comprobar que `.gitattributes` está presente y que Git lo respetó al clonar |
| **Solución** | Volver a clonar con `.gitattributes` en vigor. Es lo que `* text=auto eol=lf` garantiza |
| **Archivos** | `.gitattributes`, `tool/generate_source_manifest.py` |
| **Riesgo** | Ninguno. El comentario que encabeza `.gitattributes` explica exactamente este motivo |

Cualquier archivo de texto nuevo **debe escribirse con LF**.

### 3.6 · Los PDF de la documentación salen sin diagramas

| Aspecto | Detalle |
|---|---|
| **Síntoma** | El script avisa de que `mmdc` no está instalado y los diagramas aparecen como bloques de texto |
| **Causa** | Falta `@mermaid-js/mermaid-cli`. Ningún motor de PDF de Python ejecuta JavaScript, así que por sí solos no renderizan Mermaid |
| **Diagnóstico** | La salida del script informa cuántos diagramas se renderizaron y cuántos degradaron |
| **Solución** | `npm install -g @mermaid-js/mermaid-cli` y volver a ejecutar |
| **Archivos** | `tool/build_system_documentation_pdf.py` |
| **Riesgo** | Ninguno. La degradación es deliberada: un PDF con un diagrama en texto es mejor que ningún PDF |

En Windows, `mmdc` es un `.cmd` y Node ≥ 20.12 se niega a lanzarlo sin shell por
el endurecimiento de CVE-2024-27980; el script lo contempla.

---

## 4 · Índice rápido por síntoma

| Lo que ves | Entrada |
|---|---|
| «Escaneando» y no lee | 1.1, 1.2 |
| «Iniciando cámara…» eterno | 1.3 |
| «Cámara no disponible» | 1.4 |
| Lee pero no suena | 1.5 |
| «Inicio seguro» | 1.6 |
| Banner de modo temporal | 1.7 |
| Faltan registros | 1.8 |
| Elementos en el Centro de recuperación | 1.9 |
| «Reintentar migración» en Ajustes | 1.10 |
| La rotación de llave falló | 1.11 |
| «No existe una aplicación compatible» | 1.12 |
| Se borró el portapapeles | 1.13 |
| El QR generado no se lee | 1.14 |
| Acentos rotos en el CSV | 1.15 |
| `flutter run` no encuentra nada | 2.1 |
| `FilePickerPlugin` no encontrado | 2.2 |
| `pub get` no resuelve | 2.3 |
| Falta `yaml` | 2.4 |
| Versión de interfaz distinta | 2.5 |
| Ruta absoluta detectada | 2.6 |
| Enlace Markdown roto | 2.7 |
| Prueba de widget colgada | 2.8 |
| CI roja y local verde | 2.9 |
| La landing no se actualiza | 3.1 |
| Capturas rotas en local | 3.2 |
| SHA-256 que no coincide | 3.3 |
| Android no instala | 3.4 |
| Manifiesto de fuente descuadrado | 3.5 |
| PDF sin diagramas | 3.6 |

---

Continúa en [15 · Riesgos y deuda técnica](15-risks-and-technical-debt.md).
