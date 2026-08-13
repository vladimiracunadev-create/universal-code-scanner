# Accesibilidad e idiomas

## Idiomas en 1.1.0

La interfaz se entrega **solo en español**: idioma del sistema, español de Chile
(`es_CL`) y español internacional (`es`).

La infraestructura de localización admite inglés y `AppLocalizations` ya
contiene sus claves, pero el resto de las pantallas todavía usa literales en
español. Exponer `en` produciría una interfaz a medio traducir —barra de
navegación en inglés sobre contenido en español—, así que el delegado rechaza
ese idioma y Flutter recae en el primer idioma admitido. Una prueba verifica esa
decisión para que no se revierta por accidente.

El inglés se activará cuando todas las pantallas lean sus cadenas de
`AppLocalizations`. Las cadenas nuevas deben añadirse allí antes de incorporarse
a la interfaz.

## Opciones de accesibilidad

Opciones incluidas:

- alto contraste;
- controles táctiles más grandes;
- reducción de transiciones —con ella activada, la barra de estado del escáner
  se dibuja llena y quieta, y el marco no barre la línea de lectura: el estado
  sigue siendo legible sin movimiento;
- escala tipográfica del sistema sin limitar;
- etiquetas semánticas en acciones críticas;
- compatibilidad prevista con TalkBack, VoiceOver y teclado.

La matriz de dispositivos exige revisar contraste, orden de foco, nombres
accesibles y tamaño táctil.

Una prueba de widget levanta el Centro de recuperación con la escala tipográfica
al 200 % y comprueba las guías `labeledTapTargetGuideline` y
`textContrastGuideline` de Flutter.

La barra de estado del escáner se anuncia como región activa (`liveRegion`) con
el estado y la instrucción en una sola etiqueta, para que un lector de pantalla
comunique el cambio de «Escaneando» a «Escaneo en pausa» sin que la persona
tenga que buscarlo.
