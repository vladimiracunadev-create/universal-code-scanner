# Estado de validación

**Versión:** 1.0.0+1
**Fecha:** 3 de agosto de 2026
**Toolchain:** Flutter 3.44.7 · Dart 3.12.2 (canal estable)

## Ejecutado sobre esta misma versión del código

| Comprobación | Comando | Resultado |
|---|---|---|
| Resolución de dependencias | `flutter pub get` | Correcta · `pubspec.lock` generado y versionado |
| Análisis estático estricto | `flutter analyze --fatal-infos` | **0 hallazgos** |
| Suite de pruebas | `flutter test` | **42 de 42 en verde** |
| Generación de plataformas | `python3 tool/bootstrap.py --platforms android,web` | Correcta · permisos, `minSdk 24`, `FlutterFragmentActivity` y etiqueta aplicados |
| Compilación web | `flutter build web --release` | Compila |
| Validación estructural | `python3 tool/validate_structure.py` | Sin errores |

## Defectos corregidos durante esta validación

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

## No ejecutado en este entorno

| Pendiente | Motivo | Dónde se cubre |
|---|---|---|
| `flutter build apk` · `appbundle` | Sin Android SDK instalado | Trabajo `quality` de la CI |
| `flutter build ios` · `macos` | Requiere macOS | Trabajo `apple` de la CI |
| Prueba de integración de arranque | Requiere dispositivo o escritorio destino | Trabajo `apple` de la CI |
| Cámara, biometría, PDF grandes, TalkBack y VoiceOver | Requieren hardware real | [`docs/quality/DEVICE_TEST_MATRIX.md`](docs/quality/DEVICE_TEST_MATRIX.md) |
| Compatibilidad XLSX con Excel, LibreOffice y Google Sheets | Requiere las aplicaciones destino | Matriz de dispositivos |

Las comprobaciones ejecutadas demuestran que el proyecto **resuelve, analiza,
prueba y compila**. No sustituyen la validación en dispositivos físicos, que
sigue declarada como pendiente en [`IMPLEMENTATION_STATUS.md`](IMPLEMENTATION_STATUS.md).
