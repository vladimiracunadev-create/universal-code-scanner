# Contrato de compatibilidad

Compromisos que la versión 1.0.0 adquiere frente a las versiones futuras. Cada
punto es una restricción sobre lo que puede cambiar sin romper instalaciones ya
existentes.

## Datos del usuario

1. Ningún cambio de esquema elimina el origen antes de verificar la cantidad
   migrada y conservar un respaldo.
2. Cada cambio de esquema es idempotente y se aplica dentro de una transacción.
3. Los sobres cifrados declaran versión, algoritmo e identificador de llave; los
   sobres sin campo `version` se siguen aceptando como formato inicial.
4. Una llave ausente no se recrea durante el descifrado y no puede sobrescribirse
   de forma accidental.
5. La llave activa se guarda en metadatos transaccionales de la base de datos.
6. El respaldo exportado por 1.0.0 (`schemaVersion` 2) seguirá siendo importable.
7. Una importación se valida por completo antes de combinar, omitir duplicados o
   reemplazar.
8. El modo temporal no abre la base persistente y no altera los datos del
   usuario.

## Extensiones

9. Los parsers nuevos se registran por `ContentParserRegistry` y no modifican el
   parser integrado.
10. Los motores nuevos se conectan mediante `ScannerEngine`; `MobileScannerEngine`
    sigue siendo el predeterminado.
11. Las capacidades futuras permanecen apagadas en `FeatureFlags`, y activar una
    bandera nunca cambia el formato persistente.

## Operación

12. La interfaz nunca confirma una mutación antes de que la base haya terminado
    de persistirla.
13. Las escrituras concurrentes de inventario se ejecutan en una cola serial.
14. Las dependencias se actualizan de forma individual, con pruebas de regresión
    y posibilidad de reversión.
