# Bloqueo de dependencias

El proyecto es una aplicación, no un paquete, por lo que `pubspec.lock` **se
versiona**. El archivo incluido se generó con Flutter 3.44.7, la versión fijada
en [`.fvmrc`](../../.fvmrc), y la CI comprueba que exista.

```bash
flutter pub get
```

## Restricciones conocidas

Tres dependencias no pueden fijarse en su última versión publicada porque
generan conflictos de resolución. Cada una está anclada de forma deliberada:

| Paquete | Fijado en | Motivo |
|---|---|---|
| `share_plus` | `12.0.2` | Desde `13.0.0` exige `win32 ^6`, incompatible con el `win32 ^5.9` que requiere `file_picker 11.x` |
| `pdfrx` | `2.4.5` | Desde `2.4.6` arrastra `archive ^4`, incompatible con el `archive ^3.6.1` que requiere `excel 4.0.6` |
| `excel` | `4.0.6` | Última versión publicada; es la que ancla `archive` a la serie 3 |

Estos anclajes deben revisarse cuando `excel` publique una versión sobre
`archive ^4`, o cuando `file_picker` estabilice su serie 12 sobre `win32 ^6`.
`flutter pub outdated` los muestra como actualizables, pero subirlos sin resolver
antes el conflicto rompe la resolución.

## Antes de etiquetar una versión

```bash
./tool/finalize_stable.sh
```

Ese comando ejecuta la resolución, el análisis estricto, las pruebas, las
compilaciones de Android y web, y exige que el lockfile exista antes de
continuar.
