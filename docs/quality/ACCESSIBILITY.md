# Accesibilidad e idiomas

La aplicación admite idioma del sistema, español de Chile (`es_CL`), español internacional (`es`) e inglés (`en`) para la navegación principal y la infraestructura de localización. Las nuevas cadenas deben añadirse a `AppLocalizations` antes de incorporarse a la interfaz.

Opciones incluidas:

- alto contraste;
- controles táctiles más grandes;
- reducción de transiciones;
- escala tipográfica del sistema sin limitar;
- etiquetas semánticas en acciones críticas;
- compatibilidad prevista con TalkBack, VoiceOver y teclado.

La matriz de dispositivos exige revisar contraste, orden de foco, nombres accesibles y tamaño táctil.

La infraestructura está preparada para localizar todas las pantallas. La navegación principal ya utiliza claves localizadas; cualquier cadena nueva o aún heredada debe migrarse sin modificar la lógica de negocio.
