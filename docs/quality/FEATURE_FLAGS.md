# Funciones aisladas

`FeatureFlags` mantiene apagadas por defecto las extensiones que todavía no forman parte del contrato estable:

- parsers experimentales;
- segundo motor de escaneo;
- OCR;
- NFC;
- reputación remota de URLs;
- consulta de productos;
- sincronización cifrada;
- API empresarial;
- modo kiosco.

Activar una bandera nunca debe cambiar el formato persistente ni sustituir el motor estable. Cada función requiere su propio adaptador, pruebas y mecanismo de reversión.
