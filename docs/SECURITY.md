# Seguridad

## Modelo aplicado

1. No abrir contenido automáticamente.
2. Mostrar dominio y campos interpretados antes de actuar.
3. Elevar advertencias por señales heurísticas.
4. Exigir confirmación cuando existe riesgo o el usuario lo configuró.
5. No persistir automáticamente OTP ni Wi-Fi con contraseña.
6. Cifrar historial e inventarios antes de escribirlos.
7. Guardar la llave de cifrado en el almacén seguro de la plataforma.
8. Permitir bloqueo local y sesión privada.

## Señales de URL

- HTTP sin TLS.
- Usuario o contraseña embebidos.
- Punycode y mezcla de alfabetos.
- IP literal, red privada, loopback o `localhost`.
- Puertos poco habituales.
- Acortadores conocidos.
- Exceso de subdominios o URL muy extensa.
- Caracteres de control.
- Descargas potencialmente ejecutables o archivadas.
- Rutas que aparentan inicio de sesión.
- Parámetros de seguimiento.

## Alcance

El analizador no consulta reputación de dominios y no declara que un enlace sea seguro. Solo presenta señales locales. Una versión empresarial podría añadir una fuente de reputación opcional y explícita, con política de privacidad separada.

## Reporte

No incluyas secretos, claves OTP ni documentos personales en un reporte público. Entrega una descripción mínima, plataforma, versión y pasos reproducibles.

## Consideraciones por plataforma

- Android desactiva `allowBackup` para evitar que una llave de Keystore sea restaurada sin su material criptográfico compatible.
- La PWA debe publicarse únicamente por HTTPS, con HSTS y cabeceras de seguridad apropiadas; el almacenamiento seguro web depende del origen del navegador.
- La exportación JSON, CSV y XLSX contiene datos descifrados por decisión explícita del usuario. Debe tratarse como información sensible fuera de la aplicación.
