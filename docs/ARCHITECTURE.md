# Arquitectura

La aplicación separa captura, interpretación, seguridad, persistencia y
presentación en capas independientes.

<p align="center">
  <img src="images/arquitectura.svg" width="820" alt="Diagrama de capas: features, state, services y core" />
</p>

## Flujo de lectura

```text
Cámara / Imagen / PDF
        ↓
mobile_scanner
        ↓
ScanRecord.fromBarcode
        ├── ContentInterpreter
        └── ScanSecurityAnalyzer
        ↓
Resultado inmediato
        ├── acción segura
        ├── compartir/copiar
        └── HistoryRepository (si corresponde)
```

## Persistencia

- `AppDatabase`: abre Sembast en archivos nativos o IndexedDB web.
- `PayloadCipher`: AES-GCM de 256 bits; guarda nonce, texto cifrado y MAC.
- `HistoryRepository`: almacena metadatos mínimos visibles y carga completa cifrada.
- `InventoryRepository`: aplica el mismo esquema a sesiones de inventario.
- `SettingsRepository`: preferencias no sensibles mediante `SharedPreferencesAsync`.

## Capas

- `models`: entidades inmutables y serializables.
- `services`: interpretación, seguridad, cifrado, importación, exportación y plataforma.
- `state`: stores basados en `ChangeNotifier`.
- `features`: pantallas y componentes por caso de uso.
- `core`: infraestructura transversal.

## Extensión de motores

`ScannerEngine` es la frontera estable alrededor del paquete de captura;
`MobileScannerEngine` es su única implementación en 1.0.0. La interpretación y la
persistencia no dependen de `mobile_scanner`.

Para añadir Windows o Linux nativos basta con una segunda implementación de
`ScannerEngine` — por ejemplo sobre ZXing-C++ — sin modificar `ScanRecord`,
`ContentInterpreter` ni los repositorios. La bandera `secondaryScannerEngine` de
`FeatureFlags` reserva ese punto de activación y permanece apagada.

## Del código a la acción

<p align="center">
  <img src="images/flujo-seguridad.svg" width="820" alt="Flujo de captura, interpretación, riesgo, confirmación y persistencia cifrada" />
</p>
