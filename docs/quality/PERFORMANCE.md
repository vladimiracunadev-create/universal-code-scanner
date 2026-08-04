# Rendimiento y memoria

- Galería limitada a 20 imágenes por operación.
- PDF limitado a 50 páginas.
- Render PDF ajustado a un máximo aproximado de 2400 px en su lado mayor.
- Cada imagen PDF se libera y elimina después del análisis; la cancelación se propaga también al renderizador de página.
- Los procesos masivos muestran progreso y pueden cancelarse.
- El historial se limita a 5000 registros.
- Las operaciones de cifrado se preparan antes de la transacción para reducir bloqueos.
- Las rotaciones de llave y las escrituras de inventario se serializan para evitar carreras entre lecturas continuas, cambios de cantidad y notas.
- La interfaz se actualiza solo después de confirmar la persistencia segura.
- Los límites no deben ampliarse sin medir memoria, tiempo y temperatura en dispositivos reales.
