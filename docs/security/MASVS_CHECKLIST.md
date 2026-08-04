# Matriz OWASP MASVS del proyecto

Esta matriz es una guía de verificación del código fuente; no constituye una certificación externa.

| Área | Controles incorporados | Evidencia |
|---|---|---|
| STORAGE | Historial e inventario cifrados, secretos OTP/Wi-Fi excluidos por defecto, modo privado, diagnóstico sin cargas | `PayloadCipher`, repositorios, pruebas de diagnóstico |
| CRYPTO | AES-256-GCM autenticado, sobres versionados, llave por identificador, rotación transaccional, rechazo de manipulación | `payload_cipher_test.dart`, `data_maintenance_test.dart` |
| AUTH | Bloqueo local, reautenticación al pasar a segundo plano/inactivo, modo temporal de recuperación | `BiometricLockGate`, matriz de dispositivos |
| NETWORK | El reconocimiento local no requiere red; URLs se muestran y evalúan antes de abrir | `ScanSecurityAnalyzer`, pruebas de enlaces |
| PLATFORM | Permisos mínimos, cámara liberada por ciclo de vida, copia de seguridad Android desactivada | `tool/bootstrap.py`, `ScannerScreen` |
| CODE | CI, análisis estático, pruebas, dependencias fijadas, SBOM, inventario de licencias, hashes y feature flags | `.github/workflows`, `tool/`, `SOURCE_MANIFEST.json` |
| RESILIENCE | Inicio seguro, registros dañados aislados, importaciones limitadas y atómicas, cancelación de lotes | `BootstrapHost`, recuperación, importación y rendimiento |
| PRIVACY | Sin publicidad ni analítica, portapapeles temporal, confirmación para datos sensibles | configuración y servicios de privacidad |

## Validación pendiente en dispositivos

- comprobar almacenamiento con herramientas de inspección de Android/iOS;
- probar biometría cancelada, bloqueada y sin enrolamiento;
- revisar capturas del selector de aplicaciones;
- ejecutar manipulación de base y archivos reales;
- revisar dependencias y licencias resueltas después de `flutter pub get`;
- realizar una revisión independiente antes de distribuir públicamente.
