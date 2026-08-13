# Changelog

Todas las versiones notables de este proyecto se documentan en este archivo.
El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y
el proyecto usa [Versionado Semántico](https://semver.org/lang/es/).

## [1.1.0] — 2026-08-12

Corrige el fallo de lectura reportado en un teléfono real y convierte el estado
del escáner en algo visible. Verificado con Flutter 3.44.7: `analyze
--fatal-infos` sin hallazgos y 57 pruebas en verde.

### Corregido

- **La cámara no leía al abrir la pestaña y sí al salir y volver.** La ventana de
  lectura se calculaba una sola vez y quedaba congelada por un umbral de
  actualización mal dimensionado: se expresa en porcentajes de 0 a 1 y el umbral
  era 4, de modo que jamás se recalculaba. Si el primer cálculo salía mal
  —porque el tamaño de la cámara o la orientación del dispositivo llegan después
  del primer cuadro—, todos los códigos quedaban fuera de la región analizada.
  Ahora la ventana se recalcula cuando esos datos cambian.
- **Volver del segundo plano dejaba la vista previa congelada.** `MobileScanner`
  solo atiende el ciclo de vida cuando él mismo crea el controlador; estas
  pantallas le pasan el suyo. `ScannerScreen` e `InventoryScreen` ahora observan
  el ciclo de vida y reinician la cámara al volver, incluido el regreso del
  diálogo de permiso del sistema.
- **Los errores de arranque de la cámara no llegaban a la interfaz.** Todo
  arranque, parada y reinicio pasa por rutas que capturan la excepción y la
  convierten en un estado visible con acción de recuperación.

### Añadido

- Barra de estado permanente en el escáner con los cuatro estados reales
  —iniciando, escaneando, en pausa y no disponible— y una **barra horizontal que
  solo se mueve mientras el motor analiza cuadros**.
- Línea de lectura que recorre el marco mientras se escanea. Con movimiento
  reducido activado, el marco y la barra se dibujan quietos.
- Botón explícito **«Escanear» / «Pausar»** con texto, botón **«Reiniciar
  cámara»** siempre disponible y **«Reintentar»** cuando la cámara no arranca.
  Tocar la vista previa en pausa reanuda la lectura.
- Mensaje específico cuando falta el permiso de cámara, con acción de reintento
  en la propia pantalla.
- Pausa y estado visible también en el inventario continuo.
- `docs/quality/SCANNER_UX.md`: comportamiento por estado, causas del fallo y
  comparación con las convenciones de otros lectores.

### Cambiado

- **Sonido de lectura conseguida.** La confirmación usaba el efecto de sonido de
  la interfaz del sistema, que Android silencia en cuanto el usuario apaga los
  sonidos táctiles: por eso no se oía nada. Ahora suena un tono propio
  empaquetado en la aplicación (`assets/sounds/scan_success.wav`, generado por
  `tool/generate_scan_beep.py`), reproducido con `audioplayers` en modo de baja
  latencia y mezclado con el audio existente para no interrumpir música ni
  llamadas. Si el reproductor falla, degrada al sonido del sistema.
- Nueva dependencia directa: `audioplayers` 6.8.1.
- 57 pruebas (9 nuevas sobre estado de escaneo, marco, sonido y vibración).

## [1.0.0] — 2026-08-03

Primera versión pública. Todo lo que se describe a continuación está presente en
el código fuente y verificado con Flutter 3.44.7 (`analyze --fatal-infos` sin
hallazgos y 48 pruebas en verde).

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

### Identidad y adaptación de pantalla

- Icono propio de la aplicación: el marco de lectura del escáner con un patrón
  de localización QR al centro. Se dibuja por código desde
  `tool/generate_launcher_icons.py` y se aplica a los iconos heredados,
  adaptativos y monocromos de Android, además de los iconos y el favicon de la
  PWA.
- En pantallas anchas la interfaz se centra con un ancho máximo de teléfono en
  lugar de estirarse de borde a borde.

### Accesibilidad e idiomas

- Alto contraste, controles táctiles grandes y reducción de movimiento.
- Interfaz íntegramente en español: idioma del sistema, español de Chile y
  español internacional. La infraestructura admite inglés y sus claves ya
  existen, pero el idioma no se expone hasta que todas las pantallas lean sus
  cadenas de `AppLocalizations`, para no entregar una interfaz a medio traducir.

### Calidad

- 48 pruebas unitarias, de widget y de integración.
- Catálogo de regresión con 8 imágenes y manifiesto de resultados esperados.
- Validador estructural offline, SBOM CycloneDX, inventario de licencias,
  checksums, Dependabot, modelo de amenazas y lista MASVS.
- CI para Android, web, iOS y macOS sobre Flutter 3.44.7.

### Distribución

- APK de Android publicados en Releases: uno por arquitectura (`arm64-v8a`,
  `armeabi-v7a`, `x86_64`) y uno universal, cada uno con su SHA-256.

### Fuera del alcance de 1.0.0

- Firma de publicación: los APK van firmados con la clave de depuración de
  Android, así que sirven para instalar y probar pero no para las tiendas.
- Publicación en Google Play o App Store.
- Windows y Linux nativos: se cubren mediante la PWA.
- OCR, NFC, reputación remota de URLs, consulta de productos, sincronización y
  funciones empresariales permanecen apagadas en `FeatureFlags`.

[1.1.0]: https://github.com/vladimiracunadev-create/universal-code-scanner/releases/tag/v1.1.0
[1.0.0]: https://github.com/vladimiracunadev-create/universal-code-scanner/releases/tag/v1.0.0
