# Estado de validación

**Versión:** 1.1.0+2
**Fecha:** 12 de agosto de 2026
**Toolchain:** Flutter 3.44.7 · Dart 3.12.2 (canal estable)

## Ejecutado sobre esta misma versión del código

| Comprobación | Comando | Resultado |
|---|---|---|
| Resolución de dependencias | `flutter pub get` | Correcta · `pubspec.lock` generado y versionado |
| Análisis estático estricto | `flutter analyze --fatal-infos` | **0 hallazgos** |
| Suite de pruebas | `flutter test` | **57 de 57 en verde** |
| Generación de plataformas | `python3 tool/bootstrap.py --platforms android,web` | Correcta · permisos, `minSdk 24`, `FlutterFragmentActivity`, etiqueta y cadena Gradle aplicados |
| Compilación web | `flutter build web --release` | Compila |
| Compilación Android | `flutter build apk --debug` | Compila con la dependencia de audio añadida |
| Validación estructural | `python3 tool/validate_structure.py --require-lock` | Sin errores |

Medido en 1.0.0 y no repetido en 1.1.0: el APK release pesó 87,7 MB y arrancó en
el emulador de Android API 36 con la cámara transmitiendo y las cinco pestañas
respondiendo.

Además, la CI de GitHub completa ambos trabajos en verde: análisis, pruebas,
SBOM, compilación web, **APK de Android**, iOS sin firma y macOS.

## Defectos corregidos en 1.1.0

Reportados al probar el APK de 1.0.0 en un teléfono real. Detalle completo, con
la causa técnica de cada uno, en
[`docs/quality/SCANNER_UX.md`](docs/quality/SCANNER_UX.md).

1. **La cámara no leía al abrir la pestaña; sí al salir y volver.** La ventana de
   lectura se expresa en porcentajes de 0 a 1 y el umbral de actualización estaba
   fijado en 4, así que nunca se recalculaba. Si el primer cálculo salía mal
   —porque el tamaño de la cámara y la orientación del dispositivo pueden llegar
   después del primer cuadro—, todos los códigos quedaban fuera de la región
   analizada. Eliminado el umbral.
2. **Volver del segundo plano dejaba la vista previa congelada.**
   `MobileScanner` solo atiende el ciclo de vida cuando él crea el controlador, y
   estas pantallas le pasan el suyo. `ScannerScreen` e `InventoryScreen` ahora lo
   observan y reinician la cámara al volver.
3. **Los errores de arranque no llegaban a la interfaz.** `start()` lanza
   excepción con el controlador desechado, ya iniciándose o sin permiso, y nadie
   la capturaba: el usuario veía una pantalla idéntica a la de una cámara
   funcionando. Ahora cada estado se nombra y ofrece «Reintentar».
4. **No había señal de que estuviera escaneando.** Un texto fijo era la única
   indicación. Añadida una barra de estado que solo se mueve mientras el motor
   analiza cuadros, más la línea que recorre el marco.
5. **El pitido de lectura no sonaba.** `SystemSound.play` se traduce al efecto de
   sonido de la interfaz, que Android silencia cuando el usuario apaga los
   sonidos táctiles. Sustituido por un tono propio empaquetado y reproducido con
   `audioplayers`.

## Defectos corregidos en la validación de 1.0.0

La versión previa de la fuente **no resolvía dependencias ni compilaba**. Se
detectó y corrigió lo siguiente:

1. **Conflicto `share_plus` / `file_picker`.** `share_plus 13.x` exige
   `win32 ^6`, incompatible con el `win32 ^5.9` de `file_picker 11.x`. Fijado
   `share_plus 12.0.2`.
2. **Conflicto `pdfrx` / `excel`.** `pdfrx ≥ 2.4.6` arrastra `archive ^4`,
   incompatible con el `archive ^3.6.1` de `excel 4.0.6`. Fijado `pdfrx 2.4.5`.
3. **API inexistente de `file_picker`.** El código llamaba
   `FilePicker.platform.pickFiles()`, eliminado en la versión 11 en favor del
   método estático `FilePicker.pickFiles()`. Corregido en `import_service.dart`
   y `pdf_page_renderer_io.dart`.
4. **`switch` con rama inalcanzable** en `ScanRecord._decodedBytes`, reescrito
   como comprobaciones de tipo explícitas.
5. **22 avisos del analizador** que habrían hecho fallar el paso
   `flutter analyze --fatal-infos` declarado en la CI: importaciones
   redundantes, `BuildContext` a través de brechas asíncronas, parámetros con
   doble guion bajo y un miembro obsoleto.
6. **Pruebas que nunca podían pasar.** Cuatro casos construían
   `SharedPreferencesAsync` sin plataforma de pruebas registrada, y la prueba de
   accesibilidad se colgaba diez minutos porque abría la base de datos dentro
   del reloj falso de `testWidgets`; ahora usa `tester.runAsync`.
7. **Aserción imposible en el diagnóstico.** La prueba exigía que la exportación
   no contuviera la palabra `secret`, pero el propio aviso de privacidad la
   incluía. Reescrito el aviso.
8. **Versión de aplicación fija en el SBOM.** `tool/generate_sbom.py` la
   escribía a mano; ahora la lee de `pubspec.yaml`.
9. **Android no compilaba.** `flutter build apk` fallaba con
   `cannot find symbol: class FilePickerPlugin`. La plantilla de Flutter 3.44.7
   genera AGP 9 —cuyo valor por defecto es el Kotlin integrado— pero entrega
   `android.builtInKotlin=false`; varios plugins dejan de aplicar el Kotlin
   Gradle Plugin al detectar AGP 9, así que nadie compila su código Kotlin.
   `tool/bootstrap.py` fija ahora AGP 8.11.1, Kotlin 2.2.20 y Gradle 8.14.3.
10. **Interfaz a medio traducir.** En un dispositivo configurado en inglés la
    aplicación mostraba la navegación traducida sobre contenido en español,
    porque solo las nueve cadenas de navegación existen en `AppLocalizations`.
    Desde entonces la aplicación expone únicamente español; las claves en inglés
    se conservan para cuando todas las pantallas lean sus cadenas de esa clase.
11. **Validador estructural inservible tras `pub get`.** Recorría `.dart_tool`
    y fallaba al encontrar rutas absolutas del entorno. Ahora excluye los
    directorios generados, igual que el manifiesto de fuente.

## No ejecutado en este entorno

| Pendiente | Motivo | Dónde se cubre |
|---|---|---|
| `flutter build appbundle` y firma de publicación | Fuera del alcance de 1.1.0; los APK publicados usan la clave de depuración | [`docs/RELEASE.md`](docs/RELEASE.md) |
| Ejecución en iOS y macOS | Requiere hardware Apple | Solo se verifica la compilación, en la CI |
| Prueba de integración de arranque | Los runners de GitHub no tienen sesión gráfica | Ejecutar en local: `flutter test integration_test/app_launch_test.dart -d macos` |
| Cámara real, biometría, PDF grandes, TalkBack y VoiceOver | Requieren hardware físico | [`docs/quality/DEVICE_TEST_MATRIX.md`](docs/quality/DEVICE_TEST_MATRIX.md) |
| Compatibilidad XLSX con Excel, LibreOffice y Google Sheets | Requiere las aplicaciones destino | Matriz de dispositivos |

Las comprobaciones ejecutadas demuestran que el proyecto **resuelve, analiza,
prueba, compila y arranca**. No sustituyen la validación en dispositivos
físicos, que sigue declarada como pendiente en
[`IMPLEMENTATION_STATUS.md`](IMPLEMENTATION_STATUS.md): un emulador no reproduce
cámaras reales, sensores biométricos ni presión de memoria.
