# Modelo de amenazas

## Activos

Historial, inventarios, contraseñas Wi-Fi, semillas OTP, información de pagos, identificaciones, llave local y archivos exportados.

## Límites de confianza

- cámara y galería;
- archivos JSON/PDF/imágenes importados;
- almacén seguro del sistema;
- base Sembast/IndexedDB;
- aplicaciones externas abiertas mediante URI;
- portapapeles;
- archivos compartidos.

## Amenazas y controles

| Amenaza | Control |
|---|---|
| QR dirige a phishing o ejecutable | análisis local, dominio visible, confirmación y bloqueo de esquemas |
| Archivo importado modifica datos | límite de tamaño, esquema versionado, vista previa y estrategia explícita |
| Pérdida de llave | incidencias de recuperación, respaldo cifrado, no recrear la llave durante descifrado y no borrar registros automáticamente |
| Manipulación de la base | AES-GCM autentica cada carga y los errores se aíslan |
| Exposición en logs | diagnóstico acepta solo tipo, área y huella de stack |
| Exposición por portapapeles | borrado programado y confirmación para datos sensibles |
| Regresión por dependencia | versiones fijadas, lockfile, CI, SBOM, inventario de licencias y actualizaciones individuales |
| Denegación de servicio por PDF/imagen | límites, progreso, cancelación, escalado y limpieza temporal |
| Migración destructiva | respaldo previo, transacción, verificación e idempotencia |

## Fuera de alcance

La aplicación no sustituye antivirus, reputación en línea, validación bancaria ni autenticidad de documentos oficiales. No se promete interpretar formatos privados o cifrados sin especificación.
