# Comportamiento del escáner en cámara

Este documento explica **qué hace la pantalla de lectura en cada estado**, por
qué se eligió ese comportamiento y qué convenciones del sector se adoptaron.
Nace de una prueba en un teléfono real (agosto de 2026) en la que la cámara no
leía al abrir la aplicación y sí lo hacía al salir de la pestaña y volver.

---

## 1. El fallo que originó este trabajo

Reporte textual: *«el tema de lectura de código de barra no funciona; al salir y
volver se activa»*.

La pantalla mostraba la imagen de la cámara y un texto fijo —«Alinea uno o varios
códigos dentro del marco»— **idéntico tanto si el motor estaba analizando cuadros
como si no**. Ese texto era la única señal de estado, así que una cámara que no
llegaba a arrancar era visualmente indistinguible de una cámara esperando un
código. El usuario no tenía forma de saber cuál de las dos cosas ocurría, ni
manera de corregirlo sin abandonar la pestaña.

Tres causas técnicas concretas, las tres corregidas:

| Causa | Efecto observado | Corrección |
|---|---|---|
| `scanWindowUpdateThreshold: 4` congelaba la ventana de lectura | La ventana se calcula en **porcentajes** (0 a 1) sobre el tamaño de la cámara y la orientación del dispositivo, datos que pueden llegar después del primer cuadro. Un umbral de 4 sobre una magnitud que nunca varía más de 1 significaba «no recalcular nunca»: si la primera ventana salía mal, todo código quedaba fuera de la región analizada | Sin umbral: la ventana se recalcula cuando cambian el tamaño, la orientación o el diseño |
| El ciclo de vida de la aplicación quedaba sin atender | `MobileScanner` solo gestiona el ciclo de vida **cuando él crea el controlador**. Esta pantalla le pasa el suyo, así que volver del segundo plano —o del diálogo de permiso de cámara del sistema— dejaba la vista previa congelada | `ScannerScreen` e `InventoryScreen` observan el ciclo de vida y reinician la cámara al volver |
| Ningún error de arranque llegaba a la interfaz | `start()` puede lanzar excepción (controlador desechado, ya iniciándose, permiso denegado) y nadie la capturaba ni la mostraba | Todo arranque pasa por `_startCamera()`, que captura el fallo y lo convierte en un estado visible con acción de recuperación |

---

## 2. Los cuatro estados, siempre visibles

La barra superior nombra el estado, lo describe y lo dibuja. Es una
`ScanStatusBar` con una **barra horizontal** que solo se mueve cuando el motor
está analizando cuadros de verdad.

| Estado | Título | Barra | Acción ofrecida |
|---|---|---|---|
| `starting` | «Iniciando cámara…» | En movimiento | — |
| `scanning` | «Escaneando» | En movimiento + línea que recorre el marco | Botón «Pausar» |
| `paused` | «Escaneo en pausa» | Detenida y vacía | «Reanudar escaneo» + toque en cualquier punto de la vista |
| `unavailable` | «Cámara no disponible» | Detenida, en color de error | «Reintentar» (reconstruye el controlador) |

El escaneo **sigue siendo automático**: no hay que pulsar nada para leer un
código, que es lo que hace cualquier lector del sector. Lo que se añadió es la
respuesta permanente a la pregunta «¿está escaneando ahora mismo?», más un botón
explícito para pausar y reanudar cuando el usuario quiere controlarlo.

Con **movimiento reducido** activado en Ajustes, la barra se dibuja llena y
quieta, y el marco no barre la línea: el estado sigue siendo legible sin
animación.

---

## 3. Confirmación sonora

Antes, la confirmación era `SystemSound.play(SystemSoundType.click)`, que en
Android se traduce al efecto de sonido de la interfaz: **silencioso en cuanto el
usuario apaga los sonidos táctiles del sistema**, que es el ajuste habitual. Por
eso «faltaba el sonido» aunque el código dijera que lo emitía.

Ahora suena un tono propio empaquetado en la aplicación:

- `assets/sounds/scan_success.wav`, generado por `tool/generate_scan_beep.py`
  (dos pulsos cortos y agudos, 2 000 Hz y 2 800 Hz, ~150 ms).
- Se reproduce con `audioplayers` en modo de baja latencia y con la fuente
  precargada, para que el pitido llegue junto con la lectura y no después.
- Se mezcla con el audio existente (`mixWithOthers`): no interrumpe música ni
  llamadas por un tono de una décima de segundo.
- `ScanFeedback` degrada al sonido del sistema si el reproductor falla, y deja de
  intentarlo. Ni el sonido ni la vibración pueden romper una lectura.
- Sonido y vibración siguen siendo dos ajustes independientes.

---

## 4. Convenciones del sector adoptadas

Comparación con lo que ofrecen los lectores de códigos de uso masivo —cámara
nativa de iOS y Android, Google Lens, y lectores libres como Binary Eye o
ZXing—, y estado en esta aplicación:

| Convención | Antes | Ahora |
|---|---|---|
| Lectura automática sin pulsar nada | Sí | Sí |
| Indicador visible de «escaneando» | No | **Barra en movimiento + línea que recorre el marco** |
| Botón explícito de activar/pausar | Icono sin etiqueta | **Botón con texto «Escanear» / «Pausar»** |
| Pitido de lectura conseguida | Dependiente de los sonidos táctiles del sistema | **Tono propio empaquetado** |
| Vibración de confirmación | Sí | Sí |
| Recuperación cuando la cámara no arranca | No existía | **«Reintentar» y «Reiniciar cámara»** |
| Mensaje específico de permiso denegado | No | Sí |
| Reanudar tocando la vista previa | No | Sí |
| Linterna | Sí | Sí |
| Enfoque al tocar | Sí | Sí |
| Zoom | Deslizador | Deslizador |
| Cambio de cámara | Sí | Sí |
| Lectura de varios códigos a la vez | Sí | Sí |
| Importar desde galería y PDF | Sí | Sí |
| Historial de lecturas | Sí | Sí |
| Modo continuo (inventario) | Sí | Sí, además con pausa y estado visible |

Diferencias deliberadas con el resto del sector: esta aplicación **no abre nada
sin confirmación** y **no envía nada a servidores**. El análisis de riesgo de la
URL y la interpretación del contenido ocurren antes de cualquier acción, y esa
decisión no se toca.

---

## 5. Qué se comprobó

| Comprobación | Resultado |
|---|---|
| `flutter analyze --fatal-infos` | 0 hallazgos |
| `flutter test` | 57 de 57 en verde |
| Pruebas nuevas de estado de escaneo | 9 (barra, marco, sonido y vibración) |
| `flutter build apk --debug` | Compila con la dependencia de audio añadida |

Lo que **no** está verificado desde este repositorio: la lectura en un teléfono
físico después de estos cambios. Esa prueba la ejecuta la persona que reportó el
fallo, instalando el APK de la versión 1.1.0.
