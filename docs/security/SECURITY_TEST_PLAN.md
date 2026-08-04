# Plan de pruebas de seguridad

- almacenamiento: confirmar que los valores claros no aparecen en base, preferencias, logs o copias de seguridad;
- criptografía: manipular nonce, ciphertext y MAC y confirmar rechazo;
- autenticación: bloquear al pasar a segundo plano y probar cancelación biométrica;
- plataforma: permisos denegados, revocados y cámara ocupada;
- entrada: JSON truncado, esquema futuro, 25 MB+, profundidad anormal y campos incorrectos;
- enlaces: Punycode, alfabetos mezclados, IP privada, credenciales, puertos, ejecutables y tracking;
- privacidad: verificar que diagnósticos y paquete de recuperación no contienen llaves ni texto claro;
- resiliencia: eliminar la llave, dañar un registro y confirmar que el resto continúa cargando;
- dependencias: generar SBOM y revisar cambios de licencia y vulnerabilidades antes de actualizar.
