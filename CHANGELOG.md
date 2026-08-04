# Changelog

Todas las versiones notables de este proyecto se documentan en este archivo.
El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y
el proyecto usa [Versionado Semántico](https://semver.org/lang/es/).

## [1.0.0] — 2026-08-03

Primera versión pública. Todo lo que se describe a continuación está presente en
el código fuente y verificado con Flutter 3.44.7 (`analyze --fatal-infos` sin
hallazgos y 45 pruebas en verde).

### Lectura

- Escáner de cámara con marco real, cámara frontal/trasera, zoom, enfoque por
  toque, linterna y lectura de varios códigos en una misma imagen.
- Importación de hasta 20 imágenes y 50 páginas de PDF, con barra de progreso y
  cancelación en cualquier punto del lote.
- Simbologías solicitadas al motor: QR, Micro QR, Data Matrix, Aztec, PDF417,
  MaxiCode, Code 128/39/93, Codabar, EAN-13/8, UPC-A/E, ITF y GS1 DataBar.

### Interpretación

- Wi-Fi, vCard, MeCard, vEvent, correo, teléfono, SMS, geolocalización y OTP.
- Identificadores GS1, ISBN y códigos de producto.
- Pagos EMVCo, EPC/SEPA, Swiss QR Bill y direcciones de criptomonedas.
- Documentos AAMVA reconocibles y cargas binarias en Base64.
- `ContentParserRegistry` permite añadir parsers sin tocar el integrado.

### Seguridad y privacidad

- Análisis preventivo de URLs con 16 señales locales: HTTP sin TLS, dominio
  ausente, credenciales embebidas, Punycode, mezcla de alfabetos, caracteres
  internacionales, IP literal, red privada o loopback, acortadores conocidos,
  exceso de subdominios, puertos inusuales, longitud anómala, caracteres de
  control, descargas ejecutables, rutas que aparentan inicio de sesión y exceso
  de parámetros de seguimiento. Los esquemas de aplicación no permitidos se
  bloquean.
- Ninguna acción externa se ejecuta sin confirmación explícita.
- Historial e inventarios cifrados con AES-256-GCM antes de escribirse en disco.
- Llave en el almacén seguro del sistema operativo; una llave ausente nunca se
  regenera de forma silenciosa.
- Rotación de llave dentro de una única transacción, con limpieza de la llave
  huérfana si la operación falla.
- Bloqueo biométrico, modo temporal en memoria y borrado programado del
  portapapeles.
- OTP y redes Wi-Fi con contraseña quedan fuera del historial automático.

### Datos y recuperación

- Inicio seguro con reintento, diagnóstico privado sin cargas escaneadas y modo
  temporal cuando la base persistente no puede abrirse.
- Centro de recuperación: reintento de descifrado, descarte individual, marca de
  revisión y paquete exportable que nunca incluye llaves.
- Esquema interno versionado e idempotente, aplicado dentro de una transacción.
- Sobres de cifrado versionados que siguen aceptando el formato anterior.
- Importación validada por completo antes de aplicarse, con vista previa,
  detección de duplicados y estrategias combinar/omitir/reemplazar.

### Inventario, generación y exportación

- Sesiones de inventario con conteo, notas y cola serial de escritura.
- Generador PNG y SVG de QR, Data Matrix, Aztec, PDF417, Code 128, Code 39,
  EAN-13, EAN-8, UPC-A y GS1-128.
- Exportación a JSON, CSV, XLSX, VCF e ICS, con la codificación pesada fuera del
  hilo de interfaz mediante `compute`.

### Accesibilidad e idiomas

- Alto contraste, controles táctiles grandes y reducción de movimiento.
- Interfaz íntegramente en español: idioma del sistema, español de Chile y
  español internacional. La infraestructura admite inglés y sus claves ya
  existen, pero el idioma no se expone hasta que todas las pantallas lean sus
  cadenas de `AppLocalizations`, para no entregar una interfaz a medio traducir.

### Calidad

- 45 pruebas unitarias, de widget y de integración.
- Catálogo de regresión con 8 imágenes y manifiesto de resultados esperados.
- Validador estructural offline, SBOM CycloneDX, inventario de licencias,
  checksums, Dependabot, modelo de amenazas y lista MASVS.
- CI para Android, web, iOS y macOS sobre Flutter 3.44.7.

### Fuera del alcance de 1.0.0

- Firma de artefactos y publicación en Google Play o App Store.
- Windows y Linux nativos: se cubren mediante la PWA.
- OCR, NFC, reputación remota de URLs, consulta de productos, sincronización y
  funciones empresariales permanecen apagadas en `FeatureFlags`.

[1.0.0]: https://github.com/vladimiracunadev-create/universal-code-scanner/releases/tag/v1.0.0
