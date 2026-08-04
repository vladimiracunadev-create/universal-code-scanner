# Matriz de pruebas en dispositivos

La versión se considera candidata estable solamente cuando todos los casos obligatorios estén registrados con modelo, sistema, resultado y evidencia.

| Área | Android gama baja | Android media | Android alta | iPhone compatible | macOS | Web |
|---|---:|---:|---:|---:|---:|---:|
| Inicio normal y modo seguro | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio |
| Cámara trasera/frontal | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio |
| Permiso denegado y revocado | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio |
| Poca luz y enfoque | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Recomendado | Recomendado |
| Código pequeño, curvo y dañado | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Recomendado | Recomendado |
| Varios códigos simultáneos | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio |
| Galería y PDF de 1/10/25/50 páginas | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio | No aplica |
| Biometría y regreso desde segundo plano | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio | No aplica |
| Rotación de llave y reinstalación | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio |
| XLSX en Excel/Sheets/LibreOffice | Una exportación por plataforma de escritorio y servicio objetivo |
| TalkBack/VoiceOver/teclado | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio |

Los recursos reproducibles están en `test_assets/manifest.json`. Las simbologías no generadas de forma confiable deben incorporarse únicamente como capturas reales verificadas.
