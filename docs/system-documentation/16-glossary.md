# 16 · Glosario

Definiciones pensadas para que las entienda alguien sin formación técnica. Los
términos marcados con **★** significan algo **específico en este sistema**: su
definición general no basta para entender el código.

---

## A

**AAMVA** — Estándar estadounidense para el código de barras del reverso de una
licencia de conducir. Este sistema **reconoce siete campos**: número de licencia,
apellido, nombre, fecha de nacimiento, vencimiento, dirección y ciudad. Se marca
siempre como contenido sensible.

**AES-256-GCM** — El método de cifrado que protege el historial y los
inventarios. «AES-256» es la cerradura; «GCM» añade un sello de garantía que
delata si alguien manipuló el contenido. Si se altera un solo bit, el descifrado
falla en vez de devolver basura.

**Application Identifier (AI)** ★ — En un código GS1, un número de dos a cuatro
dígitos que dice qué significa el dato que viene detrás. `01` es el GTIN del
producto, `10` el lote, `17` la fecha de vencimiento. Este sistema traduce nueve
de ellos a nombre legible; el resto se muestra como «AI» seguido del número.

**Aztec** — Un tipo de código bidimensional, parecido a un QR pero con un
cuadrado en el centro en vez de tres esquinas. Común en billetes de tren y
tarjetas de embarque.

---

## B

**Base64** — Una forma de escribir datos binarios usando solo letras, números y
un par de símbolos. Este sistema la usa para dos cosas: guardar el resultado del
cifrado, y representar un código cuyo contenido no es texto legible.

**`binary-base64:`** ★ — Prefijo interno. Cuando un código contiene datos que no
son texto, este sistema lo guarda como `binary-base64:` seguido del contenido en
Base64. Tres partes del código reconocen ese prefijo —el intérprete, el analizador
de riesgo y el generador de registros— y hay que cambiarlas a la vez si se toca.

**Bootstrap** ★ — En este proyecto tiene **dos significados distintos**:

1. `tool/bootstrap.py`, el script que genera las carpetas de Android, iOS, web y
   macOS, que no están en el repositorio.
2. `lib/bootstrap.dart`, el arranque interno de la aplicación, que construye la
   base de datos, el cifrador y los almacenes de estado.

**`builtin-v2`** ★ — El identificador del intérprete de contenido integrado. Es
el único que **no se puede quitar** del registro de intérpretes.

---

## C

**Cancelación en dos niveles** ★ — Al analizar un PDF, el botón «Cancelar» actúa
sobre dos cosas a la vez: el bucle que recorre las páginas y el propio motor que
está dibujando la página actual. Sin la segunda, cancelar esperaría a que
terminara de dibujar la página en curso.

**`canOpen`** ★ — Campo de cada lectura que dice si existe una acción externa
posible. **No significa «es seguro»**: un enlace de riesgo alto tiene `canOpen`
verdadero, y lo que impide abrirlo sin más es el diálogo de confirmación.

**Catálogo de regresión** ★ — Las ocho imágenes de `test_assets/` con su
resultado esperado. Sirven para comprobar que el lector sigue leyendo lo mismo
tras un cambio. **En esta versión ninguna prueba automática las usa**; ver el
hallazgo R-01.

**Cifrado autenticado** — Cifrado que, además de ocultar, detecta manipulación.
Es lo que aporta la parte «GCM» de AES-256-GCM.

**`ContentKind`** ★ — La lista de los diecisiete tipos de contenido que este
sistema sabe reconocer: enlace, Wi-Fi, contacto, evento, correo, teléfono, SMS,
ubicación, OTP, GS1, ISBN, producto, pago, criptomoneda, identidad, binario y
texto.

---

## D

**Data Matrix** — Código bidimensional cuadrado, muy usado en industria y
etiquetado de componentes pequeños.

**Deduplicación en dos niveles** ★ — Este sistema evita registrar el mismo código
dos veces de dos maneras: dentro de una misma captura descarta repeticiones del
mismo texto, y entre capturas ignora la misma **combinación** de códigos durante
dos segundos. El inventario usa una ventana distinta —1,2 segundos y por código
individual— porque ahí escanear dos veces sí debe sumar dos unidades.

**Diagnóstico privado** ★ — El informe técnico que la aplicación permite copiar.
Contiene **solo** el tipo de error, la zona donde ocurrió y una huella de la pila
de llamadas. Nunca contiene el mensaje del error, ni códigos escaneados, ni
enlaces, ni contraseñas, ni notas. Hay una prueba que lo verifica.

---

## E

**EAN-13 / EAN-8** — Los códigos de barras de los productos del supermercado. El
de 13 dígitos es el habitual; el de 8, para envases pequeños.

**EMVCo** — El estándar de los QR de pago. Este sistema los reconoce, extrae
moneda, monto, comercio, ciudad y país, y los marca como contenido sensible.

**EPC / SEPA** — El QR europeo de transferencia bancaria. Se identifica porque
empieza por las letras `BCD` seguidas de un salto de línea.

**Esquema** — La primera parte de una dirección, antes de los dos puntos:
`https:`, `mailto:`, `tel:`. Este sistema **solo permite abrir siete**: `http`,
`https`, `mailto`, `tel`, `sms`, `smsto` y `geo`. Cualquier otro se marca como
riesgo elevado y no se abre.

---

## F

**FeatureFlags** ★ — Nueve interruptores para capacidades futuras: parsers
experimentales, segundo motor, OCR, NFC, reputación de enlaces, consulta de
productos, sincronización, API empresarial y modo kiosco. **Se guardan y se leen
del almacenamiento, pero ningún código los consulta**: en esta versión son una
declaración de intención, no un mecanismo activo. Hallazgo R-02.

**Flutter** — El marco de trabajo con el que está hecha la aplicación. Permite
escribir una vez y compilar para Android, iOS, macOS y navegador.

---

## G

**GS1** — La organización que define los códigos de producto y logística de todo
el mundo. Un «código GS1» agrupa varios datos con etiqueta: producto, lote,
vencimiento, cantidad.

**GTIN** — El número que identifica un producto de forma única en todo el mundo.
Es lo que hay detrás de un código de barras de supermercado.

---

## H

**`HandheldFrame`** ★ — La capa que impide que la aplicación se estire de borde a
borde en una pantalla ancha. Por debajo de 560 puntos **no envuelve nada**: en un
móvil, la aplicación es exactamente la misma que si esta capa no existiera.

**Huella de pila** ★ — Un número corto de ocho dígitos que resume dónde ocurrió un
error, sin revelar nada del contenido. Dos errores con la misma huella son
probablemente el mismo problema.

---

## I

**Inicio seguro** ★ — La pantalla que aparece si la aplicación no consigue
arrancar. Ofrece cuatro salidas: reintentar, abrir en modo temporal, restablecer
las preferencias visuales o copiar el diagnóstico privado.

**Isolate** — En Flutter, un hilo de ejecución con su propia memoria. Este
sistema usa uno aparte para generar los archivos CSV y Excel, para que la
interfaz no se congele.

**ISBN** — El número que identifica un libro. Este sistema lo reconoce cuando
tiene 13 dígitos empezando por 978 o 979, **o cuando tiene exactamente diez
caracteres**, lo que hace que algunos códigos de producto de diez dígitos se
etiqueten como ISBN. Hallazgo R-14.

---

## L

**Llave activa** ★ — El identificador de la llave con la que se está cifrando
ahora mismo. Empieza siendo `v2` y cambia a `v3_` seguido de una marca de tiempo
cada vez que se rota. Se guarda **dentro de la base de datos**, en la misma
transacción que los datos recifrados.

**Llave ausente** ★ — Situación en la que la aplicación encuentra datos cifrados
pero no la llave para descifrarlos. Ocurre tras una reinstalación o una
restauración del sistema. La respuesta del sistema es deliberada: **no crea una
llave nueva**, informa del problema y **bloquea también las escrituras** con ese
identificador. Sin esa segunda mitad, la primera escritura posterior destruiría
la posibilidad de recuperar los datos antiguos.

---

## M

**MaxiCode** — El código hexagonal que usa UPS en sus paquetes.

**MeCard** — Un formato de tarjeta de contacto más compacto que vCard, popular en
Japón.

**Micro QR** — Un QR pequeño, con menos capacidad, para etiquetas diminutas.

**ML Kit** — El motor de reconocimiento de Google que este sistema usa en
Android. En Apple se usa Vision; en el navegador, el motor web del paquete de
lectura.

**Modo temporal** ★ — Forma de arrancar cuando la base de datos no se puede
abrir. Todo funciona igual, pero **el historial y los inventarios viven solo en
memoria y se pierden al cerrar**. Un aviso permanente lo indica, y la rotación de
llave se deshabilita.

---

## N

**Nonce** — Un número aleatorio que se usa una sola vez en cada operación de
cifrado. Es lo que hace que cifrar dos veces el mismo texto produzca resultados
distintos. Se guarda junto al texto cifrado porque hace falta para descifrar; no
es secreto.

---

## O

**OTP** — «One-Time Password», el código de seis dígitos que cambia cada treinta
segundos para verificación en dos pasos. Un QR de OTP contiene la **semilla** que
genera esos códigos, así que es tan sensible como una contraseña. Este sistema lo
muestra pero **nunca lo guarda en el historial** desde el escáner.

---

## P

**PDF417** — Código de barras rectangular y apilado. Se usa en tarjetas de
embarque y en el reverso de las licencias de conducir.

**Punycode** — Una forma de escribir dominios con caracteres no latinos usando
solo letras ASCII. Se reconoce porque el dominio contiene `xn--`. Es legítimo,
pero también es la técnica con la que se fabrican dominios que **parecen** otro.
Este sistema lo marca como riesgo elevado.

**PWA** — «Progressive Web App»: la aplicación funcionando dentro de un
navegador, instalable como si fuera nativa. Es la forma en que este proyecto
cubre Windows y Linux, que no tienen versión nativa.

---

## R

**Recuperación (Centro de)** ★ — La pantalla donde aparecen los registros que no
se pudieron leer. Permite reintentar el descifrado, descartar solo el registro
afectado, marcarlo revisado o exportar un paquete para soporte. **Los registros
dañados nunca se borran solos.**

**Registro sensible** ★ — Una lectura que el sistema clasifica como demasiado
delicada para guardarla sola: contraseña de Wi-Fi, semilla OTP, datos de pago,
dirección de criptomoneda o documento de identidad. Se muestra en pantalla, con
los campos delicados tapados, pero **no entra en el historial** cuando se escanea
desde la pestaña Escanear. En el inventario sí entra; hallazgo R-03.

**Rotación de llave** ★ — Cambiar la llave de cifrado y volver a cifrar todo con
la nueva. Es una operación de todo o nada: si algo falla a mitad, nada cambia y
la llave nueva se borra para que no quede material suelto.

---

## S

**SBOM** — «Software Bill of Materials»: la lista completa de las piezas de
terceros que componen el programa, con su versión. Sirve para saber si una
vulnerabilidad publicada afecta a este proyecto.

**`ScanPhase`** ★ — Los cuatro estados que la barra superior del escáner puede
mostrar: iniciando, escaneando, en pausa y no disponible. **La barra solo se
mueve cuando el motor está analizando imágenes de verdad**, que es lo que
distingue una cámara esperando un código de una cámara que no llegó a arrancar.

**Sembast** — La base de datos que usa este proyecto. No es SQL: guarda documentos
en un archivo local, o en el almacenamiento del navegador cuando se usa como PWA.

**Sobre de cifrado** ★ — La caja donde viaja cada dato cifrado. Por fuera lleva
cuatro etiquetas legibles —versión, algoritmo, identificador de llave y fecha— y
por dentro el contenido cifrado, el nonce y el sello de garantía. Las etiquetas
van visibles porque sin ellas nadie sabría cómo abrir la caja.

**Sobre heredado** ★ — El formato anterior, sin etiquetas por fuera. Se sigue
aceptando, y **se actualiza al formato nuevo la primera vez que se lee**. Eso
significa que leer el historial escribe en la base de datos.

**Swiss QR Bill** — La factura con QR del sistema bancario suizo. Se identifica
porque empieza por las letras `SPC` seguidas de un salto de línea.

---

## T

**Tono de lectura** ★ — El doble pitido que suena al leer un código. Es un
**recurso propio empaquetado dentro de la aplicación**, no el sonido del sistema.
El motivo es concreto: Android silencia el sonido del sistema en cuanto el
usuario apaga los sonidos táctiles, así que la confirmación no se oía en la
mayoría de los teléfonos.

---

## U

**UPC-A / UPC-E** — Los códigos de barras de producto usados sobre todo en
Estados Unidos y Canadá.

---

## V

**Validador estructural** ★ — `tool/validate_structure.py`. Diez comprobaciones
que se ejecutan sin necesidad de compilar: que los YAML sean válidos, que ningún
`import` interno apunte a un archivo inexistente, que no haya rutas de máquina
personal, que la versión mostrada coincida con la real, que nada registre datos
sensibles, que los recursos de prueba existan, que los JSON sean válidos, que
**ningún enlace de la documentación esté roto**, y que el SBOM exista.

**vCard** — El formato estándar de tarjeta de contacto. Un QR de vCard contiene
nombre, teléfono, correo y organización.

**vEvent** — El formato estándar de evento de calendario, dentro de un archivo
iCalendar.

**Ventana de lectura** ★ — El cuadrado central donde se busca el código. Ocupa el
68 % del lado menor de la vista. Se puede desactivar en Ajustes para analizar la
imagen completa. **Un defecto en su recálculo fue la causa del fallo que originó
la versión 1.1.0.**

---

## Z

**Zona horaria** ★ — Detalle a tener presente: la fecha de cada lectura se guarda
en **hora local**, mientras que las fechas internas del sistema de recuperación y
de los sobres de cifrado se guardan en UTC. Hallazgo R-22.

---

## Abreviaturas usadas en esta documentación

| Abreviatura | Significado |
|---|---|
| **AGP** | Android Gradle Plugin |
| **API** | Interfaz de programación. En Android, también el número de versión del sistema |
| **CI** | Integración continua: las comprobaciones automáticas en cada cambio |
| **CSP** | Content-Security-Policy, una cabecera de seguridad web |
| **CVE** | Identificador público de una vulnerabilidad conocida |
| **D-N** | Identificador de una deuda de documentación en [15](15-risks-and-technical-debt.md) |
| **FVM** | Flutter Version Management, gestor de versiones de Flutter |
| **KGP** | Kotlin Gradle Plugin |
| **MASVS** | Estándar de verificación de seguridad de aplicaciones móviles de OWASP |
| **PR** | Pull request: propuesta de cambio |
| **R-N** | Identificador de un hallazgo en [15](15-risks-and-technical-debt.md) |
| **S-N** | Identificador de un hallazgo de seguridad en [11](11-security.md) |
| **SDK** | Kit de desarrollo |
| **SHA-256** | Función que produce una huella única de un archivo. Sirve para verificar que una descarga es exactamente la publicada |
| **TLV** | «Tag-Length-Value», la forma en que se estructuran los datos de un QR de pago EMVCo |
| **UTC** | Hora universal coordinada, sin ajuste de zona |

---

Continúa en [17 · Resumen ejecutivo](17-executive-summary.md).
