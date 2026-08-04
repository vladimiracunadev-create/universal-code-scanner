# Estado de implementación · 1.0.0

## Presente en el código fuente y verificado

- Escáner de cámara con marco, zoom, enfoque por toque, linterna, cambio de
  cámara y lectura de varios códigos simultáneos.
- Lotes de hasta 20 imágenes y 50 páginas de PDF, con progreso y cancelación.
- Interpretación de URL, texto, binario, Wi-Fi, vCard, MeCard, vEvent, correo,
  teléfono, SMS, geo, OTP, GS1, ISBN, producto, EMVCo, EPC/SEPA, Swiss QR,
  criptomonedas y AAMVA.
- Analizador de riesgo con 16 señales locales y bloqueo de esquemas no
  permitidos.
- Historial e inventarios cifrados con AES-256-GCM; llave en el almacén seguro
  del sistema operativo.
- Rotación de llave transaccional con limpieza de llave huérfana ante fallo.
- Inicio seguro con reintento, diagnóstico privado y modo temporal en memoria.
- Centro de recuperación con reintento, descarte individual y paquete exportable
  sin llaves.
- Esquema interno idempotente y sobres de cifrado versionados.
- Importación validada por completo antes de aplicarse, con vista previa,
  duplicados y estrategias explícitas.
- Generador PNG/SVG de diez simbologías y exportación JSON, CSV, XLSX, VCF e ICS.
- Fronteras de extensión: `ScannerEngine`, `ContentParserRegistry` y
  `FeatureFlags` (todas las capacidades futuras apagadas).
- Accesibilidad: alto contraste, controles grandes y reducción de movimiento.
- 42 pruebas unitarias, de widget y de integración, más catálogo de regresión.
- CI para Android, web, iOS y macOS; SBOM, inventario de licencias, checksums,
  Dependabot y documentación de seguridad.

## Parcial y declarado como tal

- **Localización.** La infraestructura `es_CL`/`es`/`en` existe y la navegación
  principal usa claves localizadas. El resto de la interfaz está escrito en
  español y se migrará pantalla por pantalla.
- **Catálogo de regresión.** Ocho imágenes reproducibles, todas QR. Las demás
  simbologías requieren capturas reales verificadas antes de incorporarse.

## Requiere dispositivos reales

- Cámara, enfoque, poca luz, códigos curvos o dañados y varios modelos.
- Biometría, Keychain/Keystore, reinstalación y regreso desde segundo plano.
- PDF grandes y medición de memoria.
- TalkBack, VoiceOver y navegación por teclado.
- Compatibilidad de XLSX con Excel, LibreOffice y Google Sheets.

## Fuera del alcance de 1.0.0

- Firma de artefactos, cuentas de desarrollador, fichas, capturas comerciales,
  AAB/IPA y despliegue en tiendas.
- Motor nativo para Windows y Linux: ambos se cubren mediante la PWA.
- OCR, NFC, reputación remota de URLs, consulta de productos, sincronización
  cifrada, API empresarial y modo kiosco.
