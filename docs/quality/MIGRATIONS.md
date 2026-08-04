# Migraciones

## Esquema de la base de datos

`SchemaMigrator` conserva un número de esquema interno en el almacén
`_schema_meta`. Las migraciones se ejecutan dentro de una transacción y pueden
repetirse sin efectos secundarios. En una instalación nueva el migrador parte del
esquema inicial y aplica los pasos pendientes en una sola transacción.

## Sobres de cifrado

El sobre actual contiene versión, algoritmo, identificador de llave y fecha de
creación, además del nonce, el texto cifrado y el MAC. El descifrador acepta
también el sobre sin campo `version`, que se interpreta como formato inicial y se
actualiza de forma perezosa cuando el registro se vuelve a leer.

Una versión de sobre superior a la conocida se rechaza de forma explícita en
lugar de intentar interpretarla.

## Rotación de llave

La rotación prepara todos los sobres nuevos en memoria antes de tocar la base de
datos, y luego escribe registros y metadatos dentro de una única transacción. Si
cualquier paso falla, la transacción se revierte y la llave recién generada se
elimina del almacén seguro para no dejar material huérfano.

## Historial en preferencias

`HistoryRepository` incluye un paso de conversión desde un historial guardado en
preferencias como JSON plano bajo la clave `scan_history_v1`. En una instalación
limpia ese paso se resuelve como una operación nula y se marca completado.

Cuando sí encuentra datos, el procedimiento es:

1. Convertir el origen exacto en un respaldo cifrado, sin duplicarlo en claro.
2. Convertir y cifrar todos los registros.
3. Insertarlos mediante transacción.
4. Comprobar que la cantidad resultante contiene todo lo esperado.
5. Solo entonces eliminar la clave antigua y marcar la conversión terminada.
6. Ante cualquier error, conservar el origen intacto, no marcar la conversión
   como terminada y crear una incidencia en el Centro de recuperación.

La llave activa se registra dentro de la misma base de datos. La preferencia
equivalente solo se lee una vez para trasladarla; después, los cambios de llave
se confirman en la misma transacción que los datos reencriptados.
